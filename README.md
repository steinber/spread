spread v0.7 entropybound

each voice wanders stochastically by single steps along a chosen scale, synced to divisions of the global clock, and you can lock in patterns (lengths up to 16 steps) to add some regularity before releasing it again.

you can adjust many aspects of each voice
- instrument (whatever is available from mx.samples - but i don't check for whether you've downloaded it!)
- gaussian spread, relative to central note (i.e. sigma=1-4)
- rate - in divisions of clock speed (1-8)
- octave (1-6)
- central note (within the octave)
- phrase-lock (turing machine style)
- phrase length (it buffers the last 2-16 steps)

atm, still some conditions underwhich you lose control of a voice.

tbd:
- global key change
- - midi panic
- global panic
- perhaps a more clever way to select faster time divisions (e.g. step by 2^n, with nudge)
- crow output (independent? fully synced?)
