-- MiniMapSize：调整小地图大小
-- 做法：整体缩放 MinimapCluster（边框、按钮、时钟一起等比变化，不会错位）
-- 检测到 NDui 在管小地图时自动让位（避免双重缩放），可在设置里强制覆盖
-- 设置入口：界面设置 → 插件 → 小地图尺寸
-- 命令：/mms 180   /mms reset   /mms status

local ADDON = "MiniMapSize"
local ADDON_VERSION = "1.1.0"
local ADDON_AUTHOR = "火药"
local DEFAULT_SIZE = 140
local MIN_SIZE = 80
local MAX_SIZE = 320
local STEP = 5

local db

local function EnsureDB()
    if type(MiniMapSizeDB) ~= "table" then
        MiniMapSizeDB = {}
    end
    db = MiniMapSizeDB
    if type(db.size) ~= "number" then
        db.size = DEFAULT_SIZE
    end
    if db.force == nil then
        db.force = false
    end
    if db.size < MIN_SIZE then db.size = MIN_SIZE end
    if db.size > MAX_SIZE then db.size = MAX_SIZE end
end

local function Clamp(v)
    v = tonumber(v) or DEFAULT_SIZE
    if v < MIN_SIZE then return MIN_SIZE end
    if v > MAX_SIZE then return MAX_SIZE end
    return v
end

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0MiniMapSize|r " .. tostring(msg))
end

local function AddonLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    if IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

-- NDui 是否在接管小地图（它会 Minimap:SetSize + Minimap:SetScale）
local function NDuiOwnsMinimap()
    if not AddonLoaded("NDui") then
        return false
    end
    local adb = _G.NDuiADB
    if type(adb) == "table" then
        local map = adb["Map"]
        if type(map) == "table" then
            return map["DisableMinimap"] ~= true
        end
    end
    return true
end

-- 应用尺寸：返回方式和缩放，便于排查
local function ApplySize(size)
    EnsureDB()
    size = Clamp(size)
    db.size = size

    if NDuiOwnsMinimap() and not db.force then
        if MinimapCluster and MinimapCluster.SetScale then
            MinimapCluster:SetScale(1)
        end
        return "ndui", 1
    end

    local scale = size / DEFAULT_SIZE
    if MinimapCluster and MinimapCluster.SetScale then
        MinimapCluster:SetScale(scale)
        return "MinimapCluster", scale
    elseif Minimap and Minimap.SetScale then
        Minimap:SetScale(scale)
        return "Minimap", scale
    end
    return nil, scale
end

-- ---------------- 设置界面（新版 Settings API） ----------------
local function SetupSettings()
    EnsureDB()
    local S = _G.Settings
    if not S or not S.RegisterVerticalLayoutCategory then
        return false
    end

    local ok = pcall(function()
        local category = S.RegisterVerticalLayoutCategory("小地图尺寸")

        local sizeSetting = S.RegisterAddOnSetting(category, ADDON .. "_size", "size",
            db, "number", "小地图大小", DEFAULT_SIZE)
        if sizeSetting and sizeSetting.SetValueChangedCallback then
            sizeSetting:SetValueChangedCallback(function(_, value)
                ApplySize(value)
            end)
        end

        local sliderOptions = S.CreateSliderOptions(MIN_SIZE, MAX_SIZE, STEP)
        local label = _G.MinimalSliderWithSteppersMixin
            and _G.MinimalSliderWithSteppersMixin.Label
            and _G.MinimalSliderWithSteppersMixin.Label.Right
        if label then
            sliderOptions:SetLabelFormatter(label)
        end
        S.CreateSlider(category, sizeSetting, sliderOptions,
            "小地图整体大小，默认 140。若装了 NDui，NDui 的小地图接管时本项不生效（见下一项）。")

        local forceSetting = S.RegisterAddOnSetting(category, ADDON .. "_force", "force",
            db, "boolean", "强制使用本插件（忽略 NDui）", false)
        if forceSetting and forceSetting.SetValueChangedCallback then
            forceSetting:SetValueChangedCallback(function(_, value)
                db.force = value and true or false
                ApplySize(db.size)
            end)
        end
        S.CreateCheckbox(category, forceSetting,
            "NDui 自带「地图 → 小地图尺寸」，两者同时生效会叠加缩放。默认让位给 NDui；勾选后才用本插件。")

        S.RegisterAddOnCategory(category)
    end)

    return ok
end

-- ---------------- 事件 ----------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

local announced = false

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        EnsureDB()
        ApplySize(db.size)
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        local how = ApplySize(db.size)
        SetupSettings()
        Print(string.format("v%s by %s 已加载 · 尺寸 %d · 方式 %s",
            ADDON_VERSION, ADDON_AUTHOR, db.size, tostring(how)))
        if how == "ndui" and not announced then
            announced = true
            Print("检测到 NDui 在接管小地图，本插件已让位。调整请去 NDui → 地图 → 小地图尺寸；"
                .. "要用本插件请到「界面设置 → 插件 → 小地图尺寸」勾选强制。")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ApplySize(db.size)
    end
end)

-- ---------------- 命令 ----------------
SLASH_MINIMAPSIZE1 = "/mms"
SLASH_MINIMAPSIZE2 = "/mmsize"
SlashCmdList["MINIMAPSIZE"] = function(msg)
    EnsureDB()
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lower = msg:lower()

    if lower == "status" then
        local how, scale = ApplySize(db.size)
        Print(string.format("v%s by %s · 尺寸 %d · 方式 %s · 缩放 %.2f · NDui接管 %s · 强制 %s",
            ADDON_VERSION, ADDON_AUTHOR, db.size, tostring(how), scale or 0,
            tostring(NDuiOwnsMinimap()), tostring(db.force)))
        return
    end

    if lower == "" then
        local how, scale = ApplySize(db.size)
        Print(string.format("v%s by %s · 当前 %d（方式 %s，缩放 %.2f）· 用法：/mms 180 · /mms reset · /mms status",
            ADDON_VERSION, ADDON_AUTHOR, db.size, tostring(how), scale or 0))
        return
    end

    if lower == "version" or lower == "版本" then
        Print(string.format("v%s · 作者 %s", ADDON_VERSION, ADDON_AUTHOR))
        return
    end

    if lower == "reset" or lower == "默认" then
        MiniMapSizeDB.size = DEFAULT_SIZE
        ApplySize(DEFAULT_SIZE)
        Print("已恢复默认 " .. tostring(DEFAULT_SIZE))
        return
    end

    if lower == "force" then
        MiniMapSizeDB.force = not MiniMapSizeDB.force
        ApplySize(db.size)
        Print("强制模式：" .. tostring(MiniMapSizeDB.force))
        return
    end

    local n = tonumber(msg)
    if not n then
        Print("请输入数字，例如 /mms 180（范围 " .. MIN_SIZE .. "-" .. MAX_SIZE .. "）")
        return
    end

    local how, scale = ApplySize(n)
    if how then
        Print(string.format("已设为 %d（方式 %s，缩放 %.2f）", Clamp(n), how, scale))
    else
        Print("没找到小地图对象，调整失败")
    end
end
