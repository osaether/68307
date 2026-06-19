/*
 *
 * MC68307 Hello World
 * Copyright (c) Ole Saether 1995
 */
#include "mc68307.h"

        .text
        .org 0
        .long   0x188000
        .long   start           // Reset vector

start:  move.w   #0x2700,SR      // Disable interrupts and stay in SP mode
        move.l   #0x188000,sp    // Set stack pointer to 0x188000 (top of 32kB RAM)
        move.l   #0xff000010,SCR // disable watch dog, 8 bit bus etc.
        move.w   #0x0100,MBAR    // Set register base to 0x100000
        move.w   #0xc001,BR0     // ROM at address 0x000000
        move.w   #0x1fc2,OR0     // 128kB ROM, ignore FC's
        move.w   #0x0301,BR1     // RAM at address 0x180000
        move.w   #0x1fc0,OR1     // 128kB RAM, ignore FC's
        // This loop can be removed if you are not using the CMS micro module:
        move.w   #0xff,d0
rloop:  move.b   0x180000,d1
        dbra    d0,rloop

        bsr     uart_init
hello:
        move.b   #'H',d0
        bsr     putc
        move.b   #'e',d0
        bsr     putc
        move.b   #'l',d0
        bsr     putc
        move.b   #'l',d0
        bsr     putc
        move.b   #'o',d0
        bsr     putc
        move.b   #' ',d0
        bsr     putc
        move.b   #'W',d0
        bsr     putc
        move.b   #'o',d0
        bsr     putc
        move.b   #'r',d0
        bsr     putc
        move.b   #'l',d0
        bsr     putc
        move.b   #'d',d0
        bsr     putc
        move.b   #'!',d0
        bsr     putc
        move.b   #'\r',d0
        bsr     putc
        move.b   #'\n',d0
        bsr     putc

end:    jmp     end

putc:   btst.b   #2,USR
        beq.s    putc
        move.b   d0,UTB
        rts

uart_init:
        move.w   #0x000C,PBCNT           // PB2 and PB3 used for UART
        move.b   #0x20,UCR               // Reset receiver
        move.b   #0x30,UCR               // Reset transmitter
        move.b   #0x4C,UIVR              // UART interrupt vector
        move.b   #0xE0,UACR              // Set 2, Timer mode, divided by 1 (CTMS=110)
        move.b   #0x00,UBG1              // MSB
        move.b   #0x03,UBG2              // 115200 baud
//        move.b  #0x30,UBG2              // 9600 baud
        move.b   #0,UISR                 // 0x10B is UIMR on write: mask all UART interrupts
        move.b   #0x10,UCR               // Reset mode register pointer
        move.b   #0x13,UMR1              // 8N1
        move.b   #0x07,UMR2              // 1 stop bit
        move.b   #0xDD,UCSR              // Clock select
        move.b   #0x04,UCR               // Enable transmitter ONLY
        move.b   #0x00,UIMR              // NO interrupts for now
        rts
