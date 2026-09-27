# Process

### Step 1 
The Fitbit datasets were imported into Google BigQuery and checked for missing values, duplicates, and invalid values.

### Step 2 
Duplicate sleep records were identified and removed, reducing the sleep dataset from 413 to 410 records.

### Step 3 
The data was also checked for negative values and inconsistencies in sleep duration. Zero-step and zero-calorie records 
were reviewed and retained as potential data quality limitations rather than removing it directly. 

### Step 4 
Finally, the cleaned sleep data was combined with the daily activity data to create a `daily_analysis` table for analysis.
