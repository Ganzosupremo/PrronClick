"""Repeat bars 8-11 (16.07-24.07 s) after 24.07 s so the track runs 8 s longer, then trim + fade.
usage: extend.py in.wav out.wav total_s"""
import wave, array, sys
w = wave.open(sys.argv[1]); p = w.getparams(); a = array.array('h', w.readframes(p.nframes)); w.close()
r, ch = p.framerate, p.nchannels
idx = lambda s: int(round(s * r)) * ch
A, B, X = idx(24.07), idx(16.07), idx(0.03)  # splice at 24.07 back to 16.07 (same bar phase), 30 ms crossfade
out = a[:A - X]
for i in range(0, X, ch):
    k = i / X
    for c in range(ch):
        out.append(int(a[A - X + i + c] * (1 - k) + a[B - X + i + c] * k))
out.extend(a[B:])
total = idx(float(sys.argv[3])); out = out[:total]
fi, fo = idx(0.02), idx(1.5)
for i in range(0, fi, ch):
    for c in range(ch): out[i + c] = int(out[i + c] * i / fi)
for i in range(0, fo, ch):
    j = total - fo + i
    for c in range(ch): out[j + c] = int(out[j + c] * (1 - i / fo))
assert len(out) == total, (len(out), total)
o = wave.open(sys.argv[2], 'wb'); o.setparams(p); o.writeframes(out.tobytes()); o.close()
print('in', p.nframes / r, 's  out', len(out) / ch / r, 's')
