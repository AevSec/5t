local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LayerLib = {}
LayerLib.__index = LayerLib

local Section = {}
Section.__index = Section

local Group = {}
Group.__index = Group

local Theme = {
	Column = Color3.fromRGB(17, 18, 22),
	Raised = Color3.fromRGB(21, 22, 27),
	Hover = Color3.fromRGB(26, 28, 34),
	Line = Color3.fromRGB(31, 33, 39),
	Line2 = Color3.fromRGB(43, 46, 54),
	Input = Color3.fromRGB(13, 14, 17),
	Text = Color3.fromRGB(229, 229, 232),
	Soft = Color3.fromRGB(201, 202, 208),
	Mute = Color3.fromRGB(125, 128, 139),
	Dim = Color3.fromRGB(79, 82, 91),
	Warn = Color3.fromRGB(242, 180, 90),
	Danger = Color3.fromRGB(242, 103, 106),
	Info = Color3.fromRGB(127, 183, 255),
}
LayerLib.Theme = Theme

LayerLib.Fonts = {
	Familjen = {
		[400] = "https://raw.githubusercontent.com/google/fonts/main/ofl/familjengrotesk/FamiljenGrotesk%5Bwght%5D.ttf",
	},
}

local FONT_DIR = "LayerLib/fonts"
local FALLBACK_FONT = "rbxasset://fonts/families/GothamSSm.json"
local Mono = Font.new("rbxasset://fonts/families/RobotoMono.json")
local Glyph = Font.new("rbxasset://fonts/families/Arial.json")
local Medium, SemiBold = Enum.FontWeight.Medium, Enum.FontWeight.SemiBold

local KeyNames = {
	RightShift = "RShift", LeftShift = "LShift", LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftAlt = "LAlt", RightAlt = "RAlt", MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
}

function LayerLib.LoadFont(name, faces)
	local ok, family = pcall(function()
		for _, dir in { "LayerLib", FONT_DIR } do
			if not isfolder(dir) then
				makefolder(dir)
			end
		end
		local list = {}
		for weight, url in pairs(faces) do
			local path = ("%s/%s-%d.ttf"):format(FONT_DIR, name, weight)
			if not isfile(path) then
				writefile(path, game:HttpGet(url))
			end
			table.insert(list, { name = tostring(weight), weight = weight, style = "normal", assetId = getcustomasset(path) })
		end
		local json = ("%s/%s.json"):format(FONT_DIR, name)
		writefile(json, HttpService:JSONEncode({ name = name, faces = list }))
		return getcustomasset(json)
	end)
	return ok and family or FALLBACK_FONT
end

function LayerLib.Icon(icon)
	if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
		return "rbxassetid://" .. icon
	end
	if type(icon) == "string" and icon:match("^https?://") then
		local ok, asset = pcall(function()
			for _, dir in { "LayerLib", "LayerLib/icons" } do
				if not isfolder(dir) then
					makefolder(dir)
				end
			end
			local path = "LayerLib/icons/" .. icon:gsub("[^%w]", ""):sub(-48) .. ".png"
			if not isfile(path) then
				writefile(path, game:HttpGet(icon))
			end
			return getcustomasset(path)
		end)
		if ok then
			return asset
		end
	end
	return icon or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function New(class, props, children)
	local o = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	o.Parent = props.Parent
	return o
end

local function Tween(o, t, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Corner(r)
	return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function Stroke(color, thickness, transparency)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Pad(l, r, t, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r or l),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
	})
end

local function List(padding, horizontal)
	return New("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function IsPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function Hover(o)
	if not UIS.MouseEnabled then
		return
	end
	o.MouseEnter:Connect(function()
		Tween(o, 0.15, { BackgroundTransparency = 0 })
	end)
	o.MouseLeave:Connect(function()
		Tween(o, 0.15, { BackgroundTransparency = 1 })
	end)
end

local function Chevron(parent, size, position, open)
	return New("TextLabel", {
		Name = "Chevron",
		Text = ">",
		FontFace = Mono,
		TextSize = size,
		TextColor3 = Theme.Mute,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = position,
		Size = UDim2.fromOffset(16, 16),
		Rotation = open and 270 or 90,
		Parent = parent,
	})
end

local function Row(parent, height, click)
	local row = New(click and "TextButton" or "Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Corner(7), Pad(8, 8) })
	if click then
		row.Text = ""
		row.AutoButtonColor = false
		Hover(row)
	end
	return row
end

function LayerLib:Font(weight)
	return Font.new(self.Family, weight or Enum.FontWeight.Regular)
end

function LayerLib:Text(props, children)
	local t = New("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = self:Font(),
		TextSize = 14,
		TextColor3 = Theme.Soft,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}, children)
	for k, v in props do
		t[k] = v
	end
	return t
end

function LayerLib:Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self.Connections, c)
	return c
