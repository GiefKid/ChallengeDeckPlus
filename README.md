# Challenge Deck+

**Alpha.** Rules and balance (especially on the newer challenges) are still being tuned and may change between updates. Please open an issue for bugs or crashes.

A [Steamodded](https://github.com/Steamodded/smods) mod for [Balatro](https://www.playbalatro.com/) that lets you play any challenge on any stake, and adds nine new challenges.

## Features

### Play any challenge on any stake

Vanilla always starts a challenge on White Stake. This mod adds a stake chip to every row of the challenge list:

- **Left click** the chip to cycle the stake up, **right click** to cycle it down (White through Gold).
- The row's completion check reflects the highest stake you've beaten that challenge on, not just whether you've beaten it at all.
- Cycling the chip is purely cosmetic/bookkeeping — it never touches deck wins, joker win stickers, stake unlocks, or achievements. A challenge run never feeds the real profile progression systems at all, regardless of stake.

### New challenges

- **Canio, Triboulet, Yorick, Chicot, Perkeo** — one challenge per Legendary Joker. Each starts with a Foil Joker and that Joker already in hand; every blind's chip requirement is tripled. The starting Foil Joker becomes Perishable once the selected stake would put Perishable jokers in the shop anyway (Orange and up).
- **Wild Ride** — an ordinary Challenge Deck run whose entire 52-card deck starts as Wild Cards, at 2X blind score. Starts with Director's Cut and Retcon. Driver's License and Vampire are banned. The four suit-debuff bosses (The Club/Goad/Head/Window) are staggered into the boss pool a few antes late instead of banned outright, since Wild Cards count as every suit at once.
- **Wild Ride 3X** — identical to Wild Ride, at 3X blind score instead.
- **Magician's Deck** — the same idea as Wild Ride, but every card starts as a Lucky Card, at 3X blind score. Driver's License and Vampire are banned.
- **Naneinf** — starts with a Perkeo and the Ghost Deck. Doesn't win on Ante 8's boss blind; instead it's won the moment any blind's score corrupts to NaN or Infinity, on whichever ante that happens to land on.

### Other per-challenge tuning

A few existing challenges get small stake-ladder adjustments where a vanilla stake modifier would otherwise fight the challenge's own gimmick — for example, Jokerless gets a starting hand-level cushion on stakes that would otherwise just tax a deck with no jokers to offset it, and A Knife's Edge swaps its stake ladder around Ceremonial Dagger's positioning quirk.

## Installation

1. Install [Lovely](https://github.com/ethangreen-dev/lovely-injector) and [Steamodded](https://github.com/Steamodded/smods).
2. Drop this folder into your Balatro `Mods` directory (`%AppData%/Balatro/Mods/` on Windows).

## Requirements

- Steamodded (SMODS)

## License

[GPL-3.0](LICENSE)
