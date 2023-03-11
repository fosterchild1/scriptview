-- Press the "Home" or "Right shift" key to toggle it
-- Sadly never made an editor, maybe someone can improve this
-- An api (not mine) was used to make syntax highlighting work since my way was stupid
-- Yeas this ui is just like dnspy i did that on purpose

local version = "1.6"
local changelog = [[
-- Expect a value editor and other implementations in a future update!!

[v1.6 - Quality of Life Update]
-- removed Active Scripts from script explorer due to it being laggy
-- minor bug fixes and tweaks
-- imrpoved script finder
-- added settings
-- value editor

[v1.5.1]
-- fixed ScriptView getting bricked upon searching for a script

[v1.5 - Simplification Update]
-- removed the two buttons in the up left corner because they were useless because of the new update
-- notification now shows the ScriptView icon
-- ScriptView icon moved and centered since it was being covered by the roblox ui
-- bigger script explorer and bigger script frame
-- you can now search for scripts with the new textbox in script explorer
-- patched constants/upvalues/environment showing when right clicking an expanded local script

[v1.4.22]
-- LocalScript icon fixed

[v1.4.21]
-- get path now returns a better path

[v1.4.2]
-- right click on scripts and now you can save/copy/get their path
-- removed broken cursor because to my knowledge theres no way to fix it

[v1.4.1511]
-- fate took over since Litten stopped]]

--============================================================--

--local screenGui			= script.Parent
local screenGui			= game:GetObjects("rbxassetid://12749845767")[1]
local backdrop			= screenGui.Backdrop
local cSource, cName, cInfo	= "", "", nil
local localPlayer		= game:GetService("Players").LocalPlayer

local ZCount=2

local meta = getrawmetatable(game)
setreadonly(meta, false)

screenGui.Parent = game.CoreGui.RobloxGui
backdrop.Parent = game:GetService("CoreGui")
local oldnamecall=meta.__namecall
meta.__namecall=function(self, ...)
    local method=getnamecallmethod()
    if self==localPlayer and method:lower()=="kick" then
        return
    end
    return oldnamecall(self, ...)
end
setreadonly(meta, true)

backdrop.Position = UDim2.new(0.5, 0, 1, 2)
backdrop.Size = UDim2.new(0.25, 0, 0.25, 0)

--// for new users
local ex = identifyexecutor()
local StarterGui = game:GetService("StarterGui")
if ex~="Synapse X" then
    StarterGui:SetCore("SendNotification", {
	Title = "ScriptView Warning",
	Text = "Warning! ScriptView works best on Synapse X.",
	Icon = "rbxassetid://2950787461"
    })
end
StarterGui:SetCore("SendNotification", {
	Title = "ScriptView loaded",
	Text = "Press Right Control to open!",
	Icon = "rbxassetid://2950787461"
})

--\\ the stuff
local blank = "​ " -- zero width unicode + space

local UIS				= game:GetService("UserInputService")
local localPlayer		= game:GetService("Players").LocalPlayer
local m					= localPlayer:GetMouse()
local debuggerFrame		= backdrop.Debugger
  local scriptList		= debuggerFrame.Scripts

    local debugScrollUp		= debuggerFrame.VerticalFrame.ScrollUp
    local debugScrollDown	= debuggerFrame.VerticalFrame.ScrollDown
    local debugScrollLeft	= debuggerFrame.HorizontalFrame.ScrollLeft
    local debugScrollRight	= debuggerFrame.HorizontalFrame.ScrollRight

    local debugTemplate		= scriptList.Template; debugTemplate.Parent = nil;
    
local editor            = backdrop.Editor
  local editorVal1      = editor.value
  local editorVal2      = editor.value2
 
local scriptFrame		= backdrop.ScriptFrame
  local sourceFrame		= scriptFrame.Source

    local scriptScrollUp	= scriptFrame.VerticalFrame.ScrollUp
    local scriptScrollDown	= scriptFrame.VerticalFrame.ScrollDown
    local scriptScrollLeft	= scriptFrame.HorizontalFrame.ScrollLeft
    local scriptScrollRight	= scriptFrame.HorizontalFrame.ScrollRight

    local lineTemplate		= sourceFrame.Line; lineTemplate.Parent = nil;
    local wordTemplate		= lineTemplate.Word; wordTemplate.Parent = nil;