end

function LayerLib:OnAccent(fn)
	table.insert(self.Hooks, fn)
	fn(self.Accent, self.Ink)
end

function LayerLib:SetAccent(color)
	self.Accent = color
	local lum = 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
	self.Ink = lum > 0.55 and Color3.fromRGB(13, 16, 4) or Color3.new(1, 1, 1)
	for _, fn in self.Hooks do
		fn(color, self.Ink)
	end
end

function LayerLib:Track(node, fn)
	node.InputBegan:Connect(function(input)
		if not IsPress(input) then
			return
		end
		local scroller = node:FindFirstAncestorOfClass("ScrollingFrame")
		if scroller then
			scroller.ScrollingEnabled = false
		end
		local function go(p)
			local a, s = node.AbsolutePosition, node.AbsoluteSize
			fn(math.clamp((p.X - a.X) / s.X, 0, 1), math.clamp((p.Y - a.Y) / s.Y, 0, 1), true)
		end
		go(input.Position)
		local move, up
		move = UIS.InputChanged:Connect(function(i)
			if i == input or i.UserInputType == Enum.UserInputType.MouseMovement then
				go(i.Position)
			end
		end)
		up = UIS.InputEnded:Connect(function(i)
			if i == input or i.UserInputType == Enum.UserInputType.MouseButton1 then
				move:Disconnect()
				up:Disconnect()
				if scroller then
					scroller.ScrollingEnabled = true
				end
				fn(nil, nil, false)
			end
		end)
	end)
end

function LayerLib:Fold(parent, open, maxHeight)
	local holder = New("Frame", {
		Name = "Fold",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = parent,
	})
	local host = holder
	if maxHeight then
		host = New("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Line2,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = holder,
		})
	end
	local inner = New("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = host,
	})
	local fold = { Holder = holder, Inner = inner, Open = open }
	local tween

	local function target()
		local h = inner.AbsoluteSize.Y / self.UIScale.Scale
		if maxHeight then
			host.CanvasSize = UDim2.fromOffset(0, h)
			h = math.min(h, maxHeight())
		end
		return fold.Open and h or 0
	end

	function fold:Set(state)
		fold.Open = state
		local t = Tween(holder, 0.32, { Size = UDim2.new(1, 0, 0, target()) })
		tween = t
		t.Completed:Connect(function()
			if tween == t then
				tween = nil
				holder.Size = UDim2.new(1, 0, 0, target())
			end
		end)
	end

	inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not tween then
			holder.Size = UDim2.new(1, 0, 0, target())
		end
	end)
	return fold
end

function LayerLib.new(options)
	options = options or {}
	local self = setmetatable({ Sections = {}, Hooks = {}, Connections = {}, Z = 1 }, LayerLib)
	self.Family = options.Font or LayerLib.LoadFont("FamiljenGrotesk", LayerLib.Fonts.Familjen)
	self.Width = options.Width or 208
	self:SetAccent(options.Accent or Color3.fromRGB(200, 242, 107))

	self.Gui = New("ScreenGui", {
		Name = options.Name or "LayerLib",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999999,
		ResetOnSpawn = false,
		Parent = (gethui and gethui()) or game:GetService("CoreGui"),
	})
	self.Cover = New("Frame", {
		Name = "ScreenCover",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = self.Gui,
	})
	self.UIScale = New("UIScale", { Parent = self.Cover })
	self.Toasts = New("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0, 320, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 1e4,
		Parent = self.Cover,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})

	local camera = workspace.CurrentCamera
	local function rescale()
		local v = camera.ViewportSize
		local s = math.clamp(math.min(v.X / 1100, v.Y / 680), 0.5, 1)
		self.UIScale.Scale = s
		self.Cover.Size = UDim2.fromScale(0.98 / s, 0.98 / s)
	end
	self:Connect(camera:GetPropertyChangedSignal("ViewportSize"), rescale)
	rescale()
	return self
end

