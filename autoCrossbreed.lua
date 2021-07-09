local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")
local tasks = require("tasks")

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
