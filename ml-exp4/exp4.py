import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# ------------------------------------------------------------
# Load dataset (robust: handles BOM, stray spaces, odd delimiters)
# ------------------------------------------------------------
#right click on the house_prediction.csv and then paste the path in read_csv() function
df = pd.read_csv("/home/shrikant/practicals/ml-exp4/house_prediciton.csv", encoding="utf-8-sig",
                 sep=None, engine="python")
df.columns = df.columns.str.strip()
df = df.dropna(how="all").dropna(axis=1, how="all")

print("Columns found:", df.columns.tolist())
if df.shape[1] < 2:
    raise SystemExit("CSV was read as a single column. Check that the file "
                     "is comma-separated and has the header on the first line.")

# Target = last column (Price_Lakhs), features = all other columns
target_col = df.columns[-1]

# 1. First five records
print("\n" + "=" * 60)
print("1. FIRST FIVE RECORDS")
print("=" * 60)
print(df.head())

# 2. Dataset information and statistical summary
print("\n" + "=" * 60)
print("2. DATASET INFORMATION & STATISTICAL SUMMARY")
print("=" * 60)
df.info()
print("\nShape:", df.shape)
print("\nStatistical Summary:")
print(df.describe())

# 3. Missing-value analysis
print("\n" + "=" * 60)
print("3. MISSING VALUE ANALYSIS")
print("=" * 60)
print(df.isnull().sum())
print("\nTotal missing values:", df.isnull().sum().sum())

# 4. Correlation matrix
print("\n" + "=" * 60)
print("4. CORRELATION MATRIX")
print("=" * 60)
corr = df.corr()
print(corr.round(3))

# 5. Correlation heatmap
plt.figure(figsize=(8, 6))
sns.heatmap(corr, annot=True, cmap="coolwarm", fmt=".2f", linewidths=0.5)
plt.title("Correlation Heatmap")
plt.tight_layout()
plt.savefig("correlation_heatmap.png", dpi=150)
plt.show()

# ------------------------------------------------------------
# Features / Target and train-test split
# ------------------------------------------------------------
X = df.drop(columns=[target_col])
y = df[target_col]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# 6. Training and testing record count
print("\n" + "=" * 60)
print("6. TRAINING AND TESTING RECORD COUNT")
print("=" * 60)
print("Total records    :", len(df))
print("Training records :", len(X_train))
print("Testing records  :", len(X_test))

# ------------------------------------------------------------
# Train model
# ------------------------------------------------------------
model = LinearRegression()
model.fit(X_train, y_train)

# 7. Intercept
print("\n" + "=" * 60)
print("7. REGRESSION INTERCEPT")
print("=" * 60)
print("Intercept:", round(model.intercept_, 4))

# 8. Coefficients
print("\n" + "=" * 60)
print("8. REGRESSION COEFFICIENTS")
print("=" * 60)
coef_df = pd.DataFrame({"Feature": X.columns, "Coefficient": model.coef_})
print(coef_df.to_string(index=False))

# 9. Regression equation
print("\n" + "=" * 60)
print("9. REGRESSION EQUATION")
print("=" * 60)
equation = f"{target_col} = {model.intercept_:.4f}"
for feature, coef in zip(X.columns, model.coef_):
    sign = "+" if coef >= 0 else "-"
    equation += f" {sign} ({abs(coef):.4f} * {feature})"
print(equation)

# ------------------------------------------------------------
# Predictions
# ------------------------------------------------------------
y_pred = model.predict(X_test)

# 10. Actual vs Predicted table
print("\n" + "=" * 60)
print("10. ACTUAL vs PREDICTED PRICE")
print("=" * 60)
comparison = pd.DataFrame({
    "Actual": y_test.values,
    "Predicted": y_pred.round(2),
    "Difference": (y_test.values - y_pred).round(2)
})
print(comparison)

# 11. Evaluation metrics
mae = mean_absolute_error(y_test, y_pred)
mse = mean_squared_error(y_test, y_pred)
rmse = np.sqrt(mse)
r2 = r2_score(y_test, y_pred)

print("\n" + "=" * 60)
print("11. MODEL EVALUATION METRICS")
print("=" * 60)
print(f"MAE  (Mean Absolute Error)     : {mae:.4f}")
print(f"MSE  (Mean Squared Error)      : {mse:.4f}")
print(f"RMSE (Root Mean Squared Error) : {rmse:.4f}")
print(f"R2 Score                       : {r2:.4f}")

# 12. Actual vs Predicted graph
plt.figure(figsize=(7, 5))
plt.scatter(y_test, y_pred, color="blue", edgecolor="k", label="Predictions")
plt.plot([y.min(), y.max()], [y.min(), y.max()], "r--", label="Perfect Fit")
plt.xlabel("Actual Price (Lakhs)")
plt.ylabel("Predicted Price (Lakhs)")
plt.title("Actual vs Predicted House Price")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("actual_vs_predicted.png", dpi=150)
plt.show()

# 13. Residual analysis
residuals = y_test.values - y_pred

print("\n" + "=" * 60)
print("13. RESIDUAL ANALYSIS")
print("=" * 60)
print("Residuals:", residuals.round(3))
print("Mean of residuals :", round(residuals.mean(), 4))
print("Std of residuals  :", round(residuals.std(), 4))

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

axes[0].scatter(y_pred, residuals, color="green", edgecolor="k")
axes[0].axhline(0, color="red", linestyle="--")
axes[0].set_xlabel("Predicted Price")
axes[0].set_ylabel("Residuals")
axes[0].set_title("Residual Plot")
axes[0].grid(True)

sns.histplot(residuals, kde=True, ax=axes[1], color="purple")
axes[1].set_xlabel("Residual")
axes[1].set_title("Residual Distribution")

plt.tight_layout()
plt.savefig("residual_analysis.png", dpi=150)
plt.show()

# 14. New house price prediction
print("\n" + "=" * 60)
print("14. NEW HOUSE PRICE PREDICTION")
print("=" * 60)
new_house = pd.DataFrame([[1750, 3, 2, 5, 4]], columns=X.columns)
predicted_price = model.predict(new_house)
print("New House Details:")
print(new_house.to_string(index=False))
print(f"\nPredicted Price: {predicted_price[0]:.2f} Lakhs")