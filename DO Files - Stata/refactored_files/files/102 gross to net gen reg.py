import pandas as pd
import numpy as np
import os
import downloads.globals_regular as gr

cems_dirreg = gr.config['cems_dirreg']
datadir = gr.config['data_dir']
rawdata_dir = gr.config['rawdata_dir']
eia923_dir = rawdata_dir + "/EIA923"

# Load only needed columns after reading the pickle file
emissions = pd.read_pickle(cems_dirreg + "/emissions_all_unit_allyears21.pkl")[
    ['UTCDATE', 'SO2MASS', 'NOXMASS', 'CO2MASS', 'GLOAD', 'PLANT', 'unitid', 'UTCHOUR']
]


emissions['PLANT'] = emissions['PLANT'].astype('uint8') 
emissions['UTCHOUR'] = emissions['UTCHOUR'].astype('uint8')

emissions['yr'] = emissions['UTCDATE'].astype(int) // 10000
emissions['month'] = (emissions['UTCDATE'].astype(int) // 100) % 100
emissions['yr'] = emissions['yr'].astype('uint16') 
emissions['month'] = emissions['month'].astype('uint8')

# Drop rows where CO2MASS is NA or PLANT is 0
emissions = emissions.dropna(subset=['CO2MASS'])
emissions = emissions[emissions['PLANT'] != 0]



emissions = emissions.sort_values(by=['PLANT', 'UTCDATE', 'unitid',  'UTCHOUR'])
#emissions.drop(columns=['UTCDATE'], inplace=True)
# Reorder columns to match specified order
emissions = emissions[['PLANT', 'UTCDATE', 'unitid', 'UTCHOUR', 'SO2MASS', 'NOXMASS', 'CO2MASS', 'GLOAD', 'yr', 'month']]

print("Emissions loaded and sorted")

print(emissions.info())
pd.set_option('display.max_columns', None)
print(f"\nNumber of unique plant-unit combinations: {len(emissions.groupby(['PLANT', 'unitid']).size())}")

print(emissions.head(10))

# Take first 100k rows and save to csv
plant_3_data = emissions[(emissions['PLANT'] == 3) & (emissions['unitid'] == 1)]
plant_3_data.to_csv(f"{cems_dirreg}/plant_3_data.csv", index=False)

print("Saved 100k row sample to CSV")
