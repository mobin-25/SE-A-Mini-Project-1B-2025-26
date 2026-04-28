import pandas as pd
import json

try:
    file_path = "SE-DS_(25-26)Gantt Chart-Mini Project 1A.xlsx"
    df = pd.read_excel(file_path, header=None)
    # Just print the first 10 rows and columns
    print(df.iloc[:10, :10].to_string())
except Exception as e:
    print(f"Error: {e}")
