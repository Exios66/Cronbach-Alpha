import numpy as np
import pandas as pd

# Create example data
data = np.array([
    [4, 3, 5, 2, 4],
    [3, 4, 2, 5, 3],
    [5, 4, 3, 4, 5],
    [2, 5, 4, 3, 2],
    [4, 3, 5, 2, 4],
    [3, 4, 2, 5, 3],
    [5, 4, 3, 4, 5],
    [2, 5, 4, 3, 2],
    [4, 3, 5, 2, 4],
    [3, 4, 2, 5, 3]
])

# Save as numpy array
np.save('example_data.npy', data)

# Save as pandas DataFrame
df = pd.DataFrame(data, columns=['Item1', 'Item2', 'Item3', 'Item4', 'Item5'])
df.to_pickle('example_data.pkl') 