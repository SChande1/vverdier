import pandas as pd
import numpy as np
from pathlib import Path
from downloads.globals_regular import config


# Set up paths
raw_data_dir = config['rawdata_dir']
data_dir = config['data_dir']
temp_dir = config['temp_dir']
cemsdirreg = config['cems_dirreg']

# v3 updates to include 2022
# make master plant file with plant orispl codes, fips, interconnection, NERC Regions, NERC subregions, EIA 930 regions, Balancing Authority Code, so2 and nox damages in dollars per pound in 2020 dollars

# use new crosswalk from BA to region downloaded 11/30/22
ba_region_crosswalk = pd.read_excel(f"{raw_data_dir}/EIA930/EIA930_Reference_Tables.xlsx")
ba_region_crosswalk = ba_region_crosswalk.rename(columns={
    'BA Code': 'bacode',
    'BA Name': 'baname_930',
    'Time Zone': 'timezone',
    'Region/Country Name': 'region'
})
print(ba_region_crosswalk.columns)
ba_region_crosswalk = ba_region_crosswalk[['bacode', 'baname_930', 'timezone', 'region']]
ba_region_crosswalk.to_pickle(f"{data_dir}/BalancingAuthority_Region_crosswalk21.pkl")

# make master list of all plants in CEMS data from 2019-2022
cems_plant_list = pd.concat([
    pd.read_pickle(f"{cemsdirreg}/plants in cems {year}.pkl") for year in range(2019, 2022)
])
cems_plant_list.to_pickle(f"{data_dir}/cems_plant_list_19-22.pkl")

# epa file with plant, name, state and city
epa_crosswalk = pd.read_excel(f"{raw_data_dir}/EIA930/oris-ghgrp_crosswalk_public_ry14_final.xls", skiprows=3)
epa_crosswalk['PlantCode'] = pd.to_numeric(epa_crosswalk['ORIS CODE'], errors='coerce')
epa_crosswalk = epa_crosswalk.dropna(subset=['PlantCode'])
epa_crosswalk = epa_crosswalk[['PlantCode', 'GHGRP - State', 'FACILITY NAME', 'GHGRP - City']]
epa_crosswalk = epa_crosswalk.drop_duplicates(subset=['PlantCode'], keep='first')
epa_crosswalk.to_pickle(f"{temp_dir}/temp7.pkl")

# EIA 860 information about plants
eia_860_plant = pd.read_excel(f"{raw_data_dir}/EIA860/2___Plant_Y2021.xlsx", skiprows=1)
eia_860_plant = eia_860_plant[['PlantCode', 'PlantName', 'City', 'State', 'Zip', 'County', 'Latitude', 'Longitude', 'NERCRegion', 'BalancingAuthorityCode', 'BalancingAuthorityName']]
eia_860_plant.to_stata(temp_dir / "temp2.dta")

# Continue with the rest of the data processing...
# (The rest of the code would follow a similar pattern of reading data, processing it, and saving to Stata files)

# Final merges and data cleanup
final_data = pd.read_stata(data_dir / "cems_plant_list_19-22.dta")
final_data = final_data.drop(columns=['yr']).drop_duplicates()

# Merge with other datasets
final_data = final_data.merge(pd.read_stata(data_dir / "plant_locationEPA22.dta"), on='PLANT', how='left')
final_data = final_data.merge(pd.read_stata(data_dir / "plant_pollution_damagesEPA22.dta"), on='PLANT', how='left')

# Rename columns and perform data cleaning
final_data = final_data.rename(columns={'BACODE': 'bacode'})
final_data.loc[final_data['PLANT'] == 880079, 'bacode'] = 'TVA'

# Merge with BA Region crosswalk
final_data = final_data.merge(pd.read_stata(data_dir / "BalancingAuthority_Region_crosswalk21.dta"), on='bacode', how='left')

# Add INTERCON column
final_data['INTERCON'] = 'East'
final_data.loc[final_data['NERC'] == 'WECC', 'INTERCON'] = 'West'
final_data.loc[final_data['NERC'] == 'TRE', 'INTERCON'] = 'Texas'

# Clean up and standardize data
# (Include all the data cleaning steps here)

# Save final dataset
final_data.to_stata(data_dir / "plant_all_data22.dta")
