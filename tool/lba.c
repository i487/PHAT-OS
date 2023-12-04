#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define PROGRAM_VERSION "1.0.0(GCC debug build)"

typedef struct
{
    uint8_t cyl;
    uint8_t head;
    uint8_t sec;
    uint8_t temp;
} CHS;

CHS g_CHS;

CHS lba_to_chs(uint16_t lba, uint16_t heads, uint16_t secPerTrack)
{
    CHS ret;
    uint8_t temp = lba % (secPerTrack * heads);
    ret.sec = temp % secPerTrack + 1;
    ret.head = temp / secPerTrack;
    ret.cyl = lba / (secPerTrack * heads);
    ret.temp = temp;

}

void usage()
{
    printf("Usage:\n lba [LBA] [HEADS] [SEC PER TRACK]\n");
}

int main(int argc, char *argv[])
{
    printf("LBA to CHS converter by Am286\nVersion: %s\n\n", PROGRAM_VERSION);

    if (argc > 4)
    {
        printf("Too many arguments\n");
        usage();
        return -1;
    }
    if (argc < 4)
    {
        printf("Not enough argunents\n");
        usage();
        return -1;
    }

    g_CHS = lba_to_chs(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));

    printf("%s: %d\n", "Temp", g_CHS.temp);
    printf("%s: %d\n", "Head", g_CHS.head);
    printf("%s: %d\n", "Cylinder", g_CHS.cyl);
    printf("%s: %d\n", "Sector", g_CHS.sec);

    return 0;
}
