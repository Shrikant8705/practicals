# Python Program for First-Order Logic 

This project implements a simple student-course enrollment system inspired by **First-Order Logic (FOL)** concepts.

Instead of just treating this as basic object-oriented code, it models relationships and predicates between entities like *students* and *courses*.

---

## 📌 Conceptual Overview

In **First-Order Logic**, we represent knowledge using:

* **Objects (constants)** → e.g., `Alice`, `Bob`, `Math101`
* **Predicates** → relationships between objects
* **Facts** → true statements about the world

This code mirrors that structure using Python classes and functions.

---

## 🧠 Logical Mapping

| FOL Concept | Code Representation                     |
| ----------- | --------------------------------------- |
| Constant    | `Student("Alice")`, `Course("Math101")` |
| Predicate   | `Enrolled(student, course)`             |
| Fact        | `enroll_student(alice, math101)`        |
| Query       | `is_enrolled(student, course)`          |

---

## 🧱 Entities

### `Student`

Represents a logical object (constant).

* `name`: Identifier of the student
* `courses`: Courses the student is enrolled in

---

### `Course`

Represents another logical object.

* `name`: Identifier of the course
* `students`: Students enrolled in the course

---

## ⚙️ Predicates (Functions)

### `enroll_student(student, course)`

Represents the predicate:

```
Enrolled(student, course)
```

Adds a **fact** to the system stating that a student is enrolled in a course.

---

### `is_enrolled(student, course)`

Represents a **query**:

```
Enrolled(student, course)?
```

Returns:

* `True` if the fact exists
* `False` otherwise

---

### `list_enrolled_students(course)`

Represents:

```
{ s | Enrolled(s, course) }
```

Returns all students satisfying the predicate.

---

### `list_student_courses(student)`

Represents:

```
{ c | Enrolled(student, c) }
```

Returns all courses satisfying the predicate.

---

## 🚀 Example Usage

```python id="fol123"
alice = Student("Alice")
bob = Student("Bob")

math101 = Course("Math101")
cs101 = Course("CS101")

# Facts
enroll_student(alice, math101)
enroll_student(bob, cs101)
enroll_student(alice, cs101)

# Queries
print(is_enrolled(alice, math101))  # True
print(is_enrolled(bob, math101))    # False

print(list_enrolled_students(cs101))
print(list_student_courses(alice))
```

---

## 🧠 Key Idea

The system behaves like a **mini knowledge base**:

* `enroll_student` → adds facts
* `is_enrolled` → queries facts
* Lists → return all objects satisfying a predicate

---

## ⚠️ Limitations

* No formal inference engine (no rule-based reasoning)
* No quantifiers like ∀ (for all) or ∃ (exists)
* No persistence or database
* Works only with explicit facts (no derived knowledge)

---

## 💡 Possible Extensions

* Add logical rules (e.g., prerequisites)
* Implement inference (forward/backward chaining)
* Introduce quantifiers and constraints
* Convert into a Prolog-style system
* Store facts in a database or logic engine

---

## 📜 License

Free to use for educational purposes.

