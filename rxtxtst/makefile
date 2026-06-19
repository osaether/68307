CC=m68k-linux-gnu-gcc
LD=m68k-linux-gnu-ld
LDFLAGS=-v -z noexecstack -T cms307.ld
INCLUDE=-I../include
OBJCOPY=m68k-linux-gnu-objcopy

rxtxtst.hex: rxtxtst.a
	$(OBJCOPY) -O ihex $^ $@

rxtxtst.a: rxtxtst.o cms307.ld
	$(LD) $(LDFLAGS) -o $@ -Map $(basename $@).map $(basename $@).o

%.o: %.S
	$(CC) $(INCLUDE) -c -Wa,-mcpu=68307 -Wa,--register-prefix-optional -Wa,-a=$(basename $@).lst $^

%.o: %.c
	$(CC) -march=68000 -c $^

clean:
	rm -f rxtxtst.o
	rm -f rxtxtst.a
	rm -f rxtxtst.lst
	rm -f rxtxtst.map
	rm -f rxtxtst.hex
