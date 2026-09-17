-- Challenge Deck+ - default config
-- SMODS loads this into SMODS.Mods.ChallengeDeckPlus.config, then merges any
-- saved overrides from config/ChallengeDeckPlus.jkr over the top on launch.
--
-- Both sub-tables are keyed by profile ("p1".."p3"), then by challenge id:
--   selected["p1"]["c_omelette_1"] = "stake_gold"   -- chip the row is showing
--   wins["p1"]["c_omelette_1"]     = "stake_gold"   -- highest stake beaten
-- Stake *keys* are stored rather than pool indices so that mods which insert
-- extra stakes into the pool can't silently shift the meaning of saved data.
return {
   selected = {},
   wins     = {},
}
