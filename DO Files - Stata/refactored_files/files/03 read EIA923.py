# Import necessary libraries
import pandas as pd, numpy as np, matplotlib.pyplot as plt
import os, zipfile, requests
from scipy import stats
from io import BytesIO
import downloads.download_eia923 as download_eia923


# Define paths
rawdata_dir = "C:/Users/shrey/Desktop/UNC CH Verdier/DO Files - Stata/refactored_files/rawdata_dir"
tempdir = "C:/Users/shrey/Desktop/UNC CH Verdier/DO Files - Stata/refactored_files/tempdir"

# Create subfolders
EIA923_dir = "C:/Users/shrey/Desktop/UNC CH Verdier/DO Files - Stata/refactored_files/rawdata_dir/EIA923"
if not os.path.exists(EIA923_dir):
    os.makedirs(EIA923_dir)

years = download_eia923.years
used_files = download_eia923.used_files


# Function to process EIA923 data
def process_eia923_data(file_path, year):
    # Read Excel file
    df = pd.read_excel(file_path, sheet_name='Page 1 Generation and Fuel Data', header=5)
    
    # Add year column
    df['yr'] = year
    
    # Rename columns
    column_mapping = {
        'Plant Id': 'PLANT',
        'Net Generation\n(Megawatthours)': 'NGEN',
        'Netgen\nJanuary': 'ngen1',
        'Netgen\nFebruary': 'ngen2',
        'Netgen\nMarch': 'ngen3',
        'Netgen\nApril': 'ngen4',
        'Netgen\nMay': 'ngen5',
        'Netgen\nJune': 'ngen6',
        'Netgen\nJuly': 'ngen7',
        'Netgen\nAugust': 'ngen8',
        'Netgen\nSeptember': 'ngen9',
        'Netgen\nOctober': 'ngen10',
        'Netgen\nNovember': 'ngen11',
        'Netgen\nDecember': 'ngen12',
        'Elec_MMBtu\nJanuary': 'input1',
        'Elec_MMBtu\nFebruary': 'input2',
        'Elec_MMBtu\nMarch': 'input3',
        'Elec_MMBtu\nApril': 'input4',
        'Elec_MMBtu\nMay': 'input5',
        'Elec_MMBtu\nJune': 'input6',
        'Elec_MMBtu\nJuly': 'input7',
        'Elec_MMBtu\nAugust': 'input8',
        'Elec_MMBtu\nSeptember': 'input9',
        'Elec_MMBtu\nOctober': 'input10',
        'Elec_MMBtu\nNovember': 'input11',
        'Elec_MMBtu\nDecember': 'input12',
        'AER\nFuel Type Code': 'AERFTYPE',
        'MER\nFuel Type Code': 'AERFTYPE',
        'Plant State': 'State',
        'NERC Region': 'NERCRegion',
        'Reported\nPrime Mover': 'ReportedPrimeMover'
    }
    df.rename(columns=column_mapping, inplace=True)

    
    # Generate FTYPE column
    df['FTYPE'] = np.select([
        df['AERFTYPE'].isin(['NG', 'OOG']),
        df['AERFTYPE'].isin(['COL', 'PC', 'WOC']),
        df['AERFTYPE'].isin(['DFO', 'WOO', 'RFO']),
        df['AERFTYPE'] == 'NUC',
        df['AERFTYPE'] == 'SUN',
        df['AERFTYPE'] == 'WND',
        df['AERFTYPE'] == 'HYC'
    ], ['GAS', 'COAL', 'OIL', 'NUKE', 'SOLAR', 'WIND', 'HYDRO'], default='OTHER')
    



    # Drop rows for HI and AK
    df = df[~df['State'].isin(['HI', 'AK'])]
    
    # Process NERC regions
    df['NERCRegion'] = df['NERCRegion'].replace('TRE', 'ERCOT')
    df['nNERC'] = pd.Categorical(df['NERCRegion']).codes
    df['mediannercstate'] = df.groupby('State')['nNERC'].transform(lambda x: x.mode().iloc[0])
    
    nerc_mapping = {1: 'ERCOT', 2: 'FRCC', 3: 'MRO', 4: 'NPCC', 5: 'RFC', 6: 'SERC', 7: 'SPP', 8: 'WECC'}
    df.loc[df['NERCRegion'] == '', 'NERCRegion'] = df.loc[df['NERCRegion'] == '', 'mediannercstate'].map(nerc_mapping)
    
    # Generate ccgt column
    df['ccgt'] = df['ReportedPrimeMover'].isin(['CA', 'CS', 'CT'])
    
    # Convert columns to numeric
    for col in [f'ngen{i}' for i in range(1, 13)] + [f'input{i}' for i in range(1, 13)]:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    
    # Keep only necessary columns
    columns_to_keep = ['yr', 'FTYPE', 'PLANT', 'NGEN', 'NERCRegion', 'State', 'ccgt'] + \
                      [f'ngen{i}' for i in range(1, 13)] + [f'input{i}' for i in range(1, 13)]
    df = df[columns_to_keep]
    
    return df

