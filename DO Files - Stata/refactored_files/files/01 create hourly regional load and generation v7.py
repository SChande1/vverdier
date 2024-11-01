import pandas as pd
import numpy as np
import os
import downloads.globals_regular as gr

# Create empty temporary dataframes
temp_df = pd.DataFrame()
temp7_df = pd.DataFrame()

# Import and combine regional data
for region in gr.AllRegions:
    print(region)
    df = pd.read_csv(r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\rawdata_dir\EIA930\Regional\Region_" + region + ".csv")
    
    # Filter years
    df['Local date'] = pd.to_datetime(df['Local date'])
    df = df[df['Local date'].dt.year.between(2019, 2022)]
    temp_df = pd.concat([temp_df, df])

# Convert column names to lowercase
temp_df.columns = temp_df.columns.str.lower()

# Generate UTC dates and hours
temp_df['utcdate'] = pd.to_datetime(temp_df['utc time']).dt.date
temp_df['utchour'] = pd.to_datetime(temp_df['utc time']).dt.hour + 1

# Adjust UTC date for hour 24
temp_df.loc[temp_df['utchour'] == 24, 'utcdate'] = \
    pd.to_datetime(temp_df.loc[temp_df['utchour'] == 24, 'utcdate']) - pd.Timedelta(days=1)

temp_df.to_pickle('temp.pkl')

# Process data by hour
for hour in gr.hoursAll:
    hourly_df = temp_df[temp_df['utchour'] == hour].copy()
    
    # Rename columns
    hourly_df = hourly_df.rename(columns={
        'localdate': 'date',
        'd': 'demand',
        'ngng': 'gengas', 
        'ngsun': 'gensun',
        'ngwnd': 'genwind',
        'ngnuc': 'gennuke',
        'ngwat': 'genwater',
        'ngcol': 'gencoal',
        'ngoil': 'genoil'
    })
    
    # Fill NaN values with 0 for generation columns
    gen_cols = [col for col in hourly_df.columns if col.startswith('ng')] + \
               [col for col in hourly_df.columns if col in ['cal', 'mex']]
    hourly_df[gen_cols] = hourly_df[gen_cols].fillna(0)
    
    # Calculate other generation
    hourly_df['genother'] = hourly_df['ng: oth'] + hourly_df['ng: unk']
    hourly_df = hourly_df.drop(['ng: oth', 'ng: unk'], axis=1)
    
    # Set up trade variables
    # West
    hourly_df['genMEXtoCAL'] = np.where(hourly_df['region'] == 'CAL', hourly_df['mex'], 0)
    hourly_df['genCANtoNW'] = np.where(hourly_df['region'] == 'NW', hourly_df['can'], 0)
    hourly_df['genCENTtoNW'] = np.where(hourly_df['region'] == 'NW', hourly_df['cent'], 0)
    hourly_df['genCENTtoSW'] = np.where(hourly_df['region'] == 'SW', hourly_df['cent'], 0)
    
    # Texas
    hourly_df['genCENTtoTEX'] = np.where(hourly_df['region'] == 'TEX', hourly_df['cent'], 0)
    hourly_df['genMEXtoTEX'] = np.where(hourly_df['region'] == 'TEX', hourly_df['mex'], 0)
    
    # East
    hourly_df['genCANtoCENT'] = np.where(hourly_df['region'] == 'CENT', hourly_df['can'], 0)
    hourly_df['genCANtoMIDW'] = np.where(hourly_df['region'] == 'MIDW', hourly_df['can'], 0)
    hourly_df['genCANtoNE'] = np.where(hourly_df['region'] == 'NE', hourly_df['can'], 0)
    hourly_df['genCANtoNY'] = np.where(hourly_df['region'] == 'NY', hourly_df['can'], 0)
    hourly_df['genTEXtoCENT'] = np.where(hourly_df['region'] == 'CENT', hourly_df['tex'], 0)
    hourly_df['genNWtoCENT'] = np.where(hourly_df['region'] == 'CENT', hourly_df['nw'], 0)
    hourly_df['genSWtoCENT'] = np.where(hourly_df['region'] == 'CENT', hourly_df['sw'], 0)
    
    # Add region names
    region_names = {
        'CAL': 'California',
        'CAR': 'Carolinas', 
        'CENT': 'Central',
        'FLA': 'Florida',
        'MIDA': 'Mid-Atlantic',
        'MIDW': 'Midwest',
        'NE': 'New England',
        'NY': 'New York',
        'NW': 'Northwest',
        'SE': 'Southeast',
        'SW': 'Southwest',
        'TEN': 'Tennessee',
        'TEX': 'Texas'
    }
    hourly_df['regionname'] = hourly_df['region'].map(region_names)
    
    # Sort and append
    print(hourly_df.columns)

    hourly_df = hourly_df.sort_values(['region', 'local date', 'hour'])
    temp7_df = pd.concat([temp7_df, hourly_df])

# Save final output
temp7_df.to_csv(r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\rawdata_dir\EIA930\Hourly_Regional_Load_Generation.csv", index=False)