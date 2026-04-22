#include <stdio.h>
#include <string.h>

int main() {
    char p[50], a[20], b[20], c[20];
    int i = 2, j = 0;

    printf("Enter production: ");
    scanf("%s", p);

    // split into two parts
    while (p[i] != '|') a[j++] = p[i++];
    a[j] = '\0'; i++; j = 0;
    while (p[i]) b[j++] = p[i++];
    b[j] = '\0';

    // find common prefix
    i = 0;
    while (a[i] == b[i]) c[i] = a[i], i++;
    c[i] = '\0';

    if (!strlen(c))
        printf("No Left Factoring Needed\n");
    else {
        printf("After Left Factoring:\n");
        printf("%c=%s%c'\n", p[0], c, p[0]);
        printf("%c'=%s|%s\n", p[0], a+i, b+i);
    }
    return 0;
}