function LayerLib:Notify(title, subtitle, duration)
	self.ToastCount = (self.ToastCount or 0) + 1
	local toast = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Theme.Column,
		BackgroundTransparency = 1,
		LayoutOrder = self.ToastCount,
		Parent = self.Toasts,
	}, { Corner(10), Pad(14, 14, 10, 10), New("UIListLayout", {
		Padding = UDim.new(0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	local stroke = Stroke(Theme.Line2, 1, 1)
	stroke.Parent = toast
	local dot = New("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Rotation = 45,
		BackgroundColor3 = self.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = toast,
	}, { Corner(2) })
	local labels = {
		self:Text({ Text = title, TextColor3 = Theme.Text, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), TextTransparency = 1, LayoutOrder = 1, Parent = toast }),
		self:Text({ Text = subtitle or "", FontFace = Mono, TextSize = 11, TextColor3 = Theme.Mute, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), TextTransparency = 1, LayoutOrder = 2, Parent = toast }),
	}
	local function fade(a)
		Tween(toast, 0.3, { BackgroundTransparency = a })
		Tween(stroke, 0.3, { Transparency = a })
		Tween(dot, 0.3, { BackgroundTransparency = a })
		for _, l in labels do
			Tween(l, 0.3, { TextTransparency = a })
		end
	end
	fade(0)
	task.delay(duration or 2.2, function()
		fade(1)
		task.wait(0.3)
		toast:Destroy()
	end)
end

function LayerLib:Section(name, icon)
	local index = #self.Sections + 1
	local open = true
	local frame = New("Frame", {
		Name = "Section",
		Size = UDim2.fromOffset(self.Width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset((index - 1) * (self.Width + 16), 0),
		BackgroundColor3 = Theme.Column,
		BorderSizePixel = 0,
		ZIndex = index,
		Parent = self.Cover,
	}, {
		Corner(10),
		Stroke(Theme.Line),
		New("UIShadow", { Transparency = 0.61, BlurRadius = UDim.new(0, 10) }),
		List(),
	})

	local top = New("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = frame,
	})
	local image = New("ImageLabel", {
		Name = "SectionIcon",
		Image = LayerLib.Icon(icon),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		ScaleType = Enum.ScaleType.Fit,
		BackgroundTransparency = 1,
		Parent = top,
	})
	self:OnAccent(function(c)
		image.ImageColor3 = c
	end)
	self:Text({
		Name = "SectionHeader",
		Text = name,
		TextSize = 15,
		TextColor3 = Theme.Text,
		FontFace = self:Font(SemiBold),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 36, 0.5, 0),
		Size = UDim2.new(1, -110, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = top,
	})
	local count = self:Text({
		FontFace = Mono,
		TextSize = 10,
		TextColor3 = Theme.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0.5, 0),
		Size = UDim2.fromOffset(44, 20),
		Parent = top,
	})
	local button = New("TextButton", {
		Name = "ToggleSectBtn",
		Text = ">",
		FontFace = Mono,
		TextSize = 14,
		TextColor3 = Theme.Mute,
		AutoButtonColor = false,
		Selectable = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		Rotation = 270,
		Parent = top,
	})
	local divider = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = frame,
	})
	local fold = self:Fold(frame, true, function()
		return math.max(120, self.Cover.AbsoluteSize.Y / self.UIScale.Scale - frame.Position.Y.Offset - 64)
	end)
	fold.Holder.LayoutOrder = 3
	Pad(6, 6, 6, 6).Parent = fold.Inner
	List(4).Parent = fold.Inner

	local function set(state)
		open = state
		fold:Set(state)
		Tween(button, 0.32, { Rotation = state and 270 or 90 })
		Tween(divider, 0.25, { BackgroundTransparency = state and 0 or 1 })
	end
	button.Activated:Connect(function()
		set(not open)
	end)

	top.InputBegan:Connect(function(input)
		if not IsPress(input) then
			return
		end
		local start, origin, moved = input.Position, frame.Position, false
		self.Z += 1
		frame.ZIndex = self.Z
		local move, up
		move = UIS.InputChanged:Connect(function(i)
			if not (i == input or i.UserInputType == Enum.UserInputType.MouseMovement) then
				return
			end
			local d = (i.Position - start) / self.UIScale.Scale
			if not moved and d.Magnitude > 4 then
				moved = true
			end
			if moved then
				frame.Position = UDim2.fromOffset(origin.X.Offset + d.X, math.max(0, origin.Y.Offset + d.Y))
			end
		end)
		up = UIS.InputEnded:Connect(function(i)
			if i == input or i.UserInputType == Enum.UserInputType.MouseButton1 then
				move:Disconnect()
				up:Disconnect()
				if not moved then
					set(not open)
				end
			end
		end)
	end)

	local section = setmetatable({ Window = self, Frame = frame, Body = fold.Inner, Count = count, N = 0 }, Section)
	function section:SetOpen(state)
		set(state)
	end
	table.insert(self.Sections, section)
	return section
