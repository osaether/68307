# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repo-wide guidance (toolchain, build commands, datasheet workflow, memory layout, UART notes) lives in `../CLAUDE.md` and is loaded automatically alongside this file. This file covers only the `rxtxtst` architecture.

## rxtxtst architecture

Single-file (`rxtxtst.S`) interrupt-driven UART with **two** 32-byte circular buffers — one for TX, one for RX. Prints a banner on startup, then echoes every received character. This is the `hello_world_irq` design extended with a receive path.

- **BSS**: `txwp` / `txrp` / `txcnt` + `txbuf[32]` and `rxwp` / `rxrp` / `rxcnt` + `rxbuf[32]`, all reserved with `.fill`/`.byte` in `.bss`; `start` zeroes the six control bytes at runtime
- **`start`**: relocates the SIM (`SCR`, `MBAR=0x0100` → module base `0x100000`), disables the watchdog (`WRR`), programs chip selects `BR0`/`OR0` (ROM @ 0) and `BR1`/`OR1` (RAM @ 0x180000), runs the CMS micro-module RAM-CS-latch clear loop, calls `uart_init`, zeroes the TX/RX buffer state, sets `PICR=0x0040` (UART IPL 4) / `PIVR=0x40`, drops the interrupt mask (`movew #0x2000,sr`), prints `message` via `puts`, then enters `main_loop`
- **`main_loop`**: `getch` → `putch` forever — blocking read of one RX byte, echoed straight back to TX
- **`uart_init`**: configures port B pins (`PBCNT`), resets RX/TX, sets `UIVR=0x4C`, `UACR=0xE0` (baud set 2, Timer mode, crystal ÷1, `CTMS=110`) and `UBG2=0x03` — the original hardware-verified config; see the UART note in `../CLAUDE.md` for why the `0xB0`/`0x04` "fix" was reverted. 8N1, enables **both** TX and RX (`UCR=0x05`), and sets `UIMR=0x02` to arm the RxRDY interrupt (TxRDY bit added later by `putch`)
- **`uartisr`** (vector at `.org 304`): handles RxRDY and TxRDY in one handler. Checks `USR` bits 0/2 before saving registers; exits via bare `rte` if neither is set. Disables `UIMR` for the critical section, then: RX side reads `URB` (clears RxRDY) and enqueues to `rxbuf` (dropping on overflow); TX side dequeues one byte from `txbuf` to `UTB`. On exit it rebuilds `UIMR`: bit 1 (RxRDY) always set, bit 0 (TxRDY) only when `txcnt != 0`
- **`getch`**: blocking — busy-waits on `rxcnt`, then dequeues one byte from `rxbuf` into `d0`
- **`putch`**: if TX buffer empty and TXRDY set, writes directly to `UTB`; otherwise enqueues to `txbuf` (busy-waits if full). Always sets `UIMR=0x03` to keep both RxRDY and TxRDY interrupts enabled
- **`puts`**: iterates a null-terminated string calling `putch`

The two ring buffers are independent single-producer/single-consumer queues; on the 68000 the single-instruction counter updates keep them interrupt-safe without locking. Wrap-around uses `andib #(BUF_SIZE-1), ...`, valid only because the buffers are a power-of-2 size.

Note `rxtxtst` runs the UART at IPL 4 (`PICR=0x0040`), unlike `hello_world_irq`'s IPL 7.
