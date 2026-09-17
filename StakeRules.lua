-- Challenge Deck+ / StakeRules
--
-- Per-challenge stake ladder overrides. Every challenge not listed in
-- CDP.STAKE_RULES below runs the completely stock ladder at every stake; this
-- file exists for the handful where a vanilla stake modifier interacts badly
-- with the challenge's own gimmick.
--
-- On a Knife's Edge (c_knife_1): Black Stake's eternals-in-shop modifier is
-- self-defeating here -- an eternal joker parked directly to the right of
-- Ceremonial Dagger switches the dagger off for the rest of the run, because
-- card.lua:2978 only ever looks at slot my_pos+1 and never scans past a blocked
-- slot for another target. So for that challenge only:
--
--   Black  (vanilla: eternals in shop)    -> rentals at the normal 30% rate
--   Orange (vanilla: perishables in shop) -> unchanged
--   Gold   (vanilla: rentals in shop)     -> rentals again, at double rate (60%)
--
-- and eternals are never enabled at any stake, so every rung is a pure tax.
--
-- Medusa (c_medusa_1) bans Stone Joker, Driver's License and Hologram from Red
-- Stake up. All three scale off the deck rather than the hand, so they sail
-- past the challenge's gimmick and trivialise it.
--
-- Rentals are taken over through the supported sticker hook rather than a lovely
-- patch: create_card runs every sticker whose `should_apply` is a function
-- (common_events.lua ~2455) and skips its own hardcoded poll for that sticker
-- (~2473). Vanilla ships rental with `should_apply = false`, so installing a
-- function here means this mod owns rental application in every run -- the
-- default branch below reproduces the vanilla condition exactly, same seed
-- strings and same guard order, leaving normal and seeded runs alone.

CDP = CDP or {}

CDP.RENTAL_RATE = 0.3 -- vanilla shop rate (poll > 0.7)

-- challenge id -> overrides. `rentals_from` names the stake at which rentals
-- start appearing, `no_eternals` suppresses the stake's shop-eternal flag, and
-- `rental_rate` is a stake key -> rate table applied at or above that stake.
CDP.STAKE_RULES = {
   c_knife_1 = {
      no_eternals  = true,
      rentals_from = 'stake_black',
      rental_rate  = { stake_gold = 0.6 },
      -- Shown in the Restrictions tab's "Other" column at that stake and above.
      -- `loc` reads this mod's own localization file; `label` reuses a base-game
      -- string that is already translated everywhere (here the Rental sticker
      -- badge), so "Rental X2" needs no new string in any language. `text` is
      -- only a fallback for when a lookup somehow comes back empty.
      notes = {
         { from = 'stake_black', loc = 'cdp_rental_shop', text = 'Rental Jokers appear in the shop' },
         { from = 'stake_gold',  label = 'rental', suffix = ' X2', text = 'Rental X2' },
      },
   },
   c_medusa_1 = {
      banned_cards = {
         from = 'stake_red',
         keys = { 'j_stone', 'j_drivers_license', 'j_hologram' },
      },
   },
   -- Jokerless has no jokers to lean on, so the vanilla ladder just makes the
   -- antes harder with nothing to offset it. `hand_levels` counters that on the
   -- stakes whose vanilla scaling bump (Green, Purple) would otherwise be a
   -- pure tax -- Green and Purple keep vanilla's own harder scaling untouched,
   -- this only adds a starting hand-level cushion.
   --
   -- An exact per-stake map rather than an "at or above" ladder: the bonus is
   -- deliberately non-monotonic (Black and Blue drop back to no bonus between
   -- Green and Purple) because Black/Blue/Orange/Gold's own vanilla perks
   -- (eternals, -1 discard, perishables, rentals) are enough of a tax on their
   -- own without also compounding on Green's leftover level. Orange keeps a
   -- level-2 cushion since it inherits Purple's scaling=3 without stepping it
   -- up further itself. Gold gets no cushion here -- see gold_relief below,
   -- which handles Gold with a bankroll boost instead of a hand level.
   c_jokerless_1 = {
      hand_levels = {
         stake_white  = 1,
         stake_red    = 1,
         stake_green  = 2,
         stake_black  = 1,
         stake_blue   = 1,
         stake_purple = 3,
         stake_orange = 2,
         stake_gold   = 1,
      },
      -- Gold stacks scaling=3 ante growth with rentals in the shop and no
      -- jokers to buy them for, so it runs otherwise-stock (hand levels
      -- included, back to 1 above) with just a much bigger bankroll to buy
      -- rentals with. `dollars` is the exact starting amount (not a delta),
      -- since it's simpler to reason about than "+/- vanilla's default" and
      -- doesn't need to track what that default happens to be. Gold-only
      -- (exact match in gold_relief_at below), not "Gold and up", since there
      -- is no stake above it to accidentally inherit this.
      gold_relief = {
         dollars = 25,
      },
   },
   -- LegendaryChallenges.lua's five challenges (each starts with a Foil
   -- Joker) all share the same rule: once a stake would put Perishable
   -- jokers in the shop anyway (Orange and up -- SMODS.Stake's "orange"
   -- definition sets G.GAME.modifiers.enable_perishables_in_shop), the
   -- starting Foil Joker becomes Perishable too. Applied here rather than as
   -- a static challenge.rules.custom entry so the Rules tab line (see
   -- extra_custom_rules below) only shows up while previewing a stake it's
   -- actually true for, instead of unconditionally at every stake.
   c_cdp_canio = { perishable_foil_from = 'stake_orange' },
   c_cdp_triboulet = { perishable_foil_from = 'stake_orange' },
   c_cdp_yorick = { perishable_foil_from = 'stake_orange' },
   c_cdp_chicot = { perishable_foil_from = 'stake_orange' },
   c_cdp_perkeo = { perishable_foil_from = 'stake_orange' },
}