end

function Section:Group(name, open)
	if open == nil then
		open = true
	end
	local win = self.Window
	self.N += 1
	self.Count.Text = self.N .. " sec"

	local frame = New("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self.N,
		Parent = self.Body,
	}, { List() })
	local head = New("TextButton", {
		Name = "Header",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Hover,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = frame,
	}, { Corner(8) })
	Hover(head)
	local bar = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(3, 10),
		BackgroundColor3 = Theme.Line2,
		BorderSizePixel = 0,
		Parent = head,
	}, { Corner(2) })
	local title = win:Text({
		Text = name,
		TextSize = 14,
		FontFace = win:Font(Medium),
		TextColor3 = Theme.Mute,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -80, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = head,
	})
	local count = win:Text({
		FontFace = Mono,
		TextSize = 10,
		TextColor3 = Theme.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.new(0, 30, 1, 0),
		Parent = head,
	})
	local chevron = Chevron(head, 13, UDim2.new(1, -9, 0.5, 0), open)

	local fold = win:Fold(frame, open)
	fold.Holder.LayoutOrder = 2
	Pad(20, 0, 2, 10).Parent = fold.Inner
	List(2).Parent = fold.Inner
	New("Frame", {
		Position = UDim2.fromOffset(11, 2),
		Size = UDim2.new(0, 1, 1, -12),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
		Parent = fold.Holder,
	})

	local function paint(animate)
		local t = animate and 0.3 or 0
		Tween(title, t, { TextColor3 = open and Theme.Text or Theme.Mute })
		Tween(bar, t, { Size = UDim2.fromOffset(3, open and 14 or 10), BackgroundColor3 = open and win.Accent or Theme.Line2 })
		Tween(chevron, 0.32, { Rotation = open and 270 or 90 })
	end
	win:OnAccent(function(c)
		if open then
			bar.BackgroundColor3 = c
		end
	end)
	head.Activated:Connect(function()
		open = not open
		fold:Set(open)
		paint(true)
	end)
	paint(false)

	return setmetatable({ Window = win, Body = fold.Inner, Count = count, N = 0 }, Group)
end

function Group:Add(o)
	self.N += 1
	o.LayoutOrder = self.N
	o.Parent = self.Body
	self.Count.Text = self.N
	return o
end

function Group:Toggle(o)
	local win = self.Window
	local toggle = { Value = o.Default or false }
	local row = self:Add(Row(nil, 32, true))
	local label = win:Text({ Text = o.Name, Size = UDim2.new(1, -24, 1, 0), Parent = row })
	local holder = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local ring = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
		Rotation = 45,
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Corner(2) })
	local ringStroke = Stroke(Theme.Dim, 1.5)
	ringStroke.Parent = ring
	local dot = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Corner(1) })

	local function paint(animate)
		local on, t = toggle.Value, animate and 0.3 or 0
		Tween(label, t, { TextColor3 = on and Theme.Text or Theme.Mute })
		Tween(ring, t, { Rotation = on and 225 or 45, Size = UDim2.fromOffset(on and 11 or 9, on and 11 or 9) })
		Tween(ringStroke, t, { Color = on and win.Accent or Theme.Dim })
		Tween(dot, t, { Size = UDim2.fromOffset(on and 6 or 0, on and 6 or 0) })
	end
	win:OnAccent(function(c)
		dot.BackgroundColor3 = c
		if toggle.Value then
			ringStroke.Color = c
		end
	end)

	function toggle:Set(value, silent)
		toggle.Value = value
		paint(true)
		if o.Callback and not silent then
			task.spawn(o.Callback, value)
		end
	end
	row.Activated:Connect(function()
		toggle:Set(not toggle.Value)
	end)
	paint(false)
	if toggle.Value and o.Callback then
		task.spawn(o.Callback, true)
	end
	return toggle
end

