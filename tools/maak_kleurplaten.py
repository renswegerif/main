"""Maakt de kleurplaten (A4 liggend) als SVG. Draai daarna tools/kleurplaten_pdf.js voor de PDF."""
from pathlib import Path

UIT = Path(__file__).resolve().parent.parent / "kleurplaten"

# Alle maten in millimeters. Het vak (gestippeld) is wat de webcam moet zien.
VAK = (18, 30, 261, 162)  # x, y, breedte, hoogte

DIEREN = {
    "vis": """
      <path d="M232 112 C216 70 152 62 108 96 L62 64 C69 90 69 132 62 160 L108 128 C152 162 216 154 232 112 Z"/>
      <path d="M140 74 C150 48 178 52 190 80"/>
      <path d="M150 142 C158 164 176 162 182 142"/>
      <path d="M188 82 C176 104 176 120 188 140"/>
      <path d="M120 102 c9 6 9 14 0 20 M136 94 c9 7 9 22 0 30 M152 92 c9 8 9 26 0 34 M168 94 c8 7 8 22 0 30"/>
      <path d="M74 84 L100 106 M72 112 L102 112 M74 140 L100 118"/>
      <circle cx="208" cy="100" r="8"/><circle cx="210" cy="100" r="3" class="vol"/>
      <path d="M222 120 q6 4 10 -2"/>
    """,
    "haai": """
      <path d="M250 114 C226 86 176 80 136 88 L124 54 L106 92 C86 96 72 100 58 98 L34 64 C40 88 42 104 40 118 L28 154 L58 124 C92 132 132 138 172 138 C214 138 238 128 250 114 Z"/>
      <path d="M176 134 L160 164 L148 136"/>
      <path d="M196 98 q-5 10 0 20 M206 96 q-5 11 0 22 M216 97 q-5 10 0 20"/>
      <circle cx="226" cy="104" r="6"/><circle cx="227.5" cy="104" r="2.5" class="vol"/>
      <path d="M230 124 q8 2 16 -6"/>
      <path d="M232 125 l2 4 l2 -5 l2 4 l2 -6 l2 4 l2 -6"/>
    """,
    "schildpad": """
      <path d="M78 122 C84 58 196 58 202 122 Z"/>
      <path d="M78 122 C120 136 160 136 202 122"/>
      <path d="M120 80 L140 72 L160 80 L160 100 L140 108 L120 100 Z"/>
      <path d="M120 80 L104 92 L104 114 M120 100 L104 114 M160 80 L176 92 L176 114 M160 100 L176 114 M140 108 L140 128 M140 72 L140 62"/>
      <path d="M200 112 C214 92 246 94 248 112 C248 128 222 132 202 124"/>
      <circle cx="232" cy="107" r="5"/><circle cx="233" cy="107" r="2" class="vol"/>
      <path d="M236 118 q6 2 9 -2"/>
      <path d="M176 128 C192 152 216 166 230 162 C226 146 204 130 190 126"/>
      <path d="M100 128 C88 148 70 158 56 152 C62 140 78 130 92 126"/>
      <path d="M80 116 L62 120 L80 124"/>
    """,
    "kwal": """
      <path d="M88 104 C86 44 206 40 206 104 Q196 112 186 104 Q176 112 166 104 Q156 112 146 104 Q136 112 126 104 Q116 112 106 104 Q96 112 88 104 Z"/>
      <path d="M100 108 C88 128 112 142 96 172"/>
      <path d="M124 110 C112 132 136 148 122 178"/>
      <path d="M148 110 C136 132 160 148 146 180"/>
      <path d="M172 110 C160 132 184 148 170 178"/>
      <path d="M196 108 C186 128 206 142 194 170"/>
      <circle cx="160" cy="76" r="7"/><circle cx="162" cy="76" r="3" class="vol"/>
      <circle cx="184" cy="78" r="7"/><circle cx="186" cy="78" r="3" class="vol"/>
      <path d="M164 92 q10 8 20 0"/>
      <circle cx="116" cy="70" r="6"/><circle cx="132" cy="58" r="4"/><circle cx="110" cy="90" r="4"/>
    """,
    "walvis": """
      <path d="M238 118 C238 72 172 58 122 84 C98 96 82 100 68 92 L42 66 C46 82 50 94 52 102 C40 110 30 116 26 130 C46 122 60 114 70 114 C92 128 112 152 162 154 C218 156 238 140 238 118 Z"/>
      <path d="M236 126 Q206 138 176 128"/>
      <path d="M186 136 q16 10 36 6 M180 142 q18 10 40 4"/>
      <path d="M150 128 C142 148 128 158 118 156 C122 144 132 132 142 126"/>
      <circle cx="208" cy="108" r="7"/><circle cx="210" cy="108" r="3" class="vol"/>
      <path d="M196 76 C190 62 178 58 172 60 M196 76 C200 62 212 56 220 58 M196 76 L196 56"/>
    """,
}

