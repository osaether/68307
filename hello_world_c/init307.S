/*
 * MC68307 init routines
 * Copyright (c) Ole Saether 1995
 */
#include "mc68307.h"

        .text
        .org 0
        .long   0x188000        // Stack pointer
        .long   start           // Reset vector

        .org    304
        .long   uartisr

start:  movew   #0x2700,sr              // Disable interrupts
        movel   #0xff000010,SCR
        movew   #0x0100,MBAR

        movew   #0,WRR                  // Disable watch dog
        movew   #0xc001,BR0             // ROM at address 0x000000
        movew   #0x1fc2,OR0             // 128kB ROM, ignore FC's
        movew   #0x0301,BR1             // RAM at address 0x180000
        movew   #0x1fc0,OR1             // 128kB RAM, ignore FC's
        // This loop can be removed if you are not using the CMS micro module:
        movew   #0xff,d0                // Clear the RAM CS latch
rloop:  moveb   0x180000,d1             
        dbra    d0,rloop

        bsr     uart_init
        movew  #0x7070,PICR            // Set interrupt priority
        moveb  #0x40,PIVR              // Interrupt base vector
        movew  #0x2000,sr              // Enable level 7 interrupts
        bra    hello