local tabsFrame			= backdrop.Tabs
  local tabTemplate			= tabsFrame.Deselected; tabTemplate.Parent = nil
  local ttemp				= tabsFrame.Selected; ttemp.Parent = nil

local options=screenGui.Settings
local cog=debuggerFrame.Title.settings

local searching=false
local foundscripts={}

--// explorer icons
local textures = {
	['folder']			= "2950788693";

	['localscript']		= "11047413712"; -- new cause old one got deleted LOL!
	['modulescript']	= "413367412";
	['script']          = "11782597580";  

	['function']		= "2759601950";
	['variable']		= "2759602224";
	['table']			= "2757039628";

	['constant']		= "2717878542";
	['upvalue']			= "2717876089";
}

--// customization for u guys
local operators = {
	['bracket']	= Color3.fromRGB(204, 104, 147); -- () {} []
	['math']	= Color3.fromRGB(204, 104, 147); -- + - * /
	['compare']	= Color3.fromRGB(204, 104, 147); -- = == > <
	['misc']	= Color3.fromRGB(204, 104, 147); -- other symbols
}

local highlight = {
	['builtin']	= Color3.fromRGB(255, 255, 255); -- wait, workspace
	['keyword']	= Color3.fromRGB(79, 117, 255);  -- true, function
	['string']	= Color3.fromRGB(152, 203, 248); -- "hi"
	['number']	= Color3.fromRGB(69, 255, 187);  -- 123
	['comment']	= Color3.fromRGB(85, 85, 85);    -- --comment
	
	['(']	= operators.bracket;
	[')']	= operators.bracket;
	['[']	= operators.bracket;
	[']']	= operators.bracket;
	['{']	= operators.bracket;
	['}']	= operators.bracket;
	
	['+']	= operators.math;
	['-']	= operators.math;
	['/']	= operators.math;
	['*']	= operators.math;
	
	['=']	= operators.compare;
	['==']	= operators.compare;
	['>=']	= operators.compare;
	['<=']	= operators.compare;
	['~=']	= operators.compare;
	['<']	= operators.compare;
	['>']	= operators.compare;
	
	['.']	= operators.misc;
	[',']	= operators.misc;
	['#']	= operators.misc;
	['%']	= operators.misc;
	['^']	= operators.misc;
	[';']	= operators.misc;
	['~']	= operators.misc;
}

--============================================================--

local aa = "	" -- storing the tab button because its annoying
local otherdone = 1 -- idk what to name it
local syntax = true  -- syntax highlight toggle

local module = game:GetObjects('rbxassetid://2798231692')[1]
local lexer = loadstring(module.Source)()

local showss=false
local showcorepackages=true

function GVT(v, def) --getValueType
	return (type(v) == "function" and "function") or (type(v) == "table" and "table") or def or "variable"
end

function getEnv(scr)
	if getsenv and not getmenv then
		return getsenv(scr)
	elseif getsenv and getmenv then
		return (scr:IsA("LocalScript") and getsenv(scr)) or getmenv(scr)
	else
		return {SCRIPT_ENVIRONMENT_ERROR = true}
	end
end

function getTextSize(label)
	local service = game:GetService("TextService")
	local vec2 = service:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(10000, 25))
	return vec2
end

function replacestr(str, old, new)
	return str:gsub(old, new)
end

function c3(r,g,b)
	return Color3.new(r/255,g/255,b/255)
end

function selection(tab)
	local sName = tab:FindFirstChild("ScriptName")
	if not sName then return end
	
	Tween(tab, "Out", "Sine", 0.1, {
		BackgroundColor3	= ttemp.BackgroundColor3;
		BorderColor3		= ttemp.BackgroundColor3
	})
	
	Tween(sName, "Out", "Sine", 0.1, {
		TextColor3 = ttemp.ScriptName.TextColor3;
	})
end

function deselection(tab)
	local sName = tab:FindFirstChild("ScriptName")
	if not sName then return end
	
	Tween(tab, "Out", "Sine", 0.15, {
		BackgroundColor3	= tabTemplate.BackgroundColor3;
		BorderColor3		= tabTemplate.BackgroundColor3
	})
	
	Tween(sName, "Out", "Sine", 0.15, {
		TextColor3 = tabTemplate.ScriptName.TextColor3;
	})
end

function bumpTabs(num)
	for i, v in pairs(tabsFrame:GetChildren()) do
		if v:IsA("TextButton") then
			v.LayoutOrder = v.LayoutOrder + num
		end
	end
