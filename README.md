# pfUI-PetFeed

A small pfUI third-party addon for hunters (WoW 1.12 / OctoWoW).

- Shows a button while your pet is below loyalty level 6 (Best Friend) and you have food it eats.
- The number on the button is the pet's current loyalty level; the tooltip shows loyalty, happiness and the food it will use.
- Click to feed. Plain food is used before "Well Fed" buff food, smallest stack first.
- Hidden while the pet is already eating, dead, or missing.
- Move it with pfUI's `/unlock` (frame `pfPetFeedButton`).

Food IDs come from Gazmik Fizzwidget's Feed-O-Matic database (vanilla items only; server-custom foods aren't listed).