TITELS = {
    "vis": "De vis",
    "haai": "De haai",
    "schildpad": "De schildpad",
    "kwal": "De kwal",
    "walvis": "De walvis",
    "vrij": "Teken je eigen waterdier",
}


def pagina(naam: str, binnen: str) -> str:
    x, y, w, h = VAK
    hoekjes = "".join(
        f'<path d="M{cx} {cy + dy*10} L{cx} {cy} L{cx + dx*10} {cy}" class="hoek"/>'
        for cx, cy, dx, dy in [(x, y, 1, 1), (x + w, y, -1, 1), (x, y + h, 1, -1), (x + w, y + h, -1, -1)]
    )
    if naam == "vrij":
        uitleg = "Teken een groot dier met een dikke zwarte lijn eromheen. Laat het naar rechts zwemmen."
    else:
        uitleg = "Kleur het dier in met felle kleuren. Hoe voller, hoe mooier het zwemt!"
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="297mm" height="210mm" viewBox="0 0 297 210">
  <style>
    .lijn path, .lijn circle {{ fill: none; stroke: #111; stroke-width: 2.4; stroke-linecap: round; stroke-linejoin: round; }}
    .lijn .vol {{ fill: #111; }}
    .hoek {{ fill: none; stroke: #9a9a9a; stroke-width: 1.2; }}
    .vak {{ fill: none; stroke: #c4c4c4; stroke-width: 0.5; stroke-dasharray: 3 3; }}
    text {{ font-family: 'Comic Sans MS', 'Chalkboard SE', 'Marker Felt', sans-serif; fill: #8a8a8a; }}
  </style>
  <rect width="297" height="210" fill="#fff"/>
  <text x="18" y="17" font-size="9" font-weight="bold" fill="#555">{TITELS[naam]}</text>
  <text x="18" y="24.5" font-size="4.2">{uitleg}</text>
  <text x="279" y="17" font-size="5" text-anchor="end">zwemrichting</text>
  <path d="M252 21.5 L278 21.5 M272 18 L278 21.5 L272 25" fill="none" stroke="#8a8a8a" stroke-width="1" stroke-linecap="round"/>
  <rect class="vak" x="{x}" y="{y}" width="{w}" height="{h}"/>
  {hoekjes}
  <g class="lijn">{binnen}</g>
  <text x="18" y="203" font-size="5">Naam: ................................................</text>
  <text x="279" y="203" font-size="4" text-anchor="end">Leg het blad in het vak onder de camera. De hoekjes moeten in beeld zijn.</text>
</svg>
"""


def main():
    UIT.mkdir(exist_ok=True)
    volgorde = ["vis", "haai", "schildpad", "kwal", "walvis", "vrij"]
    for i, naam in enumerate(volgorde, 1):
        (UIT / f"{i}-{naam}.svg").write_text(pagina(naam, DIEREN.get(naam, "")), encoding="utf-8")
    print("klaar:", ", ".join(volgorde))


if __name__ == "__main__":
    main()
