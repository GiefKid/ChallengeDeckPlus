# Challenge Deck+

**Alpha.** Rules and balance (especially on the newer challenges) are still being tuned and may change between updates. Please open an issue for bugs or crashes.

A [Steamodded](https://github.com/Steamodded/smods) mod for [Balatro](https://www.playbalatro.com/) that lets you play any challenge on any stake, and adds more challenges.

## Features

### Play any challenge on any stake

Vanilla always starts a challenge on White Stake. This mod adds a stake chip to every row of the challenge list:

- **Left click** the chip to cycle the stake up, **right click** to cycle it down (White through Gold).
- The row's completion check reflects the highest stake you've beaten that challenge on.
- It is not locked to progression, you can choose whatever stake you want at any time, no need to unlock by beating the previous.

### New challenges

- **Canio, Triboulet, Yorick, Chicot, Perkeo** — one challenge per Legendary Joker, 3x blind requirements. Each starts with a Foil Joker and that Joker already in hand; every blind's chip requirement is tripled. The starting Foil Joker is Perishable on Orange Stake+. As of 9/17 I have not gotten to playtesting all of these, some may end up not even needing the Foil Joker to win, while some may need some more assistance, like Chicot. I think however it is difficult to access these jokers, so having a challenge with them seems like a good add.
- **Wild Ride** — an ordinary Challenge Deck run whose entire 52-card deck starts as Wild Cards, at 2X blind score. Starts with Director's Cut and Retcon. Driver's License and Vampire are banned. The four suit-debuff bosses (The Club/Goad/Head/Window) are staggered into the boss pool a few antes late instead of banned outright, giving the user time to re-roll them since they demolish wild-enhanced cards.
- **Wild Ride 3X** — identical to Wild Ride, at 3X blind score instead. Trying to determine which I should use for the final version -- the previous, or the 3x. This version bans the suit-debuff bosses outright, as well as no longer owning the Retcon/Director's Cut Voucher)
- **Magician's Deck** — the same idea as Wild Ride, but every card starts as a Lucky Card, at 3X blind score. Driver's License and Vampire are banned. I thought this was a little easy, so I may up it to 4x or 5x the blind.
- **Naneinf** — starts with a Perkeo and the Ghost Deck. Win condition triggers on scoring naneinf score. Just a new, simple way to start a naneinf run, without needing the Brainstorm mod.

### Other per-challenge tuning

- On Knife's Edge becomes extremely easy with eternal jokers, as you can just use an eternal joker to block the forced destroy of a different joker. I have instead doubled the chance of rental jokers, which weakens the Ceremonial dagger. An alternate condition I'm debating implementing is allowing the dagger to destroy eternal jokers, but penalizing the player heavily for doing so (like setting their money to $0)
- Jokerless has its own custom stakes since many of the stakes do not apply to it. I am trying to determine what to do with gold stake, as the challenge is extremely difficult on gold-stake without some sort of help to the player. $25 start was how I was able to beat it, but other ideas are welcome. I don't think it should be left as-is though.
- Some other challenges ban certain jokers on higher stakes
- Golden Needle is very difficult on Gold Stake, may need some ideas on how to help the player a bit.
- Blast Off is almost impossible on Gold Stake without an early good joker (and I didn't even implement the -1 discard), needs a LOT of ideas on how to help the player.

## Installation

1. Install [Lovely](https://github.com/ethangreen-dev/lovely-injector) and [Steamodded](https://github.com/Steamodded/smods).
2. Drop this folder into your Balatro `Mods` directory (`%AppData%/Balatro/Mods/` on Windows).

## Requirements

- Steamodded (SMODS)

## License

[GPL-3.0](LICENSE)
