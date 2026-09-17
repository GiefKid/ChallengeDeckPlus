-- Challenge Deck+ strings. SMODS auto-loads this folder (utils.lua
-- SMODS.load_mod_localization); en-us is always loaded FIRST as the base and the
-- player's own language is layered over it, so adding e.g. de.lua later is
-- purely additive and an untranslated language falls back to English rather than
-- showing a raw key.
return {
   misc = {
      dictionary = {
         cdp_rental_shop = "Rental Jokers appear in the shop",
      },
      -- `ch_c_*` custom-rule lines (the vanilla challenge.rules.custom rows on
      -- the Rules tab) are looked up here, not under descriptions.Other --
      -- localize{type = 'text', key = ...} reads misc.v_text_parsed, which
      -- SMODS builds from this v_text table, the same place vanilla's own
      -- ch_c_no_shop_jokers etc. live.
      v_text = {
         ch_c_cdp_hand_level_start = {
            "All hand types start at {C:attention}level #1#",
         },
         -- LegendaryChallenges.lua's blind score multiplier (rules.custom id
         -- cdp_score_x3, value 3). #1# is that value, so the line stays
         -- correct if the multiplier is ever tuned.
         ch_c_cdp_score_x3 = {
            "Blind score requirements are {C:attention}#1#X#",
         },
         -- StakeRules.lua's synthetic cdp_perish_foil marker (spliced into
         -- the Rules tab only while previewing Orange Stake or above; see
         -- extra_custom_rules there). The row's mere presence already says
         -- "this only applies at Orange Stake and up" (same idiom Jokerless's
         -- own custom rules use -- they never spell out a condition in the
         -- text either, they just only show up when it's true), so the
         -- wording stays a plain statement of current fact rather than
         -- repeating the threshold in prose. `localize{type = 'text', ...}`
         -- (misc_functions.lua ~1951-1953) returns after its very first array
         -- element for this lookup type, so a v_text entry is always exactly
         -- one line -- extra elements are silently dropped, never wrapped.
         -- Each additional line on a Custom Rules row needs its own
         -- rules.custom id (and its own v_text entry below) rather than a
         -- longer array here. Also note: a "{C:x}word#" span can only be
         -- closed with a bare "#" when nothing follows it in the string --
         -- loc_parse_string (misc_functions.lua ~1796) treats a lone "#" as
         -- the *start* of a var-ref/close pair and swallows everything after
         -- it looking for a second "#" to close that pair, silently dropping
         -- the rest of the line if one never comes. "{C:x}word{}" (empty
         -- braces reset to default colour, matching the "{C:chips}+#1#{}
         -- Chips" example in SMODS's own game_object.lua) is the correct way
         -- to close a colour span with more plain text still to follow.
         ch_c_cdp_perish_foil = {
            "Foil Joker is {C:attention}Perishable{}",
         },
         -- NaneinfChallenge.lua's three rules.custom markers (all no value):
         -- cdp_win_naneinf is the one the win-condition hooks actually key
         -- off; _ante8 and _deck are display-only siblings that exist purely
         -- to get a second and third line onto the Rules tab (see the
         -- one-line-per-id note above).
         ch_c_cdp_win_naneinf = {
            "Win by reaching a naneinf score",
         },
         ch_c_cdp_win_naneinf_ante8 = {
            "Defeating Ante 8 does NOT win this challenge",
         },
         ch_c_cdp_win_naneinf_deck = {
            "Uses Ghost Deck ({C:spectral}Spectral{} Cards appear in the Shop)",
         },
         -- EnhancedDeckChallenges.lua's two challenges, each a single extra
         -- rules.custom line stating the deck's own gimmick (the multiplier
         -- itself is cdp_score_x3, the same key/text LegendaryChallenges.lua
         -- already registers, reused rather than duplicated here).
         ch_c_cdp_wildride_deck = {
            "All cards start as {C:attention}Wild{} Cards",
         },
         ch_c_cdp_magician_deck = {
            "All cards start as {C:attention}Lucky{} Cards",
         },
         -- EnhancedDeckChallenges.lua's get_new_boss wrap: each of these four
         -- is held out of the boss pool only until its own ante, then fully
         -- available from there on (see that file's CDP_WILDRIDE_BOSS_BAN_
         -- UNTIL for the exact thresholds these mirror).
         ch_c_cdp_wildride_ban_club = {
            "The Club can't appear until Ante {C:attention}3{}",
         },
         ch_c_cdp_wildride_ban_goad = {
            "The Goad can't appear until Ante {C:attention}4{}",
         },
         ch_c_cdp_wildride_ban_window = {
            "The Window can't appear until Ante {C:attention}5{}",
         },
         ch_c_cdp_wildride_ban_head = {
            "The Head can't appear until Ante {C:attention}6{}",
         },
      },
   },
}
