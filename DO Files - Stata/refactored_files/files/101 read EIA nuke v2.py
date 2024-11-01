import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import downloads.globals_regular as gr
from datetime import datetime, timedelta
import os


# Read CSV files
nuc_status_cap = pd.read_csv(os.path.join(gr.config['rawdata_dir'], "EIANuke", "EIANuke_capacity.csv"))
nuc_status_out = pd.read_csv(os.path.join(gr.config['rawdata_dir'], "EIANuke", "EIANuke_outage.csv"))

# Clean facilityName
nuc_status_cap['facilityName'] = nuc_status_cap['facilityName'].str.strip()
nuc_status_out['facilityName'] = nuc_status_out['facilityName'].str.strip()



# Merge dataframes
df = pd.merge(nuc_status_out, nuc_status_cap, on=['period', 'facilityName'], how='inner')

# Clean period
# Remove dashes from the 'period' column
df['period'] = df['period'].str.replace('-', '', regex=False)
df['period'] = df['period'].astype(int)  # Ensure 'period' is of type int
df = df[df['period'] < 20220101]


# Filter data
df = df[df['period'] < 20220101]
df = df[df['facilityName'] != "U.S. nuclear"]

# Define regions
def assign_region(plant):
    region_mapping = {
        "West": {"Columbia Generating Station": "NW", "Diablo Canyon": "CAL", "Palo Verde": "SW"},
        "Texas": {"Comanche Peak": "TEX", "South Texas Project": "TEX"},
        "East": {
            "Millstone": "NE", "Seabrook": "NE", "Pilgrim Nuclear Power Station": "NE",
            "Indian Point 2": "NY", "Indian Point 3": "NY", "James A Fitzpatrick": "NY",
            "R. E. Ginna Nuclear Power Plant": "NY", "Nine Mile Point Nuclear Station": "NY",
            "St Lucie": "FLA", "Turkey Point": "FLA",
            "Cooper": "CENT", "Wolf Creek Generating Station": "CENT",
            "V C Summer": "CAR", "Harris": "CAR", "Oconee": "CAR", "Catawba": "CAR",
            "McGuire": "CAR", "H B Robinson": "CAR", "Brunswick": "CAR",
            "Waterford 3": "MIDW", "Prairie Island": "MIDW", "Point Beach": "MIDW",
            "Monticello": "MIDW", "Grand Gulf": "MIDW", "Donald C Cook": "MIDW",
            "Arkansas Nuclear One": "MIDW", "Duane Arnold": "MIDW", "Callaway": "MIDW",
            "LaSalle Generating Station": "MIDW", "River Bend Station": "MIDW",
            "Vogtle": "SE", "Joseph M Farley": "SE", "Edwin I Hatch": "SE",
            "Sequoyah": "TEN", "Watts Bar Nuclear Plant": "TEN", "Browns Ferry": "TEN"
        }
    }

    # This function assigns a region and interconnection to a given plant.
    # It iterates through the region_mapping dictionary, checking if the plant exists in any region.
    # If found, it returns the interconnection and the specific region for that plant.
    # If the plant is not found in any specific region, it defaults to the "East" interconnection and "MIDA" region.
    for inter, plants in region_mapping.items():
        if plant in plants:
            return inter, plants.get(plant, "MIDA")
    return "East", "MIDA"

df['inter'], df['region'] = zip(*df['facilityName'].map(assign_region))

# Calculate UTC period and hour
df['utcdate'] = pd.to_datetime(df['period'].astype(str), format='%Y%m%d')
df = df.loc[df.index.repeat(24)].reset_index(drop=True)
df['utchour'] = df.groupby(['period', 'facilityName']).cumcount() + 1

# Calculate generation
df['generation'] = df['capacity'] - df['outage']
df = df.rename(columns={'facilityName': 'unitid'})
df['PLANT'] = np.nan

# Save to file
df.to_csv(os.path.join(gr.config['rawdata_dir'], "EIANuke", "nuclear_generation.csv"), index=False)

# Check consistency with EIA930 data
def check_consistency(df, eia930_df, group_by):
    df_grouped = df.groupby(['utcdate', 'utchour', group_by])['generation'].sum().reset_index()

    eia930_grouped = eia930_df.groupby(['utcdate', 'utchour', group_by])['ng: nuc'].sum().reset_index()
    
    merged = pd.merge(df_grouped, eia930_grouped, on=['utcdate', 'utchour', group_by])
    
    for name, group in merged.groupby(group_by):
        print(f"{group_by}: {name}")
        model = np.polyfit(group['generation'], group['ng: nuc'], 1)
        print(f"Slope: {model[0]}, Intercept: {model[1]}")
        print("---")

# Load EIA930 data
eia930_df = pd.read_csv(r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\rawdata_dir\EIA930\Hourly_Regional_Load_Generation.csv")


# Try this conversion instead
try:
    # Option 1: Using ISO format
    eia930_df['utcdate'] = pd.to_datetime(eia930_df['utcdate'], format='ISO8601')
except:
    try:
        # Option 2: Using mixed format
        eia930_df['utcdate'] = pd.to_datetime(eia930_df['utcdate'], format='mixed')
    except:
        # Option 3: Most flexible approach
        def clean_datetime(x):
            if pd.isna(x):
                return None
            try:
                # Remove any extra whitespace
                x = str(x).strip()
                return pd.to_datetime(x)
            except:
                print(f"Problem converting date: {x}")
                return None

        eia930_df['utcdate'] = eia930_df['utcdate'].apply(clean_datetime)

# If you only want the date portion (no time):
eia930_df['utcdate'] = pd.to_datetime(eia930_df['utcdate']).dt.date


eia930_df['utcdate'] = pd.to_datetime(eia930_df['utcdate'])
eia930_df['inter'] = np.where(eia930_df['region'].isin(['CAL', 'SW', 'NW']), 'West',
                              np.where(eia930_df['region'] == 'TEX', 'Texas', 'East'))

print(eia930_df.columns)

# Check consistency by interconnection
check_consistency(df, eia930_df, 'inter')

# Check consistency by region
all_regions = eia930_df['region'].unique()
check_consistency(df, eia930_df, 'region')

# Look at whole country
eia930_country = eia930_df[eia930_df['utcdate'] > '2019-01-01'].groupby(['utcdate', 'utchour'])['ng: nuc'].sum().reset_index()
df_country = df[df['period'] > 20190101].groupby(['utcdate', 'utchour'])['generation'].sum().reset_index()

merged_country = pd.merge(df_country, eia930_country, on=['utcdate', 'utchour'])
plt.scatter(merged_country['generation'], merged_country['ng: nuc'])
plt.xlabel('Nuclear Generation (Our Data)')
plt.ylabel('Nuclear Generation (EIA930)')
plt.title('Comparison of Nuclear Generation Data')
plt.show()