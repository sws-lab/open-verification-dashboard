#include <assert.h>
#include <stdlib.h>

char * constDATA = "Hello, World!";

int invalidDereference() {
	constDATA[0] = 'h';
	return 0;
}