end

function createTab(info, key)
	for i, v in pairs(tabsFrame:GetChildren()) do
		deselection(v)
	end
	
	local class		= info.Type:lower()
	local identity	= (info.Class and info.Class:lower()) or info.Type:lower()
	local name		= info.Name
	local value		= info.Value
	local obj		= info.Obj
	
	local tab = tabTemplate:Clone()
	local selected = false
	tab.ScriptName.Text = "   "..name:gsub("\n", ""):gsub("\r", ""):gsub("	", " ")
	tab.Name = tostring(key)
	
	local x = getTextSize(tab.ScriptName)
	tab.Size = UDim2.new(0, ((x.X < 400 and x.X) or 400) + 20, 1, 0)
	
	bumpTabs(1)
	tab.Parent = tabsFrame
	
	tab.MouseButton1Click:Connect(function()
		for i, v in pairs(tabsFrame:GetChildren()) do
			deselection(v)
		end
		
		selection(tab)
		loadSourceFromInfo(info, key)
	end)
	
	tab.Close.MouseButton1Click:Connect(function()
		if #tabsFrame:GetChildren() <= 2 then 
			loadSource("")
			return 
		end
		--bumpTabs(1)
		tab:Destroy()
		
		if otherdone == key then
			for i, v in pairs(sourceFrame:GetChildren()) do
				if v.Name == "Line" then
					v:Destroy()
				end
			end
		end
	end)
	
	selection(tab)
end

function sortString(str)
	str = str:gsub(aa, blank .. "")
	local lines = {}
	local newLine, curLine, tblLine = 1, 1, {}
	local lex = lexer.scan(str)
	local num = 0
	
	local gm = str:gmatch("[^\n]+")
	
	for typ, word in ( ( syntax and lexer.scan(str) ) or gm ) do
		num = num + 1
		if not syntax then
			word = typ
			newLine = newLine + 1
		end
		if word:find("\n") then
			word = word:gsub("\n", "")
			if word == "" then word = " " end
			newLine = newLine + 1
		end
		
		local wordTable = {typ, word}
		table.insert(tblLine, wordTable)
		
		if newLine ~= curLine then
			curLine = newLine
			table.insert(lines, tblLine)
			tblLine = {}
		end
	end
	table.insert(lines, tblLine)
	return lines
end

function arrayToString(t, a, b)
	local s = ""
	for i = 1, #t do
		s = s..tostring(t[i])
	end
	return s:sub(a, b)
end

function loadSource(source)
    editorVal1.Text=""
    editorVal2.Text=""
	cSource = source
	for i, v in pairs(sourceFrame:GetChildren()) do
		if v.Name == "Line" then
			v:Destroy()
		end
	end
	
	local linesDictionary = sortString(source)
	local uilistlayout = sourceFrame.UIListLayout
	uilistlayout.Parent = nil
	
	for num = 1, #linesDictionary do
		local lineTable = linesDictionary[num]
		local line = lineTemplate:Clone()
		local wordLayout = line.UIListLayout
		
		line.LineNumber.Text = num.."  "
		line.Parent = sourceFrame
		wordLayout.Parent = nil
		
		for i = 1, #lineTable do
			local wordTable = lineTable[i]
			local typ, str = wordTable[1], wordTable[2]
			local word = wordTemplate:Clone()
			word.Parent = line
			word.String.Text = str
			
			local txtSize = getTextSize(word.String)
			word.String.Size = UDim2.new(0, txtSize.X, 1, 0)
			word.Size = word.String.Size
			line.Size = UDim2.new(0, line.Size.X.Offset + txtSize.X, 0, 25)
			
			if syntax then
				local col = highlight[typ]
				if col then
					word.String.TextColor3 = highlight[typ]
				end
			end
		end
		wordLayout.Parent = line
	end
	
	uilistlayout.Parent = sourceFrame
end

function loadSourceFromInfo(info, k)
	pcall(function()
		otherdone = k
		local class		= info.Type:lower()
		local identity	= (info.Class and info.Class:lower()) or info.Type:lower()
		local name		= info.Name
		local value		= info.Value
		local obj		= info.Obj
		
		cName = name
		cInfo=info
		
		if class == "localscript" or class == "modulescript" then
			loadSource(decompile(obj), "new")
		elseif class == "function" then
			loadSource(decompile(value), "new")
		elseif class == "folder" then
			loadSource("-- Container for scripts parented to ".. tostring(obj))
		elseif class == "text" then
			loadSource(value)
		elseif class == "constant" then
			loadSource("<"..identity.."> "..value)
		else
			loadSource("<"..identity.."> "..name.." = <"..type(value).."> "..tostring(value))
		end
	end)
