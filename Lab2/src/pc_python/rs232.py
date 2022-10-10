#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv

assert len(argv) == 2
s = Serial(
    port=argv[1],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)
for i in range(3):
    fp_key = open(f'./golden/key{i+1}.bin', 'rb')
    fp_enc = open(f'./golden/enc{i+1}.bin', 'rb')
    fp_dec = open(f'./golden/dec{i+1}.bin', 'wb')
    assert fp_key and fp_enc and fp_dec

    key = fp_key.read(64)
    enc = fp_enc.read()
    # finish signal: key
    enc += key[0:31]
    assert len(enc) % 32 == 0

    s.write(key)
    for i in range(0, len(enc), 32):
        s.write(enc[i:i+32])
        dec = s.read(31)
        fp_dec.write(dec)

    s.write(key)

    fp_key.close()
    fp_enc.close()
    fp_dec.close()
