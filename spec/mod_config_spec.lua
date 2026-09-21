package.path = "./?.lua;" .. package.path
local Config = require("src.config")

describe("config.lua", function()
  it("matches the module defaults Steamodded will normalize against", function()
    assert.are.same(Config.defaults(), dofile("config.lua"))
  end)
end)
