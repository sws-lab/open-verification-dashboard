#include "binTree.c"
#include "grid.c"
#include "infinite.c"
#include "infiniteLoop.c"
#include "invalidDereference.c"
#include "minimalBug.c"
#include "overflow-anoted.c"
#include "overflow.c"
#include "print.c"
#include "useAfterFree.c"
#include "zeroDiv.c"
#include "zeroDivAfterError.c"
#include "forLoops.c"
#include "string.c"

int main() {
	binTree();
	grid();
	invalidDereference();
	overflow_anoted();
	overflow();
	print();
	useAfterFree();
	zeroDiv();
	zeroDivAfterError();
	forLoop();
	string();
	infinite();
	infiniteLoop();
	minimalBug();
	return 0;
}