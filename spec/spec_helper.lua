-- Global test setup: provide a minimal love mock for modules that expect LÖVE
local helpers = require("spec.helpers.love_mock")

love = love or {}
love.timer = helpers.timer
love.filesystem = helpers.filesystem