function Group:Slider(o)
	local win = self.Window
	local min, max, step, suffix = o.Min or 0, o.Max or 100, o.Step or 1, o.Suffix or ""
	local decimals = #(tostring(step):match("%.(%d+)") or "")
	local format = "%." .. decimals .. "f"
	local slider = {}

	local row = self:Add(Row(nil, 44, false))
	win:Text({ Text = o.Name, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, -80, 0, 20), Parent = row })
	local value = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(80, 20),
		FontFace = Mono,
		TextSize = 11,
		TextColor3 = Theme.Mute,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Parent = row,
	})
	local box = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(64, 18),
		FontFace = Mono,
		TextSize = 11,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Theme.Input,
		ClearTextOnFocus = false,
		Visible = false,
		Parent = row,
	}, { Corner(4), Pad(4) })
	local boxStroke = Stroke(win.Accent)
	boxStroke.Parent = box

	local track = New("Frame", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Active = true,
		Parent = row,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Theme.Line2,
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(1) })
	local fill = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(1) })
	local thumb = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(99) })
	win:OnAccent(function(c)
		fill.BackgroundColor3 = c
		thumb.BackgroundColor3 = c
		boxStroke.Color = c
	end)

	function slider:Set(v, silent)
		v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
		slider.Value = v
		local p = (v - min) / (max - min)
		fill.Size = UDim2.new(p, 0, 0, 2)
		thumb.Position = UDim2.fromScale(p, 0.5)
		value.Text = format:format(v) .. suffix
		if o.Callback and not silent then
			task.spawn(o.Callback, v)
		end
	end

	local dragging, hovering = false, false
	local function grow()
		local s = (dragging or hovering) and 13 or 10
		Tween(thumb, 0.15, { Size = UDim2.fromOffset(s, s) })
	end
	win:Track(track, function(x, _, active)
		dragging = active
		if x then
			slider:Set(min + x * (max - min))
		end
		grow()
	end)
	track.MouseEnter:Connect(function()
		hovering = true
		grow()
	end)
	track.MouseLeave:Connect(function()
		hovering = false
		grow()
	end)
	track.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseWheel then
			slider:Set(slider.Value + (i.Position.Z > 0 and step or -step))
		end
	end)
	value.Activated:Connect(function()
		box.Text = format:format(slider.Value)
		value.Visible, box.Visible = false, true
		box:CaptureFocus()
	end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			slider:Set(n)
		end
		value.Visible, box.Visible = true, false
	end)

	slider:Set(o.Default or min, true)
	return slider
end

