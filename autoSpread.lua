local database = require("database")
local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local action = require("action")
local config = require("config")
local config = require("tasks")


local args = {...}

local function init()
    database.scanFarm()
    local multifarmPos = {}
    if #args == 2 then
        multifarmPos[1] = tonumber(args[1])
        multifarmPos[2] = tonumber(args[2])
    end
    if multifarmPos[1] and multifarmPos[2] then
        database.setLastMultifarmPos(multifarmPos)
    else
        database.scanMultifarm()
    end
    action.restockAll()
end

local function main()
    init()
    while not tasks.spreadOnce() do
        gps.go({0, 0})
        action.restockAll()
    end
    gps.go({0,0})
    if #args == 1 and args[1] == "nocleanup" then
        action.destroyAll()
        gps.go({0,0})
    end
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nThe Multifarm is filled up.")
end

main()
