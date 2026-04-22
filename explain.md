# Left Factoring in C

## 📌 Overview

This program performs **Left Factoring** on a grammar production with two alternatives.

Left factoring helps remove common prefixes to make grammars suitable for predictive parsing.

---

## 🧾 Example Input

```
S=iEtS|iEtSeS
```

## ✅ Example Output

```
After Left Factoring:
S=iEtS'
S'=S|eS
```

---

## 💻 Code with Explanation

```c
#include <stdio.h>
#include <string.h>

int main() {
    char p[50], a[20], b[20], c[20];
    int i = 2, j = 0;

    printf("Enter production: ");
    scanf("%s", p);

    while (p[i] != '|') a[j++] = p[i++];
    a[j] = '\0'; i++; j = 0;

    while (p[i]) b[j++] = p[i++];
    b[j] = '\0';

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
```

---

## 🔍 Line-by-Line Explanation

### Header Files

* `#include <stdio.h>`
  → Used for input/output functions like `printf` and `scanf`.

* `#include <string.h>`
  → Used for string functions like `strlen()`.

---

### Main Function

* `int main()`
  → Entry point of the program.

---

### Variable Declaration

* `char p[50]` → stores full production (e.g., `S=iEtS|iEtSeS`)

* `char a[20]` → first alternative

* `char b[20]` → second alternative

* `char c[20]` → common prefix

* `int i = 2` → starts from index 2 to skip `S=`

* `int j = 0` → index for storing characters

---

### Input

* `printf("Enter production: ");`
  → asks user for input

* `scanf("%s", p);`
  → reads production string

---

### Extract First Alternative

* `while (p[i] != '|') a[j++] = p[i++];`
  → copies characters into `a` until `|` is found

* `a[j] = '\0';`
  → marks end of string

* `i++;`
  → skips the `|` symbol

* `j = 0;`
  → reset index for next string

---

### Extract Second Alternative

* `while (p[i]) b[j++] = p[i++];`
  → copies remaining string into `b`

* `b[j] = '\0';`
  → null terminates string

---

### Find Common Prefix

* `i = 0;`
  → reset index

* `while (a[i] == b[i]) c[i] = a[i], i++;`
  → compares both strings character by character
  → stores matching characters in `c`

* `c[i] = '\0';`
  → end of prefix string

---

### Check If Factoring Needed

* `if (!strlen(c))`
  → if prefix is empty, no factoring needed

* `printf("No Left Factoring Needed\n");`
  → prints message

---

### Apply Left Factoring

* `printf("After Left Factoring:\n");`
  → heading

* `printf("%c=%s%c'\n", p[0], c, p[0]);`
  → prints new production
  → example: `S=iEtS'`

* `printf("%c'=%s|%s\n", p[0], a+i, b+i);`
  → prints remaining parts after removing prefix
  → example: `S'=S|eS`

---

### End of Program

* `return 0;`
  → program ends successfully

---

## ⚠️ Limitations

* Works only for **two alternatives**
* Input must follow format: `A=xxx|yyy`
* Does not handle multiple `|`

---

## 🚀 Compilation & Run

```bash
gcc left_factoring.c -o leftf
./leftf
```

---

## 📚 Concepts Used

* Strings in C
* Arrays
* Prefix matching
* Compiler Design (Left Factoring)

---

## ✨ Tip for Exams

Mention this limitation if asked:

> "This implementation supports two productions but can be extended for multiple alternatives using tokenization."

---

## 👨‍💻 Author

Shrikant
