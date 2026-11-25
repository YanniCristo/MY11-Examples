import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.002, d=0.2):
    x = np.arange(n) / SR
    e = np.minimum(1, x / a) * np.exp(-x / d)
    return e


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], 'band', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def lp(x, f, order=2):
    sos = signal.butter(order, f, 'low', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def hp(x, f, order=2):
    sos = signal.butter(order, f, 'high', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def norm(x, peak=0.9):
    x = x - np.mean(x)
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def fade(x, ms=8):
    n = int(SR * ms / 1000)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x):
    x = fade(norm(x))
    wavfile.write(name, SR, (x * 32767).astype(np.int16))


# 1. COLPO: tonfo basso + schiocco + crepitio di macerie
def colpo():
    d = 0.55
    tt = t(d)
    f = 160 * np.exp(-tt * 9) + 70
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(tt), 0.001, 0.13)
    # corpo del colpo nella zona che l'altoparlante del telefono riproduce
    body = bp(rng.standard_normal(len(tt)), 250, 1200) * env(len(tt), 0.001, 0.05)
    thump = hp(thump, 90, 2) * 0.55 + body * 1.6
    crack = hp(rng.standard_normal(len(tt)), 2500) * env(len(tt), 0.0005, 0.012)
    debris = np.zeros(len(tt))
    for _ in range(14):
        s = int(SR * (0.03 + rng.random() * 0.4))
        n = int(SR * (0.006 + rng.random() * 0.02))
        g = bp(rng.standard_normal(n), 900 + rng.random() * 2500, 5000) * env(n, 0.0005, 0.006)
        debris[s:s + n] += g[: len(debris) - s] * (0.5 * np.exp(-(s / SR) * 4))
    return thump + crack * 0.8 + debris * 0.6


# 2. POP del popcorn: due scoppiettii
def pop():
    d = 0.45
    out = np.zeros(int(SR * d))
    for start, f0, amp in ((0.0, 1100, 1.0), (0.18, 1450, 0.7)):
        n = int(SR * 0.09)
        tt = t(0.09)
        f = f0 * np.exp(-tt * 38) + 260
        tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.0005, 0.03)
        click = hp(rng.standard_normal(n), 3000) * env(n, 0.0002, 0.004)
        s = int(SR * start)
        out[s:s + n] += (tone + 0.5 * click) * amp
    return out


# 3. GNAM: due morsi con la bocca che si apre e si chiude
def gnam():
    d = 0.5
    tt = t(d)
    f0 = 210 + 30 * np.sin(2 * np.pi * 2 * tt)
    saw = signal.sawtooth(2 * np.pi * np.cumsum(f0) / SR)
    mouth = np.zeros(len(tt))
    for c, w in ((0.1, 0.07), (0.32, 0.08)):
        mouth += np.exp(-((tt - c) / w) ** 2)
    # "bocca" = filtro che si apre: mescolo due bande pesate dall'apertura
    open_ = bp(saw, 500, 1600)
    closed = lp(saw, 350)
    voice = (open_ * mouth + closed * 0.35 * mouth)
    chomp = np.zeros(len(tt))
    for c in (0.16, 0.39):
        s = int(SR * c)
        n = int(SR * 0.03)
        chomp[s:s + n] += bp(rng.standard_normal(n), 1500, 6000) * env(n, 0.0005, 0.008)
    return voice + 0.5 * chomp


# 4. RUTTO da cartone: tono basso che vibra e scende, con "eco"
def rutto():
    d = 0.9
    tt = t(d)
    f0 = 150 - 45 * tt + 8 * np.sin(2 * np.pi * 7 * tt)
    jitter = 1 + 0.08 * lp(rng.standard_normal(len(tt)), 30) * 8
    phase = 2 * np.pi * np.cumsum(f0 * jitter) / SR
    src = signal.sawtooth(phase, 0.3)
    flutter = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 23 * tt + 2 * lp(rng.standard_normal(len(tt)), 15) * 10))
    voice = bp(src * flutter, 250, 1100) + 0.8 * bp(src * flutter, 900, 2200)
    e = np.minimum(1, tt / 0.04) * np.clip(1.25 - tt * 1.4, 0, 1)
    dry = hp(voice, 220, 4) * e
    # piccola eco "distruttiva"
    out = dry.copy()
    for delay, g in ((0.12, 0.35), (0.24, 0.18)):
        k = int(SR * delay)
        out[k:] += dry[:-k] * g
    return out


if __name__ == '__main__':
    import sys
    d = sys.argv[1]
    save(f'{d}/1_colpo.wav', colpo())
    save(f'{d}/2_pop_popcorn.wav', pop())
    save(f'{d}/3_gnam.wav', gnam())
    save(f'{d}/4_rutto.wav', rutto())