function Group:Buttons(list)
	local win = self.Window
	local row = self:Add(New("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, {
		Pad(8, 8, 3, 3),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}))
	for i, b in list do
		local button = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.Raised,
			LayoutOrder = i,
			Parent = row,
		}, { Corner(8), Pad(12, 12) })
		local stroke = Stroke(Theme.Line2)
		stroke.Parent = button
		local scale = New("UIScale", { Parent = button })
		local label = win:Text({
			Text = b.Name,
			TextSize = 13,
			TextColor3 = Theme.Text,
			FontFace = win:Font(Medium),
			Size = UDim2.new(1, -16, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = button,
		})
		local arrow = win:Text({
			Text = "→",
			FontFace = Glyph,
			TextSize = 13,
			TextColor3 = Theme.Dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Parent = button,
		})
		win:OnAccent(function(c, ink)
			if b.Primary then
				button.BackgroundColor3, stroke.Color = c, c
				label.TextColor3, arrow.TextColor3 = ink, ink
			end
		end)
		if UIS.MouseEnabled then
			button.MouseEnter:Connect(function()
				Tween(stroke, 0.15, { Color = win.Accent })
				Tween(arrow, 0.2, { Position = UDim2.new(1, 2, 0.5, 0), TextColor3 = b.Primary and win.Ink or win.Accent })
			end)
			button.MouseLeave:Connect(function()
				Tween(stroke, 0.15, { Color = b.Primary and win.Accent or Theme.Line2 })
				Tween(arrow, 0.2, { Position = UDim2.new(1, 0, 0.5, 0), TextColor3 = b.Primary and win.Ink or Theme.Dim })
			end)
		end
		button.MouseButton1Down:Connect(function()
			Tween(scale, 0.1, { Scale = 0.975 })
		end)
		button.MouseButton1Up:Connect(function()
			Tween(scale, 0.1, { Scale = 1 })
		end)
		button.Activated:Connect(function()
			Tween(scale, 0.1, { Scale = 1 })
			if b.Callback then
				task.spawn(b.Callback)
			end
		end)
	end
end

function Group:Button(o)
	return self:Buttons({ o })
end

function Group:Label(text)
	local label = self:Add(self.Window:Text({
		Text = text:upper(),
		FontFace = Mono,
		TextSize = 10,
		TextColor3 = Theme.Dim,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Size = UDim2.new(1, 0, 0, 22),
	}, { Pad(8, 8, 0, 3) }))
	return {
		Set = function(_, t)
			label.Text = t:upper()
		end,
	}
end

function Group:Description(text)
	local label = self:Add(self.Window:Text({
		Text = text,
		TextSize = 13,
		TextColor3 = Theme.Mute,
		TextWrapped = true,
		RichText = true,
		LineHeight = 1.15,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	}, { Pad(8, 8, 2, 6) }))
	return {
		Set = function(_, t)
			label.Text = t
		end,
	}
end

function Group:Divider()
	local holder = self:Add(New("Frame", { Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1 }))
	New("Frame", {
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
		Parent = holder,
	})
end

function Group:Warning(text, kind)
	kind = kind or "Warn"
	local color = Theme[kind]
	local tags = { Warn = "CAUTION", Danger = "DANGER", Info = "NOTE" }
	local holder = self:Add(New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Pad(8, 8, 6, 6) }))
	local stripe = New("Frame", {
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.fromOffset(4, 0),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { List(3) })
	local dash = kind == "Info" and 2 or 3
	local dashes = {}
	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Pad(14, 0, 1, 2), List(2) })
	self.Window:Text({ Text = tags[kind], FontFace = Mono, TextSize = 10, TextColor3 = color, Size = UDim2.new(1, 0, 0, 13), LayoutOrder = 1, Parent = body })
	local label = self.Window:Text({
		Text = text,
		TextSize = 13,
		TextWrapped = true,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		Parent = body,
	})
	local function fit()
		local h = math.max(0, body.AbsoluteSize.Y / self.Window.UIScale.Scale - 4)
		local count = math.max(0, math.floor((h + 3) / (dash + 3)))
		stripe.Size = UDim2.fromOffset(4, h)
		while #dashes < count do
			table.insert(dashes, New("Frame", {
				Size = UDim2.new(kind == "Info" and 0.5 or 1, 0, 0, dash),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = stripe,
			}))
		end
		while #dashes > count do
			table.remove(dashes):Destroy()
		end
	end
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return {
		Set = function(_, t)
			label.Text = t
		end,
	}
end

function Group:Textbox(o)
	local win = self.Window
	local holder = self:Add(New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Pad(8, 8, 6, 6), List(6) }))
	win:Text({ Text = o.Name, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = holder })
	local box = New("TextBox", {
		Text = o.Default or "",
		PlaceholderText = o.Placeholder or "",
		PlaceholderColor3 = Theme.Dim,
		FontFace = Mono,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 2,
		Parent = holder,
	}, { Corner(7), Pad(10) })
	local stroke = Stroke(Theme.Line2)
	stroke.Parent = box
	box.Focused:Connect(function()
		Tween(stroke, 0.15, { Color = win.Accent })
	end)
	box.FocusLost:Connect(function(enter)
		Tween(stroke, 0.15, { Color = Theme.Line2 })
		if enter and o.Callback then
			task.spawn(o.Callback, box.Text)
		end
	end)
	return {
		Set = function(_, t)
			box.Text = t
		end,
		Get = function()
			return box.Text
		end,
	}
end

