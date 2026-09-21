local mod = SMODS.current_mod
local Config = assert(SMODS.load_file("src/config.lua"))()
local Spawner = assert(SMODS.load_file("src/spawner.lua"))()

local EDITION_LABELS = {
  none = "None",
  e_foil = "Foil",
  e_holo = "Holographic",
  e_polychrome = "Polychrome",
  e_negative = "Negative",
  random = "Random",
}

local joker_options = {}

local function installed_joker_keys()
  local keys = {}
  for _, center in ipairs(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker or {}) do
    keys[#keys + 1] = center.key
  end
  return keys
end

local function joker_label(key)
  if key == Config.NONE then return "None" end
  local ok, name = pcall(localize, { type = "name_text", key = key, set = "Joker" })
  if ok and type(name) == "string" and name ~= "" and name ~= "ERROR" then return name end
  return key
end

local function config()
  local normalized = Config.normalize(mod.config, installed_joker_keys())
  mod.config = mod.config or {}
  for k, v in pairs(normalized) do mod.config[k] = v end
  return mod.config
end

local function edition_rng(n)
  local roll = pseudorandom(pseudoseed("onejoker_edition"))
  return math.max(1, math.ceil(roll * n))
end

local function spawn(plan, delay)
  if #plan == 0 or not G.jokers then return end
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = delay or 0.4,
    func = function()
      for _, card in ipairs(plan) do
        SMODS.add_card({ set = "Joker", key = card.key, edition = card.edition })
      end
      return true
    end,
  }))
end

local ease_ante_ref = ease_ante
function ease_ante(amount)
  ease_ante_ref(amount)
  if type(amount) ~= "number" or amount <= 0 then return end
  local ante = (G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 0) + amount
  spawn(Spawner.plan_for_ante(config(), ante, edition_rng))
end

local start_run_ref = Game.start_run
function Game:start_run(args)
  start_run_ref(self, args)
  if args and args.savetext then return end
  spawn(Spawner.plan_for_run_start(config(), edition_rng), 1.0)
end

local function row(node)
  return { n = G.UIT.R, config = { align = "cm", padding = 0.08 }, nodes = { node } }
end

local function columns(nodes)
  return { n = G.UIT.R, config = { align = "cm", padding = 0.08 }, nodes = nodes }
end

local function index_of(options, key)
  for i, option in ipairs(options) do
    if option.key == key then return i end
  end
  return 1
end

local function labels_of(options)
  local labels = {}
  for i, option in ipairs(options) do labels[i] = option.label end
  return labels
end

local function save()
  if SMODS.save_mod_config then SMODS.save_mod_config(mod) end
end

local function joker_cycle(label, current, callback)
  return create_option_cycle({
    label = label,
    scale = 0.8,
    w = 5.5,
    options = labels_of(joker_options),
    current_option = index_of(joker_options, current),
    opt_callback = callback,
    colour = G.C.PURPLE,
  })
end

local function index_of_key(list, key)
  for i, value in ipairs(list) do
    if value == key then return i end
  end
  return 1
end

local function edition_cycle(label, current, callback)
  local options = {}
  for i, key in ipairs(Config.EDITIONS) do options[i] = EDITION_LABELS[key] end
  return create_option_cycle({
    label = label,
    scale = 0.8,
    w = 3.5,
    options = options,
    current_option = index_of_key(Config.EDITIONS, current),
    opt_callback = callback,
    colour = G.C.DARK_EDITION,
  })
end

local function number_cycle(label, options, current, callback)
  return create_option_cycle({
    label = label,
    scale = 0.8,
    w = 3.5,
    options = options,
    current_option = current,
    opt_callback = callback,
    colour = G.C.BLUE,
  })
end

G.FUNCS.onejoker_pick_joker = function(args)
  mod.config.joker = joker_options[args.cycle_config.current_option].key
  save()
end

G.FUNCS.onejoker_pick_edition = function(args)
  mod.config.edition = Config.EDITIONS[args.cycle_config.current_option]
  save()
end

G.FUNCS.onejoker_pick_copies = function(args)
  mod.config.copies = args.cycle_config.current_option
  save()
end

G.FUNCS.onejoker_pick_cadence = function(args)
  mod.config.every_n_antes = args.cycle_config.current_option
  save()
end

for slot = 1, Config.STARTING_SLOTS do
  G.FUNCS["onejoker_pick_start_joker_" .. slot] = function(args)
    mod.config.starting_jokers[slot].joker = joker_options[args.cycle_config.current_option].key
    save()
  end
  G.FUNCS["onejoker_pick_start_edition_" .. slot] = function(args)
    mod.config.starting_jokers[slot].edition = Config.EDITIONS[args.cycle_config.current_option]
    save()
  end
end

mod.config_tab = function()
  local cfg = config()
  joker_options = Config.joker_options(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker, joker_label)

  local copies = {}
  for i = 1, Config.MAX_COPIES do copies[i] = tostring(i) end

  local cadence = { "Every ante" }
  for i = 2, Config.MAX_CADENCE do cadence[i] = "Every " .. i .. " antes" end

  local nodes = {
    row(create_toggle({ label = "Spawn every ante", ref_table = cfg, ref_value = "enabled" })),
    row(joker_cycle("Joker", cfg.joker, "onejoker_pick_joker")),
    columns({
      edition_cycle("Edition", cfg.edition, "onejoker_pick_edition"),
      number_cycle("Copies", copies, cfg.copies, "onejoker_pick_copies"),
    }),
    row(number_cycle("Cadence", cadence, cfg.every_n_antes, "onejoker_pick_cadence")),
    row(create_toggle({ label = "Also spawn on ante 1", ref_table = cfg, ref_value = "spawn_on_run_start" })),
  }

  for slot = 1, Config.STARTING_SLOTS do
    local start = cfg.starting_jokers[slot]
    nodes[#nodes + 1] = columns({
      joker_cycle("Start " .. slot, start.joker, "onejoker_pick_start_joker_" .. slot),
      edition_cycle("Edition", start.edition, "onejoker_pick_start_edition_" .. slot),
    })
  end

  return {
    n = G.UIT.ROOT,
    config = { align = "cm", padding = 0.05, colour = G.C.CLEAR },
    nodes = nodes,
  }
end
