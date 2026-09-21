package.path = "./?.lua;" .. package.path
local Config = require("src.config")

local valid = { "j_joker", "j_blueprint", "j_brainstorm" }

describe("Config.defaults", function()
  it("spawns one unedited Joker every ante", function()
    local c = Config.defaults()
    assert.is_true(c.enabled)
    assert.are.equal("j_joker", c.joker)
    assert.are.equal("none", c.edition)
    assert.are.equal(1, c.copies)
    assert.are.equal(1, c.every_n_antes)
    assert.is_true(c.spawn_on_run_start)
    assert.are.equal(Config.STARTING_SLOTS, #c.starting_jokers)
    assert.are.equal("none", c.starting_jokers[1].joker)
  end)

  it("returns a fresh table each call", function()
    local a = Config.defaults()
    a.starting_jokers[1].joker = "j_blueprint"
    assert.are.equal("none", Config.defaults().starting_jokers[1].joker)
  end)
end)

describe("Config.normalize", function()
  it("fills in missing values", function()
    local c = Config.normalize({}, valid)
    assert.are.same(Config.defaults(), c)
  end)

  it("keeps known joker keys", function()
    local c = Config.normalize({ joker = "j_blueprint" }, valid)
    assert.are.equal("j_blueprint", c.joker)
  end)

  it("falls back to the default joker when the key is unknown", function()
    local c = Config.normalize({ joker = "j_not_installed" }, valid)
    assert.are.equal("j_joker", c.joker)
  end)

  it("rejects unknown editions", function()
    assert.are.equal("none", Config.normalize({ edition = "e_glitter" }, valid).edition)
    assert.are.equal("e_negative", Config.normalize({ edition = "e_negative" }, valid).edition)
  end)

  it("clamps copies and cadence to sane ranges", function()
    assert.are.equal(1, Config.normalize({ copies = 0 }, valid).copies)
    assert.are.equal(Config.MAX_COPIES, Config.normalize({ copies = 99 }, valid).copies)
    assert.are.equal(1, Config.normalize({ every_n_antes = -3 }, valid).every_n_antes)
    assert.are.equal(Config.MAX_CADENCE, Config.normalize({ every_n_antes = 50 }, valid).every_n_antes)
    assert.are.equal(2, Config.normalize({ copies = 2.7 }, valid).copies)
  end)

  it("drops starting jokers that are not installed", function()
    local c = Config.normalize({
      starting_jokers = {
        { joker = "j_blueprint", edition = "e_holo" },
        { joker = "j_gone", edition = "e_foil" },
      },
    }, valid)
    assert.are.equal("j_blueprint", c.starting_jokers[1].joker)
    assert.are.equal("e_holo", c.starting_jokers[1].edition)
    assert.are.equal("none", c.starting_jokers[2].joker)
    assert.are.equal(Config.STARTING_SLOTS, #c.starting_jokers)
  end)

  it("never mutates the table it was given", function()
    local raw = { joker = "j_gone", starting_jokers = { { joker = "j_gone" } } }
    Config.normalize(raw, valid)
    assert.are.equal("j_gone", raw.joker)
    assert.are.equal(1, #raw.starting_jokers)
  end)
end)

describe("Config.assign_joker", function()
  it("sets the ante joker when no slot is given", function()
    local c = Config.defaults()
    Config.assign_joker(c, nil, "j_blueprint")
    assert.are.equal("j_blueprint", c.joker)
  end)

  it("sets a starting slot", function()
    local c = Config.defaults()
    Config.assign_joker(c, 2, "j_blueprint")
    assert.are.equal("j_blueprint", c.starting_jokers[2].joker)
    assert.are.equal("none", c.starting_jokers[1].joker)
  end)

  it("clears the edition when a slot is emptied", function()
    local c = Config.defaults()
    c.starting_jokers[1] = { joker = "j_blueprint", edition = "e_foil" }
    Config.assign_joker(c, 1, "none")
    assert.are.equal("none", c.starting_jokers[1].joker)
    assert.are.equal("none", c.starting_jokers[1].edition)
  end)

  it("ignores slots that do not exist", function()
    local c = Config.defaults()
    Config.assign_joker(c, 9, "j_blueprint")
    assert.are.equal(Config.STARTING_SLOTS, #c.starting_jokers)
  end)
end)

describe("Config.truncate", function()
  it("leaves short labels alone", function()
    assert.are.equal("Blueprint", Config.truncate("Blueprint", 12))
  end)

  it("cuts long labels down to the limit, ellipsis included", function()
    assert.are.equal("Gros Michel", Config.truncate("Gros Michel", 11))
    assert.are.equal("Gros M..", Config.truncate("Gros Michel", 8))
    assert.are.equal(11, #Config.truncate("The Idol Of Something", 11))
  end)
end)
