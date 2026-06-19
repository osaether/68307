/*
 *
 * MC68307 UART TX handler
 * (C) Ole Saether 1995
 */
#include "mc68307.h"

#define TX_BUF_SIZE 32

        .bss
txwp:   .byte   0                       // Write pointer (0-TX_BUF_SIZE-1)
txrp:   .byte   0                       // Read pointer (0-TX_BUF_SIZE-1)  
txcnt:  .byte   0                       // Number of chars in buffer            
txbuf:  .fill   TX_BUF_SIZE             // TX_BUF_SIZE character circular buffer

        .text
        .global putch
putch:  movem.l d0/a0,-(sp)
        cmp.b    #TX_BUF_SIZE,txcnt
        bge     3f                      // Buffer full */
        tst.b    txcnt
        bne     1f
        btst    #2,USR                  // Check TXRDY bit
        beq     1f                      // Write to buffer if not ready
        move.b   sp@(15),UTB             // Send first character
        bra     3f                      // Direct send: leave TxRDY interrupt disabled
1:      lea     txbuf,a0                // Buffer base address
        moveq  #0,d0
        move.b   txwp,d0                 // Get write pointer
        move.b   sp@(15),(a0,d0)         // Store character
        addq.b   #1,txwp
        andi.b   #(TX_BUF_SIZE-1),txwp
        addq.b   #1,txcnt
2:      move.b   #1,UIMR                 // Enable TX interrupt for remaining chars
3:      movem.l (sp)+,d0/a0
        rts

        .global uart_init
uart_init:
        clr.b    txwp
        clr.b    txrp
        clr.b    txcnt
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

.align 4
        .global uartisr
uartisr:
        btst    #2,USR                  // Is it a TX interrupt?
        beq     2f

        move.b   #0,UIMR
        movem.l  d0-d1/a0,-(sp)          // Save registers */
        tst.b    txcnt
        beq     1f                      // No data in buffer */
        lea     txbuf,a0                // Buffer base address */
        moveq  #0,d1                   // Clear all 32 bits of d1 */
        move.b   txrp,d1                 // Load read pointer */
        move.b   (a0,d1),d0
        move.b   d0,UTB                  // Send the actual character */       
        addq.b   #1,txrp
        andi.b   #(TX_BUF_SIZE-1),txrp
        subq.b   #1,txcnt
        tst.b    txcnt
        beq     1f
        move.b   #1,UIMR                 // Enable TX interrupt for remaining chars */
1:      movem.l  (sp)+,d0-d1/a0          // Restore registers */
2:      rte
