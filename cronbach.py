import pandas as pd
import numpy as np

def cronbach_alpha(df):
    # Number of items
    N = df.shape[1]
    
    # Variance for each item
    item_variances = df.var(axis=0, ddof=1)
    
    # Total scores
    total_scores = df.sum(axis=1)
    
    # Variance of total scores
    var_total = total_scores.var(ddof=1)
    
    # Cronbach's Alpha
    alpha = (N / (N - 1)) * (1 - item_variances.sum() / var_total)
    
    return alpha

# Example usage
data = {
    'Item1': [4, 3, 5, 2],
    'Item2': [3, 4, 2, 5],
    'Item3': [5, 4, 3, 4]
}

df = pd.DataFrame(data)
alpha = cronbach_alpha(df)
print(f"Cronbach's Alpha: {alpha:.3f}")
