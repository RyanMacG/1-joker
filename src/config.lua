local Config = {}

Config.STARTING_SLOTS = 3
Config.MAX_COPIES = 5
Config.MAX_CADENCE = 8
Config.NONE = "none"
Config.EDITIONS = { "none", "e_foil", "e_holo", "e_polychrome", "e_negative", "random" }

local function is_edition(edition)
  for _, key in ipairs(Config.EDITIONS) do
    if key == edition then return true end
  end
  return false
end

local function contains(list, value)
  for _, key in ipairs(list) do
    if key == value then return true end
  end
  return false
end

local function clamp_int(value, min, max, fallback)
  if type(value) ~= "number" then return fallback end
  value = math.floor(value)
  if value < min then return min end
  if value > max then return max end
  return value
end

local function slot(joker, edition)
  return { joker = joker or Config.NONE, edition = edition or Config.NONE }
end

function Config.defaults()
  local starting_jokers = {}
  for _ = 1, Config.STARTING_SLOTS do
    starting_jokers[#starting_jokers + 1] = slot()
  end
  return {
    enabled = true,
    joker = "j_joker",
    edition = Config.NONE,
    copies = 1,
    every_n_antes = 1,
    spawn_on_run_start = true,
    cap_slots = true,
    starting_jokers = starting_jokers,
  }
end

local function known_joker(key, valid_keys, fallback)
  if key == Config.NONE then return key end
  if type(key) == "string" and contains(valid_keys, key) then return key end
  return fallback
end

function Config.normalize(raw, valid_keys)
  raw = raw or {}
  valid_keys = valid_keys or {}
  local defaults = Config.defaults()
  local config = defaults

  if raw.enabled ~= nil then config.enabled = raw.enabled and true or false end
  if raw.spawn_on_run_start ~= nil then
    config.spawn_on_run_start = raw.spawn_on_run_start and true or false
  end
  if raw.cap_slots ~= nil then config.cap_slots = raw.cap_slots and true or false end
  config.joker = known_joker(raw.joker, valid_keys, defaults.joker)
  config.edition = is_edition(raw.edition) and raw.edition or defaults.edition
  config.copies = clamp_int(raw.copies, 1, Config.MAX_COPIES, defaults.copies)
  config.every_n_antes = clamp_int(raw.every_n_antes, 1, Config.MAX_CADENCE, defaults.every_n_antes)

  local raw_slots = type(raw.starting_jokers) == "table" and raw.starting_jokers or {}
  for i = 1, Config.STARTING_SLOTS do
    local raw_slot = type(raw_slots[i]) == "table" and raw_slots[i] or {}
    local joker = known_joker(raw_slot.joker, valid_keys, Config.NONE)
    local edition = is_edition(raw_slot.edition) and raw_slot.edition or Config.NONE
    config.starting_jokers[i] = slot(joker, joker ~= Config.NONE and edition or Config.NONE)
  end

  return config
end

function Config.assign_joker(config, slot, key)
  key = key or Config.NONE
  if not slot then
    config.joker = key
    return config
  end
  local target = config.starting_jokers and config.starting_jokers[slot]
  if not target then return config end
  target.joker = key
  if key == Config.NONE then target.edition = Config.NONE end
  return config
end

function Config.truncate(label, max_length)
  if #label <= max_length then return label end
  return label:sub(1, max_length - 2) .. ".."
end

return Config
