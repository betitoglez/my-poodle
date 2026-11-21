"""Cuatro notas originales, PCM mono a 44,1 kHz, sin dependencias ni red."""
import math
from pathlib import Path
import struct
import wave

root = Path(__file__).resolve().parents[2] / 'assets/audio/sfx'
for name, frequency in [('red', 261.63), ('blue', 329.63),
                        ('green', 392.0), ('yellow', 523.25)]:
    rate, seconds = 44100, .42
    samples = []
    for i in range(int(rate * seconds)):
        t = i / rate
        envelope = min(t / .015, 1) * min((seconds - t) / .08, 1)
        tone = math.sin(2 * math.pi * frequency * t)
        tone += .15 * math.sin(4 * math.pi * frequency * t)
        samples.append(struct.pack('<h', int(16000 * envelope * tone / 1.15)))
    with wave.open(str(root / f'memory_{name}.wav'), 'wb') as audio:
        audio.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(samples))
