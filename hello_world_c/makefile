CC=m68k-linux-gnu-gcc
LD=m68k-linux-gnu-ld
LDFLAGS=-v -z noexecstack -T cms307.ld
OBJCOPY=m68k-linux-gnu-objcopy
OBJS=init307.o uart.o hello_world.o

hello_world.hex: hello_world.a 
	$(OBJCOPY) -O ihex $^ $@

hello_world.a: $(OBJS) cms307.ld
	$(LD) $(LDFLAGS) -o $@ -Map $(basename $@).map $(OBJS)

%.o: %.S
	$(CC) -c -Wa,-mcpu=68307 -Wa,--register-prefix-optional -Wa,-a=$(basename $@).lst $^

%.o: %.c
	$(CC) -march=68000 -c $^

clean:
	rm -f hello_world.a
	rm -f hello_world.map
	rm -f hello_world.hex
	rm -f *.lst
	rm -f *.o