local function stake_level(key)
   return G.P_STAKES and G.P_STAKES[key] and G.P_STAKES[key].stake_level or nil
end

--- Overrides for the challenge currently being played, or nil for a normal run
-- and for any challenge without an entry.
local function rules()
   return G.GAME and G.GAME.challenge and CDP.STAKE_RULES[G.GAME.challenge] or nil
end

local function at_least(key)
   local level = stake_level(key)
   return not not (level and (G.GAME.stake or 1) >= level)
end

--- Whether a STAKE_RULES entry's perishable_foil_from threshold is met at a
-- given pool-index stake. Shared by the live application below and both
-- preview paths (Custom Rules text and the Jokers panel sticker), so all
-- three always agree on the exact same threshold.
local function perishable_active_at(r, stake)
   local level = r.perishable_foil_from and stake_level(r.perishable_foil_from)
   return not not (level and stake >= level)
end

--- Starting hand level a `hand_levels` map (stake key -> level) assigns at pool
-- index `stake`. 1 (no bonus) for a stake the map doesn't mention. Takes an
-- explicit stake rather than reading G.GAME.stake so the challenge-select menu
-- can preview the bonus for whichever stake chip is currently selected, not
-- just a live run's stake. A direct per-stake lookup rather than an "at or
-- above" ladder, since the bonus can drop back down at a higher stake (see
-- c_jokerless_1 above).
local function hand_level_bonus_at(entries, stake)
   local key = SMODS.stake_from_index(stake)
   return (key and entries[key]) or 1
end

local function hand_level_for_stake(entries)
   return hand_level_bonus_at(entries, G.GAME and G.GAME.stake or 1)
end

--- A STAKE_RULES entry's `gold_relief` payload, or nil unless `stake` is
-- exactly Gold. Exact match rather than the "at or above" test other
-- overrides use: this is a one-off bailout for the single hardest rung, not a
-- ladder that should keep applying above it.
local function gold_relief_at(r, stake)
   return r.gold_relief and stake == stake_level('stake_gold') and r.gold_relief or nil
end

