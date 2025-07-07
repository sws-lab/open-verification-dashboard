#include <stdio.h>
#include <string.h>

int main() {
	char *s1 = "hello ";
	char *s2 = malloc(2);
	if (s2 == NULL) {
		return 1;
	}
	strcpy(s2, s1);
	return 0;
}