end

function Tween(Obj, Dir, Style, Duration, Goal)
	local tweenService	= game:GetService("TweenService")
	local tweenInfo		= TweenInfo.new(
		Duration,
		Enum.EasingStyle[Style],
		Enum.EasingDirection[Dir]
	)
	local tween = tweenService:Create(Obj,tweenInfo,Goal)
	tween:Play()
	return tween
end

function updateScrollingFrame(frame)
	local elementSize = frame.UIListLayout.AbsoluteContentSize
	local canvasSize = elementSize + Vector2.new(50,50)
	local f = function(n) return frame.Parent:FindFirstChild(n,true) end
	
	local Up, Down, Left, Right = f("ScrollUp"),f("ScrollDown"),f("ScrollLeft"),f("ScrollRight")
	
	if Up and Down and canvasSize.Y <= frame.AbsoluteSize.Y then
		Up.ImageTransparency, Down.ImageTransparency = 0.5, 0.5
		Up.AutoButtonColor, Down.AutoButtonColor = false, false
	else
		Up.ImageTransparency, Down.ImageTransparency = 0, 0
		Up.AutoButtonColor, Down.AutoButtonColor = true, true
	end
	
	if Left and Right and canvasSize.X <= frame.AbsoluteSize.X then
		Left.ImageTransparency, Right.ImageTransparency = 0.5, 0.5
		Left.AutoButtonColor, Right.AutoButtonColor = false, false
	else
		Left.ImageTransparency, Right.ImageTransparency = 0, 0
		Left.AutoButtonColor, Right.AutoButtonColor = true, true
	end
end

function getScriptsOfParent(p)
	local list = {}
	local objs = (p == nil and getnilinstances and getnilinstances()) or p:GetDescendants()
	if p == game then objs = (getscripts and getscripts()) or game:GetDescendants() end
	
	for i = 1, #objs do
		local v = objs[i]
		if (v.ClassName == "LocalScript" or v.ClassName == "ModuleScript") or (v.ClassName == "Script" and showss) then
			if v.ClassName == "ModuleScript" then
				pcall(function()
					unlockmodulescript(v)
				end)
			end
			table.insert(list, v)
		end
	end
	
	return list
end

old = decompile

function getPath(fullname)
    local str=fullname:split(".")
    local returnthis='game:GetService("'
    local length=string.len(str[1])+1
    returnthis=returnthis..str[1]
    if str[2]==nil then
        returnthis=returnthis..'")'
    else
        returnthis=returnthis..'")'
    end        
    returnthis=returnthis..string.sub(fullname,length)
    return returnthis
end    

