local addonName, addon = ...
local frame = CreateFrame("Frame")

-- Default settings
local defaults = {
    enabled = false
    interval =
}

local timeSinceLastSwitch = 0
local current tracking = "HERB"
local inCombat = false
local hasHostileTarget = false

local function InitialiseSettings()

    if not MultiTrackDB then
        MultiTrackDB = CopyTable(defaults)
    end

    isEnabled = MultiTrackDB.enabled
    switchInterval = MultiTrackDB.interval

end

local function CheckTargetHostile()

    if UnitExists("target") then
        -- debug
        print("Target exists")
        print("Can attack:", UnitCanAttack("player", "target"))
        print("Is dead:", UnitIsDead("target"))
        
        if UnitCanAttack("player", "target") and not UnitIsDead("target") then
            hasHostileTarget = true
            if isEnabled then
                print("MultiTrack: Paused - hostile target")
            end
        else
            hasHostileTarget = false
        end
    else
        hasHostileTarget = false
    end

end

local function ToggleTracking()

    if inCombat or hasHostileTarget then
        return
    end

    if currentTracking == "HERB" then
        CastSpellByName("Find Minerals")
        currentTracking = "ORE"
        print("MultiTrack: Switched to Mineral tracking")
    else
        CastSpellByName("Find Herbs")
        currentTracking = "HERB"
        print("MultiTrack: Switched to Herb tracking")
    end

end

local function OnUpdate(self, elapsed)

    if not isEnabled then return end

    timeSinceLastSwitch = timeSinceLastSwitch + elapsed

    if timeSinceLastSwitch >= switchInterval then
        ToggleTracking()
        timeSinceLastSwitch = 0
    end

end

local function HandleShashCommands(msg)
    
    local command, arg = strsplit(" ", string.lower(msg), 2)

    if command == "toggle" then
        isEnabled = not isEnabled
        print("MutliTrack: Auto-switching " .. (isEnabled and "enabled" or "disabled"))

    elseif command == "interval" then
        local newInterval = tonumber(arg)

        if newInterval and newInterval >=1 then
            switchInterval = newInterval
            MultiTrackDB.interval = newInterval
            print("MultiTrack: Interval set to " .. newInterval .. " seconds")
        else
            print("MultiTrack: Invalid interval. Please use a number >= 1")
        end

    elseif command == "status" then
        print("Multitrack Status:" .. (isEnabled and "Enabled" or "Disabled"))
        print("Interval switcing at " .. switchInterval .. " seconds")

    else
        print("MutliTrack Commands:")
        print("/mtrack toggle - Enable or Disable auto-switching")
        print("/mtrack interval <seconds> - Set switching interval")
        print("/mtrack status - Show current status")
    end

end

-- Event hooks
frame:UnregisterAllEvents()
frame:SetScript("OnUpdate", OnUpdate)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitialiseSettings()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        if isEnabled then
            print("MultiTrack: Paused due to combat to avoid GCD conflict")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if isEnabled then
            print("MultiTrack: Resuming auto-switching")
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        print("Target changed event fired") -- Debug print
        local wasHostile = hasHostileTarget
        CheckTargetHostile()
        if wasHostile and not hasHostileTarget and isEnabled and not inCombat then
            print("MultiTrack: Resuming auto-switching")
        end
    end

end)

SLASH_MULTITRACK1 = "/mtrack"
SLASH_MULTITRACK2 = "/multitrack"
SlashCmdList["MULTITRACK"] = HandleShashCommands