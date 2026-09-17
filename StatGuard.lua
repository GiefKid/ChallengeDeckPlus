-- Challenge Deck+ / StatGuard
--
-- Nothing that happens inside a challenge run may reach the profile: no deck or
-- joker usage counts, no stake win stickers, no career stats, no high scores, no
-- discoveries, no card unlocks. This holds for every deck a challenge might use
-- - the challenge deck itself, a vanilla deck, or a deck added by another mod.
--
-- Vanilla already gets most of this right (see the note in ChallengeDeckPlus.lua).
-- Gaps closed here:
--
--   * set_joker_usage() is called unguarded on every round win
--     (state_events.lua), so challenge runs were incrementing profile joker
--     usage counts.
--   * check_and_set_high_score() only guards `G.GAME.seeded`, not challenges, so
--     challenge runs were writing profile high scores (and pushing to the
--     competition leaderboard when G.SETTINGS.COMP exists) -- and, even with
--     that write thrown away, still lit up the in-run "High Score!" badge
--     (G.GAME.round_scores[score].high_score) against a real high score that
--     was never actually going to be saved. Cleared unconditionally after the
--     call now, so a challenge run never shows that badge at all.
--   * set_consumeable_usage / set_voucher_usage / set_hand_usage are unguarded
--     and were feeding profile usage stats.
--   * discover_card() and unlock_card() guard challenges only while SMODS'
--     `seeded_unlocks` option is off. Guarded here unconditionally so the
--     setting can be flipped on for seeded runs without leaking challenges.
--
-- Two shapes of wrapper are needed, because some of these functions write run
-- state as well as profile state and the run state must survive - jokers like
-- Fortune Teller read G.GAME.consumeable_usage, and the run info panel reads
-- G.GAME.hand_usage.
--
--   block()   - profile-only writers: no-op inside a challenge run.
--   scratch() - mixed writers: run the original with a throwaway table swapped
--               in for the profile sub-table, so the profile writes land in
--               something that gets discarded and the G.GAME writes go through.

CDP = CDP or {}
CDP.wrapped = CDP.wrapped or {}

local function in_challenge()
   return not not (G.GAME and G.GAME.challenge)
end

--- Wrap global `name`, chaining onto whatever is currently installed there.
-- Idempotent: if our own wrapper is still the live value we leave it alone, so
-- this can be re-run after other mods load without stacking wrappers.
local function wrap(name, build)
   local current = _G[name]
   if type(current) ~= 'function' then return end
   if CDP.wrapped[name] == current then return end
   local wrapper = build(current)
   CDP.wrapped[name] = wrapper
   _G[name] = wrapper
end

--- Profile-only writer: does nothing during a challenge run.
local function block(name)
   wrap(name, function(ref)
      return function(...)
         if in_challenge() then return end
         return ref(...)
      end
   end)
end

local function shallow_copy(t)
   local c = {}
   for k, v in pairs(t) do c[k] = v end
   return c
end

--- One level deeper than shallow: high_scores entries are {amt = n} tables, so a
-- shallow copy would still share them and let writes through.
local function copy_of_tables(t)
   local c = {}
   for k, v in pairs(t) do
      c[k] = type(v) == 'table' and shallow_copy(v) or v
   end
   return c
end

--- Mixed writer: swap `field` on the profile for a throwaway table for the
-- duration of the call, so the profile writes land somewhere that gets dropped.
-- pcall guarantees the real table goes back even if the original errors. All
-- the functions wrapped this way return nothing, so no return value is relayed.
local function scratch(name, field)
   wrap(name, function(ref)
      return function(...)
         local profile = G.PROFILES[G.SETTINGS.profile]
         if not in_challenge() or not profile then return ref(...) end
         local real = profile[field]
         profile[field] = {}
         local ok, err = pcall(ref, ...)
         profile[field] = real
         if not ok then error(err, 0) end
      end
   end)
end

function CDP.install_guards()
   -- Profile-only writers.
   block('set_joker_usage')
   block('set_joker_win')
   block('set_joker_loss')
   block('set_deck_usage')
   block('set_deck_win')
   block('set_deck_loss')
   block('set_voucher_usage')
   block('inc_career_stat')  -- vanilla already guards this; kept so the promise
                             -- doesn't depend on another mod preserving it
   block('discover_card')
   block('unlock_card')

   -- Mixed writers: keep the G.GAME side, discard the profile side.
   scratch('set_consumeable_usage', 'consumeable_usage')
   scratch('set_hand_usage', 'hand_usage')

   -- high_scores is seeded from the real values so "is this a new best?"
   -- comparisons still behave the same as a normal run (the per-run
   -- G.GAME.round_scores[score].amt used for the round-eval/win-screen stat
   -- itself still updates correctly either way); the profile write is thrown
   -- away. G.SETTINGS.COMP is cleared for the call so send_score() can't push
   -- a challenge score to the competition leaderboard. The in-run "High
   -- Score!" badge (G.GAME.round_scores[score].high_score) is cleared right
   -- back off afterward -- it would otherwise still light up off the seeded
   -- comparison above, promising a save that (correctly) never happens.
   wrap('check_and_set_high_score', function(ref)
      return function(score, amt)
         local profile = G.PROFILES[G.SETTINGS.profile]
         if not in_challenge() or not profile or not profile.high_scores then return ref(score, amt) end
         local real, comp = profile.high_scores, G.SETTINGS.COMP
         profile.high_scores = copy_of_tables(real)
         G.SETTINGS.COMP = nil
         local ok, err = pcall(ref, score, amt)
         profile.high_scores = real
         G.SETTINGS.COMP = comp
         if G.GAME.round_scores[score] then G.GAME.round_scores[score].high_score = nil end
         if not ok then error(err, 0) end
      end
   end)
end

CDP.install_guards()

-- Mods that load after this one may replace these globals without chaining, so
-- re-assert the guards at the last moment before any run actually starts.
local cdp_ref_start_run = Game.start_run
function Game:start_run(args)
   CDP.install_guards()
   return cdp_ref_start_run(self, args)
end