function createButton(parent, info)
	local key		= math.random(10000000,99999999)
	local expand	= false
	local button	= debugTemplate:Clone()
	local par		= (parent:FindFirstChild("Contents")) or parent

	local class		= info.Type:lower()
	local identity	= (info.Class and info.Class:lower()) or info.Type:lower()
	local name		= info.Name
	local value		= info.Value
	local obj		= info.Obj
	
	button.Label.Text = name:gsub("\n", ""):gsub("\r", ""):gsub("	", " ")
	button.Icon.Image = "rbxassetid://"..textures[class:lower()]
	button.Parent = par
	button.Name = name
	button.LayoutOrder = #par:GetChildren()
	
	button.Clicked.MouseButton1Click:Connect(function()
	    if searching and button.Label.TextColor3==Color3.new(150/255,150/255,150/255) then return end
		if tabsFrame:FindFirstChild(tostring(key)) then
			for i, v in pairs(tabsFrame:GetChildren()) do
				deselection(v)
			end
			selection(tabsFrame[tostring(key)])
		else
			createTab(info, key)
		end
		loadSourceFromInfo(info)
	end)
	
	local contents=button.Contents
	
	button.Clicked.MouseButton2Click:Connect(function()
	    
	    if screenGui:FindFirstChild("buttonframe") then
	        screenGui.buttonframe:Destroy()
	    end 
	    
	    local copyscript=button:Clone()
	    local savescript=button:Clone()
	    local getpath=button:Clone()
	    local delscript=button:Clone()
	    copyscript.Contents:Destroy()
	    savescript.Contents:Destroy()
	    getpath.Contents:Destroy()
	    delscript.Contents:Destroy()
	    copyscript.Size=UDim2.new(0,300,0,25)
	    savescript.Size=UDim2.new(0,300,0,25)
	    getpath.Size=UDim2.new(0,300,0,25)
	    delscript.Size=UDim2.new(0,300,0,25)
	    
	    local buttonframe=Instance.new("Frame",screenGui)
	    buttonframe.BackgroundTransparency=1
	    buttonframe.Position=UDim2.new(0,m.X,0,m.Y)
	    buttonframe.Name="buttonframe"
	    
	    local l_layout=Instance.new("UIListLayout",buttonframe)
	    
	    if class == "localscript" or class == "modulescript" then
	    
	    copyscript.Parent=buttonframe
	    print(button.ZIndex)
	    button.ZIndex=ZCount
	    ZCount=ZCount+1
	    copyscript.Name="copyscript"
	    copyscript.Icon:Destroy()
	    copyscript.Expand:Destroy()
	    copyscript.BackgroundTransparency=0
	    copyscript.BackgroundColor3=Color3.new(32/255,32/255,32/255)
	    copyscript.BorderSizePixel=0
	    copyscript.Label.Text="Copy to Clipboard"
	    
	    copyscript.Clicked.MouseButton1Click:Connect(function()
            buttonframe:Destroy()
            if class == "localscript" or class == "modulescript" then
		    	setclipboard(decompile(obj))
		    elseif class == "function" then
		    	setclipboard(decompile(value))
		    elseif class == "folder" then
		    	setclipboard(tostring(obj))
	    	elseif class == "text" then
		    	setclipboard(value)
		    end
	    end)
	    
	    
	    savescript.Parent=buttonframe
	    savescript.Name="savescript"
	    savescript.Icon:Destroy()
	    savescript.Expand:Destroy()
	    savescript.BackgroundTransparency=0
	    savescript.BackgroundColor3=Color3.new(32/255,32/255,32/255)
	    savescript.BorderSizePixel=0
	    savescript.Label.Text="Save to File"
    
	    savescript.Clicked.MouseButton1Click:Connect(function()
            buttonframe:Destroy()
            if class == "localscript" or class == "modulescript" then
		    	writefile(game.PlaceId.."_"..name..".lua", decompile(obj))
		    elseif class == "function" then
		    	writefile(game.PlaceId.."_"..name..".lua", decompile(value))
		    elseif class == "folder" then
		    	writefile(name..".lua", tostring(obj))
	    	elseif class == "text" then
		    	writefile(game.PlaceId.."_"..name..".lua", value)
		    end
	    end)
	    
	    delscript.Parent=buttonframe
	    delscript.Name="getpath"
	    delscript.Icon:Destroy()
	    delscript.Expand:Destroy()
	    delscript.BackgroundTransparency=0
	    delscript.BackgroundColor3=Color3.new(32/255,32/255,32/255)
	    delscript.BorderSizePixel=0
	    delscript.Label.Text="Delete Instance"
	    
	    delscript.Clicked.MouseButton1Click:Connect(function()
	        obj:Destroy()
	        buttonframe:Destroy()
	        button:Destroy()
	    end)
	    
	    end
	    
	    
	    getpath.Parent=buttonframe
	    getpath.Name="getpath"
	    getpath.Icon:Destroy()
	    getpath.Expand:Destroy()
	    getpath.BackgroundTransparency=0
	    getpath.BackgroundColor3=Color3.new(32/255,32/255,32/255)
	    getpath.BorderSizePixel=0
	    getpath.Label.Text="Get Path"
	    
	    getpath.Clicked.MouseButton1Click:Connect(function()
	        buttonframe:Destroy()
	        setclipboard(getPath(obj:GetFullName()))
	    end)
	    
	end)
	
	button.Clicked.MouseEnter:Connect(function()
	    if searching and button.Label.TextColor3==Color3.new(150/255,150/255,150/255) then return end
		Tween(button.Clicked, "Out", "Quint", 0.25, {
			Transparency = 0.9
		})
	end)
	
	button.Clicked.MouseLeave:Connect(function()
		Tween(button.Clicked, "Out", "Quint", 0.25, {
			Transparency = 1
		})
	end)
	
	button.Expand.MouseButton1Down:Connect(function()
	    if searching and button.Label.TextColor3==Color3.new(150/255,150/255,150/255) then return end
		pcall(function()
			expand = not expand
			button.Contents.Visible = expand
			if expand then
				button.Expand.Image = "rbxassetid://2757012309"
			else
				button.Expand.Image = "rbxassetid://2757012592"
			end
			
			
			local contents = button.Contents:GetChildren()
			for i = 1, #contents do
				local v = contents[i]
				if v:IsA("Frame") then
					v:Destroy()
				end
			end
			if not expand then return end
			
			if class == "folder" then
				for i, v in pairs(getScriptsOfParent(obj)) do
					createButton(button, {
						Name = v.Name,
						Type = v.ClassName,
						Obj = v
					})
				end
			elseif class == "table" then
				for i, v in pairs(value) do
					createButton(button, {
						Name = i,
						Type = GVT(v),
						Value = v
					})
				end
			elseif class == "localscript" or class == "modulescript" then
				pcall(function()
					local env = getEnv(obj)
					for i, v in pairs(env) do
						createButton(button, {
							Name = i,
							Type = GVT(v),
							Value = v
						})
					end
			    end)
			elseif class == "function" then
				pcall(function() --getupvalues
					local env = (debug.getupvalues and debug.getupvalues(value)) or {ERROR_GETTING_UPVALUES = true}
					for i, v in pairs(env) do
						createButton(button, {
							Name = i,
							Type = GVT(v, "upvalue"),
							Class = "upvalue",
							Value = v
						})
					end
				end)
				pcall(function() --getconstants
					local env = (debug.getconstants and debug.getconstants(value)) or {ERROR_GETTING_CONSTANTS = true}
					for i, v in pairs(env) do
						createButton(button, {
							Name = tostring(v),
							Type = GVT(v, "constant"),
							Class = "constant",
							Value = v
						})
					end
				end)
			end
		end)
	end)
	
	local UILL = button.Contents.UIListLayout
	UILL.Changed:Connect(function(p)
		local a = UILL.AbsoluteContentSize
		button.Size = UDim2.new(0, 300, 0, 25 + a.Y)
	end)
	
	return button
