local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")
local config = require("tasks")

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

local function init()
    database.scanFarm()
    database.scanStorage()
    updateLowest()
    action.restockAll()
end

local function main()
    init()
    while true do
        tasks.breedOnce()
        gps.go({0,0})
        action.restockAll()
    end
end

main()
