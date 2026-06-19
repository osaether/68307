# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Toolchain

Cross-compiler for m68k on Ubuntu:
```
sudo apt install gcc-m68k-linux-gnu
```

Tools used: `m68k-linux-gnu-gcc`, `m68k-linux-gnu-ld`, `m68k-linux-gnu-objcopy`

## Build

Each project is a self-contained subdirectory. Build from within the project directory:

```bash
cd hello_world       # or hello_world_irq, hello_world_c, rxtxtst
make                 # produces <name>.hex (flashable) + <name>.lst + <name>.map
make clean
```

The output `.hex` is Intel HEX format ready to flash. The `.lst` file is the annotated assembly listing — useful for verifying addresses and instruction encoding. The `.a` file is the linked ELF binary (despite the `.a` extension).

Each project has its own copy (or symlink) of `cms307.ld`. `../include/mc68307.h` is shared across all projects.

## Memory Layout

Defined in `cms307.ld` (each project has a local copy):

| Region | Address    | Size  | Contents                   |
|--------|------------|-------|----------------------------|
| ROM    | 0x000000   | 128kB | `.text` + load image of `.data` |
| RAM    | 0x180000   | 32kB  | `.data` (runtime) + `.bss` |

Stack grows down from `0x188000` (initial SP set in vector table at offset 0).

## Vector Table

The vector table is at the start of ROM (`.org 0`):
- Offset 0x000: initial SP (`0x188000`)
- Offset 0x004: reset vector (`start`)
- Offset 0x130: UART ISR (`.org 304`) — matches `UIVR=0x4C` (0x4C × 4 = 0x130)

## Assembly Dialect

All projects use `m68k-linux-gnu-gcc` as the assembler front-end with these flags:
- `-Wa,-mcpu=68307` — target CPU
- `-Wa,--register-prefix-optional` — allows `d0` instead of `%d0`

The `hello_world` project uses classic Motorola dot-suffix syntax (`move.b`, `bge.s`). All other projects use the suffix-less form (`moveb`, `bge`). Both are valid; do not mix within a file.

Character in `d0` is the convention for `putch` argument (not on stack).

## UART Configuration

All projects configure the MC68307 built-in UART identically:
- **Pins**: PB2 (RXD) and PB3 (TXD) via `PBCNT = 0x000C`
- **Baud**: 115200 (`UBG1=0x00`, `UBG2=0x03`) — 9600 alternative is `UBG2=0x30`
- **Format**: 8N1 (`UMR1=0x13`, `UMR2=0x07`, `UCSR=0xDD`)
- **Clock**: `UACR=0xE0` (Set 2, Timer mode, ÷1)
- **Vector**: `UIVR=0x4C` → ISR at ROM offset 0x130

> **Do not change `UACR=0xE0` or `UBG2=0x03`.** This is the original 1990s configuration, verified working on hardware.
>
> A previous edit "corrected" these to `UACR=0xB0` (`CTMS=011`, Counter mode) / `UBG2=0x04` based on Table 8-11, which marks `011`=Counter as the only "valid" `CTMS` value. **That change broke the UART on real hardware (silent TX) and was reverted.** Why it was wrong:
> - The MC68307 UART is an MC68681 DUART derivative. Baud generation needs the *continuous* clock that **Timer mode** (`CTMS=110`) produces; **Counter mode** (`011`) is a one-shot down-count that never clocks the transmitter, so nothing shifts out. The datasheet's own baud example relies on the timer, contradicting Table 8-11. **Hardware behaviour is the source of truth over a self-contradictory table.**
> - The baud formula (`UBG = clock / (32 × baud)`) is independent of `CTMS`. The original ships `UBG2=0x03`; confirm any baud change on hardware before touching it.

UCR command bytes: `0x20`=reset RX, `0x30`=reset TX, `0x10`=reset MR pointer, `0x01`=enable RX, `0x04`=enable TX, `0x05`=enable both.

### UART Register Bits

| Register | Bit | Meaning               |
|----------|-----|-----------------------|
| USR      | 0   | RxRDY (data available)|
| USR      | 2   | TxRDY (ready to send) |
| UIMR     | 0   | TxRDY interrupt enable|
| UIMR     | 1   | RxRDY interrupt enable|

## Ring Buffer Pattern

TX (and RX in `rxtxtst`) use a 32-byte power-of-2 circular buffer with three control bytes:

```asm
xwp:  .byte 0   // write pointer
xrp:  .byte 0   // read pointer
xcnt: .byte 0   // bytes currently in buffer
xbuf: .fill 32
```

Wrap-around uses bit-AND: `andib #(BUF_SIZE-1), xwp` — only valid when size is a power of 2.

## Interrupt-Driven UART Pattern (`hello_world_irq`, `rxtxtst`)

**ISR** fires on TxRDY (and/or RxRDY in `rxtxtst`). Entry sequence:
1. Check USR bits before saving registers — bail immediately (`rte`) if no pending interrupt
2. Save `d0-d1/a0` and disable `UIMR` during the critical section
3. Handle RX: read `URB` (clears RxRDY), store to ring buffer (drop on overflow)
4. Handle TX: send one byte from ring buffer to `UTB`
5. Restore `UIMR`: always set bit 1 (RxRDY enable); set bit 0 (TxRDY enable) only if TX buffer is non-empty

**`putch`** fast path: if TX buffer is empty AND TxRDY is set, write directly to `UTB`. Otherwise buffer the byte. Always sets `UIMR` to enable the TX interrupt (bit 0), preserving the RX bit (bit 1) in `rxtxtst`.

**`getch`** (`rxtxtst` only): busy-waits on `rxcnt`, then reads one byte from the RX ring buffer.

## Projects Overview

| Project         | Description                                      |
|-----------------|--------------------------------------------------|
| `hello_world`   | Polled TX only; simplest possible UART output    |
| `hello_world_c` | Mixed C + assembly; `hello_world.c` calls `putch` from `uart.S` |
| `hello_world_irq` | Interrupt-driven TX ring buffer                |
| `rxtxtst`       | Interrupt-driven TX + RX ring buffers; echoes received characters |
