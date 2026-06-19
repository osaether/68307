# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repo-wide guidance (toolchain, build commands, datasheet workflow, memory layout, UART notes) lives in `../CLAUDE.md` and is loaded automatically alongside this file. This file covers only the `hello_world` architecture.

## hello_world architecture

The simplest of the four programs and the common ancestor of the others: single-file (`hello_world.S`), pure assembly, **polling** UART TX with no interrupts, no ring buffer, and no `.bss`.

- **Reset vectors** (`.org 0`): SP = `0x188000` (top of 32 KB RAM), PC = `start` — the same stack top as the interrupt-driven and C versions.
- **`start`**: masks interrupts (`movew #0x2700,SR`), sets SP, relocates the SIM (`SCR`, `MBAR=0x0100` → module base `0x100000`), programs chip selects `BR0`/`OR0` (ROM @ 0) and `BR1`/`OR1` (RAM @ 0x180000), runs the CMS micro-module RAM-CS-latch clear loop (removable on other boards), calls `uart_init`, then falls through to `hello`. Note it never sets `PICR`/`PIVR` or lowers the interrupt mask — interrupts stay off for the program's life.
- **`hello`**: emits `"Hello World!\r\n"` one character at a time via `bsr putc` (the string is unrolled inline, not a loop over a literal), then spins forever in `end: jmp end`.
- **`putc`**: busy-waits on the TXRDY bit (`btstb #2,USR` / `beqs`), then writes the byte in `d0` to `UTB`. Purely synchronous — the CPU blocks until the transmitter is ready. This is the whole reason the program needs no buffer or ISR; contrast with the `putch`/`uartisr` ring buffer in `hello_world_irq` and `hello_world_c`.
- **`uart_init`**: identical UART setup to the others — port B pins (`PBCNT`), RX/TX reset, `UACR=0xE0` (Timer mode, `CTMS=110`), `UBG2=0x03`, 8N1, TX only, all interrupts left masked. See the UART note in `../CLAUDE.md` for why the `0xB0`/`0x04` "fix" was reverted.
