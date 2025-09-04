void putch(char c);

int puts (const char *s)
{
    while (*s)
        putch(*s++);
    return 0;
}

void hello(void)
{
    const char *s = "Hello World!\r\n";
    puts(s);
    while(1)
    {
    }
}
