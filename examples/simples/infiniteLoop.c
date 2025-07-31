#include <stdio.h>

int main() {
	int y = 50;
	while (y < 100)
		y += (100 - y) / 2;
	
	printf("Final value of y: %d\n", y);
	return 0;
}