--- get_starting_params() (misc_functions.lua ~2022) is a flat set of global
-- defaults with no challenge or stake argument, so a stake-conditional display
-- override can't be expressed by changing the values it returns permanently.
-- Splicing the override into challenge.rules.modifiers instead won't work:
-- vanilla treats anything in rules.modifiers as a genuine per-challenge
-- customization -- challenge_description_tab (UI_definitions.lua
-- ~6189) promotes it into the "changed from default" section above a divider,
-- alongside Jokerless's real Joker Slots: 0 -- visually disconnecting the
-- dollar figure from the rest of the stat list it normally sits in. Wrapping
-- get_starting_params instead makes the override look like a plain default, so
-- it stays in its usual spot at the bottom of the list, unhighlighted, exactly
-- like every stake but Gold shows it. CDP.dollars_display_override is set only
-- for the duration of building the Rules tab below, never during an actual run
-- (Game:start_run reads its own G.GAME.dollars, set by CDP.apply_challenge_
-- stake_rules, not this).
CDP.dollars_display_override = nil
local cdp_ref_get_starting_params = get_starting_params
function get_starting_params()
   local params = cdp_ref_get_starting_params()
   if CDP.dollars_display_override then
      params.dollars = CDP.dollars_display_override
   end
   return params
end

--- The dollar amount the Rules tab should display at `stake` for
-- `challenge_id`, or nil if nothing overrides it there.
local function dollars_display_override(challenge_id, stake)
   local r = CDP.STAKE_RULES[challenge_id or '']
   if not r then return nil end
   local relief = gold_relief_at(r, stake)
   return relief and relief.dollars or nil
end

function CDP.rental_rate()
   local r = rules()
   local rate = CDP.RENTAL_RATE
   if r and r.rental_rate then
      for key, value in pairs(r.rental_rate) do
         if at_least(key) and value > rate then rate = value end
      end
   end
   return rate
end

--- Stand-in for vanilla's hardcoded rental poll. Outside an overridden
-- challenge this is bit-for-bit the vanilla condition; inside one, only the
-- threshold moves.
CDP.rental_should_apply = function(self, card, center, area)
   -- Guards are ordered so pseudorandom() is reached under exactly the same
   -- circumstances as vanilla -- consuming that channel at any other time would
   -- desync seeded runs.
   if not (G.GAME and G.GAME.modifiers and G.GAME.modifiers.enable_rentals_in_shop) then return false end
   if area ~= G.shop_jokers and area ~= G.pack_cards then return false end
   if not center or center.set ~= 'Joker' then return false end
   local seed = (area == G.pack_cards and 'packssjr' or 'ssjr') .. G.GAME.round_resets.ante
   return pseudorandom(seed) > (1 - CDP.rental_rate())
end

function CDP.install_rental_hook()
   local rental = SMODS.Stickers and SMODS.Stickers['rental']
   if rental and rental.should_apply ~= CDP.rental_should_apply then
      rental.should_apply = CDP.rental_should_apply
   end
end