end
local function findVal(text)
    local env = getEnv(cInfo.Obj)
	for i, v in pairs(env) do
	    if tostring(i)==text then
	        return {i,"env"}
	    end
	    if GVT(v)=="function" then
	        local upvalues = (debug.getupvalues and debug.getupvalues(v)) or {ERROR_GETTING_UPVALUES = true}
		    for l,x in pairs(upvalues) do
		        if tostring(x)==text then
		            return {x,"upvalue",v}
		        end   
		    end
		    local const = (debug.getconstants and debug.getconstants(v)) or {ERROR_GETTING_CONSTANTS = true}
			    for j,k in pairs(const) do
			        if tostring(k)==text then
			            return {k,"constant",v}
			        end   
			    end 
	    end     
	end
	return nil
end    

--============================================================--

do
	scriptScrollUp.MouseButton1Down:Connect(function()
		local sF, canvas = sourceFrame, sourceFrame.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X, canvas.Y - 25)
		})
	end)
	
	scriptScrollDown.MouseButton1Down:Connect(function()
		local sF, canvas = sourceFrame, sourceFrame.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X, canvas.Y + 25)
		})
	end)
	
	scriptScrollLeft.MouseButton1Down:Connect(function()
		local sF, canvas = sourceFrame, sourceFrame.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X + 25, canvas.Y)
		})
	end)
	
	scriptScrollRight.MouseButton1Down:Connect(function()
		local sF, canvas = sourceFrame, sourceFrame.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X - 25, canvas.Y)
		})
	end)
	
	debugScrollUp.MouseButton1Down:Connect(function()
		local sF, canvas = scriptList, scriptList.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X, canvas.Y - 25)
		})
	end)
	
	debugScrollDown.MouseButton1Down:Connect(function()
		local sF, canvas = scriptList, scriptList.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X, canvas.Y + 25)
		})
	end)
	
	debugScrollLeft.MouseButton1Down:Connect(function()
		local sF, canvas = scriptList, scriptList.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X + 25, canvas.Y)
		})
	end)
	
	debugScrollRight.MouseButton1Down:Connect(function()
		local sF, canvas = scriptList, scriptList.CanvasPosition
		Tween(sF, "Out", "Sine", 0.25, {
			CanvasPosition = Vector2.new(canvas.X - 25, canvas.Y)
		})
	end)
