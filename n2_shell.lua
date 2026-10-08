-- =====================================================================
-- LumuUI TopBar  --  LIBRARY ONLY (running this alone shows NOTHING).
--
-- Use it from your hub script:
--   local Astral = loadstring(game:HttpGet("URL/LumuUI_TopBar_Lib.lua"))()
--   local Icons  = loadstring(game:HttpGet("URL/icons_sprites.lua"))()
--   Astral:RegisterIcons(Icons)
--   local Window = Astral:CreateWindow({ Title = "My Hub" })
--   local Tab = Window:MakeTab({"Main", "star"})
--   Tab:AddButton({ Title = "Hi", Callback = function() end })
--
-- To just LOOK at the design, run LumuUI_TopBar.lua instead.
-- =====================================================================
-- Client Script (Place in StarterPlayerScripts or StarterGui)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait()
	LocalPlayer = Players.LocalPlayer
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Dynamic Device Detection
local IsMobile = false
-- Emulator / cloud phone: touch but no accelerometer (phones have one, PCs/laptops don't have touch)
local IsEmulator = false
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
if UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or Camera.ViewportSize.X < 900) then
	IsMobile = true
end
pcall(function()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.AccelerometerEnabled then
		IsEmulator = true
	end
end)

-- Mobile text scaler: call mTS(label, normalSize) to auto-shrink on mobile
local function mTS(label, normalSize)
	if IsMobile then
		label.TextSize = math.max(8, normalSize - 2)
	else
		label.TextSize = normalSize
	end
end

-- Define the Astral Library
local Astral = {}
Astral.Registry = {} -- Global registry to track all toggle/tick controllers for easy resetting

-- =========================================================================
-- LANGUAGE / TRANSLATION SYSTEM
-- Titles registered with tr() swap instantly via Astral:SetLanguage().
-- Add your own: Astral:AddTranslations("Italiano", { ["Settings"] = "Impostazioni" })
-- =========================================================================
Astral.Languages = { English = {} }
Astral.CurrentLanguage = "English"
local translatableLabels = {}
local languageRefreshers = {} -- fn() list re-run on SetLanguage (dynamic texts)

local function translateText(key)
	local lang = Astral.Languages[Astral.CurrentLanguage]
	if lang and lang[key] ~= nil and lang[key] ~= "" then
		return lang[key]
	end
	return key
end

-- GET with fallbacks: some executors block game:HttpGet for certain hosts,
-- so try the executor request functions and HttpService before giving up.
local function webGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and type(res) == "string" and res ~= "" then return res end
	local req = (typeof(request) == "function" and request)
		or (typeof(http_request) == "function" and http_request)
		or (syn and type(syn.request) == "function" and syn.request)
		or nil
	if req then
		local ok2, r = pcall(function() return req({Url = url, Method = "GET"}) end)
		if ok2 then
			if type(r) == "table" then
				local body = r.Body or r.body
				if type(body) == "string" and body ~= "" then return body end
			elseif type(r) == "string" and r ~= "" then
				return r
			end
		end
	end
	local ok3, res3 = pcall(function() return HttpService:GetAsync(url) end)
	if ok3 and type(res3) == "string" and res3 ~= "" then return res3 end
	return nil
end

function Astral:AddTranslations(langName, dict)
	if type(langName) ~= "string" or type(dict) ~= "table" then return end
	Astral.Languages[langName] = Astral.Languages[langName] or {}
	for k, v in pairs(dict) do
		Astral.Languages[langName][k] = v
	end
	if Astral.CurrentLanguage == langName then
		Astral:SetLanguage(langName)
	end
end

function Astral:SetLanguage(langName)
	if not Astral.Languages[langName] then return end
	Astral.CurrentLanguage = langName
	for _, item in ipairs(translatableLabels) do
		pcall(function()
			if item.Label and item.Label.Parent then
				item.Label[item.Prop or "Text"] = translateText(item.Key)
			end
		end)
	end
	for _, fn in ipairs(languageRefreshers) do
		pcall(fn)
	end
	pcall(function()
		if Astral._OpenSelectorRefresh then Astral._OpenSelectorRefresh() end
	end)
end

function Astral:GetLanguages()
	local out = {}
	for name in pairs(Astral.Languages) do table.insert(out, name) end
	table.sort(out)
	return out
end

-- Register a label's English text for live translation.
-- Optional prop lets inputs translate other string props too:
-- tr(SearchInput, "Search...", "PlaceholderText")
local function tr(label, englishText, prop)
	table.insert(translatableLabels, {Label = label, Key = englishText, Prop = prop})
	label[prop or "Text"] = translateText(englishText)
	return label
end


-- Starter language packs (titles swap live; add your own words anytime)
Astral:AddTranslations("Espa├▒ol", {
	["Settings"] = "Ajustes",
	["Tests"] = "Pruebas",
	["Farming"] = "Farmeo",
	["Combat"] = "Combate",
	["Dungeons"] = "Mazmorras",
	["Islands"] = "Islas",
	["Players"] = "Jugadores",
	["ESP"] = "ESP",
	["Shop"] = "Tienda",
	["Layout Columns"] = "Columnas",
	["Accent Theme"] = "Tema de acento",
	["Background Image"] = "Imagen de fondo",
	["Load Background"] = "Cargar fondo",
	["Reset Background"] = "Restablecer fondo",
	["Spam Notifications"] = "Notificaciones spam",
	["Spam With Actions"] = "Spam con acciones",
	["Menu Keybind"] = "Tecla de men├║",
	["Status Label"] = "Etiqueta de estado",
	["Select..."] = "Seleccionar...",
	["None"] = "Ninguno",
	["Search..."] = "Buscar...",
	["Select Option"] = "Seleccionar opci├│n",
	["(+%d more)"] = "(+%d m├ís)",
})
Astral:AddTranslations("Fran├ºais", {
	["Settings"] = "Param├¿tres",
	["Tests"] = "Tests",
	["Farming"] = "Farm",
	["Combat"] = "Combat",
	["Dungeons"] = "Donjons",
	["Islands"] = "├Äles",
	["Players"] = "Joueurs",
	["ESP"] = "ESP",
	["Shop"] = "Boutique",
	["Layout Columns"] = "Colonnes",
	["Accent Theme"] = "Couleur d'accent",
	["Background Image"] = "Image de fond",
	["Load Background"] = "Charger le fond",
	["Reset Background"] = "R├⌐initialiser le fond",
	["Spam Notifications"] = "Notifications spam",
	["Spam With Actions"] = "Spam avec actions",
	["Menu Keybind"] = "Touche du menu",
	["Status Label"] = "├ëtiquette de statut",
	["Select..."] = "S├⌐lectionner...",
	["None"] = "Aucun",
	["Search..."] = "Rechercher...",
	["Select Option"] = "Choisir une option",
	["(+%d more)"] = "(+%d autres)",
})
Astral:AddTranslations("Deutsch", {
	["Settings"] = "Einstellungen",
	["Tests"] = "Tests",
	["Farming"] = "Farmen",
	["Combat"] = "Kampf",
	["Dungeons"] = "Dungeons",
	["Islands"] = "Inseln",
	["Players"] = "Spieler",
	["ESP"] = "ESP",
	["Shop"] = "Shop",
	["Layout Columns"] = "Spalten",
	["Accent Theme"] = "Akzentfarbe",
	["Background Image"] = "Hintergrundbild",
	["Load Background"] = "Hintergrund laden",
	["Reset Background"] = "Hintergrund zur├╝cksetzen",
	["Spam Notifications"] = "Spam-Benachrichtigungen",
	["Spam With Actions"] = "Spam mit Aktionen",
	["Menu Keybind"] = "Men├╝taste",
	["Status Label"] = "Statusanzeige",
	["Select..."] = "Ausw├ñhlen...",
	["None"] = "Keine",
	["Search..."] = "Suchen...",
	["Select Option"] = "Option w├ñhlen",
	["(+%d more)"] = "(+%d weitere)",
})

-- Custom languages: built live in the Translation tab, saved as
-- lumu_lang_<Name>.json, auto-loaded here on next execute.
local function langFileName(name)
	return "lumu_lang_" .. tostring(name):gsub("[^%w_%- ]", "") .. ".json"
end

function Astral.DeleteLanguage(langName)
	if langName == "English" or not Astral.Languages[langName] then return false end
	Astral.Languages[langName] = nil
	if Astral.CurrentLanguage == langName then Astral:SetLanguage("English") end
	pcall(function() if delfile then delfile(langFileName(langName)) end end)
	return true
end

function Astral.SaveLanguage(langName)
	local dict = Astral.Languages[langName]
	if not dict or not writefile then return false end
	local ok = pcall(function()
		writefile(langFileName(langName), game:GetService("HttpService"):JSONEncode({ name = langName, words = dict }))
	end)
	return ok
end

function Astral.CountWords(langName)
	local dict = Astral.Languages[langName]
	if not dict then return 0 end
	local n = 0
	for _ in pairs(dict) do n = n + 1 end
	return n
end

do
	local ok, files = pcall(function() return (listfiles and listfiles("")) or {} end)
	if ok and type(files) == "table" then
		for _, f in ipairs(files) do
			if type(f) == "string" then
				local short = f:match("([^/\\]+)$") or f
				if short:match("^lumu_lang_.*%.json$") then
					pcall(function()
						local data = game:GetService("HttpService"):JSONDecode(readfile(f))
						if type(data) == "table" and type(data.words) == "table" then
							local nm = (type(data.name) == "string" and data.name ~= "") and data.name or short:match("^lumu_lang_(.*)%.json$")
							if nm then Astral:AddTranslations(nm, data.words) end
						end
					end)
				end
			end
		end
	end
end


-- Comprehensive Icon Dictionary
Astral.Icons = {
	Heart = "rbxassetid://10747374161", -- Globe/Home
	Item2 = "rbxassetid://83885110042385",
	Item3 = "rbxassetid://121905143697738",
	Item1 = "rbxassetid://122773160656447",
	SecondRewardIcon = "rbxassetid://80697366195466",
	Icon1 = "rbxassetid://106987676739927", -- Updated to requested custom logo ID
	Icon2 = "rbxassetid://116815022926368",
	CornerIcon = "rbxassetid://79361588247465",
	Icon3 = "rbxassetid://82358876994773",
	Sharingan1 = "rbxassetid://94044166423780",
	Image1 = "rbxassetid://119695090236661",
	Checkmark = "rbxassetid://12690727184", -- Updated to requested high-contrast checkmark ID
	Image2 = "rbxassetid://122758809551453",
	Close = "rbxassetid://9545003266",
	ImageLabel1 = "rbxassetid://102323672270607",
	ImageLabel2 = "rbxassetid://95040139882837",
	Icon4 = "rbxassetid://85596845927296",
	Icon5 = "rbxassetid://82328117903546",
	Icon6 = "rbxassetid://135148380892747",
	Icon7 = "rbxassetid://5642383285",
	CheckMark2 = "rbxassetid://72382658",
	QuestionMark = "rbxassetid://11961524728",
	htobar = "rbxassetid://75920759124629",
	timer = "rbxassetid://85881110920588",
	Left = "rbxassetid://96304569438872",
	Right = "rbxassetid://86166619745789",
	clock = "rbxassetid://85874026506238",
	lock = "rbxassetid://9191129676",
	Warning = "rbxassetid://7020209324",
	limit_timer = "rbxassetid://103916574484749",
	setting_ImageLabel = "rbxassetid://91616785719644",
	steering = "rbxassetid://110862082646630",
	loop_ImageLabel = "rbxassetid://82533346971856",
	hotbar_MenuButton = "rbxassetid://15481302234",
	menu_ImageLabel = "rbxassetid://107573955108045",
	ArrowOnly1 = "rbxassetid://2418686949",
	bookImageLabel = "rbxassetid://17583283314",
	chest = "rbxassetid://122154715897842",
	dungeonIcon = "rbxassetid://116834446841692",
		search = "rbxassetid://127006564692803",
		Home = "http://www.roblox.com/asset/?id=9735074448",
		Players = "rbxassetid://3025004395",
	fishing = "rbxassetid://120325871278964",
	brush = "rbxassetid://138999635884744",
	wood = "rbxassetid://17218778623",
	fragment_chest = "rbxassetid://112630312321366",
	guide_icon = "rbxassetid://80151381605349",
	map_background = "rbxassetid://91526381633533",
	up_arrow = "rbxassetid://124289284437143",
	red_key = "rbxassetid://17284014170",
	white_key = "rbxassetid://17284010749",
	yellow_key = "rbxassetid://17284012231",
	green_key = "rbxassetid://17284010015",
	blue_key = "rbxassetid://17284013433",
	eye = "rbxassetid://94513760125394",
	CrewLabel = "rbxassetid://15432293683",
	star = "rbxassetid://9117240799",
	CoinImage = "rbxassetid://119281955127934",
	GemImage = "rbxassetid://107516022193931",
	down_arrow = "rbxassetid://104073699674984",
	redo = "rbxassetid://112477956812302",
	dungeonPlaceholder = "rbxassetid://120906706443458",
	clickImageLabel = "rbxassetid://7553620727",
	right_arrow = "rbxassetid://121627513213989",
	tick = "rbxassetid://12690727184",
	InletTexture = "rbxassetid://103642499084798",
	expand = "rbxassetid://112339867431014",
	WheelFrame = "rbxassetid://79705976294216",
	ARROW_down_IMAGE = "rbxassetid://103256317191387",
	big_arrow_down = "rbxassetid://119090403860693",
	left_arrow = "rbxassetid://16734567969",
	arrow_down_button = "rbxassetid://79129710719196",
	bag_of_gold = "rbxassetid://75914651028344",
	chest_of_coin = "rbxassetid://78240658157818",
	EggBasket = "rbxassetid://97411136647622",
	egg_blue_pink = "rbxassetid://77129460699853",
	egg_yellow_skyblue = "rbxassetid://95450973493720",
	purple_blue_egg = "rbxassetid://90597623492830",
	keyboard = "rbxassetid://11385220720",
	rain = "rbxassetid://105238830795121",
	volcano = "rbxassetid://119080201393061",
	meteor = "rbxassetid://71134947880058",
	x_ImageLabel = "rbxassetid://14219436180",
	quest = "rbxassetid://18838050505",
	MarkImage = "rbxassetid://18838050505",
	Money = "rbxassetid://86689630920385",
	candy = "rbxassetid://96106029532916",
	EXP = "rbxassetid://116312601353770",
	fish = "rbxassetid://106871355874368",
	click_icon = "rbxassetid://9468220156",
	shopping = "rbxassetid://11699823846"
}

-- Helper function to parse icons safely (strings AND sprite tables pass through)
local function parseIcon(iconInput)
	if not iconInput then return nil end
	if type(iconInput) == "table" then
		return iconInput
	end
	if type(iconInput) == "string" then
		if Astral.Icons[iconInput] then
			return Astral.Icons[iconInput]
		elseif string.match(iconInput, "^%d+$") then
			return "rbxassetid://" .. iconInput
		elseif string.sub(iconInput, 1, 13) == "rbxassetid://" or string.sub(iconInput, 1, 4) == "http" then
			return iconInput
		end
	elseif type(iconInput) == "number" then
		return "rbxassetid://" .. tostring(iconInput)
	end
	return nil
end

-- Icon module hookup: merge an external table (icons_sprites.lua).
-- Built-ins above keep working standalone; registered sprites override/add.
function Astral:RegisterIcons(dict)
	if type(dict) ~= "table" then return end
	for k, v in pairs(dict) do Astral.Icons[k] = v end
end

-- Applies a plain asset string OR a sprite table {Image, ImageRectOffset, ImageRectSize}
function Astral.ApplyIcon(label, icon)
	if type(icon) == "table" then
		label.Image = icon.Image or ""
		label.ImageRectOffset = icon.ImageRectOffset or Vector2.new(0, 0)
		label.ImageRectSize = icon.ImageRectSize or Vector2.new(0, 0)
	else
		label.Image = icon or ""
		label.ImageRectOffset = Vector2.new(0, 0)
		label.ImageRectSize = Vector2.new(0, 0)
	end
end

-- High-Performance, Lag-Free Dragging Utility
local function makeElementDraggable(guiObject, dragHandle)
	dragHandle = dragHandle or guiObject
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(
			startPos.X.Scale, 
			startPos.X.Offset + delta.X, 
			startPos.Y.Scale, 
			startPos.Y.Offset + delta.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			-- yield if the Game Status panel grabbed this same press (it sits above)
			local okS, sT = pcall(function() return guiObject:GetAttribute("StatusDragT") end)
			if okS and sT and os.clock() - sT < 0.3 then return end
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			pcall(function() guiObject:SetAttribute("MainDragT", os.clock()) end)

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			-- abort mid-press if the status panel grabbed after us
			local okS, sT = pcall(function() return guiObject:GetAttribute("StatusDragT") end)
			local okM, mT = pcall(function() return guiObject:GetAttribute("MainDragT") end)
			if okS and okM and sT and mT and sT > mT then dragging = false; return end
			update(input)
		end
	end)
end

-- Helper to register clean clicks on draggable buttons
-- Touch gets a bigger drag allowance so scrolling never misfires as taps
local function registerClick(button, callback)
	local startPos
	local startType
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startPos = UserInputService:GetMouseLocation()
			startType = input.UserInputType
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if startPos then
				local endPos = UserInputService:GetMouseLocation()
				local slop = (startType == Enum.UserInputType.Touch) and 24 or 8
				if (endPos - startPos).Magnitude < slop then
					callback()
				end
			end
			startPos = nil
		end
	end)
end

-- Helper to calculate relative position inside a GUI element
local function getRelativePosition(guiObject, input)
	local absPos = guiObject.AbsolutePosition
	local absSize = guiObject.AbsoluteSize
	local inputPos = input.Position
	local relX = (inputPos.X - absPos.X) / absSize.X
	local relY = (inputPos.Y - absPos.Y) / absSize.Y
	return math.clamp(relX, 0, 1), math.clamp(relY, 0, 1)
end

-- ============================================================================
-- ============================================================================
-- THEMES: Dark (default build) / Light / Midnight.
-- Window:SetTheme(name) recolors every surface + text by value.
-- Anything currently bound to the accent color is left untouched.
-- Index: 1 = Light, 2 = Midnight (0 = Dark = the source keys themselves).
-- ============================================================================
local THEME_SWAP = {
	["100,100,105"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["110,110,118"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["12,12,14"] = { "5,7,15", "14,8,22", "18,8,10", "7,17,9", "6,15,19", "19,12,6", "19,8,15", "11,13,19", "15,11,7" },
	["120,120,125"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["15,15,15"] = { "8,11,20", "16,10,26", "20,9,10", "8,19,9", "7,17,21", "21,14,7", "22,9,17", "13,15,22", "17,12,8" },
	["150,150,158"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["16,16,18"] = { "8,11,21", "18,11,28", "27,13,15", "12,26,13", "10,25,29", "29,20,11", "29,13,22", "22,25,35", "24,18,12" },
	["160,160,165"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["162,162,172"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["165,165,176"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["170,170,178"] = { "158,170,200", "190,180,215", "215,185,185", "185,215,185", "180,210,220", "220,200,180", "220,190,210", "190,200,220", "215,195,175" },
	["175,175,182"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["18,18,22"] = { "9,12,23", "17,11,27", "25,12,14", "10,24,12", "9,23,27", "27,18,10", "27,12,20", "20,23,32", "22,16,11" },
	["180,180,185"] = { "148,160,190", "185,175,210", "210,180,180", "180,210,180", "175,205,215", "215,195,175", "215,185,205", "185,195,215", "210,190,170" },
	["20,20,24"] = { "11,15,27", "20,13,32", "29,14,16", "13,28,14", "11,27,31", "31,22,12", "31,15,24", "24,27,38", "26,19,13" },
	["22,22,26"] = { "13,18,32", "23,15,37", "32,16,18", "15,31,16", "13,30,34", "34,24,14", "34,17,27", "27,30,42", "29,21,15" },
	["255,255,255"] = { "231,237,255", "245,235,255", "255,242,242", "242,255,242", "236,250,255", "255,246,236", "255,242,250", "242,246,254", "253,246,237" },
	["26,26,30"] = { "12,16,29", "22,14,34", "32,15,17", "13,30,15", "11,29,33", "34,23,12", "34,15,25", "25,29,39", "28,20,14" },
	["28,28,34"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["30,30,36"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["32,32,36"] = { "17,23,39", "30,19,46", "42,20,22", "18,40,20", "16,39,43", "44,30,16", "46,20,33", "35,41,55", "38,28,19" },
	["35,35,40"] = { "29,39,63", "48,32,74", "68,33,35", "31,68,34", "28,65,71", "74,50,26", "78,35,59", "60,70,86", "64,47,31" },
	["36,36,40"] = { "25,33,55", "40,26,62", "54,27,29", "24,53,26", "22,51,57", "58,39,23", "60,27,45", "47,55,71", "50,37,25" },
	["38,38,44"] = { "28,38,60", "46,32,72", "66,33,35", "30,66,33", "27,63,69", "72,48,26", "76,34,57", "59,68,83", "63,46,31" },
	["45,45,50"] = { "31,43,69", "52,36,80", "72,36,38", "33,72,36", "30,70,76", "78,53,28", "82,37,62", "64,74,90", "68,50,33" },
	["50,50,55"] = { "39,53,83", "64,44,98", "88,44,46", "41,88,44", "37,86,94", "96,65,34", "100,46,76", "80,92,112", "84,62,41" },
	["52,52,60"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["54,54,62"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["70,70,75"] = { "55,70,105", "85,60,130", "115,58,60", "52,108,56", "46,106,118", "122,82,44", "128,58,96", "99,114,141", "107,78,52" },
	["205,205,214"] = { "148,160,190", "185,175,210", "210,180,180", "180,210,180", "175,205,215", "215,195,175", "215,185,205", "185,195,215", "210,190,170" },
	["70,70,80"] = { "55,70,105", "85,60,130", "115,58,60", "52,108,56", "46,106,118", "122,82,44", "128,58,96", "99,114,141", "107,78,52" },	["33,33,39"] = { "12,16,29", "22,14,34", "32,15,17", "13,30,15", "11,29,33", "34,23,12", "34,15,25", "25,29,39", "28,20,14" },
	-- Aliased newer chrome colors (same column family as nearest classic key)
	["120,120,130"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["128,132,142"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["130,130,135"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
	["14,14,16"] = { "8,11,20", "16,10,26", "20,9,10", "8,19,9", "7,17,21", "21,14,7", "22,9,17", "13,15,22", "17,12,8" },
	["140,140,145"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["150,150,160"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["16,16,20"] = { "8,11,21", "18,11,28", "27,13,15", "12,26,13", "10,25,29", "29,20,11", "29,13,22", "22,25,35", "24,18,12" },
	["160,160,168"] = { "146,158,188", "180,170,205", "205,175,175", "175,205,175", "170,200,210", "210,190,170", "210,180,200", "180,190,210", "205,185,165" },
	["170,170,180"] = { "158,170,200", "190,180,215", "215,185,185", "185,215,185", "180,210,220", "220,200,180", "220,190,210", "190,200,220", "215,195,175" },
	["18,18,20"] = { "9,12,23", "17,11,27", "25,12,14", "10,24,12", "9,23,27", "27,18,10", "27,12,20", "20,23,32", "22,16,11" },
	["20,20,25"] = { "11,15,27", "20,13,32", "29,14,16", "13,28,14", "11,27,31", "31,22,12", "31,15,24", "24,27,38", "26,19,13" },
	["20,20,26"] = { "11,15,27", "20,13,32", "29,14,16", "13,28,14", "11,27,31", "31,22,12", "31,15,24", "24,27,38", "26,19,13" },
	["200,200,208"] = { "148,160,190", "185,175,210", "210,180,180", "180,210,180", "175,205,215", "215,195,175", "215,185,205", "185,195,215", "210,190,170" },
	["220,220,228"] = { "148,160,190", "185,175,210", "210,180,180", "180,210,180", "175,205,215", "215,195,175", "215,185,205", "185,195,215", "210,190,170" },
	["232,232,237"] = { "231,237,255", "245,235,255", "255,242,242", "242,255,242", "236,250,255", "255,246,236", "255,242,250", "242,246,254", "253,246,237" },
	["240,240,245"] = { "231,237,255", "245,235,255", "255,242,242", "242,255,242", "236,250,255", "255,246,236", "255,242,250", "242,246,254", "253,246,237" },
	["24,24,29"] = { "12,16,29", "22,14,34", "32,15,17", "13,30,15", "11,29,33", "34,23,12", "34,15,25", "25,29,39", "28,20,14" },
	["24,24,30"] = { "12,16,29", "22,14,34", "32,15,17", "13,30,15", "11,29,33", "34,23,12", "34,15,25", "25,29,39", "28,20,14" },
	["28,28,35"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["30,30,37"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["30,30,38"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["32,32,34"] = { "19,25,43", "32,20,50", "44,21,23", "19,43,21", "17,41,45", "46,31,17", "48,21,35", "37,43,57", "40,29,20" },
	["32,32,40"] = { "12,16,29", "22,14,34", "32,15,17", "13,30,15", "11,29,33", "34,23,12", "34,15,25", "25,29,39", "28,20,14" },
	["34,34,40"] = { "29,39,63", "48,32,74", "68,33,35", "31,68,34", "28,65,71", "74,50,26", "78,35,59", "60,70,86", "64,47,31" },
	["37,37,45"] = { "28,38,60", "46,32,72", "66,33,35", "30,66,33", "27,63,69", "72,48,26", "76,34,57", "59,68,83", "63,46,31" },
	["38,38,50"] = { "28,38,60", "46,32,72", "66,33,35", "30,66,33", "27,63,69", "72,48,26", "76,34,57", "59,68,83", "63,46,31" },
	["40,40,46"] = { "28,38,60", "46,32,72", "66,33,35", "30,66,33", "27,63,69", "72,48,26", "76,34,57", "59,68,83", "63,46,31" },
	["40,40,48"] = { "28,38,60", "46,32,72", "66,33,35", "30,66,33", "27,63,69", "72,48,26", "76,34,57", "59,68,83", "63,46,31" },
	["40,40,50"] = { "31,43,69", "52,36,80", "72,36,38", "33,72,36", "30,70,76", "78,53,28", "82,37,62", "64,74,90", "68,50,33" },
	["42,42,46"] = { "31,43,69", "52,36,80", "72,36,38", "33,72,36", "30,70,76", "78,53,28", "82,37,62", "64,74,90", "68,50,33" },
	["42,42,50"] = { "31,43,69", "52,36,80", "72,36,38", "33,72,36", "30,70,76", "78,53,28", "82,37,62", "64,74,90", "68,50,33" },
	["45,45,52"] = { "31,43,69", "52,36,80", "72,36,38", "33,72,36", "30,70,76", "78,53,28", "82,37,62", "64,74,90", "68,50,33" },
	["48,48,58"] = { "39,53,83", "64,44,98", "88,44,46", "41,88,44", "37,86,94", "96,65,34", "100,46,76", "80,92,112", "84,62,41" },
	["52,52,56"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["54,54,64"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["55,55,60"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["55,55,65"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["58,58,64"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["58,58,66"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["60,60,70"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["60,60,72"] = { "36,48,76", "58,40,90", "80,40,42", "37,80,40", "33,77,85", "88,59,32", "92,42,69", "71,82,101", "77,56,38" },
	["62,62,72"] = { "55,70,105", "85,60,130", "115,58,60", "52,108,56", "46,106,118", "122,82,44", "128,58,96", "99,114,141", "107,78,52" },
	["80,80,90"] = { "55,70,105", "85,60,130", "115,58,60", "52,108,56", "46,106,118", "122,82,44", "128,58,96", "99,114,141", "107,78,52" },
	["95,95,110"] = { "118,130,163", "150,140,175", "165,145,145", "145,165,145", "140,165,180", "170,155,140", "170,150,165", "150,160,185", "165,150,130" },
}
local THEME_INDEX = { Dark = 0, Midnight = 1, Purple = 2, Crimson = 3, Forest = 4, Ocean = 5, Sunset = 6, Rose = 7, Slate = 8, Coffee = 9, Custom = -1 }
local THEME_ACCENT = {
	Dark = Color3.fromRGB(0, 153, 235),
	Midnight = Color3.fromRGB(88, 101, 242),
	Purple = Color3.fromRGB(138, 90, 255),
	Crimson = Color3.fromRGB(231, 76, 60),
	Forest = Color3.fromRGB(46, 204, 113),
	Ocean = Color3.fromRGB(0, 210, 255),
	Sunset = Color3.fromRGB(243, 156, 18),
	Rose = Color3.fromRGB(255, 90, 180),
	Slate = Color3.fromRGB(148, 170, 200),
	Coffee = Color3.fromRGB(210, 170, 90),
}
local CustomThemeValues = nil -- darkKey -> "r,g,b" string, built by SetCustomTheme
local CurrentThemeName = "Dark" -- global fallback for chrome built before Window exists

local function parseThemeRGB(s)
	-- accepts both "r,g,b" strings and raw Color3 values (CustomThemeValues stores Color3)
	if typeof(s) == "Color3" then return s end
	local str = tostring(s or "")
	local r, g, b = string.match(str, "^(%d+),(%d+),(%d+)$")
	return Color3.fromRGB(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0)
end

	local function lightVariantOf(darkKey)
		local dc = parseThemeRGB(darkKey)
		local avg = (dc.R + dc.G + dc.B) / 3
		if avg < 0.25 then
			local f = 0.9
			return Color3.new(dc.R + (1 - dc.R) * f, dc.G + (1 - dc.G) * f, dc.B + (1 - dc.B) * f)
		elseif avg < 0.5 then
			local f = 0.55
			return Color3.new(dc.R + (1 - dc.R) * f, dc.G + (1 - dc.G) * f, dc.B + (1 - dc.B) * f)
		elseif avg > 0.8 then
			return Color3.new(dc.R * 0.14, dc.G * 0.14, dc.B * 0.14)
		else
			return Color3.new(dc.R * 0.5, dc.G * 0.5, dc.B * 0.5)
		end
	end

	local function themeKeyOf(c)
	return math.floor(c.R * 255 + 0.5) .. "," .. math.floor(c.G * 255 + 0.5) .. "," .. math.floor(c.B * 255 + 0.5)
end

-- File-scope theme applier (kept out of MakeWindow to respect the 200-local limit).
-- Returns the new theme name on success, nil on failure.
	local function applyThemeToGui(screenGui, accentColor, fromName, toName)
	local target = THEME_INDEX[toName]
	if target == nil then return nil end
	local current = THEME_INDEX[fromName] or 0
	if target == current then return toName end

	local function valFor(srcKey, idx)
		if idx == 0 then return parseThemeRGB(srcKey) end
		if idx == 10 then return lightVariantOf(srcKey) end
		if idx == -1 then
			if CustomThemeValues and CustomThemeValues[srcKey] then return parseThemeRGB(CustomThemeValues[srcKey]) end
			return parseThemeRGB(srcKey)
		end
		local pair = THEME_SWAP[srcKey]
		if not pair then return nil end
		return parseThemeRGB(pair[idx])
	end

	-- Map EVERY known variant to the target, so elements built under any
	-- theme (or hardcoded dark) all land correctly on switch.
	local remap = {}
	local function mapVariant(srcKey, idx)
		local oldC = valFor(srcKey, idx)
		local newC = valFor(srcKey, target)
		if oldC and newC then remap[themeKeyOf(oldC)] = newC end
	end
	for srcKey in pairs(THEME_SWAP) do
		mapVariant(srcKey, 0)
		for idx = 1, 9 do mapVariant(srcKey, idx) end
		mapVariant(srcKey, -1)
	end
	if CustomThemeValues then
		for srcKey, v in pairs(CustomThemeValues) do
			local oldC = parseThemeRGB(v)
			local newC = valFor(srcKey, target)
			if oldC and newC then remap[themeKeyOf(oldC)] = newC end
		end
	end

	local accentKey = themeKeyOf(accentColor)

	local function swapProp(obj, prop, allowWhite)
		local ok, val = pcall(function() return obj[prop] end)
		if not ok or typeof(val) ~= "Color3" then return end
		local key = themeKeyOf(val)
		if key == accentKey then return end
		if not allowWhite and key == "255,255,255" then return end
		local to = remap[key]
		if to then pcall(function() obj[prop] = to end) end
	end

	local function swapGradient(grad)
		local ok, seq = pcall(function() return grad.Color end)
		if not ok or not seq then return end
		local kps = nil
		pcall(function() kps = seq.Keypoints end)
		if not kps then return end
		local out = {}
		local changed = false
		for _, kp in ipairs(kps) do
			local key = themeKeyOf(kp.Value)
			local to = (key ~= accentKey) and remap[key] or nil
			if to then
				out[#out + 1] = ColorSequenceKeypoint.new(kp.Time, to)
				changed = true
			else
				out[#out + 1] = kp
			end
		end
		if changed then pcall(function() grad.Color = ColorSequence.new(out) end) end
	end

	local function processOne(d)
		if d:IsA("GuiObject") then
			swapProp(d, "BackgroundColor3", false)
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				swapProp(d, "TextColor3", true)
				swapProp(d, "PlaceholderColor3", true)
			elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
				swapProp(d, "ImageColor3", true)
			elseif d:IsA("ScrollingFrame") then
				swapProp(d, "ScrollBarImageColor3", false)
			end
		elseif d:IsA("UIStroke") then
			swapProp(d, "Color", true)
		elseif d:IsA("UIGradient") then
			swapGradient(d)
		end
	end
	pcall(function() processOne(screenGui) end)
	for _, d in ipairs(screenGui:GetDescendants()) do
		processOne(d)
	end

	return toName
end

-- Live hover helpers: evaluated when a hover FIRES, so they always match
-- the current theme. Use these instead of hardcoded dark literals.
local function themeColorFor(darkKey, t)
	if t == "Dark" or not t then return parseThemeRGB(darkKey) end
	local idx = THEME_INDEX[t]
	if idx == -1 then
		if CustomThemeValues and CustomThemeValues[darkKey] then
			return parseThemeRGB(CustomThemeValues[darkKey])
		end
		return parseThemeRGB(darkKey)
	end
	if not idx or idx == 0 then return parseThemeRGB(darkKey) end
	if idx == 10 then return lightVariantOf(darkKey) end
	local pair = THEME_SWAP[darkKey]
	if not pair then return parseThemeRGB(darkKey) end
	return parseThemeRGB(pair[idx])
end

local function themeCardBG(t) return themeColorFor("26,26,30", t) end
local function themeHoverBG(t) return themeColorFor("36,36,40", t) end
local function themeStroke(t) return themeColorFor("50,50,55", t) end
local function themeStrokeHover(t) return themeColorFor("70,70,75", t) end

local function getGuiParent()
	-- executors: hidden UI container (CoreGui area); otherwise PlayerGui
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	return PlayerGui
end

local function makeGuiName(base)
	local suffix = ""
	pcall(function() suffix = "_" .. tostring(math.random(100000000, 999999999)) end)
	return base .. suffix
end

local UIPOS_FILE = "lumu_ui_pos.json"

local function saveUIPosFile(name, data)
	if not writefile then return false end
	local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
	if not ok then return false end
	local okW = pcall(writefile, name or UIPOS_FILE, json)
	return okW
end

local function loadUIPosFile(name)
	if not (readfile and isfile) then return nil end
	local fname = name or UIPOS_FILE
	local okE = false
	pcall(function() okE = isfile(fname) end)
	if not okE then return nil end
	local okR, raw = pcall(readfile, fname)
	if not okR or not raw or raw == "" then return nil end
	local okJ, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	if not okJ or type(data) ~= "table" then return nil end
	return data
end

local function udimToTable(u)
	if typeof(u) ~= "UDim2" and (not u or not u.X) then return nil end
	return { sX = u.X.Scale, oX = u.X.Offset, sY = u.Y.Scale, oY = u.Y.Offset }
end

local function tableToUdim(t)
	if type(t) ~= "table" then return nil end
	return UDim2.new(tonumber(t.sX) or 0, tonumber(t.oX) or 0, tonumber(t.sY) or 0, tonumber(t.oY) or 0)
end

local function clampPanelOnScreen(pos, w, hEst)
	local cam = workspace.CurrentCamera
	if not cam then return pos end
	local vp = cam.ViewportSize
	if not vp or vp.X < 10 then return pos end
	local x = pos.X.Scale * vp.X + pos.X.Offset
	local y = pos.Y.Scale * vp.Y + pos.Y.Offset
	x = math.clamp(x, 8, math.max(8, vp.X - (w or 280) - 8))
	y = math.clamp(y, 8, math.max(8, vp.Y - (hEst or 220) - 8))
	return UDim2.new(0, x, 0, y)
end
local LUMU_RAW = "https://raw.githubusercontent.com/velaricX/fghfkgjshdhsk/main/"
local DESIGN_URLS = {
	TopBar = LUMU_RAW .. "LumuHubTopbar.lua",
	Sidebar = LUMU_RAW .. "LumuHubSidebar.lua",
}
local DESIGN_FILE = "lumu_design.json"
local function readDesignPref()
	if not (readfile and isfile) then return nil end
	local okE = false
	pcall(function() okE = isfile(DESIGN_FILE) end)
	if not okE then return nil end
	local okR, raw = pcall(readfile, DESIGN_FILE)
	if not okR or not raw or raw == "" then return nil end
	local okJ, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	if okJ and type(data) == "table" and type(data.design) == "string" then return data.design end
	local txt = tostring(raw):gsub("%s", "")
	if txt == "Sidebar" or txt == "TopBar" then return txt end
	return nil
end

local function writeDesignPref(design)
	if not writefile then return false end
	local ok = pcall(function()
		writefile(DESIGN_FILE, game:GetService("HttpService"):JSONEncode({ design = design }))
	end)
	return ok
end

function Astral.GetSavedDesign()
	return readDesignPref()
end

function Astral.SetSavedDesign(design)
	if design ~= "Sidebar" and design ~= "TopBar" then return false end
	return writeDesignPref(design)
end

Astral._DesignCache = {}

function Astral:MakeWindow(config)
	config = config or {}
	-- Accent engine FIRST: panels and elements below hook into it during build
	local AccentColor = Color3.fromRGB(0, 153, 235)
	local accentAppliers = {}
	local function onAccentChange(fn)
		table.insert(accentAppliers, fn)
		pcall(fn, AccentColor)
	end
	local titleText = config.Title or "Astral"
	local subTitleText = config.SubTitle or "Hub"
	local badgeText = config.badge or "PREMIUM"
	
	-- Parse Badge Color
	local badgeColor = themeColorFor("30,110,230", CurrentThemeName or "Dark")
	if config.badgecolor then
		if type(config.badgecolor) == "string" then
			if config.badgecolor:lower() == "blue" then
				badgeColor = themeColorFor("30,110,230", CurrentThemeName or "Dark")
			elseif config.badgecolor:lower() == "red" then
				badgeColor = themeColorFor("230,50,50", CurrentThemeName or "Dark")
			elseif config.badgecolor:lower() == "green" then
				badgeColor = themeColorFor("50,230,50", CurrentThemeName or "Dark")
			end
		elseif typeof(config.badgecolor) == "Color3" then
			badgeColor = config.badgecolor
		end
	end

	-- Kill orphaned LumuHub GUIs first (re-execute / design-switch leftovers).
	-- gethui() is invisible to normal wipe code, so without this the old
	-- GameStatus panel stays alive UNDER the new one and its gray edges
	-- stick out at the corners.
	pcall(function()
		local parent = getGuiParent()
		if parent then
			for _, g in ipairs(parent:GetChildren()) do
				if g:IsA("ScreenGui") and g.Name:match("^LumuHubMain") then
					pcall(function() g:Destroy() end)
				end
			end
		end
	end)

	-- Create ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = makeGuiName("LumuHubMain")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = getGuiParent()


	-- Notification Container (Bottom-Right of Screen, copied from main UI)
	local notifW = config.NotifySize or (IsMobile
		and math.min(170, math.floor((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 760) * 0.42))
		or math.min(258, math.floor((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 760) * 0.28)))

	local NotificationContainer = Instance.new("Frame")
	NotificationContainer.Name = "NotificationContainer"
	NotificationContainer.Size = UDim2.new(0, notifW + 20, 0, 0)
	NotificationContainer.Position = UDim2.new(1, -12, 1, -12)
	NotificationContainer.AnchorPoint = Vector2.new(1, 1)
	NotificationContainer.BackgroundTransparency = 1
	NotificationContainer.ZIndex = 200
	NotificationContainer.Parent = ScreenGui

	local NotifLayout = Instance.new("UIListLayout")
	NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotifLayout.Padding = UDim.new(0, 8)
	NotifLayout.Parent = NotificationContainer

	-- Main Frame (Responsive Sizing for Mobile & PC)
	local MainFrame = Instance.new("Frame")
	local statusPanels = {}
	local defaultMainPos = UDim2.new(0.5, 15, 0.5, -4)
	local defaultLogoPos = nil
	MainFrame.Name = "MainFrame"
	MainFrame.Active = true
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = themeColorFor("12,12,14", CurrentThemeName or "Dark")
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true -- Fixes corner clipping perfectly
	
	-- Fixed sizes: big on PC (880x600), 550x400 on mobile. Never scaled down,
	-- only clamped to the viewport so nothing clips. Text stays full-size = readable.
	local refW, refH = 880, 600
	if IsMobile then refW, refH = 480, 360 end
	if IsEmulator then refW, refH = 440, 340 end -- emulator/cloud phone: bit smaller than mobile
	if config.Size then
		refW, refH = config.Size.X.Offset, config.Size.Y.Offset
	end
	-- Compact text for narrow windows: titles/descs shrink 1px so full names fit
	local compactTexts = {}
	local function regText(label, normalSize)
		table.insert(compactTexts, {Label = label, Base = normalSize})
		label.TextSize = normalSize
	end
	local function applyTextSize()
		local w = MainFrame.AbsoluteSize.X
		local compact = false -- full-size text everywhere (shrinking hurt readability)
		for _, item in ipairs(compactTexts) do
			pcall(function()
				if item.Label and item.Label.Parent then
					item.Label.TextSize = compact and math.max(8, item.Base - 1) or item.Base
				end
			end)
		end
	end
	local function updateWindowSize()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vps = cam.ViewportSize
		if vps.X < 10 or vps.Y < 10 then return end
		local w = math.min(refW, vps.X - 16)
		local h = math.min(refH, vps.Y - 16)
		if w < 200 or h < 140 then return end
		MainFrame.Size = UDim2.new(0, w, 0, h)
		MainFrame.Position = UDim2.new(0.5, 15, 0.5, -4)
		applyTextSize()
	end
	MainFrame.Size = UDim2.new(0, refW, 0, refH)
	MainFrame.Position = UDim2.new(0.5, 15, 0.5, -4)
	MainFrame.Parent = ScreenGui
	task.spawn(function()
		local cam = workspace.CurrentCamera
		if cam then updateWindowSize(); cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateWindowSize)
		else local conn; conn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() cam=workspace.CurrentCamera; if cam then conn:Disconnect(); updateWindowSize(); cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateWindowSize) end end) end
	end)

	-- Background Image (like other UI) - supports paste link or file astral_bg.jpg
	local BackgroundImage = Instance.new("ImageLabel")
	BackgroundImage.Name = "BackgroundImage"
	BackgroundImage.Size = UDim2.fromScale(1, 1)
	BackgroundImage.Position = UDim2.fromScale(0, 0)
	BackgroundImage.BackgroundTransparency = 1
	BackgroundImage.Image = config.BackgroundImage or ""
	BackgroundImage.ScaleType = Enum.ScaleType.Crop
	BackgroundImage.ImageColor3 = themeColorFor("58,58,64", CurrentThemeName or "Dark")
	BackgroundImage.ZIndex = 0
	BackgroundImage.Parent = MainFrame
	-- no default background: nothing is applied unless you call Window:SetBackground(...) yourself
	local function GetIconOnWeb(url)
		if not url or url == "" then return url end
		local ext = url:match("%.(%w+)$") or "png"
		ext = ext:lower()
		local safe = url:gsub("https?://",""):gsub("[^%w%-_%.]","_")
		local file = safe .. "." .. ext
		if isfile and isfile(file) and getcustomasset then
			local ok, asset = pcall(getcustomasset, file)
			if ok and asset ~= "" then return asset end
		end
		local data=nil
		pcall(function()
			if syn and syn.request then local r=syn.request({Url=url,Method="GET"}); if r.StatusCode==200 then data=r.Body end
			elseif http_request then local r=http_request({Url=url,Method="GET"}); if r.StatusCode==200 then data=r.Body end
			else data=game:HttpGet(url) end
		end)
		if data and #data>0 and writefile then pcall(function() writefile(file,data) end); if isfile(file) and getcustomasset then local ok,a=pcall(getcustomasset,file); if ok and a~="" then return a end end end
		return url
	end
	-- expose for Window API
	local bgFunc = GetIconOnWeb

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = MainFrame
	local BgCorner = Instance.new("UICorner")
	BgCorner.CornerRadius = UDim.new(0, 10)
	BgCorner.Parent = BackgroundImage

	-- Dim overlay so text stays readable over bright photos (image still shows through)
	local BgDim = Instance.new("Frame")
	BgDim.Name = "BackgroundDim"
	BgDim.Size = UDim2.fromScale(1, 1)
	BgDim.Position = UDim2.fromScale(0, 0)
	BgDim.BackgroundColor3 = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	BgDim.BackgroundTransparency = tonumber(config.BackgroundDim) or ((config.BackgroundImage and config.BackgroundImage ~= "") and 0.35 or 1)
	BgDim.BorderSizePixel = 0
	BgDim.ZIndex = 1
	BgDim.Parent = MainFrame

	local BgDimCorner = Instance.new("UICorner")
	BgDimCorner.CornerRadius = UDim.new(0, 10)
	BgDimCorner.Parent = BgDim

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = themeColorFor("32,32,36", CurrentThemeName or "Dark")
	UIStroke.Thickness = 1.5
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = MainFrame

	-- TopBar Frame
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundTransparency = 1
	TopBar.BorderSizePixel = 0
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.Size = UDim2.new(1, 0, 0, 50)
	TopBar.Parent = MainFrame



	-- Horizontal Layout for TopBar Elements
	local HeaderLayoutContainer = Instance.new("Frame")
	HeaderLayoutContainer.Name = "HeaderLayoutContainer"
	HeaderLayoutContainer.BackgroundTransparency = 1
	HeaderLayoutContainer.AnchorPoint = Vector2.new(0, 0.5)
	HeaderLayoutContainer.Position = UDim2.new(0, 12, 0.5, 0)
	HeaderLayoutContainer.Size = UDim2.new(1, -24, 0, 36)
	HeaderLayoutContainer.Parent = TopBar

	local HeaderListLayout = Instance.new("UIListLayout")
	HeaderListLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HeaderListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HeaderListLayout.Padding = UDim.new(0, 10)
	HeaderListLayout.Parent = HeaderLayoutContainer

	-- Title Label (FIXED: Added TextWrapped = false to prevent layout wrapping bugs)
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "TitleLabel"
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(0, 0, 1, 0)
	TitleLabel.AutomaticSize = Enum.AutomaticSize.X
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.RichText = true
	local function accentHex()
		local c = AccentColor
		return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function paintTitle()
		pcall(function()
			TitleLabel.Text = titleText .. ' <font color="#' .. accentHex() .. '">' .. subTitleText .. '</font>'
		end)
	end
	paintTitle()
	onAccentChange(function() paintTitle() end)
	TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	TitleLabel.TextSize = IsMobile and 14 or 18
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
	TitleLabel.TextWrapped = false
	TitleLabel.LayoutOrder = 1
	TitleLabel.Parent = HeaderLayoutContainer

	-- Premium Badge
	local PremiumBadge = Instance.new("Frame")
	PremiumBadge.Name = "PremiumBadge"
	PremiumBadge.BackgroundColor3 = badgeColor
	PremiumBadge.BorderSizePixel = 0
	PremiumBadge.Size = UDim2.new(0, 0, 0, 20)
	PremiumBadge.AutomaticSize = Enum.AutomaticSize.X
	PremiumBadge.LayoutOrder = 2
	PremiumBadge.Parent = HeaderLayoutContainer

	local PremiumCorner = Instance.new("UICorner")
	PremiumCorner.CornerRadius = UDim.new(0, 5)
	PremiumCorner.Parent = PremiumBadge

	local PremiumPadding = Instance.new("UIPadding")
	PremiumPadding.PaddingLeft = UDim.new(0, 8)
	PremiumPadding.PaddingRight = UDim.new(0, 8)
	PremiumPadding.Parent = PremiumBadge

	local PremiumLabel = Instance.new("TextLabel")
	PremiumLabel.Name = "PremiumLabel"
	PremiumLabel.BackgroundTransparency = 1
	PremiumLabel.Size = UDim2.new(1, 0, 1, 0)
	PremiumLabel.Font = Enum.Font.GothamBold
	PremiumLabel.Text = tostring(badgeText):upper()
		PremiumLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	PremiumLabel.TextSize = 9
	PremiumLabel.TextXAlignment = Enum.TextXAlignment.Center
	PremiumLabel.TextYAlignment = Enum.TextYAlignment.Center
	PremiumLabel.Parent = PremiumBadge

	-- Badge follows the accent color unless an explicit badgecolor was given
	if not config.badgecolor then
		onAccentChange(function(c)
			PremiumBadge.BackgroundColor3 = c
		end)
	end

	-- Decorative Alternating Arrows (FIXED: Added TextWrapped = false)
	local DecoArrows = Instance.new("TextLabel")
	DecoArrows.Name = "DecoArrows"
	DecoArrows.BackgroundTransparency = 1
	DecoArrows.Size = UDim2.new(0, 0, 1, 0)
	DecoArrows.AutomaticSize = Enum.AutomaticSize.X
	DecoArrows.Font = Enum.Font.GothamBold
	DecoArrows.RichText = true
	DecoArrows.Text = ""
	local arrowPhase = false
	local function paintArrows()
		pcall(function()
			local a = accentHex()
			local w = "FFFFFF"
			pcall(function()
				local tw = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				w = string.format("%02X%02X%02X", math.floor(tw.R * 255 + 0.5), math.floor(tw.G * 255 + 0.5), math.floor(tw.B * 255 + 0.5))
			end)
			if arrowPhase then
				DecoArrows.Text = '<font color="#' .. w .. '">&gt;&gt;</font> <font color="#' .. a .. '">&gt;&gt;</font> <font color="#' .. w .. '">&gt;&gt;</font> <font color="#' .. a .. '">&gt;&gt;</font>'
			else
				DecoArrows.Text = '<font color="#' .. a .. '">&gt;&gt;</font> <font color="#' .. w .. '">&gt;&gt;</font> <font color="#' .. a .. '">&gt;&gt;</font> <font color="#' .. w .. '">&gt;&gt;</font>'
			end
		end)
	end
	paintArrows()
	onAccentChange(function() paintArrows() end)
	task.spawn(function()
		while DecoArrows.Parent ~= nil do
			task.wait(0.6)
			if DecoArrows.Parent == nil then return end
			arrowPhase = not arrowPhase
			paintArrows()
		end
	end)
	DecoArrows.TextSize = 13
	DecoArrows.TextXAlignment = Enum.TextXAlignment.Left
	DecoArrows.TextYAlignment = Enum.TextYAlignment.Center
	DecoArrows.TextWrapped = false
	DecoArrows.LayoutOrder = 3
	if IsMobile then DecoArrows.Visible = false end
	DecoArrows.Parent = HeaderLayoutContainer

	-- (no separator line above the tab bar - clean look)

	-- =====================================================================
	-- TOP BAR NAVIGATION (topbar design: horizontal tabs, no sidebar)
	-- =====================================================================
	local TabBarTop = 52
	local TabBarHeight = 48
	local ContentTop = TabBarTop + TabBarHeight + 20

	-- ===== Bar layout: two separate boxes with a gap =====
	--   [ tab1 tab2 tab3 ]   [ v ]
	local BarPad = 4
	local CollapseW = 46
	local BoxGap = 14
	local TabsBoxW = -(10 + BoxGap + CollapseW + 10) -- left margin + gap + collapse box + right margin

	local TabBarSection = Instance.new("Frame")
	TabBarSection.Name = "TabsBox"
	TabBarSection.BackgroundColor3 = themeColorFor("20,20,24", CurrentThemeName or "Dark")
	TabBarSection.BackgroundTransparency = 0.15
	TabBarSection.BorderSizePixel = 0
	TabBarSection.Position = UDim2.new(0, 10, 0, TabBarTop - BarPad)
	TabBarSection.Size = UDim2.new(1, TabsBoxW, 0, TabBarHeight + BarPad * 2)
	TabBarSection.ZIndex = 2
	TabBarSection.Parent = MainFrame

	local TabBarCorner = Instance.new("UICorner")
	TabBarCorner.CornerRadius = UDim.new(0, 8)
	TabBarCorner.Parent = TabBarSection

	-- (no border stroke on the tab bar box - clean look)

	-- Separate box for the collapse toggle, to the right with a gap
	local CollapseBox = Instance.new("Frame")
	CollapseBox.Name = "CollapseBox"
	CollapseBox.BackgroundColor3 = themeColorFor("30,30,36", CurrentThemeName or "Dark")
	CollapseBox.BackgroundTransparency = 0
	CollapseBox.BorderSizePixel = 0
	CollapseBox.AnchorPoint = Vector2.new(1, 0)
	CollapseBox.Position = UDim2.new(1, -10, 0, TabBarTop - BarPad)
	CollapseBox.Size = UDim2.new(0, CollapseW, 0, TabBarHeight + BarPad * 2)
	CollapseBox.ZIndex = 2
	CollapseBox.Parent = MainFrame

	local CollapseBoxCorner = Instance.new("UICorner")
	CollapseBoxCorner.CornerRadius = UDim.new(0, 8)
	CollapseBoxCorner.Parent = CollapseBox

	-- (no border stroke on the collapse box - clean look)

	-- Horizontal tab strip (fills the tabs box)
	local ArrowW = 26
	local ArrowGap = 6
	local stripLeft = 6
	local stripRight = 6
	local TabContainer = Instance.new("ScrollingFrame")
	TabContainer.Name = "TabContainer"
	TabContainer.BackgroundTransparency = 1
	TabContainer.BorderSizePixel = 0
	TabContainer.Position = UDim2.new(0, stripLeft, 0, BarPad)
	TabContainer.Size = UDim2.new(1, -stripLeft - stripRight, 0, TabBarHeight)
	TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabContainer.ScrollBarThickness = 0
	TabContainer.ScrollBarImageColor3 = themeColorFor("60,60,66", CurrentThemeName or "Dark")
	TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
	TabContainer.ClipsDescendants = true
	TabContainer.ZIndex = 3
	TabContainer.Parent = TabBarSection

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Parent = TabContainer
	TabListLayout.FillDirection = Enum.FillDirection.Horizontal
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 8)
	TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabContainer.CanvasSize = UDim2.new(0, TabListLayout.AbsoluteContentSize.X + 16, 0, 0)
	end)

	local TabPadding = Instance.new("UIPadding")
	TabPadding.PaddingTop = UDim.new(0, 3)
	TabPadding.PaddingBottom = UDim.new(0, 3)
	TabPadding.PaddingLeft = UDim.new(0, 4)
	TabPadding.PaddingRight = UDim.new(0, 10)
	TabPadding.Parent = TabContainer

	-- ===== Scroll helpers (wheel + drag; no arrow buttons) =====
	local function tabMaxScroll()
		local ok, canvas = pcall(function() return TabContainer.AbsoluteCanvasSize.X end)
		if not ok or type(canvas) ~= "number" then return 0 end
		return math.max(0, canvas - TabContainer.AbsoluteSize.X)
	end

	local function tabScrollX()
		local ok, x = pcall(function() return TabContainer.CanvasPosition.X end)
		if ok and type(x) == "number" then return x end
		return 0
	end

	local function scrollTabs(delta)
		local target = math.clamp(tabScrollX() + delta, 0, tabMaxScroll())
		pcall(function()
			TweenService:Create(TabContainer, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CanvasPosition = Vector2.new(target, 0)
			}):Play()
		end)
	end

	-- Mouse wheel scrolls the strip horizontally while hovering it
	TabContainer.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			scrollTabs(-input.Position.Z * 220)
		end
	end)

	-- Hold left-click (or touch) and drag the strip left / right to scroll it.
	-- DragGain > 1 makes the strip travel further than the cursor so it feels fast.
	local DragGain = 4.5
	MainFrame:SetAttribute("TabDragMoved", false)
	do
		local dragActive, dragMoved = false, false
		local dragStartX, dragStartCanvas = 0, 0

		TabContainer.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			dragActive = true
			dragMoved = false
			dragStartX = input.Position.X
			dragStartCanvas = tabScrollX()
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragActive then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local dx = (input.Position.X - dragStartX) * DragGain
			if not dragMoved and math.abs(dx) > 3 then
				dragMoved = true
				MainFrame:SetAttribute("TabDragMoved", true)
			end
			if dragMoved then
				local target = math.clamp(dragStartCanvas - dx, 0, tabMaxScroll())
				TabContainer.CanvasPosition = Vector2.new(target, 0)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			dragActive = false
			task.delay(0.06, function()
				dragMoved = false
				MainFrame:SetAttribute("TabDragMoved", false)
			end)
		end)
	end


	-- ===== Collapse button: hide tab names, keep icons only =====
	local function applyTabCompact()
		local compact = MainFrame:GetAttribute("TabCompact") or false
		for _, d in ipairs(TabContainer:GetDescendants()) do
			if d.Name == "ButtonText" and d:IsA("TextLabel") then
				d.Visible = not compact
			end
		end
	end
	MainFrame:SetAttribute("TabCompact", false)

	do
		local TabsCollapse = Instance.new("TextButton")
		TabsCollapse.Name = "TabsCollapse"
		TabsCollapse.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
		TabsCollapse.BackgroundTransparency = 0
		TabsCollapse.BorderSizePixel = 0
		TabsCollapse.AnchorPoint = Vector2.new(0.5, 0.5)
		TabsCollapse.Position = UDim2.new(0.5, 0, 0.5, 0)
		TabsCollapse.Size = UDim2.new(1, -8, 1, -8)
		TabsCollapse.Text = ""
		TabsCollapse.AutoButtonColor = false
		TabsCollapse.ZIndex = 6
		TabsCollapse.Parent = CollapseBox

		local CCorner = Instance.new("UICorner")
		CCorner.CornerRadius = UDim.new(0, 6)
		CCorner.Parent = TabsCollapse

		local CIcon = Instance.new("ImageLabel")
		CIcon.Name = "Icon"
		CIcon.BackgroundTransparency = 1
		CIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		CIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		CIcon.Size = UDim2.new(0, 28, 0, 28)
		CIcon.Image = Astral.Icons.big_arrow_down or Astral.Icons.down_arrow
		CIcon.ImageColor3 = themeColorFor("235,235,240", CurrentThemeName or "Dark")
		CIcon.ScaleType = Enum.ScaleType.Fit
		CIcon.ZIndex = 7
		CIcon.Parent = TabsCollapse

		TabsCollapse.MouseEnter:Connect(function()
			if pickerOpen or selectorOpen then return end
			TweenService:Create(TabsCollapse, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(CurrentThemeName)}):Play()
			TweenService:Create(CIcon, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
		end)
		TabsCollapse.MouseLeave:Connect(function()
			TweenService:Create(TabsCollapse, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(CurrentThemeName)}):Play()
			TweenService:Create(CIcon, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")}):Play()
		end)

		TabsCollapse.MouseButton1Click:Connect(function()
			local compact = not (MainFrame:GetAttribute("TabCompact") or false)
			MainFrame:SetAttribute("TabCompact", compact)
			applyTabCompact()
			-- chevron points up when collapsed (click = show names), down when open
			TweenService:Create(CIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = compact and 180 or 0
			}):Play()
		end)
	end

	-- (no divider line under the tab strip - clean look)

	-- Content fills the window below the tab strip
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.BackgroundColor3 = themeColorFor("16,16,18", CurrentThemeName or "Dark")
	ContentContainer.BackgroundTransparency = 0.25 -- lets background image show through
	ContentContainer.BorderSizePixel = 0
	ContentContainer.ClipsDescendants = true
	ContentContainer.Position = UDim2.new(0, 10, 0, ContentTop)
	ContentContainer.Size = UDim2.new(1, -20, 1, -ContentTop - 10)
	ContentContainer.Parent = MainFrame

	local ContentCorner = Instance.new("UICorner")
	ContentCorner.CornerRadius = UDim.new(0, 8)
	ContentCorner.Parent = ContentContainer

	-- Apply Lag-Free Dragging
	makeElementDraggable(MainFrame, TopBar)

	-- =========================================================================
	-- PIXEL-PERFECT COLOR PICKER PANEL (SLIDES INSIDE FROM RIGHT SIDE)
	-- =========================================================================
	local cpWidth = 280
	-- Panels shrink on small windows so they never cover everything / overlap
	local function curPanelWidth()
		local w = MainFrame.AbsoluteSize.X
		if w < 10 then w = refW end
		return math.min(280, math.max(200, w - 120))
	end
	local cpHeight = IsMobile and 335 or 499
	local canvasHeight = IsMobile and 95 or 190
	local sliderHeight = IsMobile and 12 or 16
	local previewHeight = IsMobile and 22 or 36
	local inputHeight = IsMobile and 22 or 32
	local buttonHeight = IsMobile and 30 or 36
	local padding = IsMobile and 5 or 12

	local ColorPickerPanel = Instance.new("Frame")
	ColorPickerPanel.Name = "ColorPickerPanel"
	ColorPickerPanel.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark") -- lightened
	ColorPickerPanel.BorderSizePixel = 0
	ColorPickerPanel.Size = UDim2.new(0, cpWidth, 1, -51)
	ColorPickerPanel.Position = UDim2.new(1, 0, 0, 51) -- Hidden off-screen to the right (inside MainFrame)
	ColorPickerPanel.ZIndex = 200
	ColorPickerPanel.Active = true -- Block clicks from passing through
	ColorPickerPanel.Parent = MainFrame -- Parented to MainFrame to stay inside the UI

	-- Input Sinker to completely block click-throughs to elements behind the panel
	local CPInputSinker = Instance.new("TextButton")
	CPInputSinker.Name = "InputSinker"
	CPInputSinker.Size = UDim2.new(1, 0, 1, 0)
	CPInputSinker.BackgroundTransparency = 1
	CPInputSinker.Text = ""
	CPInputSinker.AutoButtonColor = false
	CPInputSinker.ZIndex = 200
	CPInputSinker.Parent = ColorPickerPanel

	local PanelSeparator = Instance.new("Frame")
	PanelSeparator.Name = "PanelSeparator"
	-- layout clean for side panels
	PanelSeparator.BackgroundColor3 = themeColorFor("38,38,44", CurrentThemeName or "Dark")
	PanelSeparator.BorderSizePixel = 0
	PanelSeparator.Position = UDim2.new(0, 0, 0, 0)
	PanelSeparator.Size = UDim2.new(0, 1, 1, 0)
	PanelSeparator.ZIndex = 201
	PanelSeparator.Parent = ColorPickerPanel

	-- Saturation/Value canvas: hue base + white (sat) + black (val) gradients,
	-- so every shade is reachable and colors are easy to match
	local Canvas = Instance.new("Frame")
	Canvas.Name = "Canvas"
	Canvas.Size = UDim2.new(1, -24, 0, canvasHeight)
	Canvas.Position = UDim2.new(0, 12, 0, padding)
	Canvas.BackgroundColor3 = themeColorFor("255,0,0", CurrentThemeName or "Dark")
	Canvas.BorderSizePixel = 0
	Canvas.ClipsDescendants = true
	Canvas.ZIndex = 202
	Canvas.Parent = ColorPickerPanel

	local CanvasCorner = Instance.new("UICorner")
	CanvasCorner.CornerRadius = UDim.new(0, 8)
	CanvasCorner.Parent = Canvas

	-- White overlay, transparent on the right = saturation axis
	local SatOverlay = Instance.new("Frame")
	SatOverlay.Name = "SatOverlay"
	SatOverlay.Size = UDim2.fromScale(1, 1)
	SatOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SatOverlay.BorderSizePixel = 0
	SatOverlay.ZIndex = 203
	SatOverlay.Parent = Canvas

	local SatOverlayCorner = Instance.new("UICorner")
	SatOverlayCorner.CornerRadius = UDim.new(0, 8)
	SatOverlayCorner.Parent = SatOverlay

	local SatGradient = Instance.new("UIGradient")
	SatGradient.Rotation = 0
	SatGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	SatGradient.Parent = SatOverlay

	-- Black overlay, transparent on top = value axis
	local ValOverlay = Instance.new("Frame")
	ValOverlay.Name = "ValOverlay"
	ValOverlay.Size = UDim2.fromScale(1, 1)
	ValOverlay.BackgroundColor3 = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	ValOverlay.BorderSizePixel = 0
	ValOverlay.ZIndex = 204
	ValOverlay.Parent = Canvas

	local ValOverlayCorner = Instance.new("UICorner")
	ValOverlayCorner.CornerRadius = UDim.new(0, 8)
	ValOverlayCorner.Parent = ValOverlay

	local ValGradient = Instance.new("UIGradient")
	ValGradient.Rotation = 90
	ValGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	ValGradient.Parent = ValOverlay

	local CanvasHandle = Instance.new("Frame")
	CanvasHandle.Name = "CanvasHandle"
	CanvasHandle.Size = UDim2.new(0, 16, 0, 16)
	CanvasHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	CanvasHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CanvasHandle.ZIndex = 205
	CanvasHandle.Parent = Canvas

	local HandleCorner = Instance.new("UICorner")
	HandleCorner.CornerRadius = UDim.new(1, 0)
	HandleCorner.Parent = CanvasHandle

	local HandleStroke = Instance.new("UIStroke")
	HandleStroke.Color = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	HandleStroke.Thickness = 1.5
	HandleStroke.Parent = CanvasHandle

	-- Hue Slider (FIXED: Subtle curve, not too curved)
	local HueSlider = Instance.new("Frame")
	HueSlider.Name = "HueSlider"
	HueSlider.Size = UDim2.new(1, -24, 0, sliderHeight)
	HueSlider.Position = UDim2.new(0, 12, 0, padding + canvasHeight + padding)
	HueSlider.ZIndex = 202
	HueSlider.Parent = ColorPickerPanel

	local HueCorner = Instance.new("UICorner")
	HueCorner.CornerRadius = UDim.new(0, 3) -- FIXED: Subtle curve, not too curved
	HueCorner.Parent = HueSlider

	local HueGradient = Instance.new("UIGradient")
	HueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, themeColorFor("255,0,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.17, themeColorFor("255,255,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.33, themeColorFor("0,255,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.5, themeColorFor("0,255,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.67, themeColorFor("0,0,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.83, themeColorFor("255,0,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(1, themeColorFor("255,0,0", CurrentThemeName or "Dark"))
	})
	HueGradient.Parent = HueSlider

	local HueHandle = Instance.new("Frame")
	HueHandle.Name = "HueHandle"
	HueHandle.Size = UDim2.new(0, 12, 1, 6) -- Vertical pill wrapping the slider
	HueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	HueHandle.Position = UDim2.new(0, 0, 0.5, 0)
	HueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HueHandle.ZIndex = 203
	HueHandle.Parent = HueSlider

	local HueHandleCorner = Instance.new("UICorner")
	HueHandleCorner.CornerRadius = UDim.new(0, 4)
	HueHandleCorner.Parent = HueHandle

	local HueHandleStroke = Instance.new("UIStroke")
	HueHandleStroke.Color = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	HueHandleStroke.Thickness = 1
	HueHandleStroke.Parent = HueHandle

	-- Current / New Preview Buttons
	local PreviewContainer = Instance.new("Frame")
	PreviewContainer.Name = "PreviewContainer"
	PreviewContainer.BackgroundTransparency = 1
	PreviewContainer.Size = UDim2.new(1, -24, 0, previewHeight)
	PreviewContainer.Position = UDim2.new(0, 12, 0, padding + canvasHeight + padding + sliderHeight + padding)
	PreviewContainer.ZIndex = 202
	PreviewContainer.Parent = ColorPickerPanel

	local CurrentPreview = Instance.new("Frame")
	CurrentPreview.Name = "CurrentPreview"
	CurrentPreview.Size = UDim2.new(0.5, -6, 1, 0)
	CurrentPreview.BackgroundColor3 = themeColorFor("34,255,34", CurrentThemeName or "Dark")
	CurrentPreview.ZIndex = 203
	CurrentPreview.Parent = PreviewContainer
	-- LAYOUT AROUND BOX (copied from good UI)
	local PreviewPadding = Instance.new("UIPadding", PreviewContainer)
	PreviewPadding.PaddingLeft = UDim.new(0, 0)
	PreviewPadding.PaddingRight = UDim.new(0, 0)

	local CurrentCorner = Instance.new("UICorner")
	CurrentCorner.CornerRadius = UDim.new(0, 6)
	CurrentCorner.Parent = CurrentPreview

	local CurrentLabel = Instance.new("TextLabel")
	CurrentLabel.Size = UDim2.new(1, 0, 1, 0)
	CurrentLabel.BackgroundTransparency = 1
	CurrentLabel.Font = Enum.Font.GothamBold
	CurrentLabel.Text = "CURRENT"
	CurrentLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	CurrentLabel.			TextSize = 11
	CurrentLabel.ZIndex = 204
	CurrentLabel.Parent = CurrentPreview

	local NewPreview = Instance.new("Frame")
	NewPreview.Name = "NewPreview"
	NewPreview.Size = UDim2.new(0.5, -6, 1, 0)
	NewPreview.Position = UDim2.new(0.5, 6, 0, 0)
	NewPreview.BackgroundColor3 = themeColorFor("58,49,255", CurrentThemeName or "Dark")
	NewPreview.ZIndex = 203
	NewPreview.Parent = PreviewContainer

	local NewCorner = Instance.new("UICorner")
	NewCorner.CornerRadius = UDim.new(0, 6)
	NewCorner.Parent = NewPreview

	local NewLabel = Instance.new("TextLabel")
	NewLabel.Size = UDim2.new(1, 0, 1, 0)
	NewLabel.BackgroundTransparency = 1
	NewLabel.Font = Enum.Font.GothamBold
	NewLabel.Text = "NEW"
	NewLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	NewLabel.			TextSize = 11
	NewLabel.ZIndex = 204
	NewLabel.Parent = NewPreview

	-- RGB Inputs
	local RGBContainer = Instance.new("Frame")
	RGBContainer.Name = "RGBContainer"
	RGBContainer.BackgroundColor3 = themeColorFor("22,22,26", CurrentThemeName or "Dark")
	RGBContainer.BackgroundTransparency = 0
	RGBContainer.BorderSizePixel = 0
	RGBContainer.Size = UDim2.new(1, -24, 0, inputHeight + 10)
	RGBContainer.Position = UDim2.new(0, 12, 0, padding + canvasHeight + padding + sliderHeight + padding + previewHeight + padding - 5)
	RGBContainer.ZIndex = 202
	RGBContainer.Parent = ColorPickerPanel

	local RGBCorner = Instance.new("UICorner")
	RGBCorner.CornerRadius = UDim.new(0, 8)
	RGBCorner.Parent = RGBContainer

	local RGBStroke = Instance.new("UIStroke")
	RGBStroke.Color = themeColorFor("52,52,60", CurrentThemeName or "Dark")
	RGBStroke.Thickness = 1
	RGBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	RGBStroke.Parent = RGBContainer

	local RGBPad = Instance.new("UIPadding")
	RGBPad.PaddingLeft = UDim.new(0, 6)
	RGBPad.PaddingRight = UDim.new(0, 6)
	RGBPad.PaddingTop = UDim.new(0, 5)
	RGBPad.PaddingBottom = UDim.new(0, 5)
	RGBPad.Parent = RGBContainer

	-- RGB Inputs: one real horizontal layout (no manual math, no dup padding)
	local RGBLayout = Instance.new("UIListLayout")
	RGBLayout.FillDirection = Enum.FillDirection.Horizontal
	RGBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	RGBLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	RGBLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RGBLayout.Padding = UDim.new(0, 8)
	RGBLayout.Parent = RGBContainer

	local function createRGBInput(name, placeholder, order)
		local Box = Instance.new("TextBox")
		Box.Name = name
		Box.Size = UDim2.new(0.333, -6, 1, 0)
		Box.BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")
		Box.BorderSizePixel = 0
		Box.Font = Enum.Font.GothamBold
		Box.Text = "255"
		Box.PlaceholderText = placeholder
		Box.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
		Box.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		Box.			TextSize = 12
		Box.ClearTextOnFocus = false
		Box.ClipsDescendants = true
		Box.TextTruncate = Enum.TextTruncate.AtEnd
		Box.TextXAlignment = Enum.TextXAlignment.Center
		Box.ZIndex = 203
		Box.LayoutOrder = order
		Box.Parent = RGBContainer

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 6)
		Corner.Parent = Box

		local Stroke = Instance.new("UIStroke")
		Stroke.Color = themeColorFor("35,35,40", CurrentThemeName or "Dark")
		Stroke.Thickness = 1
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.Parent = Box

		Box.Focused:Connect(function()
			TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = AccentColor}):Play()
		end)
		Box.FocusLost:Connect(function()
			TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = themeColorFor("35,35,40", CurrentThemeName or "Dark")}):Play()
		end)

		return Box
	end

	local RInput = createRGBInput("RInput", "R", 1)
	local GInput = createRGBInput("GInput", "G", 2)
	local BInput = createRGBInput("BInput", "B", 3)

	-- Hex row: caption + input aligned on one clean line
	local HexRow = Instance.new("Frame")
	HexRow.Name = "HexRow"
	HexRow.BackgroundColor3 = themeColorFor("22,22,26", CurrentThemeName or "Dark")
	HexRow.BackgroundTransparency = 0
	HexRow.BorderSizePixel = 0
	HexRow.Size = UDim2.new(1, -24, 0, inputHeight + 10)
	HexRow.Position = UDim2.new(0, 12, 0, padding + canvasHeight + padding + sliderHeight + padding + previewHeight + padding - 5 + inputHeight + 10 + 6)
	HexRow.ZIndex = 202
	HexRow.Parent = ColorPickerPanel

	local HexCardCorner = Instance.new("UICorner")
	HexCardCorner.CornerRadius = UDim.new(0, 8)
	HexCardCorner.Parent = HexRow

	local HexCardStroke = Instance.new("UIStroke")
	HexCardStroke.Color = themeColorFor("52,52,60", CurrentThemeName or "Dark")
	HexCardStroke.Thickness = 1
	HexCardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	HexCardStroke.Parent = HexRow

	local HexCardPad = Instance.new("UIPadding")
	HexCardPad.PaddingLeft = UDim.new(0, 6)
	HexCardPad.PaddingRight = UDim.new(0, 6)
	HexCardPad.PaddingTop = UDim.new(0, 5)
	HexCardPad.PaddingBottom = UDim.new(0, 5)
	HexCardPad.Parent = HexRow

	local HexRowLayout = Instance.new("UIListLayout")
	HexRowLayout.FillDirection = Enum.FillDirection.Horizontal
	HexRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HexRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HexRowLayout.Padding = UDim.new(0, 8)
	HexRowLayout.Parent = HexRow

	local HexCaption = Instance.new("TextLabel")
	HexCaption.Name = "HexCaption"
	HexCaption.BackgroundTransparency = 1
	HexCaption.Size = UDim2.new(0, 36, 1, 0)
	HexCaption.Font = Enum.Font.GothamBold
	HexCaption.Text = "HEX"
	HexCaption.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
	HexCaption.			TextSize = 10
	HexCaption.TextXAlignment = Enum.TextXAlignment.Left
	HexCaption.LayoutOrder = 1
	HexCaption.ZIndex = 203
	HexCaption.Parent = HexRow

	-- Hex Input
	local HexInput = Instance.new("TextBox")
	HexInput.Name = "HexInput"
	HexInput.Size = UDim2.new(1, -44, 1, 0)
	HexInput.BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")
	HexInput.BorderSizePixel = 0
	HexInput.Font = Enum.Font.GothamBold
	HexInput.Text = "#FFFFFF"
	HexInput.PlaceholderText = "#843447"
	HexInput.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
	HexInput.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	HexInput.			TextSize = 12
	HexInput.ClearTextOnFocus = false
	HexInput.ClipsDescendants = true
	HexInput.TextTruncate = Enum.TextTruncate.AtEnd
	HexInput.TextXAlignment = Enum.TextXAlignment.Center
	HexInput.ZIndex = 203
	HexInput.LayoutOrder = 2
	HexInput.Parent = HexRow
	local HexInnerPadding = Instance.new("UIPadding")
	HexInnerPadding.PaddingLeft = UDim.new(0, 8)
	HexInnerPadding.PaddingRight = UDim.new(0, 8)
	HexInnerPadding.Parent = HexInput

	local HexCorner = Instance.new("UICorner")
	HexCorner.CornerRadius = UDim.new(0, 6)
	HexCorner.Parent = HexInput

	local HexStroke = Instance.new("UIStroke")
	HexStroke.Color = themeColorFor("35,35,40", CurrentThemeName or "Dark")
	HexStroke.Thickness = 1
	HexStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	HexStroke.Parent = HexInput

	HexInput.Focused:Connect(function()
		TweenService:Create(HexStroke, TweenInfo.new(0.15), {Color = AccentColor}):Play()
	end)
	HexInput.FocusLost:Connect(function()
		TweenService:Create(HexStroke, TweenInfo.new(0.15), {Color = themeColorFor("35,35,40", CurrentThemeName or "Dark")}):Play()
	end)

	-- Apply & Cancel Buttons
	local ApplyButton = Instance.new("TextButton")
	ApplyButton.Name = "ApplyButton"
	ApplyButton.Size = UDim2.new(1, -24, 0, buttonHeight)
	ApplyButton.Position = UDim2.new(0, 12, 1, -buttonHeight - buttonHeight - padding - 8)
	ApplyButton.BackgroundColor3 = AccentColor
	ApplyButton.Font = Enum.Font.GothamBold
	ApplyButton.Text = "Apply"
			ApplyButton.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	ApplyButton.			TextSize = 14
	ApplyButton.ZIndex = 203
	ApplyButton.Parent = ColorPickerPanel

	local ApplyCorner = Instance.new("UICorner")
	ApplyCorner.CornerRadius = UDim.new(0, 8)
	ApplyCorner.Parent = ApplyButton

	-- Apply button follows theme accent
	onAccentChange(function(c)
		ApplyButton.BackgroundColor3 = c
	end)

	local CancelButton = Instance.new("TextButton")
	CancelButton.Name = "CancelButton"
	CancelButton.Size = UDim2.new(1, -24, 0, buttonHeight)
	CancelButton.Position = UDim2.new(0, 12, 1, -buttonHeight - 8)
		CancelButton.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
	CancelButton.Font = Enum.Font.GothamBold
	CancelButton.Text = "Cancel"
	CancelButton.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	CancelButton.			TextSize = 14
	CancelButton.ZIndex = 203
	CancelButton.Parent = ColorPickerPanel -- FIXED: Corrected parent from CancelButton to ColorPickerPanel to prevent crash

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 8)
	CancelCorner.Parent = CancelButton

	-- Color Picker State & Math Logic
	local currentHue, currentSat, currentValue = 0, 1, 1
	local originalColor = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	local selectedColor = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	local activeCallback = nil
	local activePreviewBox = nil
	local pickerOpen = false

	local function updateColorPickerUI()
		local color = Color3.fromHSV(currentHue, currentSat, currentValue)
		selectedColor = color
		
		-- Base shows the pure hue; overlays shape saturation (white) and value (black)
		Canvas.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
		
		CanvasHandle.Position = UDim2.new(currentSat, 0, 1 - currentValue, 0)
		HueHandle.Position = UDim2.new(currentHue, 0, 0.5, 0)
		NewPreview.BackgroundColor3 = color
		
		local r, g, b = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
		RInput.Text = tostring(r)
		GInput.Text = tostring(g)
		BInput.Text = tostring(b)
		HexInput.Text = string.format("#%02X%02X%02X", r, g, b)
	end

	-- Hue Slider Dragging
	local hueDragging = false
	local function updateHueFromInput(input)
		local relX, _ = getRelativePosition(HueSlider, input)
		currentHue = relX
		updateColorPickerUI()
	end

	HueSlider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = true
			updateHueFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateHueFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = false
		end
	end)

	-- Canvas Dragging
	local canvasDragging = false
	local function updateCanvasFromInput(input)
		local relX, relY = getRelativePosition(Canvas, input)
		currentSat = relX
		currentValue = 1 - relY
		updateColorPickerUI()
	end

	Canvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			canvasDragging = true
			updateCanvasFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if canvasDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateCanvasFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			canvasDragging = false
		end
	end)

	-- Manual Inputs
	local function updateFromRGB()
		local r = tonumber(RInput.Text) or 0
		local g = tonumber(GInput.Text) or 0
		local b = tonumber(BInput.Text) or 0
		r = math.clamp(r, 0, 255)
		g = math.clamp(g, 0, 255)
		b = math.clamp(b, 0, 255)
		
		local color = Color3.fromRGB(r, g, b)
		currentHue, currentSat, currentValue = Color3.toHSV(color)
		updateColorPickerUI()
	end

	RInput.FocusLost:Connect(updateFromRGB)
	GInput.FocusLost:Connect(updateFromRGB)
	BInput.FocusLost:Connect(updateFromRGB)

	HexInput.FocusLost:Connect(function()
		local hex = HexInput.Text:gsub("#", "")
		if #hex == 6 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			if r and g and b then
				local color = Color3.fromRGB(r, g, b)
				currentHue, currentSat, currentValue = Color3.toHSV(color)
				updateColorPickerUI()
			end
		end
	end)

	-- Forward declaration of closeSelector to prevent scope errors
	local closeSelector
	local closeMiniPicker
	local openMiniPicker

	-- Lay out picker rows from the REAL panel height every open,
	-- so short windows (XS/mobile) can never overlap rows and buttons
	local function layoutPickerPanel()
		local H = ColorPickerPanel.AbsoluteSize.Y
		if H < 10 then H = (refH or 550) - 51 end
		ColorPickerPanel.Size = UDim2.new(0, curPanelWidth(), 1, -51)
		local compact = H < 380
		local pad = compact and 4 or 12
		local ch = compact and 80 or 190
		local sh = compact and 10 or 16
		local ph = compact and 18 or 36
		local ih = compact and 22 or 32
		local bh = compact and 26 or 36
		Canvas.Size = UDim2.new(1, -24, 0, ch)
		Canvas.Position = UDim2.new(0, 12, 0, pad)
		HueSlider.Size = UDim2.new(1, -24, 0, sh)
		HueSlider.Position = UDim2.new(0, 12, 0, pad + ch + pad)
		PreviewContainer.Size = UDim2.new(1, -24, 0, ph)
		PreviewContainer.Position = UDim2.new(0, 12, 0, pad + ch + pad + sh + pad)
		RGBContainer.Size = UDim2.new(1, -24, 0, ih)
		RGBContainer.Position = UDim2.new(0, 12, 0, pad + ch + pad + sh + pad + ph + pad)
		HexRow.Size = UDim2.new(1, -24, 0, ih)
		HexRow.Position = UDim2.new(0, 12, 0, pad + ch + pad + sh + pad + ph + pad + ih + pad)
		ApplyButton.Size = UDim2.new(1, -24, 0, bh)
		ApplyButton.Position = UDim2.new(0, 12, 1, -bh - bh - pad - 8)
		CancelButton.Size = UDim2.new(1, -24, 0, bh)
		CancelButton.Position = UDim2.new(0, 12, 1, -bh - 8)
	end

	-- Slide Animations (Slides inside MainFrame from the right edge)
	local function openColorPicker(defaultColor, callback, previewBox)
		if closeMiniPicker then closeMiniPicker() end
		if closeSelector then closeSelector() end
		originalColor = defaultColor
		selectedColor = defaultColor
		currentHue, currentSat, currentValue = Color3.toHSV(defaultColor)
		
		CurrentPreview.BackgroundColor3 = defaultColor
		activeCallback = callback
		activePreviewBox = previewBox
		
		updateColorPickerUI()
		
		pickerOpen = true
		layoutPickerPanel()
		TweenService:Create(ColorPickerPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -curPanelWidth(), 0, 51)
		}):Play()
	end

	local function closeColorPicker()
		pickerOpen = false
		TweenService:Create(ColorPickerPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0, 51)
		}):Play()
	end

	ApplyButton.MouseButton1Click:Connect(function()
		if activeCallback then
			task.spawn(activeCallback, selectedColor)
		end
		if activePreviewBox then
			activePreviewBox.BackgroundColor3 = selectedColor
		end
		closeColorPicker()
	end)

	CancelButton.MouseButton1Click:Connect(function()
		closeColorPicker()
	end)

	-- =========================================================================
	-- MINI COLOR PICKER (compact popup for MultiColorPicker tiles only.
	-- The single AddColorpicker keeps the big slide-in panel above.)
	-- Wrapped in do-end so its many locals reuse registers (200 local limit).
	-- =========================================================================
	do
	local miniH, miniS, miniV = 0, 1, 1
	local miniCallback = nil
	local miniOpen = false

	local MiniCatcher = Instance.new("TextButton")
	MiniCatcher.Name = "MiniCatcher"
	MiniCatcher.Size = UDim2.new(1, 0, 1, 0)
	MiniCatcher.BackgroundTransparency = 1
	MiniCatcher.Text = ""
	MiniCatcher.AutoButtonColor = false
	MiniCatcher.Visible = false
	MiniCatcher.ZIndex = 499
	MiniCatcher.Parent = ScreenGui

	local MiniPanel = Instance.new("Frame")
	MiniPanel.Name = "MiniColorPicker"
	MiniPanel.Size = UDim2.new(0, 216, 0, 158)
	MiniPanel.ClipsDescendants = true
	MiniPanel.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
	MiniPanel.BorderSizePixel = 0
	MiniPanel.Visible = false
	MiniPanel.ZIndex = 500
	MiniPanel.Parent = ScreenGui

	local MiniCorner = Instance.new("UICorner")
	MiniCorner.CornerRadius = UDim.new(0, 10)
	MiniCorner.Parent = MiniPanel

	local MiniStroke = Instance.new("UIStroke")
	MiniStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
	MiniStroke.Thickness = 1.2
	MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MiniStroke.Parent = MiniPanel

	local MiniCanvas = Instance.new("Frame")
	MiniCanvas.Name = "Canvas"
	MiniCanvas.Position = UDim2.new(0, 10, 0, 10)
	MiniCanvas.Size = UDim2.new(0, 150, 0, 100)
	MiniCanvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniCanvas.BorderSizePixel = 0
	MiniCanvas.ClipsDescendants = true
	MiniCanvas.ZIndex = 501
	MiniCanvas.Parent = MiniPanel

	local MiniCanvasCorner = Instance.new("UICorner")
	MiniCanvasCorner.CornerRadius = UDim.new(0, 6)
	MiniCanvasCorner.Parent = MiniCanvas

	local MiniRainbow = Instance.new("UIGradient")
	MiniRainbow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, themeColorFor("255,0,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.17, themeColorFor("255,255,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.33, themeColorFor("0,255,0", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.5, themeColorFor("0,255,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.67, themeColorFor("0,0,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.83, themeColorFor("255,0,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(1, themeColorFor("255,0,0", CurrentThemeName or "Dark")),
	})
	MiniRainbow.Parent = MiniCanvas

	local MiniCursor = Instance.new("Frame")
	MiniCursor.Size = UDim2.new(0, 12, 0, 12)
	MiniCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	MiniCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniCursor.ZIndex = 502
	MiniCursor.Parent = MiniCanvas

	local MiniCursorCorner = Instance.new("UICorner")
	MiniCursorCorner.CornerRadius = UDim.new(1, 0)
	MiniCursorCorner.Parent = MiniCursor

	local MiniCursorStroke = Instance.new("UIStroke")
	MiniCursorStroke.Color = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	MiniCursorStroke.Thickness = 1.5
	MiniCursorStroke.Parent = MiniCursor

	local MiniBar = Instance.new("Frame")
	MiniBar.Name = "ShadeBar"
	MiniBar.Position = UDim2.new(0, 168, 0, 10)
	MiniBar.Size = UDim2.new(0, 16, 0, 100)
	MiniBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniBar.BorderSizePixel = 0
	MiniBar.ClipsDescendants = true
	MiniBar.ZIndex = 501
	MiniBar.Parent = MiniPanel

	local MiniBarCorner = Instance.new("UICorner")
	MiniBarCorner.CornerRadius = UDim.new(0, 5)
	MiniBarCorner.Parent = MiniBar

	local MiniBarGrad = Instance.new("UIGradient")
	MiniBarGrad.Rotation = 90
	MiniBarGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, themeColorFor("255,255,255", CurrentThemeName or "Dark")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(1, themeColorFor("0,0,0", CurrentThemeName or "Dark")),
	})
	MiniBarGrad.Parent = MiniBar

	local MiniBarCursor = Instance.new("Frame")
	MiniBarCursor.Size = UDim2.new(1, 0, 0, 5)
	MiniBarCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	MiniBarCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniBarCursor.ZIndex = 502
	MiniBarCursor.Parent = MiniBar

	local MiniBarCursorCorner = Instance.new("UICorner")
	MiniBarCursorCorner.CornerRadius = UDim.new(1, 0)
	MiniBarCursorCorner.Parent = MiniBarCursor

	local MiniPrev = Instance.new("Frame")
	MiniPrev.Position = UDim2.new(0, 10, 0, 120)
	MiniPrev.Size = UDim2.new(0, 40, 0, 28)
	MiniPrev.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	MiniPrev.BorderSizePixel = 0
	MiniPrev.ZIndex = 501
	MiniPrev.Parent = MiniPanel

	local MiniPrevCorner = Instance.new("UICorner")
	MiniPrevCorner.CornerRadius = UDim.new(0, 6)
	MiniPrevCorner.Parent = MiniPrev

	local MiniApply = Instance.new("TextButton")
	MiniApply.Position = UDim2.new(0, 58, 0, 120)
	MiniApply.Size = UDim2.new(0, 96, 0, 28)
	MiniApply.BackgroundColor3 = AccentColor
	MiniApply.Font = Enum.Font.GothamBold
	MiniApply.Text = "Apply"
	MiniApply.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	MiniApply.TextSize = 13
	MiniApply.AutoButtonColor = false
	MiniApply.ZIndex = 501
	MiniApply.Parent = MiniPanel

	local MiniApplyCorner = Instance.new("UICorner")
	MiniApplyCorner.CornerRadius = UDim.new(0, 6)
	MiniApplyCorner.Parent = MiniApply
	onAccentChange(function(c) pcall(function() MiniApply.BackgroundColor3 = c end) end)

	local MiniX = Instance.new("TextButton")
	MiniX.Position = UDim2.new(0, 162, 0, 120)
	MiniX.Size = UDim2.new(0, 44, 0, 28)
	MiniX.BackgroundColor3 = themeColorFor("40,40,48", CurrentThemeName or "Dark")
	MiniX.Font = Enum.Font.GothamBold
	MiniX.Text = "X"
	MiniX.TextColor3 = themeColorFor("200,200,208", CurrentThemeName or "Dark")
	MiniX.TextSize = 13
	MiniX.AutoButtonColor = false
	MiniX.ZIndex = 501
	MiniX.Parent = MiniPanel

	local MiniXCorner = Instance.new("UICorner")
	MiniXCorner.CornerRadius = UDim.new(0, 6)
	MiniXCorner.Parent = MiniX

	local function miniRefresh()
		local col = Color3.fromHSV(miniH, miniS, miniV)
		MiniPrev.BackgroundColor3 = col
		MiniCursor.Position = UDim2.new(miniH, 0, 1 - miniV, 0)
		local bp = (miniS < 1) and (miniS * 0.5) or (1 - miniV * 0.5)
		MiniBarCursor.Position = UDim2.new(0.5, 0, bp, 0)
		MiniBarGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, themeColorFor("255,255,255", CurrentThemeName or "Dark")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV(miniH, 1, 1)),
			ColorSequenceKeypoint.new(1, themeColorFor("0,0,0", CurrentThemeName or "Dark")),
		})
	end

	local miniCanvasDrag, miniBarDrag = false, false
	local function miniCanvasInput(input)
		local relX, relY = getRelativePosition(MiniCanvas, input)
		miniH = relX
		miniV = 1 - relY
		miniRefresh()
	end
	local function miniBarInput(input)
		local _, relY = getRelativePosition(MiniBar, input)
		local p = math.clamp(relY, 0, 1)
		if p <= 0.5 then
			miniS = p * 2
		else
			miniS = 1
			miniV = (1 - p) * 2
		end
		miniRefresh()
	end
	MiniCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			miniCanvasDrag = true
			miniCanvasInput(input)
		end
	end)
	MiniBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			miniBarDrag = true
			miniBarInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if miniCanvasDrag then miniCanvasInput(input) end
		if miniBarDrag then miniBarInput(input) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			miniCanvasDrag = false
			miniBarDrag = false
		end
	end)

	closeMiniPicker = function()
		if not miniOpen then return end
		miniOpen = false
		MiniPanel.Visible = false
		MiniCatcher.Visible = false
	end
	MiniCatcher.MouseButton1Click:Connect(function() closeMiniPicker() end)
	MiniX.MouseButton1Click:Connect(function() closeMiniPicker() end)
	MiniApply.MouseButton1Click:Connect(function()
		if miniCallback then
			task.spawn(miniCallback, Color3.fromHSV(miniH, miniS, miniV))
		end
		closeMiniPicker()
	end)

	openMiniPicker = function(defaultColor, callback, fromBtn)
		closeMiniPicker()
		if closeSelector then closeSelector() end
		miniH, miniS, miniV = Color3.toHSV(defaultColor)
		miniCallback = callback
		miniRefresh()
		local cx, cy = 200, 200
		pcall(function()
			local vw, vh = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
			local insetY = 0
			pcall(function() insetY = game:GetService("GuiService"):GetGuiInset().Y end)
			local bp = fromBtn.AbsolutePosition
			local bs = fromBtn.AbsoluteSize
			cx = math.clamp(bp.X, 8, vw - 224)
			cy = bp.Y - insetY + bs.Y + 2
			if cy + 166 > vh - insetY then cy = bp.Y - insetY - 166 end
			if cy < 8 then cy = 8 end
		end)
		MiniPanel.Size = UDim2.new(0, 216, 0, 8)
		MiniPanel.Position = UDim2.new(0, cx, 0, cy)
		MiniCatcher.Visible = true
		MiniPanel.Visible = true
		miniOpen = true
		TweenService:Create(MiniPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 216, 0, 158),
		}):Play()
	end
	end -- end mini scope (frees registers)

	-- =========================================================================
	-- PIXEL-PERFECT SELECTOR PANEL (SLIDES INSIDE FROM RIGHT SIDE)
	-- =========================================================================
	local SelectorPanel = Instance.new("Frame")
	SelectorPanel.Name = "SelectorPanel"
	SelectorPanel.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark") -- FIXED: lightened from 14,14,16 for clean visibility
	SelectorPanel.BorderSizePixel = 0
	SelectorPanel.Size = UDim2.new(0, cpWidth, 1, -51)
	SelectorPanel.Position = UDim2.new(1, 0, 0, 51) -- Hidden off-screen to the right
	SelectorPanel.ZIndex = 200
	SelectorPanel.Active = true -- Block clicks from passing through
	SelectorPanel.Parent = MainFrame

	-- FIXED: Clean, matching border stroke for the Selector Panel (No mismatched colors)
	local SelectorPanelStroke = Instance.new("UIStroke")
	SelectorPanelStroke.Color = themeColorFor("32,32,36", CurrentThemeName or "Dark") -- Matches MainFrame border exactly
	SelectorPanelStroke.Thickness = 1.5
	local SelectorPadding = Instance.new("UIPadding", SelectorPanel)
	SelectorPadding.PaddingTop = UDim.new(0, 4)
	SelectorPadding.PaddingBottom = UDim.new(0, 4)
	SelectorPanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	SelectorPanelStroke.Parent = SelectorPanel

	-- Input Sinker to completely block click-throughs to elements behind the panel
	local SelectorInputSinker = Instance.new("TextButton")
	SelectorInputSinker.Name = "InputSinker"
	SelectorInputSinker.Size = UDim2.new(1, 0, 1, 0)
	SelectorInputSinker.BackgroundTransparency = 1
	SelectorInputSinker.Text = ""
	SelectorInputSinker.AutoButtonColor = false
	SelectorInputSinker.ZIndex = 200
	SelectorInputSinker.Parent = SelectorPanel

	-- Outside-click catcher: click anywhere outside the panel to close (no close button)
	local SelectorCatcher = Instance.new("TextButton")
	SelectorCatcher.Name = "SelectorCatcher"
	SelectorCatcher.BackgroundTransparency = 1
	SelectorCatcher.Text = ""
	SelectorCatcher.AutoButtonColor = false
	SelectorCatcher.Position = UDim2.new(0, 0, 0, 51)
	SelectorCatcher.Size = UDim2.new(1, 0, 1, -51)
	SelectorCatcher.ZIndex = 150
	SelectorCatcher.Visible = false
	SelectorCatcher.Parent = MainFrame

	local SelectorPanelSeparator = Instance.new("Frame")
	SelectorPanelSeparator.Name = "SelectorPanelSeparator"
	SelectorPanelSeparator.BackgroundColor3 = themeColorFor("38,38,44", CurrentThemeName or "Dark")
	SelectorPanelSeparator.BorderSizePixel = 0
	SelectorPanelSeparator.Position = UDim2.new(0, 0, 0, 0)
	SelectorPanelSeparator.Size = UDim2.new(0, 1, 1, 0)
	SelectorPanelSeparator.ZIndex = 201
	SelectorPanelSeparator.Parent = SelectorPanel

	local SelectorPanelTitle = Instance.new("TextLabel")
	SelectorPanelTitle.Name = "SelectorPanelTitle"
	SelectorPanelTitle.Size = UDim2.new(1, -24, 0, 30)
	SelectorPanelTitle.Position = UDim2.new(0, 8, 0, 6) -- FIXED: Moved slightly left and higher
	SelectorPanelTitle.BackgroundTransparency = 1
	SelectorPanelTitle.Font = Enum.Font.GothamBold
	SelectorPanelTitle.Text = "Select Option"
	SelectorPanelTitle.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	mTS(SelectorPanelTitle, 14)
	SelectorPanelTitle.ZIndex = 202
	SelectorPanelTitle.Parent = SelectorPanel

	-- Search Container (Modernized & High-Contrast)
	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.BackgroundColor3 = themeColorFor("28,28,34", CurrentThemeName or "Dark") -- Higher contrast
	SearchContainer.Size = UDim2.new(1, -24, 0, 32)
	SearchContainer.Position = UDim2.new(0, 12, 0, 38) -- FIXED: Improved spacing relative to title
	SearchContainer.ZIndex = 202
	SearchContainer.Parent = SelectorPanel

			local SearchCorner = Instance.new("UICorner")
			SearchCorner.CornerRadius = UDim.new(0, 12)
			SearchCorner.Parent = SearchContainer

	local SearchStroke = Instance.new("UIStroke")
	SearchStroke.Color = themeColorFor("55,55,65", CurrentThemeName or "Dark") -- Higher contrast border
	SearchStroke.Thickness = 1
	SearchStroke.Parent = SearchContainer

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Size = UDim2.new(0, 16, 0, 16)
	SearchIcon.Position = UDim2.new(0, 8, 0.5, -8)
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.Image = Astral.Icons.search
	SearchIcon.ImageColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
	SearchIcon.ZIndex = 203
	SearchIcon.Parent = SearchContainer

	local SearchInput = Instance.new("TextBox")
	SearchInput.Size = UDim2.new(1, -54, 1, 0)
	SearchInput.Position = UDim2.new(0, 30, 0, 0)
	SearchInput.BackgroundTransparency = 1
	SearchInput.Font = Enum.Font.Gotham
	tr(SearchInput, "Search...", "PlaceholderText")
	SearchInput.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
	SearchInput.Text = ""
	SearchInput.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
	mTS(SearchInput, 12)
	SearchInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchInput.ZIndex = 203
	SearchInput.Parent = SearchContainer

	-- Clear Search Button
	local ClearSearchBtn = Instance.new("ImageButton")
	ClearSearchBtn.Name = "ClearSearchBtn"
	ClearSearchBtn.Size = UDim2.new(0, 14, 0, 14)
	ClearSearchBtn.Position = UDim2.new(1, -24, 0.5, -7)
	ClearSearchBtn.BackgroundTransparency = 1
	ClearSearchBtn.Image = Astral.Icons.Close
	ClearSearchBtn.ImageColor3 = themeColorFor("140,140,145", CurrentThemeName or "Dark")
	ClearSearchBtn.Visible = false
	ClearSearchBtn.ZIndex = 204
	ClearSearchBtn.Parent = SearchContainer

	ClearSearchBtn.MouseButton1Click:Connect(function()
		SearchInput.Text = ""
	end)

	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		ClearSearchBtn.Visible = (SearchInput.Text ~= "")
	end)

	-- Options Scroll Frame
	local OptionsScroll = Instance.new("ScrollingFrame")
	OptionsScroll.Name = "OptionsScroll"
	OptionsScroll.BackgroundColor3 = themeColorFor("20,20,24", CurrentThemeName or "Dark")
	OptionsScroll.BackgroundTransparency = 0
	OptionsScroll.BorderSizePixel = 0
	OptionsScroll.ScrollBarThickness = 3
	OptionsScroll.ScrollBarImageColor3 = themeColorFor("70,70,75", CurrentThemeName or "Dark")
	OptionsScroll.ZIndex = 202
	OptionsScroll.Parent = SelectorPanel

	local OptionsCorner = Instance.new("UICorner")
	OptionsCorner.CornerRadius = UDim.new(0, 8)
	OptionsCorner.Parent = OptionsScroll

	local OptionsStroke = Instance.new("UIStroke")
	OptionsStroke.Color = themeColorFor("52,52,60", CurrentThemeName or "Dark")
	OptionsStroke.Thickness = 1
	OptionsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	OptionsStroke.Parent = OptionsScroll

	local OptionsPadding = Instance.new("UIPadding")
	OptionsPadding.PaddingLeft = UDim.new(0, 6)
	OptionsPadding.PaddingRight = UDim.new(0, 6)
	OptionsPadding.PaddingTop = UDim.new(0, 6)
	OptionsPadding.PaddingBottom = UDim.new(0, 6)
	OptionsPadding.Parent = OptionsScroll

	local OptionsList = Instance.new("UIListLayout")
	OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
	OptionsList.Padding = UDim.new(0, 8)
	OptionsList.Parent = OptionsScroll

	local selectorOpen = false
	local activeSelectorCallback = nil
	local activeSelectorButtonText = nil
	local activeSelectorOptions = {}
	local activeSelectorSearch = false
	local searchConn = nil
	local activeSelectorRefresh = nil

	local function openSelector(title, options, current, searchEnabled, callback, buttonTextLabel, isMulti, numberBoxes)
		if pickerOpen then closeColorPicker() end
		
		SelectorPanelTitle.Text = translateText(title)
		activeSelectorCallback = callback
		activeSelectorButtonText = buttonTextLabel
		activeSelectorOptions = options
		activeSelectorSearch = searchEnabled
		SearchInput.Text = ""

		SearchContainer.Visible = searchEnabled
		if searchEnabled then
			OptionsScroll.Position = UDim2.new(0, 12, 0, 76)
			OptionsScroll.Size = UDim2.new(1, -24, 1, -88)
		else
			OptionsScroll.Position = UDim2.new(0, 12, 0, 42)
			OptionsScroll.Size = UDim2.new(1, -24, 1, -54)
		end

		-- Parse current selection for multi-select
		local selectedSet = {}
		if isMulti and current and current ~= "None" then
			for item in string.gmatch(current, "([^,]+)") do
				local trimmed = string.match(item, "^%s*(.-)%s*$")
				if trimmed and trimmed ~= "" then
					selectedSet[trimmed] = true
				end
			end
		end

		local function populate(filter)
			for _, child in ipairs(OptionsScroll:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			for _, option in ipairs(options) do
				local optionStr = tostring(option)
				local shownStr = translateText(optionStr)
				if filter and filter ~= "" then
					local f = string.lower(filter)
					local hitO = string.find(string.lower(optionStr), f, 1, true)
					local hitS = string.find(string.lower(shownStr), f, 1, true)
					if not hitO and not hitS then
						continue
					end
				end

				local isSelected = false
				if isMulti then
					isSelected = not not selectedSet[optionStr]
				else
					isSelected = (current == optionStr)
				end

				-- COPIED FROM GOOD UI: Indicator + horizontal layout + hover
				local OptionBtn = Instance.new("TextButton")
				OptionBtn.Name = optionStr .. "_Option"
				OptionBtn.Size = UDim2.new(1, 0, 0, 38)
				OptionBtn.BackgroundColor3 = isSelected and Color3.new(AccentColor.R * 0.25, AccentColor.G * 0.25, AccentColor.B * 0.25) or themeColorFor("18,18,22", CurrentThemeName or "Dark")
				OptionBtn.BorderSizePixel = 0
				OptionBtn.Text = ""
				OptionBtn.AutoButtonColor = false
				OptionBtn.ZIndex = 203
				OptionBtn.Parent = OptionsScroll

				local OptionCorner = Instance.new("UICorner")
				OptionCorner.CornerRadius = UDim.new(0, 6)
				OptionCorner.Parent = OptionBtn

				local OptionStroke = Instance.new("UIStroke")
				OptionStroke.Color = isSelected and AccentColor or themeColorFor("50,50,55", CurrentThemeName or "Dark")
				OptionStroke.Thickness = 1
				OptionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				OptionStroke.Parent = OptionBtn

				local OptLayout = Instance.new("UIListLayout")
				OptLayout.FillDirection = Enum.FillDirection.Horizontal
				OptLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
				OptLayout.Padding = UDim.new(0, 10)
				OptLayout.Parent = OptionBtn
				local OptPadding = Instance.new("UIPadding")
				OptPadding.PaddingLeft = UDim.new(0, 12)
				OptPadding.PaddingRight = UDim.new(0, 12)
				OptPadding.Parent = OptionBtn

				local Indicator = Instance.new("Frame")
				Indicator.Name = "Indicator"
				Indicator.Size = UDim2.fromOffset(16, 16)
				Indicator.BackgroundColor3 = isSelected and AccentColor or themeColorFor("36,36,40", CurrentThemeName or "Dark")
				Indicator.BorderSizePixel = 0
				Indicator.LayoutOrder = 1
				Indicator.ZIndex = 204
				Indicator.Parent = OptionBtn
				local IndicatorCorner = Instance.new("UICorner")
				IndicatorCorner.CornerRadius = UDim.new(1, 0)
				IndicatorCorner.Parent = Indicator
				local IndicatorStroke = Instance.new("UIStroke")
				IndicatorStroke.Thickness = 1
				IndicatorStroke.Color = isSelected and AccentColor or themeColorFor("50,50,55", CurrentThemeName or "Dark")
				IndicatorStroke.Parent = Indicator
				if isSelected then
					local Check = Instance.new("ImageLabel")
					Check.Size = UDim2.fromScale(0.8, 0.8)
					Check.AnchorPoint = Vector2.new(0.5, 0.5)
					Check.Position = UDim2.fromScale(0.5, 0.5)
					Check.BackgroundTransparency = 1
					Astral.ApplyIcon(Check, Astral.Icons.Checkmark)
					Check.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					Check.ZIndex = 204
					Check.Parent = Indicator
				end

				local OptionLabel = Instance.new("TextLabel")
				OptionLabel.Name = "OptLabel"
				OptionLabel.Size = UDim2.new(1, -26, 1, 0)
				OptionLabel.BackgroundTransparency = 1
				OptionLabel.Font = Enum.Font.GothamBold
				OptionLabel.Text = shownStr
				OptionLabel.TextColor3 = isSelected and AccentColor or themeColorFor("232,232,237", CurrentThemeName or "Dark")
				mTS(OptionLabel, 12)
				OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
				OptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
				OptionLabel.LayoutOrder = 2
				OptionLabel.ZIndex = 204
				OptionLabel.Parent = OptionBtn

				local nb = numberBoxes and numberBoxes[optionStr] or nil
				if nb then
					OptionLabel.Size = UDim2.new(1, -104, 1, 0)
					local NumWrap = Instance.new("Frame")
					NumWrap.Name = "NumWrap"
					NumWrap.BackgroundTransparency = 1
					NumWrap.BorderSizePixel = 0
					NumWrap.Size = UDim2.new(0, 68, 1, 0)
					NumWrap.LayoutOrder = 3
					NumWrap.Parent = OptionBtn
					local NumLayout = Instance.new("UIListLayout")
					NumLayout.FillDirection = Enum.FillDirection.Horizontal
					NumLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					NumLayout.SortOrder = Enum.SortOrder.LayoutOrder
					NumLayout.Padding = UDim.new(0, 4)
					NumLayout.Parent = NumWrap
					local NumBox = Instance.new("TextBox")
					NumBox.LayoutOrder = 1
					NumBox.Size = UDim2.new(0, 64, 0, 26)
					NumBox.BackgroundColor3 = themeColorFor("48,48,54", CurrentThemeName or "Dark")
					NumBox.BorderSizePixel = 0
					NumBox.Font = Enum.Font.GothamBold
					local initTxt = ""
					pcall(function() initTxt = tostring(nb.Get and nb.Get() or "") end)
					NumBox.Text = initTxt
					NumBox.PlaceholderText = "0"
					NumBox.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
					NumBox.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					NumBox.TextSize = 12
					NumBox.TextXAlignment = Enum.TextXAlignment.Center
					NumBox.ClearTextOnFocus = false
					NumBox.ZIndex = 205
					NumBox.Parent = NumWrap
					local NumCorner = Instance.new("UICorner")
					NumCorner.CornerRadius = UDim.new(0, 6)
					NumCorner.Parent = NumBox
					NumBox.FocusLost:Connect(function()
						pcall(function()
							if nb.Set then nb.Set(NumBox.Text) end
							if nb.Get then NumBox.Text = tostring(nb.Get()) end
						end)
					end)
					local NumStroke = Instance.new("UIStroke")
					NumStroke.Color = themeColorFor("120,120,130", CurrentThemeName or "Dark")
					NumStroke.Thickness = 1
					NumStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					NumStroke.Parent = NumBox
				end

				OptionBtn.MouseButton1Click:Connect(function()
					-- FIXED: High-performance subtle flash blue effect on click
					OptionBtn.BackgroundColor3 = Color3.new(AccentColor.R * 0.4, AccentColor.G * 0.4, AccentColor.B * 0.4)
					OptionStroke.Color = AccentColor
					
					task.delay(0.08, function()
						if isMulti then
							selectedSet[optionStr] = not selectedSet[optionStr]
							local selectedList = {}
							for _, opt in ipairs(options) do
								local optStr = tostring(opt)
								if selectedSet[optStr] then
									table.insert(selectedList, optStr)
									end
							end
						local dispList = {}
							for _, s in ipairs(selectedList) do table.insert(dispList, translateText(s)) end
						local newText = #dispList > 0 and table.concat(dispList, ", ") or translateText("None")
						buttonTextLabel.Text = newText
						SelectorPanelTitle.Text = #selectedList > 0 and (translateText(title) .. " (" .. #selectedList .. ")") or translateText(title)
							if callback then
								task.spawn(callback, selectedList)
							end
							populate(SearchInput.Text)
						else
							buttonTextLabel.Text = translateText(optionStr)
							if callback then
								task.spawn(callback, option)
							end
							closeSelector()
						end
					end)
				end)

				OptionBtn.MouseEnter:Connect(function()
					if pickerOpen or selectorOpen then return end
					if not isSelected then
						TweenService:Create(OptionBtn, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(CurrentThemeName)}):Play()
					end
				end)
				OptionBtn.MouseLeave:Connect(function()
					if not isSelected then
						TweenService:Create(OptionBtn, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(CurrentThemeName)}):Play()
					end
				end)
			end
			OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, OptionsList.AbsoluteContentSize.Y + 10)
			-- keep option rows themed if a non-dark theme is active
			if CurrentThemeName and CurrentThemeName ~= "Dark" then
				applyThemeToGui(ScreenGui, AccentColor, "Dark", CurrentThemeName)
			end
		end

		activeSelectorRefresh = function()
			populate(SearchInput.Text)
		end
		Astral._OpenSelectorRefresh = function()
			SelectorPanelTitle.Text = translateText(title)
			populate(SearchInput.Text)
		end
		populate("")

		if searchConn then searchConn:Disconnect() end
		searchConn = SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
			populate(SearchInput.Text)
		end)

		selectorOpen = true
		SelectorCatcher.Visible = true
		SelectorPanel.Size = UDim2.new(0, curPanelWidth(), 1, -51)
		TweenService:Create(SelectorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -curPanelWidth(), 0, 51)
		}):Play()
	end

	closeSelector = function()
		selectorOpen = false
		SelectorCatcher.Visible = false
		Astral._OpenSelectorRefresh = nil
		if searchConn then
			searchConn:Disconnect()
			searchConn = nil
		end
		TweenService:Create(SelectorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0, 51)
		}):Play()
	end

	-- Click anywhere outside the panel to close it
	SelectorCatcher.MouseButton1Click:Connect(function()
		if closeSelector then closeSelector() end
	end)

	-- Tab Management System
	local tabs = {}
	local layoutMode = "Auto" -- "Auto" | "OneColumn" | "TwoColumn" (Settings grid picker)
	-- (Accent engine lives at the top of MakeWindow so panels can hook in during build)
	-- Saved flags: every element with Flag = "id" registers Get/Set here
	local configFlags = {}
	local categoryHeaders = {}
	local currentTab = nil
	local layoutOrderCounter = 0

	local function switchTab(targetTab)
		if pickerOpen or selectorOpen then return end -- FIXED: Lock tab switching when panels are open
		if currentTab == targetTab then return end

		local directionUp = false
		if currentTab then
			if targetTab.Index < currentTab.Index then
				directionUp = true
			end
		end

		local oldTab = currentTab
		currentTab = targetTab

		-- Update Tab Button Visuals
		for _, tab in ipairs(tabs) do
			local isActive = (tab == targetTab)
			
			if isActive then
				tab.Gradient.Enabled = false
				-- Topbar active tab: solid accent pill
				TweenService:Create(tab.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = AccentColor,
					BackgroundTransparency = 0
				}):Play()
				TweenService:Create(tab.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Color = AccentColor,
					Transparency = 0
				}):Play()
				TweenService:Create(tab.ButtonText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				}):Play()
				if tab.IconLabel then
					TweenService:Create(tab.IconLabel, TweenInfo.new(0.2), {ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
				end
				if tab.FallbackLabel then
					TweenService:Create(tab.FallbackLabel, TweenInfo.new(0.2), {TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
				end
			else
				tab.Gradient.Enabled = false

				TweenService:Create(tab.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1
				}):Play()
				TweenService:Create(tab.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1
				}):Play()
				TweenService:Create(tab.ButtonText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")
				}):Play()
				if tab.IconLabel then
					TweenService:Create(tab.IconLabel, TweenInfo.new(0.2), {ImageColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")}):Play()
				end
				if tab.FallbackLabel then
					TweenService:Create(tab.FallbackLabel, TweenInfo.new(0.2), {TextColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")}):Play()
				end
			end
		end

		-- Perform Directional Slide Animations
		if oldTab then
			local oldTargetPos = directionUp and UDim2.new(0, 0, 1, 0) or UDim2.new(0, 0, -1, 0)
			local newStartPos = directionUp and UDim2.new(0, 0, -1, 0) or UDim2.new(0, 0, 1, 0)

			targetTab.Page.Position = newStartPos
			targetTab.Page.Visible = true
			-- Force full refresh once visible so right-column controls always show
			task.defer(function()
				pcall(function()
					if targetTab.Refresh then targetTab.Refresh() end
				end)
			end)

			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			
			local oldTween = TweenService:Create(oldTab.Page, tweenInfo, {Position = oldTargetPos})
			local newTween = TweenService:Create(targetTab.Page, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)})

			oldTween:Play()
			newTween:Play()

			task.delay(0.3, function()
				if currentTab ~= oldTab then
					oldTab.Page.Visible = false
				end
			end)
		else
			targetTab.Page.Position = UDim2.new(0, 0, 0, 0)
			targetTab.Page.Visible = true
			-- Force full refresh once visible so right-column controls always show
			task.defer(function()
				pcall(function()
					if targetTab.Refresh then targetTab.Refresh() end
				end)
			end)
		end
	end

	-- Window Methods
	local Window = {}

	function Window:AddCategory(name)
		name = tostring(name or "Category")
		layoutOrderCounter = layoutOrderCounter + 1

		-- In the topbar design categories are small inline labels in the tab strip
		local CategoryHeader = Instance.new("TextLabel")
		CategoryHeader.Name = name .. "_Header"
		CategoryHeader.BackgroundTransparency = 1
		CategoryHeader.Size = UDim2.new(0, 0, 1, 0)
		CategoryHeader.AutomaticSize = Enum.AutomaticSize.X
		CategoryHeader.Font = Enum.Font.GothamBold
		CategoryHeader.Text = string.upper(name)
		CategoryHeader.TextColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
		CategoryHeader.TextSize = 10
		CategoryHeader.TextXAlignment = Enum.TextXAlignment.Center
		CategoryHeader.TextYAlignment = Enum.TextYAlignment.Center
		CategoryHeader.LayoutOrder = layoutOrderCounter
		CategoryHeader.ZIndex = 4
		CategoryHeader.Parent = TabContainer

		local CatPad = Instance.new("UIPadding")
		CatPad.PaddingLeft = UDim.new(0, 10)
		CatPad.PaddingRight = UDim.new(0, 4)
		CatPad.Parent = CategoryHeader

		table.insert(categoryHeaders, CategoryHeader)
		return CategoryHeader
	end

	-- Always-on Settings gear (top-right) + auto Settings tab.
	-- Disable with CreateWindow({ SettingsTab = false }).
	-- Wrapped in do-end so its locals reuse registers (200 local limit).
	do
	if config.SettingsTab ~= false then
		local GearBtn = Instance.new("TextButton")
		GearBtn.Name = "SettingsGear"
		GearBtn.AnchorPoint = Vector2.new(1, 0.5)
		GearBtn.Position = UDim2.new(1, -10, 0.5, 0)
		GearBtn.Size = UDim2.new(0, 34, 0, 34)
		GearBtn.BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark")
		GearBtn.BorderSizePixel = 0
		GearBtn.Text = ""
		GearBtn.AutoButtonColor = false
		GearBtn.ZIndex = 5
		GearBtn.Parent = TopBar
		local GearCorner = Instance.new("UICorner")
		GearCorner.CornerRadius = UDim.new(0, 8)
		GearCorner.Parent = GearBtn
		local GearStroke = Instance.new("UIStroke")
		GearStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
		GearStroke.Thickness = 1
		GearStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		GearStroke.Parent = GearBtn
		local GearIcon = Instance.new("ImageLabel")
		GearIcon.Name = "GearIcon"
		GearIcon.BackgroundTransparency = 1
		GearIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		GearIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		GearIcon.Size = UDim2.new(0, 20, 0, 20)
		Astral.ApplyIcon(GearIcon, parseIcon("Badge Gear"))
		GearIcon.ImageColor3 = themeColorFor("200,200,208", CurrentThemeName or "Dark")
		GearIcon.ScaleType = Enum.ScaleType.Fit
		GearIcon.ZIndex = 6
		GearIcon.Parent = GearBtn
		GearBtn.MouseEnter:Connect(function()
			TweenService:Create(GearBtn, TweenInfo.new(0.15), { BackgroundColor3 = themeColorFor("54,54,64", CurrentThemeName or "Dark") }):Play()
		end)
		GearBtn.MouseLeave:Connect(function()
			TweenService:Create(GearBtn, TweenInfo.new(0.15), { BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark") }):Play()
		end)
		local settingsTabData = nil
		GearBtn.MouseButton1Click:Connect(function()
			if pickerOpen or selectorOpen then return end
			if not settingsTabData then
				local STab = Window:MakeTab({ "Settings", "Badge Gear" })
				-- 1) INFO: big discord card
				local infoSub = STab:AddSubTab({ Name = "Info", Icon = "Home" })
				infoSub:AddDiscordCard({ FullWidth = true, ServerData = {
					Description = "Official LumuHub Community ΓÇö Velaric ΓÇó kismile ΓÇó Lucas ΓÇó Xu",
				} })
				-- 2) TRANSLATION: custom packs, no Google. Hubs add words BEFORE CreateWindow.
				local langSub = STab:AddSubTab({ Name = "Translation", Icon = "Home" })
				langSub:AddLabel({ Title = "Language", Description = "Custom translations, no Google. Everything incl. dropdown options swaps live.", Icon = "Home" })
				do
					local langs = {}
					pcall(function() if Astral.GetLanguages then langs = Astral.GetLanguages() end end)
					if #langs == 0 then langs = { "English" } end
					langSub:AddSelector({ Title = "Language", Options = langs, Default = Astral.CurrentLanguage or "English", Icon = "Home", Callback = function(v)
						pcall(function() Astral:SetLanguage(v) end)
						pcall(function() Window:Notify({ Type = "good", Title = "Language", Message = tostring(v), Duration = 2 }) end)
					end })
				end
				-- 3) THEMES: presets + custom + background + transparency (merged)
				local themeSub = STab:AddSubTab({ Name = "Themes", Icon = "Chromatic Key1" })
				themeSub:AddSelector({ Title = "Theme", Description = "Recolor the whole UI live.", Options = { "Dark", "Midnight", "Purple", "Crimson", "Forest", "Ocean", "Sunset", "Rose", "Slate", "Coffee" }, Icon = "Chromatic Key1", Callback = function(v)
					pcall(function() Window:SetTheme(v) end)
				end })
				themeSub:AddColorpicker({ Title = "Accent", Description = "Your highlight color.", Default = AccentColor, Icon = "Chromatic Key1", Callback = function(c)
					pcall(function() Window:SetAccent(c) end)
				end })
				themeSub:AddButton({ Title = "Custom theme", Icon = "Badge Gear", Callback = function()
					pcall(function() Window:SetCustomTheme({ Background = Color3.fromRGB(10, 10, 14), Card = Color3.fromRGB(20, 22, 34), Accent = Color3.fromRGB(138, 90, 255) }) end)
				end })
				themeSub:AddButton({ Title = "BG image 1", Icon = "Checkmark", Callback = function()
					pcall(function() Window:SetBackground("rbxassetid://138732103165145") end)
				end })
				themeSub:AddButton({ Title = "BG image 2", Icon = "Checkmark", Callback = function()
					pcall(function() Window:SetBackground("rbxassetid://74936679753141") end)
				end })
				themeSub:AddSlider({ Title = "BG dim", Min = 0, Max = 100, Default = 35, Icon = "Badge Gear", Callback = function(v)
					pcall(function() Window:SetBackgroundDim(v / 100) end)
				end })
				themeSub:AddSlider({ Title = "UI transparency", Min = 0, Max = 70, Default = 0, Icon = "Badge Gear", Callback = function(v)
					pcall(function() Window:SetTransparency(v / 100) end)
				end })
				themeSub:AddButton({ Title = "Reset BG", Icon = "Close", Callback = function()
					pcall(function() Window:ResetBackground() end)
				end })
				-- 4) UI: sidebar/topbar choice. Saved only ΓÇö loads on NEXT execute, never now.
				local uiSub = STab:AddSubTab({ Name = "UI", Icon = "Badge Gear" })
				uiSub:AddLabel({ Title = "Layout", Description = "Applies NEXT execute, not now.", Icon = "Badge Gear" })
				uiSub:AddSelector({ Title = "Design", Options = { "Sidebar", "TopBar" }, Default = Window:GetDesign(), Icon = "Badge Gear", Callback = function(v)
					pcall(function() if Astral.SetSavedDesign then Astral.SetSavedDesign(v) end end)
					pcall(function() Window:Notify({ Type = "good", Title = "Saved", Message = "Next execute loads " .. tostring(v) .. ".", Duration = 4 }) end)
				end })
				-- 5) STATUS
				local statusSub = STab:AddSubTab({ Name = "Status", Icon = "timer" })
				statusSub:AddToggle({ Title = "Show status panels", Default = true, Icon = "timer", Callback = function(s)
					for _, sp in ipairs(statusPanels) do
						pcall(function()
							if sp.Controller and sp.Controller.SetEnabled then
								sp.Controller:SetEnabled(s)
							else
								sp.Panel.Visible = s
							end
						end)
					end
				end })
				statusSub:AddButton({ Title = "Reset panel positions", Icon = "Badge Gear", Callback = function()
					for _, sp in ipairs(statusPanels) do
						pcall(function() sp.Panel.Position = sp.DefaultPos end)
					end
				end })
				statusSub:AddSlider({ Title = "Panel size", Min = 70, Max = 130, Default = 100, Icon = "timer", Callback = function(v)
					pcall(function() Window:SetStatusScale(v / 100) end)
				end })
				-- 6) DISPLAY
				local displaySub = STab:AddSubTab({ Name = "Display", Icon = "Badge Gear" })
				displaySub:AddSlider({ Title = "UI size", Min = 70, Max = 130, Default = 100, Icon = "Badge Gear", Callback = function(v)
					pcall(function() Window:SetUIScale(v / 100) end)
				end })
				displaySub:AddSelector({ Title = "Grid columns", Description = "Layout for wide windows.", Options = { "Auto", "1 column", "2 columns" }, Icon = "Badge Gear", Callback = function(v)
					pcall(function()
						if v == "1 column" then Window:SetLayoutMode("OneColumn")
						elseif v == "2 columns" then Window:SetLayoutMode("TwoColumn")
						else Window:SetLayoutMode("Auto") end
					end)
					pcall(function() Window:Notify({ Type = "good", Title = "Layout", Message = tostring(v) .. " applied. Check another tab.", Duration = 3 }) end)
				end })
				displaySub:AddSlider({ Title = "UI transparency", Min = 0, Max = 70, Default = 0, Icon = "Badge Gear", Callback = function(v)
					pcall(function() Window:SetTransparency(v / 100) end)
				end })
				displaySub:AddToggle({ Title = "Stop button", Description = "Floating stop button.", Default = true, Icon = "Badge Gear", Callback = function(s)
					pcall(function()
						local sb = Window._AutoStop
						if sb and sb.Button then sb.Button.Visible = s end
					end)
				end })
				displaySub:AddButton({ Title = "Replay intro", Icon = "Checkmark", Callback = function()
					pcall(function() Window:PlayIntro() end)
				end })
				-- 7) DEBUG
				local dbgSub = STab:AddSubTab({ Name = "Debug", Icon = "Badge Gear" })
				dbgSub:AddButton({ Title = "Reset UI positions", Icon = "Badge Gear", Callback = function()
					pcall(function() Window:ResetUIPositions() end)
				end })
				dbgSub:AddButton({ Title = "Refresh UI", Icon = "Checkmark", Callback = function()
					pcall(function() Window:RefreshAll() end)
				end })
				dbgSub:AddButton({ Title = "Debug info", Description = "Prints to console (F9).", Icon = "Badge Gear", Callback = function()
					pcall(function() Window:DebugInfo() end)
					pcall(function() Window:Notify({ Type = "good", Title = "Debug", Message = "Printed to console (F9).", Duration = 2 }) end)
				end })
				-- 8) CONFIGS
				local configSub = STab:AddSubTab({ Name = "Configs", Icon = "Home" })
				local cfgName = "lumu_config.json"
				configSub:AddTextbox({ Title = "Config name", Placeholder = "lumu_config.json", Callback = function(t)
					if t and t ~= "" then cfgName = tostring(t) end
				end })
				configSub:AddButton({ Title = "Save config", Icon = "Checkmark", Callback = function()
					local ok2 = false
					pcall(function() ok2 = Window:SaveConfig(cfgName) end)
					pcall(function() Window:Notify({ Type = ok2 and "good" or "warning", Title = ok2 and "Saved" or "Save failed", Message = tostring(cfgName), Duration = 3 }) end)
				end })
				configSub:AddButton({ Title = "Load config", Icon = "Badge Gear", Callback = function()
					local ok2 = false
					pcall(function() ok2 = Window:LoadConfig(cfgName) end)
					pcall(function() Window:Notify({ Type = ok2 and "good" or "warning", Title = ok2 and "Loaded" or "Load failed", Message = tostring(cfgName), Duration = 3 }) end)
				end })
				local refreshFileList
				configSub:AddButton({ Title = "Delete config", Icon = "Close", Callback = function()
					local ok2 = false
					pcall(function() if delfile then delfile(cfgName); ok2 = true end end)
					pcall(function() Window:Notify({ Type = ok2 and "good" or "warning", Title = ok2 and "Deleted" or "Delete failed", Message = tostring(cfgName), Duration = 3 }) end)
					pcall(refreshFileList)
				end })
				local fileSel = nil
				refreshFileList = function()
					local files = {}
					pcall(function()
						if listfiles then
							for _, f in ipairs(listfiles("")) do
								if type(f) == "string" then
									local short = f:match("([^/\\]+)$") or f
									if short:match("^lumu_.*%.json$") then
										table.insert(files, f)
									end
								end
							end
						end
					end)
					if fileSel then
						pcall(function() fileSel:SetOptions(files) end)
					elseif #files > 0 then
						fileSel = configSub:AddSelector({ Title = "Load file", Description = "Pick a saved json.", Options = files, Icon = "Home", Callback = function(v)
							pcall(function()
								if Window:LoadConfig(v) then
									Window:Notify({ Type = "good", Title = "Loaded", Message = tostring(v), Duration = 3 })
								end
							end)
						end })
					end
				end
				refreshFileList()
				configSub:AddButton({ Title = "Rescan files", Icon = "Badge Gear", Callback = function()
					pcall(refreshFileList)
					pcall(function() Window:Notify({ Type = "good", Title = "Rescanned", Message = "Config list updated.", Duration = 2 }) end)
				end })


				settingsTabData = tabs[#tabs]
				pcall(function()
					local tb = tabs[#tabs]
					if tb and tb.Button then
						tb.Button.Visible = false
						tb.Button.Size = UDim2.new(1, 0, 0, 0)
					end
				end)
			end
			if settingsTabData then
				pcall(function() switchTab(settingsTabData) end)
			end
		end)
	end
	end
	-- Global element search (Ctrl+K): type anything, jump to any button.
	-- Zero outer locals (do-end) for the 200-local limit.
	do
	if config.SearchBar ~= false then
		local searchFlashTime = tonumber(config.SearchFlashTime) or 5
		local SearchBox = Instance.new("TextBox")
		SearchBox.Name = "GlobalSearch"
		SearchBox.AnchorPoint = Vector2.new(1, 0.5)
		SearchBox.Position = UDim2.new(1, -48, 0.5, 0)
		SearchBox.Size = UDim2.new(0, IsMobile and 140 or 220, 0, IsMobile and 28 or 30)
		SearchBox.BackgroundColor3 = themeColorFor("18,18,22", CurrentThemeName or "Dark")
		SearchBox.BorderSizePixel = 0
		SearchBox.Font = Enum.Font.Gotham
		SearchBox.Text = ""
		SearchBox.PlaceholderText = "Search..."
		SearchBox.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
		SearchBox.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		SearchBox.TextSize = IsMobile and 11 or 12
		SearchBox.TextXAlignment = Enum.TextXAlignment.Left
		SearchBox.ClearTextOnFocus = false
		SearchBox.ZIndex = 5
		SearchBox.Parent = TopBar
			local SearchCorner = Instance.new("UICorner")
			SearchCorner.CornerRadius = UDim.new(0, 4)
			SearchCorner.Parent = SearchBox
		local SearchStroke = Instance.new("UIStroke")
		SearchStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
		SearchStroke.Thickness = 1
		SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		SearchStroke.Parent = SearchBox
		local SearchPad = Instance.new("UIPadding")
		SearchPad.PaddingLeft = UDim.new(0, 10)
		SearchPad.PaddingRight = UDim.new(0, 10)
		SearchPad.Parent = SearchBox
		-- (Ctrl+K hint badge removed; shortcut still works)
		SearchBox.Focused:Connect(function()
			TweenService:Create(SearchStroke, TweenInfo.new(0.15), { Color = themeColorFor("95,95,110", CurrentThemeName or "Dark") }):Play()
		end)
		SearchBox.FocusLost:Connect(function()
			TweenService:Create(SearchStroke, TweenInfo.new(0.15), { Color = themeColorFor("50,50,55", CurrentThemeName or "Dark") }):Play()
		end)

		local Results = Instance.new("ScrollingFrame")
		Results.Name = "SearchResults"
		Results.AnchorPoint = Vector2.new(1, 0)
		Results.Position = UDim2.new(1, -48, 0, 56)
		Results.Size = UDim2.new(0, IsMobile and 140 or 220, 0, 8)
		Results.BackgroundColor3 = themeColorFor("30,30,37", CurrentThemeName or "Dark")
		Results.BorderSizePixel = 0
		Results.CanvasSize = UDim2.new(0, 0, 0, 0)
		Results.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Results.ScrollBarThickness = 3
		Results.ScrollBarImageColor3 = themeColorFor("80,80,90", CurrentThemeName or "Dark")
		Results.ScrollBarImageTransparency = 0.4
		Results.Visible = false
		Results.ZIndex = 60
		Results.Parent = MainFrame
		local ResultsCorner = Instance.new("UICorner")
		ResultsCorner.CornerRadius = UDim.new(0, 8)
		ResultsCorner.Parent = Results
		local ResultsStroke = Instance.new("UIStroke")
		ResultsStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
		ResultsStroke.Thickness = 1
		ResultsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ResultsStroke.Parent = Results
		local ResultsPad = Instance.new("UIPadding")
		ResultsPad.PaddingLeft = UDim.new(0, 4)
		ResultsPad.PaddingRight = UDim.new(0, 4)
		ResultsPad.PaddingTop = UDim.new(0, 4)
		ResultsPad.PaddingBottom = UDim.new(0, 4)
		ResultsPad.Parent = Results
		local ResultsLayout = Instance.new("UIListLayout")
		ResultsLayout.FillDirection = Enum.FillDirection.Vertical
		ResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ResultsLayout.Padding = UDim.new(0, 2)
		ResultsLayout.Parent = Results

		local function hideResults()
			Results.Visible = false
		end
		local lastMatches = {}

		local function collectMatches(q)
			local out = {}
			if q == "" then return out end
			for _, td in ipairs(tabs) do
				local tname = ""
				pcall(function() tname = (td.ButtonText and td.ButtonText.Text) or "" end)
				local els = td.Elements
				if type(els) == "table" then
					for _, el in ipairs(els) do
						local okEl, fr = pcall(function() return el.Frame or el end)
						if okEl and typeof(fr) == "Instance" and fr:IsA("GuiObject") then
							local label = fr.Name
							pcall(function()
								local tl = fr:FindFirstChild("Title", true)
								if tl and tostring(tl.Text or "") ~= "" then label = tostring(tl.Text) end
							end)
							local ll = string.lower(label)
							local hit = string.find(ll, q, 1, true) ~= nil
							if not hit then
								for w in string.gmatch(ll, "%S+") do
									if string.sub(w, 1, #q) == q or string.sub(q, 1, #w) == w then hit = true break end
								end
							end
							if hit then
								table.insert(out, { tab = td, frame = fr, sub = el.SubTabIdx or 0, title = label, tabName = tname })
								if #out >= 40 then return out end
							end
						end
					end
				end
			end
			return out
		end

		local function jumpTo(m)
			hideResults()
			pcall(function() SearchBox:ReleaseFocus() end)
			pcall(function() switchTab(m.tab) end)
			task.spawn(function()
				task.wait(0.2)
				pcall(function()
					if m.sub and m.sub ~= 0 and m.tab.SwitchSubTab then m.tab.SwitchSubTab(m.sub) end
				end)
				task.wait(0.15)
				pcall(function()
					local sc = m.tab.PageScroll
					local y = m.frame.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 80
					TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CanvasPosition = Vector2.new(0, math.max(0, y)) }):Play()
					local c0 = m.frame.BackgroundColor3
					local flashCol = c0:Lerp(AccentColor, 0.35)
					TweenService:Create(m.frame, TweenInfo.new(0.18), { BackgroundColor3 = flashCol }):Play()
					task.delay(searchFlashTime, function()
						pcall(function() TweenService:Create(m.frame, TweenInfo.new(0.25), { BackgroundColor3 = c0 }):Play() end)
					end)
				end)
			end)
		end

		local function refreshResults()
			for _, c in ipairs(Results:GetChildren()) do
				if c:IsA("GuiObject") and not c:IsA("UIListLayout") and not c:IsA("UIPadding") then pcall(function() c:Destroy() end) end
			end
			local q = string.lower(string.match(SearchBox.Text or "", "^%s*(.-)%s*$") or "")
			if q == "" then hideResults() return end
			local matches = collectMatches(q)
			lastMatches = matches
			if #matches == 0 then hideResults() return end
			for i = 1, math.min(8, #matches) do
				local m = matches[i]
				local row = Instance.new("TextButton")
				row.BackgroundColor3 = themeColorFor("32,32,40", CurrentThemeName or "Dark")
				row.BorderSizePixel = 0
				row.Size = UDim2.new(1, 0, 0, 30)
				row.Text = ""
				row.AutoButtonColor = false
				row.LayoutOrder = i
				row.Parent = Results
				local rowc = Instance.new("UICorner")
				rowc.CornerRadius = UDim.new(0, 6)
				rowc.Parent = row
				local rbar = Instance.new("Frame")
				rbar.AnchorPoint = Vector2.new(0, 0.5)
				rbar.Position = UDim2.new(0, 0, 0.5, 0)
				rbar.Size = UDim2.new(0, 3, 0, 18)
				rbar.BackgroundColor3 = AccentColor
				rbar.BackgroundTransparency = 1
				rbar.BorderSizePixel = 0
				rbar.Parent = row
				local rbarc = Instance.new("UICorner")
				rbarc.CornerRadius = UDim.new(1, 0)
				rbarc.Parent = rbar
				local rt = Instance.new("TextLabel")
				rt.BackgroundTransparency = 1
				rt.Position = UDim2.new(0, 8, 0, 0)
				rt.Size = UDim2.new(1, -110, 1, 0)
				rt.Font = Enum.Font.GothamBold
				rt.Text = m.title
				rt.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				rt.TextSize = 12
				rt.TextXAlignment = Enum.TextXAlignment.Left
				rt.TextTruncate = Enum.TextTruncate.AtEnd
				rt.Parent = row
				local rp = Instance.new("TextLabel")
				rp.BackgroundTransparency = 1
				rp.AnchorPoint = Vector2.new(1, 0.5)
				rp.Position = UDim2.new(1, -8, 0.5, 0)
				rp.Size = UDim2.new(0, 96, 0, 14)
				rp.Font = Enum.Font.Gotham
				rp.Text = m.tabName
				rp.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
				rp.TextSize = 10
				rp.TextXAlignment = Enum.TextXAlignment.Right
				rp.TextTruncate = Enum.TextTruncate.AtEnd
				rp.Parent = row
				row.MouseEnter:Connect(function()
					TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = themeColorFor("37,37,45", CurrentThemeName or "Dark") }):Play()
					TweenService:Create(rbar, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
				end)
				row.MouseLeave:Connect(function()
					TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = themeColorFor("32,32,40", CurrentThemeName or "Dark") }):Play()
					TweenService:Create(rbar, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
				end)
				row.MouseButton1Click:Connect(function() jumpTo(m) end)
			end
			Results.Size = UDim2.new(0, IsMobile and 140 or 220, 0, math.min(8, #matches) * 32 + 8)
			Results.Visible = true
		end
		SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshResults)
		SearchBox.Focused:Connect(function() refreshResults() end)
		SearchBox.FocusLost:Connect(function()
			TweenService:Create(SearchStroke, TweenInfo.new(0.15), { Color = themeColorFor("50,50,55", CurrentThemeName or "Dark") }):Play()
			task.delay(0.2, hideResults)
		end)
		UserInputService.InputBegan:Connect(function(input, gpe)
			local focused = false
			pcall(function() focused = UserInputService:GetFocusedTextBox() == SearchBox end)
			if input.KeyCode == Enum.KeyCode.Return and focused and #lastMatches > 0 then
				jumpTo(lastMatches[1])
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape and focused then
				SearchBox.Text = ""
				pcall(function() SearchBox:ReleaseFocus() end)
				return
			end
			if gpe then return end
			if input.KeyCode == Enum.KeyCode.K then
				local ctrl = false
				pcall(function() ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) end)
				if ctrl then pcall(function() SearchBox:CaptureFocus() end) end
			end
		end)
	end
	end
	function Window:MakeTab(tabConfig)
		local tabName = "Tab"
		local tabIcon = nil

		if type(tabConfig) == "table" then
			tabName = tabConfig[1] or tabConfig.Name or "Tab"
			tabIcon = parseIcon(tabConfig[2] or tabConfig.Icon)
		elseif type(tabConfig) == "string" then
			tabName = tabConfig
		end

		layoutOrderCounter = layoutOrderCounter + 1
		local tabIndex = #tabs + 1

		-- Create Tab Button (horizontal pill: icon + text, auto width)
		local TabButton = Instance.new("TextButton")
		TabButton.Name = tabName .. "_TabButton"
		TabButton.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
		TabButton.BackgroundTransparency = 1
		TabButton.BorderSizePixel = 0
		TabButton.Size = UDim2.new(0, 0, 0, 40)
		TabButton.AutomaticSize = Enum.AutomaticSize.X
		TabButton.AutoButtonColor = false
		TabButton.Text = ""
		TabButton.ClipsDescendants = true
		TabButton.LayoutOrder = layoutOrderCounter
		TabButton.ZIndex = 10

		local selectionFrame = Instance.new("Frame")
		selectionFrame.BackgroundTransparency = 1
		TabButton.SelectionImageObject = selectionFrame
		TabButton.Parent = TabContainer

		local ButtonCorner = Instance.new("UICorner")
		ButtonCorner.CornerRadius = UDim.new(0, 6)
		ButtonCorner.Parent = TabButton

		local TabStroke = Instance.new("UIStroke")
		TabStroke.Name = "TabStroke"
		TabStroke.Thickness = 1
		TabStroke.Color = themeColorFor("42,42,46", CurrentThemeName or "Dark")
		TabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		TabStroke.Transparency = 1
		TabStroke.ZIndex = 10
		TabStroke.Parent = TabButton

		local TabGradient = Instance.new("UIGradient")
		TabGradient.Name = "TabGradient"
		TabGradient.Enabled = false
		TabGradient.Parent = TabButton

		local Indicator = Instance.new("Frame")
		Indicator.Name = "Indicator"
		Indicator.Size = UDim2.new(0, 0, 0, 0)
		Indicator.Visible = false
		Indicator.Parent = TabButton

		local BtnPadding = Instance.new("UIPadding")
		BtnPadding.PaddingLeft = UDim.new(0, 14)
		BtnPadding.PaddingRight = UDim.new(0, 14)
		BtnPadding.Parent = TabButton

		local BtnLayout = Instance.new("UIListLayout")
		BtnLayout.FillDirection = Enum.FillDirection.Horizontal
		BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
		BtnLayout.Padding = UDim.new(0, 8)
		BtnLayout.Parent = TabButton

		local IconLabel = nil
		local FallbackLabel = nil

		if tabIcon then
			IconLabel = Instance.new("ImageLabel")
			IconLabel.Name = "TabIcon"
			IconLabel.BackgroundTransparency = 1
			IconLabel.Size = UDim2.new(0, 20, 0, 20)
			IconLabel.LayoutOrder = 1
			Astral.ApplyIcon(IconLabel, tabIcon)
			IconLabel.ImageColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
			IconLabel.ScaleType = Enum.ScaleType.Fit
			IconLabel.ZIndex = 11
			IconLabel.Parent = TabButton
		else
			FallbackLabel = Instance.new("TextLabel")
			FallbackLabel.Name = "FallbackIcon"
			FallbackLabel.BackgroundTransparency = 1
			FallbackLabel.Size = UDim2.new(0, 20, 0, 20)
			FallbackLabel.Font = Enum.Font.GothamBold
			FallbackLabel.Text = string.sub(tabName, 1, 1)
			FallbackLabel.TextColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
			FallbackLabel.TextSize = 15
			FallbackLabel.LayoutOrder = 1
			FallbackLabel.ZIndex = 11
			FallbackLabel.Parent = TabButton
		end

		local ButtonText = Instance.new("TextLabel")
		ButtonText.Name = "ButtonText"
		ButtonText.BackgroundTransparency = 1
		ButtonText.Size = UDim2.new(0, 0, 1, 0)
		ButtonText.AutomaticSize = Enum.AutomaticSize.X
		ButtonText.Font = Enum.Font.GothamBold
		tr(ButtonText, tabName)
		ButtonText.TextColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
		mTS(ButtonText, 14)
		ButtonText.TextXAlignment = Enum.TextXAlignment.Left
		ButtonText.TextYAlignment = Enum.TextYAlignment.Center
		ButtonText.LayoutOrder = 2
		ButtonText.ZIndex = 11
		ButtonText.Visible = not (MainFrame:GetAttribute("TabCompact") or false)
		ButtonText.Visible = not (MainFrame:GetAttribute("TabCompact") or false)
		ButtonText.Parent = TabButton

		-- Create Tab Page Frame
		local TabPage = Instance.new("Frame")
		TabPage.Name = tabName .. "_Page"
		TabPage.BackgroundTransparency = 1
		TabPage.BorderSizePixel = 0
		TabPage.Position = UDim2.new(0, 0, 1, 0)
		TabPage.Size = UDim2.new(1, 0, 1, 0)
		TabPage.Visible = false
		TabPage.Parent = ContentContainer

		-- µ¿¬σÉæ sub-tab µáÅ∩╝îΘªûµ¼íΦ░âτö¿ MakeSubTab µù╢µëìµÿ╛τñ║
		local SubTabBarHeight = IsMobile and 46 or 56
		local SubTabBtnHeight = IsMobile and 30 or 36
		local SubTabBar = Instance.new("Frame")
		SubTabBar.Name = "SubTabBar"
		SubTabBar.BackgroundColor3 = themeColorFor("24,24,30", CurrentThemeName or "Dark")
		SubTabBar.BackgroundTransparency = 0
		SubTabBar.BorderSizePixel = 0
		SubTabBar.Size = UDim2.new(1, -24, 0, SubTabBarHeight)
		SubTabBar.Position = UDim2.new(0, 12, 0, 6)
		SubTabBar.ClipsDescendants = true
		SubTabBar.Visible = false
		SubTabBar.ZIndex = 5
		SubTabBar.Parent = TabPage

		local SubTabBarCorner = Instance.new("UICorner")
		SubTabBarCorner.CornerRadius = UDim.new(0, 10)
		SubTabBarCorner.Parent = SubTabBar

		local SubTabBarStroke = Instance.new("UIStroke")
		SubTabBarStroke.Color = themeColorFor("60,60,70", CurrentThemeName or "Dark")
		SubTabBarStroke.Thickness = 1
		SubTabBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		SubTabBarStroke.Parent = SubTabBar

		-- (rounded floating card needs no separator line)

		local SubTabScroll = Instance.new("ScrollingFrame")
		SubTabScroll.Name = "SubTabScroll"
		SubTabScroll.BackgroundTransparency = 1
		SubTabScroll.BorderSizePixel = 0
		SubTabScroll.Size = UDim2.new(1, 0, 1, 0)
		SubTabScroll.Position = UDim2.new(0, 0, 0, 0)
		SubTabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		SubTabScroll.ScrollBarThickness = 0
		SubTabScroll.ScrollingDirection = Enum.ScrollingDirection.X
		SubTabScroll.ZIndex = 6
		SubTabScroll.Parent = SubTabBar

		local SubTabScrollLayout = Instance.new("UIListLayout")
		SubTabScrollLayout.FillDirection = Enum.FillDirection.Horizontal
		SubTabScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
		SubTabScrollLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		SubTabScrollLayout.Padding = UDim.new(0, 6)
		SubTabScrollLayout.Parent = SubTabScroll

		local SubTabScrollPad = Instance.new("UIPadding")
		SubTabScrollPad.PaddingLeft = UDim.new(0, 12)
		SubTabScrollPad.PaddingRight = UDim.new(0, 12)
		SubTabScrollPad.Parent = SubTabScroll

		SubTabScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SubTabScroll.CanvasSize = UDim2.new(0, SubTabScrollLayout.AbsoluteContentSize.X + 16, 0, 0)
		end)

		local subTabs = {}
		local currentSubTab = nil
		local subTabBarShown = false
		local currentBuildSubTab = 0

		-- Create Scrolling Container inside TabPage (FIXED: Changed from PageScroll to ScrollingFrame)
		local PageScroll = Instance.new("ScrollingFrame")
		PageScroll.Name = "PageScroll"
		PageScroll.BackgroundTransparency = 1
		PageScroll.BorderSizePixel = 0
		PageScroll.Size = UDim2.new(1, 0, 1, 0)
		PageScroll.Position = UDim2.new(0, 0, 0, 0)
		PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		PageScroll.ScrollBarThickness = 3
		PageScroll.ScrollBarImageColor3 = themeColorFor("50,50,55", CurrentThemeName or "Dark")
		PageScroll.Parent = TabPage

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingLeft = UDim.new(0, 12)
		PagePadding.PaddingRight = UDim.new(0, 12)
		PagePadding.PaddingTop = UDim.new(0, 12)
		PagePadding.PaddingBottom = UDim.new(0, 12)
		PagePadding.Parent = PageScroll

		-- =========================================================================
		-- HIGH-PERFORMANCE MASONRY (2-COLUMN) LAYOUT ENGINE
		-- =========================================================================
		local LeftColumn = Instance.new("Frame")
		LeftColumn.Name = "LeftColumn"
		LeftColumn.BackgroundTransparency = 1
		LeftColumn.Size = UDim2.new(0.5, -5, 0, 0)
		LeftColumn.AutomaticSize = Enum.AutomaticSize.Y
		LeftColumn.Parent = PageScroll

		local LeftLayout = Instance.new("UIListLayout")
		LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftLayout.Padding = UDim.new(0, 10)
		LeftLayout.Parent = LeftColumn

		local RightColumn = Instance.new("Frame")
		RightColumn.Name = "RightColumn"
		RightColumn.BackgroundTransparency = 1
		RightColumn.Position = UDim2.new(0.5, 5, 0, 0)
		RightColumn.Size = UDim2.new(0.5, -5, 0, 0)
		RightColumn.AutomaticSize = Enum.AutomaticSize.Y
		RightColumn.Parent = PageScroll

		local RightLayout = Instance.new("UIListLayout")
		RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightLayout.Padding = UDim.new(0, 10)
		RightLayout.Parent = RightColumn

			local elements = {}
			local forceSingleColumn = false
			-- Forced layout mode: "Auto" follows width, "OneColumn"/"TwoColumn" force it
			local function isSingleColumnNow()
				if forceSingleColumn then return true end
				if layoutMode == "OneColumn" then return true end
			if layoutMode == "TwoColumn" then return false end
			-- Invisible tabs report 0 width during build: fall back to the real
			-- window width so columns never collapse to zero and hide content.
			local w = PageScroll.AbsoluteSize.X
			if w < 10 then w = refW end
			if IsMobile then return true end
			return w < 380
		end
		local function GetTargetColumn()
			local lc, rc = 0, 0
			for _, c in ipairs(LeftColumn:GetChildren()) do if c:IsA("GuiObject") and not c:IsA("UIListLayout") and not c:IsA("UIPadding") then lc += 1 end end
			for _, c in ipairs(RightColumn:GetChildren()) do if c:IsA("GuiObject") and not c:IsA("UIListLayout") and not c:IsA("UIPadding") then rc += 1 end end
			return lc <= rc and LeftColumn or RightColumn
		end

		local function distributeElements()
			local isSingleColumn = isSingleColumnNow()

			local leftHeight = 0
			local rightHeight = 0

			for _, item in ipairs(elements) do
				if isSingleColumn then
					item.Frame.Parent = LeftColumn
					item.Frame.Size = UDim2.new(1, 0, 0, item.Height)
				else
					-- Explicit Left/Right choice wins over auto-balancing
					local forced = item.ForcedColumn
					if forced == LeftColumn then
						item.Frame.Parent = LeftColumn
						item.Frame.Size = UDim2.new(1, 0, 0, item.Height)
						leftHeight = leftHeight + item.Height + 10
					elseif forced == RightColumn then
						item.Frame.Parent = RightColumn
						item.Frame.Size = UDim2.new(1, 0, 0, item.Height)
						rightHeight = rightHeight + item.Height + 10
					elseif leftHeight <= rightHeight then
						item.Frame.Parent = LeftColumn
						item.Frame.Size = UDim2.new(1, 0, 0, item.Height)
						leftHeight = leftHeight + item.Height + 10
					else
						item.Frame.Parent = RightColumn
						item.Frame.Size = UDim2.new(1, 0, 0, item.Height)
						rightHeight = rightHeight + item.Height + 10
					end
				end
			end
		end

		local canvasDebounce = false
		local function updateCanvas()
			if canvasDebounce then return end
			canvasDebounce = true
			task.defer(function()
				local isSingleColumn = isSingleColumnNow()
				local maxHeight = isSingleColumn and LeftLayout.AbsoluteContentSize.Y or math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y)
				PageScroll.CanvasSize = UDim2.new(0, 0, 0, maxHeight + 24)
				canvasDebounce = false
			end)
		end

		-- Full refresh: column visibility + distribution + canvas.
		-- Called on tab show, resize and mode switch so right-column
		-- controls can never stay invisible.
		local function refreshTabColumns()
			if isSingleColumnNow() then
				LeftColumn.Size = UDim2.new(1, 0, 0, 0)
				RightColumn.Visible = false
			else
				LeftColumn.Size = UDim2.new(0.5, -5, 0, 0)
				RightColumn.Size = UDim2.new(0.5, -5, 0, 0)
				RightColumn.Position = UDim2.new(0.5, 5, 0, 0)
				RightColumn.Visible = true
			end
		end

		LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
		RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
		PageScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			refreshTabColumns()
			distributeElements()
		end)


		-- sub-tab Φ┐çµ╗ñ∩╝ÜσÅ¬µÿ╛τñ║σ╜ôσëì sub-tab µ│¿σåîτÜäσàâτ┤á∩╝îSubTabIdx = 0 τÜäσ╕╕Θ⌐╗
		local function applySubTabFilter()
			for _, item in ipairs(elements) do
				local idx = item.SubTabIdx or 0
				item.Frame.Visible = (idx == 0) or (idx == currentSubTab)
			end
			updateCanvas()
		end

		-- sub-tab σêçµìó∩╝ÜµîëΘÆ«Θ½ÿΣ║« + ΘçìµÄÆσÅ»Φºüσàâτ┤á
		local function switchSubTab(idx)
			if currentSubTab == idx then return end
			currentSubTab = idx
			for _, st in ipairs(subTabs) do
				local on = (st.Index == idx)
				TweenService:Create(st.Button, TweenInfo.new(0.18), {
					BackgroundColor3 = on and AccentColor or themeColorFor("32,32,40", CurrentThemeName or "Dark"),
					BackgroundTransparency = 0
				}):Play()
				TweenService:Create(st.BStroke, TweenInfo.new(0.18), {
					Color = themeColorFor("70,70,80", CurrentThemeName or "Dark"),
					Transparency = 0.5
				}):Play()
				TweenService:Create(st.BText, TweenInfo.new(0.18), {
					TextColor3 = on and themeColorFor("255,255,255", CurrentThemeName or "Dark") or themeColorFor("160,160,168", CurrentThemeName or "Dark")
				}):Play()
			end
			applySubTabFilter()
			task.defer(function()
				pcall(function()
					refreshTabColumns()
					distributeElements()
					updateCanvas()
				end)
			end)
		end

		-- re-tint the ACTIVE sub-tab pill on accent/theme change (it keeps a stale color otherwise)
		onAccentChange(function(c)
			pcall(function()
				for _, st in ipairs(subTabs) do
					if st.Index == currentSubTab then
						st.Button.BackgroundColor3 = c
					end
				end
			end)
		end)

		local tabData = {
			Button = TabButton,
			Corner = ButtonCorner,
			Stroke = TabStroke,
			Gradient = TabGradient,
			ButtonText = ButtonText,
			SwitchSubTab = switchSubTab,
			Indicator = Indicator,
			IconLabel = IconLabel,
			FallbackLabel = FallbackLabel,
			Page = TabPage,
			Index = tabIndex,
			Elements = {},
			PageScroll = PageScroll,
			LeftColumn = LeftColumn,
			RightColumn = RightColumn,
			LeftLayout = LeftLayout,
			RightLayout = RightLayout,
			Refresh = function()
				refreshTabColumns()
				distributeElements()
				updateCanvas()
				task.delay(0.35, function() pcall(updateCanvas) end)
			end
		}

		table.insert(tabs, tabData)

		-- Hover Effects (inactive tabs are transparent: hover shows a soft fill)
		TabButton.MouseEnter:Connect(function()
			if pickerOpen or selectorOpen then return end
			if currentTab ~= tabData then
				TweenService:Create(TabButton, TweenInfo.new(0.15), {
					BackgroundColor3 = AccentColor,
					BackgroundTransparency = 0.88
				}):Play()
				TweenService:Create(TabStroke, TweenInfo.new(0.15), {
					Transparency = 0.85
				}):Play()
				TweenService:Create(ButtonText, TweenInfo.new(0.15), {
					TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				}):Play()
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
				end
				if FallbackLabel then
					TweenService:Create(FallbackLabel, TweenInfo.new(0.15), {TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
				end
			end
		end)

		TabButton.MouseLeave:Connect(function()
			if pickerOpen or selectorOpen then return end
			if currentTab ~= tabData then
				TweenService:Create(TabButton, TweenInfo.new(0.15), {
					BackgroundTransparency = 1
				}):Play()
				TweenService:Create(TabStroke, TweenInfo.new(0.15), {
					Transparency = 1
				}):Play()
				TweenService:Create(ButtonText, TweenInfo.new(0.15), {
					TextColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")
				}):Play()
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")}):Play()
				end
				if FallbackLabel then
					TweenService:Create(FallbackLabel, TweenInfo.new(0.15), {TextColor3 = themeColorFor("170,170,178", CurrentThemeName or "Dark")}):Play()
				end
			end
		end)

		TabButton.MouseButton1Click:Connect(function()
			-- ignore the click that ends a drag-scroll
			if MainFrame:GetAttribute("TabDragMoved") then return end
			if not pickerOpen and not selectorOpen then -- FIXED: Prevent tab switching when panels are open
				switchTab(tabData)
			end
		end)

		if tabIndex == 1 then
			-- Never let a tab-switch error abort the whole UI build
			local okSwitch, errSwitch = pcall(switchTab, tabData)
			if not okSwitch then
				warn("[Astral] first tab switch failed: " .. tostring(errSwitch))
			end
		end

		-- Tab Object API
		local TabObject = {}
		local elementCounter = 0

		local function registerElement(frame, height, position)
			elementCounter = elementCounter + 1
			frame.LayoutOrder = elementCounter
			-- Explicit "Left"/"Right" wins, otherwise auto-balance by count
			local forced = nil
			if position == "Left" then
				forced = LeftColumn
			elseif position == "Right" then
				forced = RightColumn
			end
			local col = forced or GetTargetColumn()
			frame.Parent = col
			frame.Size = UDim2.new(1,0,0,height)
			frame:SetAttribute("SubTabIdx", currentBuildSubTab)
			table.insert(elements, {Frame = frame, Height = height, OriginalColumn = col, ForcedColumn = forced, SubTabIdx = currentBuildSubTab})
			table.insert(tabData.Elements, elements[#elements])
			Window._TransparencyTargets = Window._TransparencyTargets or {}
			table.insert(Window._TransparencyTargets, {Frame = frame, Base = frame.BackgroundTransparency or 0})
			if (Window._TransparencyCurrent or 0) > 0 then
				pcall(function() frame.BackgroundTransparency = math.clamp((frame.BackgroundTransparency or 0) + Window._TransparencyCurrent, 0, 0.9) end)
			end
			-- if a non-dark theme is active, theme just this new element (cheap subtree pass)
			if CurrentThemeName and CurrentThemeName ~= "Dark" then
				pcall(function() applyThemeToGui(frame, AccentColor, "Dark", CurrentThemeName) end)
			end
			updateCanvas()
			applySubTabFilter()
		end

		-- AddButton: COPIED FROM GOOD UI (Script_with_Example) - right_arrow + hover, no click_icon
		function TabObject:AddButton(buttonConfig)
			buttonConfig = buttonConfig or {}
			local title = buttonConfig.Title or "Button"
			local description = buttonConfig.Description
			local callback = buttonConfig.Callback or function() end
			local icon = parseIcon(buttonConfig.Icon)
			local hasDesc = description and description ~= ""
			local calculatedHeight = IsMobile and 50 or 64

			local ButtonFrame = Instance.new("TextButton")
			ButtonFrame.Name = title .. "_Button"
			ButtonFrame.BackgroundColor3 = themeColorFor("33,33,39", CurrentThemeName or "Dark")
			ButtonFrame.BorderSizePixel = 0
			ButtonFrame.Size = UDim2.new(1, 0, 0, calculatedHeight)
			ButtonFrame.Text = ""
			ButtonFrame.AutoButtonColor = false
			ButtonFrame.Parent = nil

			local ButtonCorner = Instance.new("UICorner")
			ButtonCorner.CornerRadius = UDim.new(0, 8)
			ButtonCorner.Parent = ButtonFrame

			local ButtonStroke = Instance.new("UIStroke")
			ButtonStroke.Thickness = 1
			ButtonStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ButtonStroke.Parent = ButtonFrame

			local ButtonScale = Instance.new("UIScale")
			ButtonScale.Scale = 1
			ButtonScale.Parent = ButtonFrame

			if icon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 10, 0.5, IsMobile and -16 or -21)
				IconContainer.Size = UDim2.new(0, IsMobile and 32 or 42, 0, IsMobile and 32 or 42)
				IconContainer.Parent = ButtonFrame
				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer
				local IconStroke = Instance.new("UIStroke")
				IconStroke.Thickness = 1.5
				IconStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconStroke.Transparency = 0.3
				IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconStroke.Parent = IconContainer
				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 20 or 26, 0, IsMobile and 20 or 26)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 62, 0, 0) or UDim2.new(0, 14, 0, 0)
			TextContainer.Size = icon and UDim2.new(1, -116, 1, 0) or UDim2.new(1, -76, 1, 0)
			TextContainer.Parent = ButtonFrame
			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 1)
			TextListLayout.Parent = TextContainer
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 11)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextWrapped = false
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = TextContainer
			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 14)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextWrapped = true
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = TextContainer
			end

			-- Good UI right_arrow (not click_icon) with hover
			local ActionArrow = Instance.new("ImageLabel")
			ActionArrow.Name = "ActionArrow"
			ActionArrow.BackgroundTransparency = 1
			ActionArrow.Position = UDim2.new(1, -34, 0.5, -10)
			ActionArrow.Size = UDim2.new(0, 20, 0, 20)
			ActionArrow.Image = Astral.Icons.right_arrow
			ActionArrow.ImageColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
			ActionArrow.ScaleType = Enum.ScaleType.Fit
			ActionArrow.Parent = ButtonFrame

			-- Lock state: gray overlay + lock icon, clicks + hover disabled
			local locked = buttonConfig.Locked or false
			local LockOverlay = Instance.new("Frame")
			LockOverlay.Name = "LockOverlay"
			LockOverlay.BackgroundColor3 = themeColorFor("0,0,0", CurrentThemeName or "Dark")
			LockOverlay.BackgroundTransparency = 0.55
			LockOverlay.BorderSizePixel = 0
			LockOverlay.Size = UDim2.new(1, 0, 1, 0)
			LockOverlay.Visible = locked
			LockOverlay.ZIndex = 12
			LockOverlay.Active = true
			LockOverlay.Parent = ButtonFrame

			local LockOverlayCorner = Instance.new("UICorner")
			LockOverlayCorner.CornerRadius = UDim.new(0, 8)
			LockOverlayCorner.Parent = LockOverlay

			local LockIcon = Instance.new("ImageLabel")
			LockIcon.Name = "LockIcon"
			LockIcon.BackgroundTransparency = 1
			LockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			LockIcon.Position = UDim2.new(1, -24, 0.5, 0)
			LockIcon.Size = UDim2.new(0, 20, 0, 20)
			LockIcon.Image = "rbxassetid://15117261700"
			LockIcon.ImageColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
			LockIcon.ScaleType = Enum.ScaleType.Fit
			LockIcon.Visible = locked
			LockIcon.ZIndex = 13
			LockIcon.Parent = ButtonFrame

			local function applyLock()
				LockOverlay.Visible = locked
				LockIcon.Visible = locked
				ActionArrow.Visible = not locked
			end
			applyLock()

			ButtonFrame.MouseButton1Click:Connect(function()
				if locked then return end
				task.spawn(callback)
			end)
			ButtonFrame.InputBegan:Connect(function(input)
				if locked then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					TweenService:Create(ButtonScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.95}):Play()
				end
			end)
			ButtonFrame.InputEnded:Connect(function(input)
				if locked then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					TweenService:Create(ButtonScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
				end
			end)
			ButtonFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				if locked then return end
				TweenService:Create(ButtonFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ActionArrow, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")}):Play()
			end)
			ButtonFrame.MouseLeave:Connect(function()
				if locked then return end
				TweenService:Create(ButtonFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ActionArrow, TweenInfo.new(0.15), {ImageColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")}):Play()
			end)

			registerElement(ButtonFrame, calculatedHeight, buttonConfig.Position)

			task.defer(function()
				pcall(function()
					local availW = math.max(40, TextContainer.AbsoluteSize.X - 4)
					local bound = game:GetService("TextService"):GetTextSize(TitleLabel.Text, 11, Enum.Font.GothamBold, Vector2.new(availW, 10000))
					local lines = math.max(1, math.ceil(bound.Y / 14))
					if lines > 1 then
						lines = math.min(lines, 3)
						TitleLabel.TextWrapped = true
						TitleLabel.TextTruncate = Enum.TextTruncate.None
						TitleLabel.Size = UDim2.new(1, 0, 0, 14 * lines)
						local newH = calculatedHeight + 14 * (lines - 1)
						ButtonFrame.Size = UDim2.new(1, 0, 0, newH)
						for _, el in ipairs(elements) do
							if el.Frame == ButtonFrame then el.Height = newH break end
						end
						distributeElements()
						updateCanvas()
					end
				end)
			end)

			local ButtonController = {}
			function ButtonController:SetLocked(state)
				locked = not not state
				applyLock()
			end
			function ButtonController:IsLocked()
				return locked
			end
			return ButtonController
		end

		-- AddToggle Implementation (FIXED: Standardized to exactly 60px height)
		function TabObject:AddToggle(toggleConfig)
			toggleConfig = toggleConfig or {}
			local title = toggleConfig.Title or "Toggle"
			local description = toggleConfig.Description
			local default = toggleConfig.Default or false
			local callback = toggleConfig.Callback or function() end
			local icon = parseIcon(toggleConfig.Icon)
			local hasDesc = description and description ~= ""
			local calculatedHeight = IsMobile and 50 or 64
			local TargetColumn = GetTargetColumn()
			local ToggleFrame = Instance.new("TextButton")
			ToggleFrame.Name = title .. "_Toggle"
			ToggleFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			ToggleFrame.BorderSizePixel = 0
			ToggleFrame.Text = ""
			ToggleFrame.AutoButtonColor = false
			ToggleFrame.LayoutOrder = elementCounter + 1
			local ToggleCorner = Instance.new("UICorner")
			ToggleCorner.CornerRadius = UDim.new(0, 8)
			ToggleCorner.Parent = ToggleFrame
			local ToggleStroke = Instance.new("UIStroke")
			ToggleStroke.Thickness = 1
			ToggleStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ToggleStroke.Parent = ToggleFrame
			if icon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 10, 0.5, IsMobile and -16 or -21)
				IconContainer.Size = UDim2.new(0, IsMobile and 32 or 42, 0, IsMobile and 32 or 42)
				IconContainer.Parent = ToggleFrame
				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer
				local IconStroke = Instance.new("UIStroke")
				IconStroke.Thickness = 1.5
				IconStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconStroke.Transparency = 0.3
				IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconStroke.Parent = IconContainer
				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 20 or 26, 0, IsMobile and 20 or 26)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 62, 0, 0) or UDim2.new(0, 14, 0, 0)
			TextContainer.Size = icon and UDim2.new(1, -146, 1, 0) or UDim2.new(1, -96, 1, 0)
			TextContainer.Parent = ToggleFrame
			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 1)
			TextListLayout.Parent = TextContainer
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 11)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextWrapped = false
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = TextContainer
			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 24)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextWrapped = true
				DescLabel.Parent = TextContainer
			end
			local SwitchTrack = Instance.new("Frame")
			SwitchTrack.Name = "SwitchTrack"
			SwitchTrack.BackgroundColor3 = default and AccentColor or themeColorFor("45,45,50", CurrentThemeName or "Dark")
			SwitchTrack.BorderSizePixel = 0
			SwitchTrack.Position = UDim2.new(1, -80, 0.5, -16)
			SwitchTrack.Size = UDim2.new(0, 68, 0, 32)
			SwitchTrack.Parent = ToggleFrame
			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(0, 8)
			TrackCorner.Parent = SwitchTrack

			local TrackStroke = Instance.new("UIStroke")
			TrackStroke.Color = themeColorFor("62,62,72", CurrentThemeName or "Dark")
			TrackStroke.Thickness = 1.2
			TrackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			TrackStroke.Parent = SwitchTrack
			local SwitchThumb = Instance.new("Frame")
			SwitchThumb.Name = "SwitchThumb"
			SwitchThumb.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			SwitchThumb.BorderSizePixel = 0
			SwitchThumb.Position = default and UDim2.new(1, -31, 0.5, -14) or UDim2.new(0, 3, 0.5, -14)
			SwitchThumb.Size = UDim2.new(0, 28, 0, 28)
			SwitchThumb.Parent = SwitchTrack
			local ThumbCorner = Instance.new("UICorner")
			ThumbCorner.CornerRadius = UDim.new(0, 6)
			ThumbCorner.Parent = SwitchThumb
			local enabled = default
			local function toggle(state)
				if state == nil then enabled = not enabled else enabled = state end
				local targetTrackColor = enabled and AccentColor or themeColorFor("45,45,50", CurrentThemeName or "Dark")
				local targetThumbPos = enabled and UDim2.new(1, -31, 0.5, -14) or UDim2.new(0, 3, 0.5, -14)
				TweenService:Create(SwitchTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetTrackColor}):Play()
				TweenService:Create(SwitchThumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetThumbPos}):Play()
				task.spawn(callback, enabled)
			end
			ToggleFrame.MouseButton1Click:Connect(function() toggle() end)
			ToggleFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
			end)
			ToggleFrame.MouseLeave:Connect(function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
			end)
			registerElement(ToggleFrame, calculatedHeight, toggleConfig.Position)

			-- Follow theme accent while ON
			onAccentChange(function(c)
				if enabled then
					SwitchTrack.BackgroundColor3 = c
				end
			end)
			local ToggleController = {}
			function ToggleController:Set(state) toggle(state) end
			function ToggleController:Get() return enabled end
			if toggleConfig.Flag and toggleConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = toggleConfig.Flag, Kind = "toggle",
					Get = function() return enabled end,
					Set = function(v) ToggleController:Set(v) end})
			end
			table.insert(Astral.Registry, ToggleController)
			return ToggleController
		end

		-- AddTick Implementation (FIXED: Standardized to exactly 60px height)
		function TabObject:AddTick(tickConfig)
			tickConfig = tickConfig or {}
			local title = tickConfig.Title or "Tick"
			local description = tickConfig.Description
			local default = tickConfig.Default or false
			local callback = tickConfig.Callback or function() end
			local icon = parseIcon(tickConfig.Icon)

			local hasDesc = description and description ~= ""
			local calculatedHeight = 60 -- FIXED: Standardized to exactly 60px height

			local TickFrame = Instance.new("TextButton")
			TickFrame.Name = title .. "_Tick"
			TickFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			TickFrame.BorderSizePixel = 0
			TickFrame.Text = ""
			TickFrame.AutoButtonColor = false

			local TickCorner = Instance.new("UICorner")
			TickCorner.CornerRadius = UDim.new(0, 12) -- Made corner radius bigger
			TickCorner.Parent = TickFrame

			local TickStroke = Instance.new("UIStroke")
			TickStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			TickStroke.Thickness = 1.2
			TickStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			TickStroke.Parent = TickFrame

			-- Left Icon Container (Enlarged with High-Contrast Outline) - OPTIONAL
			local IconContainer = nil
			if icon then
				IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 8, 0.5, IsMobile and -17 or -22)
				IconContainer.Size = UDim2.new(0, IsMobile and 34 or 44, 0, IsMobile and 34 or 44)
				IconContainer.Parent = TickFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 8)
				IconCorner.Parent = IconContainer

				local IconContainerStroke = Instance.new("UIStroke")
				IconContainerStroke.Color = themeColorFor("70,70,75", CurrentThemeName or "Dark") -- FIXED: Light gray outline instead of black
				IconContainerStroke.Thickness = 1.5
				IconContainerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconContainerStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 22 or 30)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			-- Text Container (Title & Description)
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 62, 0, 0) or UDim2.new(0, 14, 0, 0)
			TextContainer.Size = icon and UDim2.new(1, -120, 1, 0) or UDim2.new(1, -80, 1, 0)
			TextContainer.Parent = TickFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 2)
			TextListLayout.Parent = TextContainer

			-- Title Label
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 11)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.TextWrapped = false -- Prevents text overflow
			TitleLabel.Parent = TextContainer

			-- Description Label (Optional) - FIXED: Parented to TextContainer instead of TickFrame to prevent overlap
			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 14)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = TextContainer -- FIXED: Corrected parent to TextContainer
			end

			-- Checkbox Container (Enlarged & Moved Left to avoid border)
			local Checkbox = Instance.new("Frame")
			Checkbox.Name = "Checkbox"
			Checkbox.BackgroundColor3 = default and AccentColor or themeColorFor("22,22,26", CurrentThemeName or "Dark") -- Fills with accent Color
			Checkbox.BorderSizePixel = 0
			Checkbox.Position = UDim2.new(1, -52, 0.5, -22) -- FIXED: Centered perfectly in 60px height
			Checkbox.Size = UDim2.new(0, 44, 0, 44) -- FIXED: Sized perfectly for 60px height
			Checkbox.ZIndex = 11
			Checkbox.Parent = TickFrame

			local CheckboxCorner = Instance.new("UICorner")
			CheckboxCorner.CornerRadius = UDim.new(0, 8) -- Squircle look matching image
			CheckboxCorner.Parent = Checkbox

			local CheckboxStroke = Instance.new("UIStroke")
			CheckboxStroke.Name = "CheckboxStroke"
			CheckboxStroke.Thickness = 1.5
			CheckboxStroke.Color = default and AccentColor or themeColorFor("55,55,60", CurrentThemeName or "Dark") -- Accent stroke when active
			CheckboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			CheckboxStroke.Parent = Checkbox

			-- Checkmark Icon (Enlarged to 24x24 inside the checkbox)
			local Checkmark = Instance.new("ImageLabel")
			Checkmark.Name = "Checkmark"
			Checkmark.BackgroundTransparency = 1
			Checkmark.AnchorPoint = Vector2.new(0.5, 0.5)
			Checkmark.Position = UDim2.new(0.5, 0, 0.5, 0)
			Checkmark.Size = UDim2.new(0, 30, 0, 30) -- FIXED: Sized perfectly inside checkbox
			Checkmark.Image = Astral.Icons.Checkmark -- Uses requested ID 12690727184
			Checkmark.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			Checkmark.ImageTransparency = default and 0 or 1
			Checkmark.ScaleType = Enum.ScaleType.Fit
			Checkmark.ZIndex = 12
			Checkmark.Parent = Checkbox

			local CheckmarkScale = Instance.new("UIScale")
			CheckmarkScale.Scale = default and 1 or 0
			CheckmarkScale.Parent = Checkmark

			local enabled = default

			local function toggle(state)
				if state == nil then
					enabled = not enabled
				else
					enabled = state
				end

				local targetBoxColor = enabled and AccentColor or themeColorFor("22,22,26", CurrentThemeName or "Dark") -- Fills with accent Color
				local targetStrokeColor = enabled and AccentColor or themeColorFor("45,45,52", CurrentThemeName or "Dark") -- Accent stroke when active
				local targetCheckScale = enabled and 1 or 0
				local targetCheckTransparency = enabled and 0 or 1

				TweenService:Create(Checkbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = targetBoxColor
				}):Play()

				TweenService:Create(CheckboxStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Color = targetStrokeColor
				}):Play()

				TweenService:Create(CheckmarkScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = targetCheckScale
				}):Play()

				TweenService:Create(Checkmark, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = targetCheckTransparency
				}):Play()

				task.spawn(callback, enabled)
			end

			TickFrame.MouseButton1Click:Connect(function()
				toggle()
			end)

			TickFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(TickFrame, TweenInfo.new(0.15), {
					BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")
				}):Play()
				TweenService:Create(TickStroke, TweenInfo.new(0.15), {
					Color = themeStrokeHover(Window.ThemeName or "Dark")
				}):Play()
			end)

			TickFrame.MouseLeave:Connect(function()
				TweenService:Create(TickFrame, TweenInfo.new(0.15), {
					BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")
				}):Play()
				TweenService:Create(TickStroke, TweenInfo.new(0.15), {
					Color = themeStroke(Window.ThemeName or "Dark")
				}):Play()
			end)

			registerElement(TickFrame, calculatedHeight, tickConfig.Position)

			-- Follow theme accent while ON
			onAccentChange(function(c)
				if enabled then
					Checkbox.BackgroundColor3 = c
					CheckboxStroke.Color = c
				end
			end)

			local TickController = {}
			function TickController:Set(state)
				toggle(state)
			end
			function TickController:Get() return enabled end
			if tickConfig.Flag and tickConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = tickConfig.Flag, Kind = "tick",
					Get = function() return enabled end,
					Set = function(v) TickController:Set(v) end})
			end
			
			-- Register controller to allow global reset
			table.insert(Astral.Registry, TickController)
			
			return TickController
		end

		-- AddColorpicker Implementation (FIXED: Standardized to exactly 60px height)
		function TabObject:AddColorpicker(pickerConfig)
			pickerConfig = pickerConfig or {}
			local title = pickerConfig.Title or "Colorpicker"
			local description = pickerConfig.Description or "Customize the UI theme"
			local default = pickerConfig.Default or themeColorFor("0,125,255", CurrentThemeName or "Dark")
			local callback = pickerConfig.Callback or function() end
			local icon = parseIcon(pickerConfig.Icon)

			local hasDesc = description and description ~= ""
			local calculatedHeight = 60 -- FIXED: Standardized to exactly 60px height

			local PickerFrame = Instance.new("TextButton")
			PickerFrame.Name = title .. "_Colorpicker"
			PickerFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			PickerFrame.BorderSizePixel = 0
			PickerFrame.Text = ""
			PickerFrame.AutoButtonColor = false

			local PickerCorner = Instance.new("UICorner")
			PickerCorner.CornerRadius = UDim.new(0, 12)
			PickerCorner.Parent = PickerFrame

			local PickerStroke = Instance.new("UIStroke")
			PickerStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			PickerStroke.Thickness = 1.2
			PickerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			PickerStroke.Parent = PickerFrame

			-- Left Icon Container (Enlarged with High-Contrast Outline) - OPTIONAL
			local IconContainer = nil
			if icon then
				IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 8, 0.5, IsMobile and -17 or -22)
				IconContainer.Size = UDim2.new(0, IsMobile and 34 or 44, 0, IsMobile and 34 or 44)
				IconContainer.Parent = PickerFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 8)
				IconCorner.Parent = IconContainer

				local IconContainerStroke = Instance.new("UIStroke")
				IconContainerStroke.Color = themeColorFor("70,70,75", CurrentThemeName or "Dark") -- FIXED: Light gray outline instead of black
				IconContainerStroke.Thickness = 1.5
				IconContainerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconContainerStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 22 or 30)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			-- Text Container (Title & Description)
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 60, 0, 0) or UDim2.new(0, 12, 0, 0) -- FIXED: Adjusted offset
			TextContainer.Size = icon and UDim2.new(1, -146, 1, 0) or UDim2.new(1, -90, 1, 0) -- FIXED: Adjusted size
			TextContainer.Parent = PickerFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 2)
			TextListLayout.Parent = TextContainer

			-- Title Label
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 14)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = TextContainer

			-- Description Label (Matches image reference)
			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 14)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = TextContainer
			end

			-- Color Preview Box (Right Side) - FIXED: Made into a wide rounded rectangle matching image reference
			local ColorPreview = Instance.new("Frame")
			ColorPreview.Name = "ColorPreview"
			ColorPreview.Size = UDim2.new(0, 64, 0, 30) -- FIXED: Sized perfectly for 60px height
			ColorPreview.Position = UDim2.new(1, -76, 0.5, -15) -- FIXED: Centered perfectly in 60px height
			ColorPreview.BackgroundColor3 = default
			ColorPreview.ZIndex = 11
			ColorPreview.Parent = PickerFrame

			local PreviewCorner = Instance.new("UICorner")
			PreviewCorner.CornerRadius = UDim.new(0, 8) -- Rounded corners matching image reference
			PreviewCorner.Parent = ColorPreview

			local PreviewStroke = Instance.new("UIStroke")
			PreviewStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			PreviewStroke.Thickness = 1.2
			PreviewStroke.Parent = ColorPreview

			local myColor = default

			PickerFrame.MouseButton1Click:Connect(function()
				openColorPicker(myColor, function(c)
					myColor = c
					ColorPreview.BackgroundColor3 = c
					task.spawn(callback, c)
				end, ColorPreview)
			end)

			PickerFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(PickerFrame, TweenInfo.new(0.15), {
					BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")
				}):Play()
				TweenService:Create(PickerStroke, TweenInfo.new(0.15), {
					Color = themeStrokeHover(Window.ThemeName or "Dark")
				}):Play()
			end)

			PickerFrame.MouseLeave:Connect(function()
				TweenService:Create(PickerFrame, TweenInfo.new(0.15), {
					BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")
				}):Play()
				TweenService:Create(PickerStroke, TweenInfo.new(0.15), {
					Color = themeStroke(Window.ThemeName or "Dark")
				}):Play()
			end)

			registerElement(PickerFrame, calculatedHeight, pickerConfig.Position)

			local ColorpickerController = {}
			function ColorpickerController:Set(color)
				local isColor = (typeof(color) == "Color3") or (type(color) == "table" and color.R ~= nil and color.G ~= nil and color.B ~= nil)
				if not isColor then return end
				myColor = color
				ColorPreview.BackgroundColor3 = color
				task.spawn(callback, color)
			end
			function ColorpickerController:Get() return myColor end
			if pickerConfig.Flag and pickerConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = pickerConfig.Flag, Kind = "color",
					Get = function() return myColor end,
					Set = function(v) ColorpickerController:Set(v) end})
			end

			return ColorpickerController
		end

		-- AddSlider Implementation (FIXED: Standardized to exactly 60px height)
		function TabObject:AddSlider(sliderConfig)
			sliderConfig = sliderConfig or {}
			local title = sliderConfig.Title or "Slider"
			local min = sliderConfig.Min or 1
			local max = sliderConfig.Max or 100
			local increase = sliderConfig.Increase or 1
			local default = sliderConfig.Default or min
			local callback = sliderConfig.Callback or function() end
			local icon = parseIcon(sliderConfig.Icon)
			local calculatedHeight = IsMobile and 56 or 64
			local icoSz = IsMobile and 32 or 42
			local icoOff = IsMobile and -16 or -21
			local icoInner = IsMobile and 20 or 26
			local textLeft = icon and (IsMobile and 48 or 62) or (IsMobile and 8 or 12)
			local titleTop = IsMobile and 6 or 10
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Name = title .. "_Slider"
			SliderFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			SliderFrame.BorderSizePixel = 0
			SliderFrame.ClipsDescendants = true
			local SliderCorner = Instance.new("UICorner")
			SliderCorner.CornerRadius = UDim.new(0, 8)
			SliderCorner.Parent = SliderFrame
			local SliderStroke = Instance.new("UIStroke")
			SliderStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			SliderStroke.Thickness = 1
			SliderStroke.Parent = SliderFrame
			if icon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.Position = UDim2.new(0, 10, 0.5, icoOff)
				IconContainer.Size = UDim2.new(0, icoSz, 0, icoSz)
				IconContainer.Parent = SliderFrame
				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer
				local IconStroke = Instance.new("UIStroke")
				IconStroke.Thickness = 1.5
				IconStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconStroke.Transparency = 0.3
				IconStroke.Parent = IconContainer
				local IconLabel = Instance.new("ImageLabel")
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, icoInner, 0, icoInner)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = icon and UDim2.new(0, textLeft, 0, titleTop) or UDim2.new(0, 12, 0, titleTop)
			TitleLabel.Size = icon and UDim2.new(1, -(textLeft + 72), 0, 16) or UDim2.new(1, -80, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 12)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = SliderFrame
			local ValueBox = Instance.new("Frame")
			ValueBox.Name = "ValueBox"
			ValueBox.BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")
			ValueBox.Position = UDim2.new(1, IsMobile and -52 or -64, 0, titleTop)
			ValueBox.Size = UDim2.new(0, IsMobile and 40 or 48, 0, IsMobile and 18 or 20)
			ValueBox.Parent = SliderFrame
			local ValueCorner = Instance.new("UICorner")
			ValueCorner.CornerRadius = UDim.new(0, 4)
			ValueCorner.Parent = ValueBox
			local ValueStroke = Instance.new("UIStroke")
			ValueStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			ValueStroke.Parent = ValueBox
			local ValueInput = Instance.new("TextBox")
			ValueInput.Name = "ValueInput"
			ValueInput.BackgroundTransparency = 1
			ValueInput.Size = UDim2.new(1, 0, 1, 0)
			ValueInput.Font = Enum.Font.GothamBold
			ValueInput.Text = tostring(default)
			ValueInput.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			ValueInput.TextSize = IsMobile and 9 or 10
			ValueInput.Parent = ValueBox
			local trackLeft = icon and textLeft or 12
			local trackRightPad = icon and (IsMobile and 58 or 82) or (IsMobile and 28 or 32)
			local trackTop = IsMobile and 28 or 34
			local trackH = IsMobile and 14 or 16
			local thumbW = IsMobile and 16 or 20
			local thumbH = IsMobile and 16 or 22
			local SliderTrack = Instance.new("TextButton")
			SliderTrack.Name = "SliderTrack"
			SliderTrack.BackgroundColor3 = themeColorFor("45,45,50", CurrentThemeName or "Dark")
			SliderTrack.Position = UDim2.new(0, trackLeft, 0, trackTop)
			SliderTrack.Size = UDim2.new(1, -trackLeft - trackRightPad, 0, trackH)
			SliderTrack.Text = ""
			SliderTrack.AutoButtonColor = false
			SliderTrack.Parent = SliderFrame
			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(0, 4)
			TrackCorner.Parent = SliderTrack
			local SliderFill = Instance.new("Frame")
			SliderFill.Name = "SliderFill"
			SliderFill.BackgroundColor3 = AccentColor
			SliderFill.Size = UDim2.new((default - min)/math.max(1,max-min),0,1,0)
			SliderFill.Parent = SliderTrack
			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(0, 4)
			FillCorner.Parent = SliderFill
			local SliderThumb = Instance.new("Frame")
			SliderThumb.Name = "SliderThumb"
			SliderThumb.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			SliderThumb.AnchorPoint = Vector2.new(0.5,0.5)
			SliderThumb.Position = UDim2.new((default - min)/math.max(1,max-min),0,0.5,0)
			SliderThumb.Size = UDim2.fromOffset(thumbW, thumbH)
			SliderThumb.Parent = SliderTrack
			local ThumbCorner = Instance.new("UICorner")
			ThumbCorner.CornerRadius = UDim.new(0, 3)
			ThumbCorner.Parent = SliderThumb
			local ThumbStroke = Instance.new("UIStroke")
			ThumbStroke.Color = themeColorFor("0,0,0", CurrentThemeName or "Dark")
			ThumbStroke.Thickness = 1
			ThumbStroke.Parent = SliderThumb
			local dragging=false; local cur=default
			local function upd(p) TweenService:Create(SliderFill,TweenInfo.new(0.08),{Size=UDim2.new(p,0,1,0)}):Play(); TweenService:Create(SliderThumb,TweenInfo.new(0.08),{Position=UDim2.new(p,0,0.5,0)}):Play() end
			local function setFromInput(input)
				local rel=math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X)/SliderTrack.AbsoluteSize.X,0,1)
				local raw=min+(max-min)*rel; local stepped=math.round(raw/increase)*increase; stepped=math.clamp(stepped,min,max); cur=stepped; ValueInput.Text=tostring(cur); upd((cur-min)/math.max(1,max-min)); task.spawn(callback,cur)
			end
			SliderTrack.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; setFromInput(i) end end)
			UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setFromInput(i) end end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
			ValueInput.FocusLost:Connect(function() local n=tonumber(ValueInput.Text); if n then n=math.clamp(math.round(n/increase)*increase,min,max); cur=n; upd((cur-min)/math.max(1,max-min)); task.spawn(callback,cur) end; ValueInput.Text=tostring(cur) end)
			SliderFrame.MouseEnter:Connect(function() TweenService:Create(SliderFrame,TweenInfo.new(0.15),{BackgroundColor3=themeColorFor("36,36,40", CurrentThemeName or "Dark")}):Play(); TweenService:Create(SliderStroke,TweenInfo.new(0.15),{Color=themeColorFor("70,70,75", CurrentThemeName or "Dark")}):Play() end)

			-- Follow theme accent
			onAccentChange(function(c)
				SliderFill.BackgroundColor3 = c
			end)
			SliderFrame.MouseLeave:Connect(function() TweenService:Create(SliderFrame,TweenInfo.new(0.15),{BackgroundColor3=themeColorFor("26,26,30", CurrentThemeName or "Dark")}):Play(); TweenService:Create(SliderStroke,TweenInfo.new(0.15),{Color=themeColorFor("50,50,55", CurrentThemeName or "Dark")}):Play() end)
			registerElement(SliderFrame, calculatedHeight, sliderConfig.Position)
			local C={}; function C:Set(v) v=math.clamp(v,min,max); cur=v; ValueInput.Text=tostring(v); upd((v-min)/math.max(1,max-min)); task.spawn(callback,v) end; function C:Get() return cur end; if sliderConfig.Flag and sliderConfig.Flag ~= "" then table.insert(configFlags, {Flag = sliderConfig.Flag, Kind = "slider", Get = function() return cur end, Set = function(v) C:Set(v) end}) end; return C
		end


		-- AddSelector: tall card (title + value box), clear selected state, mobile-compact
		function TabObject:AddSelector(selectorConfig)
			selectorConfig = selectorConfig or {}
			local title = selectorConfig.Title or "Selector"
			local description = selectorConfig.Description
			local options = selectorConfig.Options or {}
			local default = selectorConfig.Default
			local callback = selectorConfig.Callback or function() end
			local icon = parseIcon(selectorConfig.Icon)
			local searchEnabled = selectorConfig.Search or false
			local multi = selectorConfig.Multi or false
			local hasDesc = description and description ~= "" or false

			local calculatedHeight = IsMobile and 76 or 84
			local titleSize = 11
			local descSize = 11
			local textY = IsMobile and 6 or 8
			local valueY = calculatedHeight - 38
			local valueH = 28

			local selectedOptions = {}
			local function applyDefault(def)
				table.clear(selectedOptions)
				if multi then
					if type(def) == "table" then
						for _, val in ipairs(def) do selectedOptions[tostring(val)] = true end
					elseif def ~= nil and tostring(def) ~= "" then
						selectedOptions[tostring(def)] = true
					end
				else
					if def ~= nil and tostring(def) ~= "" then
						selectedOptions[tostring(def)] = true
					end
				end
			end
			applyDefault(default)

			local SelectorFrame = Instance.new("Frame")
			SelectorFrame.Name = title .. "_Selector"
			SelectorFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			SelectorFrame.BorderSizePixel = 0
			SelectorFrame.Size = UDim2.new(1, 0, 0, calculatedHeight)

			local SelectorCorner = Instance.new("UICorner")
			SelectorCorner.CornerRadius = UDim.new(0, 8)
			SelectorCorner.Parent = SelectorFrame

			local SelectorStroke = Instance.new("UIStroke")
			SelectorStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			SelectorStroke.Thickness = 1
			SelectorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			SelectorStroke.Parent = SelectorFrame

			if icon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 10, 0.5, IsMobile and -16 or -21)
				IconContainer.Size = UDim2.new(0, IsMobile and 32 or 42, 0, IsMobile and 32 or 42)
				IconContainer.Parent = SelectorFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer

				local IconContainerStroke = Instance.new("UIStroke")
				IconContainerStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconContainerStroke.Transparency = 0.3
				IconContainerStroke.Thickness = 1.5
				IconContainerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconContainerStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 20 or 26, 0, IsMobile and 20 or 26)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 62, 0, textY) or UDim2.new(0, 12, 0, textY)
			TextContainer.Size = icon and UDim2.new(1, -72, 0, 34) or UDim2.new(1, -24, 0, 34)
			TextContainer.Parent = SelectorFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 1)
			TextListLayout.Parent = TextContainer

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, titleSize)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = TextContainer

			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 16)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, descSize)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = TextContainer
			end

			-- Value box: bright selected text + count badge + arrow, clear at a glance
			local ValueBox = Instance.new("TextButton")
			ValueBox.Name = "ValueBox"
			ValueBox.BackgroundColor3 = themeColorFor("18,18,20", CurrentThemeName or "Dark")
			ValueBox.BorderSizePixel = 0
			ValueBox.Position = icon and UDim2.new(0, 62, 0, valueY) or UDim2.new(0, 12, 0, valueY)
			ValueBox.Size = icon and UDim2.new(1, -72, 0, valueH) or UDim2.new(1, -24, 0, valueH)
			ValueBox.Text = ""
			ValueBox.AutoButtonColor = false
			ValueBox.Parent = SelectorFrame

			local ValueCorner = Instance.new("UICorner")
			ValueCorner.CornerRadius = UDim.new(0, 6)
			ValueCorner.Parent = ValueBox

			local ValueStroke = Instance.new("UIStroke")
			ValueStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			ValueStroke.Thickness = 1
			ValueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ValueStroke.Parent = ValueBox

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Name = "ValueLabel"
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Size = UDim2.new(1, -76, 1, 0)
			ValueLabel.Position = UDim2.new(0, 10, 0, 0)
			ValueLabel.Font = Enum.Font.GothamBold
			ValueLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(ValueLabel, 11)
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
			ValueLabel.Parent = ValueBox

			-- Multi-select count badge (perfect circle, like the toggle knob)
			local CountBadge = Instance.new("Frame")
			CountBadge.Name = "CountBadge"
			CountBadge.BackgroundColor3 = AccentColor
			CountBadge.BorderSizePixel = 0
			CountBadge.AnchorPoint = Vector2.new(1, 0.5)
			CountBadge.Position = UDim2.new(1, -36, 0.5, 0)
			CountBadge.Size = UDim2.new(0, 22, 0, 22)
			CountBadge.Visible = false
			CountBadge.ZIndex = 12
			CountBadge.Parent = ValueBox

			local BadgeCorner = Instance.new("UICorner")
			BadgeCorner.CornerRadius = UDim.new(0, 7)
			BadgeCorner.Parent = CountBadge

			local BadgeLabel = Instance.new("TextLabel")
			BadgeLabel.BackgroundTransparency = 1
			BadgeLabel.Size = UDim2.new(1, 0, 1, 0)
			BadgeLabel.Font = Enum.Font.GothamBold
			BadgeLabel.Text = ""
			BadgeLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(BadgeLabel, 12)
			BadgeLabel.TextXAlignment = Enum.TextXAlignment.Center
			BadgeLabel.ZIndex = 13
			BadgeLabel.Parent = CountBadge

			local function selectedList()
				local list = {}
				for _, opt in ipairs(options) do
					local s = tostring(opt)
					if selectedOptions[s] then table.insert(list, s) end
				end
				return list
			end

			local function updateValueLabel()
				local list = selectedList()
				local disp = {}
				for _, s in ipairs(list) do table.insert(disp, translateText(s)) end
				if #disp == 0 then
					ValueLabel.Text = translateText("Select...")
					ValueLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				elseif #disp > 2 then
					ValueLabel.Text = string.format("%s, %s " .. translateText("(+%d more)"), disp[1], disp[2], #disp - 2)
					ValueLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				else
					ValueLabel.Text = table.concat(disp, ", ")
					ValueLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				end
				if multi then
					CountBadge.Visible = #list > 0
					BadgeLabel.Text = (#list > 9) and "9+" or tostring(#list)
				else
					CountBadge.Visible = false
				end
			end
			table.insert(languageRefreshers, updateValueLabel)
			updateValueLabel()

			local DropIcon = Instance.new("ImageLabel")
			DropIcon.Name = "DropIcon"
			DropIcon.BackgroundTransparency = 1
			DropIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			DropIcon.Position = UDim2.new(1, -16, 0.5, 0)
			DropIcon.Size = UDim2.new(0, 12, 0, 12)
			DropIcon.Image = Astral.Icons.down_arrow
			DropIcon.ImageColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
			DropIcon.Parent = ValueBox

			local function currentText()
				local list = selectedList()
				if multi then
					return #list > 0 and table.concat(list, ", ") or "None"
				end
				return list[1]
			end

			local function openPanel()
				openSelector(title, options, currentText(), searchEnabled, function(pick)
					table.clear(selectedOptions)
					if multi and type(pick) == "table" then
						for _, v in ipairs(pick) do selectedOptions[tostring(v)] = true end
					elseif pick ~= nil and tostring(pick) ~= "" and tostring(pick) ~= "None" then
						selectedOptions[tostring(pick)] = true
					end
					updateValueLabel()
					task.spawn(callback, pick)
				end, ValueLabel, multi)
			end

			ValueBox.MouseButton1Click:Connect(openPanel)
			-- Mobile: only open on tap, not on scroll/drag
			do
				local touchStartPos = nil
				SelectorFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						touchStartPos = input.Position
					end
				end)
				SelectorFrame.InputEnded:Connect(function(input)
					if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and touchStartPos then
						local delta = (input.Position - touchStartPos).Magnitude
						if delta < 10 then
							openPanel()
						end
						touchStartPos = nil
					end
				end)
			end

			ValueBox.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(SelectorFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(SelectorStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
			end)
			ValueBox.MouseLeave:Connect(function()
				TweenService:Create(SelectorFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(SelectorStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
			end)

			registerElement(SelectorFrame, calculatedHeight, selectorConfig.Position)

			-- Count badge follows the accent color
			onAccentChange(function(c)
				CountBadge.BackgroundColor3 = c
			end)

			local SelectorController = {}
			function SelectorController:Set(value)
				applyDefault(value)
				updateValueLabel()
				task.spawn(callback, value)
			end
			function SelectorController:SetOptions(newOptions, newDefault)
				table.clear(options)
				if type(newOptions) == "table" then
					for _, v in ipairs(newOptions) do table.insert(options, v) end
				end
				-- drop selections that no longer exist
				for s in pairs(selectedOptions) do
					local stillThere = false
					for _, opt in ipairs(options) do
						if tostring(opt) == s then stillThere = true; break end
					end
					if not stillThere then selectedOptions[s] = nil end
				end
				if newDefault ~= nil then applyDefault(newDefault) end
				updateValueLabel()
				-- if this selector's panel is open, refresh it live
				if selectorOpen and activeSelectorRefresh then
					pcall(activeSelectorRefresh)
				end
			end
			function SelectorController:Get()
				if multi then
					local list = {}
					for _, opt in ipairs(options) do
						local s = tostring(opt)
						if selectedOptions[s] then table.insert(list, s) end
					end
					return list
				end
				for s in pairs(selectedOptions) do return s end
				return nil
			end
			if selectorConfig.Flag and selectorConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = selectorConfig.Flag, Kind = "select",
					Get = function()
						if multi then
							local list = {}
							for _, opt in ipairs(options) do
								local s = tostring(opt)
								if selectedOptions[s] then table.insert(list, s) end
							end
							return list
						end
						for s in pairs(selectedOptions) do return s end
						return nil
					end,
					Set = function(v) SelectorController:Set(v) end})
			end

			return SelectorController
		end
		TabObject.Addselector = TabObject.AddSelector -- Alias to support lowercase calls


		-- =========================================================================
		-- TEXTBOX (icon + title on top, big box under)
		-- =========================================================================
		function TabObject:AddTextbox(textboxConfig)
			textboxConfig = textboxConfig or {}
			local title = textboxConfig.Title or "Textbox"
			local description = textboxConfig.Description
			local placeholder = textboxConfig.Placeholder or "Type here..."
			local default = textboxConfig.Default or ""
			local clearOnFocus = textboxConfig.ClearOnFocus
			if clearOnFocus == nil then clearOnFocus = textboxConfig.ClearOnTextFocus end
			if clearOnFocus == nil then clearOnFocus = false end
			local callback = textboxConfig.Callback or function() end
			local icon = parseIcon(textboxConfig.Icon)
			local hasDesc = description and description ~= "" or false

			local boxSize = IsMobile and 44 or 48
			local titleSize = 13
			local descSize = 11
			local pad = IsMobile and 6 or 8
			local inputH = IsMobile and 46 or 52

			-- Auto height: measure the description so long text grows the card, short text keeps it small
			local textH = 18
			if hasDesc then
				local measureW = IsMobile and 180 or 260
				local ok, ts = pcall(function()
					return game:GetService("TextService"):GetTextSize(description, descSize, Enum.Font.Gotham, Vector2.new(measureW, 10000))
				end)
				if ok and ts then
					textH = 18 + 1 + math.clamp(math.ceil(ts.Y), 12, 110)
				else
					textH = 18 + 1 + 14
				end
			end
			local topH = math.max(boxSize, textH)
			local inputY = pad + topH + pad
			local calculatedHeight = inputY + inputH + 10

			local TextboxFrame = Instance.new("Frame")
			TextboxFrame.Name = title .. "_Textbox"
			TextboxFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			TextboxFrame.BorderSizePixel = 0
			TextboxFrame.Size = UDim2.new(1, 0, 0, calculatedHeight)

			local FrameCorner = Instance.new("UICorner")
			FrameCorner.CornerRadius = UDim.new(0, 8)
			FrameCorner.Parent = TextboxFrame

			local TextboxStroke = Instance.new("UIStroke")
			TextboxStroke.Thickness = 1
			TextboxStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			TextboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			TextboxStroke.Parent = TextboxFrame

			-- Top row: icon + title (+ description), one aligned grid (12px margins, 10px gaps)
			if icon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 12, 0, pad)
				IconContainer.Size = UDim2.new(0, boxSize, 0, boxSize)
				IconContainer.Parent = TextboxFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 8)
				IconCorner.Parent = IconContainer

				local IconStroke = Instance.new("UIStroke")
				IconStroke.Thickness = 1.5
				IconStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconStroke.Transparency = 0.3
				IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, boxSize - 18, 0, boxSize - 18)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			local textX = icon and (22 + boxSize) or 12
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = UDim2.new(0, textX, 0, pad)
			TextContainer.Size = UDim2.new(1, -textX - 12, 0, textH)
			TextContainer.Parent = TextboxFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			TextListLayout.Padding = UDim.new(0, 1)
			TextListLayout.Parent = TextContainer

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 18)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, titleSize)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = TextContainer

			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 16)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, descSize)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = TextContainer
			end

			-- Big input box under them, full width
			local InputBox = Instance.new("TextBox")
			InputBox.Name = "InputBox"
			InputBox.BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")
			InputBox.BorderSizePixel = 0
			InputBox.Position = UDim2.new(0, 12, 0, inputY)
			InputBox.Size = UDim2.new(1, -24, 0, inputH)
			InputBox.Font = Enum.Font.Gotham
			InputBox.PlaceholderText = placeholder
			InputBox.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")
			InputBox.Text = default
			InputBox.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(InputBox, 12)
			InputBox.TextXAlignment = Enum.TextXAlignment.Left
			InputBox.TextTruncate = Enum.TextTruncate.AtEnd
			InputBox.ClearTextOnFocus = clearOnFocus
			InputBox.ClipsDescendants = true
			InputBox.Parent = TextboxFrame

			local InputCorner = Instance.new("UICorner")
			InputCorner.CornerRadius = UDim.new(0, 6)
			InputCorner.Parent = InputBox

			local InputStroke = Instance.new("UIStroke")
			InputStroke.Thickness = 1.5
			InputStroke.Color = themeColorFor("100,100,105", CurrentThemeName or "Dark")
			InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			InputStroke.Parent = InputBox

			local InputPadding = Instance.new("UIPadding")
			InputPadding.PaddingLeft = UDim.new(0, 12)
			InputPadding.PaddingRight = UDim.new(0, 12)
			InputPadding.Parent = InputBox

			InputBox.Focused:Connect(function()
				TweenService:Create(InputBox, TweenInfo.new(0.15), {BackgroundColor3 = themeColorFor("38,38,44", CurrentThemeName or "Dark")}):Play()
				TweenService:Create(InputStroke, TweenInfo.new(0.15), {Color = themeColorFor("100,100,105", CurrentThemeName or "Dark")}):Play()
			end)

			InputBox.FocusLost:Connect(function()
				TweenService:Create(InputBox, TweenInfo.new(0.15), {BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")}):Play()
				TweenService:Create(InputStroke, TweenInfo.new(0.15), {Color = themeColorFor("100,100,105", CurrentThemeName or "Dark")}):Play()
				-- Only fire when the text actually changed (clicking in/out does nothing)
				if InputBox.Text ~= lastText then
					lastText = InputBox.Text
					task.spawn(callback, InputBox.Text)
				end
			end)

			TextboxFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(TextboxFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(TextboxStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(InputStroke, TweenInfo.new(0.15), {Color = themeColorFor("130,130,135", CurrentThemeName or "Dark")}):Play()
			end)

			TextboxFrame.MouseLeave:Connect(function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(TextboxStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
				if not InputBox:IsFocused() then
					TweenService:Create(InputStroke, TweenInfo.new(0.15), {Color = themeColorFor("100,100,105", CurrentThemeName or "Dark")}):Play()
				end
			end)

			registerElement(TextboxFrame, calculatedHeight, textboxConfig.Position)

			local lastText = default

			-- Correction pass: after render, fix height from the REAL wrapped text
			-- (measurement can be off on narrow columns; long desc grows downward)
			if hasDesc then
				task.spawn(function()
					RunService.RenderStepped:Wait()
					RunService.RenderStepped:Wait()
					local ok, bounds = pcall(function() return DescLabel.TextBounds.Y end)
					if not ok or not bounds then return end
					local need = 18 + 1 + math.ceil(bounds) + 6
					if math.abs(need - textH) > 4 then
						textH = need
						local topH2 = math.max(boxSize, textH)
						local inputY2 = pad + topH2 + pad
						local h2 = inputY2 + inputH + 10
						TextContainer.Size = UDim2.new(1, -textX - 12, 0, textH)
						DescLabel.Size = UDim2.new(1, 0, 0, textH - 19)
						InputBox.Position = UDim2.new(0, 12, 0, inputY2)
						TextboxFrame.Size = UDim2.new(1, 0, 0, h2)
						for _, item in ipairs(elements) do
							if item.Frame == TextboxFrame then
								item.Height = h2
								break
							end
						end
						distributeElements()
					end
				end)
			end

			local TextboxController = {}
			function TextboxController:Set(text)
				InputBox.Text = tostring(text)
				lastText = InputBox.Text
				task.spawn(callback, InputBox.Text)
			end
			function TextboxController:Get()
				return InputBox.Text
			end
			if textboxConfig.Flag and textboxConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = textboxConfig.Flag, Kind = "text",
					Get = function() return InputBox.Text end,
					Set = function(v) TextboxController:Set(v) end})
			end

			return TextboxController
		end

		-- =========================================================================
		-- NEW LABEL IMPLEMENTATION (STATIC DISPLAY ELEMENT WITH OPTIONAL ICONS)
		-- =========================================================================
		function TabObject:AddLabel(labelConfig)
			labelConfig = labelConfig or {}
			local title = labelConfig.Title or "Label"
			local description = labelConfig.Description
			local icon = parseIcon(labelConfig.Icon)
			local callback = labelConfig.Callback or function() end
			local titleSize = tonumber(labelConfig.TextSize) or 14
			local descSize = tonumber(labelConfig.DescSize) or 15

			local hasDesc = description and description ~= ""
			local calculatedHeight = IsMobile and 50 or 64

			local LabelFrame = Instance.new("Frame")
			LabelFrame.Name = title .. "_Label"
			LabelFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			LabelFrame.BorderSizePixel = 0

			local LabelCorner = Instance.new("UICorner")
			LabelCorner.CornerRadius = UDim.new(0, 12)
			LabelCorner.Parent = LabelFrame

			local LabelStroke = Instance.new("UIStroke")
			LabelStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			LabelStroke.Thickness = 1.2
			LabelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			LabelStroke.Parent = LabelFrame

			-- Left Icon Container (Enlarged with High-Contrast Outline) - OPTIONAL
			local IconContainer = nil
			if icon then
				IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 8, 0.5, IsMobile and -17 or -22)
				IconContainer.Size = UDim2.new(0, IsMobile and 34 or 44, 0, IsMobile and 34 or 44)
				IconContainer.Parent = LabelFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 8)
				IconCorner.Parent = IconContainer

				local IconContainerStroke = Instance.new("UIStroke")
				IconContainerStroke.Color = themeColorFor("70,70,75", CurrentThemeName or "Dark")
				IconContainerStroke.Thickness = 1.5
				IconContainerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconContainerStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 22 or 30)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			local leftInset = icon and 60 or 12

			-- Right-hand STATUS BADGE (hidden until SetStatus is called)
			local StatusBadge = Instance.new("Frame")
			StatusBadge.Name = "StatusBadge"
			StatusBadge.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
			StatusBadge.BorderSizePixel = 0
			StatusBadge.AnchorPoint = Vector2.new(1, 0.5)
			StatusBadge.Position = UDim2.new(1, -12, 0.5, 0)
			StatusBadge.Size = UDim2.new(0, 0, 0, 30)
			StatusBadge.AutomaticSize = Enum.AutomaticSize.X
			StatusBadge.Visible = false
			StatusBadge.Parent = LabelFrame

			local StatusCorner = Instance.new("UICorner")
			StatusCorner.CornerRadius = UDim.new(0, 8)
			StatusCorner.Parent = StatusBadge

			local StatusStroke = Instance.new("UIStroke")
			StatusStroke.Color = themeColorFor("70,70,75", CurrentThemeName or "Dark")
			StatusStroke.Thickness = 1.2
			StatusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			StatusStroke.Parent = StatusBadge

			local StatusPad = Instance.new("UIPadding")
			StatusPad.PaddingLeft = UDim.new(0, 8)
			StatusPad.PaddingRight = UDim.new(0, 9)
			StatusPad.Parent = StatusBadge

			local StatusLayout = Instance.new("UIListLayout")
			StatusLayout.FillDirection = Enum.FillDirection.Horizontal
			StatusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			StatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
			StatusLayout.Padding = UDim.new(0, 5)
			StatusLayout.Parent = StatusBadge

			local StatusIcon = Instance.new("ImageLabel")
			StatusIcon.Name = "StatusIcon"
			StatusIcon.BackgroundTransparency = 1
			StatusIcon.Size = UDim2.new(0, 18, 0, 18)
			StatusIcon.LayoutOrder = 1
			StatusIcon.ScaleType = Enum.ScaleType.Fit
			StatusIcon.ImageColor3 = themeColorFor("46,204,113", CurrentThemeName or "Dark")
			StatusIcon.Parent = StatusBadge

			local StatusText = Instance.new("TextLabel")
			StatusText.Name = "StatusText"
			StatusText.BackgroundTransparency = 1
			StatusText.AutomaticSize = Enum.AutomaticSize.X
			StatusText.Size = UDim2.new(0, 0, 1, 0)
			StatusText.LayoutOrder = 2
			StatusText.Font = Enum.Font.GothamBold
			StatusText.Text = ""
			StatusText.TextColor3 = themeColorFor("46,204,113", CurrentThemeName or "Dark")
			regText(StatusText, 13)
			StatusText.TextXAlignment = Enum.TextXAlignment.Left
			StatusText.Parent = StatusBadge

			-- Text Container (Title & Description)
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = UDim2.new(0, leftInset, 0, 0)
			TextContainer.Size = UDim2.new(1, -(leftInset + 12), 1, 0)
			TextContainer.Parent = LabelFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 2)
			TextListLayout.Parent = TextContainer

			-- Title Label (bigger by default, override with TextSize =)
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, titleSize + 5)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, titleSize)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.TextWrapped = false
			TitleLabel.Parent = TextContainer

			-- Description Label (created on demand, cached in a local)
			local DescLabel = nil
			local function ensureDesc(text)
				if not DescLabel then
					DescLabel = Instance.new("TextLabel")
					DescLabel.Name = "Description"
					DescLabel.BackgroundTransparency = 1
					DescLabel.Size = UDim2.new(1, 0, 0, descSize + 4)
					DescLabel.Font = Enum.Font.Gotham
					DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
					regText(DescLabel, descSize)
					DescLabel.TextXAlignment = Enum.TextXAlignment.Left
					DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
					DescLabel.Parent = TextContainer
				end
				DescLabel.Text = tostring(text)
			end
			if hasDesc then ensureDesc(description) end

			-- Keep the text clear of the status badge whenever it is visible
			local function applyStatusLayout()
				local rightInset = 12
				if StatusBadge.Visible then
					rightInset = 12 + StatusBadge.AbsoluteSize.X + 10
				end
				TextContainer.Size = UDim2.new(1, -(leftInset + rightInset), 1, 0)
			end
			StatusBadge:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyStatusLayout)

			-- Hover white effect like toggle (good UI)
			LabelFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(LabelFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(LabelStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
				pcall(function() local s = IconContainer and IconContainer:FindFirstChild("UIStroke"); if s then TweenService:Create(s, TweenInfo.new(0.15), {Transparency = 0}):Play() end end)
			end)
			LabelFrame.MouseLeave:Connect(function()
				TweenService:Create(LabelFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(LabelStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
				pcall(function() local s = IconContainer and IconContainer:FindFirstChild("UIStroke"); if s then TweenService:Create(s, TweenInfo.new(0.15), {Transparency = 0.3}):Play() end end)
			end)

			registerElement(LabelFrame, calculatedHeight, labelConfig.Position)

			local LabelController = {}

			local STATUS_DEFS = {
				good    = { Icon = "Checkmark", Color = themeColorFor("46,204,113", CurrentThemeName or "Dark"),  Text = "SPAWNED" },
				bad     = { Icon = "Close",     Color = themeColorFor("231,76,60", CurrentThemeName or "Dark"),   Text = "NOT SPAWNED" },
				waiting = { Icon = "timer",     Color = themeColorFor("255,212,0", CurrentThemeName or "Dark"),  Text = "WAITING" },
			}
			local function tint(c, f)
				return Color3.fromRGB(math.floor(c.R * 255 * f), math.floor(c.G * 255 * f), math.floor(c.B * 255 * f))
			end

			function LabelController:SetText(newText)
				TitleLabel.Text = tostring(newText)
			end
			LabelController.SetTitle = LabelController.SetText

			function LabelController:SetDescription(newDesc)
				ensureDesc(newDesc)
			end

			function LabelController:SetIcon(newIcon)
				if IconContainer and IconContainer:FindFirstChild("Icon") then
					Astral.ApplyIcon(IconContainer.Icon, parseIcon(newIcon))
				end
			end

			-- Status: "good" (green check) | "bad" (red cross) | "waiting" (timer) | "none"
			function LabelController:SetStatus(status, text)
				local def = STATUS_DEFS[status]
				if not def then
					StatusBadge.Visible = false
					applyStatusLayout()
					return
				end
				StatusBadge.Visible = true
				Astral.ApplyIcon(StatusIcon, parseIcon(def.Icon))
				StatusIcon.ImageColor3 = def.Color
				StatusStroke.Color = def.Color
				StatusBadge.BackgroundColor3 = tint(def.Color, 0.16)
				StatusText.Text = (text ~= nil) and tostring(text) or def.Text
				StatusText.TextColor3 = def.Color
				applyStatusLayout()
			end

			-- Live countdown written into the description.
			--   :SetCountdown(300)                  -> counts DOWN 05:00 -> 00:00
			--   :SetCountdown(300, "down")          -> same, explicit
			--   :SetCountdown(0, "up")              -> counts UP 00:00 -> ...
			--   :SetCountdown(300, function() end)  -> down, callback at zero
			--   :SetCountdown(0, "up", function() end)
			local countdownToken = 0
			local function fmtTime(sec)
				sec = math.max(0, math.floor(sec))
				if sec >= 3600 then
					return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60)
				end
				return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
			end
			-- Options table form lets you control the wording + where it shows:
			--   label:SetCountdown(300, { Prefix = "Respawns in ", Suffix = "", Where = "description" })
			--   Where = "description" (default) or "badge"
			function LabelController:SetCountdown(seconds, modeOrOpts, onDone)
				local mode, done, prefix, suffix, where = "down", nil, "", "", "description"
				if type(modeOrOpts) == "function" then
					done = modeOrOpts
				elseif type(modeOrOpts) == "string" then
					mode = modeOrOpts
					done = onDone
				elseif type(modeOrOpts) == "table" then
					mode = modeOrOpts.Mode or "down"
					done = modeOrOpts.OnDone or onDone
					prefix = modeOrOpts.Prefix or ""
					suffix = modeOrOpts.Suffix or ""
					where = modeOrOpts.Where or "description"
				end
				countdownToken = countdownToken + 1
				local myToken = countdownToken
				local total = math.max(0, math.floor(tonumber(seconds) or 0))
				local anchor = os.clock()
				local function write(txt)
					if where == "badge" then
						LabelController:SetStatus("waiting", prefix .. txt .. suffix)
					else
						LabelController:SetDescription(prefix .. txt .. suffix)
					end
				end
				task.spawn(function()
					while true do
						if countdownToken ~= myToken then return end
						local elapsed = math.floor(os.clock() - anchor)
						local value = total
						if mode == "up" then
							value = total + elapsed
						else
							value = total - elapsed
						end
						if value < 0 then value = 0 end
						write(fmtTime(value))
						if mode ~= "up" and value <= 0 then break end
						task.wait(1)
					end
					if mode ~= "up" and countdownToken == myToken then
						if where == "badge" then
							LabelController:SetStatus("good", "SPAWNED")
						end
						if done then task.spawn(done) end
					end
				end)
			end

			function LabelController:StopCountdown()
				countdownToken = countdownToken + 1
			end

			if labelConfig.Status then
				LabelController:SetStatus(labelConfig.Status, labelConfig.StatusText)
			end

			-- Fire callback on load
			task.spawn(callback)

			return LabelController
		end
		-- =========================================================================
		-- SECTION HEADER (clean divider label: accent bar + title + line)
		--   local S = Tab:AddSection({ Title = "Farming", Icon = "Home" })
		--   S:SetTitle("Bosses")
		-- =========================================================================
		function TabObject:AddSection(sectionConfig)
			sectionConfig = sectionConfig or {}
			local title = sectionConfig.Title or sectionConfig.Name or "Section"
			local icon = parseIcon(sectionConfig.Icon)
			local h = IsMobile and 36 or 42

			local SectionFrame = Instance.new("Frame")
			SectionFrame.Name = title .. "_Section"
			SectionFrame.BackgroundTransparency = 1
			SectionFrame.BorderSizePixel = 0

			local RowLayout = Instance.new("UIListLayout")
			RowLayout.FillDirection = Enum.FillDirection.Horizontal
			RowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			RowLayout.Padding = UDim.new(0, 10)
			RowLayout.Parent = SectionFrame

			local BarL = Instance.new("Frame")
			BarL.Name = "BarL"
			BarL.Size = UDim2.new(0, IsMobile and 60 or 110, 0, IsMobile and 14 or 18)
			BarL.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			BarL.BorderSizePixel = 0
			BarL.LayoutOrder = 1
			BarL.Parent = SectionFrame
			local BarLCorner = Instance.new("UICorner")
			BarLCorner.CornerRadius = UDim.new(0, 4)
			BarLCorner.Parent = BarL
			local BarLGrad = Instance.new("UIGradient")
			BarLGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, themeColorFor("59,130,246", CurrentThemeName or "Dark")),
				ColorSequenceKeypoint.new(1, themeColorFor("168,85,247", CurrentThemeName or "Dark")),
			})
			BarLGrad.Parent = BarL

			if icon then
				local IcoBox = Instance.new("Frame")
				IcoBox.Name = "IconBox"
				IcoBox.Size = UDim2.new(0, 26, 0, 26)
				IcoBox.BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark")
				IcoBox.BorderSizePixel = 0
				IcoBox.LayoutOrder = 2
				IcoBox.Parent = SectionFrame
				local IcoBoxCorner = Instance.new("UICorner")
				IcoBoxCorner.CornerRadius = UDim.new(1, 0)
				IcoBoxCorner.Parent = IcoBox
				local IcoBoxStroke = Instance.new("UIStroke")
				IcoBoxStroke.Color = AccentColor
				IcoBoxStroke.Thickness = 1.5
				IcoBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IcoBoxStroke.Parent = IcoBox
				local Ico = Instance.new("ImageLabel")
				Ico.Name = "Icon"
				Ico.BackgroundTransparency = 1
				Ico.AnchorPoint = Vector2.new(0.5, 0.5)
				Ico.Position = UDim2.new(0.5, 0, 0.5, 0)
				Ico.Size = UDim2.new(0, 15, 0, 15)
				Astral.ApplyIcon(Ico, icon)
				Ico.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				Ico.ScaleType = Enum.ScaleType.Fit
				Ico.Parent = IcoBox
				onAccentChange(function(c) pcall(function() IcoBoxStroke.Color = c end) end)
			end

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(0, 0, 0, IsMobile and 20 or 22)
			TitleLabel.AutomaticSize = Enum.AutomaticSize.X
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(TitleLabel, IsMobile and 19 or 22)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.LayoutOrder = 3
			TitleLabel.Parent = SectionFrame

			local BarR = Instance.new("Frame")
			BarR.Name = "BarR"
			BarR.Size = UDim2.new(0, IsMobile and 60 or 110, 0, IsMobile and 14 or 18)
			BarR.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			BarR.BorderSizePixel = 0
			BarR.LayoutOrder = 4
			BarR.Parent = SectionFrame
			local BarRCorner = Instance.new("UICorner")
			BarRCorner.CornerRadius = UDim.new(0, 4)
			BarRCorner.Parent = BarR
			local BarRGrad = Instance.new("UIGradient")
			BarRGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, themeColorFor("168,85,247", CurrentThemeName or "Dark")),
				ColorSequenceKeypoint.new(1, themeColorFor("59,130,246", CurrentThemeName or "Dark")),
			})
			BarRGrad.Parent = BarR
			local function paintSectionBars(c)
				BarLGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, c),
					ColorSequenceKeypoint.new(1, c),
				})
				BarRGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, c),
					ColorSequenceKeypoint.new(1, c),
				})
			end
			paintSectionBars(AccentColor)
			onAccentChange(function(c) pcall(function() paintSectionBars(c) end) end)

			registerElement(SectionFrame, h, sectionConfig.Position)

			local SectionController = {}
			function SectionController:SetTitle(t)
				TitleLabel.Text = tostring(t)
			end
			SectionController.SetText = SectionController.SetTitle
			function SectionController:SetIcon(iconInput)
				local ic = SectionFrame:FindFirstChild("Icon", true)
				if ic then Astral.ApplyIcon(ic, parseIcon(iconInput)) end
			end
			return SectionController
		end
		-- =========================================================================
		-- CONTENT SECTION (classic style: left title + underline).
		-- Second flavor next to AddSection ΓÇö use whichever fits the tab.
		--   local C = Tab:AddContentSection({ Title = "Farming & Combat" })
		--   C:SetTitle("Bosses")
		-- =========================================================================
		function TabObject:AddContentSection(sectionConfig)
			sectionConfig = sectionConfig or {}
			local title = sectionConfig.Title or sectionConfig.Name or "Section"
			local h = IsMobile and 40 or 45

			local SecFrame = Instance.new("Frame")
			SecFrame.Name = title .. "_ContentSection"
			SecFrame.BackgroundTransparency = 1
			SecFrame.BorderSizePixel = 0

			local SecLabel = Instance.new("TextLabel")
			SecLabel.Name = "Title"
			SecLabel.BackgroundTransparency = 1
			SecLabel.Position = UDim2.new(0, 2, 0, 6)
			SecLabel.Size = UDim2.new(1, -4, 0, IsMobile and 20 or 24)
			SecLabel.Font = Enum.Font.GothamBold
			tr(SecLabel, title)
			SecLabel.TextColor3 = themeColorFor("220,220,228", CurrentThemeName or "Dark")
			mTS(SecLabel, IsMobile and 15 or 16)
			SecLabel.TextXAlignment = Enum.TextXAlignment.Left
			SecLabel.TextTruncate = Enum.TextTruncate.AtEnd
			SecLabel.Parent = SecFrame

			local SecLine = Instance.new("Frame")
			SecLine.Name = "Line"
			SecLine.AnchorPoint = Vector2.new(0, 1)
			SecLine.Position = UDim2.new(0, 2, 1, -4)
			SecLine.Size = UDim2.new(1, -4, 0, 2)
			SecLine.BackgroundColor3 = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			SecLine.BackgroundTransparency = 0.3
			SecLine.BorderSizePixel = 0
			SecLine.Parent = SecFrame

			registerElement(SecFrame, h, sectionConfig.Position)

			local ContentSectionController = {}
			function ContentSectionController:SetTitle(t)
				SecLabel.Text = tostring(t)
			end
			ContentSectionController.SetText = ContentSectionController.SetTitle
			return ContentSectionController
		end
		-- =========================================================================
		-- NEW PARAGRAPH IMPLEMENTATION (PIXEL-PERFECT IMAGE & TEXT CARD)
		-- =========================================================================
		function TabObject:AddParagraph(paraConfig)
			paraConfig = paraConfig or {}
			-- Handle nested array structure if passed as { { ... } }
			if paraConfig[1] and type(paraConfig[1]) == "table" then
				paraConfig = paraConfig[1]
			end

			local title = paraConfig.Title or "Paragraph"
			local description = paraConfig.Description or ""
			local image = parseIcon(paraConfig.Image)
			local icon = parseIcon(paraConfig.Icon)

			local hasImage = not not image
			local calculatedHeight = hasImage and 200 or 75

			local ParaFrame = Instance.new("Frame")
			ParaFrame.Name = title .. "_Paragraph"
			ParaFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark") -- FIXED: match other buttons (was 14,14,16 too dark)
			ParaFrame.BorderSizePixel = 0

			local ParaCorner = Instance.new("UICorner")
			ParaCorner.CornerRadius = UDim.new(0, 10)
			ParaCorner.Parent = ParaFrame

			local ParaStroke = Instance.new("UIStroke")
			ParaStroke.Color = themeColorFor("32,32,36", CurrentThemeName or "Dark")
			ParaStroke.Thickness = 1.2
			ParaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ParaStroke.Parent = ParaFrame

			-- Layout
			local ParaLayout = Instance.new("UIListLayout")
			ParaLayout.SortOrder = Enum.SortOrder.LayoutOrder
			ParaLayout.Padding = UDim.new(0, 8)
			ParaLayout.Parent = ParaFrame

			local ParaPad = Instance.new("UIPadding")
			ParaPad.PaddingLeft = UDim.new(0, 12)
			ParaPad.PaddingRight = UDim.new(0, 12)
			ParaPad.PaddingTop = UDim.new(0, 12)
			ParaPad.PaddingBottom = UDim.new(0, 12)
			ParaPad.Parent = ParaFrame

			-- Image (if provided)
			if hasImage then
				local ImageContainer = Instance.new("Frame")
				ImageContainer.Name = "ImageContainer"
				ImageContainer.BackgroundTransparency = 1
				ImageContainer.Size = UDim2.new(1, 0, 0, 130)
				ImageContainer.LayoutOrder = 1
				ImageContainer.Parent = ParaFrame

				local ImageLabel = Instance.new("ImageLabel")
				ImageLabel.Name = "Image"
				ImageLabel.BackgroundTransparency = 1
				ImageLabel.Size = UDim2.new(1, 0, 1, 0)
				ImageLabel.Image = image
				ImageLabel.ScaleType = Enum.ScaleType.Crop
				ImageLabel.Parent = ImageContainer

				local ImageCorner = Instance.new("UICorner")
				ImageCorner.CornerRadius = UDim.new(0, 10)
				ImageCorner.Parent = ImageLabel
			end

			-- Text Content Container
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Size = UDim2.new(1, 0, 0, 0)
			TextContainer.AutomaticSize = Enum.AutomaticSize.Y
			TextContainer.LayoutOrder = 2
			TextContainer.Parent = ParaFrame

			local TextLayout = Instance.new("UIListLayout")
			TextLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextLayout.Padding = UDim.new(0, 6)
			TextLayout.Parent = TextContainer

			-- Title row (optional icon + title on one line)
			local TitleRow = Instance.new("Frame")
			TitleRow.Name = "TitleRow"
			TitleRow.BackgroundTransparency = 1
			TitleRow.Size = UDim2.new(1, 0, 0, 26)
			TitleRow.LayoutOrder = 1
			TitleRow.Parent = TextContainer

			local TitleRowLayout = Instance.new("UIListLayout")
			TitleRowLayout.FillDirection = Enum.FillDirection.Horizontal
			TitleRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TitleRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TitleRowLayout.Padding = UDim.new(0, 8)
			TitleRowLayout.Parent = TitleRow

			if icon then
				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.Size = UDim2.new(0, 24, 0, 24)
				IconLabel.LayoutOrder = 1
				IconLabel.ScaleType = Enum.ScaleType.Fit
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.Parent = TitleRow
			end

			-- Title
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, (icon and -34 or 0), 1, 0)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 16)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.LayoutOrder = 2
			TitleLabel.Parent = TitleRow

			-- Description
			local DescLabel = Instance.new("TextLabel")
			DescLabel.Name = "Description"
			DescLabel.BackgroundTransparency = 1
			DescLabel.Size = UDim2.new(1, 0, 0, 0)
			DescLabel.AutomaticSize = Enum.AutomaticSize.Y
			DescLabel.Font = Enum.Font.Gotham
			tr(DescLabel, description)
			DescLabel.TextColor3 = themeColorFor("175,175,182", CurrentThemeName or "Dark")
			regText(DescLabel, 13)
			DescLabel.TextXAlignment = Enum.TextXAlignment.Left
			DescLabel.TextYAlignment = Enum.TextYAlignment.Top
			DescLabel.TextWrapped = true
			DescLabel.LineHeight = 1.18
			DescLabel.LayoutOrder = 2
			DescLabel.Parent = TextContainer

			-- Adjust frame height dynamically based on text size
			local function adjustHeight()
				local textHeight = TextLayout.AbsoluteContentSize.Y
				local imageOffset = hasImage and 162 or 24
				local totalHeight = imageOffset + textHeight
				ParaFrame.Size = UDim2.new(1, 0, 0, totalHeight)
				-- Update masonry layout height
				for _, item in ipairs(elements) do
					if item.Frame == ParaFrame then
						item.Height = totalHeight
						break
					end
				end
				distributeElements()
			end

			TextLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(adjustHeight)
			task.spawn(adjustHeight)

			-- hover white effect like toggle (good UI)
			ParaFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(ParaFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ParaFrame:FindFirstChild("UIStroke") or ParaFrame:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
				pcall(function() local ic=ParaFrame:FindFirstChild("IconContainer",true); if ic then local s=ic:FindFirstChild("UIStroke"); if s then TweenService:Create(s,TweenInfo.new(0.15),{Transparency=0}):Play() end end end)
			end)
			ParaFrame.MouseLeave:Connect(function()
				TweenService:Create(ParaFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ParaFrame:FindFirstChild("UIStroke") or ParaFrame:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.15), {Color = themeCardBG(Window.ThemeName or "Dark")}):Play()
				pcall(function() local ic=ParaFrame:FindFirstChild("IconContainer",true); if ic then local s=ic:FindFirstChild("UIStroke"); if s then TweenService:Create(s,TweenInfo.new(0.15),{Transparency=0.3}):Play() end end end)
			end)

			registerElement(ParaFrame, calculatedHeight, paraConfig.Position)

			local ParaController = {}
			function ParaController:SetTitle(newTitle)
				TitleLabel.Text = tostring(newTitle)
				adjustHeight()
			end
			function ParaController:SetDescription(newDesc)
				DescLabel.Text = tostring(newDesc)
				adjustHeight()
			end

			return ParaController
		end


		-- =========================================================================
		-- DISCORD INVITE CARD (FROM MAIN UI)
		-- =========================================================================
		function TabObject:AddDiscordCard(config)
			config = config or {}
			local data = config.ServerData or {}
			local inviteCode = data.InviteCode or "RhQa6kZu9A"
			if config.FullWidth then
				forceSingleColumn = true
				pcall(refreshTabColumns)
				pcall(distributeElements)
				pcall(updateCanvas)
			end



			local MainFrame = Instance.new("Frame")
			MainFrame.Name = "DiscordInvite"
			MainFrame.Size = UDim2.new(1, 0, 0, 260)
			MainFrame.BackgroundColor3 = themeColorFor("30,30,36", CurrentThemeName or "Dark")
			MainFrame.BorderSizePixel = 0
			MainFrame.ClipsDescendants = true

			local MainCorner = Instance.new("UICorner")
			MainCorner.CornerRadius = UDim.new(0, 16)
			MainCorner.Parent = MainFrame

			local BgHighlight = Instance.new("Frame")
			BgHighlight.Name = "BgHighlight"
			BgHighlight.Size = UDim2.new(1, 0, 1, 0)
			BgHighlight.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			BgHighlight.BackgroundTransparency = 1
			BgHighlight.ZIndex = 0
			BgHighlight.Parent = MainFrame

			local BgHLCorner = Instance.new("UICorner")
			BgHLCorner.CornerRadius = UDim.new(0, 16)
			BgHLCorner.Parent = BgHighlight

			local Banner = Instance.new("ImageLabel")
			Banner.Name = "Banner"
			Banner.Size = UDim2.new(1, 0, 0, 110)
			Banner.Position = UDim2.new(0, 0, 0, 0)
			Banner.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			Banner.Image = data.BackgroundBannerId or "rbxassetid://127861212431489"
			Banner.ScaleType = Enum.ScaleType.Crop
			Banner.BorderSizePixel = 0
			Banner.Parent = MainFrame

			local BannerCorner = Instance.new("UICorner")
			BannerCorner.CornerRadius = UDim.new(0, 16)
			BannerCorner.Parent = Banner

			-- (banner art shows true colors, no tint)

			local ServerIcon = Instance.new("ImageLabel")
			ServerIcon.Name = "ServerIcon"
			ServerIcon.Size = UDim2.new(0, 64, 0, 64)
			ServerIcon.Position = UDim2.new(0, 14, 0, 78)
			ServerIcon.Image = data.ServerIconId or "rbxassetid://106987676739927"
			ServerIcon.ScaleType = Enum.ScaleType.Crop
			ServerIcon.BackgroundColor3 = themeColorFor("30,30,36", CurrentThemeName or "Dark")
			ServerIcon.BorderSizePixel = 0
			ServerIcon.ZIndex = 2
			ServerIcon.Parent = MainFrame

			local IconCorner = Instance.new("UICorner")
			IconCorner.CornerRadius = UDim.new(0, 16)
			IconCorner.Parent = ServerIcon

			local IconStroke = Instance.new("UIStroke")
			IconStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			IconStroke.Thickness = 3
			IconStroke.Parent = ServerIcon

			local InfoHolder = Instance.new("Frame")
			InfoHolder.Name = "InfoHolder"
			InfoHolder.Size = UDim2.new(1, -100, 0, 60)
			InfoHolder.Position = UDim2.new(0, 86, 0, 114)
			InfoHolder.BackgroundTransparency = 1
			InfoHolder.Parent = MainFrame

			local ListLayout = Instance.new("UIListLayout")
			ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			ListLayout.Padding = UDim.new(0, 3)
			ListLayout.Parent = InfoHolder

			local NameFrame = Instance.new("Frame")
			NameFrame.Name = "NameFrame"
			NameFrame.Size = UDim2.new(1, 0, 0, 22)
			NameFrame.BackgroundTransparency = 1
			NameFrame.LayoutOrder = 1
			NameFrame.Parent = InfoHolder

			local NameListLayout = Instance.new("UIListLayout")
			NameListLayout.FillDirection = Enum.FillDirection.Horizontal
			NameListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			NameListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			NameListLayout.Padding = UDim.new(0, 6)
			NameListLayout.Parent = NameFrame

			local ServerName = Instance.new("TextLabel")
			ServerName.Size = UDim2.new(0, 0, 1, 0)
			ServerName.AutomaticSize = Enum.AutomaticSize.X
			ServerName.Text = data.ServerName or "LumuHub"
			ServerName.Font = Enum.Font.GothamBold
			mTS(ServerName, 17)
			ServerName.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			ServerName.TextXAlignment = Enum.TextXAlignment.Left
			ServerName.BackgroundTransparency = 1
			ServerName.LayoutOrder = 1
			ServerName.Parent = NameFrame

			local BadgeIcon = Instance.new("ImageLabel")
			BadgeIcon.Size = UDim2.new(0, 14, 0, 14)
			BadgeIcon.Image = "rbxassetid://75143132170494"
			BadgeIcon.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			BadgeIcon.BackgroundTransparency = 1
			BadgeIcon.LayoutOrder = 2
			BadgeIcon.Parent = NameFrame

			-- Bottom action bar: counts left, Join right, one container (no float overlap)
			local BottomBar = Instance.new("Frame")
			BottomBar.Name = "BottomBar"
			BottomBar.Size = UDim2.new(1, -28, 0, 44)
			BottomBar.Position = UDim2.new(0, 14, 1, -48)
			BottomBar.BackgroundTransparency = 1
			BottomBar.Parent = MainFrame

			local MetricsFrame = Instance.new("Frame")
			MetricsFrame.Size = UDim2.new(0.5, 0, 0, 16)
			MetricsFrame.Position = UDim2.new(0, 0, 0.5, -8)
			MetricsFrame.BackgroundTransparency = 1
			MetricsFrame.Parent = BottomBar

			local MetricsLayout = Instance.new("UIListLayout")
			MetricsLayout.FillDirection = Enum.FillDirection.Horizontal
			MetricsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			MetricsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			MetricsLayout.Padding = UDim.new(0, 5)
			MetricsLayout.Parent = MetricsFrame

			local OnlineDot = Instance.new("Frame")
			OnlineDot.Name = "OnlineDot"
			OnlineDot.Size = UDim2.new(0, 8, 0, 8)
			OnlineDot.BackgroundColor3 = Color3.fromRGB(35, 165, 90)
			OnlineDot.BorderSizePixel = 0
			OnlineDot.LayoutOrder = 1
			OnlineDot.Parent = MetricsFrame

			local OnlineDotCorner = Instance.new("UICorner")
			OnlineDotCorner.CornerRadius = UDim.new(1, 0)
			OnlineDotCorner.Parent = OnlineDot

			local OnlineLabel = Instance.new("TextLabel")
			OnlineLabel.Size = UDim2.new(0, 0, 1, 0)
			OnlineLabel.AutomaticSize = Enum.AutomaticSize.X
			OnlineLabel.Text = tostring(data.OnlineCount or 46) .. " Online"
			OnlineLabel.Font = Enum.Font.GothamMedium
			mTS(OnlineLabel, 12)
			OnlineLabel.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
			OnlineLabel.BackgroundTransparency = 1
			OnlineLabel.LayoutOrder = 2
			OnlineLabel.Parent = MetricsFrame

			local MetricSpace = Instance.new("Frame")
			MetricSpace.Size = UDim2.new(0, 4, 1, 0)
			MetricSpace.BackgroundTransparency = 1
			MetricSpace.LayoutOrder = 3
			MetricSpace.Parent = MetricsFrame

			local MemberDot = Instance.new("Frame")
			MemberDot.Name = "MemberDot"
			MemberDot.Size = UDim2.new(0, 8, 0, 8)
			MemberDot.BackgroundColor3 = Color3.fromRGB(128, 132, 142)
			MemberDot.BorderSizePixel = 0
			MemberDot.LayoutOrder = 4
			MemberDot.Parent = MetricsFrame

			local MemberDotCorner = Instance.new("UICorner")
			MemberDotCorner.CornerRadius = UDim.new(1, 0)
			MemberDotCorner.Parent = MemberDot

			local MemberLabel = Instance.new("TextLabel")
			MemberLabel.Size = UDim2.new(0, 0, 1, 0)
			MemberLabel.AutomaticSize = Enum.AutomaticSize.X
			MemberLabel.Text = tostring(data.MemberCount or 593) .. " Members"
			MemberLabel.Font = Enum.Font.GothamMedium
			mTS(MemberLabel, 12)
			MemberLabel.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
			MemberLabel.BackgroundTransparency = 1
			MemberLabel.LayoutOrder = 5
			MemberLabel.Parent = MetricsFrame

			-- Live Discord counts: no bot token needed. Just set
			-- ServerData.InviteCode = "your-code" (the part after discord.gg/)
			-- and real online/member numbers load from Discord's public
			-- invite API. Falls back to OnlineCount/MemberCount if offline.
			task.spawn(function()
				local res = webGet("https://discord.com/api/v9/invites/" .. inviteCode .. "?with_counts=true")
				if type(res) ~= "string" or res == "" then return end
				local ok2, js = pcall(function() return HttpService:JSONDecode(res) end)
				if not ok2 or type(js) ~= "table" then return end
				pcall(function()
					local online = tonumber(js.approximate_presence_count)
					local members = tonumber(js.approximate_member_count)
					if online then OnlineLabel.Text = tostring(online) .. " Online" end
					if members then MemberLabel.Text = tostring(members) .. " Members" end
					local guild = js.guild
					if type(guild) == "table" then
						if data.ServerName == nil and type(guild.name) == "string" and guild.name ~= "" then
							ServerName.Text = guild.name
						end
						if data.ServerIconId == nil and type(guild.id) == "string" and type(guild.icon) == "string" and guild.icon ~= "" then
							ServerIcon.Image = "https://cdn.discordapp.com/icons/" .. guild.id .. "/" .. guild.icon .. ".png?size=128"
						end
					end
				end)
			end)

			local DescLabel = Instance.new("TextLabel")
			DescLabel.Name = "DescLabel"
			DescLabel.Size = UDim2.new(1, 0, 0, 32)
			DescLabel.Text = data.Description or "Official LumuHub Community"
			DescLabel.Font = Enum.Font.GothamMedium
			regText(DescLabel, 12)
			DescLabel.TextColor3 = themeColorFor("220,220,228", CurrentThemeName or "Dark")
			DescLabel.TextXAlignment = Enum.TextXAlignment.Left
			DescLabel.TextYAlignment = Enum.TextYAlignment.Top
			DescLabel.TextWrapped = true
			DescLabel.BackgroundTransparency = 1
			DescLabel.LayoutOrder = 2
			DescLabel.Parent = InfoHolder

			local GameActivityFrame = Instance.new("Frame")
			GameActivityFrame.Size = UDim2.new(1, -28, 0, 20)
			GameActivityFrame.Position = UDim2.new(0, 14, 0, 178)
			GameActivityFrame.BackgroundTransparency = 1
			GameActivityFrame.Parent = MainFrame

			local GameIcon = Instance.new("ImageLabel")
			GameIcon.Size = UDim2.new(0, 18, 0, 18)
			GameIcon.Position = UDim2.new(0, 0, 0.5, -9)
			GameIcon.Image = "rbxassetid://104079816442680"
			GameIcon.BackgroundTransparency = 1
			GameIcon.Parent = GameActivityFrame

			local FlameBadge = Instance.new("ImageLabel")
			FlameBadge.Size = UDim2.new(0, 10, 0, 10)
			FlameBadge.Position = UDim2.new(1, -5, 0, -3)
			FlameBadge.Image = "rbxassetid://10841141110"
			FlameBadge.ImageColor3 = Color3.fromHex("#ff7324")
			FlameBadge.BackgroundTransparency = 1
			FlameBadge.Parent = GameIcon

			local GameLabel = Instance.new("TextLabel")
			GameLabel.Size = UDim2.new(1, -28, 1, 0)
			GameLabel.Position = UDim2.new(0, 28, 0, 0)
			GameLabel.Text = data.GameLabel or "ROBLOX"
			GameLabel.Font = Enum.Font.GothamBold
			mTS(GameLabel, 12)
			GameLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			GameLabel.TextXAlignment = Enum.TextXAlignment.Left
			GameLabel.BackgroundTransparency = 1
			GameLabel.Parent = GameActivityFrame

			local ActionButton = Instance.new("TextButton")
			ActionButton.Name = "JoinButton"
			ActionButton.Size = UDim2.new(0, 104, 0, 34)
			ActionButton.AnchorPoint = Vector2.new(1, 0.5)
			ActionButton.Position = UDim2.new(1, 0, 0.5, 0)
			ActionButton.BackgroundColor3 = Color3.fromRGB(30, 140, 78)
			ActionButton.BorderSizePixel = 0
			ActionButton.Text = "Join"
			ActionButton.Font = Enum.Font.GothamBold
			mTS(ActionButton, 15)
			ActionButton.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			ActionButton.AutoButtonColor = false
			ActionButton.Parent = BottomBar

			local ButtonCorner = Instance.new("UICorner")
			ButtonCorner.CornerRadius = UDim.new(0, 6)
			ButtonCorner.Parent = ActionButton

			local baseColor = Color3.fromRGB(30, 140, 78)
			local hoverColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.1)
			local pressColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.15)

			ActionButton.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(ActionButton, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
			end)
			ActionButton.MouseLeave:Connect(function()
				TweenService:Create(ActionButton, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
			end)
			ActionButton.MouseButton1Down:Connect(function()
				TweenService:Create(ActionButton, TweenInfo.new(0.05), {BackgroundColor3 = pressColor}):Play()
			end)

			ActionButton.MouseButton1Click:Connect(function()
				local inviteLink = "https://discord.gg/" .. inviteCode

				pcall(function() if setclipboard then setclipboard(inviteLink) end end)

				Window:Notify({
					Type = "good",
					Title = "Invite copied",
					Message = "discord.gg/" .. tostring(inviteCode) .. " is on your clipboard.",
					Duration = 6,
				})

				pcall(function()
					if httpRequest then
						httpRequest({
							Url = "http://127.0.0.1:6463/rpc?v=1",
							Method = "POST",
							Headers = {
								["Content-Type"] = "application/json",
								["Origin"] = "https://discord.com"
							},
							Body = HttpService:JSONEncode({
								cmd = "INVITE_BROWSER",
								args = { code = inviteCode },
								nonce = tostring(math.random(100000, 999999))
							})
						})
					end
				end)

				ActionButton.Text = "Copied!"
				ActionButton.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
				task.wait(2)
				ActionButton.Text = "Join"
				ActionButton.BackgroundColor3 = baseColor
			end)

			MainFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(BgHighlight, TweenInfo.new(0.2), {BackgroundTransparency = 0.95}):Play()
			end)
			MainFrame.MouseLeave:Connect(function()
				TweenService:Create(BgHighlight, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			end)

			registerElement(MainFrame, 240, config.Position)

		end
		-- =========================================================================
		-- NEW KEYBIND IMPLEMENTATION (MATCHES REFERENCE IMAGE PERFECTLY)
		-- =========================================================================
		function TabObject:AddKeybind(keybindConfig)
			keybindConfig = keybindConfig or {}
			local title = keybindConfig.Title or "Keybind"
			local default = keybindConfig.Default or Enum.KeyCode.RightControl
			local callback = keybindConfig.Callback or function() end
			local icon = parseIcon(keybindConfig.Icon)

			local calculatedHeight = IsMobile and 50 or 64

			local KeybindFrame = Instance.new("Frame")
			KeybindFrame.Name = title .. "_Keybind"
			KeybindFrame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			KeybindFrame.BorderSizePixel = 0

			local KeybindCorner = Instance.new("UICorner")
			KeybindCorner.CornerRadius = UDim.new(0, 12)
			KeybindCorner.Parent = KeybindFrame

			local KeybindStroke = Instance.new("UIStroke")
			KeybindStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			KeybindStroke.Thickness = 1
			KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			KeybindStroke.Parent = KeybindFrame

			-- Left Icon Container (Optional, same as toggle rows)
			local IconContainer = nil
			if icon then
				IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, 10, 0.5, IsMobile and -16 or -21)
				IconContainer.Size = UDim2.new(0, IsMobile and 32 or 42, 0, IsMobile and 32 or 42)
				IconContainer.Parent = KeybindFrame

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer

				local IconContainerStroke = Instance.new("UIStroke")
				IconContainerStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconContainerStroke.Transparency = 0.3
				IconContainerStroke.Thickness = 1.5
				IconContainerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconContainerStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 22 or 30)
				Astral.ApplyIcon(IconLabel, icon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			-- Text Container
			local TextContainer = Instance.new("Frame")
			TextContainer.Name = "TextContainer"
			TextContainer.BackgroundTransparency = 1
			TextContainer.Position = icon and UDim2.new(0, 60, 0, 0) or UDim2.new(0, 12, 0, 0)
			TextContainer.Size = icon and UDim2.new(1, -180, 1, 0) or UDim2.new(1, -130, 1, 0)
			TextContainer.Parent = KeybindFrame

			local TextListLayout = Instance.new("UIListLayout")
			TextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TextListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			TextListLayout.Padding = UDim.new(0, 2)
			TextListLayout.Parent = TextContainer

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 11)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.TextWrapped = false
			TitleLabel.Parent = TextContainer


			local KeybindButton = Instance.new("TextButton")
			KeybindButton.Name = "KeybindButton"
			KeybindButton.BackgroundColor3 = themeColorFor("42,42,50", CurrentThemeName or "Dark")
			KeybindButton.BorderSizePixel = 0
			KeybindButton.AnchorPoint = Vector2.new(1, 0.5)
			KeybindButton.Position = UDim2.new(1, -12, 0.5, 0)
			KeybindButton.Size = UDim2.new(0, 0, 0, 34) -- Dynamic width
			KeybindButton.AutomaticSize = Enum.AutomaticSize.X
			KeybindButton.Font = Enum.Font.GothamBold
			KeybindButton.Text = default.Name
			KeybindButton.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(KeybindButton, 13)
			KeybindButton.AutoButtonColor = false
			KeybindButton.Parent = KeybindFrame

			local ButtonCorner = Instance.new("UICorner")
			ButtonCorner.CornerRadius = UDim.new(0, 8)
			ButtonCorner.Parent = KeybindButton

			-- Clear outline so the key box is easy to see on the dark card
			local ButtonStroke = Instance.new("UIStroke")
			ButtonStroke.Color = themeColorFor("70,70,80", CurrentThemeName or "Dark")
			ButtonStroke.Thickness = 1.2
			ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ButtonStroke.Parent = KeybindButton

			local ButtonPadding = Instance.new("UIPadding")
			ButtonPadding.PaddingLeft = UDim.new(0, 18)
			ButtonPadding.PaddingRight = UDim.new(0, 18)
			ButtonPadding.Parent = KeybindButton

			local currentKey = default
			local listening = false
			local inputConnection

			-- Sink game input while binding so e.g. pressing S binds it without walking
			local sinkName = "AstralKeybindSink_" .. tostring(math.random(100000, 999999))
			local function sinkGameInput()
				local CAS = game:GetService("ContextActionService")
				local keys = {}
				for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
					if item ~= Enum.KeyCode.Unknown then
						table.insert(keys, item)
					end
				end
				pcall(function()
					CAS:UnbindAction(sinkName)
					CAS:BindActionAtPriority(sinkName, function()
						return Enum.ContextActionResult.Sink
					end, false, Enum.ContextActionPriority.High.Value, unpack(keys))
				end)
			end
			local function unsinkGameInput()
				pcall(function()
					game:GetService("ContextActionService"):UnbindAction(sinkName)
				end)
			end

			local function stopListeningVisual()
				TweenService:Create(KeybindButton, TweenInfo.new(0.15), {BackgroundColor3 = themeColorFor("34,34,40", CurrentThemeName or "Dark")}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.15), {Color = themeColorFor("70,70,80", CurrentThemeName or "Dark")}):Play()
			end

			local function startListening()
				if listening then return end
				listening = true
				KeybindButton.Text = "..."
				TweenService:Create(KeybindButton, TweenInfo.new(0.15), {BackgroundColor3 = AccentColor}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.15), {Color = AccentColor}):Play()
				sinkGameInput()

				if inputConnection then inputConnection:Disconnect() end

				inputConnection = UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Keyboard then
						local key = input.KeyCode
						if key ~= Enum.KeyCode.Unknown then
							inputConnection:Disconnect()
							inputConnection = nil
							currentKey = key
							KeybindButton.Text = key.Name
							listening = false
							unsinkGameInput()
							stopListeningVisual()
							task.spawn(callback, key)
						end
					end
				end)
			end

			KeybindButton.MouseButton1Click:Connect(function()
				-- Click again while binding = cancel (never trap movement)
				if listening then
					listening = false
					if inputConnection then
						inputConnection:Disconnect()
						inputConnection = nil
					end
					unsinkGameInput()
					KeybindButton.Text = currentKey.Name
					stopListeningVisual()
					return
				end
				startListening()
			end)

			-- Hover effects (identical to toggle/button rows)
			KeybindFrame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(KeybindFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(KeybindStroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
			end)
			KeybindFrame.MouseLeave:Connect(function()
				TweenService:Create(KeybindFrame, TweenInfo.new(0.15), {BackgroundColor3 = themeCardBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(KeybindStroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
			end)

			-- Key box hover: accent outline so it reads as clickable
			KeybindButton.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				if listening then return end
				TweenService:Create(KeybindButton, TweenInfo.new(0.15), {BackgroundColor3 = themeHoverBG(Window.ThemeName or "Dark")}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.15), {Color = AccentColor}):Play()
			end)
			KeybindButton.MouseLeave:Connect(function()
				if listening then return end
				stopListeningVisual()
			end)

			registerElement(KeybindFrame, calculatedHeight, keybindConfig.Position)

			local KeybindController = {}
			function KeybindController:Set(key)
				if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
					currentKey = key
					KeybindButton.Text = key.Name
					task.spawn(callback, key)
				end
			end
			function KeybindController:Get()
				return currentKey
			end
			if keybindConfig.Flag and keybindConfig.Flag ~= "" then
				table.insert(configFlags, {Flag = keybindConfig.Flag, Kind = "key",
					Get = function() return currentKey end,
					Set = function(v) KeybindController:Set(v) end})
			end

			return KeybindController
		end

		-- =========================================================================
		-- MULTIBUTTON: card with a grid of clickable buttons.
		-- Buttons can be text only, icon only, or icon + text.
		--   Tab:AddMultiButton({
		--     Title = "Quick Teleports",
		--     Columns = 2,               -- optional (default 2)
		--     Buttons = {
		--       {Title = "sea 1", Callback = function() end},
		--       {Title = "sea 2", Icon = "star", Callback = function() end},
		--       {Icon = "chest", Callback = function() end},  -- icon only
		--     },
		--   })
		-- =========================================================================
		-- =========================================================================
		-- MULTIBUTTON: card with a grid of clickable buttons.
		-- Buttons can be text only, icon only, or icon + text.
		--   Tab:AddMultiButton({
		--     Title = "Quick Teleports",
		--     Columns = 2,                     -- optional (default 2)
		--     ButtonColor = Color3.fromRGB(..),-- optional: all buttons this color
		--     Buttons = {
		--       {Title = "sea 1", Callback = function() end},
		--       {Title = "sea 2", Icon = "star", Callback = function() end},
		--       {Icon = "chest", Color = "red", Callback = function() end},  -- icon only
		--     },
		--   })
		-- If EVERY button is icon-only they render as big square icon tiles.
		-- =========================================================================
		local function parseButtonColor(v)
			if typeof(v) == "Color3" then return v end
			if type(v) == "string" then
				local named = {
					red = themeColorFor("231,76,60", CurrentThemeName or "Dark"),
					green = themeColorFor("46,204,113", CurrentThemeName or "Dark"),
					blue = themeColorFor("0,153,235", CurrentThemeName or "Dark"),
					cyan = themeColorFor("0,210,255", CurrentThemeName or "Dark"),
					purple = Color3.fromRGB(138, 90, 255),
					pink = themeColorFor("255,90,180", CurrentThemeName or "Dark"),
					orange = themeColorFor("243,156,18", CurrentThemeName or "Dark"),
					gold = themeColorFor("255,212,0", CurrentThemeName or "Dark"),
					white = themeColorFor("240,240,245", CurrentThemeName or "Dark"),
					dark = Color3.fromRGB(40, 40, 46),
				}
				return named[v:lower()]
			end
			return nil
		end

		function TabObject:AddMultiButton(cfg)
			cfg = cfg or {}
			local title = cfg.Title or "Multi Button"
			local description = cfg.Description
			local cardIcon = parseIcon(cfg.Icon)
			local items = cfg.Buttons or {}
			local columns = math.max(1, math.floor(cfg.Columns or 2))
			if IsMobile and columns > 2 then columns = 2 end
			local hasDesc = description and description ~= ""
			local cardButtonColor = parseButtonColor(cfg.ButtonColor)

			-- icon-only mode: every button has no title -> big square tiles
			local iconOnlyMode = #items > 0
			for _, it in ipairs(items) do
				if it and it.Title and it.Title ~= "" then iconOnlyMode = false; break end
			end

			local pad = IsMobile and 6 or 10
			local gap = IsMobile and 6 or 10
			local btnH = iconOnlyMode and (IsMobile and 48 or 64) or (IsMobile and 28 or 34)
			if not iconOnlyMode then
				for _, it in ipairs(items) do
					if it and it.Title and string.find(tostring(it.Title), "%s") then
						btnH = (IsMobile and 44 or 50)
						break
					end
				end
			end
			local headerH = hasDesc and (IsMobile and 30 or 36) or (IsMobile and 18 or 22)
			local rows = math.max(1, math.ceil(#items / columns))
			local gridH = rows * btnH + (rows - 1) * gap
			local calculatedHeight = pad + headerH + 10 + gridH + pad

			local Card = Instance.new("Frame")
			Card.Name = title .. "_MultiButton"
			Card.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			Card.BorderSizePixel = 0
			Card.Size = UDim2.new(1, 0, 0, calculatedHeight)

			local CardCorner = Instance.new("UICorner")
			CardCorner.CornerRadius = UDim.new(0, 8)
			CardCorner.Parent = Card

			local CardStroke = Instance.new("UIStroke")
			CardStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			CardStroke.Thickness = 1
			CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			CardStroke.Parent = Card

			-- Optional card icon
			if cardIcon then
				local IconContainer = Instance.new("Frame")
				IconContainer.Name = "IconContainer"
				IconContainer.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
				IconContainer.BorderSizePixel = 0
				IconContainer.Position = UDim2.new(0, pad, 0, pad)
				IconContainer.Size = UDim2.new(0, 30, 0, 30)
				IconContainer.Parent = Card

				local IconCorner = Instance.new("UICorner")
				IconCorner.CornerRadius = UDim.new(0, 6)
				IconCorner.Parent = IconContainer

				local IconStroke = Instance.new("UIStroke")
				IconStroke.Color = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconStroke.Transparency = 0.3
				IconStroke.Thickness = 1.5
				IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				IconStroke.Parent = IconContainer

				local IconLabel = Instance.new("ImageLabel")
				IconLabel.Name = "Icon"
				IconLabel.BackgroundTransparency = 1
				IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				IconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				IconLabel.Size = UDim2.new(0, 18, 0, 18)
				Astral.ApplyIcon(IconLabel, cardIcon)
				IconLabel.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				IconLabel.ScaleType = Enum.ScaleType.Fit
				IconLabel.Parent = IconContainer
			end

			local textX = cardIcon and (pad + 38) or pad
			local Header = Instance.new("Frame")
			Header.Name = "Header"
			Header.BackgroundTransparency = 1
			Header.Position = UDim2.new(0, textX, 0, pad)
			Header.Size = UDim2.new(1, -textX - pad, 0, headerH)
			Header.Parent = Card

			local HeaderLayout = Instance.new("UIListLayout")
			HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
			HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			HeaderLayout.Padding = UDim.new(0, 1)
			HeaderLayout.Parent = Header

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 18)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 12)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = Header

			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 16)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = Header
			end

			-- Button grid
			local Grid = Instance.new("Frame")
			Grid.Name = "ButtonGrid"
			Grid.BackgroundTransparency = 1
			Grid.Position = UDim2.new(0, pad, 0, pad + headerH + 10)
			Grid.Size = UDim2.new(1, -pad * 2, 0, gridH)
			Grid.Parent = Card

			local GridLayout = Instance.new("UIGridLayout")
			if columns <= 1 then
				GridLayout.CellSize = UDim2.new(1, 0, 0, btnH)
				GridLayout.CellPadding = UDim2.new(0, 0, 0, gap)
			else
				local shrink = math.ceil((columns - 1) * gap / columns)
				GridLayout.CellSize = UDim2.new(1 / columns, -shrink, 0, btnH)
				GridLayout.CellPadding = UDim2.new(0, gap, 0, gap)
			end
			GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
			GridLayout.FillDirectionMaxCells = columns
			GridLayout.Parent = Grid

			local accentButtons = {}

			for i, item in ipairs(items) do
				item = item or {}
				local bTitle = item.Title
				local bIcon = parseIcon(item.Icon)
				local bCallback = item.Callback or function() end
				local bColor = parseButtonColor(item.Color) or cardButtonColor

				local Btn = Instance.new("TextButton")
				Btn.Name = (bTitle or "icon") .. "_MultiBtn"
				Btn.BackgroundColor3 = bColor or AccentColor
				Btn.BorderSizePixel = 0
				Btn.Text = ""
				Btn.AutoButtonColor = false
				Btn.ClipsDescendants = true
				Btn.LayoutOrder = i
				Btn.Parent = Grid

				local BtnCorner = Instance.new("UICorner")
				BtnCorner.CornerRadius = UDim.new(0, iconOnlyMode and 10 or 6)
				BtnCorner.Parent = Btn

				local BtnScale = Instance.new("UIScale")
				BtnScale.Scale = 1
				BtnScale.Parent = Btn

				-- Centered content row: icon and/or text
				local Content = Instance.new("Frame")
				Content.Name = "Content"
				Content.BackgroundTransparency = 1
				Content.ClipsDescendants = true
				Content.Size = UDim2.new(1, -12, 1, 0)
				Content.Position = UDim2.new(0, 6, 0, 0)
				Content.Parent = Btn

				local ContentLayout = Instance.new("UIListLayout")
				ContentLayout.FillDirection = Enum.FillDirection.Horizontal
				ContentLayout.HorizontalAlignment = iconOnlyMode and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left
				ContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ContentLayout.Padding = UDim.new(0, 6)
				ContentLayout.Parent = Content

				if bIcon then
					local BIcon = Instance.new("ImageLabel")
					BIcon.Name = "Icon"
					BIcon.BackgroundTransparency = 1
					local iSize = iconOnlyMode and (IsMobile and 28 or 34) or (IsMobile and 14 or 18)
					BIcon.Size = UDim2.new(0, iSize, 0, iSize)
					BIcon.LayoutOrder = 1
					Astral.ApplyIcon(BIcon, bIcon)
					BIcon.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					BIcon.ScaleType = Enum.ScaleType.Fit
					BIcon.Parent = Content
				end

				if not iconOnlyMode and bTitle and bTitle ~= "" then
					local BLabel = Instance.new("TextLabel")
					BLabel.Name = "Label"
					BLabel.BackgroundTransparency = 1
					BLabel.Size = UDim2.new(1, bIcon and -20 or 0, 1, 0)
					BLabel.Font = Enum.Font.GothamBold
					BLabel.Text = bTitle
					BLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					BLabel.TextSize = IsMobile and 10 or 12
					BLabel.TextXAlignment = Enum.TextXAlignment.Center
					BLabel.TextWrapped = true
					BLabel.TextTruncate = Enum.TextTruncate.AtEnd
					BLabel.LayoutOrder = 2
					BLabel.Parent = Content
				end

				Btn.MouseButton1Click:Connect(function()
					task.spawn(bCallback)
				end)
				Btn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						TweenService:Create(BtnScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.95}):Play()
					end
				end)
				Btn.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						TweenService:Create(BtnScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
					end
				end)
				Btn.MouseEnter:Connect(function()
					if pickerOpen or selectorOpen then return end
					TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = (bColor or AccentColor):Lerp(Color3.new(1, 1, 1), 0.15)}):Play()
				end)
				Btn.MouseLeave:Connect(function()
					TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = bColor or AccentColor}):Play()
				end)

				-- only buttons without an explicit color follow the accent
				if not bColor then
					table.insert(accentButtons, Btn)
					onAccentChange(function(c)
						Btn.BackgroundColor3 = c
					end)
				end
			end

			registerElement(Card, calculatedHeight, cfg.Position)

			-- Icon-only tiles: make the cells square once the real width is known
			if iconOnlyMode then
				GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				local function squareUp()
					local w = Grid.AbsoluteSize.X
					if w < 10 then return end
					-- fit the row, but keep tiles a sane size (44..72px)
					local fit = math.floor((w - (columns - 1) * gap) / columns)
					local cell = math.clamp(fit, 44, 72)
					local cellSize = UDim2.new(0, cell, 0, cell)
					if GridLayout.CellSize ~= cellSize then
						GridLayout.CellSize = cellSize
						local newRows = math.max(1, math.ceil(#items / columns))
						local newGridH = newRows * cell + (newRows - 1) * gap
						Grid.Size = UDim2.new(1, -pad * 2, 0, newGridH)
						local newCardH = pad + headerH + 10 + newGridH + pad
						Card.Size = UDim2.new(1, 0, 0, newCardH)
						for _, el in ipairs(elements) do
							if el.Frame == Card then
								el.Height = newCardH
								break
							end
						end
						distributeElements()
					end
				end
				Grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(squareUp)
				task.defer(squareUp)
			end

			local MultiController = {}
			function MultiController:SetAccent(color)
				for _, b in ipairs(accentButtons) do
					pcall(function() b.BackgroundColor3 = color end)
				end
			end
			return MultiController
		end


		-- MultiColorPicker: MultiButton-style buttons where every tile is a
		-- mini color picker. Tap a tile to open the picker; confirming recolors
		-- the tile and fires Callback(index, color).
		-- Usage: tab:AddMultiColorPicker({ Title = "Skins", Columns = 2, Buttons = {
		--   { Title = "Kill", Icon = "Gun", Color = "red",
		--     Callback = function(i, c) print(i, c) end },
		-- }})
		function TabObject:AddMultiColorPicker(cfg)
			cfg = cfg or {}
			local title = cfg.Title or "Colors"
			local description = cfg.Description
			local items = cfg.Buttons or {}
			local columns = math.max(1, math.floor(cfg.Columns or 2))
			if IsMobile and columns > 2 then columns = 2 end
			local hasDesc = description and description ~= "" or false

			local iconOnlyMode = #items > 0
			for _, it in ipairs(items) do
				if it and it.Title and it.Title ~= "" then iconOnlyMode = false; break end
			end

			local pad = IsMobile and 6 or 10
			local gap = IsMobile and 6 or 10
			local btnH = iconOnlyMode and (IsMobile and 48 or 64) or (IsMobile and 40 or 48)
			local headerH = hasDesc and (IsMobile and 30 or 36) or (IsMobile and 18 or 22)
			local rows = math.max(1, math.ceil(math.max(1, #items) / columns))
			local gridH = rows * btnH + (rows - 1) * gap
			local calculatedHeight = pad + headerH + 10 + gridH + pad

			local Card = Instance.new("Frame")
			Card.Name = title .. "_MultiColorPicker"
			Card.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			Card.BorderSizePixel = 0
			Card.Size = UDim2.new(1, 0, 0, calculatedHeight)

			local CardCorner = Instance.new("UICorner")
			CardCorner.CornerRadius = UDim.new(0, 8)
			CardCorner.Parent = Card

			local CardStroke = Instance.new("UIStroke")
			CardStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			CardStroke.Thickness = 1
			CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			CardStroke.Parent = Card

			local Header = Instance.new("Frame")
			Header.Name = "Header"
			Header.BackgroundTransparency = 1
			Header.Position = UDim2.new(0, pad, 0, pad)
			Header.Size = UDim2.new(1, -pad * 2, 0, headerH)
			Header.Parent = Card

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Size = UDim2.new(1, 0, 0, 18)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, 12)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = Header

			if hasDesc then
				local DescLabel = Instance.new("TextLabel")
				DescLabel.Name = "Description"
				DescLabel.BackgroundTransparency = 1
				DescLabel.Size = UDim2.new(1, 0, 0, 16)
				DescLabel.Font = Enum.Font.Gotham
				tr(DescLabel, description)
				DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
				regText(DescLabel, 10)
				DescLabel.TextXAlignment = Enum.TextXAlignment.Left
				DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
				DescLabel.Parent = Header
			end

			local Grid = Instance.new("Frame")
			Grid.Name = "ButtonGrid"
			Grid.BackgroundTransparency = 1
			Grid.Position = UDim2.new(0, pad, 0, pad + headerH + 10)
			Grid.Size = UDim2.new(1, -pad * 2, 0, gridH)
			Grid.Parent = Card

			local GridLayout = Instance.new("UIGridLayout")
			local shrink = math.ceil((columns - 1) * gap / columns)
			GridLayout.CellSize = UDim2.new(1 / columns, -shrink, 0, btnH)
			GridLayout.CellPadding = UDim2.new(0, gap, 0, gap)
			GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
			GridLayout.FillDirectionMaxCells = columns
			GridLayout.Parent = Grid

			local tiles = {}
			local expandedTile = nil
			local baseCardH = calculatedHeight
			local function setMultiCardHeight(h)
				Card.Size = UDim2.new(1, 0, 0, h)
				for _, el in ipairs(elements) do
					if el.Frame == Card then el.Height = h; break end
				end
				distributeElements()
				updateCanvas()
			end
			local function collapseTile(t)
				if not t or not t.Exp then return end
				if expandedTile == t then expandedTile = nil end
				t.Btn.ZIndex = 1
				TweenService:Create(t.Exp, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, t.ExpW or 0, 0, 0) }):Play()
				setMultiCardHeight(baseCardH)
				task.delay(0.2, function()
					pcall(function()
						if expandedTile ~= t then t.Exp.Visible = false end
					end)
				end)
			end
			local function expandTile(t)
				if expandedTile and expandedTile ~= t then collapseTile(expandedTile) end
				local order = t.Btn.LayoutOrder or 1
				local row = math.floor((order - 1) / math.max(1, columns))
				local gx, gy, gw = 12, 0, 200
				pcall(function()
					local gp = Grid.AbsolutePosition
					local cp = Card.AbsolutePosition
					gx = gp.X - cp.X
					gy = (gp.Y - cp.Y) + row * (btnH + gap) + btnH + 4
					gw = Grid.AbsoluteSize.X
				end)
				t.ExpW = gw
				t.Exp.Parent = Card
				t.Exp.Position = UDim2.new(0, gx, 0, gy)
				t.Exp.Size = UDim2.new(0, gw, 0, 0)
				t.Exp.Visible = true
				t.Btn.ZIndex = 10
				TweenService:Create(t.Exp, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, gw, 0, 134) }):Play()
				expandedTile = t
				setMultiCardHeight(baseCardH + 138)
			end
			local function buildExpander(tileBtn, initColor, onApply, onClose)
				local eh, es, ev = Color3.toHSV(initColor)
				local Exp = Instance.new("Frame")
				Exp.Name = "Expander"
				Exp.BackgroundColor3 = themeColorFor("24,24,29", CurrentThemeName or "Dark")
				Exp.BorderSizePixel = 0
				Exp.Position = UDim2.new(0, 0, 1, 4)
				Exp.Size = UDim2.new(1, 0, 0, 0)
				Exp.ClipsDescendants = true
				Exp.Visible = false
				Exp.ZIndex = 10
				Exp.Parent = Card
				local ExpCorner = Instance.new("UICorner")
				ExpCorner.CornerRadius = UDim.new(0, 8)
				ExpCorner.Parent = Exp
				local ExpStroke = Instance.new("UIStroke")
				ExpStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
				ExpStroke.Thickness = 1
				ExpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				ExpStroke.Parent = Exp
				local ExpCanvas = Instance.new("Frame")
				ExpCanvas.Position = UDim2.new(0, 8, 0, 8)
				ExpCanvas.Size = UDim2.new(1, -40, 0, 86)
				ExpCanvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ExpCanvas.BorderSizePixel = 0
				ExpCanvas.ClipsDescendants = true
				ExpCanvas.Parent = Exp
				local ExpCanvasCorner = Instance.new("UICorner")
				ExpCanvasCorner.CornerRadius = UDim.new(0, 6)
				ExpCanvasCorner.Parent = ExpCanvas
				local ExpRainbow = Instance.new("UIGradient")
				ExpRainbow.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, themeColorFor("255,0,0", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.17, themeColorFor("255,255,0", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.33, themeColorFor("0,255,0", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.5, themeColorFor("0,255,255", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.67, themeColorFor("0,0,255", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.83, themeColorFor("255,0,255", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(1, themeColorFor("255,0,0", CurrentThemeName or "Dark")),
				})
				ExpRainbow.Parent = ExpCanvas
				local ExpShade = Instance.new("Frame")
				ExpShade.Size = UDim2.fromScale(1, 1)
				ExpShade.BackgroundColor3 = themeColorFor("0,0,0", CurrentThemeName or "Dark")
				ExpShade.BorderSizePixel = 0
				ExpShade.Parent = ExpCanvas
				local ExpShadeCorner = Instance.new("UICorner")
				ExpShadeCorner.CornerRadius = UDim.new(0, 6)
				ExpShadeCorner.Parent = ExpShade
				local ExpShadeGrad = Instance.new("UIGradient")
				ExpShadeGrad.Rotation = 90
				ExpShadeGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				})
				ExpShadeGrad.Parent = ExpShade
				local ExpCursor = Instance.new("Frame")
				ExpCursor.Size = UDim2.new(0, 12, 0, 12)
				ExpCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				ExpCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ExpCursor.Parent = ExpCanvas
				local ExpCursorCorner = Instance.new("UICorner")
				ExpCursorCorner.CornerRadius = UDim.new(1, 0)
				ExpCursorCorner.Parent = ExpCursor
				local ExpCursorStroke = Instance.new("UIStroke")
				ExpCursorStroke.Color = themeColorFor("0,0,0", CurrentThemeName or "Dark")
				ExpCursorStroke.Thickness = 1.5
				ExpCursorStroke.Parent = ExpCursor
				local ExpBar = Instance.new("Frame")
				ExpBar.Position = UDim2.new(1, -24, 0, 8)
				ExpBar.Size = UDim2.new(0, 16, 0, 86)
				ExpBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ExpBar.BorderSizePixel = 0
				ExpBar.ClipsDescendants = true
				ExpBar.Parent = Exp
				local ExpBarCorner = Instance.new("UICorner")
				ExpBarCorner.CornerRadius = UDim.new(0, 5)
				ExpBarCorner.Parent = ExpBar
				local ExpBarGrad = Instance.new("UIGradient")
				ExpBarGrad.Rotation = 90
				ExpBarGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, themeColorFor("255,255,255", CurrentThemeName or "Dark")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(1, themeColorFor("0,0,0", CurrentThemeName or "Dark")),
				})
				ExpBarGrad.Parent = ExpBar
				local ExpBarCursor = Instance.new("Frame")
				ExpBarCursor.Size = UDim2.new(1, 0, 0, 5)
				ExpBarCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				ExpBarCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ExpBarCursor.Parent = ExpBar
				local ExpBarCursorCorner = Instance.new("UICorner")
				ExpBarCursorCorner.CornerRadius = UDim.new(1, 0)
				ExpBarCursorCorner.Parent = ExpBarCursor
				local ExpPrev = Instance.new("Frame")
				ExpPrev.Position = UDim2.new(0, 8, 0, 102)
				ExpPrev.Size = UDim2.new(0, 36, 0, 24)
				ExpPrev.BackgroundColor3 = initColor
				ExpPrev.BorderSizePixel = 0
				ExpPrev.Parent = Exp
				local ExpPrevCorner = Instance.new("UICorner")
				ExpPrevCorner.CornerRadius = UDim.new(0, 6)
				ExpPrevCorner.Parent = ExpPrev
				local ExpApply = Instance.new("TextButton")
				ExpApply.Position = UDim2.new(0, 52, 0, 102)
				ExpApply.Size = UDim2.new(1, -60, 0, 24)
				ExpApply.BackgroundColor3 = AccentColor
				ExpApply.Font = Enum.Font.GothamBold
				ExpApply.Text = "Apply"
				ExpApply.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				ExpApply.TextSize = 12
				ExpApply.AutoButtonColor = false
				ExpApply.Parent = Exp
				local ExpApplyCorner = Instance.new("UICorner")
				ExpApplyCorner.CornerRadius = UDim.new(0, 6)
				ExpApplyCorner.Parent = ExpApply
				local function expRefresh()
					local col = Color3.fromHSV(eh, es, ev)
					ExpPrev.BackgroundColor3 = col
					ExpCursor.Position = UDim2.new(eh, 0, 1 - ev, 0)
					local bp = (es < 1) and (es * 0.5) or (1 - ev * 0.5)
					ExpBarCursor.Position = UDim2.new(0.5, 0, bp, 0)
					ExpBarGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, themeColorFor("255,255,255", CurrentThemeName or "Dark")),
						ColorSequenceKeypoint.new(0.5, Color3.fromHSV(eh, 1, 1)),
						ColorSequenceKeypoint.new(1, themeColorFor("0,0,0", CurrentThemeName or "Dark")),
					})
				end
				local cDrag, bDrag = false, false
				ExpCanvas.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						cDrag = true
						local rx, ry = getRelativePosition(ExpCanvas, input)
						eh = rx
						ev = 1 - ry
						expRefresh()
					end
				end)
				ExpBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						bDrag = true
						local _, ry = getRelativePosition(ExpBar, input)
						local p = math.clamp(ry, 0, 1)
						if p <= 0.5 then es = p * 2 else es = 1 ev = (1 - p) * 2 end
						expRefresh()
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
					if cDrag then
						local rx, ry = getRelativePosition(ExpCanvas, input)
						eh = rx
						ev = 1 - ry
						expRefresh()
					end
					if bDrag then
						local _, ry = getRelativePosition(ExpBar, input)
						local p = math.clamp(ry, 0, 1)
						if p <= 0.5 then es = p * 2 else es = 1 ev = (1 - p) * 2 end
						expRefresh()
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						cDrag = false
						bDrag = false
					end
				end)
				ExpApply.MouseButton1Click:Connect(function()
					onApply(Color3.fromHSV(eh, es, ev))
				end)
				expRefresh()
				return Exp
			end
			for i, item in ipairs(items) do
				item = item or {}
				local bTitle = item.Title
				local bIcon = parseIcon(item.Icon)
				local bCallback = item.Callback or function() end
				local bColor = parseButtonColor(item.Color) or themeColorFor("40,40,48", CurrentThemeName or "Dark")
				local baseName = (bTitle and bTitle ~= "") and bTitle or ("Color " .. i)

				local Btn = Instance.new("TextButton")
				Btn.Name = baseName .. "_MultiColorBtn"
				Btn.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
				Btn.BorderSizePixel = 0
				Btn.Text = ""
				Btn.AutoButtonColor = false
				Btn.ClipsDescendants = false
				Btn.LayoutOrder = i
				Btn.Parent = Grid

				local BtnCorner = Instance.new("UICorner")
				BtnCorner.CornerRadius = UDim.new(0, iconOnlyMode and 10 or 6)
				BtnCorner.Parent = Btn

				local BtnStroke = Instance.new("UIStroke")
				BtnStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
				BtnStroke.Thickness = 1
				BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BtnStroke.Parent = Btn

				local TilePreview = nil
				if not iconOnlyMode then
					TilePreview = Instance.new("TextButton")
					TilePreview.Name = "ColorBox"
					TilePreview.AnchorPoint = Vector2.new(1, 0.5)
					TilePreview.Position = UDim2.new(1, -10, 0.5, 0)
					TilePreview.Size = UDim2.new(0, IsMobile and 48 or 56, 0, IsMobile and 22 or 26)
					TilePreview.BackgroundColor3 = bColor
					TilePreview.BorderSizePixel = 0
					TilePreview.Text = ""
					TilePreview.AutoButtonColor = false
					TilePreview.ZIndex = 2
					TilePreview.Parent = Btn

					local PreviewCorner = Instance.new("UICorner")
					PreviewCorner.CornerRadius = UDim.new(0, 8)
					PreviewCorner.Parent = TilePreview

					local PreviewStroke = Instance.new("UIStroke")
					PreviewStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
					PreviewStroke.Thickness = 1.2
					PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					PreviewStroke.Parent = TilePreview
				end

				if bIcon then
					local BIcon = Instance.new("ImageLabel")
					BIcon.Name = "Icon"
					BIcon.BackgroundTransparency = 1
					if iconOnlyMode then
						BIcon.AnchorPoint = Vector2.new(0.5, 0.5)
						BIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
					else
						BIcon.AnchorPoint = Vector2.new(0, 0.5)
						BIcon.Position = UDim2.new(0, 10, 0.5, 0)
					end
					BIcon.Size = UDim2.new(0, iconOnlyMode and (IsMobile and 28 or 34) or (IsMobile and 18 or 22), 0, iconOnlyMode and (IsMobile and 28 or 34) or (IsMobile and 18 or 22))
					Astral.ApplyIcon(BIcon, bIcon)
					BIcon.ImageColor3 = iconOnlyMode and bColor or themeColorFor("255,255,255", CurrentThemeName or "Dark")
					BIcon.ScaleType = Enum.ScaleType.Fit
					BIcon.Parent = Btn
				end

				if not iconOnlyMode and bTitle and bTitle ~= "" then
					local BLabel = Instance.new("TextLabel")
					BLabel.Name = "Label"
					BLabel.BackgroundTransparency = 1
					BLabel.Position = UDim2.new(0, bIcon and 38 or 10, 0, 0)
					BLabel.Size = UDim2.new(1, -(bIcon and 38 or 10) - (IsMobile and 68 or 76), 1, 0)
					BLabel.Font = Enum.Font.GothamBold
					tr(BLabel, bTitle)
					BLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					BLabel.TextSize = IsMobile and 10 or 12
					BLabel.TextXAlignment = Enum.TextXAlignment.Left
					BLabel.TextTruncate = Enum.TextTruncate.AtEnd
					BLabel.Parent = Btn
				end

				local tileIndex = i
				local Exp = buildExpander(Btn, bColor, function(col)
					local tt = tiles[tileIndex]
					if tt then
						tt.Color = col
						if tt.Preview then
							tt.Preview.BackgroundColor3 = col
						else
							local ic = tt.Btn:FindFirstChild("Icon")
							if ic then ic.ImageColor3 = col end
						end
						task.spawn(tt.Callback, tileIndex, col)
					end
					collapseTile(tiles[tileIndex])
				end, function()
					collapseTile(tiles[tileIndex])
				end)
				tiles[i] = {Btn = Btn, Preview = TilePreview, Color = bColor, Callback = bCallback, Exp = Exp, Stroke = BtnStroke}
				Btn.MouseButton1Click:Connect(function()
					if pickerOpen or selectorOpen then return end
					local t = tiles[tileIndex]
					if not t then return end
					if expandedTile == t then
						collapseTile(t)
					else
						expandTile(t)
					end
				end)
				if TilePreview then
					TilePreview.MouseButton1Click:Connect(function()
						if pickerOpen or selectorOpen then return end
						local t = tiles[tileIndex]
						if not t then return end
						if expandedTile == t then
							collapseTile(t)
						else
							expandTile(t)
						end
					end)
				end
				Btn.MouseEnter:Connect(function()
					if pickerOpen or selectorOpen then return end
					TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")}):Play()
				end)
				Btn.MouseLeave:Connect(function()
					TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")}):Play()
				end)
			end

			registerElement(Card, calculatedHeight, cfg.Position)

			local MultiColorController = {}
			function MultiColorController:GetColor(index)
				local t = tiles[index or 1]
				if t then return t.Color end
				return nil
			end
			function MultiColorController:GetAllColors()
				local out = {}
				for i, t in ipairs(tiles) do out[i] = t.Color end
				return out
			end
			function MultiColorController:SetColor(index, color)
				if typeof(color) ~= "Color3" then return end
				local t = tiles[index]
				if not t then return end
				t.Color = color
				if t.Preview then
					t.Preview.BackgroundColor3 = color
				else
					local ic = t.Btn:FindFirstChild("Icon")
					if ic then ic.ImageColor3 = color end
				end
			end
			function MultiColorController:Click(index)
				local t = tiles[index]
				if t and t.Callback then task.spawn(t.Callback, index, t.Color) end
			end
			return MultiColorController
		end
		TabObject.Addmulticolorpicker = TabObject.AddMultiColorPicker


		-- PlayerBrowser: players section with avatar cards (pfp + display name
		-- + @username). Grid of big boxes or single-row compact strip, live
		-- search, per-player "..." options. Tracks joins/leaves by itself.
		-- Usage:
		--   local pb = Tab:AddPlayerBrowser({
		--     Title = "Players Section",    -- optional
		--     Mode = "Grid",                -- "Grid" or "Row" (default Grid)
		--     Search = true,                -- search box (default true)
		--     Callback = function(player) print(player.Name) end,        -- card click
		--     Multi = true, -- pick several players at once (GetSelected returns a list)
		--   })
		--   pb:SetMode("Row"); pb:Refresh(); pb:GetSelected()
		-- =========================================================================
		-- SKILL SELECTOR (fight-game skills: key rows with cooldowns).
		-- Press the key (or tap the row) to fire; row greys out with a
		-- countdown until it can be used again. Hold box edits per-skill hold.
		--   Tab:AddSkillSelector({
		--     Skills = { { Key = "Z", Hold = 0.5, Cooldown = 3 } },
		--     Callback = function(key, hold) print(key, hold) end,
		--   })
		-- =========================================================================
		-- =========================================================================
		-- SKILL SELECTOR (dropdown like AddSelector + number boxes).
		-- Pick the skill in the slide-in panel, set its Cooldown/Hold in
		-- the small boxes. Press the key (or :Trigger) to fire; cooldown
		-- is enforced per skill, early presses are ignored.
		--   Tab:AddSkillSelector({
		--     Title = "Skill",
		--     Skills = { { Key = "Z", Hold = 0.5, Cooldown = 3 } },
		--     Callback = function(key, hold) print(key, hold) end,
		--   })
		-- =========================================================================
		-- =========================================================================
		-- SKILL SELECTOR (plain selector look, opens the slide-in panel).
		-- Each panel row carries a small cooldown box. Press the key
		-- (or :Trigger) to fire; cooldown is enforced per skill.
		--   Tab:AddSkillSelector({
		--     Title = "Skill",
		--     Skills = { { Key = "Z", Hold = 0.5, Cooldown = 3 } },
		--     Callback = function(key, hold) print(key, hold) end,
		--   })
		-- =========================================================================
		function TabObject:AddSkillSelector(skillConfig)
			skillConfig = skillConfig or {}
			local callback = skillConfig.Callback or function() end
			local title = skillConfig.Title or "Skill"
			local skills = {}
			local order = {}
			for _, s in ipairs(skillConfig.Skills or {}) do
				if type(s) == "table" and s.Key then
					local kc = nil
					pcall(function() kc = Enum.KeyCode[tostring(s.Key)] end)
					local k = tostring(s.Key):upper()
					table.insert(skills, {
						Key = k,
						Code = kc,
						Hold = tonumber(s.Hold) or 0.5,
						Cooldown = tonumber(s.Cooldown) or 3,
						cdUntil = 0,
					})
					table.insert(order, k)
				end
			end
			if #skills == 0 then
				table.insert(skills, { Key = "Z", Code = Enum.KeyCode.Z, Hold = 0.5, Cooldown = 3, cdUntil = 0 })
				table.insert(order, "Z")
			end
			local selectedKey = skillConfig.Default or skills[1].Key
			local function findSkill(k)
				for _, st in ipairs(skills) do
					if st.Key == k then return st end
				end
				return skills[1]
			end

			local cardH = 68
			local SkillCard = Instance.new("Frame")
			SkillCard.Name = title .. "_SkillSelector"
			SkillCard.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			SkillCard.BorderSizePixel = 0

			local SkillCorner = Instance.new("UICorner")
			SkillCorner.CornerRadius = UDim.new(0, 12)
			SkillCorner.Parent = SkillCard

			local SkillStroke = Instance.new("UIStroke")
			SkillStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			SkillStroke.Thickness = 1.2
			SkillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			SkillStroke.Parent = SkillCard

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0, 12, 0, 8)
			TitleLabel.Size = UDim2.new(1, -24, 0, 16)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(TitleLabel, 12)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = SkillCard

			local ValueBox = Instance.new("TextButton")
			ValueBox.Name = "ValueBox"
			ValueBox.BackgroundColor3 = themeColorFor("32,32,36", CurrentThemeName or "Dark")
			ValueBox.BorderSizePixel = 0
			ValueBox.Position = UDim2.new(0, 12, 0, 28)
			ValueBox.Size = UDim2.new(1, -24, 0, 30)
			ValueBox.Text = ""
			ValueBox.AutoButtonColor = false
			ValueBox.Parent = SkillCard

			local ValueCorner = Instance.new("UICorner")
			ValueCorner.CornerRadius = UDim.new(0, 6)
			ValueCorner.Parent = ValueBox

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Position = UDim2.new(0, 10, 0, 0)
			ValueLabel.Size = UDim2.new(1, -40, 1, 0)
			ValueLabel.Font = Enum.Font.GothamBold
			ValueLabel.Text = ""
			ValueLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(ValueLabel, 12)
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			ValueLabel.Parent = ValueBox

			local DropIcon = Instance.new("ImageLabel")
			DropIcon.BackgroundTransparency = 1
			DropIcon.AnchorPoint = Vector2.new(1, 0.5)
			DropIcon.Position = UDim2.new(1, -10, 0.5, 0)
			DropIcon.Size = UDim2.new(0, 12, 0, 12)
			DropIcon.Image = Astral.Icons.down_arrow
			DropIcon.ImageColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
			DropIcon.ScaleType = Enum.ScaleType.Fit
			DropIcon.Parent = ValueBox

			local function refreshCard()
				local st = findSkill(selectedKey)
				pcall(function()
					ValueLabel.Text = st.Key .. "  ┬╖  " .. tostring(st.Cooldown) .. "s"
				end)
			end

			local function triggerSkill(st)
				if not st then return end
				if os.clock() < (st.cdUntil or 0) then return end
				st.cdUntil = os.clock() + (tonumber(st.Cooldown) or 0)
				task.spawn(callback, st.Key, st.Hold)
			end

			ValueBox.MouseButton1Click:Connect(function()
				if pickerOpen or selectorOpen then return end
				local boxes = {}
				for _, st in ipairs(skills) do
					local sk = st
					boxes[sk.Key] = {
						Get = function() return sk.Cooldown end,
						Set = function(t)
							local v = tonumber(t)
							if v then
								sk.Cooldown = math.max(0, v)
								refreshCard()
							end
						end,
					}
				end
				openSelector(title, order, selectedKey, false, function(pick)
					if pick ~= nil and tostring(pick) ~= "" and tostring(pick) ~= "None" then
						selectedKey = tostring(pick):upper()
						refreshCard()
					end
				end, ValueLabel, false, boxes)
			end)
			refreshCard()

			UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe then return end
				if pickerOpen or selectorOpen then return end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				for _, st in ipairs(skills) do
					if st.Code and input.KeyCode == st.Code then
						triggerSkill(st)
						break
					end
				end
			end)

			registerElement(SkillCard, cardH, skillConfig.Position)

			local SkillController = {}
			function SkillController:GetSkills()
				local out = {}
				for _, st in ipairs(skills) do
					out[st.Key] = { Hold = st.Hold, Cooldown = st.Cooldown }
				end
				return out
			end
			function SkillController:GetSelected()
				return selectedKey
			end
			function SkillController:SetSelected(key)
				for _, st in ipairs(skills) do
					if st.Key == tostring(key):upper() then
						selectedKey = st.Key
						refreshCard()
						return true
					end
				end
				return false
			end
			function SkillController:SetHold(key, v)
				for _, st in ipairs(skills) do
					if st.Key == tostring(key):upper() and tonumber(v) then
						st.Hold = math.clamp(tonumber(v), 0.05, 30)
					end
				end
			end
			function SkillController:SetCooldown(key, v)
				for _, st in ipairs(skills) do
					if st.Key == tostring(key):upper() and tonumber(v) then
						st.Cooldown = math.max(0, tonumber(v))
						refreshCard()
					end
				end
			end
			function SkillController:Trigger(key)
				for _, st in ipairs(skills) do
					if st.Key == tostring(key):upper() then triggerSkill(st) return end
				end
			end
			return SkillController
		end


		function TabObject:AddPlayerBrowser(config)
			config = config or {}
			local title = config.Title or "Players Section"
			local mode = (config.Mode == "Grid") and "Grid" or "Row"
			local showSearch = config.Search
			if showSearch == nil then showSearch = true end
			local callback = config.Callback or function() end
			local optionsCallback = config.OptionsCallback or function() end
			local PlayersSvc = game:GetService("Players")
			local LocalPlayer = PlayersSvc.LocalPlayer

			local GRID_H = 320
			local ROW_H = 280
			local cardH = (mode == "Row") and ROW_H or GRID_H

			local Card = Instance.new("Frame")
			Card.Name = title .. "_PlayerBrowser"
			Card.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			Card.BorderSizePixel = 0
			Card.Size = UDim2.new(1, 0, 0, cardH)
			Card.ClipsDescendants = true

			local CardCorner = Instance.new("UICorner")
			CardCorner.CornerRadius = UDim.new(0, 8)
			CardCorner.Parent = Card

			local CardStroke = Instance.new("UIStroke")
			CardStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			CardStroke.Thickness = 1
			CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			CardStroke.Parent = Card

			local Header = Instance.new("Frame")
			Header.Name = "Header"
			Header.BackgroundTransparency = 1
			Header.Size = UDim2.new(1, 0, 0, 68)
			Header.Parent = Card

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0, 12, 0, 4)
			TitleLabel.Size = UDim2.new(1, -56, 0, 24)
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(TitleLabel, 15)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Parent = Header

			local CountPill = Instance.new("Frame")
			CountPill.Name = "Count"
			CountPill.AnchorPoint = Vector2.new(1, 0)
			CountPill.Position = UDim2.new(1, -12, 0, 36)
			CountPill.Size = UDim2.new(0, 64, 0, 28)
			CountPill.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
			CountPill.BorderSizePixel = 0
			CountPill.Parent = Header

			local CountPillCorner = Instance.new("UICorner")
			CountPillCorner.CornerRadius = UDim.new(0, 8)
			CountPillCorner.Parent = CountPill

			local CountPillLabel = Instance.new("TextLabel")
			CountPillLabel.BackgroundTransparency = 1
			CountPillLabel.Size = UDim2.new(1, 0, 1, 0)
			CountPillLabel.Font = Enum.Font.GothamBold
			CountPillLabel.Text = "0 / 0"
			CountPillLabel.TextColor3 = themeColorFor("200,200,208", CurrentThemeName or "Dark")
			mTS(CountPillLabel, 11)
			CountPillLabel.Parent = CountPill

			local SearchBox = Instance.new("TextBox")
			SearchBox.Name = "SearchBox"
			SearchBox.AnchorPoint = Vector2.new(0, 0)
			SearchBox.Position = UDim2.new(0, 12, 0, 36)
			SearchBox.Size = UDim2.new(1, -96, 0, 28)
			SearchBox.BackgroundColor3 = themeColorFor("18,18,22", CurrentThemeName or "Dark")
			SearchBox.BorderSizePixel = 0
			SearchBox.Font = Enum.Font.Gotham
			SearchBox.Text = ""
			SearchBox.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(SearchBox, 12)
			SearchBox.TextXAlignment = Enum.TextXAlignment.Left
			SearchBox.ClearTextOnFocus = false
			SearchBox.Visible = showSearch
			SearchBox.Parent = Header
			tr(SearchBox, "Search players...", "PlaceholderText")
			SearchBox.PlaceholderColor3 = themeColorFor("120,120,125", CurrentThemeName or "Dark")

			local SearchBoxCorner = Instance.new("UICorner")
			SearchBoxCorner.CornerRadius = UDim.new(0, 4)
			SearchBoxCorner.Parent = SearchBox

			local SearchBoxStroke = Instance.new("UIStroke")
			SearchBoxStroke.Color = themeColorFor("55,55,65", CurrentThemeName or "Dark")
			SearchBoxStroke.Thickness = 1
			SearchBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			SearchBoxStroke.Parent = SearchBox

			local SearchPad = Instance.new("UIPadding")
			SearchPad.PaddingLeft = UDim.new(0, 10)
			SearchPad.PaddingRight = UDim.new(0, 8)
			SearchPad.Parent = SearchBox
			SearchBox.Focused:Connect(function()
				TweenService:Create(SearchBoxStroke, TweenInfo.new(0.15), { Color = themeColorFor("95,95,110", CurrentThemeName or "Dark") }):Play()
			end)
			SearchBox.FocusLost:Connect(function()
				TweenService:Create(SearchBoxStroke, TweenInfo.new(0.15), { Color = themeColorFor("55,55,65", CurrentThemeName or "Dark") }):Play()
			end)

			local ViewBtn = Instance.new("TextButton")
			ViewBtn.Name = "ViewToggle"
			ViewBtn.AnchorPoint = Vector2.new(1, 0)
			ViewBtn.Position = UDim2.new(1, -10, 0, 5)
			ViewBtn.Size = UDim2.new(0, 26, 0, 26)
			ViewBtn.BackgroundColor3 = AccentColor
			ViewBtn.BorderSizePixel = 0
			ViewBtn.Text = ""
			ViewBtn.AutoButtonColor = false
			ViewBtn.Parent = Header
			onAccentChange(function(c) pcall(function() ViewBtn.BackgroundColor3 = c end) end)

			local ViewBtnCorner = Instance.new("UICorner")
			ViewBtnCorner.CornerRadius = UDim.new(0, 6)
			ViewBtnCorner.Parent = ViewBtn

			local gridGlyph = Instance.new("Frame")
			gridGlyph.Name = "GridGlyph"
			gridGlyph.BackgroundTransparency = 1
			gridGlyph.Size = UDim2.new(1, 0, 1, 0)
			gridGlyph.Parent = ViewBtn
			gridGlyph.Visible = (mode == "Grid")
			for r = 0, 1 do
				for c = 0, 1 do
					local sq = Instance.new("Frame")
					sq.Size = UDim2.new(0, 6, 0, 6)
					sq.Position = UDim2.new(0, 6 + c * 8, 0, 6 + r * 8)
					sq.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
					sq.BorderSizePixel = 0
					sq.Parent = gridGlyph
					local sqc = Instance.new("UICorner")
					sqc.CornerRadius = UDim.new(0, 2)
					sqc.Parent = sq
				end
			end
			local rowGlyph = Instance.new("Frame")
			rowGlyph.Name = "RowGlyph"
			rowGlyph.BackgroundTransparency = 1
			rowGlyph.Size = UDim2.new(1, 0, 1, 0)
			rowGlyph.Visible = (mode == "Row")
			rowGlyph.Parent = ViewBtn
			for r = 0, 2 do
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 16, 0, 3)
				bar.Position = UDim2.new(0.5, -8, 0, 5 + r * 7)
				bar.BackgroundColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
				bar.BorderSizePixel = 0
				bar.Parent = rowGlyph
				local barc = Instance.new("UICorner")
				barc.CornerRadius = UDim.new(0, 1)
				barc.Parent = bar
			end

			local GridScroll = Instance.new("ScrollingFrame")
			GridScroll.Name = "Grid"
			GridScroll.BackgroundTransparency = 1
			GridScroll.BorderSizePixel = 0
			GridScroll.Position = UDim2.new(0, 0, 0, 76)
			GridScroll.Size = UDim2.new(1, 0, 1, -84)
			GridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			GridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			GridScroll.ScrollBarThickness = 3
			GridScroll.ScrollBarImageColor3 = themeColorFor("80,80,90", CurrentThemeName or "Dark")
			GridScroll.ScrollBarImageTransparency = 0.4
			GridScroll.Parent = Card

			local GridPad = Instance.new("UIPadding")
			GridPad.PaddingLeft = UDim.new(0, 10)
			GridPad.PaddingRight = UDim.new(0, 10)
			GridPad.PaddingTop = UDim.new(0, 4)
			GridPad.PaddingBottom = UDim.new(0, 8)
			GridPad.Parent = GridScroll

			local GridLayout = Instance.new("UIGridLayout")
			GridLayout.CellSize = UDim2.new(1 / (IsMobile and 2 or 3), -10, 0, 106)
			GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
			GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
			GridLayout.Parent = GridScroll

			local RowScroll = Instance.new("ScrollingFrame")
			RowScroll.Name = "Row"
			RowScroll.BackgroundTransparency = 1
			RowScroll.BorderSizePixel = 0
			RowScroll.Position = UDim2.new(0, 0, 0, 76)
			RowScroll.Size = UDim2.new(1, 0, 1, -84)
			RowScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			RowScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			RowScroll.ScrollingDirection = Enum.ScrollingDirection.Y
			RowScroll.ScrollBarThickness = 3
			RowScroll.ScrollBarImageColor3 = themeColorFor("80,80,90", CurrentThemeName or "Dark")
			RowScroll.ScrollBarImageTransparency = 0.4
			RowScroll.Visible = false
			RowScroll.Parent = Card

			local RowPad = Instance.new("UIPadding")
			RowPad.PaddingLeft = UDim.new(0, 10)
			RowPad.PaddingRight = UDim.new(0, 10)
			RowPad.PaddingTop = UDim.new(0, 4)
			RowPad.PaddingBottom = UDim.new(0, 4)
			RowPad.Parent = RowScroll

			local RowLayout = Instance.new("UIListLayout")
			RowLayout.FillDirection = Enum.FillDirection.Vertical
			RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			RowLayout.Padding = UDim.new(0, 8)
			RowLayout.Parent = RowScroll

			local selectedPlayer = LocalPlayer
			local multiSelect = (config.Multi == true)
			local selectedSet = {}
			local SEL_BG = themeColorFor("38,38,50", CurrentThemeName or "Dark")
			local cardRefs = {}
			local populate
			local PlayerBrowserController

			local function isOn(uid)
				if multiSelect then return selectedSet[uid] ~= nil end
				return selectedPlayer ~= nil and uid == selectedPlayer.UserId
			end

			local function paintSelected()
				for uid, refs in pairs(cardRefs) do
					local on = isOn(uid)
					local th = CurrentThemeName or "Dark"
					pcall(function()
						refs.Stroke.Color = on and AccentColor or themeColorFor("50,50,55", th)
						refs.Stroke.Transparency = on and 0 or 0.3
						refs.Stroke.Thickness = on and 3 or 2
						refs.Frame.BackgroundColor3 = on and themeColorFor("38,38,50", th) or themeColorFor("30,30,37", th)
						if refs.Halo then
							refs.Halo.BackgroundColor3 = AccentColor
							refs.Halo.BackgroundTransparency = on and 0.55 or 0.92
						end
					end)
				end
			end
			onAccentChange(function() pcall(paintSelected) end)

			local function setCardHeight(h)
				cardH = h
				Card.Size = UDim2.new(1, 0, 0, h)
				for _, el in ipairs(elements) do
					if el.Frame == Card then el.Height = h; break end
				end
				distributeElements()
				updateCanvas()
			end

			local function currentQuery()
				local t = ""
				pcall(function() t = SearchBox.Text or "" end)
				t = string.match(t, "^%s*(.-)%s*$") or ""
				return string.lower(t)
			end

			local thumbCache = {}
			local function makeAvatarThumb(imgLabel, player)
				local uid = nil
				pcall(function() uid = player.UserId end)
				if uid and thumbCache[uid] then
					local cached = thumbCache[uid]
					pcall(function() imgLabel.Image = cached end)
					return
				end
				task.spawn(function()
					local ok, img = pcall(function()
						return PlayersSvc:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					end)
					if ok and type(img) == "string" and img ~= "" then
						if uid then thumbCache[uid] = img end
						pcall(function() imgLabel.Image = img end)
					else
						task.wait(2)
						local ok2, img2 = pcall(function()
							return PlayersSvc:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
						end)
						if ok2 and type(img2) == "string" and img2 ~= "" then
							if uid then thumbCache[uid] = img2 end
							pcall(function() imgLabel.Image = img2 end)
						end
					end
				end)
			end

			local function clearHolder(holder)
				for _, c in ipairs(holder:GetChildren()) do
					if c:IsA("GuiObject") and not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
						pcall(function() c:Destroy() end)
					end
				end
			end

			local function buildGridCard(plr, idx)
				local uname = ""
				local dname = ""
				pcall(function() uname = tostring(plr.Name or "") end)
				pcall(function() dname = tostring(plr.DisplayName or "") end)
			if dname == "" then dname = uname end

			local cell = Instance.new("TextButton")
				cell.Name = "Player_" .. uname
				cell.BackgroundColor3 = themeColorFor("30,30,37", CurrentThemeName or "Dark")
				cell.BorderSizePixel = 0
				cell.Text = ""
				cell.AutoButtonColor = false
				cell.LayoutOrder = idx
				cell.Parent = GridScroll

			local cellCorner = Instance.new("UICorner")
			cellCorner.CornerRadius = UDim.new(0, 14)
			cellCorner.Parent = cell

			local cellStroke = Instance.new("UIStroke")
			cellStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			cellStroke.Transparency = 0.3
			cellStroke.Thickness = 2
				cellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				cellStroke.Parent = cell

			-- (per-player options button removed; use row click + Callback)

			local rank = Instance.new("TextLabel")
			rank.BackgroundTransparency = 1
			rank.Position = UDim2.new(0, 8, 0, 5)
			rank.Size = UDim2.new(0, 34, 0, 14)
			rank.Font = Enum.Font.GothamBold
			rank.Text = "#" .. tostring(idx)
			rank.TextColor3 = themeColorFor("120,120,130", CurrentThemeName or "Dark")
			mTS(rank, 10)
			rank.TextXAlignment = Enum.TextXAlignment.Left
			rank.Parent = cell

			local extraTxt = nil
			pcall(function()
				if config.Extra then extraTxt = config.Extra(plr) end
			end)
			if extraTxt ~= nil and tostring(extraTxt) ~= "" then
				local tag = Instance.new("TextLabel")
				tag.AnchorPoint = Vector2.new(1, 0)
				tag.Position = UDim2.new(1, -6, 0, 5)
				tag.Size = UDim2.new(0, 0, 0, 16)
				tag.AutomaticSize = Enum.AutomaticSize.X
				tag.BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark")
				tag.BorderSizePixel = 0
				tag.Font = Enum.Font.GothamBold
				tag.Text = "  " .. tostring(extraTxt) .. "  "
				tag.TextColor3 = themeColorFor("200,200,208", CurrentThemeName or "Dark")
				mTS(tag, 10)
				tag.Parent = cell
				local tagc = Instance.new("UICorner")
				tagc.CornerRadius = UDim.new(1, 0)
				tagc.Parent = tag
			end

			local av = Instance.new("ImageLabel")
			av.Name = "Avatar"
			av.AnchorPoint = Vector2.new(0.5, 0)
			av.Position = UDim2.new(0.5, 0, 0, 14)
			av.Size = UDim2.new(0, 48, 0, 48)
			av.BackgroundColor3 = themeColorFor("20,20,24", CurrentThemeName or "Dark")
			av.BorderSizePixel = 0
			av.ScaleType = Enum.ScaleType.Crop
			av.Parent = cell

			local avCorner = Instance.new("UICorner")
			avCorner.CornerRadius = UDim.new(1, 0)
			avCorner.Parent = av
			local avRing = Instance.new("UIStroke")
			avRing.Color = themeColorFor("70,70,80", CurrentThemeName or "Dark")
			avRing.Thickness = 1.5
			avRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			avRing.Parent = av
			local halo = Instance.new("Frame")
			halo.Name = "Halo"
			halo.AnchorPoint = Vector2.new(0.5, 0)
			halo.Position = UDim2.new(0.5, 0, 0, 9)
			halo.Size = UDim2.new(0, 58, 0, 58)
			halo.BackgroundColor3 = AccentColor
			halo.BackgroundTransparency = 0.92
			halo.BorderSizePixel = 0
			halo.ZIndex = -1
			halo.Parent = cell
			local haloCorner = Instance.new("UICorner")
			haloCorner.CornerRadius = UDim.new(1, 0)
			haloCorner.Parent = halo
			makeAvatarThumb(av, plr)

			local dn = Instance.new("TextLabel")
			dn.BackgroundTransparency = 1
			dn.Position = UDim2.new(0, 6, 0, 66)
			dn.Size = UDim2.new(1, -12, 0, 18)
			dn.Font = Enum.Font.GothamBold
			dn.Text = dname
			dn.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(dn, 13)
			dn.TextTruncate = Enum.TextTruncate.AtEnd
			dn.Parent = cell

			local un = Instance.new("TextLabel")
			un.BackgroundTransparency = 1
			un.Position = UDim2.new(0, 6, 0, 84)
			un.Size = UDim2.new(1, -12, 0, 15)
			un.Font = Enum.Font.Gotham
			un.Text = "@" .. uname
			un.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
			mTS(un, 11)
			un.TextTruncate = Enum.TextTruncate.AtEnd
			un.Parent = cell

			cell.MouseEnter:Connect(function()
				TweenService:Create(cell, TweenInfo.new(0.15), { BackgroundColor3 = themeColorFor("37,37,45", CurrentThemeName or "Dark") }):Play()
				TweenService:Create(cellStroke, TweenInfo.new(0.15), { Transparency = 0.15 }):Play()
			end)
			cell.MouseLeave:Connect(function()
				local on = isOn(plr.UserId)
				local th = CurrentThemeName or "Dark"
				TweenService:Create(cell, TweenInfo.new(0.2), { BackgroundColor3 = on and themeColorFor("38,38,50", th) or themeColorFor("30,30,37", th) }):Play()
				TweenService:Create(cellStroke, TweenInfo.new(0.2), { Transparency = on and 0 or 0.3 }):Play()
			end)

			local cellScale = Instance.new("UIScale")
			cellScale.Scale = 1
			cellScale.Parent = cell
			cardRefs[plr.UserId] = {Frame = cell, Stroke = cellStroke, Base = themeColorFor("30,30,37", CurrentThemeName or "Dark"), Scale = cellScale, Halo = halo}
				cell.MouseButton1Click:Connect(function()
					if multiSelect then
						if selectedSet[plr.UserId] then selectedSet[plr.UserId] = nil else selectedSet[plr.UserId] = plr end
					else
						if selectedPlayer == plr then selectedPlayer = nil else selectedPlayer = plr end
					end
					paintSelected()
					task.spawn(callback, plr)
					local sc = cardRefs[plr.UserId] and cardRefs[plr.UserId].Scale
					if sc then
						TweenService:Create(sc, TweenInfo.new(0.09), { Scale = 0.94 }):Play()
						task.delay(0.09, function()
							pcall(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
						end)
					end
				end)
			end

			local function buildRowChip(plr, idx)
				local uname = ""
				local dname = ""
				pcall(function() uname = tostring(plr.Name or "") end)
				pcall(function() dname = tostring(plr.DisplayName or "") end)
			if dname == "" then dname = uname end

			local chip = Instance.new("TextButton")
				chip.Name = "Player_" .. uname
			chip.BackgroundColor3 = themeColorFor("30,30,37", CurrentThemeName or "Dark")
			chip.BorderSizePixel = 0
			chip.Size = UDim2.new(1, 0, 0, 62)
				chip.Text = ""
				chip.AutoButtonColor = false
				chip.LayoutOrder = idx or 0
				chip.Parent = RowScroll

			local chipCorner = Instance.new("UICorner")
			chipCorner.CornerRadius = UDim.new(0, 12)
			chipCorner.Parent = chip

			local chipStroke = Instance.new("UIStroke")
			chipStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			chipStroke.Transparency = 0.3
			chipStroke.Thickness = 2
				chipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				chipStroke.Parent = chip

			local av = Instance.new("ImageLabel")
			av.AnchorPoint = Vector2.new(0, 0.5)
			av.Position = UDim2.new(0, 7, 0.5, 0)
			av.Size = UDim2.new(0, 32, 0, 32)
			av.BackgroundColor3 = themeColorFor("20,20,24", CurrentThemeName or "Dark")
			av.BorderSizePixel = 0
			av.ScaleType = Enum.ScaleType.Crop
			av.Parent = chip

			local avCorner = Instance.new("UICorner")
			avCorner.CornerRadius = UDim.new(1, 0)
			avCorner.Parent = av
			local avRing = Instance.new("UIStroke")
			avRing.Color = themeColorFor("70,70,80", CurrentThemeName or "Dark")
			avRing.Thickness = 1.5
			avRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			avRing.Parent = av
			local halo = Instance.new("Frame")
			halo.Name = "Halo"
			halo.AnchorPoint = Vector2.new(0, 0.5)
			halo.Position = UDim2.new(0, 3, 0.5, 0)
			halo.Size = UDim2.new(0, 40, 0, 40)
			halo.BackgroundColor3 = AccentColor
			halo.BackgroundTransparency = 0.92
			halo.BorderSizePixel = 0
			halo.ZIndex = -1
			halo.Parent = chip
			local haloCorner = Instance.new("UICorner")
			haloCorner.CornerRadius = UDim.new(1, 0)
			haloCorner.Parent = halo
			makeAvatarThumb(av, plr)

			local dn = Instance.new("TextLabel")
			dn.BackgroundTransparency = 1
			dn.Position = UDim2.new(0, 46, 0, 6)
			dn.Size = UDim2.new(1, -150, 0, 19)
			dn.Font = Enum.Font.GothamBold
			dn.Text = dname
			dn.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			mTS(dn, 13)
			dn.TextXAlignment = Enum.TextXAlignment.Left
			dn.TextTruncate = Enum.TextTruncate.AtEnd
			dn.Parent = chip

			local un = Instance.new("TextLabel")
			un.BackgroundTransparency = 1
			un.Position = UDim2.new(0, 46, 0, 25)
			un.Size = UDim2.new(1, -150, 0, 15)
			un.Font = Enum.Font.Gotham
			un.Text = "@" .. uname
			un.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
			mTS(un, 11)
			un.TextXAlignment = Enum.TextXAlignment.Left
			un.TextTruncate = Enum.TextTruncate.AtEnd
			un.Parent = chip

			local uidTxt = "ID --"
			pcall(function() uidTxt = "ID " .. tostring(plr.UserId or 0) end)
			local meta = Instance.new("TextLabel")
			meta.BackgroundTransparency = 1
			meta.Position = UDim2.new(0, 46, 0, 39)
			meta.Size = UDim2.new(1, -150, 0, 12)
			meta.Font = Enum.Font.Gotham
			meta.Text = uidTxt
			meta.TextColor3 = themeColorFor("120,120,130", CurrentThemeName or "Dark")
			mTS(meta, 9)
			meta.TextXAlignment = Enum.TextXAlignment.Left
			meta.TextTruncate = Enum.TextTruncate.AtEnd
			meta.Parent = chip

			-- (per-player options button removed; use row click + Callback)
			local rank = Instance.new("TextLabel")
			rank.BackgroundTransparency = 1
			rank.AnchorPoint = Vector2.new(1, 0.5)
			rank.Position = UDim2.new(1, -10, 0.5, 0)
			rank.Size = UDim2.new(0, 34, 0, 14)
			rank.Font = Enum.Font.GothamBold
			rank.Text = "#" .. tostring(idx or 0)
			rank.TextColor3 = themeColorFor("120,120,130", CurrentThemeName or "Dark")
			mTS(rank, 10)
			rank.TextXAlignment = Enum.TextXAlignment.Right
			rank.Parent = chip

			local extraTxt = nil
			pcall(function()
				if config.Extra then extraTxt = config.Extra(plr) end
			end)
			if extraTxt ~= nil and tostring(extraTxt) ~= "" then
				local tag = Instance.new("TextLabel")
				tag.AnchorPoint = Vector2.new(1, 0.5)
				tag.Position = UDim2.new(1, -50, 0.5, 0)
				tag.Size = UDim2.new(0, 0, 0, 18)
				tag.AutomaticSize = Enum.AutomaticSize.X
				tag.BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark")
				tag.BorderSizePixel = 0
				tag.Font = Enum.Font.GothamBold
				tag.Text = "  " .. tostring(extraTxt) .. "  "
				tag.TextColor3 = themeColorFor("200,200,208", CurrentThemeName or "Dark")
				mTS(tag, 10)
				tag.Parent = chip
				local tagc = Instance.new("UICorner")
				tagc.CornerRadius = UDim.new(1, 0)
				tagc.Parent = tag
			end
			chip.MouseEnter:Connect(function()
				TweenService:Create(chip, TweenInfo.new(0.15), { BackgroundColor3 = themeColorFor("37,37,45", CurrentThemeName or "Dark") }):Play()
				TweenService:Create(chipStroke, TweenInfo.new(0.15), { Transparency = 0.15 }):Play()
			end)
			chip.MouseLeave:Connect(function()
				local on = isOn(plr.UserId)
				local th = CurrentThemeName or "Dark"
				TweenService:Create(chip, TweenInfo.new(0.2), { BackgroundColor3 = on and themeColorFor("38,38,50", th) or themeColorFor("30,30,37", th) }):Play()
				TweenService:Create(chipStroke, TweenInfo.new(0.2), { Transparency = on and 0 or 0.3 }):Play()
			end)

			local chipScale = Instance.new("UIScale")
			chipScale.Scale = 1
			chipScale.Parent = chip
			cardRefs[plr.UserId] = {Frame = chip, Stroke = chipStroke, Base = themeColorFor("30,30,37", CurrentThemeName or "Dark"), Scale = chipScale, Halo = halo}
				chip.MouseButton1Click:Connect(function()
					if multiSelect then
						if selectedSet[plr.UserId] then selectedSet[plr.UserId] = nil else selectedSet[plr.UserId] = plr end
					else
						if selectedPlayer == plr then selectedPlayer = nil else selectedPlayer = plr end
					end
					paintSelected()
					task.spawn(callback, plr)
					local sc = cardRefs[plr.UserId] and cardRefs[plr.UserId].Scale
					if sc then
						TweenService:Create(sc, TweenInfo.new(0.09), { Scale = 0.96 }):Play()
						task.delay(0.09, function()
							pcall(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
						end)
					end
				end)
			end

			local EmptyLabel = Instance.new("TextLabel")
			EmptyLabel.Name = "EmptyState"
			EmptyLabel.BackgroundTransparency = 1
			EmptyLabel.Position = UDim2.new(0, 12, 0, 90)
			EmptyLabel.Size = UDim2.new(1, -24, 0, 30)
			EmptyLabel.Font = Enum.Font.Gotham
			tr(EmptyLabel, "No players found")
			EmptyLabel.TextColor3 = themeColorFor("150,150,160", CurrentThemeName or "Dark")
			mTS(EmptyLabel, 12)
			EmptyLabel.Visible = false
			EmptyLabel.Parent = Card

			populate = function()
				if not Card.Parent then return end
				local all = {}
				pcall(function() all = PlayersSvc:GetPlayers() end)
				table.sort(all, function(a, b)
					if a == LocalPlayer then return true end
					if b == LocalPlayer then return false end
					return string.lower(tostring(a.Name)) < string.lower(tostring(b.Name))
				end)
				local q = currentQuery()
				pcall(function()
					CountPillLabel.Text = tostring(#all) .. " / " .. tostring(PlayersSvc.MaxPlayers)
				end)
				clearHolder(GridScroll)
				clearHolder(RowScroll)
				cardRefs = {}
				local shown = 0
				for idx, plr in ipairs(all) do
					local dn = ""
					local un = ""
					pcall(function() dn = string.lower(tostring(plr.DisplayName or "")) end)
					pcall(function() un = string.lower("@" .. tostring(plr.Name or "")) end)
					if q == "" or string.find(dn, q, 1, true) or string.find(un, q, 1, true) then
						shown = shown + 1
						if mode == "Grid" then
							buildGridCard(plr, idx)
						else
							buildRowChip(plr, idx)
						end
					end
				end
				GridScroll.Visible = (mode == "Grid")
				RowScroll.Visible = (mode == "Row")
				paintSelected()
				pcall(function() EmptyLabel.Visible = (shown == 0) end)
			end

			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				if SearchBox:GetAttribute("SearchDeb") then return end
				SearchBox:SetAttribute("SearchDeb", true)
				task.delay(0.3, function()
					pcall(function() SearchBox:SetAttribute("SearchDeb", nil) end)
					pcall(populate)
				end)
			end)

			ViewBtn.MouseButton1Click:Connect(function()
				if mode == "Grid" then
					PlayerBrowserController:SetMode("Row")
				else
					PlayerBrowserController:SetMode("Grid")
				end
			end)

			pcall(function()
				PlayersSvc.PlayerAdded:Connect(function()
					task.delay(0.5, function() pcall(populate) end)
				end)
			end)
			pcall(function()
				PlayersSvc.PlayerRemoving:Connect(function()
					task.delay(0.5, function() pcall(populate) end)
				end)
			end)

			local function setCardHeight(h)
				cardH = h
				Card.Size = UDim2.new(1, 0, 0, h)
				for _, el in ipairs(elements) do
					if el.Frame == Card then el.Height = h; break end
				end
				distributeElements()
				updateCanvas()
			end

			registerElement(Card, cardH, config.Position)

			PlayerBrowserController = {}
			function PlayerBrowserController:Refresh()
				populate()
			end
			function PlayerBrowserController:SetMode(m)
				if m ~= "Grid" and m ~= "Row" then return end
				mode = m
				gridGlyph.Visible = (m == "Grid")
				rowGlyph.Visible = (m == "Row")
				setCardHeight((m == "Row") and ROW_H or GRID_H)
				populate()
			end
			function PlayerBrowserController:GetSelected()
				if multiSelect then
					local list = {}
					for _, p in pairs(selectedSet) do table.insert(list, p) end
					return list
				end
				return selectedPlayer
			end
			function PlayerBrowserController:ClearSelected()
				selectedPlayer = nil
				selectedSet = {}
				paintSelected()
			end
			local lastIds = ""
			local function idsNow()
				local ids = {}
				pcall(function()
					for _, p in ipairs(PlayersSvc:GetPlayers()) do
						table.insert(ids, tostring(p.UserId))
					end
				end)
				table.sort(ids)
				return table.concat(ids, ",")
			end
			lastIds = idsNow()
			task.spawn(function()
				while task.wait(5) do
					if not Card.Parent then return end
					local cur = idsNow()
					if cur ~= lastIds then
						lastIds = cur
						pcall(populate)
					end
				end
			end)
			populate()
			return PlayerBrowserController
		end
		TabObject.Addplayerbrowser = TabObject.AddPlayerBrowser

		-- Fault tolerance: one bad element can never kill the whole UI build.
		-- Any failing Add* call is skipped and reported instead of aborting.
		do
			local addNames = {"AddButton", "AddToggle", "AddTick", "AddSlider", "AddTextbox",
				"AddSelector", "AddColorpicker", "AddLabel", "AddParagraph", "AddKeybind", "AddDiscordCard", "AddMultiButton", "AddMultiColorPicker", "AddPlayerBrowser"}
			for _, addName in ipairs(addNames) do
				local orig = TabObject[addName]
				if type(orig) == "function" then
					TabObject[addName] = function(self, ...)
						local ok, res = pcall(orig, self, ...)
						if not ok then
							warn("[Astral] " .. addName .. " failed: " .. tostring(res))
							return nil
						end
						return res
					end
				end
			end
		end

		-- if a non-dark theme is active, theme the new tab too (idempotent)


		function TabObject:AddSubTab(stCfg)
			local stName = "SubTab"
			local stIcon = nil
			if type(stCfg) == "table" then
				stName = stCfg[1] or stCfg.Name or "SubTab"
				stIcon = parseIcon(stCfg[2] or stCfg.Icon)
			elseif type(stCfg) == "string" then
				stName = stCfg
			end

			-- Θªûµ¼íΦ░âτö¿µëìµÿ╛τñ║ sub-tab µáÅ∩╝îσÄƒ PageScroll Σ╕ïτº╗Φ«⌐Σ╜ì
			if not subTabBarShown then
				subTabBarShown = true
			SubTabBar.Visible = true
			PageScroll.Position = UDim2.new(0, 0, 0, SubTabBarHeight + 6)
			PageScroll.Size = UDim2.new(1, 0, 1, -(SubTabBarHeight + 6))
			end

			local stIdx = #subTabs + 1

			local StBtn = Instance.new("TextButton")
			StBtn.Name = stName .. "_SubTabBtn"
			StBtn.BackgroundColor3 = themeColorFor("32,32,40", CurrentThemeName or "Dark")
			StBtn.BackgroundTransparency = 0
			StBtn.BorderSizePixel = 0
			StBtn.Size = UDim2.new(0, 0, 0, SubTabBtnHeight)
			StBtn.AutomaticSize = Enum.AutomaticSize.X
			StBtn.AutoButtonColor = false
			StBtn.Text = ""
			StBtn.ClipsDescendants = true
			StBtn.LayoutOrder = stIdx
			StBtn.ZIndex = 7
			StBtn.Parent = SubTabScroll

			local StBtnCorner = Instance.new("UICorner")
			StBtnCorner.CornerRadius = UDim.new(0, 8)
			StBtnCorner.Parent = StBtn

			local StBtnStroke = Instance.new("UIStroke")
			StBtnStroke.Color = themeColorFor("70,70,80", CurrentThemeName or "Dark")
			StBtnStroke.Thickness = 1
			StBtnStroke.Transparency = 0.5
			StBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			StBtnStroke.Parent = StBtn

			local StBtnLayout = Instance.new("UIListLayout")
			StBtnLayout.FillDirection = Enum.FillDirection.Horizontal
			StBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			StBtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
			StBtnLayout.Padding = UDim.new(0, 8)
			StBtnLayout.Parent = StBtn

			local StBtnPad = Instance.new("UIPadding")
			StBtnPad.PaddingLeft = UDim.new(0, 14)
			StBtnPad.PaddingRight = UDim.new(0, 14)
			StBtnPad.Parent = StBtn

			if stIcon then
				local StBtnIco = Instance.new("ImageLabel")
				StBtnIco.BackgroundTransparency = 1
				StBtnIco.Size = UDim2.fromOffset(IsMobile and 16 or 18, IsMobile and 16 or 18)
				StBtnIco.LayoutOrder = 1
				StBtnIco.ZIndex = 8
				Astral.ApplyIcon(StBtnIco, stIcon)
				StBtnIco.ImageColor3 = themeColorFor("160,160,168", CurrentThemeName or "Dark")
				StBtnIco.Parent = StBtn
			end

			local StBtnText = Instance.new("TextLabel")
			StBtnText.Name = "SubTabText"
			StBtnText.BackgroundTransparency = 1
			StBtnText.Size = UDim2.new(0, 0, 1, 0)
			StBtnText.AutomaticSize = Enum.AutomaticSize.X
			StBtnText.Font = Enum.Font.GothamBold
			tr(StBtnText, stName)
			StBtnText.TextColor3 = themeColorFor("160,160,168", CurrentThemeName or "Dark")
			mTS(StBtnText, 15)
			StBtnText.TextXAlignment = Enum.TextXAlignment.Center
			StBtnText.TextYAlignment = Enum.TextYAlignment.Center
			StBtnText.TextTruncate = Enum.TextTruncate.None
			StBtnText.LayoutOrder = 2
			StBtnText.ZIndex = 8
			StBtnText.Parent = StBtn

			local stData = {Button = StBtn, BStroke = StBtnStroke, BText = StBtnText, Index = stIdx}
			table.insert(subTabs, stData)

			StBtn.MouseEnter:Connect(function()
				if currentSubTab ~= stIdx then
					TweenService:Create(StBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.55}):Play()
					TweenService:Create(StBtnText, TweenInfo.new(0.15), {TextColor3 = themeColorFor("220,220,228", CurrentThemeName or "Dark")}):Play()
				end
			end)
			StBtn.MouseLeave:Connect(function()
				if currentSubTab ~= stIdx then
					TweenService:Create(StBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
					TweenService:Create(StBtnText, TweenInfo.new(0.15), {TextColor3 = themeColorFor("160,160,168", CurrentThemeName or "Dark")}):Play()
				end
			end)
			StBtn.MouseButton1Click:Connect(function()
				switchSubTab(stIdx)
			end)

			if stIdx == 1 then switchSubTab(stIdx) end

			-- Σ╗úτÉå∩╝ÜσÇƒτö¿ TabObject τÜäσà¿Θâ¿ AddXxx∩╝îµ│¿σåîµ£ƒΘù┤µèè currentBuildSubTab µîçσÉæµ£¼ sub-tab
			local proxy = {Name = stName, Index = stIdx}
			return setmetatable(proxy, {
				__index = function(_, key)
					local fn = TabObject[key]
					if type(fn) == "function" then
						return function(_, ...)
							local prev = currentBuildSubTab
							currentBuildSubTab = stIdx
							local ok, res = pcall(fn, TabObject, ...)
							currentBuildSubTab = prev
							if not ok then
								warn("[Astral] SubTab " .. stName .. ":" .. tostring(key) .. " failed: " .. tostring(res))
							end
							return res
						end
					end
					return fn
				end
			})
		end
		TabObject.Addsubtab = TabObject.AddSubTab

		return TabObject
	end

	-- =========================================================================
	-- FIXED FEATURE: SEPARATED, ENLARGED, INDEPENDENTLY DRAGGABLE LOGO BUTTON
	-- =========================================================================

	-- LOGO TOGGLE BUTTON (Completely Independent ScreenGui Element)
	-- Smaller footprint (was oversized), slightly bigger on mobile for touch
	local logoSize = IsMobile and 54 or 72
	-- Default logo, change per window with Logo = "rbxassetid://..." in CreateWindow config
	local logoAsset = config.Logo or "rbxassetid://134909842242325"
	local LogoButton = Instance.new("TextButton")
	LogoButton.Name = "LogoButton"
	LogoButton.Size = UDim2.new(0, logoSize, 0, logoSize)
	
	-- Apply Responsive Position for Logo Button
	if IsMobile then
		LogoButton.Position = UDim2.new(0.05, -2, 0.32, -90)
	else
		LogoButton.Position = UDim2.new(0.05, -2, 0.32, -90)
	end
	defaultLogoPos = LogoButton.Position
	
	LogoButton.BackgroundColor3 = themeColorFor("15,15,15", CurrentThemeName or "Dark") -- Dark black base matching image reference
	LogoButton.BorderSizePixel = 0
	LogoButton.Text = ""
	LogoButton.AutoButtonColor = false
	LogoButton.Active = true
	LogoButton.ClipsDescendants = true -- FIXED: Clips any overflowing square elements perfectly
	LogoButton.ZIndex = 101
	LogoButton.Parent = ScreenGui

	local LogoCorner = Instance.new("UICorner")
	LogoCorner.CornerRadius = UDim.new(1, 0) -- Perfect Circle
	LogoCorner.Parent = LogoButton

	local LogoStroke = Instance.new("UIStroke")
	LogoStroke.Color = themeColorFor("58,58,66", CurrentThemeName or "Dark") -- Neutral ring (no accent)
	LogoStroke.Thickness = 1.5
	LogoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	LogoStroke.Parent = LogoButton

	-- Logo Icon (Sized perfectly to fit snugly inside the button)
	local LogoIcon = Instance.new("ImageLabel")
	LogoIcon.Name = "LogoIcon"
	LogoIcon.BackgroundTransparency = 1
	LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	LogoIcon.Size = UDim2.new(1, -6, 1, -6) -- FIXED: Sized to sit perfectly inside the green border stroke
		LogoIcon.Image = logoAsset
	LogoIcon.ScaleType = Enum.ScaleType.Crop -- FIXED: Crop to fill circular frame perfectly without stretching
	LogoIcon.ZIndex = 103
	LogoIcon.Parent = LogoButton

	local LogoIconCorner = Instance.new("UICorner") -- FIXED: Rounds the square image asset itself into a perfect circle
	LogoIconCorner.CornerRadius = UDim.new(1, 0)
	LogoIconCorner.Parent = LogoIcon

	-- Logo Button Drop Shadow Frame
	local LogoShadow = Instance.new("Frame")
	LogoShadow.Name = "LogoShadow"
	LogoShadow.Size = LogoButton.Size
	LogoShadow.Position = LogoButton.Position + UDim2.new(0, 2, 0, 2)
	LogoShadow.BackgroundColor3 = themeColorFor("0,0,0", CurrentThemeName or "Dark")
	LogoShadow.BackgroundTransparency = 0.4
	LogoShadow.ZIndex = 100
	LogoShadow.Parent = ScreenGui

	local LogoShadowCorner = Instance.new("UICorner")
	LogoShadowCorner.CornerRadius = UDim.new(1, 0)
	LogoShadowCorner.Parent = LogoShadow

	-- Sync Shadow Position with Dragging
	LogoButton:GetPropertyChangedSignal("Position"):Connect(function()
		LogoShadow.Position = LogoButton.Position + UDim2.new(0, 2, 0, 2)
	end)

	-- Apply Lag-Free Dragging to the logo button
	makeElementDraggable(LogoButton)

	-- Logo Button Click Action (Toggles Main UI Visibility)
	local uiVisible = true
	registerClick(LogoButton, function()
		uiVisible = not uiVisible
		MainFrame.Visible = uiVisible
		
		-- Smooth pop animation for the logo button
		TweenService:Create(LogoButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = uiVisible and UDim2.new(0, logoSize, 0, logoSize) or UDim2.new(0, logoSize - 10, 0, logoSize - 10)
		}):Play()
		TweenService:Create(LogoShadow, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = uiVisible and UDim2.new(0, logoSize, 0, logoSize) or UDim2.new(0, logoSize - 10, 0, logoSize - 10)
		}):Play()
	end)

	-- Stop Farm Callback Registry
	Astral.OnStopFarm = function()
		print("[Astral]: Stop Farm triggered! Resetting all features...")
		for _, controller in ipairs(Astral.Registry) do
			pcall(function()
				controller:Set(false)
			end)
		end
	end

	function Window:SetBackground(urlOrId)
		if type(urlOrId) ~= "string" or urlOrId == "" then return end
		if urlOrId:match("^https?://") then
			BackgroundImage.Image = bgFunc(urlOrId)
			BackgroundImage.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		else
			BackgroundImage.Image = urlOrId
			BackgroundImage.ImageColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		end
		if BgDim.BackgroundTransparency >= 1 then
			BgDim.BackgroundTransparency = 0.25
		end
	end
	-- alias kept for old scripts: downloads the URL then applies it
	function Window:LoadBackgroundFromUrl(url)
		return Window:SetBackground(url)
	end
	function Window:SetBackgroundDim(transparency)
		local t = tonumber(transparency)
		if not t then return end
		BgDim.BackgroundTransparency = math.clamp(t, 0, 1)
	end
	function Window:SetStatusScale(s)
		s = math.clamp(tonumber(s) or 1, 0.7, 1.3)
		for _, p in ipairs(statusPanels) do
			pcall(function()
				if p.Scale then p.Scale.Scale = s end
			end)
		end
	end
	-- Floating circular STOP button (lives outside the window, draggable).
	-- Turns the given toggles off (needs their :Set) then fires Callback.
	--   local stop = Window:AddStopButton({ Text = "STOP", ToggleList = { myToggle }, Callback = function() end })
	function Window:AddStopButton(cfg)
		cfg = cfg or {}
		local text = cfg.Text or "Stop Farm"
		local toggles = cfg.ToggleList or {}
		local cb = cfg.Callback or function() end
		local hasCb = cfg.Callback ~= nil
		local SZ = 72
		local btn = Instance.new("TextButton")
		btn.Name = "StopButton"
		btn.Size = UDim2.new(0, SZ, 0, SZ)
		btn.Position = cfg.Position or UDim2.new(0.05, -2, 0.32, -8)
		btn.BackgroundColor3 = themeColorFor("15,15,15", CurrentThemeName or "Dark")
		btn.Font = Enum.Font.GothamBold
		btn.Text = tostring(text)
		btn.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		btn.TextSize = 13
		btn.TextWrapped = true
		btn.AutoButtonColor = false
		btn.Active = true
		btn.ZIndex = 450
		btn.Parent = ScreenGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = btn
		local ring = Instance.new("UIStroke")
		ring.Color = AccentColor
		ring.Thickness = 2
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Parent = btn
		onAccentChange(function(c) pcall(function() ring.Color = c end) end)
		local sc = Instance.new("UIScale")
		sc.Scale = 1
		sc.Parent = btn
		local dragging = false
		local dragStart, startPos = nil, nil
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = btn.Position
				TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 0.85 }):Play()
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local dx = input.Position.X - dragStart.X
				local dy = input.Position.Y - dragStart.Y
				btn.Position = clampPanelOnScreen(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy), SZ, SZ)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not dragging then return end
			local moved = false
			pcall(function()
				local d = input.Position - dragStart
				if math.abs(d.X) + math.abs(d.Y) > 8 then moved = true end
			end)
			dragging = false
			TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			if moved then return end
			for _, tg in ipairs(toggles) do
				pcall(function()
					if tg and tg.Set then tg:Set(false)
					elseif tg and tg.SetState then tg:SetState(false) end
				end)
			end
			if (not hasCb) and (#toggles == 0) then
				pcall(function()
					for _, item in ipairs(configFlags or {}) do
						if item.Kind == "toggle" or item.Kind == "tick" then
							pcall(item.Set, false)
						end
					end
				end)
			end
			task.spawn(cb)
		end)
		local StopController = {}
		function StopController:SetText(t) btn.Text = tostring(t) end
		function StopController:Destroy() pcall(function() btn:Destroy() end) end
		StopController.Button = btn
		return StopController
	end
	function Window:SetTransparency(t)
		t = math.clamp(tonumber(t) or 0, 0, 0.75)
		Window._TransparencyCurrent = t
		pcall(function() MainFrame.BackgroundTransparency = t end)
		pcall(function()
			Sidebar.BackgroundTransparency = math.clamp(0.12 + t, 0, 0.9)
			SidebarFillerTop.BackgroundTransparency = math.clamp(0.12 + t, 0, 0.9)
			SidebarFillerRight.BackgroundTransparency = math.clamp(0.12 + t, 0, 0.9)
		end)
		for _, rec in ipairs(Window._TransparencyTargets or {}) do
			pcall(function()
				if rec.Frame and rec.Frame.Parent then
					rec.Frame.BackgroundTransparency = math.clamp(rec.Base + t, 0, 0.9)
				end
			end)
		end
	end

	function Window:ResetBackground()
		BackgroundImage.Image = ""
		BackgroundImage.ImageColor3 = themeColorFor("58,58,64", CurrentThemeName or "Dark")
		BgDim.BackgroundTransparency = 1
	end
	-- Manual window size override (preview PC vs mobile sizes live)
	function Window:SetUIScale(p)
		p = math.clamp(tonumber(p) or 1, 0.7, 1.3)
		p = math.floor(p / 0.05 + 0.5) * 0.05
		Window._UIScalePending = p
		if Window._UIScaleBusy then return end
		Window._UIScaleBusy = true
		task.spawn(function()
			task.wait(0.3)
			local fp = Window._UIScalePending
			Window._UIScaleBusy = false
			if fp == nil then return end
			Window._UIScalePending = nil
			Window._BaseRefW = Window._BaseRefW or refW
			Window._BaseRefH = Window._BaseRefH or refH
			refW, refH = math.floor(Window._BaseRefW * fp), math.floor(Window._BaseRefH * fp)
			pcall(updateWindowSize)
		end)
	end
	function Window:PlayIntro()
		pcall(function()
			MainFrame.Size = UDim2.new(0, math.floor(refW * 0.7), 0, math.floor(refH * 0.7))
			TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, refW, 0, refH),
			}):Play()
		end)
	end
	if config.OpenAnimation ~= false then
		task.delay(0.05, function() pcall(function() Window:PlayIntro() end) end)
	end
	function Window:SetWindowSize(w, h)
		if type(w) == "number" and w >= 200 then refW = w end
		if type(h) == "number" and h >= 140 then refH = h end
		-- Close popups first so they re-open sized to the new window
		if closeSelector then closeSelector() end
		if pickerOpen then closeColorPicker() end
		updateWindowSize()
	end
	-- Diagnostic: prints tab + element counts (paste console output when reporting bugs)
	function Window:DebugInfo()
		print("[Astral] tabs built: " .. #tabs)
		for _, t in ipairs(tabs) do
			local n = 0
			if t.Elements then n = #t.Elements end
			local gui = 0
			if t.Page then gui = #t.Page:GetDescendants() end
			print("[Astral] tab '" .. tostring(t.Button and t.Button.Name) .. "' elements: " .. n .. " gui: " .. gui)
		end
	end
	-- Re-run column layout on every tab (fixes anything built while hidden)
	function Window:RefreshAll()
		for _, td in ipairs(tabs) do
			pcall(function()
				if td.Refresh then td.Refresh() end
			end)
		end
	end
	function Window:SetLayoutMode(mode)
		if mode ~= "OneColumn" and mode ~= "TwoColumn" then
			mode = "Auto"
		end
		layoutMode = mode
		local n, err0 = 0, nil
		for _, td in ipairs(tabs) do
			local ok, err = pcall(function()
				if td.Refresh then td.Refresh() end
			end)
			if ok then n = n + 1 else err0 = err end
		end
		if err0 then warn("[Astral] SetLayoutMode: " .. tostring(err0)) end
		task.delay(0.15, function()
			for _, td in ipairs(tabs) do
				local ok, err = pcall(function()
					if td.Refresh then td.Refresh() end
				end)
				if not ok then warn("[Astral] SetLayoutMode(2): " .. tostring(err)) end
			end
		end)
	end
	function Window:GetLayoutMode()
		return layoutMode
	end

	local CONFIG_FILE = "lumu_config.json"
	local function encodeValue(kind, v)
		if kind == "color" and typeof(v) == "Color3" then
			return {r = math.floor(v.R * 255), g = math.floor(v.G * 255), b = math.floor(v.B * 255)}
		elseif kind == "key" and typeof(v) == "EnumItem" then
			return v.Name
		end
		return v
	end
	local function decodeValue(kind, v)
		if kind == "color" and type(v) == "table" then
			return Color3.fromRGB(tonumber(v.r) or 255, tonumber(v.g) or 255, tonumber(v.b) or 255)
		elseif kind == "key" and type(v) == "string" then
			local ok, kc = pcall(function() return Enum.KeyCode[v] end)
			if ok and kc then return kc end
			return nil
		end
		return v
	end
	-- Save all Flagged element states to file (survives server hop: Load on next run)
	function Window:SaveConfig(name)
		local data = {}
		for _, item in ipairs(configFlags) do
			local ok, v = pcall(item.Get)
			if ok then
				data[item.Flag] = encodeValue(item.Kind, v)
			end
		end
		local ok, json = pcall(function()
			return game:GetService("HttpService"):JSONEncode(data)
		end)
		if ok and writefile then
			pcall(writefile, name or CONFIG_FILE, json)
			return true
		end
		return false
	end
	-- Load saved states back (call after building UI; fires each callback to resume)
	function Window:LoadConfig(name)
		if not (readfile and isfile) then return false end
		local fname = name or CONFIG_FILE
		local okExists = false
		pcall(function() okExists = isfile(fname) end)
		if not okExists then return false end
		local okRead, raw = pcall(readfile, fname)
		if not okRead or not raw or raw == "" then return false end
		local okJson, data = pcall(function()
			return game:GetService("HttpService"):JSONDecode(raw)
		end)
		if not okJson or type(data) ~= "table" then return false end
		for _, item in ipairs(configFlags) do
			if data[item.Flag] ~= nil then
				local v = decodeValue(item.Kind, data[item.Flag])
				if v ~= nil then
					pcall(item.Set, v)
				end
			end
		end
		return true
	end

	-- UI positions: save / load / reset (main window, logo button, status panels)
	function Window:SaveUIPositions(name)
		local data = {}
		pcall(function() data.main = udimToTable(MainFrame.Position) end)
		pcall(function() data.logo = udimToTable(LogoButton.Position) end)
		data.status = {}
		pcall(function()
			for _, p in ipairs(statusPanels) do
				if p.Panel and p.Panel.Parent then
					table.insert(data.status, udimToTable(p.Panel.Position))
				end
			end
		end)
		return saveUIPosFile(name, data)
	end

	function Window:LoadUIPositions(name)
		local data = loadUIPosFile(name)
		if not data then return false end
		pcall(function()
			local pos = tableToUdim(data.main)
			if pos then MainFrame.Position = clampPanelOnScreen(pos, 880, 600) end
		end)
		pcall(function()
			local pos = tableToUdim(data.logo)
			if pos then LogoButton.Position = pos end
		end)
		pcall(function()
			if type(data.status) == "table" then
				for i, p in ipairs(statusPanels) do
					local pos = tableToUdim(data.status[i])
					if pos and p.Panel then
						p.Panel.Position = clampPanelOnScreen(pos, 276, 220)
					end
				end
			end
		end)
		return true
	end

	function Window:ResetUIPositions(name)
		pcall(function()
			local fname = name or UIPOS_FILE
			if delfile and isfile and isfile(fname) then
				pcall(delfile, fname)
			elseif writefile then
				pcall(writefile, fname, "")
			end
		end)
		pcall(function() MainFrame.Position = defaultMainPos end)
		pcall(function() LogoButton.Position = defaultLogoPos end)
		pcall(function()
			for _, p in ipairs(statusPanels) do
				if p.Panel and p.DefaultPos then
					p.Panel.Position = p.DefaultPos
				end
			end
		end)
		return true
	end
	function Window:SetAccent(color)
		if typeof(color) ~= "Color3" then return end
		AccentColor = color
		for _, fn in ipairs(accentAppliers) do
			pcall(fn, color)
		end
		-- recolor tab strokes + logo ring (not registered, direct refs)
		for _, td in ipairs(tabs) do pcall(function() if td.Stroke then td.Stroke.Color = color end end) end
		pcall(function() end) -- ring stays neutral
		-- re-apply the ACTIVE tab pill with the new accent (solid pill style)
		for _, td in ipairs(tabs) do
			if td == currentTab then
				pcall(function() td.Button.BackgroundColor3 = color; td.Button.BackgroundTransparency = 0 end)
				pcall(function() td.Stroke.Color = color; td.Stroke.Transparency = 0 end)
				if td.Gradient then td.Gradient.Enabled = false end
			else
				pcall(function() td.Stroke.Color = themeColorFor("42,42,46", CurrentThemeName or "Dark") end)
			end
		end
	end

	function Window:SetTheme(name)
		local result = applyThemeToGui(ScreenGui, AccentColor, Window.ThemeName or "Dark", name)
		if result then
			Window.ThemeName = result
			CurrentThemeName = result
			local acc = THEME_ACCENT[result]
			if acc then Window:SetAccent(acc) end
			return true
		end
		return false
	end

	function Window:GetTheme()
		return Window.ThemeName or "Dark"
	end

	-- Custom theme: pick your own colours for the main parts.
	--   Window:SetCustomTheme({
	--     Background = Color3.fromRGB(20, 20, 26),
	--     Card = Color3.fromRGB(30, 30, 38),
	--     Text = Color3.fromRGB(255, 255, 255),
	--     SubText = Color3.fromRGB(170, 170, 180),
	--     Border = Color3.fromRGB(60, 60, 72),
	--     Accent = Color3.fromRGB(0, 153, 235),
	--   })
	function Window:SetCustomTheme(opts)
		opts = opts or {}
		local function pick(c, fallbackKey)
			if typeof(c) == "Color3" then
				return math.floor(c.R * 255 + 0.5) .. "," .. math.floor(c.G * 255 + 0.5) .. "," .. math.floor(c.B * 255 + 0.5)
			end
			return fallbackKey
		end
		local bg = pick(opts.Background, "12,12,14")
		local card = pick(opts.Card, "26,26,30")
		local text = pick(opts.Text, "255,255,255")
		local sub = pick(opts.SubText, "160,160,165")
		local border = pick(opts.Border, "50,50,55")

		if opts.Accent and typeof(opts.Accent) == "Color3" then
			Window:SetAccent(opts.Accent)
		end

		CustomThemeValues = {
			["12,12,14"] = bg, ["15,15,15"] = bg,
			["26,26,30"] = card, ["18,18,22"] = card, ["16,16,18"] = card,
			["20,20,24"] = card, ["22,22,26"] = card, ["30,30,36"] = card,
			["28,28,34"] = card, ["36,36,40"] = card, ["32,32,36"] = card,
			["35,35,40"] = border, ["45,45,50"] = border, ["50,50,55"] = border,
			["38,38,44"] = border, ["52,52,60"] = border, ["54,54,62"] = border,
			["70,70,75"] = border,
			["14,14,16"] = card, ["16,16,20"] = card, ["18,18,20"] = card,
			["20,20,25"] = card, ["20,20,26"] = card, ["24,24,29"] = card,
			["24,24,30"] = card, ["28,28,35"] = card, ["30,30,37"] = card,
			["30,30,38"] = card, ["32,32,34"] = card, ["32,32,40"] = card,
			["34,34,40"] = card, ["37,37,45"] = card, ["38,38,50"] = card,
			["40,40,46"] = card, ["40,40,48"] = card, ["40,40,50"] = card,
			["42,42,46"] = card, ["42,42,50"] = card,
			["45,45,52"] = border, ["48,48,58"] = border, ["52,52,56"] = border,
			["54,54,64"] = border, ["55,55,60"] = border, ["55,55,65"] = border,
			["58,58,64"] = border, ["58,58,66"] = border, ["60,60,70"] = border,
			["60,60,72"] = border, ["62,62,72"] = border, ["80,80,90"] = border,
			["255,255,255"] = text,
			["160,160,165"] = sub, ["150,150,158"] = sub, ["162,162,172"] = sub,
			["165,165,176"] = sub, ["175,175,182"] = sub, ["170,170,178"] = sub,
			["180,180,185"] = sub, ["120,120,125"] = sub, ["110,110,118"] = sub,
			["100,100,105"] = sub,
			["95,95,110"] = sub, ["120,120,130"] = sub, ["128,132,142"] = sub,
			["130,130,135"] = sub, ["140,140,145"] = sub, ["150,150,160"] = sub,
			["160,160,168"] = sub, ["170,170,180"] = sub, ["200,200,208"] = sub,
			["220,220,228"] = sub, ["232,232,237"] = sub, ["240,240,245"] = sub,
		}

		local result = applyThemeToGui(ScreenGui, AccentColor, Window.ThemeName or "Dark", "Custom")
		if result then
			Window.ThemeName = result
			CurrentThemeName = result
			return true
		end
		return false
	end
	
		-- ==========================================
		-- NOTIFICATION SYSTEM
		-- ==========================================
		local notifTypeColors = {
			good = {bg = themeColorFor("46,204,113", CurrentThemeName or "Dark")},
			warning = {bg = themeColorFor("255,212,0", CurrentThemeName or "Dark")},
			bad = {bg = themeColorFor("231,76,60", CurrentThemeName or "Dark")}
		}
		local notifTypeIcons = {
			good = Astral.Icons.Checkmark,
			warning = Astral.Icons.Warning,
			bad = Astral.Icons.Close
		}

		function Window:Notify(config)
			config = config or {}
			local nType = config.Type or "good"
			local title = tostring(config.Title or "")
			local message = tostring(config.Message or "")
			local duration = tonumber(config.Duration) or 10
			if duration <= 0 then duration = 1 end
			local actions = config.Actions or {}
			local hasActions = #actions > 0
			local tColor = notifTypeColors[nType] or notifTypeColors.good
			local tIcon = notifTypeIcons[nType] or notifTypeIcons.good
			local notifH = (IsMobile and (hasActions and 90 or 56) or (hasActions and 88 or 62))

			-- type colour drives the whole card so good/warning/bad read instantly
			local tc = tColor.bg
			local function mix(base, color, amount)
				return Color3.fromRGB(
					math.floor(base.R * 255 * (1 - amount) + color.R * 255 * amount),
					math.floor(base.G * 255 * (1 - amount) + color.G * 255 * amount),
					math.floor(base.B * 255 * (1 - amount) + color.B * 255 * amount)
				)
			end

			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(0, notifW, 0, notifH)
			Frame.BackgroundColor3 = themeColorFor("26,26,30", CurrentThemeName or "Dark")
			Frame.BorderSizePixel = 0
			Frame.ZIndex = 200
			Frame.ClipsDescendants = true
			Frame.Parent = NotificationContainer

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 10)
			Corner.Parent = Frame

			local Stroke = Instance.new("UIStroke")
			Stroke.Thickness = 1.4
			Stroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			Stroke.Transparency = 0.5
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			Stroke.Parent = Frame


			-- Icon (matches UI IconContainer style)
			local IconFrame = Instance.new("Frame")
			IconFrame.Size = UDim2.fromOffset(IsMobile and 26 or 34, IsMobile and 26 or 34)
			IconFrame.Position = UDim2.new(0, 10, 0, hasActions and 10 or 12)
			IconFrame.BackgroundColor3 = mix(themeColorFor("30,30,36", CurrentThemeName or "Dark"), tc, 0.28)
			IconFrame.BorderSizePixel = 0
			IconFrame.ZIndex = 200
			IconFrame.Parent = Frame

			local IconCorner = Instance.new("UICorner")
			IconCorner.CornerRadius = UDim.new(0, IsMobile and 6 or 8)
			IconCorner.Parent = IconFrame

			local IconStroke = Instance.new("UIStroke")
			IconStroke.Thickness = 1.2
			IconStroke.Color = tc
			IconStroke.Transparency = 0.4
			IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			IconStroke.Parent = IconFrame

			local Icon = Instance.new("ImageLabel")
			Icon.Size = UDim2.fromOffset(IsMobile and 17 or 22, IsMobile and 17 or 22)
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
			Icon.BackgroundTransparency = 1
			Astral.ApplyIcon(Icon, tIcon)
			Icon.ImageColor3 = tc
			Icon.ZIndex = 200
			Icon.Parent = IconFrame

			-- Text
			local TextFrame = Instance.new("Frame")
TextFrame.Size = UDim2.new(1, IsMobile and -60 or -68, 0, hasActions and 38 or 34)
			TextFrame.Position = UDim2.new(0, IsMobile and 42 or 50, 0, hasActions and 6 or 8)
			TextFrame.BackgroundTransparency = 1
			TextFrame.ZIndex = 200
			TextFrame.Parent = Frame

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, -6, 0, 18)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Font = Enum.Font.GothamBold
			tr(TitleLabel, title)
			TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
			regText(TitleLabel, IsMobile and 10 or 12)
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.ZIndex = 200
			TitleLabel.Parent = TextFrame

			local DescLabel = Instance.new("TextLabel")
			DescLabel.Size = UDim2.new(1, -6, 0, hasActions and 20 or 24)
			DescLabel.Position = UDim2.new(0, 0, 0, 19)
			DescLabel.BackgroundTransparency = 1
			DescLabel.Font = Enum.Font.Gotham
			DescLabel.Text = message
			DescLabel.TextColor3 = themeColorFor("160,160,165", CurrentThemeName or "Dark")
			regText(DescLabel, IsMobile and 9 or 11)
			DescLabel.TextXAlignment = Enum.TextXAlignment.Left
			DescLabel.TextYAlignment = Enum.TextYAlignment.Top
			DescLabel.TextWrapped = true
			DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
			DescLabel.ZIndex = 200
			DescLabel.Parent = TextFrame

			-- countdown seconds (top-right)
			local CountPill = Instance.new("Frame")
			CountPill.Name = "CountdownPill"
			CountPill.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
			CountPill.BorderSizePixel = 0
			CountPill.AnchorPoint = Vector2.new(1, 0)
			CountPill.Position = UDim2.new(1, -12, 0, 11)
			CountPill.Size = UDim2.new(0, IsMobile and 24 or 34, 0, IsMobile and 14 or 18)
			CountPill.ZIndex = 202
			CountPill.Parent = Frame

			local CountPillCorner = Instance.new("UICorner")
			CountPillCorner.CornerRadius = UDim.new(0, 6)
			CountPillCorner.Parent = CountPill

			local CountPillStroke = Instance.new("UIStroke")
CountPillStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			CountPillStroke.Transparency = 0.5
			CountPillStroke.Thickness = 1
			CountPillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			CountPillStroke.Parent = CountPill

			local CountLabel = Instance.new("TextLabel")
			CountLabel.Name = "Countdown"
			CountLabel.BackgroundTransparency = 1
			CountLabel.Size = UDim2.new(1, 0, 1, 0)
			CountLabel.Font = Enum.Font.GothamBold
			CountLabel.Text = tostring(math.ceil(duration)) .. "s"
			CountLabel.TextSize = IsMobile and 10 or 11
			CountLabel.TextColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
			CountLabel.TextXAlignment = Enum.TextXAlignment.Center
			CountLabel.ZIndex = 203
			CountLabel.Parent = CountPill

			-- Bottom progress bar (neutral, matches UI - no type colors)
			local ProgressTrack = Instance.new("Frame")
			ProgressTrack.Name = "ProgressTrack"
			ProgressTrack.Size = UDim2.new(1, -24, 0, 3)
			ProgressTrack.Position = UDim2.new(0, 12, 1, -6)
			ProgressTrack.BackgroundColor3 = themeColorFor("36,36,40", CurrentThemeName or "Dark")
			ProgressTrack.BorderSizePixel = 0
			ProgressTrack.ZIndex = 201
			ProgressTrack.Parent = Frame

			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(1, 0)
			TrackCorner.Parent = ProgressTrack

			local ProgressFill = Instance.new("Frame")
			ProgressFill.Name = "ProgressFill"
			ProgressFill.Size = UDim2.new(1, 0, 1, 0)
			ProgressFill.BackgroundColor3 = themeColorFor("50,50,55", CurrentThemeName or "Dark")
			ProgressFill.BorderSizePixel = 0
			ProgressFill.ZIndex = 202
			ProgressFill.Parent = ProgressTrack

			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = ProgressFill

			-- Action Buttons (premium: primary = type color, others = dark UI style)
			local dismiss
			local btnRow
			if hasActions then
				btnRow = Instance.new("Frame")
				btnRow.Size = UDim2.new(1, -56, 0, IsMobile and 24 or 26)
				btnRow.Position = UDim2.new(0, 42, 0, IsMobile and 56 or 58)
				btnRow.BackgroundTransparency = 1
				btnRow.ZIndex = 200
				btnRow.Parent = Frame

				local BtnLayout = Instance.new("UIListLayout")
				BtnLayout.FillDirection = Enum.FillDirection.Horizontal
				BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				BtnLayout.Padding = UDim.new(0, 8)
				BtnLayout.Parent = btnRow

				for i, action in ipairs(actions) do
					local aType = action.Type or nType
					local aColor = (notifTypeColors[aType] or tColor).bg
					local isPrimary = (i == 1)
					local Btn = Instance.new("TextButton")
					Btn.Size = UDim2.new(0, IsMobile and 44 or 72, 0, IsMobile and 22 or 26)
					Btn.BackgroundColor3 = isPrimary and aColor or themeColorFor("36,36,40", CurrentThemeName or "Dark")
					Btn.BorderSizePixel = 0
					Btn.Font = Enum.Font.GothamBold
					Btn.Text = action.Text or ""
					Btn.TextColor3 = isPrimary and themeColorFor("15,15,15", CurrentThemeName or "Dark") or themeColorFor("255,255,255", CurrentThemeName or "Dark")
					Btn.TextSize = IsMobile and 10 or 11
					Btn.AutoButtonColor = false
					Btn.ZIndex = 200
					Btn.Parent = btnRow

					local BtnCorner = Instance.new("UICorner")
					BtnCorner.CornerRadius = UDim.new(0, 6)
					BtnCorner.Parent = Btn

					if not isPrimary then
						local BtnStroke = Instance.new("UIStroke")
						BtnStroke.Thickness = 1
						BtnStroke.Color = themeColorFor("50,50,55", CurrentThemeName or "Dark")
						BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
						BtnStroke.Parent = Btn
					end

					local BtnScale = Instance.new("UIScale")
					BtnScale.Scale = 1
					BtnScale.Parent = Btn

					Btn.MouseEnter:Connect(function()
						if pickerOpen or selectorOpen then return end
						TweenService:Create(BtnScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.04}):Play()
					end)
					Btn.MouseLeave:Connect(function()
						TweenService:Create(BtnScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
					end)
					Btn.MouseButton1Down:Connect(function()
						TweenService:Create(BtnScale, TweenInfo.new(0.08), {Scale = 0.96}):Play()
					end)
					Btn.MouseButton1Up:Connect(function()
						TweenService:Create(BtnScale, TweenInfo.new(0.12), {Scale = 1.04}):Play()
					end)
					Btn.MouseButton1Click:Connect(function()
						if action.Callback then
							task.spawn(action.Callback)
						end
						dismiss()
					end)
				end
			end

			-- Hover highlight like UI cards
			Frame.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = themeStrokeHover(Window.ThemeName or "Dark")}):Play()
			end)
			Frame.MouseLeave:Connect(function()
				TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = themeStroke(Window.ThemeName or "Dark")}):Play()
			end)

			-- Slide in from right side
			Frame.Position = UDim2.new(1, 60, 0, 0)
			Frame.BackgroundTransparency = 1
			local NotifScale = Instance.new("UIScale")
			NotifScale.Scale = 0.96
			NotifScale.Parent = Frame
			TweenService:Create(Frame, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 0
			}):Play()
			TweenService:Create(NotifScale, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1
			}):Play()

			-- Auto-Dismiss with progress bar
			local elapsed = 0
			local running = true
			local conn

			dismiss = function()
				if not running then return end
				running = false
				if conn then conn:Disconnect() end
				TweenService:Create(Frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(1, 60, 0, 0),
					BackgroundTransparency = 1
				}):Play()
				TweenService:Create(NotifScale, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Scale = 0.96
				}):Play()
				task.delay(0.3, function()
					pcall(function() Frame:Destroy() end)
				end)
			end

			conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
				if not running then return end
				elapsed = elapsed + dt
				local remain = math.clamp(1 - (elapsed / duration), 0, 1)
				pcall(function()
					ProgressFill.Size = UDim2.new(remain, 0, 1, 0)
					CountLabel.Text = tostring(math.max(0, math.ceil(duration - elapsed))) .. "s"
				end)
				if elapsed >= duration then
					dismiss()
				end
			end)
		end

	-- =========================================================================
	-- GAME STATUS -- small draggable overlay panel outside the window
	--   local S = Window:AddGameStatus({ Title = "Game Status" })
	--   S:Set("Server Uptime", "56h")
	--   S:Countdown("Next Boss", 300)            -- 5m 0s -> 0s
	--   S:Countdown("Full Moon", 1380, "down")
	--   S:Countdown("Uptime", 56*3600, "up")
	-- =========================================================================
	-- =========================================================================
	-- GAME STATUS -- small draggable overlay panel outside the window
	--   local S = Window:AddGameStatus({ Title = "Game Status" })
	--   S:Set("Server Uptime", "56h")
	--   S:SetRow("Next Boss", { Value = "5m", Icon = "timer", Color = "gold" })
	--   S:Countdown("Next Full Moon", 1380)
	-- =========================================================================
	-- =========================================================================
	-- GAME STATUS -- small draggable overlay panel outside the window
	--   local S = Window:AddGameStatus({ Title = "Game Status" })
	--   S:Set("Server Uptime", "56h")
	--   S:SetRow("Next Boss", { Value = "5m", Icon = "timer", Color = "gold" })
	--   S:Countdown("Next Full Moon", 1380)
	-- =========================================================================
	function Window:AddGameStatus(config)
		config = config or {}
		local title = config.Title or "Game Status"
		local icon = parseIcon(config.Icon or "timer")
		local panelW = tonumber(config.Width) or (IsMobile and 150 or 240)
		local rowH = tonumber(config.RowHeight) or (IsMobile and 24 or 30)
		local enabled = config.Enabled
		if enabled == nil then enabled = true end
		local rows = {}

		local NAMED = {
			red = themeColorFor("231,76,60", CurrentThemeName or "Dark"),
			green = themeColorFor("46,204,113", CurrentThemeName or "Dark"),
			blue = themeColorFor("0,153,235", CurrentThemeName or "Dark"),
			cyan = themeColorFor("0,210,255", CurrentThemeName or "Dark"),
			purple = Color3.fromRGB(138, 90, 255),
			pink = themeColorFor("255,90,180", CurrentThemeName or "Dark"),
			orange = themeColorFor("243,156,18", CurrentThemeName or "Dark"),
			gold = themeColorFor("255,212,0", CurrentThemeName or "Dark"),
			white = themeColorFor("240,240,245", CurrentThemeName or "Dark"),
			gray = themeColorFor("160,160,168", CurrentThemeName or "Dark"),
		}
		local function parseColor(v)
			if typeof(v) == "Color3" then return v end
			if type(v) == "string" then return NAMED[v:lower()] end
			return nil
		end

		local Panel = Instance.new("Frame")
		local gsHeaderH = IsMobile and 36 or 44
		local gsMaxPanelH = tonumber(config.MaxHeight) or (IsMobile and 220 or 300)

		Panel.Name = "GameStatus"
		Panel.BackgroundColor3 = themeColorFor("20,20,25", CurrentThemeName or "Dark")
		Panel.BorderSizePixel = 0
		Panel.Size = UDim2.new(0, panelW, 0, gsHeaderH)
		Panel.Position = config.Position or UDim2.new(0, 1254, 0, 64)
		Panel.ZIndex = 500
		Panel.Active = true
		Panel.Visible = enabled
		Panel.ClipsDescendants = true
		Panel.Parent = ScreenGui
		-- clamp on-screen at spawn (fixes off-screen summon on join)
		do
			local defaultPos = Panel.Position
			Panel.Position = clampPanelOnScreen(defaultPos, panelW, 220)
			table.insert(statusPanels, { Panel = Panel, DefaultPos = Panel.Position })
		end

		local gsCornerR = IsMobile and 8 or 12
		local PanelCorner = Instance.new("UICorner")
		PanelCorner.CornerRadius = UDim.new(0, gsCornerR)
		PanelCorner.Parent = Panel

		local PanelStroke = Instance.new("UIStroke")
		PanelStroke.Color = themeColorFor("54,54,64", CurrentThemeName or "Dark")
		PanelStroke.Thickness = 1.2
		PanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		PanelStroke.Parent = Panel

		local PanelGrad = Instance.new("UIGradient")
		PanelGrad.Rotation = 90
		PanelGrad.Color = ColorSequence.new(themeColorFor("30,30,38", CurrentThemeName or "Dark"), themeColorFor("16,16,20", CurrentThemeName or "Dark"))
		PanelGrad.Parent = Panel

		local PanelLayout = Instance.new("UIListLayout")
		PanelLayout.FillDirection = Enum.FillDirection.Vertical
		PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PanelLayout.Padding = UDim.new(0, 0)
		PanelLayout.Parent = Panel

		-- Header doubles as the drag handle
		local Header = Instance.new("Frame")
		Header.Name = "Header"
		Header.BackgroundColor3 = themeColorFor("28,28,35", CurrentThemeName or "Dark")
		Header.BackgroundTransparency = 0.35
		Header.BorderSizePixel = 0
		Header.Size = UDim2.new(1, 0, 0, IsMobile and 36 or 44)
		Header.LayoutOrder = 1
		Header.ZIndex = 501
		Header.Active = true
		Header.Parent = Panel

		-- Header gets its own corners: ClipsDescendants only clips to the
		-- panel rect, NOT its rounded corners, so square header edges poke out.
		local HeaderCorner = Instance.new("UICorner")
		HeaderCorner.CornerRadius = UDim.new(0, gsCornerR)
		HeaderCorner.Parent = Header
		local HeaderIcon = Instance.new("ImageLabel")
		HeaderIcon.Name = "Icon"
		HeaderIcon.BackgroundTransparency = 1
		HeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
		HeaderIcon.Position = UDim2.new(0, 12, 0.5, 0)
		HeaderIcon.Size = UDim2.new(0, IsMobile and 15 or 19, 0, IsMobile and 15 or 19)
		HeaderIcon.ZIndex = 502
		HeaderIcon.ScaleType = Enum.ScaleType.Fit
		HeaderIcon.ImageColor3 = AccentColor
		if icon then Astral.ApplyIcon(HeaderIcon, icon) end
		HeaderIcon.Parent = Header
		onAccentChange(function(c) HeaderIcon.ImageColor3 = c end)

		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Name = "Title"
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
		TitleLabel.Position = UDim2.new(0, 39, 0.5, 0)
		TitleLabel.Size = UDim2.new(0, math.max(40, panelW - 39 - 66), 1, 0)
		TitleLabel.Font = Enum.Font.GothamBold
		tr(TitleLabel, title)
		TitleLabel.TextSize = IsMobile and 13 or 15
		TitleLabel.TextColor3 = themeColorFor("255,255,255", CurrentThemeName or "Dark")
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		TitleLabel.ZIndex = 502
		TitleLabel.Parent = Header

		-- Minimize/Expand "-" button
		local gsMinimized = false
		local MinBtn = Instance.new("TextButton")
		MinBtn.Name = "MinimizeBtn"
		MinBtn.BackgroundColor3 = themeColorFor("40,40,48", CurrentThemeName or "Dark")
		MinBtn.Size = UDim2.new(0, IsMobile and 22 or 26, 0, IsMobile and 22 or 26)
		MinBtn.AnchorPoint = Vector2.new(1, 0.5)
		MinBtn.Position = UDim2.new(1, -10, 0.5, 0)
		MinBtn.Text = "-"
		MinBtn.TextColor3 = themeColorFor("180,180,185", CurrentThemeName or "Dark")
		MinBtn.Font = Enum.Font.GothamBold
		MinBtn.TextSize = IsMobile and 14 or 16
		MinBtn.AutoButtonColor = false
		MinBtn.ZIndex = 503
		MinBtn.Parent = Header

		local MinBtnCorner = Instance.new("UICorner")
		MinBtnCorner.CornerRadius = UDim.new(0, 5)
		MinBtnCorner.Parent = MinBtn

		local RowsContainer
		local RowsLayout
		local function resizePanel(animate)
			if not RowsContainer or not RowsLayout then return end
			local rowsH = RowsLayout.AbsoluteContentSize.Y + 14
			local contentH = gsHeaderH + rowsH
			local targetH = math.min(contentH, gsMaxPanelH)
			targetH = math.max(targetH, gsHeaderH)
			if animate then
				TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, panelW, 0, targetH)
				}):Play()
			else
				Panel.Size = UDim2.new(0, panelW, 0, targetH)
			end
		end

		MinBtn.MouseButton1Click:Connect(function()
			gsMinimized = not gsMinimized
			if gsMinimized then
				MinBtn.Text = "+"
				RowsContainer.Visible = false
				TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, panelW, 0, gsHeaderH)
				}):Play()
			else
				MinBtn.Text = "-"
				RowsContainer.Visible = true
				resizePanel(true)
			end
		end)

		MinBtn.MouseEnter:Connect(function()
			TweenService:Create(MinBtn, TweenInfo.new(0.1), {BackgroundColor3 = themeColorFor("55,55,65", CurrentThemeName or "Dark")}):Play()
		end)
		MinBtn.MouseLeave:Connect(function()
			TweenService:Create(MinBtn, TweenInfo.new(0.1), {BackgroundColor3 = themeColorFor("40,40,48", CurrentThemeName or "Dark")}):Play()
		end)

		local Sep = Instance.new("Frame")
		Sep.Name = "Separator"
		Sep.BackgroundColor3 = themeColorFor("48,48,58", CurrentThemeName or "Dark")
		Sep.BorderSizePixel = 0
		Sep.AnchorPoint = Vector2.new(0.5, 1)
		Sep.Position = UDim2.new(0.5, 0, 1, 0)
		Sep.Size = UDim2.new(1, -20, 0, 1)
		Sep.ZIndex = 502
		Sep.Parent = Header

		RowsContainer = Instance.new("ScrollingFrame")
		RowsContainer.Name = "Rows"
		RowsContainer.BackgroundTransparency = 1
		RowsContainer.Size = UDim2.new(1, 0, 1, -(gsHeaderH + 2))
		RowsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		RowsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		RowsContainer.ScrollBarThickness = 3
		RowsContainer.ScrollBarImageColor3 = themeColorFor("80,80,90", CurrentThemeName or "Dark")
		RowsContainer.ScrollBarImageTransparency = 0.4
		RowsContainer.LayoutOrder = 2
		RowsContainer.ZIndex = 501
		RowsContainer.Parent = Panel

		RowsLayout = Instance.new("UIListLayout")
		RowsLayout.FillDirection = Enum.FillDirection.Vertical
		RowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RowsLayout.Padding = UDim.new(0, 3)
		RowsLayout.Parent = RowsContainer

		local RowsPad = Instance.new("UIPadding")
		RowsPad.PaddingLeft = UDim.new(0, 12)
		RowsPad.PaddingRight = UDim.new(0, 12)
		RowsPad.PaddingTop = UDim.new(0, 7)
		RowsPad.PaddingBottom = UDim.new(0, 12)
		RowsPad.Parent = RowsContainer

		-- Auto-fit the panel whenever rows change. AbsoluteContentSize only
		-- updates after layout runs, so this also fixes initial sizing where
		-- a synchronous read still sees 0.
		RowsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if not gsMinimized then resizePanel(false) end
		end)

		local ICON_GAP = 25

		-- Measure wrapped text and grow the row so nothing is ever cut to "...".
		local function fitRow(row)
			local nameW = math.max(20, panelW * 0.58 - 8)
			local valW = math.max(20, panelW * 0.42 - 8)
			local ts = game:GetService("TextService")
			local nY = ts:GetTextSize(row.Name.Text, row.Name.TextSize, Enum.Font.Gotham, Vector2.new(nameW, 10000)).Y
			local vY = ts:GetTextSize(row.Value.Text, row.Value.TextSize, Enum.Font.GothamBold, Vector2.new(valW, 10000)).Y
			local lineH = row.Name.TextSize * 1.3
			local h = math.max(rowH, math.ceil(math.max(nY, vY) / lineH - 0.001) * lineH + 8)
			row.Frame.Size = UDim2.new(1, 0, 0, h)
		end

		local function makeRow(name, value, iconAsset, colorOverride)
			local Row = Instance.new("Frame")
			Row.Name = "Row"
			Row.BackgroundTransparency = 1
			Row.Size = UDim2.new(1, 0, 0, rowH)
			Row.ZIndex = 501
			Row.Parent = RowsContainer

			-- Rounded hover highlight behind the text
			local RowHover = Instance.new("Frame")
			RowHover.Name = "Hover"
			RowHover.BackgroundColor3 = themeColorFor("40,40,50", CurrentThemeName or "Dark")
			RowHover.BackgroundTransparency = 1
			RowHover.BorderSizePixel = 0
			RowHover.Position = UDim2.new(0, -6, 0, 0)
			RowHover.Size = UDim2.new(1, 12, 1, 0)
			RowHover.ZIndex = 500
			RowHover.Parent = Row

			local RowHoverCorner = Instance.new("UICorner")
			RowHoverCorner.CornerRadius = UDim.new(0, 6)
			RowHoverCorner.Parent = RowHover

			local IconLabel = Instance.new("ImageLabel")
			IconLabel.Name = "Icon"
			IconLabel.BackgroundTransparency = 1
			IconLabel.AnchorPoint = Vector2.new(0, 0.5)
			IconLabel.Position = UDim2.new(0, 2, 0.5, 0)
			IconLabel.Size = UDim2.new(0, IsMobile and 14 or 17, 0, IsMobile and 14 or 17)
			IconLabel.Visible = false
			IconLabel.ScaleType = Enum.ScaleType.Fit
			IconLabel.ImageColor3 = colorOverride or themeColorFor("205,205,214", CurrentThemeName or "Dark")
			IconLabel.ZIndex = 502
			IconLabel.Parent = Row

			local NameLabel = Instance.new("TextLabel")
			NameLabel.Name = "Name"
			NameLabel.BackgroundTransparency = 1
			NameLabel.AnchorPoint = Vector2.new(0, 0.5)
			NameLabel.Position = UDim2.new(0, 0, 0.5, 0)
			NameLabel.Size = UDim2.new(0.58, 0, 1, 0)
			NameLabel.Font = Enum.Font.Gotham
			tr(NameLabel, tostring(name))
			NameLabel.TextSize = IsMobile and 12 or 14
			NameLabel.TextColor3 = themeColorFor("165,165,176", CurrentThemeName or "Dark")
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextTruncate = Enum.TextTruncate.None
			NameLabel.TextWrapped = true
			NameLabel.ZIndex = 502
			NameLabel.Parent = Row

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Name = "Value"
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.AnchorPoint = Vector2.new(1, 0.5)
			ValueLabel.Position = UDim2.new(1, -2, 0.5, 0)
			ValueLabel.Size = UDim2.new(0.42, 0, 1, 0)
			ValueLabel.Font = Enum.Font.GothamBold
			ValueLabel.Text = tostring(value or "--")
			ValueLabel.TextSize = IsMobile and 12 or 13
			ValueLabel.TextColor3 = colorOverride or AccentColor
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.TextTruncate = Enum.TextTruncate.None
			ValueLabel.TextWrapped = true
			ValueLabel.ZIndex = 502
			ValueLabel.Parent = Row

			Row.MouseEnter:Connect(function()
				if pickerOpen or selectorOpen then return end
				TweenService:Create(RowHover, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
			end)
			Row.MouseLeave:Connect(function()
				TweenService:Create(RowHover, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
			end)

			local row = { Frame = Row, Name = NameLabel, Value = ValueLabel, Icon = IconLabel, Hover = RowHover, color = colorOverride, token = 0 }
			onAccentChange(function(c)
				if not row.color then row.Value.TextColor3 = c end
			end)
			row.Name:GetPropertyChangedSignal("Text"):Connect(function() fitRow(row) end)
			row.Value:GetPropertyChangedSignal("Text"):Connect(function() fitRow(row) end)
			fitRow(row)
			return row
		end

		local function applyRow(row, opts)
			opts = opts or {}
			if opts.Icon ~= nil then
				local asset = parseIcon(opts.Icon)
				if asset then
					Astral.ApplyIcon(row.Icon, asset)
					row.Icon.Visible = true
					row.Name.Position = UDim2.new(0, ICON_GAP, 0.5, 0)
					row.Name.Size = UDim2.new(0.58, -ICON_GAP, 1, 0)
				else
					row.Icon.Visible = false
					row.Name.Position = UDim2.new(0, 0, 0.5, 0)
					row.Name.Size = UDim2.new(0.58, 0, 1, 0)
				end
			end
			if opts.Color ~= nil then
				row.color = parseColor(opts.Color)
				row.Value.TextColor3 = row.color or AccentColor
				row.Icon.ImageColor3 = row.color or themeColorFor("205,205,214", CurrentThemeName or "Dark")
			end
			if opts.Value ~= nil then
				row.Value.Text = tostring(opts.Value)
			end
			if opts.Name ~= nil then
				tr(row.Name, tostring(opts.Name))
			end
			fitRow(row)
		end

		-- Drag the whole panel by its header
		local dragging, dragStart, startPos = false, nil, nil
		Header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				pcall(function() MainFrame:SetAttribute("StatusDragT", os.clock()) end)
				dragging = true
				dragStart = input.Position
				startPos = Panel.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local dx = input.Position.X - dragStart.X
				local dy = input.Position.Y - dragStart.Y
				local nextPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
				Panel.Position = clampPanelOnScreen(nextPos, panelW, 220)
			end
		end)

		local function fmtDuration(sec)
			sec = math.max(0, math.floor(sec))
			local h = math.floor(sec / 3600)
			local m = math.floor((sec % 3600) / 60)
			local s = sec % 60
			if h > 0 then return h .. "h " .. m .. "m" end
			if m > 0 then return m .. "m " .. s .. "s" end
			return s .. "s"
		end

		local GameStatus = {}

		function GameStatus:SetRow(name, opts)
			name = tostring(name)
			opts = opts or {}
			local row = rows[name]
			if not row then
				row = makeRow(name, opts.Value, nil, parseColor(opts.Color))
				rows[name] = row
			end
			row.token = (row.token or 0) + 1
			applyRow(row, opts)
			if not gsMinimized then task.defer(function() resizePanel(false) end) end

		return GameStatus
		end

		function GameStatus:Set(name, value)
			if type(value) == "table" then return GameStatus:SetRow(name, value) end

		return GameStatus:SetRow(name, { Value = value })
		end
		GameStatus.SetValue = GameStatus.Set

		function GameStatus:SetColor(name, color)
			local r = rows[tostring(name)]
			if r then applyRow(r, { Color = color }) end

		return GameStatus
		end

		function GameStatus:SetIcon(name, iconInput)
			local r = rows[tostring(name)]
			if r then applyRow(r, { Icon = iconInput }) end

		return GameStatus
		end

		function GameStatus:Get(name)
			local r = rows[tostring(name)]
			return r and r.Value.Text or nil
		end

		function GameStatus:Remove(name)
			name = tostring(name)
			local r = rows[name]
			if r then pcall(function() r.Frame:Destroy() end); rows[name] = nil end
			if not gsMinimized then task.defer(function() resizePanel(false) end) end

		return GameStatus
		end

		function GameStatus:Clear()
			for _, r in pairs(rows) do pcall(function() r.Frame:Destroy() end) end
			rows = {}
			if not gsMinimized then task.defer(function() resizePanel(false) end) end

		return GameStatus
		end

		function GameStatus:SetRows(list)
			GameStatus:Clear()
			for _, r in ipairs(list or {}) do
				if type(r) == "table" then
					local nm = r.Name or r[1]
					if type(r[2]) == "table" then
						GameStatus:SetRow(nm, r[2])
					else
						GameStatus:SetRow(nm, { Value = r.Value or r[2], Icon = r.Icon, Color = r.Color })
					end
				end
			end

		return GameStatus
		end

		-- Live row timer: GameStatus:Countdown("Next Boss", 300) / (..., "up")
		function GameStatus:Countdown(name, seconds, mode, onDone)
			if type(mode) == "function" then onDone = mode; mode = "down" end
			mode = mode or "down"
			name = tostring(name)
			if not rows[name] then GameStatus:Set(name, "") end
			local row = rows[name]
			row.token = (row.token or 0) + 1
			local myToken = row.token
			local total = math.max(0, math.floor(tonumber(seconds) or 0))
			local anchor = os.clock()
			task.spawn(function()
				while true do
					if row.token ~= myToken then return end
					local elapsed = math.floor(os.clock() - anchor)
					local value = total
					if mode == "up" then
						value = total + elapsed
					else
						value = total - elapsed
					end
					if value < 0 then value = 0 end
					row.Value.Text = fmtDuration(value)
					if mode ~= "up" and value <= 0 then break end
					task.wait(1)
				end
				if row.token == myToken and mode ~= "up" and onDone then task.spawn(onDone) end
			end)

		return GameStatus
		end

		function GameStatus:StopCountdown(name)
			local r = rows[tostring(name)]
			if r then r.token = (r.token or 0) + 1 end

		return GameStatus
		end

		function GameStatus:SetTitle(t) TitleLabel.Text = tostring(t); return GameStatus end
		function GameStatus:SetTitleIcon(iconInput)
			local asset = parseIcon(iconInput)
			if asset then Astral.ApplyIcon(HeaderIcon, asset) end

		return GameStatus
		end
		function GameStatus:SetPosition(pos) Panel.Position = pos; return GameStatus end
		function GameStatus:Show() enabled = true; Panel.Visible = true; return GameStatus end
		function GameStatus:Hide() enabled = false; Panel.Visible = false; return GameStatus end
		function GameStatus:SetEnabled(v)
			if v then return GameStatus:Show() end

		return GameStatus:Hide()
		end
		function GameStatus:Toggle() return GameStatus:SetEnabled(not enabled) end
		function GameStatus:IsEnabled() return enabled end
		function GameStatus:Destroy() pcall(function() Panel:Destroy() end) end

		if config.Rows then GameStatus:SetRows(config.Rows) end

		if Window.ThemeName and Window.ThemeName ~= "Dark" then
			applyThemeToGui(ScreenGui, AccentColor, "Dark", Window.ThemeName)
		end

		for _, sp in ipairs(statusPanels) do
			if sp.Panel == Panel then sp.Controller = GameStatus end
		end

		return GameStatus
	end



	Window.ThemeName = "Dark"
	if config.Theme and type(config.Theme) == "string" then
		local initial = applyThemeToGui(ScreenGui, AccentColor, "Dark", config.Theme)
		if initial then Window.ThemeName = initial; CurrentThemeName = initial end
	end

	-- restore saved UI positions (main, logo, status panels)
	pcall(function() Window:LoadUIPositions() end)

	-- auto-load saved element states so a server hop resumes itself
	if config.AutoLoad or config.AutoLoadConfig then
		local cfgName = config.ConfigName
		task.delay(1, function()
			pcall(Window.LoadConfig, Window, cfgName)
		end)
	end

	-- design identity + LIVE switcher (no rejoin needed; choice is persisted)
	Window.DesignName = "TopBar"
	Window._Config = config
	-- register this lib in the design cache so SwitchDesign can swap instantly
	Astral._DesignCache["TopBar"] = Astral

	function Window:GetDesign()
		return Window.DesignName
	end

	-- Switch design right now: wipes this UI, rebuilds in the other design instantly.
	-- Priority: LumuHubReload hook (rebuilds your full app) > cached lib > HTTP fallback.
	function Window:SwitchDesign(design)
		if design ~= "Sidebar" and design ~= "TopBar" then return false end
		writeDesignPref(design)
		-- 1) app-provided reload hook (rebuilds the whole script, keeps your tabs)
		if type(getgenv().LumuHubReload) == "function" then
			local ok = pcall(getgenv().LumuHubReload, design)
			if ok then return true end
		end
		-- 2) cached lib (instant, no network ΓÇö loader must cache both libs at startup)
		local cached = Astral._DesignCache and Astral._DesignCache[design]
		if cached then
			local ok = pcall(function()
				if cached.RegisterIcons and Astral.Icons then pcall(cached.RegisterIcons, cached, Astral.Icons) end
				local cfg = Window._Config or { Title = "Lumu" }
				pcall(function() ScreenGui:Destroy() end)
				cached:CreateWindow(cfg)
			end)
			if ok then return true end
		end
		-- 3) last resort: HTTP fallback (slow)
		local ok3 = pcall(function()
			local lib = loadstring(game:HttpGet(DESIGN_URLS[design]))()
			if lib and lib.RegisterIcons and Astral.Icons then pcall(lib.RegisterIcons, lib, Astral.Icons) end
			local cfg = Window._Config or { Title = "Lumu" }
			pcall(function() ScreenGui:Destroy() end)
			lib:CreateWindow(cfg)
		end)
		return ok3
	end

	-- SetDesign is an alias of SwitchDesign (persist + switch live)
	function Window:SetDesign(design)
		return Window:SwitchDesign(design)
	end

	-- Auto floating STOP button unless opted out (no script code needed).
	if config.StopButton ~= false then
		pcall(function()
			for _, g in ipairs(ScreenGui:GetChildren()) do
				if g.Name == "StopButton" then pcall(function() g:Destroy() end) end
			end
			Window._AutoStop = Window:AddStopButton({ Text = "Stop Farm" })
		end)
	end


	return Window
end

-- Alias to support CreateWindow calls
Astral.CreateWindow = Astral.MakeWindow

return Astral
