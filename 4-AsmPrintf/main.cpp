
int myprintf(const char* format, ...);

int main() {

    int res = myprintf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127,
                                                                         -1, "love", 3802, 100, 33, 127);

    return myprintf("%d\n", res) <= 0;
}
