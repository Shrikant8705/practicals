import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

# Create dataset
data = {
    "Study_Hours": [1, 2, 2, 3, 3, 4, 4, 5, 5, 6,
                    6, 7, 7, 8, 8, 9, 4, 5, 6, 7],
    "Attendance": [40, 45, 55, 50, 65, 60, 70, 68, 75, 70,
                   80, 75, 85, 82, 90, 88, 55, 60, 65, 72],
    "Assignments": [1, 2, 3, 2, 4, 3, 5, 4, 6, 5,
                    6, 7, 8, 7, 9, 8, 4, 5, 6, 7],
    "Previous_Marks": [30, 35, 45, 42, 50, 48, 58, 55, 60, 57,
                       65, 68, 72, 70, 82, 78, 46, 54, 59, 64],
    "Pass": [0, 0, 0, 0, 1, 0, 1, 1, 1, 0,
             1, 1, 1, 1, 1, 1, 0, 1, 1, 1]
}

df = pd.DataFrame(data)

# Separate input and output
X = df[["Study_Hours", "Attendance",
        "Assignments", "Previous_Marks"]]
y = df["Pass"]

# Split dataset
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Create and train model
model = LogisticRegression()
model.fit(X_train, y_train)

# Predict test results
y_pred = model.predict(X_test)

# Calculate accuracy
print("Accuracy:", accuracy_score(y_test, y_pred))

# Predict for a new student
student = pd.DataFrame(
    [[6, 80, 6, 65]],
    columns=["Study_Hours", "Attendance",
             "Assignments", "Previous_Marks"]
)

prediction = model.predict(student)

if prediction[0] == 1:
    print("Student will Pass")
else:
    print("Student will Fail")

# Display graph
plt.scatter(df["Study_Hours"], df["Pass"])
plt.xlabel("Study Hours")
plt.ylabel("Pass (1) / Fail (0)")
plt.title("Logistic Regression")
plt.show()