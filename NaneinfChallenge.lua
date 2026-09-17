-- Challenge Deck+ / NaneinfChallenge
--
-- Challenge #26, "Naneinf": starts with a Perkeo and the Ghost Deck (a Hex to
-- start, an elevated chance of Spectral cards in the shop, and the Ghost
-- Deck's own card back -- all of that is just SMODS.Challenge's `deck.type`
-- pointed at the real vanilla Ghost Deck back, see below), and doesn't win on
-- Ante 8's boss blind -- the max ante is raised to 99, high enough that no
-- realistic scaling gets a normal (non-corrupted) score there anyway. Long
-- before that, though, it's won the moment ANY blind's score comes out NaN or
-- Infinite -- floating point corruption from a wild enough scoring combo --
-- whichever blind that happens to land on.
--
-- `cdp_win_naneinf` is a rules.custom marker with no `value`, so game.lua's
-- challenge-start loop drops it into G.GAME.modifiers.cdp_win_naneinf = true
-- (same pipeline LegendaryChallenges.lua's cdp_score_x3 uses -- see
-- ChallengeDeckPlus.lua's own notes on that pipeline). Both hooks below key
-- off that modifier rather than this challenge's id, so any future challenge
-- that wants the same win condition can just carry the same rule.

CDP = CDP or {}

-- Captured so the Game:start_run hook below can recognise this exact
-- challenge by identity (`args.challenge == CDP.NANEINF`) instead of matching
-- against its prefixed key as a string.
CDP.NANEINF = SMODS.Challenge{
   key = 'naneinf',
   loc_txt = {name = 'Naneinf'},
   jokers = {
      {id = 'j_perkeo'},
   },
   -- Shown on the challenge list's Consumables tab, and -- via the ordinary
   -- challenge-start pipeline (game.lua's `if _ch.consumeables then` loop,
   -- right alongside the jokers/vouchers loops) -- what actually puts the Hex
   -- in hand at the start of a run. Ghost Deck's own config.consumables would
   -- normally do that same job (see the deck.type note below), so it's
   -- suppressed for this one challenge in the Game:start_run hook further
   -- down to avoid handing out two Hexes.
   consumeables = {
      {id = 'c_hex'},
   },
   -- Three separate ids rather than one multi-line entry: the Custom Rules
   -- panel gives each rules.custom id its own row, but `localize{type =
   -- 'text', ...}` only ever renders the first line of whatever array a
   -- single id's v_text entry holds (misc_functions.lua ~1951-1953) --
   -- extra array elements are silently dropped. cdp_win_naneinf is the one
   -- the win-condition hooks below actually check; _ante8 and _deck are
   -- inert siblings that exist purely to add their own line.
   rules = {
      custom = {
         {id = 'cdp_win_naneinf'},
         {id = 'cdp_win_naneinf_ante8'},
         {id = 'cdp_win_naneinf_deck'},
      },
   },
   -- The actual vanilla Ghost Deck back (game.lua's b_ghost: config =
   -- {spectral_rate = 2, consumables = {'c_hex'}}), not the plain "Challenge
   -- Deck" back every other challenge in this mod uses. Game:start_run
   -- (game.lua ~2075) resolves challenge.deck.type by matching a Back's own
   -- `.name` field via get_deck_from_name, so this is the same as picking
   -- Ghost Deck from the deck-select screen: its card back art and its raised
   -- Spectral shop rate come along for free through Back:apply_to_run(),
   -- which Game:start_run already calls for every run. Its starting Hex is
   -- suppressed there (see the consumeables field above and the hook below)
   -- since this challenge supplies its own.
   deck = {type = 'Ghost Deck'},
   button_colour = G.C.RARITY[4],
   text_colour = G.C.WHITE,
}

-- Vanilla's own Custom Rules rows (UI_definitions.lua's challenge_description_
-- tab, ~line 6223) are hardcoded to `align = "cl"` (vertically centered,
-- horizontally left) -- fine for a single rule that fills most of the box's
-- width, but with three short, independent lines it reads better centered.
-- Chained onto whatever challenge_description_tab currently is (StakeRules.lua
-- already wraps it for its own Rules-tab overrides), and scoped to this one
-- challenge's Rules tab only via identity, so every other challenge's Custom
-- Rules box keeps vanilla's own left alignment.
local cdp_ref_challenge_description_tab = G.UIDEF.challenge_description_tab
function G.UIDEF.challenge_description_tab(args)
   local res = cdp_ref_challenge_description_tab(args)
   if args and args._tab == 'Rules' and G.CHALLENGES[args._id] == CDP.NANEINF then
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

