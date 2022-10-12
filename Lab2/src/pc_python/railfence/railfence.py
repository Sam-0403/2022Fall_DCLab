#!/usr/bin/env python
from sys import argv, stdin, stdout
from struct import unpack, pack
def enc(y):
	y = format(y, '#0258b')[2:]
	r1 = ""
	r2 = ""
	assert len(y)==256,"y length = {}".format(len(y))
	for i in range(0, 256, 2):
		r1 += y[i]
		r2 += y[i+1]
	assert len(r1)==128,"r1 length = {}".format(len(r1))
	assert len(r2)==128,"r1 length = {}".format(len(r2))

	return int(r1+r2, 2)
	
def dec(y):
	y = format(y, '#0258b')[2:]
	assert len(y)==256,"y length = {}".format(len(y))
	r1 = y[0:128]
	assert len(r1)==128,"r1 length = {}".format(len(r1))
	r2 = y[128:]
	x = ""
	for i in range(128):
		x += r1[i] 
		x += r2[i]
	return int(x, 2)

def railfence(m, y):
	if m == 'e':
		return enc(y)
	elif m == 'd':
		return dec(y)


if __name__ == '__main__':

    assert len(argv) == 2, "Usage: {} e|d".format(argv[0])
    if argv[1] == 'e':
        r_chunk_size = 31
        w_chunk_size = 32
    else:
        r_chunk_size = 32
        w_chunk_size = 31
    while True:
        chunk = stdin.read(r_chunk_size)
        n_read = len(chunk)
        if n_read < r_chunk_size:
            if n_read != 0:
                print "There are {} trailing bytes left (ignored).".format(n_read)
            break
        else:
            vals = unpack("{}B".format(r_chunk_size), chunk)
            msg = 0
            for val in vals:
                msg = (msg<<8) | val
            msg_new = railfence(argv[1], msg)
            vals_new = map(lambda shamt: (msg_new>>shamt)&255, range((w_chunk_size-1)*8, -8, -8))
            vals_new = pack("{}B".format(w_chunk_size), *vals_new)
            stdout.write(vals_new)