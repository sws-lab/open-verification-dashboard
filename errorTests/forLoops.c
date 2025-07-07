#include <stdio.h>
#include <stdlib.h>

int main() {
	int *array = malloc(10 * sizeof(int));
	if (array == NULL) {
		return 1;
	}
	array[9] = -1;
	for (int *p = array; *p != -1; p++) {
		*p = 0;
	}
	return 0;
}