#!/usr/bin/env python3
import math

POINTS=1024
def to_hex(val, nbits):
  return hex((val + (1 << nbits)) % (1 << nbits)).lstrip('0x')

with open("sine.mem", "w") as w:
    i=0
    while i<=2*math.pi:
        val = to_hex(int(2**12*math.sin(i)), 24)
        w.write(f"{val}\n")
        i+=2*math.pi/POINTS
