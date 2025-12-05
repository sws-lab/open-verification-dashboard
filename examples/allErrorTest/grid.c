#include <stdio.h>
#include <stdlib.h>

int grid() {
	int **buffer;
	buffer = malloc(5 * sizeof(int *));
	if (buffer == NULL) {
		return 1;
	}
	buffer[0] = malloc(5 * sizeof(int));
	buffer[1] = malloc(5 * sizeof(int)) + 1;
	buffer[2] = malloc(5 * sizeof(int)) + 2;
	buffer[3] = malloc(5 * sizeof(int)) + 3;
	buffer[4] = malloc(5 * sizeof(int)) + 4;

	
	for (int i = 0; i < 5; i++) {
		for (int j = 0; j < 5; j++) {
			int x = i * 5 + j;
			buffer[i][j] = x;
		}
	}
	return 0;
}