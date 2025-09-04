#define MBASE   0x100000     // Module Base Address
#define MBASE   0x100000

// System Integration Module

#define MBAR    0x0000F2     // Module Base Address Register
#define SCR     0x0000F4     // System Control Register

#define PACNT   MBASE+0x011  // Port A Control Register
#define PADDR   MBASE+0x013  // Port A Data Direction Register
#define PADAT   MBASE+0x015  // Port A Data Register
#define PBCNT   MBASE+0x016  // Port B Control Register
#define PBDDR   MBASE+0x018  // Port B Data Direction Register
#define PBDAT   MBASE+0x01A  // Port B Data Register
#define LICR1   MBASE+0x020  // Latched Interrupt Control Register 1
#define LICR2   MBASE+0x022  // Latched Interrupt Control Register 2
#define PICR    MBASE+0x024  // Peripheral Interrupt Control Register
#define PIVR    MBASE+0x027  // Programmable Interrupt Vector Register
#define BR0     MBASE+0x040  // Base Register 0
#define OR0     MBASE+0x042  // Option Register 0
#define BR1     MBASE+0x044  // Base Register 1
#define OR1     MBASE+0x046  // Option Register 1
#define BR2     MBASE+0x048  // Base Register 2
#define OR2     MBASE+0x04A  // Option Register 2
#define BR3     MBASE+0x04C  // Base Register 3
#define OR3     MBASE+0x04E  // Option Register 3

// Serial Module Registers

#define UMR1    MBASE+0x101  // UART Mode Register 1
#define UMR2    MBASE+0x101  // UART Mode Register 2
#define USR     MBASE+0x103  // UART Status Register
#define UCSR    MBASE+0x103  // UART Clock Select Register
#define UCR     MBASE+0x105  // UART Command Register
#define URB     MBASE+0x107  // UART Receiver Buffer
#define UTB     MBASE+0x107  // UART Transmitter Buffer
#define UIPCR   MBASE+0x109  // UART Input Port Change Register
#define UACR    MBASE+0x109  // UART Control Register
#define UISR    MBASE+0x10B  // UART Interrupt Status Register
#define UIMR    MBASE+0x10B  // UART Interrupt Mask Register
#define UBG1    MBASE+0x10D  // UART MSB Baud Rate Prescalar
#define UBG2    MBASE+0x10F  // UART LSB Baud Rate Prescalar
#define UIVR    MBASE+0x119  // UART Interrupt Vector Register
#define UIP     MBASE+0x11B  // UART Input Port Register
#define UOP1    MBASE+0x11D  // UART Output Port Set Command
#define UOP0    MBASE+0x11F  // UART Output Port Reset Command

// Dual Timer Module

#define TMR1    MBASE+0x120  // Timer Mode Register 1
#define TRR1    MBASE+0x122  // Timer Reference Register 1
#define TCR1    MBASE+0x124  // Timer Capture Register 1
#define TCN1    MBASE+0x126  // Timer Counter 1
#define TER1    MBASE+0x129  // Timer Event Register 1
#define WRR     MBASE+0x12A  // Watchdog Reference Register
#define WCR     MBASE+0x12C  // Watchdog Counter Register
#define TMR2    MBASE+0x130  // Timer Mode Register 2
#define TRR2    MBASE+0x132  // Timer Reference Register 2
#define TCR2    MBASE+0x134  // Timer Capture Register 2
#define TCN2    MBASE+0x136  // Timer Counter 2
#define TER2    MBASE+0x139  // Timer Event Register 2

// M-Bus Interface Module

#define MADR    MBASE+0x141  // M-Bus Address Register
#define MFDR    MBASE+0x143  // M-Bus Freq Divider Register
#define MBCR    MBASE+0x145  // M-Bus Control Register
#define MBSR    MBASE+0x147  // M-Bus Status Register
#define MBDR    MBASE+0x149  // M-Bus Data I/O Register
