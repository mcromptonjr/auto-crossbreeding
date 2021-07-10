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
if #args == 1 then
    if args[1] == "nocleanup" then
        docleanup = false
    elseif args[1] == "nonstop" then
        nonstop = true
    end
end

local function init()
    database.scanFarm()
end

local function main()
    init()
    gps.go({0,0})
    while not tasks.breedOnce() do
        gps.go({0,0})
        tasks.fillGaps()
    end
    gps.go({0,0})
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    print("Done.\nAll crops are now 21/31/0")
end

main()