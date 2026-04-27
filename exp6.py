#Progam for first order logic

class Student:
    def __init__(self, name):
        self.name = name
        self.courses = []

    def __repr__(self):
        return f"Student({self.name})"


class Course:
    def __init__(self, name):
        self.name = name
        self.students = []

    def __repr__(self):
        return f"Course({self.name})"


def enroll_student(student, course):
    if student not in course.students:
        course.students.append(student)
    if course not in student.courses:
        student.courses.append(course)


def is_enrolled(student, course):
    return student in course.students


def list_enrolled_students(course):
    return course.students


def list_student_courses(student):
    return student.courses


# Example Usage

# Create some students and courses
alice = Student("Alice")
bob = Student("Bob")
math101 = Course("Math101")
cs101 = Course("CS101")

# Enroll students in courses
enroll_student(alice, math101)
enroll_student(bob, cs101)
enroll_student(alice, cs101)

# Check if a student is enrolled in a course
print(f"Is Alice enrolled in Math101? {is_enrolled(alice, math101)}")
print(f"Is Bob enrolled in Math101? {is_enrolled(bob, math101)}")

# List all students enrolled in a course
print(f"Students enrolled in CS101: {list_enrolled_students(cs101)}")

# List all courses a student is enrolled in
print(f"Courses Alice is enrolled in: {list_student_courses(alice)}")
