#include <stdlib.h>
int x,y;

int zeroDivAfterError() {
	int *p = NULL;
	x = *p;
	y = x / 0;
	return 0;
}