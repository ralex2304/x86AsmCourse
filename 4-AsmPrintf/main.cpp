#include <stdio.h>
#include <math.h>

int myprintf(const char* format, ...);

int main() {

    int res = myprintf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127,
                                                                         -1, "love", 3802, 100, 33, 127);

    res += myprintf("%f\n\n", -1.25);

    res += myprintf("%c %f %c %f %d %f %d %f %d %f %d %f %d %f %d %f\n",
                     1, 2.56, 1, 2.56, 1, 2.56, 1, 2.56, 1, 2.56, 1, 2.56, 1, 2.56, 1, 2.56);

    return myprintf("%d\n", res) <= 0;
}
