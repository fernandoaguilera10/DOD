#!/usr/bin/env python3
"""Generate the APAT measure-button icons and the header chinchilla sprites.

Self-contained (grids below, from the approved Oct 16 2026 designs): every
sprite is a character grid (one character = one pixel, colours in PAL,
'.' = transparent), upscaled with nearest-neighbour so the pixels stay
crisp. Writes RGBA PNGs next to this script:

  icon_abr / icon_efr / icon_oae / icon_memr   measure buttons (one dark ink,
                                               '#' solid, 'a' 40 % fill)
  chin_front, chin_front_lg (header sign), chin_happy, chin_desp, chin_phone,
  chin_walk1/2 (+ _l mirrored), chin_pj1/2 (+ _l), chin_snack1/2,
  chin_fridge, chin_fridge_open, chin_bed, chin_bed_sleep, chin_med,
  chin_incense, chin_incense2 (smoke frame)      run status card (run_status.m)

make_icons.py (type-button icons) calls main() of this file at its end, so
running either one keeps the measure icons up to date.

    python3 make_sprites.py
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SPRITE_SCALE = 2          # run card sprites
SIGN_SCALE = 3            # header chinchilla holding the sign
ICON_SCALE = 2            # measure-button icons
INK = (38, 38, 38)        # measure-icon ink (unselected and selected buttons)

# Palette: sprite character -> colour (. = transparent)
PAL = {'B': '#8E6F3E', 'K': '#2B2D31', 'O': '#E8A33D', 'P': '#FFFFFF', 'R': '#E8613C', 'Z': '#A88BCB', 'b': '#A8743A', 'c': '#7FD3F7', 'd': '#7A7F87', 'e': '#141414', 'f': '#E9EEF2', 'g': '#A3A8AF', 'h': '#E26D7D', 'i': '#FFF4C2', 'l': '#E6E8EB', 'm': '#C9C2B4', 'n': '#C9707E', 'o': '#7A2B35', 'p': '#E7A3AE', 'q': '#7FBF5F', 'r': '#C0392B', 's': '#55585E', 't': '#6B4A2B', 'u': '#4F6FA8', 'v': '#A9C1E8', 'w': '#FFFFFF', 'x': '#1B1D21', 'y': '#DAAA00', 'z': '#7E5BA6'}

# Chinchilla sprites (from the approved RunCard / Combined designs)
SPRITES = {
    'FRONT': [
        '....KKK..........KKK......',
        '...KpppK........KpppK.....',
        '..KppppdK......KdppppK....',
        '..KppppdK......KdppppK....',
        '..KdpppdK......KdpppdK....',
        '...KddddKKKKKKKKddddK.....',
        '....KggggggggggggggK......',
        '...KggggggggggggggggK.....',
        '..KgggeeggggggggeeggK.....',
        '..KgggewggggggggewggK.....',
        '..KgggggggggnngggggggK....',
        'ss.KggggggglllggggggKss...',
        '..sKggggglllllllgggKs.....',
        '...KgggglllllllllgggK.....',
        '..KggggllllllllllgggK.....',
        '..KggggllllllllllgggKKK...',
        '..KgggglllllllllggggKdddK.',
        '...KggggllllllllgggKddddK.',
        '....KgggglllllgggggKdddK..',
        '.....KKgggggggggggKKKdK...',
        '......KgK......KgK..KK....',
        '......KKK......KKK........',
    ],
    'HAPPY': [
        'y.h.KKK..........KKK.h..y.',
        '...KpppK........KpppK.....',
        '..KppppdK......KdppppK..h.',
        'y.KppppdK......KdppppK....',
        '..KdpppdK......KdpppdK..y.',
        '...KddddKKKKKKKKddddK.....',
        '....KggggggggggggggK......',
        '...KggggggggggggggggK.....',
        '..KggKgKggggggggKgKggK....',
        'KKKgKgggKggggggKgggKgKKK..',
        'KgKggghggggnngggghggKgK...',
        'sKsKgggggKooooKgggggKsKs..',
        '..sKggggglKoohKlggggKs....',
        '...KgggglllKKKllllgggK....',
        '..KggggllllllllllgggK.....',
        '..KggggllllllllllgggKKK...',
        '..KgggglllllllllggggKdddK.',
        '...KggggllllllllgggKddddK.',
        '....KgggglllllgggggKdddK..',
        '.....KKgggggggggggKKKdK...',
        '......KgK......KgK..KK....',
        '......KKK......KKK........',
    ],
    'WALK1': [
        '..............KKK...........',
        '.............KpppK..........',
        '............KppppdK.........',
        '............KdpppdK.........',
        '.KKK........KKddKKKK........',
        'KdddK.....KKgggggggKK.......',
        'KddddKKKKKgggggggggggK......',
        '.KddddKgggggggggggeeggK.....',
        '..KdddggggggggggggewgggnKs..',
        '...KggggggggggggggggggKKss..',
        '...KgggggggggggggggllllK.s..',
        '...KggggggggggglllllllK.....',
        '....KgggggggglllllllKK......',
        '.....KgK..KgK....KgK.KgK....',
        '.....KKK..KKK....KKK.KKK....',
    ],
    'WALK2': [
        '..............KKK...........',
        '.............KpppK..........',
        '............KppppdK.........',
        '............KdpppdK.........',
        '.KKK........KKddKKKK........',
        'KdddK.....KKgggggggKK.......',
        'KddddKKKKKgggggggggggK......',
        '.KddddKgggggggggggeeggK.....',
        '..KdddggggggggggggewgggnKs..',
        '...KggggggggggggggggggKKss..',
        '...KgggggggggggggggllllK.s..',
        '...KggggggggggglllllllK.....',
        '....KgggggggglllllllKK......',
        '......KgKKgK......KgKKgK....',
        '......KKKKKK......KKKKKK....',
    ],
    'DESP': [
        '.r.r.KKK.........KKK.r.r..',
        '.r.r.KppK.......KppK.r.r..',
        '.....KpppK.....KpppK......',
        '.r.rKppppdK...KdppppK.r.r.',
        '....KdpppdK...KdpppdK.....',
        'KK...KddddKKKKKddddK...KK.',
        'KgK...KggggggggggggK..KgK.',
        '.KgK.KggggggggggggggK.KgK.',
        '..KgKgggeegggggggeegggKK..',
        '...KggggewgggggggewggggK..',
        '...KgggggggggnngggggggK...',
        '.ss.KggggggKoKggggggKss...',
        '..s.KgggglllllllllggKs....',
        '....KggglllllllllllgK.....',
        '....KggglllllllllllgK.....',
        '....KgggglllllllllggKKK...',
        '....KggggllllllllgggKdddK.',
        '.....KgggglllllllggKddddK.',
        '......KgggglllllggKdddK...',
        '.......KKgggggggKKKKdK....',
        '........KgK...KgK..KK.....',
        '........KKK...KKK.........',
    ],
    'PHONE': [
        '....KKK..........KKK......',
        '...KpppK........KpppK.....',
        '..KppppdK......KdppppK....',
        '..KppppdK......KdppppK....',
        '..KdpppdK......KdpppdK....',
        '...KddddKKKKKKKKddddK.....',
        '....KggggggggggggggK......',
        '...KggggggggggggggggK.....',
        '..KggggggggggggggggggK....',
        '..KgggKKggggggggKKgggK....',
        '..KggggggggnngggggggggK...',
        'ss.KggggggglllggggggKss...',
        '..sKgggggKxxxxxKgggKs.....',
        '...KggggKxccccxKgggK......',
        '..KgggggKxccccxKggggK.....',
        '..KggggKgxccccxgKgggKKK...',
        '..KggggglxxxxxxlggggKdddK.',
        '...KggggllllllllgggKKddddK',
        '....KgggglllllgggggKdddK..',
        '.....KKgggggggggggKKKdK...',
        '......KgK......KgK..KK....',
        '......KKK......KKK........',
    ],
    'FRIDGE': [
        'KKKKKKKKKKKKKK',
        'KffffffffffffK',
        'KfffffffffKffK',
        'KfffffffffKffK',
        'KffffffffffffK',
        'KKKKKKKKKKKKKK',
        'KffffffffffffK',
        'KfffffffffKffK',
        'KfffffffffKffK',
        'KfffffffffKffK',
        'KfffffffffKffK',
        'KffffffffffffK',
        'KffffffffffffK',
        'KffffffffffffK',
        'KffffffffffffK',
        'KffffffffffffK',
        'KKKKKKKKKKKKKK',
        '.KK........KK.',
    ],
    'FRIDGE_OPEN': [
        'KKKKKKKKKKKKKKKKKK',
        'KiiiiiiiiiiiiKffKK',
        'KiiOiiqqiiiiiKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KKKKKKKKKKKKKKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KiqqiiiiiOOiiKffKK',
        'KiqqiiiiiOOiiKffKK',
        'KmmmmmmmmmmmmKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KiiiOOOiiiqqiKffKK',
        'KiiiOOOiiiqqiKffKK',
        'KmmmmmmmmmmmmKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KiiiiiiiiiiiiKffKK',
        'KKKKKKKKKKKKKKKKKK',
        '.KK........KK.....',
    ],
    'BED': [
        'KK................................',
        'KBK...............................',
        'KBK...............................',
        'KBK...............................',
        'KBKKKKKK..........................',
        'KBKPPPPPK.........................',
        'KBKPPPPPPKKKKKKKKKKKKKKKKKKKKKKKKK',
        'KBKKKKKKKuuuuuuuuuuuuuuuuuuuuuuuuK',
        'KBKBBBBBKvvvvvvvvvvvvvvvvvvvvvvvvK',
        'KBKBBBBBBKKKKKKKKKKKKKKKKKKKKKKKKK',
        'KBKBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK',
        'KBKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK',
        'KK.KK.........................KK..',
    ],
    'BED_SLEEP': [
        'KK.......uu........................',
        'KBK.....uuvv.......................',
        'KBK....uuuuvv......................',
        'KBK...KKKKKKuuv....................',
        'KBKKKKgggggggKy....................',
        'KBKPPKgKKgggggKKKKK................',
        'KBKPPKggggggggnKKuKKKKKKKKKKKKKKKKK',
        'KBKKKKKggggggKKuuuuuuuuuuuuuuuuuuuK',
        'KBKBBBBKKKKKKvvvvvvvvvvvvvvvvvvvvvK',
        'KBKBBBBBBKKKKKKKKKKKKKKKKKKKKKKKKKK',
        'KBKBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK',
        'KBKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK',
        'KK.KK.........................KK...',
    ],
    'PJ1': [
        '........uu....KKK...........',
        '.......uuvv..KpppK..........',
        '......uuuvvvKppppdK.........',
        '............KdpppdK.........',
        '.KKK........KKddKKKK........',
        'KdddK.....KKgggggggKK.......',
        'KddddKKKKKuuuuuuuggggK......',
        '.KddddKvvvvvvvvvvgeeggK.....',
        '..KddduuuuuuuuuuugewgggnKs..',
        '...KvvvvvvvvvvvvvgggggKKss..',
        '...KuuuuuuuuuuuuuggllllK.s..',
        '...KvvvvvvvvvvvlllllllK.....',
        '....KuuuuuuuulllllllKK......',
        '.....KgK..KgK....KgK.KgK....',
        '.....KKK..KKK....KKK.KKK....',
    ],
    'PJ2': [
        '........uu....KKK...........',
        '.......uuvv..KpppK..........',
        '......uuuvvvKppppdK.........',
        '............KdpppdK.........',
        '.KKK........KKddKKKK........',
        'KdddK.....KKgggggggKK.......',
        'KddddKKKKKuuuuuuuggggK......',
        '.KddddKvvvvvvvvvvgeeggK.....',
        '..KddduuuuuuuuuuugewgggnKs..',
        '...KvvvvvvvvvvvvvgggggKKss..',
        '...KuuuuuuuuuuuuuggllllK.s..',
        '...KvvvvvvvvvvvlllllllK.....',
        '....KuuuuuuuulllllllKK......',
        '......KgKKgK......KgKKgK....',
        '......KKKKKK......KKKKKK....',
    ],
    'MED': [
        'y...KKK..........KKK...y..',
        '...KpppK........KpppK.....',
        '..KppppdK......KdppppK....',
        '..KppppdK......KdppppK....',
        '..KdpppdK......KdpppdK....',
        '...KddddKKKKKKKKddddK.....',
        '....KggggggggggggggK......',
        '...KggggggggggggggggK.....',
        '..KgggggggggggggggggK.....',
        '..KgggKKggggggggKKggK.....',
        '..KgggggggggnngggggggK....',
        'ss.KggggggglllggggggKss...',
        '..sKggggglllllllgggKs.....',
        '...KgggglllllllllgggK.....',
        '..KKgggglllllllllggggKK...',
        '.KgKKggglllllllllggKKgK...',
        '.KgK.KgglllllllllgK.KgK...',
        'KlllKKKgglllllllggKKKlllK.',
        'KllllllKKgggggggKKllllllK.',
        '.KKllllllKKKKKKKllllllKK..',
        '..zKKKKKKzzzzzzzzKKKKKKz..',
        '.zZZZZZZZZZZZZZZZZZZZZZz..',
        '..zzzzzzzzzzzzzzzzzzzzz...',
    ],
    'INCENSE': [
        '...R..',
        '...t..',
        '...t..',
        '...t..',
        '...t..',
        '...t..',
        '.KtKK.',
        'KBBBBK',
        '.KKKK.',
    ],
    'SNACK1': [
        '..............KKK...........',
        '.............KpppK..........',
        '............KppppdK.........',
        '............KppppdK.........',
        '............KdpppdK.........',
        '.............KdddKKKK.......',
        '...........KKgggggggKK......',
        '..........KggggggggggggK....',
        '.........KgggggggggeeggK....',
        '.........KgggggggggewgggK...',
        '........KgggggggggggggggnK.s',
        '........KggggggggggggKKbKss.',
        '.KKK....KgggggggggggKggbK.s.',
        'KdddK...KggggggggggKggKK....',
        'KddddK.KgggggggggglllllK....',
        '.KddddKKggggggggggllllK.....',
        '..KddddKgggggggggglllllK....',
        '...KdddKggggggggggllllllK...',
        '....KddKgggggggggglllllK....',
        '.....KKKggggggggggglllK.....',
        '.......KgggggggggggggK......',
        '.......KggggKKKKKKgggK......',
        '.......KgggKggggggggggK.....',
        '........KKKKKKKKKKKKKKK.....',
    ],
    'SNACK2': [
        '...............KKK..........',
        '..............KpppK.........',
        '............KppppdK.........',
        '............KppppdK.........',
        '............KdpppdK.........',
        '.............KdddKKKK.......',
        '...........KKgggggggKK......',
        '..........KggggggggggggK....',
        '.........KgggggggggeeggK....',
        '.........KgggggggggewgggK...',
        '........KgggggggggggggggnK.s',
        '........KggggggggggggggKKss.',
        '.KKK....KgggggggggggglllK.s.',
        'KdddK...KggggggggggllKbbK...',
        'KddddK.KggggggggggllKggK....',
        '.KddddKKggggggggggllllK.....',
        '..KddddKgggggggggglllllK....',
        '...KdddKggggggggggllllllK...',
        '....KddKgggggggggglllllK....',
        '.....KKKggggggggggglllK.....',
        '.......KgggggggggggggK......',
        '.......KggggKKKKKKgggK......',
        '.......KgggKggggggggggK.....',
        '........KKKKKKKKKKKKKKK.....',
    ],
}

# Measure icons: '#' = outline / solid ink, 'a' = 40 % ink fill, '.' = none
ART = {
    'ABR': [
        '....................................',
        '.......................######.......',
        '......................#aaaaaa#......',
        '.....................#aaaaa#aa#.....',
        '....................#aaaaaaa#aa#....',
        '....................#aaaaaaaa#a#....',
        '......##............#aa###aaaa##....',
        '......##...........#aa#...#aaaaa#...',
        '.....###..##.......#a#.....#aaaa#...',
        '.....#.#..##.......#a#.....#aaaa#...',
        '.###.#.#..###......#a#.....#aaaa#...',
        '##.#.#.#.##.##.....#a###...#aaaa#...',
        '...#.#.#.#..##......####...#aaa#....',
        '...#.#.###..........##.....#aaa#....',
        '...###..##..........#a#...#aaaa#....',
        '........##...........#a###aaaa#.....',
        '........##............#aaaaaa#......',
        '.......................#aaaa#.......',
        '......................#aaaa#........',
        '......................#aaaa#........',
        '.......................#aa#.........',
        '........................##..........',
    ],
    'EFR': [
        '............................######..........',
        '.........................####aa#####........',
        '.##....................######a######a#......',
        '.##...................##aa####aa####a##.....',
        '.##....##.##.........#####a####a#aa#####....',
        '.##.##.##.##.........##a###aa###a###a###....',
        '.##.##.##.###.##....###aa####a###a##aa###...',
        '###.#######.####.#...####a###aa###a####a#...',
        '..###.##.##.##.####..###aa##a####aa##a###...',
        '..##.....##.##.#.#....#####a###a#####a##....',
        '..##.....##....#.......##############.##....',
        '.........##..............#######..###.......',
        '.........##.......................###.......',
        '...................................###......',
        '....................................##......',
        '............................................',
    ],
    'OAE': [
        '........................................',
        '...#####################################',
        '...#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa#',
        '...#####################################',
        '.....................#.......#.......#..',
        '........##.........#.#.....#.#.....#.#..',
        '.......###.......#.#.#...#.#.#...#.#.#..',
        '.......###.......#.#.#...#.#.#...#.#.#..',
        '.......###.......#####...#####...#####..',
        '.......#a#.......#aaa#...#aaa#...#aaa#..',
        '.......#a#.......#aaa#...#aaa#...#aaa#..',
        '......#aa#.......#aaa#...#aaa#...#aaa#..',
        '.....#aaaa#......#aaa#...#aaa#...#aaa#..',
        '....#aaaaaa#.....#aaa#...#aaa#...#aaa#..',
        '....#aa##aa#.....#aaa#...#aaa#...#aaa#..',
        '....#aa##aa#.....#a#a#...#a#a#...#a#a#..',
        '....#aa##aa#.....#####...#####...#####..',
        '.....#aaaa#......#a#a#...#a#a#...#a#a#..',
        '......#aa#.......#aaa#...#aaa#...#aaa#..',
        '.......##........#aaa#...#aaa#...#aaa#..',
        '..................###.....###.....###...',
        '........................................',
    ],
    'MEMR': [
        '....................................',
        '...####............#................',
        '..#aaaa#...########a#...............',
        '..#aaaa#..#aaaaaa###................',
        '..#aaaa#.#aaaaaa#...................',
        '..#aaaa#.#aaaaaa#...................',
        '..#aaa#...#aaaa#....................',
        '###aa#.....##a#.....................',
        '...#a#.......##.....................',
        '...#a#.......#a#................##..',
        '...#a#........##.............###a#..',
        '...#a#........#a#..........####.##..',
        '...#a#.........##.......#####...##..',
        '...#a#.........#a#..#.####......##..',
        '...#a#..........#a##a#a#........##..',
        '...#a#..........###.######......##..',
        '...##...................#####...##..',
        '...##......................####.##..',
        '...##........................###a#..',
        '................................##..',
    ],
}


def hex_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def sprite_image(rows, scale, mirror=False):
    W = max(len(r) for r in rows)
    rows = [r.ljust(W, '.') for r in rows]
    im = Image.new('RGBA', (W, len(rows)), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c in PAL:
                px[x, y] = hex_rgb(PAL[c]) + (255,)
    if mirror:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    return im.resize((W * scale, len(rows) * scale), Image.NEAREST)


def art_image(rows, scale):
    W = max(len(r) for r in rows)
    im = Image.new('RGBA', (W, len(rows)), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(rows):
        for x, c in enumerate(r.ljust(W, '.')):
            if c == '#':
                px[x, y] = INK + (255,)
            elif c == 'a':
                px[x, y] = INK + (102,)
    return im.resize((W * scale, len(rows) * scale), Image.NEAREST)


def incense_smoke():
    """Incense with a 3-row smoke puff above (two frames)."""
    base = SPRITES['INCENSE']
    f1 = ['....m.', '...m..', '..m...'] + base
    f2 = ['..m...', '...m..', '....m.'] + base
    return f1, f2


def main():
    out = []
    for name, key in (('icon_abr', 'ABR'), ('icon_efr', 'EFR'),
                      ('icon_oae', 'OAE'), ('icon_memr', 'MEMR')):
        out.append((name, art_image(ART[key], ICON_SCALE)))
        out.append((name + '_sm', art_image(ART[key], 1)))   # Results bar (1x)
    plain = {'chin_front': 'FRONT', 'chin_happy': 'HAPPY', 'chin_desp': 'DESP',
             'chin_phone': 'PHONE', 'chin_snack1': 'SNACK1', 'chin_snack2': 'SNACK2',
             'chin_fridge': 'FRIDGE', 'chin_fridge_open': 'FRIDGE_OPEN',
             'chin_bed': 'BED', 'chin_bed_sleep': 'BED_SLEEP', 'chin_med': 'MED'}
    for name, key in plain.items():
        out.append((name, sprite_image(SPRITES[key], SPRITE_SCALE)))
    out.append(('chin_front_lg', sprite_image(SPRITES['FRONT'], SIGN_SCALE)))
    for name, key in (('chin_walk1', 'WALK1'), ('chin_walk2', 'WALK2'),
                      ('chin_pj1', 'PJ1'), ('chin_pj2', 'PJ2')):
        out.append((name, sprite_image(SPRITES[key], SPRITE_SCALE)))
        out.append((name + '_l', sprite_image(SPRITES[key], SPRITE_SCALE, mirror=True)))
    f1, f2 = incense_smoke()
    out.append(('chin_incense', sprite_image(f1, SPRITE_SCALE)))
    out.append(('chin_incense2', sprite_image(f2, SPRITE_SCALE)))
    for name, im in out:
        im.save(os.path.join(HERE, name + '.png'))
    return out


if __name__ == '__main__':
    for n, im in main():
        print(n, im.size)
