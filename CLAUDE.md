# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repo-wide guidance shared by all three sub-projects. Each sub-project has its own `CLAUDE.md` describing that program's architecture; Claude Code loads both this file and the sub-directory file when you work inside a sub-project.

## Project overview

MC68307 bare-metal assembly programs from the 1990s, updated for the GNU m68k cross-compiler toolchain. Three sibling sub-projects, simplest to most involved:

- `hello_world/` — pure assembly, polling UART TX
- `hello_world_irq/` — assembly, interrupt-driven UART TX (ring buffer + ISR)
- `hello_world_c/` — C entry point over assembly startup and UART driver

Shared header `include/mc68307.h` defines all SIM/UART/Timer/M-Bus registers as `MBASE + offset` macros (MBASE = `0x100000`); each sub-project includes it via `-I../include`.

## Build

`cd` into a sub-project first, then:

```sh
make          # builds hello_world.hex (Intel HEX for flashing)
make clean    # removes all build artifacts
```

There are no automated tests — this is bare-metal firmware. "Passing" means it assembles and links cleanly; behaviour is verified on hardware or against the datasheet, so **treat register values as the source of truth and check them against the datasheet before changing them.**

Toolchain (`sudo apt install gcc-m68k-linux-gnu` on Ubuntu):
- `.S` files assemble with `m68k-linux-gnu-gcc -Wa,-mcpu=68307 -Wa,--register-prefix-optional` (the latter allows bare register names like `d0`/`sr` instead of `%d0`).
- `.c` files compile with `-march=68000` (the 68307 has a 68000 core; gcc has no `-march=68307`). Only `hello_world_c` has C sources.
- Link with `m68k-linux-gnu-ld -T cms307.ld -z noexecstack`; convert with `m68k-linux-gnu-objcopy -O ihex`. Keep these flags in sync if you add sources.

Build artifacts (`.o`, `.a`, `.lst`, `.map`, `.hex`) are all gitignored.

## Memory layout (cms307.ld)

All three sub-projects share an identical `cms307.ld`:

| Region | Address  | Size   | Contents                          |
|--------|----------|--------|-----------------------------------|
| ROM    | 0x000000 | 128 KB | `.text`, load address for `.data` |
| RAM    | 0x180000 | 32 KB  | `.data`, `.bss`                   |

The reset vector lives at address 0 (SP) and 4 (PC = `start`). Interrupt-driven programs additionally place their ISR vector with `.org` at the table offset matching their `PIVR`/`UIVR` configuration.

## Datasheet

`MC68307UM.pdf` (the 265-page user manual) is the authority for every register bit. It is large and copyrighted, so it is **not committed** — download it from [NXP](https://www.nxp.com/docs/en/reference-manual/MC68307UM.pdf) into the repo root, where it stays untracked (`*.pdf` is gitignored). Search it with `pdftotext -layout MC68307UM.pdf - | grep ...` (e.g. Table 8-11 "Timer Mode and Source Select Bits" for the UACR `CTMS` field encodings).

## UART configuration note

All three programs set `UACR=0xB0` (baud set 2, counter mode, crystal clock — `CTMS=011`). The original 1990s code used `0xE0` (`CTMS=110`); Table 8-11 ("Timer Mode and Source Select Bits") gives `011` as the only valid `CTMS` encoding and marks all other values invalid, so `0xB0` is the documented value for the intended function. Baud 115200 comes from `UBG2=0x04` at the board's 14.7456 MHz crystal (baud = crystal / (32 × UBG)).
