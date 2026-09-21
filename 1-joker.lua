local mod = SMODS.current_mod
local Config = assert(SMODS.load_file("src/config.lua"))()
local Spawner = assert(SMODS.load_file("src/spawner.lua"))()

local EDITION_LABELS = {
  none = "None",
  e_foil = "Foil",
  e_holo = "Holo",
  e_polychrome = "Poly",
  e_negative = "Negative",
  random = "Random",
}

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

local function save()
  if SMODS.save_mod_config then SMODS.save_mod_config(mod) end
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

--
-- Config UI
--

local function joker_of(slot)
  local cfg = config()
  if slot then return cfg.starting_jokers[slot] end
  return { joker = cfg.joker, edition = cfg.edition }
end

local function back_to_config(e)
  local back = G.FUNCS["openModUI_" .. mod.id]
  if back then back(e) else G.FUNCS.exit_overlay_menu() end
end

G.FUNCS.onejoker_open_picker = function(e)
  local slot = e.config.ref_table and e.config.ref_table.slot
  G.FUNCS.overlay_menu({
    definition = SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Joker, { 5, 5, 5 }, {
      h_mod = 0.95,
      no_materialize = true,
      snap_back = true,
      modify_card = function(card, center)
        card.states.click.can = true
        card.click = function(self)
          play_sound("button", 1, 0.3)
          self:juice_up(0.2, 0.1)
          Config.assign_joker(config(), slot, center.key)
          save()
          back_to_config(self)
        end
      end,
    }),
  })
end

G.FUNCS.onejoker_clear_joker = function(e)
  Config.assign_joker(config(), e.config.ref_table and e.config.ref_table.slot, Config.NONE)
  save()
  back_to_config(e)
end

G.FUNCS.onejoker_pick_edition = function(args)
  local slot = args.cycle_config.slot
  local edition = Config.EDITIONS[args.cycle_config.current_option]
  if slot then
    mod.config.starting_jokers[slot].edition = edition
  else
    mod.config.edition = edition
  end
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

local function row(nodes, align)
  return { n = G.UIT.R, config = { align = align or "cm", padding = 0.05 }, nodes = nodes }
end

local function button(label, func, ref_table, opts)
  opts = opts or {}
  return {
    n = G.UIT.C,
    config = {
      align = "cm",
      padding = 0.08,
      r = 0.1,
      minw = opts.minw or 3.6,
      minh = 0.6,
      colour = opts.colour or G.C.PURPLE,
      button = func,
      ref_table = ref_table,
      shadow = true,
      hover = true,
      focus_args = { nav = "wide" },
    },
    nodes = {
      { n = G.UIT.T, config = { text = label, scale = opts.scale or 0.4, colour = G.C.UI.TEXT_LIGHT } },
    },
  }
end

local function label_text(text, scale)
  return { n = G.UIT.T, config = { text = text, scale = scale or 0.4, colour = G.C.UI.TEXT_LIGHT } }
end

local function index_of_key(list, key)
  for i, value in ipairs(list) do
    if value == key then return i end
  end
  return 1
end

local function edition_cycle(current, slot)
  local options = {}
  for i, key in ipairs(Config.EDITIONS) do options[i] = EDITION_LABELS[key] end
  return create_option_cycle({
    scale = 0.7,
    w = 2.6,
    options = options,
    current_option = index_of_key(Config.EDITIONS, current),
    opt_callback = "onejoker_pick_edition",
    slot = slot,
    colour = G.C.DARK_EDITION,
    no_pips = true,
    focus_args = { nav = "wide" },
  })
end

local function joker_row(slot)
  local target = joker_of(slot)
  local name = Config.truncate(joker_label(target.joker), 14)
  return row({
    label_text(slot and ("Start " .. slot) or "Joker", 0.4),
    button(name, "onejoker_open_picker", { slot = slot }, { minw = 3.4 }),
    button("X", "onejoker_clear_joker", { slot = slot }, { minw = 0.5, colour = G.C.RED }),
    edition_cycle(target.edition, slot),
  })
end

mod.config_tab = function()
  local cfg = config()

  local copies = {}
  for i = 1, Config.MAX_COPIES do copies[i] = tostring(i) end

  local cadence = { "Every ante" }
  for i = 2, Config.MAX_CADENCE do cadence[i] = "Every " .. i .. " antes" end

  local nodes = {
    row({ create_toggle({ label = "Spawn every ante", ref_table = cfg, ref_value = "enabled" }) }),
    joker_row(nil),
    row({
      create_option_cycle({
        scale = 0.7,
        w = 3.4,
        options = cadence,
        current_option = cfg.every_n_antes,
        opt_callback = "onejoker_pick_cadence",
        colour = G.C.BLUE,
        no_pips = true,
        focus_args = { nav = "wide" },
      }),
      label_text("Copies", 0.4),
      create_option_cycle({
        scale = 0.7,
        w = 2.0,
        options = copies,
        current_option = cfg.copies,
        opt_callback = "onejoker_pick_copies",
        colour = G.C.BLUE,
        no_pips = true,
        focus_args = { nav = "wide" },
      }),
    }),
    row({ create_toggle({ label = "Also spawn on ante 1", ref_table = cfg, ref_value = "spawn_on_run_start" }) }),
    row({ label_text("Starting jokers", 0.45) }),
  }

  for slot = 1, Config.STARTING_SLOTS do
    nodes[#nodes + 1] = joker_row(slot)
  end

  return {
    n = G.UIT.ROOT,
    config = { align = "cm", padding = 0.05, colour = G.C.CLEAR },
    nodes = nodes,
  }
end
