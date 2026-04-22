#include <stdio.h>
#include <string.h>
int main()
{
char production[50], part1[20], part2[20];
char common[20];
char nonTerminal;
int i = 0, j = 0;
printf("Enter production (Example: S=iEtS|iEtSeS): ");
scanf("%s", production);
nonTerminal = production[0];
// Extract first alternative
for(i = 2; production[i] != '|'; i++)
part1[j++] = production[i];
part1[j] = '\0';
j = 0;
i++; // Skip '|'
// Extract second alternative
while(production[i] != '\0')
part2[j++] = production[i++];
part2[j] = '\0';
// Find common prefix
i = 0;
while(part1[i] == part2[i])
{
common[i] = part1[i];
i++;
}
common[i] = '\0';
if(strlen(common) == 0)
{
printf("\nNo Left Factoring Needed.\n");
}
else
{
printf("\nLeft Factoring Possible!\n");
printf("\nAfter Left Factoring:\n");
printf("%c=%s%c'\n", nonTerminal, common, nonTerminal);
printf("%c'=%s|%s\n", nonTerminal, part1 + strlen(common), part2 +strlen(common));
}
return 0;
}
