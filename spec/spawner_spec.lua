package.path = "./?.lua;" .. package.path
local Config = require("src.config")
local Spawner = require("src.spawner")

local function config(overrides)
  local c = Config.defaults()
  for k, v in pairs(overrides or {}) do c[k] = v end
  return c
end

describe("Spawner.plan_for_ante", function()
  it("spawns the configured joker every ante by default", function()
    local plan = Spawner.plan_for_ante(config(), 4)
    assert.are.equal(1, #plan)
    assert.are.equal("j_joker", plan[1].key)
    assert.is_nil(plan[1].edition)
  end)

  it("spawns nothing when disabled", function()
    assert.are.equal(0, #Spawner.plan_for_ante(config({ enabled = false }), 3))
  end)

  it("spawns one card per configured copy", function()
    local plan = Spawner.plan_for_ante(config({ copies = 3, joker = "j_blueprint" }), 2)
    assert.are.equal(3, #plan)
    assert.are.equal("j_blueprint", plan[3].key)
  end)

  it("honours the ante cadence, anchored on ante 1", function()
    local c = config({ every_n_antes = 3 })
    assert.are.equal(1, #Spawner.plan_for_ante(c, 1))
    assert.are.equal(0, #Spawner.plan_for_ante(c, 2))
    assert.are.equal(0, #Spawner.plan_for_ante(c, 3))
    assert.are.equal(1, #Spawner.plan_for_ante(c, 4))
    assert.are.equal(1, #Spawner.plan_for_ante(c, 7))
  end)

  it("ignores antes below the first one", function()
    assert.are.equal(0, #Spawner.plan_for_ante(config(), 0))
  end)

  it("spawns nothing when no joker is picked", function()
    assert.are.equal(0, #Spawner.plan_for_ante(config({ joker = "none" }), 2))
  end)

  it("passes a forced edition through", function()
    local plan = Spawner.plan_for_ante(config({ edition = "e_negative" }), 2)
    assert.are.equal("e_negative", plan[1].edition)
  end)

  it("rolls a random edition per card", function()
    local rolls, i = { 3, 1 }, 0
    local rng = function(n)
      i = i + 1
      assert.are.equal(#Spawner.RANDOM_EDITIONS, n)
      return rolls[i]
    end
    local plan = Spawner.plan_for_ante(config({ edition = "random", copies = 2 }), 2, rng)
    assert.are.equal(Spawner.RANDOM_EDITIONS[3], plan[1].edition)
    assert.are.equal(Spawner.RANDOM_EDITIONS[1], plan[2].edition)
  end)
end)

describe("Spawner.plan_for_run_start", function()
  it("adds the starting jokers before the ante 1 spawn", function()
    local c = config({ joker = "j_blueprint" })
    c.starting_jokers[1] = { joker = "j_brainstorm", edition = "e_holo" }
    c.starting_jokers[3] = { joker = "j_mime", edition = "none" }

    local plan = Spawner.plan_for_run_start(c)
    assert.are.equal(3, #plan)
    assert.are.same({ key = "j_brainstorm", edition = "e_holo" }, plan[1])
    assert.are.same({ key = "j_mime" }, plan[2])
    assert.are.equal("j_blueprint", plan[3].key)
  end)

  it("skips the ante 1 spawn when disabled", function()
    local c = config({ spawn_on_run_start = false })
    c.starting_jokers[1] = { joker = "j_mime", edition = "none" }
    local plan = Spawner.plan_for_run_start(c)
    assert.are.equal(1, #plan)
    assert.are.equal("j_mime", plan[1].key)
  end)

  it("still adds starting jokers when the mod is disabled", function()
    local c = config({ enabled = false })
    c.starting_jokers[2] = { joker = "j_mime", edition = "e_foil" }
    local plan = Spawner.plan_for_run_start(c)
    assert.are.same({ { key = "j_mime", edition = "e_foil" } }, plan)
  end)
end)

describe("Spawner.slot_limit", function()
  it("leaves the run's limit alone when capping is off", function()
    assert.is_nil(Spawner.slot_limit(config({ cap_slots = false }), 3))
  end)

  it("caps the limit to the number of jokers the mod has spawned", function()
    assert.are.equal(3, Spawner.slot_limit(config({ cap_slots = true }), 3))
  end)

  it("keeps at least one slot", function()
    assert.are.equal(1, Spawner.slot_limit(config({ cap_slots = true }), 0))
  end)
end)
