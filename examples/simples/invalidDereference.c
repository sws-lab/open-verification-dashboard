#include <assert.h>
#include <stdlib.h>

char * constDATA = "Hello, World!";

int main() {
	constDATA[0] = 'h';
	return 0;
}