local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")
local config = require("tasks")


local args = {...}

local function init()
    database.scanFarm()
end

local function main()
    init()
    gps.go({0,0})
    action.destroyAll()
    gps.go({0,0})
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.go({0,0})
    print("Done.\n")
end

main()