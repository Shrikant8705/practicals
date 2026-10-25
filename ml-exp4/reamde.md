# Multivariate Linear Regression: House Price Prediction

Predicts house price (in Lakhs) from area, bedrooms, bathrooms, age and distance from the city using scikit-learn's `LinearRegression`.

## Files

| File | Purpose |
|------|---------|
| `exp4.py` | Main script |
| `house_prediction.csv` | Dataset (20 records) |
| `requirements.txt` | Python dependencies |

## Dataset columns

`Area_sqft`, `Bedrooms`, `Bathrooms`, `Age_Years`, `Distance_City_km` (features) and `Price_Lakhs` (target, last column).

## Setup

Run these from inside the `ml-exp4` folder.

**1. Create a virtual environment**

Ubuntu / Linux / macOS:

```
python3 -m venv .venv
```

Windows (Command Prompt or PowerShell):

```
python -m venv .venv
```

On Ubuntu, if this fails with an error about `ensurepip`, install the venv package first: `sudo apt install python3-venv`.

**2. Activate it**

Ubuntu / Linux / macOS:

```
source .venv/bin/activate
```

Windows (Command Prompt):

```
.venv\Scripts\activate
```

Windows (PowerShell):

```
.venv\Scripts\Activate.ps1
```

You should see `(.venv)` at the start of your terminal prompt.

**3. Install the dependencies**

```
pip install -r requirements.txt
```

## Run

Keep `exp4.py` and `house_prediction.csv` in the same folder, make sure the virtual environment is active, then run:

```
python exp4.py
```

To leave the virtual environment when you're done, run `deactivate`.

Close each plot window to move on to the next output.

## Outputs

1. First five records
2. Dataset information and statistical summary
3. Missing-value analysis
4. Correlation matrix
5. Correlation heatmap (`correlation_heatmap.png`)
6. Training and testing record count (16 / 4)
7. Regression intercept
8. Regression coefficients
9. Regression equation
10. Actual vs Predicted price table
11. MAE, MSE, RMSE and R² score
12. Actual vs Predicted graph (`actual_vs_predicted.png`)
13. Residual analysis (`residual_analysis.png`)
14. New house price prediction

Plots are saved as PNG files in the folder you run the script from, even if no plot window opens.

## Troubleshooting

- **File not found:** run the script from the folder that contains the CSV.
- **No plot windows (Ubuntu):** install `python3-tk` or `pip install PyQt6`. The PNG files are saved regardless.
- **Column error:** the script strips spaces and treats the last column as the target, so check the CSV header is on the first line.