-- Challenge Deck+ / EnhancedDeckChallenges
--
-- Three more challenges on the same score-multiplier gimmick LegendaryChal-
-- lenges.lua uses (cdp_score_x3 -- that file's own get_blind_amount hook
-- already reads this modifier off G.GAME regardless of which challenge set
-- it or what value it was given, so nothing new is needed here to make the
-- multiplier real). Each is otherwise an ordinary Challenge Deck run, with no
-- starting jokers, whose entire 52-card deck starts under a single
-- Enhancement instead of unenhanced:
--
--   Wild Ride       -- every card a Wild Card,  2X blind score
--   Wild Ride 3X    -- identical to Wild Ride,  3X blind score instead
--   Magician's Deck -- every card a Lucky Card, 3X blind score
--
-- Wild Ride 3X is a deliberate duplicate of Wild Ride (same deck, vouchers,
-- bans and boss stagger below) rather than a shared definition with a
-- variable multiplier, so the two sit side by side as separate challenges --
-- easy to playtest against each other, and easy to delete whichever one
-- doesn't earn its place.
--
-- Driver's License and Vampire are banned on all three: Driver's License
-- scales off the whole deck rather than the hand (same reason StakeRules.lua
-- already bans it from Medusa), and Vampire eats the very enhancement each of
-- these challenges is built around -- both would either trivialise or gut a
-- challenge whose whole point is playing around the enhancement's own
-- effect.
--
-- Both Wild Ride challenges also start with Director's Cut and Retcon, and
-- stagger the four suit-debuff bosses (The Club/Goad/Head/Window) into the
-- boss pool a few antes late instead of banning them outright -- see the
-- get_new_boss wrap below for why: Wild Cards count as every suit, so any one
-- of those four would debuff the entire deck on whichever blind draws it.
-- Each is held back until a specific ante, then fully in the pool from there
-- on:
--
--   The Club   -- Ante 3+
--   The Goad   -- Ante 4+
--   The Window -- Ante 5+
--   The Head   -- Ante 6+

CDP = CDP or {}

local SUITS = {'S', 'H', 'D', 'C'}
local RANKS = {'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'}

