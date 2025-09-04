/*
 *
 * MC68307 Hello World
 * Copyright (c) Ole Saether 1995
 */
#include "mc68307.h"

        .text
        .org 0
        .long   0x181000
        .long   start           // Reset vector

start:  movew   #0x2700,SR      // Disable interrupts and stay in SP mode
        movel   #0x181000,sp    // Set stack pointer to 0x181000
        movel   #0xff000010,SCR // disable watch dog, 8 bit bus etc.
        movew   #0x0100,MBAR    // Set register base to 0x100000
        movew   #0xc001,BR0     // ROM at address 0x000000
        movew   #0x1fc2,OR0     // 128kB ROM, ignore FC's
        movew   #0x0301,BR1     // RAM at address 0x180000
        movew   #0x1fc0,OR1     // 128kB RAM, ignore FC's
        // This loop can be removed if you are not using the CMS micro module:
        movew   #0xff,d0
rloop:  moveb   0x180000,d1
        dbra    d0,rloop

        bsr     uart_init
hello:
        moveb   #'H',d0
        bsr     putc
        moveb   #'e',d0
        bsr     putc
        moveb   #'l',d0
        bsr     putc
        moveb   #'l',d0
        bsr     putc
        moveb   #'o',d0
        bsr     putc
        moveb   #' ',d0
        bsr     putc
        moveb   #'W',d0
        bsr     putc
        moveb   #'o',d0
        bsr     putc
        moveb   #'r',d0
        bsr     putc
        moveb   #'l',d0
        bsr     putc
        moveb   #'d',d0
        bsr     putc
        moveb   #'!',d0
        bsr     putc
        moveb   #'\r',d0
        bsr     putc
        moveb   #'\n',d0
        bsr     putc

end:    jmp     end

putc:   btstb   #2,USR
        beqs    putc
        moveb   d0,UTB
        rts

uart_init:
        move.w  #0x000C,PBCNT           // PB2 and PB3 used for UART
        move.b  #0x20,UCR               // Reset receiver
        move.b  #0x30,UCR               // Reset transmitter
        move.b  #0x4C,UIVR              // UART interrupt vector
        move.b  #0xE0,UACR              // Set 2, Timer mode, divided by 1
        move.b  #0x00,UBG1              // MSB
        move.b  #0x03,UBG2              // 115200 baud
//        move.b  #0x30,UBG2              // 9600 baud
        move.b  #0,UISR                 // Clear interrupt status register
        move.b  #0x10,UCR               // Reset mode register pointer
        move.b  #0x13,UMR1              // 8N1
        move.b  #0x07,UMR2              // 1 stop bit
        move.b  #0xDD,UCSR              // Clock select
        move.b  #0x04,UCR               // Enable transmitter ONLY
        move.b  #0x00,UIMR              // NO interrupts for now
        rts