--- True once `n` has gone somewhere a normal chip score never does: NaN or
-- either infinity. Goes through vanilla's own number_format (misc_functions.
-- lua ~1059) rather than testing the number directly: number_format prints
-- true NaN as literal "nan"/"-nan", and true Infinity (num == math.huge) as
-- "naneinf" -- so checking the display text for either substring catches
-- every broken case vanilla itself recognises, with no separate
-- math.huge/-math.huge/`n ~= n` test needed.
local function is_naneinf(n)
   if type(n) ~= 'number' then return false end
   local text = number_format(n)
   if type(text) ~= 'string' then return false end
   return text:find('nan', 1, true) ~= nil or text:find('inf', 1, true) ~= nil
end

-- Vanilla's own win check (state_events.lua's end_round, ~line 110) is
-- `ante >= G.GAME.win_ante and blind_on_deck == 'Boss'`, with win_ante fixed
-- at 8 by Game:init_game_object. Raising it for a naneinf-flagged run moves
-- that check out to Ante 99 instead -- Ante 8 (and every ante up to 99) plays
-- out as an ordinary blind with no win screen attached, exactly as asked. 99
-- rather than something astronomically large: normal (non-corrupted) score
-- requirements are already well out of reach by around Ante 40, so this still
-- reads as "essentially unwinnable the normal way" without the modulo risk
-- math.huge would carry into the boss picker (see below). This also shifts
-- where showdown bosses (The Eye/The Mouth, common_events.lua's get_boss_key,
-- keyed off `ante % win_ante`) recur to every 99 antes instead of every 8.
local CDP_MAX_ANTE = 99

local cdp_ref_start_run = Game.start_run
function Game:start_run(args)
   -- Ghost Deck's own starting Hex (game.lua ~239 in back.lua, applied by
   -- Back:apply_to_run() before challenge.consumeables is even looked at) is
   -- suppressed for exactly this challenge's runs, since CDP.NANEINF already
   -- supplies its own Hex through the ordinary challenge-consumeables
   -- pipeline (for the challenge-list preview, see the definition above) --
   -- without this, a new Naneinf run would start with two Hexes. Nilled and
   -- restored around the call rather than left off permanently: Ghost Deck's
   -- P_CENTERS entry is the one shared, global object every other Ghost Deck
   -- run (challenge or otherwise) also uses.
   local ghost = args and args.challenge == CDP.NANEINF and G.P_CENTERS.b_ghost
   local saved_consumables
   if ghost and ghost.config then
      saved_consumables = ghost.config.consumables
      ghost.config.consumables = nil
   end

   local ret = cdp_ref_start_run(self, args)

   if ghost and ghost.config then
      ghost.config.consumables = saved_consumables
   end

   if G.GAME and G.GAME.modifiers and G.GAME.modifiers.cdp_win_naneinf then
      G.GAME.win_ante = CDP_MAX_ANTE
   end
   return ret
end

