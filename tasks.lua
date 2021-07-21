local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local lowestTier
local lowestTierSlot
local lowestStat
local lowestStatSlot
local nearestReplacableDistance
local nearestReplacableSlot
local fillGaps

local function updateLowest()
    lowestStat = 64
    lowestStatSlot = 0
    local farm = database.getFarm()
    local workingCropName = database.getFarm()[1].name
    for slot=1, config.farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            local stat = crop.gr+crop.ga-crop.re
            if stat < lowestStat then
                lowestStat = stat
                lowestStatSlot = slot
            end
        end
    end

    nearestReplacableSlot = 0
    nearestReplacableDistance = config.farmArea * 2
    for slot=1, config.farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil and crop.name ~= workingCropName then
            local pos = posUtil.farmToGlobal(slot)
            if (pos[1] + pos[2]) < nearestReplacableDistance then
                nearestReplacableDistance = pos[1] + pos[2]
                nearestReplacableSlot = slot
            end
        end
    end
end

--[[
This came from autoCrossBred, needs to be renamed or something lated

local function findSuitableFarmSlot(crop)
    -- if the return value > 0, then it's a valid crop slot
    -- if the return value == 0, then it's not a valid crop slot
    --     the caller may consider not to replace any crop.
    if crop.tier > lowestTier then
        return lowestTierSlot
    elseif crop.tier == lowestTier then
        if crop.gr+crop.ga-crop.re > lowestStat then
            return lowestStatSlot
        end
    end
    return 0
end
]]

local function findSuitableFarmSlot(crop)
    if nearestReplacableSlot ~= 0 then
        return nearestReplacableSlot
    elseif crop.gr+crop.ga-crop.re > lowestStat then
        return lowestStatSlot
    else
        return 0
    end
end

local function breedOnce(nonstop)
    -- return true if all stats are maxed out
    -- 52 = 21(max gr) + 31(max ga) - 0 (min re)
    if lowestStat == 52 then
        if nonstop == false then
            return true
        end
    end

    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.placeCropStick(2)
        elseif (not config.assumeNoBareStick) and crop.name == "crop" then
            action.placeCropStick()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 21 or crop.re > 0 or
              (crop.name == "venomilia" and crop.gr > 7) then
                action.deweed()
                action.placeCropStick()
            elseif crop.name == database.getFarm()[1].name then
                local suitableSlot = findSuitableFarmSlot(crop)
                if suitableSlot == 0 then
                    action.deweed()
                    action.placeCropStick()
                else
                    action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                    action.placeCropStick(2)
                    database.updateFarm(suitableSlot, crop)
                    updateLowest()
                end
            elseif config.keepNewCropWhileMinMaxing and (not database.existInStorage(crop)) then
                action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()))
                action.placeCropStick(2)
                database.addToStorage(crop)
            else
                action.deweed()
                action.placeCropStick()
            end
        end
        if action.needCharge() then
            action.charge()
        end
    end
    return false
end

local function spreadOnce()
    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.placeCropStick(2)
        elseif (not config.assumeNoBareStick) and crop.name == "crop" then
            action.placeCropStick()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 23 or
              (crop.name == "venomilia" and crop.gr > 7) then
                action.deweed()
                action.placeCropStick()
            elseif crop.name == database.getFarm()[1].name and
                  (not config.bestStatWhileSpreading or (crop.gr >= 21 and crop.ga == 31 and crop.re == 0)) then
                local nextMultifarmPos = database.nextMultifarmPos()
                if nextMultifarmPos then
                    action.transplantToMultifarm(posUtil.farmToGlobal(slot), nextMultifarmPos)
                    action.placeCropStick(2)
                    database.updateMultifarm(nextMultifarmPos)
                else
                    return true
                end
            else
                action.deweed()
                action.placeCropStick()
            end
        end
        if action.needCharge() then
            action.charge()
        end
    end
    return false
end

local function fillGaps(ignorestats)
    -- return true if all the gaps have been filled
    print("fillGaps called\n")

    if ignorestats then
        print("ingnorestats = true\n")
    else
        print("ingnorestats = false\n")
    end

    local fillResult = true
    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        print("crop="..slot..", name=`"..crop.name.."`\n")
        if crop.name == "air" then
            action.placeCropStick(2)
            fillResult = false
                print("Crop = air\n")
        elseif (not config.assumeNoBareStick) and crop.name == "crop" then
            action.placeCropStick()
            fillResult = false
                print("Crop = empty\n")
        elseif crop.isCrop then
            if crop.name == "weed" or
              (crop.name == "venomilia" and crop.gr > 7) then
                action.deweed()
                action.placeCropStick()
                fillResult = false
                    print("Crop = weed\n")
            elseif (not ignorestats and ( crop.ga ~= 31 or crop.re ~= 0 or crop.gr ~= 21 )) or
                (ignorestats and (crop.gr > 21 )) then
                action.decrop()
                action.placeCropStick()
                action.placeCropStick()
                fillResult = false
                    print("Crop = wrong stats\n")
            elseif crop.name == database.getFarm()[1].name then
                database.addToFilled(slot)
                local ignoreMe = true
                    print("Crop = matched\n")
            else
                action.deweed()
                action.placeCropStick()
                fillResult = false
                print("Crop = unknown\n")
            end
        end
        if action.needCharge() then
            action.charge()
        end
    end
    print("fillResult=")
    print(fillResult)
    print("\n")
    return fillResult
end


return {
    spreadOnce = spreadOnce,
    breedOnce = breedOnce,
    updateLowest = updateLowest,
    fillGaps = fillGaps
}