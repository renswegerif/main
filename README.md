# Tekenzee

Kinderen kleuren een waterdier in, leggen het onder een webcam en zien het daarna rondzwemmen op een beamerprojectie in het zwembad. Twee kinderen kunnen met hun eigen dier ook een race tegen elkaar zwemmen.

| Map | Wat |
|---|---|
| `godot/` | Het spel (Godot 4.5): aquarium, webcam, race 1 tegen 1 |
| `kleurplaten/` | Kleurplaten om te printen (`kleurplaten.pdf`, A4 liggend) |
| `tekenzwembad.html` | Eerste webversie (foto's insturen met de telefoon) |
| `tools/` | Scripts die de kleurplaten en de tijdelijke plaatjes maken |

## Starten

1. Installeer [Godot 4.5](https://godotengine.org/download) of nieuwer.
2. Open in Godot de map `godot/` (Importeren → `project.godot`).
3. Druk op Play (F5). De eerste keer vraagt de Mac om toestemming voor de camera.
4. Druk op **H** voor alle toetsen.

## Zo werkt het

- **Tekening toevoegen:** leg de kleurplaat onder de webcam en druk op **spatie**. Het papier wordt weggeknipt en het dier zwemt het aquarium in. Zonder webcam kun je ook foto's of scans in de map `Tekenzee-inbox` op het bureaublad zetten (toets **O**). Ze worden dan vanzelf toegevoegd, ook via AirDrop.
- **Race:** druk op **R**, of laat beide spelers tegelijk op hun knop drukken. Kort drukken kiest een ander dier, vasthouden betekent klaar. Daarna volgt 3-2-1-zwem! Wie het snelst drukt, is het eerst bij 50 meter.
- **Besturing:** speler 1 = **A** of gamepad 1, speler 2 = **L** of gamepad 2, foto = **spatie** of gamepad 3. Arcadeknoppen met een USB-encoder en dansmatten werken als gamepad.
- **Beamer:** **M** spiegelt het beeld, **T** draait het 180°, **F** zet volledig scherm aan, **+ / -** maakt de dieren groter of kleiner.
- **Webcam:** **W** toont het beeld, **N** kiest een andere camera, **K** draait het beeld, **J** spiegelt het, **[ / ]** knipt minder of strenger.

## Eigen illustraties

De plaatjes in `godot/assets/dummy/` zijn tijdelijk. Zet je eigen PNG's (bijvoorbeeld uit een gekocht illustratiepakket) in `godot/assets/eigen/` in dezelfde mappen (`dieren`, `achter`, `midden`, `voor`). Zodra een map daar een plaatje bevat, wordt die gebruikt. `assets/eigen/` gaat niet mee naar GitHub.

## Nog niet getest

Getest in Godot 4.5.1 op Linux zonder camera: het knippen van tekeningen (met nagemaakte foto's), het aquarium en de hele race. **De webcam is nog niet getest.** Dat kan alleen op een computer met camera.
