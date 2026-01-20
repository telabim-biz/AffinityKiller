-- AffinityKiller - 1.12/Turtle addon to target specific NPCs and cast configured spells
-- Macro: /ak  (press repeatedly)
-- Config dialog: /ak config (with per-NPC checkboxes)
-- Reset: /ak reset
-- Help: /ak help
-- Toggle debug: /akdebug

-- Defensive SavedVariables init
if not AffinityKillerDB then AffinityKillerDB = {} end

local function ensureDB()
    if not AffinityKillerDB then AffinityKillerDB = {} end
    if not AffinityKillerDB.spells then AffinityKillerDB.spells = {} end
    if not AffinityKillerDB.enabled then AffinityKillerDB.enabled = {} end
end

local AK = {}
AK.names = {
    "Black Affinity",
    "Blue Affinity",
    "Crystal Affinity",
    "Green Affinity",
    "Mana Affinity",
    "Red Affinity",
    "Manascale Ley-Seeker"
}

local DEBUG = false

local function dprint(msg)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AffinityKiller]|r " .. tostring(msg))
    end
end

local function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AffinityKiller]|r " .. tostring(msg))
end

local function isTrackedName(name)
    for i=1, table.getn(AK.names) do
        if AK.names[i] == name then return true end
    end
    return false
end

local function isNameEnabled(name)
    ensureDB()
    local en = AffinityKillerDB.enabled[name]
    -- Treat nil as enabled by default for convenience
    return en == nil or en == true or en == 1
end

local function hasSpell(name)
    ensureDB()
    local s = AffinityKillerDB.spells[name]
    return s ~= nil and s ~= ""
end

local function currentTargetName()
    local n = UnitName and UnitName("target") or nil
    return n
end

local function castForName(name)
    ensureDB()
    local spell = AffinityKillerDB.spells[name]
    if not spell or spell == "" then
        -- Per user request: if no spell, do nothing (no print). Target-only behavior handled in runOnce.
        return false
    end
    dprint("Casting '" .. spell .. "' on '" .. name .. "'")
    CastSpellByName(spell)
    return true
end

local function tryTargetExact(name)
    if not TargetByName then
        chat("TargetByName not available on this client.")
        return false
    end
    dprint("Attempting to target '" .. name .. "'")
    TargetByName(name, true) -- exact match
    local ct = currentTargetName()
    dprint("Current target after TargetByName: " .. tostring(ct))
    return ct == name
end

local function runOnce()
    ensureDB()
    local acted = false

    -- Precompute if any NPC is enabled
    local anyEnabled = false
    for i=1, table.getn(AK.names) do
        if isNameEnabled(AK.names[i]) then
            anyEnabled = true
            break
        end
    end

    -- If current target is one of our names and enabled:
    local ct = currentTargetName()
    if ct and isTrackedName(ct) and isNameEnabled(ct) then
        dprint("Current target is tracked and enabled: " .. ct)
        if hasSpell(ct) then
            if castForName(ct) then acted = true; return end
        else
            -- No spell configured: target-only behavior; do nothing else and no prints
            acted = true
            return
        end
    end

    -- Otherwise, try to target each enabled name in order
    for i=1, table.getn(AK.names) do
        local name = AK.names[i]
        if isNameEnabled(name) then
            if tryTargetExact(name) then
                if hasSpell(name) then
                    if castForName(name) then acted = true; return end
                else
                    -- Found and targeted, but no spell configured: stop here without printing
                    acted = true
                    return
                end
            end
        end
    end

    -- Fallback messaging only if we did not act at all
    if not acted then
        if not anyEnabled then
            chat("No NPCs enabled. Use /ak config to enable and set spells.")
        else
            chat("No enabled NPC found nearby. Use /ak config to review settings.")
        end
    end
end

-- Config UI (with scrollframe and per-NPC checkbox)
local cfg = CreateFrame("Frame", "AffinityKillerConfigFrame", UIParent)
cfg:SetWidth(420)
cfg:SetHeight(320)
cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", function() if this:IsMovable() then this:StartMoving() end end)
cfg:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
cfg:Hide()

cfg.bg = cfg:CreateTexture(nil, "BACKGROUND")
cfg.bg:SetAllPoints(cfg)
cfg.bg:SetTexture(0, 0, 0, 0.7)

cfg.title = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cfg.title:SetPoint("TOP", cfg, "TOP", 0, -10)
cfg.title:SetText("AffinityKiller Configuration")

cfg.tip = cfg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cfg.tip:SetPoint("TOP", cfg.title, "BOTTOM", 0, -6)
cfg.tip:SetText("Check NPCs to target, and enter the exact spell to cast (you may include Rank).")

-- ScrollFrame area
local scroll = CreateFrame("ScrollFrame", "AffinityKillerScrollFrame", cfg, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", cfg, "TOPLEFT", 12, -58)
scroll:SetPoint("TOPRIGHT", cfg, "TOPRIGHT", -32, -58)   -- leave room for scrollbar
scroll:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 12, 50) -- above the buttons

-- ScrollChild (content container)
local content = CreateFrame("Frame", "AffinityKillerScrollChild", scroll)
content:SetWidth( scroll:GetWidth() )
content:SetHeight(200)
scroll:SetScrollChild(content)

cfg.checks = {}
cfg.labels = {}
cfg.edits = {}

local startY = -6
local rowHeight = 48