--- A full 52-card deck.cards list (challenge.lua's own {s=,r=,e=} shape),
-- every card carrying the same starting enhancement.
local function full_enhanced_deck(enhancement)
   local cards = {}
   for _, s in ipairs(SUITS) do
      for _, r in ipairs(RANKS) do
         cards[#cards + 1] = {s = s, r = r, e = enhancement}
      end
   end
   return cards
end

-- Wild Ride's own vouchers and its four boss-stagger custom-rule lines,
-- shared verbatim between Wild Ride and Wild Ride 3X.
local WILDRIDE_VOUCHERS = {
   {id = 'v_directors_cut'},
   {id = 'v_retcon'},
}
local WILDRIDE_EXTRA_CUSTOM = {
   {id = 'cdp_wildride_ban_club'},
   {id = 'cdp_wildride_ban_goad'},
   {id = 'cdp_wildride_ban_window'},
   {id = 'cdp_wildride_ban_head'},
}

-- id -> {name, enhancement, deck_rule, score_mult, vouchers, extra_custom,
-- wildride_boss_stagger}. `deck_rule` is the rules.custom id carrying this
-- challenge's own "all cards start as X" line (localization/en-us.lua's
-- ch_c_<id>); `vouchers`/`extra_custom` are optional extras only the two Wild
-- Ride challenges use; `wildride_boss_stagger` marks a challenge for the
-- get_new_boss wrap further down.
local ENHANCED_DECKS = {
   {
      key = 'wildride', name = 'Wild Ride', enhancement = 'm_wild', deck_rule = 'cdp_wildride_deck',
      score_mult = 2, vouchers = WILDRIDE_VOUCHERS, extra_custom = WILDRIDE_EXTRA_CUSTOM,
      wildride_boss_stagger = true,
   },
   {
      key = 'wildride3x', name = 'Wild Ride 3X', enhancement = 'm_wild', deck_rule = 'cdp_wildride_deck',
      score_mult = 3, vouchers = WILDRIDE_VOUCHERS, extra_custom = WILDRIDE_EXTRA_CUSTOM,
      wildride_boss_stagger = true,
   },
   {key = 'magician', name = "Magician's Deck", enhancement = 'm_lucky', deck_rule = 'cdp_magician_deck', score_mult = 3},
}

-- Populated below with each registered challenge object, so the Rules-tab
-- alignment patch further down can recognise all three by identity, and the
-- get_new_boss wrap can recognise the two Wild Ride ones.
CDP.ENHANCED_DECK_CHALLENGES = CDP.ENHANCED_DECK_CHALLENGES or {}
CDP.WILDRIDE_CHALLENGES = CDP.WILDRIDE_CHALLENGES or {}

for _, v in ipairs(ENHANCED_DECKS) do
   local custom = {
      {id = 'cdp_score_x3', value = v.score_mult},
      {id = v.deck_rule},
   }
   for _, extra in ipairs(v.extra_custom or {}) do custom[#custom + 1] = extra end

   local challenge = SMODS.Challenge{
      key = v.key,
      loc_txt = {name = v.name},
      jokers = {},
      vouchers = v.vouchers,
      rules = {custom = custom},
      deck = {
         cards = full_enhanced_deck(v.enhancement),
         type = 'Challenge Deck',
      },
      restrictions = {
         banned_cards = {
            {id = 'j_drivers_license'},
            {id = 'j_vampire'},
         },
      },
      button_colour = G.C.RARITY[4],
      text_colour = G.C.WHITE,
   }
   CDP.ENHANCED_DECK_CHALLENGES[challenge] = true
   if v.wildride_boss_stagger then CDP.WILDRIDE_CHALLENGES[challenge] = true end
end

-- Staggering the four suit-debuff bosses into Wild Ride's boss pool

-- Wild Cards (game.lua's m_wild enhancement) count as every suit at once, so
-- The Club/Goad/Head/Window -- each of which debuffs one specific suit for
-- the blind -- would debuff literally every card in a Wild Ride deck on
-- whichever blind draws them. Rather than a flat ban, each is held out of the
-- pool only until its own ante (see the file header for the exact list), then
-- fully available from there on -- earlier antes get no jokers or shop passes
-- yet to build any answer with, but by the time each one unlocks the run has
-- had a real chance to prepare.
--
-- G.GAME.banned_keys is vanilla's own mechanism for excluding a boss from the
-- pool (get_new_boss, common_events.lua ~2736); temporarily adding whichever
-- of these four haven't reached their ante yet, only while get_new_boss is
-- choosing the current ante's boss, then restoring whatever was there before,
-- reuses that mechanism without a static restrictions.banned_other entry
-- (which would ban them for the whole run, not just the early antes).
-- get_new_boss reads G.GAME.round_resets.ante itself, so this works both for
-- a fresh run's own calls and for a save loaded back into an early ante.
local CDP_WILDRIDE_BOSS_BAN_UNTIL = {
   bl_club = 3,
   bl_goad = 4,
   bl_window = 5,
   bl_head = 6,
}

local cdp_ref_get_new_boss = get_new_boss
function get_new_boss()
   local wildride = G.GAME and CDP.WILDRIDE_CHALLENGES[G.GAME.challenge_tab]
   local ante = wildride and math.max(1, G.GAME.round_resets.ante or 1)

   local saved
   if wildride then
      G.GAME.banned_keys = G.GAME.banned_keys or {}
      saved = {}
      for key, ban_until in pairs(CDP_WILDRIDE_BOSS_BAN_UNTIL) do
         if ante < ban_until then
            saved[key] = G.GAME.banned_keys[key]
            G.GAME.banned_keys[key] = true
         end
      end
   end

   local boss = cdp_ref_get_new_boss()

   if saved then
      for key, was_banned in pairs(saved) do
         G.GAME.banned_keys[key] = was_banned
      end
   end

   return boss
end

-- Same centered-alignment patch as LegendaryChallenges.lua and
-- NaneinfChallenge.lua apply for their own challenges -- vanilla's Custom
-- Rules rows (UI_definitions.lua's challenge_description_tab, ~line 6223)
-- are hardcoded to `align = "cl"`, which reads worse than centered once a
-- challenge has more than one short, independent Custom Rules line, as all
-- three do (the score-multiplier rule plus this challenge's own deck line,
-- plus Wild Ride's four boss-stagger lines). Chained onto whatever
-- challenge_description_tab currently is, and scoped to these three
-- challenges only via table membership.
local cdp_ref_challenge_description_tab = G.UIDEF.challenge_description_tab
function G.UIDEF.challenge_description_tab(args)
   local res = cdp_ref_challenge_description_tab(args)
   if args and args._tab == 'Rules' and CDP.ENHANCED_DECK_CHALLENGES[G.CHALLENGES[args._id]] then
      local root_c = res and res.nodes and res.nodes[1]
      local custom_box = root_c and root_c.nodes and root_c.nodes[1] and root_c.nodes[1].nodes and root_c.nodes[1].nodes[2]
      if custom_box and type(custom_box.nodes) == 'table' then
         for _, row in ipairs(custom_box.nodes) do
            if row.config then row.config.align = 'cm' end
         end
      end
   end
   return res
end
