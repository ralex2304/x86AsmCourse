
int myprintf(const char* format, ...);

int main() {

    int res = myprintf("%b\n", 0xa0);

    return myprintf("%d\n", res) <= 0;
}
