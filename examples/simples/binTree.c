#include <stdlib.h>
#include <stdio.h>

typedef struct Node {
    int data;
    struct Node *left;
    struct Node *right;
} Node;

Node* createNode(int data) {
    Node *newNode = (Node *)malloc(sizeof(Node));
    if (newNode == NULL) {
        exit(EXIT_FAILURE);
    }
    newNode->data = data;
    newNode->left = NULL;
    newNode->right = NULL;
    return newNode;
}

Node *tree(int data, Node *left, Node *right) {
    Node *newNode = createNode(data);
    newNode->left = left;
    newNode->right = right;
    return newNode;
}

int dfs(const Node *node, int value) {
    if (node == NULL) {
        return 0;
    }
    if (node->data == value) {
        return 1;
    }
    return dfs(node->left, value) || dfs(node->right, value);
}

int main() {
    Node *root = tree(1, 
        tree(2, createNode(4), (Node*)124578), 
        tree(3, createNode(6), createNode(5))); // voluntary invalid pointer
    
    int valueToFind = 5;
    if (dfs(root, valueToFind)) {
        printf("Value %d found in the tree.\n", valueToFind);
    } else {
        printf("Value %d not found in the tree.\n", valueToFind);
    }

    return 0;
}