--- Apply this challenge's overrides. Runs after the stake, the deck and the
-- challenge have all had their say on G.GAME.modifiers, and is idempotent so it
-- can also run when an in-progress run is resumed from a save.
--
-- `is_new_run` gates `hand_levels` and `gold_relief`: neither is idempotent
-- like the flags below (level_up_hand adds to the current level rather than
-- setting it; re-granting the Hermit or resetting dollars on every resume
-- would hand out free money each time a save is reloaded), so both must only
-- ever fire once, on the run's actual creation -- never on a save resume,
-- where G.GAME.hands and G.GAME.dollars already carry whatever the run left
-- off at. Mirrors vanilla's own `if not saveTable` guard around the stake's
-- one-time run setup in Game:start_run (game.lua ~2103).
function CDP.apply_challenge_stake_rules(is_new_run)
   local r = rules()
   if not (r and G.GAME.modifiers) then return end
   if is_new_run and r.hand_levels then
      local level = hand_level_for_stake(r.hand_levels)
      if level > 1 then
         for _, hand in ipairs(G.handlist) do
            level_up_hand(nil, hand, true, level - 1)
         end
      end
   end
   if is_new_run then
      local relief = gold_relief_at(r, G.GAME.stake or 1)
      if relief then
         if relief.dollars then G.GAME.dollars = relief.dollars end
         if relief.consumable then
            G.E_MANAGER:add_event(Event({
               func = function()
                  add_joker(relief.consumable, nil, false)
                  return true
               end
            }))
         end
      end
   end
   -- Only the stake's shop-eternal flag is cleared; a challenge that asks for
   -- eternal jokers itself (modifiers.all_eternal) is left alone, since that is
   -- the challenge's own design rather than something the stake added.
   if r.no_eternals then G.GAME.modifiers.enable_eternals_in_shop = nil end
   if r.rentals_from and at_least(r.rentals_from) then
      G.GAME.modifiers.enable_rentals_in_shop = true
   end
   -- Idempotent (set_perishable is itself a no-op once perishable is already
   -- set), so this is safe to run unconditionally on every resume as well as
   -- a fresh run -- unlike hand_levels/gold_relief above, there's no "only
   -- once" state to protect here.
   if r.perishable_foil_from and at_least(r.perishable_foil_from) then
      for _, card in ipairs(G.jokers.cards) do
         if card.config and card.config.center and card.config.center.key == 'j_joker'
            and card.edition and card.edition.foil
            and not card.ability.eternal and not card.ability.perishable then
            card:set_perishable(true)
         end
      end
   end
   -- Same mechanism the challenge's own restrictions.banned_cards uses
   -- (game.lua:2192): banned_keys is consulted when pools are built, and it
   -- lives on G.GAME so it survives a save/resume.
   if r.banned_cards and at_least(r.banned_cards.from) then
      G.GAME.banned_keys = G.GAME.banned_keys or {}
      for _, key in ipairs(r.banned_cards.keys) do
         G.GAME.banned_keys[key] = true
      end
   end
end

-- Typecast (c_typecast_1): vanilla's ante-eternal mechanic skips perishable
--
-- state_events.lua ~182 makes every joker eternal at the end of the boss blind
-- of G.GAME.modifiers.set_eternal_ante (this is how Typecast works). But
-- Card:set_eternal (card.lua:667) is a no-op whenever ability.perishable is
-- truthy -- the mirror of the guard Card:set_perishable uses in reverse -- so
-- any joker that is currently perishable just never goes eternal. That sticker
-- only reaches a Typecast run at all because a high enough stake puts
-- perishables in the shop (Orange and up), which is why this only ever shows
-- up on the higher rungs Challenge Deck+ unlocks for a challenge that vanilla
-- would otherwise only ever run at White Stake.
--
-- Worse, if a perishable joker's last life would run out on that exact boss
-- blind, it gets debuffed there (the perish decrement runs inside end_round,
-- via SMODS.calculate_context at state_events.lua ~107) a beat before the
-- eternal assignment runs (~182), so it fails to go eternal on top of being
-- debuffed. So the sticker is stripped right when the player commits to the
-- ante's boss blind (G.FUNCS.select_blind, before the fight itself starts) --
-- it's moot at that point either way, and this also means the joker no longer
-- shows as perishable, or at risk, for the fight the eternal sticker was about
-- to make irrelevant. A joker that already ran out earlier in the ante is
-- already debuffed and stays that way -- clearing the sticker doesn't undo a
-- debuff that already landed, only prevents this round's from happening.
local function cdp_strip_perishable_for_eternal_ante()
   if not (G.GAME and G.GAME.modifiers and G.GAME.modifiers.set_eternal_ante
      and G.GAME.round_resets.ante == G.GAME.modifiers.set_eternal_ante
      and G.GAME.blind_on_deck == 'Boss') then
      return
   end
   for _, v in ipairs(G.jokers.cards) do
      if v.ability.perishable then
         v.ability.perishable = nil
         v.ability.perish_tally = nil
      end
   end
end

local cdp_ref_select_blind = G.FUNCS.select_blind
G.FUNCS.select_blind = function(e)
   cdp_strip_perishable_for_eternal_ante()
   return cdp_ref_select_blind(e)