-- A NaN/Infinite score only ever gets *checked* by vanilla once a round
-- actually ends -- and vanilla only ends a round when hands run out or the
-- blind's chip requirement is met (Game:update_hand_played, game.lua ~3386:
-- `if G.GAME.chips - G.GAME.blind.chips >= 0 or hands_left < 1 then
-- [end the round] else [draw another hand] end`). NaN comparisons are always
-- false, so with hands still left a naneinf score just gets waved through and
-- play continues as if nothing happened -- chips sit at "-nan" with
-- hands_left still positive and nothing else reacts to it. This hook forces
-- the round to end on the very hand that
-- produces it, by satisfying the *other* half of that OR (hands_left < 1)
-- rather than the chips comparison, so the real NaN/Infinite value is never
-- touched here and still displays normally (vanilla's own chip-counter text
-- already renders it as "naneinf", not a crash -- that's where this
-- challenge's name comes from).
local cdp_ref_update_hand_played = Game.update_hand_played
function Game:update_hand_played(dt)
   if G.GAME and G.GAME.modifiers and G.GAME.modifiers.cdp_win_naneinf
      and G.GAME.blind and G.GAME.current_round and is_naneinf(G.GAME.chips) then
      G.GAME.current_round.hands_left = 0
   end
   return cdp_ref_update_hand_played(self, dt)
end

-- With the round now ending immediately (see above), end_round (state_events.
-- lua) runs its own beaten-blind check next: `G.GAME.chips - G.GAME.blind.
-- chips >= 0`, which is false for NaN no matter how thoroughly the blind was
-- actually cleared. A finite stand-in swapped in right here (chips is left
-- genuinely NaN/Infinite everywhere else, including on the blind-select
-- screen the moment it happened) is the only way to make vanilla treat this
-- as a beaten blind rather than a loss. Left in place rather than restored:
-- G.FUNCS.evaluate_round (called shortly after, to build the round-eval
-- screen) re-runs this same chips-vs-requirement comparison to decide the
-- blind's cash reward row, and a lingering NaN there would zero out that
-- reward despite the round having just been won.
local cdp_ref_end_round = end_round
function end_round()
   local naneinf = G.GAME and G.GAME.modifiers and G.GAME.modifiers.cdp_win_naneinf
      and G.GAME.blind and is_naneinf(G.GAME.chips)
   if naneinf then
      G.GAME.chips = G.GAME.blind.chips or 0
      -- check_and_set_high_score('hand', ...) (state_events.lua ~859, called
      -- earlier from evaluate_play) never recorded this naneinf hand as the
      -- run's Best Hand -- its own `math.floor(amt) > current.amt` compares
      -- false for any NaN, so it silently kept whatever the last real finite
      -- hand was. math.huge is the one value number_format actually prints as
      -- "naneinf" (a bare NaN prints as "-nan"/"nan" instead -- see
      -- is_naneinf above), so the win screen's Best Hand line reads "naneinf"
      -- too, matching what actually happened this run.
      if G.GAME.round_scores and G.GAME.round_scores.hand then
         G.GAME.round_scores.hand.amt = math.huge
      end
   end

   cdp_ref_end_round()

   if naneinf then
      -- Vanilla's own ante-8 win call (state_events.lua ~155-168) is an
      -- `immediate`-trigger event whose func only `return`s true (removing
      -- itself) once `G.STATE == G.STATES.ROUND_EVAL` -- until then it
      -- implicitly returns nil/false and the event manager just re-runs it
      -- next frame. That self-polling, not any fixed delay, is what makes a
      -- real ante-8 win always land in the right frame regardless of how
      -- long the beaten-blind animation actually takes. Mirroring that exact
      -- pattern here gets a naneinf win to feel identical: added the moment
      -- end_round is called, but it only actually fires once ROUND_EVAL is
      -- really reached, however long that takes.
      G.E_MANAGER:add_event(Event({
         trigger = 'immediate',
         blocking = false,
         blockable = false,
         func = function()
            if G.GAME.won then return true end
            if G.STATE == G.STATES.ROUND_EVAL then
               G.GAME.won = true
               if not G.GAME.win_notified then
                  G.GAME.win_notified = true
                  win_game()
               end
               return true
            end
         end,
      }))
   end
end
