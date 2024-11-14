import pandas as pd
import numpy as np
import downloads.globals_regular as gr

# Read facility attributes data
cemsdir = gr.config['cems_dir']
tempdir = gr.config['temp_dir']
cemsdirreg = gr.config['cems_dirreg']
datadir = gr.config['data_dir']

df = pd.read_pickle(f"{cemsdir}/facility-attributes.pkl")

# Rename columns
df = df.rename(columns={
    'facilityID': 'PLANT',
    'year': 'yr',
    'unitId': 'unitid',
    'sourceCategory': 'Source'
})

# Filter source categories
source_categories = [
    "Electric Utility", "Small Power Producer", "Cogeneration",
    "Industrial Boiler", "Industrial Turbine", "Petroleum Refinery",
    "Institutional", "Pulp & Paper Mill"
]
df = df[df['Source'].isin(source_categories)]

# Set fuel types
df['Fuel'] = "Other"
coal_types = [
    "Coal", "Coal Refuse", "Coal, Coal Refuse", "Coal, Natural Gas",
    "Coal, Other Gas", "Coal, Pipeline Natural Gas", "Coal, Wood"
]
gas_types = [
    "Natural Gas", "Pipeline Natural Gas",
    "Natural Gas, Pipeline Natural Gas", "Other Gas"
]

df.loc[df['primaryFuelInfo'].isin(coal_types), 'Fuel'] = "Coal"
df.loc[df['primaryFuelInfo'].isin(gas_types), 'Fuel'] = "Gas"

# Keep only needed columns
df = df[['PLANT', 'unitid', 'yr', 'Fuel', 'Source']]

# Clean unitid by removing leading zeros
df['unitid'] = df['unitid'].apply(lambda x: x.lstrip('0'))

# Save intermediate result
df.to_pickle(f"{tempdir}/temp2.pkl")

# Read and combine CEMS data
cems_dfs = []
for year in range(2019, 2022):
    df_cems = pd.read_pickle(f"{cemsdirreg}/plants and units in cems {year}.pkl")
    cems_dfs.append(df_cems)
cems_df = pd.concat(cems_dfs)
cems_df.to_pickle(f"{datadir}/cems_plant_unit_list_19-22.pkl")

# Merge datasets
merged_df = pd.merge(cems_df, df, on=['PLANT', 'unitid', 'yr'], how='left')

# Fix specific plant unit
merged_df.loc[(merged_df['PLANT'] == 60589) & 
              (merged_df['unitid'] == "CT-1") & 
              (merged_df['yr'] == 2019), 'Fuel'] = "Gas"

# Save final result
merged_df.to_pickle(f"{datadir}/cems_units_fuel_19-22.pkl")
