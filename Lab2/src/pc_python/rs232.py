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
while True:
    # print("Index: {index}".format(index=j+1))
    try:
        type_enc = input("Enter the encrypted type (0:RS232/1:RailFence): ")
        idx = input("Enter the encrypted file index: ")
        fp_key = open('./golden/key.bin', 'rb')
        fp_dec = open('./test/dec{index}.bin'.format(index=idx), 'wb')
        if type_enc=="1":
            fp_enc = open('./railfence/enc{index}.bin'.format(index=idx), 'rb')
        else:
            fp_enc = open('./golden/enc{index}.bin'.format(index=idx), 'rb')
        assert fp_key and fp_enc and fp_dec

        key = fp_key.read(64)
        enc = fp_enc.read()
        # print(len(key))
        # print(len(enc))
        enc += key    # add FINISH signal
        assert len(enc) % 32 == 0
        # print(len(enc))

        s.write(key)
        for i in range(0, len(enc)-32, 32):
            s.write(enc[i:i+32])
            # print("Dec start")
            if i<len(enc)-64:
                dec = s.read(31)
                # print("Dec end")
                fp_dec.write(dec)
            # else:
                # print("Finish signal sent")

        fp_key.close()
        fp_enc.close()
        fp_dec.close()
    except KeyboardInterrupt:
        print("Decryption is done!")