local function buildRows()
    -- Hide old, if any
    for i=1, table.getn(cfg.checks) do if cfg.checks[i] then cfg.checks[i]:Hide() end end
    for i=1, table.getn(cfg.labels) do if cfg.labels[i] then cfg.labels[i]:Hide() end end
    for i=1, table.getn(cfg.edits) do if cfg.edits[i] then cfg.edits[i]:Hide() end end
    cfg.checks = {}
    cfg.labels = {}
    cfg.edits = {}

    for i=1, table.getn(AK.names) do
        local y = startY - (i-1)*rowHeight

        -- Checkbox (UICheckButtonTemplate exists on 1.12)
        local chk = CreateFrame("CheckButton", "AffinityKillerCheck"..i, content, "UICheckButtonTemplate")
        chk:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
        cfg.checks[i] = chk

        -- Label to the right of the checkbox
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", chk, "RIGHT", 6, 0)
        label:SetText(AK.names[i])
        cfg.labels[i] = label

        -- Edit box below the label
        local edit = CreateFrame("EditBox", "AffinityKillerEdit"..i, content, "InputBoxTemplate")
        edit:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
        edit:SetWidth(320)
        edit:SetHeight(20)
        edit:SetAutoFocus(false)
        edit:SetFontObject(GameFontHighlightSmall)
        edit:SetScript("OnEnterPressed", function() this:ClearFocus() end)
        edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        cfg.edits[i] = edit
    end

    local totalHeight = (-startY) + (table.getn(AK.names) * rowHeight) + 12
    content:SetHeight(totalHeight)
end

-- Buttons
local saveBtn = CreateFrame("Button", "AffinityKillerSaveButton", cfg, "UIPanelButtonTemplate")
saveBtn:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 12, 12)
saveBtn:SetWidth(100)
saveBtn:SetHeight(22)
saveBtn:SetText("Save")
saveBtn:SetScript("OnClick", function()
    ensureDB()
    for i=1, table.getn(AK.names) do
        local name = AK.names[i]
        local txt = cfg.edits[i]:GetText() or ""
        if txt ~= "" then
            AffinityKillerDB.spells[name] = txt
        else
            AffinityKillerDB.spells[name] = nil
        end
        local c = cfg.checks[i]:GetChecked() -- 1 or nil in 1.12
        AffinityKillerDB.enabled[name] = (c and true or false)
    end
    chat("AffinityKiller: configuration saved.")
end)

local closeBtn = CreateFrame("Button", "AffinityKillerCloseButton", cfg, "UIPanelButtonTemplate")
closeBtn:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -12, 12)
closeBtn:SetWidth(100)
closeBtn:SetHeight(22)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() cfg:Hide() end)

local function populateConfig()
    ensureDB()
    buildRows()
    for i=1, table.getn(AK.names) do
        local name = AK.names[i]
        local val = AffinityKillerDB.spells[name] or ""
        local en = AffinityKillerDB.enabled[name]
        -- default enabled if nil
        cfg.edits[i]:SetText(val)
        if en == nil then
            cfg.checks[i]:SetChecked(1)
        else
            cfg.checks[i]:SetChecked(en and 1 or nil)
        end
    end
    -- Update content width to match current scroll width
    local w = scroll:GetWidth()
    content:SetWidth(w)
end

-- Utility: get first word using string.find (Lua 5.0-safe)
local function getFirstWord(s)
    local _, _, w = string.find(s or "", "^%s*(%S+)")
    return string.lower(w or "")
end

-- Slash commands
SLASH_AFFINITYKILLER1 = "/ak"
SlashCmdList["AFFINITYKILLER"] = function(msg)
    local cmd = getFirstWord(msg)

    if cmd == "" then
        runOnce()
        return
    end

    if cmd == "config" then
        populateConfig()
        cfg:Show()
        return
    end

    if cmd == "reset" then
        ensureDB()
        AffinityKillerDB.spells = {}
        chat("Cleared all configured spells. Enable NPCs and set spells via /ak config.")
        return
    end

    if cmd == "show" then
        ensureDB()
        chat("Configured spells (checkbox indicates enabled):")
        for i=1, table.getn(AK.names) do
            local n = AK.names[i]
            local s = AffinityKillerDB.spells[n] or "(not set)"
            local en = AffinityKillerDB.enabled[n]
            local flag = (en == nil or en == true or en == 1) and "[x]" or "[ ]"
            chat(" "..flag.." "..n..": "..s)
        end
        return
    end

    if cmd == "help" then
        chat("Usage: /ak            -> target & cast (use in a macro)")
        chat("       /ak config     -> open configuration dialog (checkbox per NPC)")
        chat("       /ak reset      -> clear all spell mappings")
        chat("       /ak show       -> list current mappings and enabled status")
        chat("       /akdebug       -> toggle debug prints")
        return
    end

    -- Unknown subcommand: default to runOnce for convenience
    runOnce()
end

SLASH_AFFINITYKILLERDEBUG1 = "/akdebug"
SlashCmdList["AFFINITYKILLERDEBUG"] = function()
    DEBUG = not DEBUG
    chat("Debug = "..(DEBUG and "ON" or "OFF"))
end

-- Init
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        ensureDB()
        chat("AffinityKiller loaded. Use /ak config to enable NPCs and set spells, then /ak in a macro.")
    end
end)
