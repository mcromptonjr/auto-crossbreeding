--[[
This Script fills the gaps in the normal farm by continuing the crossing process and only keeping the good crops
Use the 'any' option to keep any crops.
It assumes that you have aleady run autoStat and by default will only keep the same crop type as in crop positon 1 (adjacent to the charger)
]]

local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")
local tasks = require("tasks")

local args = {...}
local nonstop = false
local docleanup = true
local ignorestats = false
if #args == 1 then
    if args[1] == "nocleanup" then
        docleanup = false
    elseif args[1] == "nonstop" then
        nonstop = true
    elseif args[1] == "ignorestats" then
        nonstop = true
    end
end

local function init()
--    database.addToFilled(1)
--    print(database.existsInFilled(1))
--    print("\n")
--    gps.turnTo(1)
    database.scanFarm()
end

local function main()
    gps.turnTo(1)
    print("init\n")
    init()
    gps.go({0,0})
    if (nonstop) then
        print("nonstop...\n")
    end
    repeat
        while not tasks.fillGaps(ignorestats) do
            gps.go({0,0})
        end
        gps.go({0,0})
        if config.takeCareOfDrops then
            action.dumpInventory()
        end
        gps.go({0,0})
        gps.turnTo(1)
        action.destroyAll()
        gps.go({0,0})
        if config.takeCareOfDrops then
            action.dumpInventory()
        end
        gps.go({0,0})
        gps.turnTo(1)
        print("Loop Done.\n")
    until (not nonstop)
end

main()