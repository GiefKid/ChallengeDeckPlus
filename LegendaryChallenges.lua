-- Challenge Deck+ / LegendaryChallenges
--
-- A new page of five challenges, one per Legendary Joker. Each starts the
-- player with a Foil Joker and that challenge's Legendary Joker (no edition),
-- and otherwise runs exactly like a stock challenge (standard Challenge Deck,
-- no bans, no other modifiers) except that every blind's chip requirement is
-- tripled -- the payoff for starting with a Legendary Joker already in hand.
--
-- The multiplier is real gameplay, not just a display number: it's carried as
-- a rules.custom entry (game.lua's challenge-start loop drops any custom rule
-- with a value straight into G.GAME.modifiers, keyed by id -- see
-- ChallengeDeckPlus.lua's own notes on that pipeline) and consumed by the
-- get_blind_amount wrapper below, the same global vanilla itself calls to
-- size every blind.
--
-- These are ordinary SMODS.Challenge registrations, so they inherit
-- everything the rest of this mod already does for every challenge: always
-- unlocked (SMODS.Challenge's default `unlocked` returns true, so the stake
-- chip in ChallengeDeckPlus.lua shows up immediately), selectable on any
-- stake White through Gold via that same chip, and fully shielded from the
-- real progression systems by StatGuard.lua (which guards on G.GAME.challenge
-- being set at all, not on a fixed list of challenge ids).

CDP = CDP or {}

-- id -> {key, joker} for each Legendary Joker. `key` becomes this challenge's
-- SMODS key (prefixed to c_cdp_<key> by SMODS.add_prefixes: mod prefix "cdp",
-- then Challenge's class prefix "c"); `joker` is the vanilla Legendary Joker
-- card key it starts with. The challenge is named after that joker.
-- Canio's actual card key is the vanilla typo "j_caino" (game.lua's own
-- center table spells it that way; the in-game name shown to players is
-- still "Canio").
local LEGENDARIES = {
   {key = 'canio',     joker = 'j_caino',     name = 'Canio'},
   {key = 'triboulet', joker = 'j_triboulet', name = 'Triboulet'},
   {key = 'yorick',    joker = 'j_yorick',    name = 'Yorick'},
   {key = 'chicot',    joker = 'j_chicot',    name = 'Chicot'},
   {key = 'perkeo',    joker = 'j_perkeo',    name = 'Perkeo'},
}

-- Populated below with each registered challenge object, so the Rules-tab
-- alignment patch further down can recognise all five by identity.
CDP.LEGENDARY_CHALLENGES = CDP.LEGENDARY_CHALLENGES or {}

for _, v in ipairs(LEGENDARIES) do
   local challenge = SMODS.Challenge{
      key = v.key,
      loc_txt = {name = v.name},
      jokers = {
         {id = 'j_joker', edition = 'foil'},
         {id = v.joker},
      },
      -- The Perishable-Foil-Joker-at-Orange-Stake+ mechanic isn't listed here:
      -- it's driven entirely by StakeRules.lua's CDP.STAKE_RULES (keyed by
      -- this challenge's id once registered, c_cdp_<key>), which both applies
      -- it for real and adds its Rules tab line only while previewing a
      -- stake it's actually true for -- a static entry here would show that
      -- line unconditionally, even at White Stake.
      rules = {
         custom = {
            {id = 'cdp_score_x3', value = 3},
         },
      },
      deck = {type = 'Challenge Deck'},
      button_colour = G.C.RARITY[4],
      text_colour = G.C.WHITE,
   }
   CDP.LEGENDARY_CHALLENGES[challenge] = true
end

-- Vanilla's own Custom Rules rows (UI_definitions.lua's challenge_description_
-- tab, ~line 6223) are hardcoded to `align = "cl"` -- fine for a single rule
-- that fills most of the box's width, but with two short, independent lines
-- (the static 3X-score rule plus, at Orange Stake+, the synthetic perishable-
-- foil line StakeRules.lua splices in) it reads better centered, same as
-- NaneinfChallenge.lua's identical patch for its own three-line Rules box.
-- Chained onto whatever challenge_description_tab currently is (StakeRules.lua
-- already wraps it for its own stake-conditional overrides), and scoped to
-- these five challenges only via table membership, so every other
-- challenge's Custom Rules box keeps vanilla's own left alignment.
local cdp_ref_challenge_description_tab = G.UIDEF.challenge_description_tab
function G.UIDEF.challenge_description_tab(args)
   local res = cdp_ref_challenge_description_tab(args)
   if args and args._tab == 'Rules' and CDP.LEGENDARY_CHALLENGES[G.CHALLENGES[args._id]] then
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

-- Triples every blind's chip requirement for a challenge tagged with the
-- cdp_score_x3 modifier above. Chained onto whatever get_blind_amount is
-- already installed as (vanilla, or SMODS.get_blind_amount for a modded
-- scaling value -- see misc_functions.lua's own branch on G.GAME.modifiers.
-- scaling), so this composes with any stake or deck scaling rather than
-- replacing it.
local cdp_ref_get_blind_amount = get_blind_amount
function get_blind_amount(ante)
   local amount = cdp_ref_get_blind_amount(ante)
   local mult = G.GAME and G.GAME.modifiers and G.GAME.modifiers.cdp_score_x3
   if mult then amount = math.floor(amount * mult) end
   return amount
end
