# Example Data for Cronbach's Alpha Analysis

This directory contains example data files for testing the Cronbach's Alpha implementations in different programming languages.

## Data Description

The example dataset contains responses from 10 participants on 5 items, with scores ranging from 1-5 on a Likert scale.

### File Formats

- `example_data.csv` - CSV format (accessible by all implementations)
- `example_data.mat` - MATLAB format
- `example_data.RData` - R format
- `example_data.npy` - NumPy format
- `example_data.pkl` - Pandas DataFrame format

### Data Structure

- Rows: 10 participants
- Columns: 5 items
- Values: Integer scores from 1-5

### Usage Examples

#### MATLAB

```matlab
load('example_data.mat');
results = cronbach(data);
```

#### R

```R
data <- read.csv('example_data.csv')
results <- cronbach(data)
```

#### Python

```python
data = pd.read_csv('example_data.csv')
results = cronbach(data)
```

Alternatively, using pandas:

```python
data = pd.read_pickle('example_data.pkl')
results = cronbach(data)
```

### Notes

- All data files contain the same underlying data in different formats
- The CSV file serves as a common format readable by all implementations
- Each implementation includes appropriate data loading functions
