-- Challenge Deck+
--
-- Vanilla always starts challenges on White Stake (G.FUNCS.start_challenge_run
-- hardcodes `stake = 1`). This mod adds a stake chip to every row of the
-- challenge list so any challenge can be started on any stake up to Gold, with
-- no unlock gating - every stake is always selectable.
--
--   left click chip  -> next stake  (wraps Gold -> White)
--   right click chip -> previous stake (wraps White -> Gold)
--
-- The green completion check next to the chip tracks the *selected* stake: it
-- is only shown if the challenge has been beaten on that stake or higher, the
-- same rule vanilla uses for deck stake wins.
--
-- A challenge run must never feed the real progression systems (Completionist,
-- stake unlocks, joker win stickers, career stats, high scores), whichever deck
-- it uses. Vanilla already gets win/loss right (win_game and update_game_over
-- only call set_deck_win/set_joker_win/set_deck_loss/set_joker_loss when
-- `not G.GAME.challenge`); everything else is enforced in StatGuard.lua.

CDP = CDP or {}

local cdp_mod = SMODS.current_mod
CDP.config = cdp_mod.config

assert(SMODS.load_file('StatGuard.lua'))()
assert(SMODS.load_file('StakeRules.lua'))()
assert(SMODS.load_file('LegendaryChallenges.lua'))()
assert(SMODS.load_file('EnhancedDeckChallenges.lua'))()
assert(SMODS.load_file('NaneinfChallenge.lua'))()

-- Sprites for the per-row completion check, keyed by challenge index. Rebuilt
-- every time a challenge list page is built; used to toggle the check in place.
CDP.check_sprites = {}

-- Stake helpers

-- Highest selectable pool index: Gold Stake. Modded stakes that sort before Gold
-- come along for the ride; anything above Gold is deliberately out of range.
function CDP.max_stake()
   for i, v in ipairs(G.P_CENTER_POOLS.Stake) do
      if v.key == 'stake_gold' then return i end
   end
   return #G.P_CENTER_POOLS.Stake
end

function CDP.stake_index(key)
   if not key then return nil end
   for i, v in ipairs(G.P_CENTER_POOLS.Stake) do
      if v.key == key then return i end
   end
   return nil
end

-- Persistence (SMODS config, one bucket per profile)

local function profile_key()
   return 'p' .. tostring(G.SETTINGS.profile or 1)
end

local function bucket(which)
   CDP.config[which] = CDP.config[which] or {}
   local p = profile_key()
   CDP.config[which][p] = CDP.config[which][p] or {}
   return CDP.config[which][p]
end

local function save_config()
   SMODS.save_mod_config(cdp_mod)
end

--- Stake the chip for `challenge_id` is currently showing (pool index).
function CDP.get_selected(challenge_id)
   local idx = CDP.stake_index(bucket('selected')[challenge_id or ''])
   if not idx then return 1 end
   return math.max(1, math.min(idx, CDP.max_stake()))
end

function CDP.set_selected(challenge_id, index)
   if not challenge_id then return end
   bucket('selected')[challenge_id] = SMODS.stake_from_index(index)
   save_config()
end

--- Highest stake this challenge has been beaten on (pool index, 0 = never).
-- Vanilla's own completion flag counts as a White Stake win so that challenges
-- beaten before this mod was installed keep their check.
function CDP.get_best(challenge_id)
   local best = CDP.stake_index(bucket('wins')[challenge_id or '']) or 0
   if challenge_id and G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[challenge_id] then
      best = math.max(best, 1)
   end
   return best
end

function CDP.is_beaten(challenge_id, index)
   return CDP.get_best(challenge_id) >= index
end

function CDP.record_win(challenge_id, index)
   if not challenge_id or not index then return end
   local wins = bucket('wins')
   if (CDP.stake_index(wins[challenge_id]) or 0) < index then
      wins[challenge_id] = SMODS.stake_from_index(index)
      save_config()
   end
end

-- Challenge list UI: inject a stake chip, and make the check stake-aware

local function stake_chip_node(k, challenge, index)
   local stake_center = G.P_CENTER_POOLS.Stake[index]
   return {n = G.UIT.C, config = {align = "cm", padding = 0.05, minw = 0.6}, nodes = {
      {n = G.UIT.C, config = {
         id = 'cdp_chip_' .. k,
         cdp_k = k,
         cdp_challenge_id = challenge.id,
         align = "cm", minh = 0.5, minw = 0.5, r = 0.1, emboss = 0.05,
         colour = G.C.BLACK, hover = true, shadow = true,
         button = 'cdp_cycle_stake',
         tooltip = {
            title = localize{type = 'name_text', key = stake_center.key, set = stake_center.set},
            text = {},
         },
      }, nodes = {
         {n = G.UIT.O, config = {id = 'cdp_chipsprite_' .. k, object = get_stake_sprite(index, 0.4), can_collide = false}},
      }},
   }}
