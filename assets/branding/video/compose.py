"""Composites the PrronClick promo: Codesign cards + phone takes, streams raw RGB to stdout.

usage: compose.py DIR [--preview t1,t2,...]   (preview writes PNGs instead of streaming)

DIR holds cards/*.png (exported from prronclick-promo-cards.imgly), takes/*.mp4 (adb screenrecord, demo songs at 120 BPM)
and f30/<take>/NNNN.png, made per take with:
  gst-launch-1.0 filesrc location=takes/T.mp4 ! decodebin ! videoconvert ! videorate ! video/x-raw,framerate=30/1
    ! videocrop top=110 bottom=155 ! videoscale method=lanczos ! video/x-raw,width=445,height=880
    ! videoconvert ! pngenc ! multifilesink location=f30/T/%04d.png
Encode: python compose.py DIR | gst-launch-1.0 -e fdsrc fd=0 blocksize=6220800 ! rawvideoparse width=1920 height=1080
  format=rgb framerate=30/1 ! videoconvert ! video/x-raw,format=I420 ! x264enc bitrate=12000 ! h264parse
  ! mp4mux name=mux ! filesink location=out.mp4  filesrc location=music-38.wav ! wavparse ! audioconvert
  ! voaacenc bitrate=192000 ! aacparse ! mux.
(music.wav = music-stable-audio-3-v1.mp3 decoded to 48 kHz S16 stereo;
 music-38.wav = extend.py music.wav music-38.wav 38: bars 8-11 repeated once, 1.5 s fade-out.)
"""
import sys
from PIL import Image, ImageDraw

S = sys.argv[1]
FPS, W, H, DUR = 30, 1920, 1080, 38.0
# screen hole in the cards (must match the Codesign V_* pages)
SW, SH = 445, 880
SX, SY = W - 120 - 14 - SW, (H - SH) // 2
BEZEL = (0x12, 0x0D, 0x33)
XF = 0.25  # crossfade seconds

# (start, end, card, take, take_start_s). Every cut sits on a downbeat of the 120 BPM track
# (bars start at 0.07 + 2k s). take_start for the playing takes is chosen so the app's beat-1
# flash (metro 3.35 s, lyrics 3.33 s, then every 2 s) lands on the music's downbeats.
D = 0.07
SEG = [
    (0.0, D + 4, 'intro', None, 0),
    (D + 4, D + 8, 'metro', 't-metro', 3.35),
    (D + 8, D + 14, 'lyrics', 't-lyrics', 9.33),  # Intro -> Verse 1 at 11.33 s
    (D + 14, D + 18, 'setlist', 't-setlist', 1.7),
    (D + 18, D + 22, 'songs', 't-songs', 1.0),
    (D + 22, D + 26, 'band', 't-band', 2.5),
    (D + 26, D + 30, 'practice', 't-practice', 7.2),
    (D + 30, D + 34, 'history', 't-history', 1.5),
    (D + 34, DUR, 'end', None, 0),  # the track drops to its outro here
]
cards = {c: Image.open(f'{S}/cards/{c}.png').convert('RGB') for _, _, c, _, _ in SEG}
for c, im in cards.items():
    assert im.size == (W, H), (c, im.size)

# bezel-coloured corners outside the rounded screen, pasted over the video
corner = Image.new('RGBA', (SW, SH), BEZEL + (255,))
hole = Image.new('L', (SW, SH), 255)
ImageDraw.Draw(hole).rounded_rectangle((0, 0, SW - 1, SH - 1), 50, fill=0)
corner.putalpha(hole)

nframes = {}
def take_frame(take, t):
    if take not in nframes:
        import os
        nframes[take] = len(os.listdir(f'{S}/f30/{take}'))
    i = min(max(int(round(t * FPS)), 0), nframes[take] - 1)  # hold the last frame
    return Image.open(f'{S}/f30/{take}/{i:04d}.png').convert('RGB')

def zoomed(card, k):
    if k == 1.0:
        return card.copy()
    w, h = round(W * k), round(H * k)
    big = card.resize((w, h), Image.BICUBIC)
    x, y = (w - W) // 2, (h - H) // 2
    return big.crop((x, y, x + W, y + H))

def seg_frame(seg, t):
    a, b, card, take, ts = seg
    if take is None:  # slow push-in on the brand cards
        return zoomed(cards[card], 1.0 + 0.035 * (t - a) / (b - a))
    im = cards[card].copy()
    im.paste(take_frame(take, ts + (t - a)), (SX, SY))
    im.paste(corner, (SX, SY), corner)
    return im

def frame(t):
    for i, seg in enumerate(SEG):
        if seg[0] <= t < seg[1] or i == len(SEG) - 1:
            break
    im = seg_frame(seg, t)
    # crossfade only into/out of the brand cards; card-to-card is a hard cut on the beat
    # (two headlines blended over each other read as mush)
    if i > 0 and t < seg[0] + XF and (seg[3] is None or SEG[i - 1][3] is None):
        im = Image.blend(seg_frame(SEG[i - 1], t), im, (t - seg[0]) / XF)
    if t > DUR - 0.5:  # fade to black at the very end
        im = Image.blend(im, Image.new('RGB', (W, H)), (t - (DUR - 0.5)) / 0.5)
    return im

if __name__ == '__main__':
    if len(sys.argv) > 3 and sys.argv[2] == '--preview':
        for t in map(float, sys.argv[3].split(',')):
            frame(t).save(f'{S}/preview-{t:05.2f}.png')
    else:
        out = sys.stdout.buffer
        for n in range(int(DUR * FPS)):
            out.write(frame(n / FPS).tobytes())