end

CDP.install_rental_hook()

local cdp_ref_start_run = Game.start_run
function Game:start_run(args)
   local is_new_run = not (args and args.savetext)
   local ret = cdp_ref_start_run(self, args)
   CDP.install_rental_hook()
   -- Deferred rather than run synchronously here: a new run's challenge.jokers
   -- entries (game.lua's Game:start_run, ~2124) are only *queued* onto
   -- G.E_MANAGER as events, not created yet by the time cdp_ref_start_run
   -- above returns -- so the perishable_foil_from check in
   -- CDP.apply_challenge_stake_rules would find an empty G.jokers.cards and
   -- silently do nothing. It only ever appeared to work on a save resume,
   -- where the jokers already exist by the time this runs. Queuing this as
   -- its own event instead runs it strictly after every event start_run just
   -- queued (same G.E_MANAGER, same FIFO order), by which point the
   -- challenge's starting jokers are actually in play.
   G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
         CDP.apply_challenge_stake_rules(is_new_run)
         return true
      end
   }))
   return ret
end

-- Showing stake-conditional bans in the challenge description's Restrictions tab

--- Pool index of the stake the Restrictions panel should be describing: the
-- chip's current selection out in the challenge menu, or the live stake when the
-- panel is opened from inside a run (deck_view_challenge).
function CDP.display_stake(challenge_id)
   if G.GAME and G.GAME.challenge == challenge_id then return G.GAME.stake or 1 end
   return CDP.get_selected(challenge_id)
end