function Group:Dropdown(o)
	local win = self.Window
	local multi = o.Multi
	local dropdown = {}
	local selected, items = {}, {}

	local frame = self:Add(New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { List() }))
	local head = Row(frame, 32, true)
	head.LayoutOrder = 1
	win:Text({ Text = o.Name, Size = UDim2.new(1, -110, 1, 0), Parent = head })
	local value = win:Text({
		FontFace = Mono,
		TextSize = 11,
		TextColor3 = Theme.Mute,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 0),
		Size = UDim2.new(0, 100, 1, 0),
		Parent = head,
	})
	local chevron = Chevron(head, 11, UDim2.new(1, 2, 0.5, 0), false)
	local fold = win:Fold(frame, false)
	fold.Holder.LayoutOrder = 2
	Pad(8, 0, 2, 4).Parent = fold.Inner
	List().Parent = fold.Inner

	local function list()
		local out = {}
		for _, v in dropdown.Options do
			if selected[v] then
				table.insert(out, v)
			end
		end
		return out
	end

	local function render()
		local chosen = list()
		if multi then
			value.Text = #chosen == 0 and "none" or #chosen > 2 and (#chosen .. " selected") or table.concat(chosen, ", ")
		else
			value.Text = chosen[1] or "none"
		end
		for v, item in items do
			local on = selected[v] == true
			Tween(item.Label, 0.15, { TextColor3 = on and Theme.Text or Theme.Mute })
			Tween(item.Check, 0.25, { Size = UDim2.fromOffset(on and 6 or 0, on and 6 or 0) })
		end
	end

	local function setOpen(state)
		fold:Set(state)
		Tween(chevron, 0.32, { Rotation = state and 270 or 90 })
	end

	function dropdown:Refresh(options)
		dropdown.Options = options
		for _, item in items do
			item.Button:Destroy()
		end
		items = {}
		for i, v in options do
			local button = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = Theme.Hover,
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Parent = fold.Inner,
			}, { Corner(6), Pad(10, 10) })
			Hover(button)
			local label = win:Text({ Text = v, TextSize = 13, TextColor3 = Theme.Mute, Size = UDim2.new(1, -16, 1, 0), Parent = button })
			local check = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -3, 0.5, 0),
				Size = UDim2.new(),
				Rotation = 45,
				BorderSizePixel = 0,
				BackgroundColor3 = win.Accent,
				Parent = button,
			}, { Corner(2) })
			win:OnAccent(function(c)
				check.BackgroundColor3 = c
			end)
			items[v] = { Button = button, Label = label, Check = check }
			button.Activated:Connect(function()
				if multi then
					selected[v] = not selected[v] or nil
				else
					selected = { [v] = true }
					setOpen(false)
				end
				render()
				if o.Callback then
					task.spawn(o.Callback, multi and list() or v)
				end
			end)
		end
		render()
	end

	function dropdown:Set(v, silent)
		selected = {}
		for _, x in multi and v or { v } do
			selected[x] = true
		end
		render()
		if o.Callback and not silent then
			task.spawn(o.Callback, multi and list() or v)
		end
	end

	head.Activated:Connect(function()
		setOpen(not fold.Open)
	end)
	dropdown:Refresh(o.Options)
	dropdown:Set(o.Default or (multi and {} or o.Options[1]), true)
	return dropdown
end

function Group:Keybind(o)
	local win = self.Window
	local keybind = { Value = o.Default }
	local binding, pulse = false, nil

	local row = self:Add(Row(nil, 32, true))
	win:Text({ Text = o.Name, Size = UDim2.new(1, -60, 1, 0), Parent = row })
	local chip = New("TextLabel", {
		FontFace = Mono,
		TextSize = 10,
		TextColor3 = Theme.Mute,
		BackgroundColor3 = Theme.Input,
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 20),
		Parent = row,
	}, { Corner(5), Pad(7, 7), New("UISizeConstraint", { MinSize = Vector2.new(36, 20) }) })
	local stroke = Stroke(Theme.Line2)
	stroke.Parent = chip

	local function name(key)
		return key and (KeyNames[key.Name] or key.Name) or "None"
	end
	local function paint()
		if pulse then
			pulse:Cancel()
			pulse = nil
		end
		chip.TextTransparency = 0
		chip.Text = binding and "···" or name(keybind.Value)
		chip.TextColor3 = binding and win.Accent or Theme.Mute
		stroke.Color = binding and win.Accent or Theme.Line2
		if binding then
			pulse = TweenService:Create(chip, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.55 })
			pulse:Play()
		end
	end

	function keybind:Set(key)
		keybind.Value = key
		paint()
		if o.Changed then
			task.spawn(o.Changed, key)
		end
	end

	row.Activated:Connect(function()
		binding = true
		paint()
	end)
	win:Connect(UIS.InputBegan, function(input, processed)
		if binding then
			local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode
				or (input.UserInputType.Name:match("^MouseButton") and input.UserInputType)
			if not key then
				return
			end
			binding = false
			keybind:Set(key ~= Enum.KeyCode.Escape and key or nil)
			return
		end
		local key = keybind.Value
		if not processed and key and (input.KeyCode == key or input.UserInputType == key) and o.Callback then
			task.spawn(o.Callback)
		end
	end)
	paint()
	return keybind
