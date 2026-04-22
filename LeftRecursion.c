#include <stdio.h> 
#include <string.h> 
int main() 
{ 
    char production[20], alpha[20], beta[20]; 
    char nonTerminal; 
    int i, j = 0, k = 0; 
    printf("Enter production"); 
    scanf("%s", production); 
    nonTerminal = production[0]; 
    if (production[2] == nonTerminal) 
    { 
        printf("\nLeft Recursion Detected!\n"); 
        for (i = 3; production[i] != '|'; i++) 
        alpha[j++] = production[i]; 
        alpha[j] = '\0'; 
        for (i = i + 1; production[i] != '\0'; i++) 
        beta[k++] = production[i]; 
        beta[k] = '\0'; 
        printf("\nAfter Removing Left Recursion:\n"); 
        printf("%c=%s%c'\n", nonTerminal, beta, nonTerminal); 
        printf("%c'=%s%c'|#\n", nonTerminal, alpha, nonTerminal); 
    } 
    else 
    { 
        printf("\nNo Left Recursion Detected.\n"); 
    } 
    return 0; 
}


/*
Enter production (Example: E=E+T|T): E=E+T|T

Left Recursion Detected!

After Removing Left Recursion:
E=TE'
E'=+TE'|#
*/