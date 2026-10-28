"""Tijdelijke plaatjes in krijtstijl voor Tekenzee. Vervang ze later door echte illustraties
(zet die in godot/assets/eigen/<map>/, dan worden de dummy's in die map niet meer gebruikt)."""
import math, random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

UIT = Path(__file__).resolve().parent.parent / "godot" / "assets" / "dummy"
random.seed(7)


def krijt(img: Image.Image) -> Image.Image:
    """Ruwe randjes en korrel, zodat het op krijt lijkt."""
    px = img.load()
    w, h = img.size
    for _ in range(w * h // 6):
        x, y = random.randrange(w), random.randrange(h)
        r, g, b, a = px[x, y]
        if a:
            f = random.uniform(0.7, 1.15)
            px[x, y] = (min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f)), a)
    return img


def lijn(d, pts, kleur, dikte):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        d.line([(x0 + random.uniform(-1, 1), y0 + random.uniform(-1, 1)), (x1, y1)], fill=kleur, width=dikte)
        d.ellipse([x1 - dikte / 2, y1 - dikte / 2, x1 + dikte / 2, y1 + dikte / 2], fill=kleur)


def wier(naam, hoogte, kleur, n=3, breed=180):
    img = Image.new("RGBA", (breed, hoogte), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i in range(n):
        x0 = breed / 2 + (i - (n - 1) / 2) * breed / (n + 1)
        top = random.uniform(0.0, 0.25) * hoogte
        fase = random.uniform(0, 6)
        links, rechts = [], []
        for k in range(41):
            t = k / 40
            y = hoogte - t * (hoogte - top)
            x = x0 + math.sin(t * 7 + fase) * breed * 0.08 * t
            b = (1 - t) * 18 + 4
            links.append((x - b, y)); rechts.append((x + b, y))
        d.polygon(links + rechts[::-1], fill=kleur)
        lijn(d, links, (20, 40, 30, 255), 4)
        lijn(d, rechts, (20, 40, 30, 255), 4)
    img.save(UIT / naam)


def koraal(naam, kleur, grootte=260):
    img = Image.new("RGBA", (grootte, grootte), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def tak(x, y, hoek, lengte, dikte, diepte):
        if diepte == 0 or lengte < 8:
            d.ellipse([x - dikte, y - dikte, x + dikte, y + dikte], fill=kleur)
            return
        x2 = x + math.cos(hoek) * lengte
        y2 = y - math.sin(hoek) * lengte
        d.line([(x, y), (x2, y2)], fill=kleur, width=int(dikte * 2))
        d.ellipse([x2 - dikte, y2 - dikte, x2 + dikte, y2 + dikte], fill=kleur)
        for s in (-1, 1):
            tak(x2, y2, hoek + s * random.uniform(0.3, 0.6), lengte * random.uniform(0.62, 0.78), dikte * 0.75, diepte - 1)

    tak(grootte / 2, grootte - 4, math.pi / 2, grootte * 0.3, 13, 5)
    rand = img.filter(ImageFilter.MaxFilter(7))
    donker = Image.new("RGBA", img.size, (30, 20, 40, 255))
    uit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    uit.paste(donker, mask=rand.split()[3])
    uit.alpha_composite(img)
    krijt(uit).save(UIT / naam)


def steen(naam, kleur, b=300, h=150):
    img = Image.new("RGBA", (b, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(25):
        a = math.pi * k / 24
        r = random.uniform(0.85, 1.0)
        pts.append((b / 2 - math.cos(a) * b * 0.48 * r, h - 2 - math.sin(a) * h * 0.92 * r))
    d.polygon(pts, fill=kleur)
    lijn(d, pts, (25, 25, 40, 255), 6)
    for _ in range(6):
        x, y = random.uniform(b * .2, b * .8), random.uniform(h * .45, h * .85)
        d.ellipse([x, y, x + 14, y + 9], outline=(25, 25, 40, 255), width=3)
    krijt(img).save(UIT / naam)


def vis(naam, kleur, streep, b=320, h=200):
    img = Image.new("RGBA", (b, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    lijf = [(250 + 30 * math.cos(a), 100 + 0 * a) for a in [0]]
    lijf = []
    for k in range(41):
        a = math.pi * 2 * k / 40
        lijf.append((165 + 95 * math.cos(a), 100 + 58 * math.sin(a)))
    staart = [(80, 100), (22, 45), (38, 100), (22, 160)]
    d.polygon(staart, fill=kleur)
    d.polygon(lijf, fill=kleur)
    for x in range(120, 240, 34):
        d.line([(x, 50), (x + 6, 150)], fill=streep, width=14)
    masker = Image.new("L", (b, h), 0)
    ImageDraw.Draw(masker).polygon(lijf, fill=255)
    ImageDraw.Draw(masker).polygon(staart, fill=255)
    img.putalpha(masker)
    d = ImageDraw.Draw(img)
    lijn(d, lijf + [lijf[0]], (25, 25, 35, 255), 7)
    lijn(d, staart + [staart[0]], (25, 25, 35, 255), 7)
    d.ellipse([210, 72, 238, 100], fill="white", outline=(25, 25, 35), width=4)
    d.ellipse([222, 80, 234, 92], fill=(25, 25, 35))
    krijt(img).save(UIT / naam)


def walvis(naam, b=520, h=240):
    img = Image.new("RGBA", (b, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    lijf = []
    for k in range(41):
        a = math.pi * 2 * k / 40
        lijf.append((300 + 200 * math.cos(a), 130 + 80 * math.sin(a) * (1.1 if math.sin(a) > 0 else 0.9)))
    d.polygon(lijf, fill=(40, 70, 120, 255))
    d.polygon([(110, 120), (20, 60), (55, 125), (20, 190)], fill=(40, 70, 120, 255))
    d.ellipse([430, 105, 448, 123], fill=(10, 20, 40))
    krijt(img).save(UIT / naam)


def main():
    for m in ["dieren", "achter", "midden", "voor"]:
        (UIT / m).mkdir(parents=True, exist_ok=True)
    vis("dieren/oranje.png", (255, 140, 66, 255), (255, 210, 63, 255))
    vis("dieren/blauw.png", (95, 168, 255, 255), (180, 240, 255, 255))
    vis("dieren/roze.png", (255, 95, 162, 255), (255, 194, 222, 255))
    walvis("achter/walvis.png")
    steen("achter/rots.png", (40, 60, 90, 255), 420, 200)
    wier("midden/wier1.png", 420, (60, 170, 110, 255))
    wier("midden/wier2.png", 320, (110, 200, 90, 255), n=2, breed=140)
    koraal("midden/koraal1.png", (255, 110, 120, 255))
    koraal("midden/koraal2.png", (255, 180, 70, 255), 220)
    steen("midden/steen.png", (110, 110, 140, 255))
    wier("voor/wier.png", 520, (40, 140, 90, 255), n=4, breed=240)
    koraal("voor/koraal.png", (200, 90, 220, 255), 300)
    print("dummy's gemaakt in", UIT)


if __name__ == "__main__":
    main()
