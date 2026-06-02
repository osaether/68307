# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repo-wide guidance (toolchain, build commands, datasheet workflow, memory layout, UART notes) lives in `../CLAUDE.md` and is loaded automatically alongside this file. This file covers only the `hello_world_irq` architecture.

## hello_world_irq architecture

Single-file (`hello_world.S`) interrupt-driven UART TX using a 32-byte circular buffer:

- **BSS**: `txwp` / `txrp` / `txcnt` (buffer state) + `txbuf[32]`, all reserved with `.skip` (`.bss` is NOBITS, so data initializers there are silently dropped — `start` zeroes them at runtime)
- **`start`**: relocates the SIM (`SCR`, `MBAR=0x0100` → module base `0x100000`), disables the watchdog (`WRR`), programs chip selects `BR0`/`OR0` (ROM @ 0) and `BR1`/`OR1` (RAM @ 0x180000), runs the CMS micro-module RAM-CS-latch clear loop (removable on other boards), calls `uart_init`, zeroes the buffer state, sets `PICR`/`PIVR`, drops the interrupt mask to level 7 (`movew #0x2000,sr`), then calls `puts(message)` and loops forever
- **`uart_init`**: configures port B pins (`PBCNT`), resets RX/TX, sets `UACR=0xB0` (baud set 2, counter mode, `CTMS=011` — the old `0xE0` was the invalid `110` encoding, see Table 8-11), baud rate 115200 (`UBG2=0x03`), 8N1, enables TX only — interrupts off initially
- **`putch`**: if buffer empty and TXRDY, sends directly to UTB; otherwise enqueues to circular buffer and enables TX interrupt (`UIMR=1`)
- **`uartisr`** (vector at `.org 304`): checks TXRDY bit in USR, dequeues one byte to UTB, re-arms or disables the TX interrupt depending on whether the buffer still has data
- **`puts`**: iterates over a null-terminated string calling `putch`

The interrupt priority is configured via `PICR=0x7070` (UART IPL 7) and the UART interrupt vector register `UIVR=0x4C` (→ vector 76 → table offset 304). The ring buffer is a single-producer/single-consumer queue; on the 68000 the single-instruction counter updates make it interrupt-safe without locking.