end

local function check_node(k, challenge, index)
   local beaten = CDP.is_beaten(challenge.id, index)
   local sprite = Sprite(0, 0, 0.4, 0.4, G.ASSET_ATLAS["icons"], {x = 1, y = 0})
   sprite.states.drag.can = false
   sprite.states.visible = beaten
   CDP.check_sprites[k] = sprite

   return {n = G.UIT.C, config = {align = "cm", padding = 0.05, minw = 0.6}, nodes = {
      {n = G.UIT.C, config = {id = 'cdp_check_' .. k, minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1,
                              colour = beaten and G.C.GREEN or G.C.BLACK}, nodes = {
         {n = G.UIT.O, config = {object = sprite, can_collide = false}},
      }},
   }}
end

-- Post-process vanilla's page definition rather than replacing it, so other
-- mods' changes to the row layout survive. Vanilla emits exactly one row per
-- challenge, in page order, so row i is challenge PAGE_SIZE*page + i.
local cdp_ref_challenge_list_page = G.UIDEF.challenge_list_page
function G.UIDEF.challenge_list_page(_page)
   local t = cdp_ref_challenge_list_page(_page)
   CDP.check_sprites = {}

   for i, row in ipairs(t.nodes or {}) do
      local k = G.CHALLENGE_PAGE_SIZE * (_page or 0) + i
      local challenge = G.CHALLENGES[k]
      -- Locked challenges can't be started at all, so they keep the plain row.
      -- Vanilla row = {number, name button, check box}; bail out on anything else
      -- rather than clobbering a node whose meaning we can't be sure of.
      if challenge and row.nodes and #row.nodes == 3 and SMODS.challenge_is_unlocked(challenge, k) then
         local index = CDP.get_selected(challenge.id)
         row.nodes[#row.nodes] = check_node(k, challenge, index)
         table.insert(row.nodes, #row.nodes, stake_chip_node(k, challenge, index))
      end
   end

   return t
end

--- Redraw one row's chip + check in place, so cycling doesn't rebuild the page
-- (which would drop the currently selected challenge's description panel).
function CDP.refresh_row(k, challenge_id)
   if not G.OVERLAY_MENU then return end
   local index = CDP.get_selected(challenge_id)

   local sprite_e = G.OVERLAY_MENU:get_UIE_by_ID('cdp_chipsprite_' .. k)
   if sprite_e then
      local new_sprite = get_stake_sprite(index, 0.4)
      new_sprite.states.collide.can = false -- don't steal hover from the chip button
      -- get_stake_sprite builds at Sprite(0, 0, ...), i.e. the world origin, and
      -- the engine only moves it once ui_object_updated is processed on the next
      -- UIElement update. A left click is dispatched from Controller:update after
      -- the UI tree has already updated for the frame, so without this the sprite
      -- gets drawn once in the top-left corner first. Place it up front, the same
      -- way ui.lua does when it takes the object over.
      new_sprite:hard_set_T(sprite_e.T.x, sprite_e.T.y, sprite_e.T.w, sprite_e.T.h)
      if sprite_e.config.object then sprite_e.config.object:remove() end
      sprite_e.config.object = new_sprite
      new_sprite.ui_object_updated = true
   end

   local chip_e = G.OVERLAY_MENU:get_UIE_by_ID('cdp_chip_' .. k)
   if chip_e then
      local stake_center = G.P_CENTER_POOLS.Stake[index]
      chip_e.config.tooltip = {
         title = localize{type = 'name_text', key = stake_center.key, set = stake_center.set},
         text = {},
      }
      -- Tooltips are only rebuilt on hover-start, so re-run hover to pick up the
      -- new stake name while the cursor is still sitting on the chip.
      if chip_e.states.hover.is then
         chip_e:stop_hover()
         chip_e:hover()
      end
   end

   local beaten = CDP.is_beaten(challenge_id, index)
   local check_e = G.OVERLAY_MENU:get_UIE_by_ID('cdp_check_' .. k)
   if check_e then check_e.config.colour = beaten and G.C.GREEN or G.C.BLACK end
   if CDP.check_sprites[k] then CDP.check_sprites[k].states.visible = beaten end
end

-- The description panel's three tabs, as {localization key, _tab arg}. Tab
-- buttons are given `id = 'tab_but_'..label` by create_tabs, and clicking a
-- `choice` button keeps config.chosen accurate (ui.lua:1060), so the live tab
-- can simply be read back off the old UIBox instead of being tracked in a
-- variable that could go stale.
local CDP_TABS = {
   {'b_rules', 'Rules'},
   {'b_restrictions', 'Restrictions'},
   {'b_deck', 'Deck'},
}

local function chosen_tab(uibox)
   if not uibox or not uibox.get_UIE_by_ID then return nil end
   for _, tab in ipairs(CDP_TABS) do
      local button = uibox:get_UIE_by_ID('tab_but_' .. tostring(localize(tab[1])))
      if button and button.config and button.config.chosen then return tab[2] end
   end
   return nil
end

-- create_tabs always honours whichever entry carries `chosen`, but
-- G.UIDEF.challenge_description hardcodes that onto Rules. CDP.force_tab is set
-- only for the duration of a rebuild below, so every other tabbed UI in the game
-- passes straight through.
local cdp_ref_create_tabs = create_tabs
function create_tabs(args)
   if CDP.force_tab and args and type(args.tabs) == 'table' then
      local target
      for _, tab in ipairs(args.tabs) do
         local tab_args = tab.tab_definition_function_args
         if tab_args and tab_args._tab == CDP.force_tab then target = tab break end
      end
      -- Only touch anything once the remembered tab is actually found here,
      -- so an unrecognised tab set keeps its own choice.
      if target then
         for _, tab in ipairs(args.tabs) do tab.chosen = (tab == target) or nil end
      end
   end
   return cdp_ref_create_tabs(args)
end

--- Rebuild the description panel for challenge `k` if it is the one on screen.
-- G.FUNCS.change_challenge_description only rebuilds when a DIFFERENT challenge
-- is clicked, so without this the panel keeps showing the bans and notes for
-- whatever stake was selected at the moment it was first built. Rebuilt directly
-- rather than through change_challenge_description so that oid/old_chosen -- and
-- therefore the row's highlight -- are left untouched.
function CDP.refresh_description(k)
   if not G.OVERLAY_MENU then return end
   local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('challenge_area')
   if not (desc_area and desc_area.config.oid == k) then return end

   CDP.force_tab = chosen_tab(desc_area.config.object)
   if desc_area.config.object then desc_area.config.object:remove() end

   local ok, res = pcall(function()
      return UIBox{
         definition = G.UIDEF.challenge_description(k),
         config = {offset = {x = 0, y = 0}, align = 'cm', parent = desc_area}
      }
   end)
   CDP.force_tab = nil
   if not ok then error(res, 0) end
   desc_area.config.object = res
end

function CDP.cycle(k, challenge_id, dir)
   local max = CDP.max_stake()
   local index = CDP.get_selected(challenge_id) + dir
   if index > max then index = 1 end
   if index < 1 then index = max end

   CDP.set_selected(challenge_id, index)
   CDP.refresh_row(k, challenge_id)
   CDP.refresh_description(k)
   play_sound('cardSlide1', 1.2, 0.4)
end

G.FUNCS.cdp_cycle_stake = function(e)
   CDP.cycle(e.config.cdp_k, e.config.cdp_challenge_id, 1)
end

-- Right click. The engine never routes right clicks to UI elements at all
-- (Controller:queue_R_cursor_press only ever unhighlights the hand), so hovered
-- chips have to be picked off here.

local cdp_ref_queue_R = Controller.queue_R_cursor_press
function Controller:queue_R_cursor_press(x, y)
   if not self.locks.frame then
      local node = self.hovering.target or self.cursor_hover.target
      while node do
         if node.config and node.config.cdp_k then
            CDP.cycle(node.config.cdp_k, node.config.cdp_challenge_id, -1)
            return
         end
         node = node.parent
      end
   end
   return cdp_ref_queue_R(self, x, y)
end

-- Starting the run on the chosen stake

G.FUNCS.start_challenge_run = function(e)
   local challenge = G.CHALLENGES[e.config.id]
   local stake = challenge and CDP.get_selected(challenge.id) or 1
   if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
   G.FUNCS.start_run(e, {stake = stake, challenge = challenge})
end

-- Recording the win (and keeping it out of the real progression systems)

local cdp_ref_win_game = win_game
function win_game()
   local challenge_id = G.GAME.challenge
   local stake = G.GAME.stake or 1

   -- win_game's whole progression block (set_deck_win, set_joker_win, the
   -- win/win_stake/win_deck unlock checks, c_wins) is gated on
   -- `(not G.GAME.seeded and not G.GAME.challenge) or SMODS.config.seeded_unlocks`.
   -- StatGuard already neuters the individual writers, but suppressing the option
   -- for the call keeps the block from running at all, so a challenge win takes
   -- exactly the vanilla path no matter how that setting is configured.
   local restore_seeded_unlocks = nil
   if challenge_id and SMODS.config and SMODS.config.seeded_unlocks then
      restore_seeded_unlocks = SMODS.config.seeded_unlocks
      SMODS.config.seeded_unlocks = false
   end

   cdp_ref_win_game()

   if restore_seeded_unlocks ~= nil then SMODS.config.seeded_unlocks = restore_seeded_unlocks end

   if challenge_id then CDP.record_win(challenge_id, stake) end
end
