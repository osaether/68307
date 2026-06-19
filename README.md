# Various MC68307 programs I wrote in the 90's

I have provided them here in case they might be useful to someone.

I have used Claude Code and Google Gemini to find bugs and improve the code.

2026: The assembly syntax and makefiles have been updated for the GNU m68k cross compiler.

## Projects Overview

The repository contains four self-contained projects demonstrating different ways to interact with the MC68307:

| Project           | Description                                                                    |
|-------------------|--------------------------------------------------------------------------------|
| `hello_world`     | Pure assembly. Polled UART TX only (no interrupts, no buffer).                 |
| `hello_world_c`   | Mixed C & assembly. C app over an interrupt-driven TX driver.                  |
| `hello_world_irq` | Pure assembly. Interrupt-driven UART TX using a 32-byte circular buffer.       |
| `rxtxtst`         | Pure assembly. Interrupt-driven TX & RX ring buffers; echoes characters.       |

## Building

Each project is located in its own subdirectory. To build a project, navigate to its directory and run `make`:

```bash
cd hello_world
make
```

This will produce several files:
* `<name>.hex`: Intel HEX format binary, ready to be flashed.
* `<name>.lst`: Annotated assembly listing (useful for verifying addresses).
* `<name>.map`: Linker map file.

### Toolchain Prerequisites

On Ubuntu, install the GNU m68k cross-compiler with:
```bash
sudo apt install gcc-m68k-linux-gnu
```

## Hardware Assumptions

All projects configure the built-in UART for **115200 baud** (8N1) on pins PB2 (RXD) and PB3 (TXD).
The memory layout assumes:
* **ROM**: `0x000000` (128kB)
* **RAM**: `0x180000` (32kB) - Stack grows down from `0x188000`

## Reference

[MC68307 User's Manual (PDF)](https://www.nxp.com/docs/en/reference-manual/MC68307UM.pdf) — official NXP document.
