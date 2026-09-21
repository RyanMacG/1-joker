local Spawner = {}

local NONE = "none"

Spawner.RANDOM_EDITIONS = { "e_foil", "e_holo", "e_polychrome" }

local function edition_for(edition, rng)
  if edition == nil or edition == NONE then return nil end
  if edition == "random" then
    rng = rng or math.random
    function Spawner.slot_limit(config, spawned_count, negative_count)
  if not config.cap_slots then return nil end
  return math.max(1, spawned_count or 0) + (negative_count or 0)
end

function Spawner.slot_consuming(plan)
  local count = 0
  for _, card in ipairs(plan) do
    if card.edition ~= "e_negative" then count = count + 1 end
  end
  return count
end

return Spawner.RANDOM_EDITIONS[rng(#Spawner.RANDOM_EDITIONS)]
  end
  return edition
end

local function spawns_on_ante(config, ante)
  if not config.enabled or config.joker == NONE then return false end
  if type(ante) ~= "number" or ante < 1 then return false end
  return (ante - 1) % config.every_n_antes == 0
end

function Spawner.plan_for_ante(config, ante, rng)
  local plan = {}
  if not spawns_on_ante(config, ante) then return plan end
  for _ = 1, config.copies do
    plan[#plan + 1] = { key = config.joker, edition = edition_for(config.edition, rng) }
  end
  return plan
end

function Spawner.plan_for_run_start(config, rng)
  local plan = {}
  for _, slot in ipairs(config.starting_jokers or {}) do
    if slot.joker and slot.joker ~= NONE then
      plan[#plan + 1] = { key = slot.joker, edition = edition_for(slot.edition, rng) }
    end
  end
  if config.spawn_on_run_start then
    for _, card in ipairs(Spawner.plan_for_ante(config, 1, rng)) do
      plan[#plan + 1] = card
    end
  end
  return plan
end

function Spawner.slot_limit(config, spawned_count, negative_count)
  if not config.cap_slots then return nil end
  return math.max(1, spawned_count or 0) + (negative_count or 0)
end

function Spawner.slot_consuming(plan)
  local count = 0
  for _, card in ipairs(plan) do
    if card.edition ~= "e_negative" then count = count + 1 end
  end
  return count
end

return Spawner