# Process data for each year
dfs = []
for year, file_name in zip(years, used_files):
    file_path = f"{rawdata_dir}/EIA923/{file_name}"
    df = process_eia923_data(file_path, year)
    dfs.append(df)
    os.remove(file_path)

# Combine all dataframes
final_df = pd.concat(dfs, ignore_index=True)

# Save the final dataframe
final_df.to_csv(EIA923_dir + "/EIA923_2019_22.csv")

# Internal consistency check
df_check = pd.read_csv(EIA923_dir + "/EIA923_2019_22.csv")
df_check = df_check[~df_check['FTYPE'].isin(['HYDRO', 'NUKE', 'SOLAR', 'WIND'])]

df_check['Fuel'] = np.select([
    df_check['FTYPE'] == 'COAL',
    df_check['FTYPE'] == 'GAS'
], ['Coal', 'Gas'], default='Other')

df_check = df_check.groupby(['PLANT', 'Fuel', 'yr']).agg({
    'NGEN': 'sum',
    'ccgt': 'mean',
    **{f'ngen{i}': 'sum' for i in range(1, 13)},
    **{f'input{i}': 'sum' for i in range(1, 13)}
}).reset_index()

df_check = df_check.melt(id_vars=['PLANT', 'Fuel', 'yr', 'NGEN', 'ccgt'],
                         value_vars=[f'ngen{i}' for i in range(1, 13)] + [f'input{i}' for i in range(1, 13)],
                         var_name='month', value_name='value')

df_check['type'] = df_check['month'].str[:4]

# Remove the word 'input' from the 'month' column
df_check['month'] = df_check['month'].str.replace('input', '')
df_check['month'] = df_check['month'].str.replace('ngen', '')

# Now safely convert the 'month' column to integers
df_check['month'] = df_check['month'].astype(int)


df_check = df_check.pivot(index=['PLANT', 'Fuel', 'yr', 'month'], columns='type', values='value').reset_index()
df_check = df_check[df_check['Fuel'] == 'Coal']


df_check.rename(columns = {'inpu': 'input'}, inplace=True)


df_check = df_check[(df_check['input'] > 0) & (df_check['ngen'] > 0)]

# Calculate coefficients and R-squared for each plant
results = df_check.groupby('PLANT').apply(lambda x: 
    stats.linregress(x['input'], x['ngen']) if len(x) > 10 else None
).dropna()

coef_rsq = pd.DataFrame({
    'PLANT': results.index,
    'coef': results.apply(lambda x: x.slope),
    'rsqr': results.apply(lambda x: x.rvalue**2)
})

# Plot results
plt.figure(figsize=(10, 6))
plt.scatter(coef_rsq['coef'], coef_rsq['rsqr'])
plt.xlabel('Coefficient')
plt.ylabel('R-squared')
plt.title('Coefficient vs R-squared for Coal Plants')
plt.show()