end

function Group:ColorPicker(o)
	local win = self.Window
	local picker = {}
	local h, s, v = (o.Default or Color3.new(1, 1, 1)):ToHSV()

	local frame = self:Add(New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { List() }))
	local head = Row(frame, 32, true)
	head.LayoutOrder = 1
	win:Text({ Text = o.Name, Size = UDim2.new(1, -100, 1, 0), Parent = head })
	local swatch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BorderSizePixel = 0,
		Parent = head,
	}, { Corner(5), Stroke(Color3.new(1, 1, 1), 1, 0.86) })
	local hex = win:Text({
		FontFace = Mono,
		TextSize = 11,
		TextColor3 = Theme.Mute,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 70, 1, 0),
		Parent = head,
	})

	local fold = win:Fold(frame, false)
	fold.Holder.LayoutOrder = 2
	Pad(8, 8, 4, 10).Parent = fold.Inner
	List(9).Parent = fold.Inner

	local sv = New("Frame", { Size = UDim2.new(1, 0, 0, 118), Active = true, BorderSizePixel = 0, LayoutOrder = 1, Parent = fold.Inner }, { Corner(8) })
	New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv }, {
		Corner(8),
		New("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
	})
	New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv }, {
		Corner(8),
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
	})
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		ZIndex = 2,
		Parent = sv,
	}, { Corner(99), Stroke(Color3.new(1, 1, 1), 2) })

	local hue = New("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Active = true,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = fold.Inner,
	}, {
		Corner(5),
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
		}),
	})
	local hueKnob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(6, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = hue,
	}, { Corner(3), Stroke(Color3.new(0, 0, 0), 1, 0.55) })

	local bottom = New("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 3, Parent = fold.Inner })
	local box = New("TextBox", {
		FontFace = Mono,
		TextSize = 12,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		BackgroundColor3 = Theme.Input,
		Size = UDim2.fromOffset(86, 26),
		Parent = bottom,
	}, { Corner(7) })
	local boxStroke = Stroke(Theme.Line2)
	boxStroke.Parent = box
	local presets = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(116, 16),
		BackgroundTransparency = 1,
		Parent = bottom,
	}, { List(4, true) })

	local function render(fromBox, silent)
		local c = Color3.fromHSV(h, s, v)
		picker.Value = c
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		knob.Position = UDim2.fromScale(s, 1 - v)
		knob.BackgroundColor3 = c
		hueKnob.Position = UDim2.fromScale(h, 0.5)
		swatch.BackgroundColor3 = c
		hex.Text = "#" .. c:ToHex():upper()
		if not fromBox then
			box.Text = hex.Text
		end
		if o.Callback and not silent then
			task.spawn(o.Callback, c)
		end
	end

	function picker:Set(c, silent)
		h, s, v = c:ToHSV()
		render(false, silent)
	end

	for i, c in o.Presets or { win.Accent, Theme.Info, Theme.Danger, Theme.Warn, Color3.fromRGB(180, 140, 255), Color3.new(1, 1, 1) } do
		local p = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = c,
			Size = UDim2.fromOffset(16, 16),
			LayoutOrder = i,
			Parent = presets,
		}, { Corner(4), Stroke(Color3.new(1, 1, 1), 1, 0.9) })
		p.Activated:Connect(function()
			picker:Set(c)
		end)
	end

	win:Track(sv, function(x, y)
		if x then
			s, v = x, 1 - y
			render()
		end
	end)
	win:Track(hue, function(x)
		if x then
			h = math.min(x, 0.999)
			render()
		end
	end)
	box.Focused:Connect(function()
		Tween(boxStroke, 0.15, { Color = win.Accent })
	end)
	box.FocusLost:Connect(function()
		Tween(boxStroke, 0.15, { Color = Theme.Line2 })
		local text = box.Text:gsub("#", "")
		if #text == 6 and text:match("^%x+$") then
			h, s, v = Color3.fromHex(text):ToHSV()
			render(true)
		else
			box.Text = hex.Text
		end
	end)
	head.Activated:Connect(function()
		fold:Set(not fold.Open)
	end)

	render(false, true)
	return picker
end

function LayerLib:Destroy()
	for _, c in self.Connections do
		c:Disconnect()
	end
	self.Gui:Destroy()
end

return LayerLib
