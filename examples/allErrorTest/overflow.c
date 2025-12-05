#include <stdio.h>
#include <stdlib.h>

int overflow() {
	int test[50];
	for (int i = 0; i < sizeof(test) / sizeof(int); i++) {
		test[i] = i;
	}
	return 0;
}