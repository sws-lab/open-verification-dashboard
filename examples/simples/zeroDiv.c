#include <stdio.h>
#include <stdlib.h>

int main() {
	int *buff = malloc(sizeof(int) * 10);
	int result = 100;
	for (int i = 0; i < 10; i++) {
		result -= buff[i];
	}
	return 1/result;
}