end

--============================================================--

local open = false

local about = "--\ ScriptView " .. version .. "\--\n--\ Developed by Litten then fate \--".."\n-- Original: https://v3rmillion.net/showthread.php?tid=846255 --\n\n"..changelog

backdrop.Title.Label.Text = "ScriptView "..version

local aboutinfo = {Name="About", Type="Text", Obj=nil, Value=about}

function createFolders()
    
local buttons={}

table.insert(buttons,createButton(scriptList,
	{Name="LocalPlayer", Type="Folder", Obj=game:GetService("Players").LocalPlayer}
).Name)

table.insert(buttons,createButton(scriptList,
	{Name="Nil", Type="Folder", Obj=nil}
).Name)

for i, v in pairs(game:GetChildren()) do
	pcall(function()
		if v:FindFirstChildWhichIsA("LocalScript", true) or v:FindFirstChildWhichIsA("ModuleScript", true) then
		    if v.Name=="CorePackages" and showcorepackages then
		        table.insert(buttons,createButton(scriptList,
				{Name=v.ClassName, Type="Folder", Obj=v}
			    ).Name)
		    elseif v.Name~="CorePackages" then
		    	table.insert(buttons,createButton(scriptList,
				{Name=v.ClassName, Type="Folder", Obj=v}
			    ).Name)
			end
		end
	end)
end

return buttons

end

local buttons=createFolders()

local aboutButton = createTab(aboutinfo, 1)

loadSourceFromInfo(aboutinfo)

game:GetService("RunService").RenderStepped:Connect(function()
	
	do
		updateScrollingFrame(scriptList)
		local elementSize = scriptList.UIListLayout.AbsoluteContentSize
		local canvasSize = elementSize + Vector2.new(25,25)
		
		scriptList.CanvasSize = UDim2.new(0, canvasSize.X, 0, canvasSize.Y)
	end
	
	do
		updateScrollingFrame(sourceFrame)
		local elementSize = sourceFrame.UIListLayout.AbsoluteContentSize
		local canvasSize = elementSize + Vector2.new(50,50)
		
		sourceFrame.CanvasSize = UDim2.new(0, canvasSize.X, 0, canvasSize.Y)
	end
end)

function Close()
	Tween(backdrop, "Out", "Sine", 0.2, {
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.new(0.25, 0, 0.25, 0),
	})
	options.Visible=false
	if screenGui:FindFirstChild("buttonframe") then
        screenGui.buttonframe:Destroy()
    end    
end

function Open()
	Tween(backdrop, "Out", "Sine", 0.2, {
		Position = UDim2.new(0.5, 0, 0, -35),
		Size = UDim2.new(1, -2, 1, -2 + 36),
	})
end

--======--
local changingkb=false
local keybind=Enum.KeyCode.RightControl.Name
cog.MouseButton1Click:Connect(function()
    options.Visible=true
    if not options.Options.Visible then
        options.se.Visible=false
        options.sf.Visible=false
        options.Options.Visible=true
    end    
    options.Position=UDim2.new(0,m.X,0,m.Y+50)
end)
options.Topbar.exit.MouseButton1Click:Connect(function()
    if not options.Options.Visible then
        for i,v in pairs(options:GetChildren()) do
            if v.Name~="Options" and v.Name~="Topbar" and v.Visible then
                v.Visible=false
            end
        end
        options.Options.Visible=true
    else    
        options.Visible=false
    end    
end)
options.Options.kb.MouseButton1Click:Connect(function()
    options.Options.kb.Text="Awaiting input...."
    changingkb=true
end)
options.Options.sf.MouseButton1Click:Connect(function()
    options.Options.Visible=false
    options.sf.Visible=true
end)
options.sf.syntax.MouseButton1Click:Connect(function()
    syntax=not syntax
end)
options.Options.se.MouseButton1Click:Connect(function()
    options.Options.Visible=false
    options.se.Visible=true
end)
options.se.ss.MouseButton1Click:Connect(function()
    showss=not showss
end)
options.se.corepack.MouseButton1Click:Connect(function()
    showcorepackages=not showcorepackages
    if not showcorepackages then
        table.remove(buttons,table.find(buttons,"CorePackages"))
        scriptList.CorePackages:Destroy()
    else
        table.insert(buttons,createButton(scriptList,
			{Name="CorePackages", Type="Folder", Obj=game.CorePackages}
		).Name)
    end    
end)
for i,v in pairs(options:GetDescendants()) do
    if v:IsA("TextButton") and v.Name~="sf" and v.Name~="se" then
        v.MouseButton1Click:Connect(function()
            if v.BackgroundColor3==Color3.new(200/255,200/255,200/255) then
                v.BackgroundColor3=Color3.fromRGB(20,20,20)
                v.BorderColor3=Color3.fromRGB(23,23,23)
            else
                v.BackgroundColor3=Color3.fromRGB(200,200,200)
                v.BorderColor3=Color3.fromRGB(205,205,205)
            end    
        end)
    end
