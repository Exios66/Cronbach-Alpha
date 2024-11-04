import pandas as pd
import numpy as np
import logging
from typing import Dict, Union

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def validate_data(df: pd.DataFrame) -> None:
    """Validate input data meets requirements for Cronbach's alpha calculation."""
    if not isinstance(df, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame")
    
    if df.shape[0] < 2:
        raise ValueError("Data must have at least 2 rows (participants)")
        
    if df.shape[1] < 2:
        raise ValueError("Data must have at least 2 columns (items)")
        
    if df.isna().any().any():
        logging.warning("Data contains missing values which may affect results")
        
    if not np.issubdtype(df.dtypes.iloc[0], np.number):
        raise TypeError("All columns must contain numeric data")

def cronbach_alpha(df: pd.DataFrame) -> Dict[str, Union[float, pd.Series]]:
    """
    Calculate Cronbach's alpha and related statistics.
    
    Args:
        df: pandas DataFrame with items as columns and participants as rows
        
    Returns:
        Dictionary containing:
        - alpha: Cronbach's alpha coefficient
        - item_total_correlations: Correlation of each item with total score
        - alpha_if_deleted: Alpha coefficient if each item is deleted
    """
    try:
        validate_data(df)
        logging.info("Data validation passed. Processing analysis...")
        
        # Number of items
        N = df.shape[1]
        
        # Variance for each item
        item_variances = df.var(axis=0, ddof=1)
        
        # Total scores
        total_scores = df.sum(axis=1)
        
        # Variance of total scores
        var_total = total_scores.var(ddof=1)
        
        # Calculate alpha
        alpha = (N / (N - 1)) * (1 - item_variances.sum() / var_total)
        
        # Calculate item-total correlations
        item_total_correlations = pd.Series(
            {col: df[col].corr(total_scores - df[col]) for col in df.columns},
            name="Item-Total Correlations"
        )
        
        # Calculate alpha if item deleted
        alpha_if_deleted = pd.Series(
            {col: cronbach_alpha(df.drop(columns=col))['alpha'] for col in df.columns},
            name="Alpha if Item Deleted"
        )
        
        results = {
            'alpha': alpha,
            'item_total_correlations': item_total_correlations,
            'alpha_if_deleted': alpha_if_deleted
        }
        
        return results
        
    except Exception as e:
        logging.error(f"Error calculating Cronbach's alpha: {str(e)}")
        raise

def display_results(results: Dict[str, Union[float, pd.Series]]) -> None:
    """Display formatted results of the Cronbach's alpha analysis."""
    print("\nCRONBACH'S ALPHA ANALYSIS")
    print("=" * 50)
    print(f"\nOverall Cronbach's Alpha: {results['alpha']:.3f}")
    
    print("\nItem Analysis:")
    print("-" * 50)
    analysis = pd.DataFrame({
        'Item-Total Correlation': results['item_total_correlations'],
        'Alpha if Item Deleted': results['alpha_if_deleted']
    })
    print(analysis.round(3))

# Example usage with error handling
if __name__ == "__main__":
    try:
        # Sample data
        data = {
            'Item1': [4, 3, 5, 2],
            'Item2': [3, 4, 2, 5],
            'Item3': [5, 4, 3, 4]
        }
        
        df = pd.DataFrame(data)
        logging.info("Processing sample data...")
        
        results = cronbach_alpha(df)
        display_results(results)
        
    except Exception as e:
        logging.error(f"Program execution failed: {str(e)}")
        raise