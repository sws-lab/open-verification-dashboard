#include <limits.h>

int minimalBug() {
    int *a;
    return (*a) || (*a);
}