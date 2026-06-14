# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repo-wide guidance (toolchain, build commands, datasheet workflow, memory layout, UART notes) lives in `../CLAUDE.md` and is loaded automatically alongside this file. This file covers only the `hello_world_c` architecture.

## hello_world_c architecture

Three sources linked into one image, demonstrating C-over-assembly interop: `init307.S` (startup) + `uart.S` (interrupt-driven UART driver) + `hello_world.c` (application). The makefile lists them as `OBJS=init307.o uart.o hello_world.o`.

**Link order matters**: `init307.o` must be first in `.text` because `init307.S` uses `.org 0` to place the reset vectors (SP at 0, PC=`start` at 4) and `.org 304` for the UART ISR vector. Keep it first in `OBJS` so those `.org` offsets land at the ROM base.

- **`init307.S`** — reset vectors, then `start`: masks interrupts (`movew #0x2700,sr`), relocates the SIM (`SCR`, `MBAR=0x0100` → module base `0x100000`), disables the watchdog (`WRR`), programs chip selects `BR0`/`OR0` (ROM @ 0) and `BR1`/`OR1` (RAM @ 0x180000), runs the CMS micro-module RAM-CS-latch clear loop (removable on other boards), calls `uart_init`, sets `PICR=0x7070`/`PIVR=0x40`, drops the interrupt mask to level 7 (`movew #0x2000,sr`), then `bra hello` — a tail branch into the C entry point. SP is set by the reset vector to `0x188000` (top of RAM). There is **no `.data` copy or `.bss` zero loop** at startup: the program has no initialized globals, the only string is a `.text`/rodata literal, and `uart_init` explicitly zeroes the three buffer-state bytes it depends on.
- **`hello_world.c`** — `hello()` is the entry point (branched to from `start`, never returns — it ends in `while(1)`). It calls `puts()`, which is defined here in C and walks the null-terminated string calling the assembly `putch()`. Compiled `-march=68000` (no `-march=68307` exists in gcc); no libc is linked, so this `puts`/`hello` are freestanding, not the C-library symbols.
- **`uart.S`** — the same single-producer/single-consumer 32-byte ring buffer as `hello_world_irq`, but exported for C to drive. `.global putch` / `.global uart_init` / `.global uartisr`. `uart_init` configures port B (`PBCNT`), resets RX/TX, sets `UACR=0xE0` (baud set 2, Timer mode, crystal ÷1, `CTMS=110`), `UBG2=0x03` — the original hardware-verified config; see the UART note in `../CLAUDE.md` for why the `0xB0`/`0x04` "fix" was reverted, 8N1, TX only, interrupts off. `putch` sends directly to `UTB` if the buffer is empty and TXRDY, else enqueues and enables the TX interrupt (`UIMR=1`). `uartisr` (vector at `.org 304`) dequeues one byte and re-arms or disables the TX interrupt.

**C/assembly calling convention**: m68k passes arguments on the stack. In `putch` (`char c`), after `moveml d0/a0,-(sp)` pushes 8 bytes over the 4-byte return address, the char arrives at `sp@(15)` — the low byte of the int-promoted argument (big-endian). If you change the prologue's pushed registers, that offset shifts.
