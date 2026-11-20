"""Feature graphic 1024x500: a FEAT_* page exported from Codesign + an app screen in its phone.
usage: feature.py card.png screen.png out.png [top [bar_end]]
screen: a raw 1080x2400 device capture (cropped from y=top, default 110, down to the nav bar at 2245;
a larger top scrolls the view down; with bar_end the app bar 110..bar_end stays pinned on top, as in the app) or a frame already cropped to the screen (445x880 from the video takes)."""
import sys
from PIL import Image, ImageDraw
X, Y, SW, SH, R = 669, 44, 267, 528, 30  # screen hole of FEAT_* (vphone scaled 0.6, at y=36)
BEZEL, APP_BG = (0x12, 0x0D, 0x33, 255), (0x1A, 0x14, 0x42)
card = Image.open(sys.argv[1]).convert('RGB'); assert card.size == (1024, 500), card.size
src = Image.open(sys.argv[2]).convert('RGB')
if src.size == (1080, 2400):
    top = int(sys.argv[4]) if len(sys.argv) > 4 else 110
    body = src.crop((0, top, 1080, 2245))
    if len(sys.argv) > 5:
        bar = src.crop((0, 110, 1080, int(sys.argv[5])))
        src = Image.new('RGB', (1080, bar.height + body.height)); src.paste(bar, (0, 0)); src.paste(body, (0, bar.height))
    else:
        src = body
h = round(src.height * SW / src.width)
scr = Image.new('RGB', (SW, SH), APP_BG)
scr.paste(src.resize((SW, h), Image.LANCZOS).crop((0, 0, SW, min(h, SH))), (0, 0))
card.paste(scr, (X, Y))
corner = Image.new('RGBA', (SW, SH), BEZEL); hole = Image.new('L', (SW, SH), 255)
ImageDraw.Draw(hole).rounded_rectangle((0, 0, SW - 1, SH - 1), R, fill=0); corner.putalpha(hole)
card.paste(corner, (X, Y), corner)
assert card.size == (1024, 500)
card.save(sys.argv[3])

# How each graphic was made (cards = pages FEAT_<variant>_<lang> and FEAT_CARD of ../prronclick-branding.imgly,
# exported as PNG; screens = raw 1080x2400 captures of the app in that language with the demo library):
#   01-metronome  feature.py FEAT_metro_<l>.png   <metronome capture> out.png
#   02-lyrics     feature.py FEAT_lyrics_<l>.png  <lyrics capture>    out.png
#   03-setlist    feature.py FEAT_setlist_<l>.png <setlist capture>   out.png 780 250   (app bar pinned, list scrolled)
#   04-band       feature.py FEAT_band_<l>.png    <metronome with Band on, Leader picked> out.png
#                 (en-US uses page FEAT_CARD and the ../video/takes/t-band.mp4 frame at 6.67 s, 445x880)
