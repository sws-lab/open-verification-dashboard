#include <stdio.h>
#include <stdlib.h>

typedef struct Array {
	int *data;
	size_t size;
	size_t capacity;
} Array;

Array createArray(size_t size) {
	Array arr;
	arr.data = malloc(size * sizeof(int));
	arr.size = 0;
	arr.capacity = size;
	return arr;
}

void push(Array *arr, int value) {
	if (arr->size >= arr->capacity) {
		arr->capacity *= 2;
		arr->data = realloc(arr->data, arr->capacity * sizeof(int));
	}
	arr->data[arr->size++] = value;
}

void clear(Array *arr) {
	if (arr->data) {
		free(arr->data);
		arr->data = NULL;
	}
	arr->size = 0;
	arr->capacity = 0;
}

int useAfterFree() {
	Array arr = createArray(10);
	for (int i = 0; i < 20; i++) {
		push(&arr, i);
	}
	printf("Array size: %zu\n", arr.size);
	for (int i = 0; i < arr.capacity; i++) {
		printf("%d ", arr.data[i]);
	}
	printf("\n");
	clear(&arr);
	for (int i = 0; i < 10; i++) {
		printf("%d ", arr.data[i]);
	}
	printf("\n");
	return 0;
}