end    
UIS.InputBegan:Connect(function(input)
    if changingkb then
        options.Options.kb.Text=input.KeyCode.Name
        changingkb=false
        keybind=input.KeyCode.Name
        return
    end    
	if input.KeyCode.Name == keybind then
		open = not open
		if open then
			Open()
		else
			Close()
		end
	end
end)
local scriptsingame=getScriptsOfParent(game)
local expandedlist={}
debuggerFrame.Find.FocusLost:Connect(function()
    if debuggerFrame.Find.Text=="" then 
        if expandedlist~={} then
            for i,v in pairs(expandedlist) do
                v.Expand.Image="rbxassetid://2757012592"
                for l,x in pairs(v.Contents:GetChildren()) do
                    if not x:IsA("UIListLayout") then
                        x:Destroy()
                    end    
                end    
            end    
        end
        expandedlist={}
        for i,v in pairs(buttons) do
            scriptList[v].Label.TextColor3=Color3.new(204/255,204/255,204/255)
        end
        searching=false
        return
    end
    for i,v in pairs(scriptsingame) do
        searching=true
        local lowerN=v.Name:lower()
        local lowerT=debuggerFrame.Find.Text:lower()
        if lowerN:find(lowerT) then
            local splitname=v:GetFullName():split(".")
            local folder=splitname[1]
            if table.find(buttons,folder) then
                if not table.find(expandedlist,scriptList[buttons[table.find(buttons,folder)]]) then
                    table.insert(expandedlist,scriptList[buttons[table.find(buttons,folder)]])
                end
                table.insert(foundscripts,v)
                createButton(scriptList[buttons[table.find(buttons,folder)]], {
					Name = v.Name,
					Type = v.ClassName,
					Obj = v
				})
				scriptList[buttons[table.find(buttons,folder)]].Expand.Image = "rbxassetid://2757012309"
            end    
        end    
    end
    for i,v in pairs(buttons) do
        scriptList[v].Label.TextColor3=Color3.new(150/255,150/255,150/255)
    end    
end)
local count=0
spawn(function()
    while wait(1/5) do
        if count%3==0 then
		    local generatedname="CoreScripts/"
		    for i=1,16 do
		        if i==1 then
		            local rng=math.random(1,10)
		            generatedname=generatedname..string.sub("1234567890",rng,rng)
		            continue
		        end
		        local char=math.random(1,2)
		        if char==1 then
		            local rng=math.random(1,6)
		            generatedname=generatedname..string.sub("abcdef",rng,rng)
		        else
		            local rng=math.random(1,10)
		            generatedname=generatedname..string.sub("1234567890",rng,rng)
		        end
	    	end
	    	screenGui.Name=generatedname
		end
		count=count+1
	end	
end)
m.Button1Up:Connect(function()
    if screenGui:FindFirstChild("buttonframe") then
        screenGui.buttonframe:Destroy()
    end
end)
editorVal2.FocusLost:Connect(function()
    local tx=editorVal1.Text
    local to=editorVal2.Text
    if tonumber(to) then
        to=tonumber(to)
    end
    if findVal(tx) then
        local val=findVal(tx)
        print(val[1],val[2])
        if val[2]=="env" then
            getsenv(cInfo.Obj)[val[1]]=to
            print(getsenv(cInfo.Obj)[val[1]])
        elseif val[2]=="upvalue" then
            debug.setupvalue(val[3],tostring(val[1]),to)
        elseif val[2]=="constant" then
            setconstant(val[3],tostring(val[1]),to)
        end
    end    
end)
while wait() do
	if backdrop.Position==UDim2.new(0.5, 0, 1, 2) then
		backdrop.Parent=nil
	else
		backdrop.Parent=screenGui
	end
end
