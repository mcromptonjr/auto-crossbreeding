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
    if config.keepNewCropWhileMinMaxing then
        database.scanStorage()
    end
    tasks.updateLowest()
    action.restockAll()
end

local function main()
    init()
    while not tasks.breedOnce() do
        gps.go({0,0})
        action.restockAll()
    end
    gps.go({0,0})
    if docleanup then
        action.destroyAll()
        gps.go({0,0})
    end
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nAll crops are now 21/31/0")
end

main()