--- The bans this challenge picks up at `stake`, in the same {id = key} shape
-- vanilla's restrictions.banned_cards uses. nil when there are none.
local function extra_banned_cards(challenge_id, stake)
   local r = CDP.STAKE_RULES[challenge_id or '']
   if not (r and r.banned_cards) then return nil end
   local level = stake_level(r.banned_cards.from)
   if not (level and stake >= level) then return nil end
   local list = {}
   for _, key in ipairs(r.banned_cards.keys) do list[#list + 1] = { id = key } end
   return list
end

--- Note lines this challenge picks up at `stake`, or nil for none.
local function active_notes(challenge_id, stake)
   local r = CDP.STAKE_RULES[challenge_id or '']
   if not (r and r.notes) then return nil end
   local out = {}
   for _, note in ipairs(r.notes) do
      local level = stake_level(note.from)
      if level and stake >= level then out[#out + 1] = note end
   end
   return out[1] and out or nil
end

--- Resolve a note to display text, preferring localized sources and never
-- letting a failed lookup leak a raw key into the panel.
local function note_text(note)
   local function lookup(key, cat)
      local ok, res = pcall(localize, key, cat)
      if ok and type(res) == 'string' and res ~= '' and res ~= key and res ~= 'ERROR' then return res end
      return nil
   end
   if note.label then
      local base = lookup(note.label, 'labels')
      if base then return base .. (note.suffix or '') end
   end
   if note.loc then
      local str = lookup(note.loc)
      if str then return str end
   end
   return note.text or ''
end

--- The "Other" column is only ~2 units wide (vanilla puts banned blind sprites
-- there, not prose) and must not be widened, or it pushes the whole panel out.
-- There is plenty of unused height though, so lines are wrapped short by hand
-- and simply stack downwards.
local function wrap_text(text, max_chars)
   local lines, line = {}, ''
   for word in string.gmatch(text, '%S+') do
      local candidate = line == '' and word or (line .. ' ' .. word)
      if #candidate > max_chars and line ~= '' then
         lines[#lines + 1] = line
         line = word
      else
         line = candidate
      end
   end
   if line ~= '' then lines[#lines + 1] = line end
   return lines
end

--- Append note lines to the "Other" column of a built Restrictions tab.
-- Layout from UI_definitions.lua ~6378: ROOT > C > {cards, tags, other}, and
-- each of those is {header row, content row}.
local function inject_notes(tree, challenge, notes)
   local root_c = tree and tree.nodes and tree.nodes[1]
   local other = root_c and root_c.nodes and root_c.nodes[3]
   local box = other and other.nodes and other.nodes[2]
   if not (box and type(box.nodes) == 'table') then return end

   -- Vanilla drops a "None" placeholder in when the challenge bans no blinds;
   -- clear it, otherwise keep the blinds and add underneath them.
   local restrictions = challenge.restrictions
   local has_blinds = restrictions and restrictions.banned_other and next(restrictions.banned_other) ~= nil
   if not has_blinds then
      for i = #box.nodes, 1, -1 do box.nodes[i] = nil end
   end

   for _, note in ipairs(notes) do
      if box.nodes[1] then
         box.nodes[#box.nodes + 1] = {n = G.UIT.R, config = {align = "cm", minh = 0.16}, nodes = {}}
      end
      -- Chip rather than the stake's name: it says which stake the note belongs
      -- to without spending any of the column's scarce width on words.
      local index = CDP.stake_index(note.from)
      if index then
         box.nodes[#box.nodes + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.02}, nodes = {
            {n = G.UIT.O, config = {object = get_stake_sprite(index, 0.35), can_collide = false}},
         }}
      end
      for _, line in ipairs(wrap_text(note_text(note), 13)) do
         box.nodes[#box.nodes + 1] = {n = G.UIT.R, config = {align = "cm"}, nodes = {
            {n = G.UIT.T, config = {text = line, scale = 0.28, colour = G.C.UI.TEXT_DARK}},
         }}
      end
   end
end

--- Synthetic custom-rule entries this challenge's stake overrides add at the
-- given display stake, in the same {id, value} shape as challenge.rules.custom
-- -- so splicing them in below gets them rendered with vanilla's own styling.
-- nil when nothing applies at `stake`. The starting-money override lives in
-- CDP.dollars_display_override instead (see get_starting_params above), not
-- here, so it renders as a plain stat rather than a promoted "changed from
-- default" one.
local function extra_custom_rules(challenge_id, stake)
   local r = CDP.STAKE_RULES[challenge_id or '']
   if not r then return nil end
   local extra = {}

   local level = r.hand_levels and hand_level_bonus_at(r.hand_levels, stake) or 1
   if level > 1 then extra[#extra + 1] = { id = 'cdp_hand_level_start', value = level } end

   if perishable_active_at(r, stake) then extra[#extra + 1] = { id = 'cdp_perish_foil' } end

   return extra[1] and extra or nil
end

--- Splice extra_custom_rules' entries into the Rules tab's Custom Rules box
-- and set CDP.dollars_display_override for the Game Modifiers panel, then put
-- the challenge back exactly as it was. Same trick as the Restrictions branch
-- below, applied to `rules.custom` instead of `restrictions.banned_cards`, so
-- vanilla renders the custom-rule entries with its own styling.
local function with_stake_rule_overrides(challenge, stake, fn)
   local extra_custom = extra_custom_rules(challenge.id, stake)
   local dollars_override = dollars_display_override(challenge.id, stake)
   if not (extra_custom or dollars_override) then return fn() end

   local had_rules = challenge.rules
   challenge.rules = had_rules or {}
   local had_custom = challenge.rules.custom

   if extra_custom then
      local merged = {}
      for _, v in ipairs(type(had_custom) == 'table' and had_custom or {}) do merged[#merged + 1] = v end
      for _, v in ipairs(extra_custom) do merged[#merged + 1] = v end
      challenge.rules.custom = merged
   end
   CDP.dollars_display_override = dollars_override

   local ok, res = pcall(fn)

   CDP.dollars_display_override = nil
   challenge.rules.custom = had_custom
   challenge.rules = had_rules

   if not ok then error(res, 0) end
   return res
end

local cdp_ref_challenge_description_tab = G.UIDEF.challenge_description_tab
function G.UIDEF.challenge_description_tab(args)
   args = args or {}

   if args._tab == 'Rules' then
      local challenge = G.CHALLENGES[args._id]
      if not (challenge and challenge.id) then return cdp_ref_challenge_description_tab(args) end
      return with_stake_rule_overrides(challenge, CDP.display_stake(challenge.id), function()
         return cdp_ref_challenge_description_tab(args)
      end)
   end

   -- Banned cards are spliced into the challenge so vanilla renders them with
   -- its own code, then the challenge is put back exactly as it was --
   -- G.CHALLENGES is long-lived and the same tables are read when the run
   -- actually starts, so nothing may be left mutated behind us (hence the
   -- pcall). Notes are appended to the finished tree instead, since the
   -- "Other" column only knows how to draw banned blinds.
   local challenge = args._tab == 'Restrictions' and G.CHALLENGES[args._id] or nil
   if not (challenge and challenge.id) then return cdp_ref_challenge_description_tab(args) end

   local stake = CDP.display_stake(challenge.id)
   local extra = extra_banned_cards(challenge.id, stake)
   local notes = active_notes(challenge.id, stake)
   local real = challenge.restrictions and challenge.restrictions.banned_cards
   -- A challenge may define banned_cards as a function, which start_run resolves
   -- to a table before anything reads it; the UI can't render that, so leave any
   -- such challenge completely alone.
   if type(real) == 'function' then extra = nil end
   if not (extra or notes) then return cdp_ref_challenge_description_tab(args) end

   local had_restrictions, res, ok
   if extra then
      local merged, seen = {}, {}
      for _, v in ipairs(type(real) == 'table' and real or {}) do
         merged[#merged + 1] = v
         if v.id then seen[v.id] = true end
      end
      for _, v in ipairs(extra) do
         if not seen[v.id] then merged[#merged + 1] = v end
      end

      had_restrictions = challenge.restrictions
      challenge.restrictions = had_restrictions or {}
      challenge.restrictions.banned_cards = merged

      ok, res = pcall(cdp_ref_challenge_description_tab, args)

      challenge.restrictions.banned_cards = real
      challenge.restrictions = had_restrictions
   else
      ok, res = pcall(cdp_ref_challenge_description_tab, args)
   end

   if not ok then error(res, 0) end
   if notes then inject_notes(res, challenge, notes) end
   return res
end

-- Showing the Perishable sticker on the Jokers panel's preview card too

--- Mirrors CDP.apply_challenge_stake_rules' perishable_foil_from branch, but
-- for the challenge-select screen's Jokers preview card rather than a live
-- run's G.jokers.cards, and keyed to the stake chip's current preview
-- selection (CDP.display_stake) rather than G.GAME.stake. Path into the tree
-- follows G.UIDEF.challenge_description above: ROOT/R > nodes[1] (the
-- jokers/consumables/vouchers row) > nodes[1] (joker_col) > nodes[2] (the
-- white box) > nodes[1], whose config.object is the Jokers CardArea itself
-- (or absent, when the challenge has no jokers at all).
local cdp_ref_challenge_description = G.UIDEF.challenge_description
function G.UIDEF.challenge_description(_id, daily, is_row)
   local res = cdp_ref_challenge_description(_id, daily, is_row)
   local challenge = G.CHALLENGES[_id]
   local r = challenge and CDP.STAKE_RULES[challenge.id]
   if r and perishable_active_at(r, CDP.display_stake(challenge.id)) then
      local joker_col = res and res.nodes and res.nodes[1] and res.nodes[1].nodes and res.nodes[1].nodes[1]
      local wrapper = joker_col and joker_col.nodes and joker_col.nodes[2]
      local card_area = wrapper and wrapper.nodes and wrapper.nodes[1]
         and wrapper.nodes[1].config and wrapper.nodes[1].config.object
      if card_area and card_area.cards then
         for _, card in ipairs(card_area.cards) do
            if card.config and card.config.center and card.config.center.key == 'j_joker'
               and card.edition and card.edition.foil
               and not card.ability.eternal and not card.ability.perishable then
               card:set_perishable(true)
            end
         end
      end
   end
   return res
end
