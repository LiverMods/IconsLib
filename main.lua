--<LM>----<LM>----<LM>----<LM>----<LM>----<LM>----<LM>----<LM>----<LM>----<LM>-- 
if not game:IsLoaded() then
    game.Loaded:Wait()
end

--<>---<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>---<>---
local IsStudio = game:GetService("RunService"):IsStudio()
local env = getgenv and getgenv() or getfenv(0)

local function randomString()
    local length = math.random(10,20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

local function encryptNames(target)
    if typeof(target) ~= "Instance" then return end
    for _, descendant in ipairs(target:GetDescendants()) do
        if descendant:IsA("Instance") then
            descendant.Name = randomString()
        end
    end
    target.Name = randomString()
end

local Utils = {}
Utils.Services = setmetatable({}, {
    __index = function(t, k)
        local s, v = pcall(function()
            if IsStudio then return game:GetService(k) end
            local service = game:GetService(k)
            if type(env.cloneref) == "function" then return env.cloneref(service) end
            return service
        end)
        if s then rawset(t, k, v) return v end 
        error("[IconsLib] Serviço Invalido ou Bloqueado: "..tostring(k))
    end
})

local function CSI(buildFunction)
    assert(typeof(buildFunction) == "function")
    local gui = buildFunction()
    assert(typeof(gui) == "Instance" and gui:IsA("ScreenGui"))

    local success, err = pcall(function()
        if IsStudio then
            local s_cg, r_cg = pcall(function() return Utils.Services.CoreGui end)
            gui.Parent = (s_cg and r_cg) and r_cg or Utils.Services.Players.LocalPlayer:WaitForChild("PlayerGui")
        elseif env.get_hidden_gui or env.gethui then
            local hidden = env.get_hidden_gui or env.gethui
            gui.Parent = hidden()
        elseif type(env.is_sirhurt_closure) == "nil" and env.syn and env.syn.protect_gui then
            env.syn.protect_gui(gui)
            gui.Parent = Utils.Services.CoreGui
        else
            gui.Parent = Utils.Services.CoreGui
        end
    end)

    if not success then
        warn("[CreateSafeGui]: Failed to apply protection/parent: " .. tostring(err))
        return nil
    end
    return gui
end

function Utils.Make(cls, props, parent)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

function Utils.Tween(obj, props, t)
    local tw = Utils.Services.TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

function Utils.Notify(title, msg, stateConfig)
    if stateConfig.Notify then 
        pcall(function() Utils.Services.StarterGui:SetCore("SendNotification", {Title = title, Text = msg, Duration = 3}) end) 
    end
end

function Utils.GDA()
    local UIS = game:GetService("UserInputService")
    local GS = game:GetService("GuiService")
    if UIS.VREnabled then return "VR" end
    if GS:IsTenFootInterface() then return "Console" end
    if UIS.TouchEnabled then return (UIS.KeyboardEnabled) and "PC" or "Mobile" end
    return "PC"
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

local App = { IsReloading = false }
local Controllers = {}
local Components = {}
local State = {
    LoadTicket = 0,
    IsLoading = false,
    AllCells = {},
    Icons = {},
    ActiveUI = {},
    
    C = {
        BG = Color3.fromRGB(15, 15, 20), TOPBAR = Color3.fromRGB(22, 22, 28),
        PANEL = Color3.fromRGB(30, 30, 38), CARD = Color3.fromRGB(26, 26, 32),
        CARD_HV = Color3.fromRGB(40, 40, 50), BORDER = Color3.fromRGB(45, 45, 55),
        ACCENT = Color3.fromRGB(99, 102, 241), TXT_W = Color3.fromRGB(250, 250, 255),
        TXT_G = Color3.fromRGB(160, 160, 175), CLOSE = Color3.fromRGB(239, 68, 68),
        SUCCESS = Color3.fromRGB(34, 197, 94),
    },

    LIBRARIES = {
        {"Fluency", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Fluency.lua"},
        {"Lucide_LM", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Lucide_LM.lua"},
        {"Lucide", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Lucide.lua"},
        {"Lucide_Lab", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Lucide_Lab.lua"},
        {"SFS_LM", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/SFS_LM.lua"},
        {"SF_Symbols", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/SF_Symbols.lua"},
        {"Material", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Material.lua"},
        {"Phosphor", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Phosphor.lua"},
        {"Phosphor_Filled", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Phosphor_Filled.lua"},
        {"Symbols", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Symbols.lua"},
        {"Symbols_Filled", "https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/Folder/IconsLib/Symbols_Filled.lua"}
    },
    
    CONFIG = { LangIndex = 1, LibIndex = 2, FormatIndex = 1, SizeIndex = 2, Notify = true, CloseOnCopy = false, SecureCopy = false }
}

State.LIB_NAMES = {}
for _, v in ipairs(State.LIBRARIES) do table.insert(State.LIB_NAMES, v[1]) end

local i18n = {
    TransTexts = {}, DynamicDrops = {},
    LANG_KEYS = {"en", "pt", "es", "vi"}, LANG_NAMES = {"English", "Português", "Español", "Tiếng Việt"},
    DICT = {
        en = {loading = "Loading...", icons = "icons", search = "Search...", settings = "Settings", library = "Library", copyFormat = "Copy Format", iconSize = "Icon Size", idOnly = "ID Only", small = "Small", medium = "Medium", large = "Large", notifyCopy = "Notify on Copy", secureCopy = "Secure Copy (Ctrl+Click)", closeCopy = "Close on Copy", copied = "Copied!", language = "Language"},
        pt = {loading = "Carregando...", icons = "ícones", search = "Pesquisar...", settings = "Configurações", library = "Biblioteca", copyFormat = "Formato de Cópia", iconSize = "Tamanho dos Ícones", idOnly = "Apenas ID", small = "Pequeno", medium = "Médio", large = "Grande", notifyCopy = "Notificar ao Copiar", secureCopy = "Cópia Segura (Ctrl+Click)", closeCopy = "Fechar ao Copiar", copied = "Copiado!", language = "Idioma"},
        es = {loading = "Cargando...", icons = "iconos", search = "Buscar...", settings = "Ajustes", library = "Biblioteca", copyFormat = "Formato de Copia", iconSize = "Tamaño de Iconos", idOnly = "Solo ID", small = "Pequeño", medium = "Mediano", large = "Grande", notifyCopy = "Notificar al Copiar", secureCopy = "Copia Segura (Ctrl+Clic)", closeCopy = "Cerrar al Copiar", copied = "¡Copiado!", language = "Idioma"},
        vi = {loading = "Đang tải...", icons = "biểu tượng", search = "Tìm kiếm...", settings = "Cài đặt", library = "Thư viện", copyFormat = "Định dạng Copy", iconSize = "Kích thước", idOnly = "Chỉ ID", small = "Nhỏ", medium = "Vừa", large = "Lớn", notifyCopy = "Thông báo khi Copy", secureCopy = "Copy An toàn (Ctrl+Click)", closeCopy = "Đóng khi Copy", copied = "Đã sao chép!", language = "Ngôn ngữ"}
    }
}

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function i18n.Init()
    local s_loc, r_loc = pcall(function() return Utils.Services.LocalizationService.RobloxLocaleId end)
    local sysLang = (s_loc and type(r_loc) == "string") and r_loc:sub(1,2):lower() or "en"
    local langMap = {en=1, pt=2, es=3, vi=4}
    State.CONFIG.LangIndex = langMap[sysLang] or 1
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function i18n.Get(key) return i18n.DICT[i18n.LANG_KEYS[State.CONFIG.LangIndex]][key] or i18n.DICT.en[key] end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function i18n.Bind(element, key, isPlaceholder)
    table.insert(i18n.TransTexts, {e = element, k = key, isPh = isPlaceholder})
    if isPlaceholder then element.PlaceholderText = i18n.Get(key) else element.Text = i18n.Get(key) end
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function i18n.UpdateUI()
    for _, item in ipairs(i18n.TransTexts) do
        if item.isPh then item.e.PlaceholderText = i18n.Get(item.k) else item.e.Text = i18n.Get(item.k) end
    end
    for _, drop in ipairs(i18n.DynamicDrops) do drop.lbl.Text = drop.fn()[State.CONFIG[drop.ref]] end
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Components.CreateDrop(parent, titleKey, listFn, keyRef, ord, callback)
    local btn = Utils.Make("TextButton", {Size = UDim2.new(1,-20,0,50), BackgroundColor3 = State.C.PANEL, Text = "", AutoButtonColor = false, LayoutOrder = ord, ZIndex = 5}, parent)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,12)}, btn); Utils.Make("UIStroke", {Color = State.C.BORDER, Thickness = 1.5}, btn)
    local titleLbl = Utils.Make("TextLabel", {Size = UDim2.new(0,200,1,0), Position = UDim2.fromOffset(15,0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = State.C.TXT_G, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6}, btn)
    i18n.Bind(titleLbl, titleKey)
    local valLbl = Utils.Make("TextLabel", {Size = UDim2.new(0,150,1,0), Position = UDim2.new(1,-165,0,0), BackgroundTransparency = 1, Text = listFn()[State.CONFIG[keyRef]], Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = State.C.ACCENT, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6}, btn)
    table.insert(i18n.DynamicDrops, {lbl = valLbl, fn = listFn, ref = keyRef})

    btn.MouseEnter:Connect(function() Utils.Tween(btn, {BackgroundColor3 = State.C.CARD_HV}, 0.15) end)
    btn.MouseLeave:Connect(function() Utils.Tween(btn, {BackgroundColor3 = State.C.PANEL}, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        local list = listFn()
        State.CONFIG[keyRef] = (State.CONFIG[keyRef] >= #list) and 1 or (State.CONFIG[keyRef] + 1)
        valLbl.Text = list[State.CONFIG[keyRef]]
        Utils.Tween(valLbl, {TextSize = 11}, 0.05); task.delay(0.05, function() Utils.Tween(valLbl, {TextSize = 13}, 0.2) end)
        if callback then callback() end
    end)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Components.CreateToggle(parent, titleKey, keyRef, ord)
    local btn = Utils.Make("TextButton", {Size = UDim2.new(1,-20,0,50), BackgroundColor3 = State.C.PANEL, Text = "", AutoButtonColor = false, LayoutOrder = ord, ZIndex = 5}, parent)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,12)}, btn); Utils.Make("UIStroke", {Color = State.C.BORDER, Thickness = 1.5}, btn)
    local titleLbl = Utils.Make("TextLabel", {Size = UDim2.new(0,200,1,0), Position = UDim2.fromOffset(15,0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = State.C.TXT_G, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6}, btn)
    i18n.Bind(titleLbl, titleKey)
    local tBg = Utils.Make("Frame", {Size = UDim2.fromOffset(40,20), Position = UDim2.new(1,-55,0.5,-10), BackgroundColor3 = State.CONFIG[keyRef] and State.C.SUCCESS or State.C.BORDER, ZIndex = 6}, btn)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,10)}, tBg)
    local circ = Utils.Make("Frame", {Size = UDim2.fromOffset(14,14), Position = UDim2.new(0, State.CONFIG[keyRef] and 23 or 3, 0.5, -7), BackgroundColor3 = State.C.TXT_W, ZIndex = 7}, tBg)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,7)}, circ)
    
    btn.MouseEnter:Connect(function() Utils.Tween(btn, {BackgroundColor3 = State.C.CARD_HV}, 0.15) end)
    btn.MouseLeave:Connect(function() Utils.Tween(btn, {BackgroundColor3 = State.C.PANEL}, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        State.CONFIG[keyRef] = not State.CONFIG[keyRef]
        Utils.Tween(tBg, {BackgroundColor3 = State.CONFIG[keyRef] and State.C.SUCCESS or State.C.BORDER}, 0.25)
        Utils.Tween(circ, {Position = UDim2.new(0, State.CONFIG[keyRef] and 23 or 3, 0.5, -7)}, 0.3)
    end)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Components.CreateCard(parent, name, id, layoutOrder)
    local C, CONFIG = State.C, State.CONFIG
    local rawId = tostring(id); local numId = rawId:match("%d+") or "0"; local fullId = "rbxassetid://" .. numId

    local cell = Utils.Make("Frame", {BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)
    cell:SetAttribute("IconName", name)

    local card = Utils.Make("TextButton", {Size = UDim2.fromScale(1,1), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.CARD, Text = "", AutoButtonColor = false, ZIndex = 5}, cell)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,10)}, card)
    local cStroke = Utils.Make("UIStroke", {Color = C.BORDER, Thickness = 1.5}, card)
    local iconImg = Utils.Make("ImageLabel", {Size = UDim2.fromOffset(32,32), Position = UDim2.new(0.5,-16,0,12), BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id="..numId.."&w=150&h=150", ScaleType = Enum.ScaleType.Fit, ZIndex = 6}, card)
    Utils.Make("TextLabel", {Size = UDim2.new(1,-6,0,16), Position = UDim2.new(0,3,1,-22), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.TXT_G, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6}, card)
    local flash = Utils.Make("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = C.SUCCESS, BackgroundTransparency = 1, ZIndex = 7}, card)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,10)}, flash)

    local function copy()
        local cData = (CONFIG.FormatIndex == 2) and numId or (CONFIG.FormatIndex == 3) and ('"'..fullId..'"') or fullId
        pcall(function() 
            if IsStudio then Utils.Services.StudioService:CopyToClipboard(cData) elseif env.setclipboard then env.setclipboard(cData) end
        end)
        
        Utils.Tween(card, {Size = UDim2.fromScale(0.85,0.85)}, 0.1); Utils.Tween(cStroke, {Color = C.SUCCESS, Thickness = 2}, 0.1)
        Utils.Tween(iconImg, {Size = UDim2.fromOffset(42,42), Position = UDim2.new(0.5,-21,0,8)}, 0.1); Utils.Tween(flash, {BackgroundTransparency = 0.6}, 0.1)
        task.delay(0.1, function()
            if not card.Parent then return end
            Utils.Tween(card, {Size = UDim2.fromScale(1,1)}, 0.4); Utils.Tween(cStroke, {Color = C.BORDER, Thickness = 1.5}, 0.4)
            Utils.Tween(iconImg, {Size = UDim2.fromOffset(32,32), Position = UDim2.new(0.5,-16,0,12)}, 0.4); Utils.Tween(flash, {BackgroundTransparency = 1}, 0.3)
        end)
        Utils.Notify(i18n.Get("copied"), name .. "\n" .. cData, CONFIG)
        if CONFIG.CloseOnCopy then State.ActiveUI.CloseBtn.MouseButton1Click:Fire() end
    end

    card.MouseEnter:Connect(function()
        Utils.Tween(card, {BackgroundColor3 = C.CARD_HV}, 0.15)
        Utils.Tween(iconImg, {Size = UDim2.fromOffset(36,36), Position = UDim2.new(0.5,-18,0,10)}, 0.15)
    end)
    
    card.MouseLeave:Connect(function()
        Utils.Tween(card, {BackgroundColor3 = C.CARD}, 0.15)
        Utils.Tween(iconImg, {Size = UDim2.fromOffset(32,32), Position = UDim2.new(0.5,-16,0,12)}, 0.15)
    end)

    local ht = 0
    card.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            Utils.Tween(card, {BackgroundColor3 = C.CARD_HV}, 0.15)
            if CONFIG.SecureCopy then
                local ctrl = Utils.Services.UserInputService
                if ctrl:IsKeyDown(Enum.KeyCode.LeftControl) then copy() else ht = tick(); local ct = ht; task.delay(0.4, function() if ht == ct then copy() end end) end
            end
        end
    end)
    
    card.InputEnded:Connect(function(i) 
        if i.UserInputType.Name:find("Mouse") or i.UserInputType.Name:find("Touch") then 
            ht = 0
            if i.UserInputType == Enum.UserInputType.Touch then
                Utils.Tween(card, {BackgroundColor3 = C.CARD}, 0.15) 
            end
        end 
    end)
    
    card.MouseButton1Click:Connect(function() if not CONFIG.SecureCopy then copy() end end)

    encryptNames(cell)
    table.insert(State.AllCells, cell)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Controllers.RenderFilter()
    local UI = State.ActiveUI
    if not UI.SearchBox then return end
    
    local f = UI.SearchBox.Text:lower()
    local vis = 0
    
    for _, cell in ipairs(State.AllCells) do
        local iconName = cell:GetAttribute("IconName") or ""
        local isVis = (f == "" or iconName:lower():find(f, 1, true) ~= nil)
        cell.Visible = isVis
        if isVis then vis = vis + 1 end
    end
    
    UI.CountLabel.Text = vis .. " " .. i18n.Get("icons")
    Utils.Tween(UI.BadgeBg, {Size = UDim2.fromOffset(math.clamp(40 + (#tostring(vis) * 8), 60, 100), 22)}, 0.2)
end

function Controllers.UpdateGrid()
    local idx = State.CONFIG.SizeIndex
    State.ActiveUI.Grid.CellSize = (idx == 1) and UDim2.fromOffset(60,78) or (idx == 2) and UDim2.fromOffset(70,88) or UDim2.fromOffset(84,102)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Controllers.FetchLibrary()
    local url = State.LIBRARIES[State.CONFIG.LibIndex][2]
    local s, r = pcall(function()
        local raw = IsStudio and Utils.Services.HttpService:GetAsync(url) or env.game:HttpGet(url)
        if raw:find("return {") then return loadstring(raw)() end
        raw = raw:gsub('"(.-)"%s*=%s*', '["%1"] = ')
        return loadstring(raw)()
    end)
    if not s and IsStudio then warn("[IconsLib] Erro ao carregar biblioteca. HttpRequests desativado?") end
    return (s and type(r) == "table") and r or {}
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function Controllers.LoadData()
    State.LoadTicket = State.LoadTicket + 1
    local myTicket = State.LoadTicket

    for _, c in ipairs(State.AllCells) do c:Destroy() end
    table.clear(State.AllCells)
    
    State.ActiveUI.TitleText.Text = State.LIBRARIES[State.CONFIG.LibIndex][1]
    State.ActiveUI.CountLabel.Text = i18n.Get("loading")
    State.Icons = Controllers.FetchLibrary()

    local sorted = {}
    for n in pairs(State.Icons) do table.insert(sorted, n) end
    table.sort(sorted)

    local loadCount = 0
    Controllers.UpdateGrid() 

    for index, name in ipairs(sorted) do
        if State.LoadTicket ~= myTicket then break end 
        loadCount = loadCount + 1
        
        Components.CreateCard(State.ActiveUI.Scroll, name, State.Icons[name], index)
        
        if loadCount % 30 == 0 then 
            State.ActiveUI.CountLabel.Text = i18n.Get("loading") .. " (" .. loadCount .. ")"
            Controllers.RenderFilter() 
            task.wait() 
        end 
    end
    
    if State.LoadTicket == myTicket then Controllers.RenderFilter() end
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function App.BuildUI()
    i18n.Init()
    local C, UI = State.C, State.ActiveUI
    
    local sg = CSI(function()
        return Utils.Make("ScreenGui", {ResetOnSpawn = false, DisplayOrder = 99999})
    end)
    
    if not sg then return false end
    UI.ScreenGui = sg

    UI.Overlay = Utils.Make("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BackgroundColor3 = Color3.new(0,0,0), ZIndex = 1}, sg)
    UI.Win = Utils.Make("Frame", {Size = UDim2.fromScale(0,0), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.BG, ClipsDescendants = true, ZIndex = 2}, sg)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,16)}, UI.Win)
    Utils.Make("UISizeConstraint", {MaxSize = Vector2.new(700,550), MinSize = Vector2.new(300,400)}, UI.Win)
    UI.WinStroke = Utils.Make("UIStroke", {Color = C.BORDER, Transparency = 1, Thickness = 1.5}, UI.Win)

    local top = Utils.Make("Frame", {Size = UDim2.new(1,0,0,55), BackgroundColor3 = C.TOPBAR, Active = (Utils.GDA() == "Mobile"),ZIndex = 10}, UI.Win)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,16)}, top)
    Utils.Make("Frame", {Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,1,-16), BackgroundColor3 = C.TOPBAR, BorderSizePixel = 0, ZIndex = 10}, top)
    Utils.Make("Frame", {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = C.BORDER, BorderSizePixel = 0, ZIndex = 11}, top)
    Utils.Make("ImageLabel", {Size = UDim2.fromOffset(20,20), Position = UDim2.new(0,16,0.5,-10), BackgroundTransparency = 1, Image = "rbxassetid://7733960981", ImageColor3 = C.ACCENT, ZIndex = 12}, top)
    
    UI.TitleText = Utils.Make("TextLabel", {Size = UDim2.new(0,90,0,22), Position = UDim2.fromOffset(44,8), BackgroundTransparency = 1, Text = "IconsLib", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.TXT_W, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12}, top)
    Utils.Make("TextLabel", {Size = UDim2.new(0,90,0,15), Position = UDim2.fromOffset(44,28), BackgroundTransparency = 1, Text = "by Liver zMods", Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.ACCENT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12}, top)

    -- Container maior (250px) para acomodar a Badge + Botões sem apertar
    local rightBtns = Utils.Make("Frame", {Size = UDim2.new(0,250,1,0), Position = UDim2.new(1,-12,0,0), AnchorPoint = Vector2.new(1,0), BackgroundTransparency = 1, ZIndex = 12}, top)
    Utils.Make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder}, rightBtns)

    -- Badge agora faz parte do 'rightBtns' e possui LayoutOrder = 0 (aparece antes dos botões)
    UI.BadgeBg = Utils.Make("Frame", {Size = UDim2.fromOffset(60,22), BackgroundColor3 = C.PANEL, LayoutOrder = 0, ZIndex = 12}, rightBtns)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,6)}, UI.BadgeBg)
    UI.CountLabel = Utils.Make("TextLabel", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.TXT_G, ZIndex = 13}, UI.BadgeBg)
    i18n.Bind(UI.CountLabel, "loading", false)

    local function createTopBtn(icon, color, hoverColor, order)
        local btn = Utils.Make("TextButton", {Size = UDim2.fromOffset(32,32), BackgroundColor3 = color == C.CLOSE and C.CLOSE or C.PANEL, BackgroundTransparency = 0.85, Text = "", AutoButtonColor = false, LayoutOrder = order, ZIndex = 13}, rightBtns)
        Utils.Make("UICorner", {CornerRadius = UDim.new(0,8)}, btn)
        local img = Utils.Make("ImageLabel", {Size = UDim2.fromOffset(16,16), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = icon, ImageColor3 = color == C.CLOSE and C.CLOSE or C.TXT_G, ZIndex = 14}, btn)
        btn.MouseEnter:Connect(function() Utils.Tween(btn, {BackgroundTransparency = 0.1}, 0.15); Utils.Tween(img, {ImageColor3 = hoverColor}, 0.15) end)
        btn.MouseLeave:Connect(function() Utils.Tween(btn, {BackgroundTransparency = 0.85}, 0.15); Utils.Tween(img, {ImageColor3 = color == C.CLOSE and C.CLOSE or C.TXT_G}, 0.15) end)
        return btn, img
    end

    UI.ReloadBtn, UI.ReloadImg = createTopBtn("rbxassetid://7734051957", C.TXT_G, C.TXT_W, 1)
    UI.ConfigBtn, UI.ConfigImg = createTopBtn("rbxassetid://7734053495", C.TXT_G, C.TXT_W, 2)
    UI.CloseBtn = createTopBtn("rbxassetid://7743878857", C.CLOSE, C.TXT_W, 3)

    local contentMask = Utils.Make("Frame", {Size = UDim2.new(1,0,1,-55), Position = UDim2.fromOffset(0,55), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3}, UI.Win)
    UI.MainContent = Utils.Make("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ZIndex = 3}, contentMask)
    UI.SetContent = Utils.Make("Frame", {Size = UDim2.fromScale(1,1), Position = UDim2.fromScale(1,0), BackgroundTransparency = 1, Visible = false, ZIndex = 3}, contentMask)

    local searchBg = Utils.Make("Frame", {Size = UDim2.new(1,-40,0,42), Position = UDim2.fromOffset(20,15), BackgroundColor3 = C.PANEL, ZIndex = 4}, UI.MainContent)
    Utils.Make("UICorner", {CornerRadius = UDim.new(0,21)}, searchBg)
    local searchStroke = Utils.Make("UIStroke", {Color = C.BORDER, Thickness = 1.5}, searchBg)
    Utils.Make("ImageLabel", {Size = UDim2.fromOffset(18,18), Position = UDim2.new(0,16,0.5,-9), BackgroundTransparency = 1, Image = "rbxassetid://7734052925", ImageColor3 = C.TXT_G, ZIndex = 5}, searchBg)
    UI.SearchBox = Utils.Make("TextBox", {Size = UDim2.new(1,-50,1,0), Position = UDim2.fromOffset(44,0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, Text = "", TextColor3 = C.TXT_W, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 5}, searchBg)
    i18n.Bind(UI.SearchBox, "search", true)

    UI.SearchBox.Focused:Connect(function() Utils.Tween(searchStroke, {Color = C.ACCENT}, 0.2) end)
    UI.SearchBox.FocusLost:Connect(function() Utils.Tween(searchStroke, {Color = C.BORDER}, 0.2) end)

    UI.Scroll = Utils.Make("ScrollingFrame", {Size = UDim2.new(1,-20,1,-80), Position = UDim2.fromOffset(10,70), ScrollingDirection = Enum.ScrollingDirection.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.BORDER, ZIndex = 4}, UI.MainContent)
    Utils.Make("UIPadding", {PaddingRight = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingTop = UDim.new(0,5)}, UI.Scroll)
    UI.Grid = Utils.Make("UIGridLayout", {CellSize = UDim2.fromOffset(70,88), CellPadding = UDim2.fromOffset(12,12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, UI.Scroll)
    UI.Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() UI.Scroll.CanvasSize = UDim2.new(0, 0, 0, UI.Grid.AbsoluteContentSize.Y + 20) end)

    local setLbl = Utils.Make("TextLabel", {Size = UDim2.new(1,-40,0,30), Position = UDim2.fromOffset(20,20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.TXT_W, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4}, UI.SetContent)
    i18n.Bind(setLbl, "settings")

    local setScroll = Utils.Make("ScrollingFrame", {Size = UDim2.new(1,-20,1,-70), Position = UDim2.fromOffset(10,60), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ZIndex = 4}, UI.SetContent)
    local setList = Utils.Make("UIListLayout", {Padding = UDim.new(0,10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, setScroll)
    setList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() setScroll.CanvasSize = UDim2.new(0, 0, 0, setList.AbsoluteContentSize.Y + 20) end)

    local function getFormats() return {"rbxassetid://ID", i18n.Get("idOnly"), '"rbxassetid://ID"'} end
    local function getSizes() return {i18n.Get("small"), i18n.Get("medium"), i18n.Get("large")} end

    Components.CreateDrop(setScroll, "language", function() return i18n.LANG_NAMES end, "LangIndex", 0, function() i18n.UpdateUI(); Controllers.RenderFilter() end)
    Components.CreateDrop(setScroll, "library", function() return State.LIB_NAMES end, "LibIndex", 1, App.TriggerReload)
    Components.CreateDrop(setScroll, "copyFormat", getFormats, "FormatIndex", 2)
    Components.CreateDrop(setScroll, "iconSize", getSizes, "SizeIndex", 3, function() Controllers.UpdateGrid(); Controllers.RenderFilter() end)
    Components.CreateToggle(setScroll, "notifyCopy", "Notify", 4)
    Components.CreateToggle(setScroll, "secureCopy", "SecureCopy", 5)
    Components.CreateToggle(setScroll, "closeCopy", "CloseOnCopy", 6)

    App.BindEvents(top)
    
    encryptNames(sg)
    return true
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function App.TriggerReload()
    if App.IsReloading then return end
    App.IsReloading = true
    State.IsLoading = false 
    
    local rot = 0 
    local rsc = Utils.Services.RunService.RenderStepped:Connect(function(dt) 
        rot = rot + (dt * 360) 
        State.ActiveUI.ReloadImg.Rotation = rot 
    end)
    
    Utils.Tween(State.ActiveUI.ReloadImg, {ImageColor3 = State.C.ACCENT}, 0.2)
    
    task.spawn(function()
        Controllers.LoadData()
        rsc:Disconnect()
        State.ActiveUI.ReloadImg.Rotation = 0
        Utils.Tween(State.ActiveUI.ReloadImg, {ImageColor3 = State.C.TXT_G}, 0.3)
        App.IsReloading = false
    end)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function App.BindEvents(topbar)
    local UI = State.ActiveUI
    local inSet = false
    
    UI.ConfigBtn.MouseButton1Click:Connect(function()
        inSet = not inSet
        Utils.Tween(UI.ConfigImg, {Rotation = inSet and 90 or 0}, 0.4)
        if inSet then UI.SetContent.Visible = true end
        Utils.Tween(UI.MainContent, {Position = UDim2.fromScale(inSet and -1 or 0, 0)}, 0.5)
        Utils.Tween(UI.SetContent, {Position = UDim2.fromScale(inSet and 0 or 1, 0)}, 0.5).Completed:Once(function() if not inSet then UI.SetContent.Visible = false end end)
    end)

    UI.CloseBtn.MouseButton1Click:Connect(function()
        Utils.Tween(UI.Win, {Size = UDim2.fromScale(0,0)}, 0.4); Utils.Tween(UI.WinStroke, {Transparency = 1}, 0.3); Utils.Tween(UI.Overlay, {BackgroundTransparency = 1}, 0.4)
        task.delay(0.4, function() 
            if UI.ScreenGui then UI.ScreenGui:Destroy() end 
        end)
    end)

    UI.ReloadBtn.MouseButton1Click:Connect(App.TriggerReload)

    local searchThread = nil
    UI.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchThread then task.cancel(searchThread) end
        searchThread = task.delay(0.25, function()
            Controllers.RenderFilter()
        end)
    end)

    local drag, dStart, sPos
    topbar.InputBegan:Connect(function(i) if i.UserInputType.Name:find("Mouse") or i.UserInputType.Name:find("Touch") then drag = true; dStart = i.Position; sPos = UI.Win.Position end end)
    topbar.InputEnded:Connect(function(i) if i.UserInputType.Name:find("Mouse") or i.UserInputType.Name:find("Touch") then drag = false end end)
    Utils.Services.UserInputService.InputChanged:Connect(function(i) 
        if drag and (i.UserInputType.Name == "MouseMovement" or i.UserInputType.Name == "Touch") then
            Utils.Tween(UI.Win, {Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + (i.Position - dStart).X, sPos.Y.Scale, sPos.Y.Offset + (i.Position - dStart).Y)}, 0.1)
        end 
    end)
end

--<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--

function App.Init()
    local success = App.BuildUI()
    if not success then return end 
    
    Utils.Tween(State.ActiveUI.Win, {Size = UDim2.fromScale(0.85, 0.85)}, 1.6)
    Utils.Tween(State.ActiveUI.WinStroke, {Transparency = 0}, 1.2)
    task.spawn(Controllers.LoadData)
end

--<>---<>---<>---<>---<>---<>---<>---<>---<>--

App.Init()

--[[ --<>---<>---<>---<>---<LICENSED CODE>---<>---<>---<>---<>--
===========================================================================
                            ICONS LIB FRAMEWORK
===========================================================================
  • Author: Liver zMods
  • Development: Created with the aid of Artificial Intelligence (IA).
  • License: CC BY-NC 4.0 (Creative Commons Attribution-NonCommercial 4.0)
             This code is open for modification and free distribution. 
             Commercial use or selling is STRICTLY PROHIBITED. 
             Original credits must be kept intact.
             More info: https://creativecommons.org/licenses/by-nc/4.0/
===========================================================================
]]
