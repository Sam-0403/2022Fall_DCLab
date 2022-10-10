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
for j in range(1):
    fp_key = open('./golden/key.bin', 'rb')
    fp_enc = open('./golden/enc{index}.bin'.format(index=j+1), 'rb')
    fp_dec = open('./test/dec{index}.bin'.format(index=j+1), 'wb')
    assert fp_key and fp_enc and fp_dec

    key = fp_key.read(64)
    enc = fp_enc.read()
    print(len(key))
    print(len(enc))
    # finish signal: key
    enc += key    # add FINISH signal
    assert len(enc) % 32 == 0
    print(len(enc))

    s.write(key)
    for i in range(0, len(enc)-64, 32):
        s.write(enc[i:i+32])
        print("Dec start")
        dec = s.read(31)
        print("Dec end")
        fp_dec.write(dec)

    fp_key.close()
    fp_enc.close()
    fp_dec.close()
