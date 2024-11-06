import pandas as pd
import numpy as np
import os
from pathlib import Path
from downloads.globals_regular import config
import requests

# Set up paths
raw_data_dir = config['rawdata_dir']
data_dir = config['data_dir']
temp_dir = config['temp_dir']
cemsdirreg = config['cems_dirreg']
cemsdir = config['cems_dir']

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

ba_region_crosswalk = ba_region_crosswalk[['bacode', 'baname_930', 'timezone', 'region']]
ba_region_crosswalk.to_pickle(f"{data_dir}/BalancingAuthority_Region_crosswalk21.pkl")

# make master list of all plants in CEMS data from 2019-2022
cems_plant_list = pd.concat([
    pd.read_pickle(f"{cemsdirreg}/plants in cems {year}.pkl") for year in range(2019, 2022)
])
cems_plant_list.to_pickle(f"{data_dir}/cems_plant_list_19-22.pkl")

# epa file with plant, name, state and city
epa_crosswalk = pd.read_excel(f"{raw_data_dir}/EIA930/oris-ghgrp_crosswalk_public_ry14_final.xls", skiprows=3)
epa_crosswalk['Plant Code'] = pd.to_numeric(epa_crosswalk['ORIS CODE'], errors='coerce')
epa_crosswalk = epa_crosswalk.dropna(subset=['Plant Code'])
epa_crosswalk = epa_crosswalk[['Plant Code', 'GHGRP - State', 'FACILITY NAME', 'GHGRP - City']]
epa_crosswalk = epa_crosswalk.drop_duplicates(subset=['Plant Code'], keep='first')
epa_crosswalk.to_pickle(f"{temp_dir}/temp7.pkl")


# EIA 860 information about plants
eia_860_plant = pd.read_excel(f"{raw_data_dir}/EIA860/2___Plant_Y2021.xlsx", skiprows=1)
eia_860_plant = eia_860_plant[['Plant Code', 'Plant Name', 'City', 'State', 'Zip', 'County', 'Latitude', 'Longitude', 'NERC Region', 'Balancing Authority Code', 'Balancing Authority Name']]
eia_860_plant.to_pickle(f"{temp_dir}/temp2.pkl")

# Generator data
eia_860_gen_op = pd.read_excel(f"{raw_data_dir}/EIA860/3_1_Generator_Y2021.xlsx", sheet_name='Operable', skiprows=1, usecols='A:BU', nrows=23418)
eia_860_gen_op = eia_860_gen_op[['Plant Code', 'Technology', 'Prime Mover', 'Nameplate Capacity (MW)']]

eia_860_gen_ret = pd.read_excel(f"{raw_data_dir}/EIA860/3_1_Generator_Y2021.xlsx", sheet_name='Retired and Canceled', skiprows=1)
eia_860_gen_ret = eia_860_gen_ret[['Plant Code', 'Technology', 'Prime Mover', 'Nameplate Capacity (MW)']]
eia_860_gen_ret['Nameplate Capacity (MW)'] = pd.to_numeric(eia_860_gen_ret['Nameplate Capacity (MW)'], errors='coerce')

eia_860_gen = pd.concat([eia_860_gen_op, eia_860_gen_ret])

# Create plant type categories
def get_plant_type(row):
    if 'Coal' in str(row['Technology']):
        return 'Coal'
    elif 'Natural Gas' in str(row['Technology']):
        if row['Prime Mover'] == 'GT':
            return 'Peak'
        elif row['Technology'] == 'Natural Gas Fired Combined Cycle':
            return 'CCGT'
        else:
            return 'Base'
    elif row['Technology'] in ['Landfill Gas', 'Other Gases', 'Other Waste Biomass']:
        return 'Base'
    return None

eia_860_gen['type'] = eia_860_gen.apply(get_plant_type, axis=1)
eia_860_gen = eia_860_gen[eia_860_gen['type'].notna()]
eia_860_gen = eia_860_gen.rename(columns={'Nameplate Capacity (MW)': 'cap'})

# Aggregate capacity by plant and type
eia_860_gen = eia_860_gen.groupby(['Plant Code', 'type'])['cap'].sum().unstack(fill_value=0)
eia_860_gen = eia_860_gen.reset_index()

# Merge with plant data
plant_data = pd.merge(eia_860_gen, pd.read_pickle(f"{temp_dir}/temp2.pkl"), on='Plant Code', how='inner')
plant_data.to_pickle(f"{temp_dir}/temp4.pkl")

# eGRID data processing
def process_egrid_year(year):
    egrid = pd.read_excel(f"{raw_data_dir}/egrid/egrid{year}_data.xlsx", 
                         sheet_name=f'PLNT{str(year)[-2:]}', skiprows=1)
    if year == 2021:
        cols = ['PSTATABB', 'PNAME', 'ORISPL', 'BANAME', 'BACODE', 'NERC', 
                'SUBRGN', 'SRNAME', 'FIPSST', 'FIPSCNTY', 'CNTYNAME', 
                'PLFUELCT', 'NAMEPCAP']
    else:
        cols = ['ORISPL', 'BACODE']
    return egrid[cols]

egrid_data = process_egrid_year(2021)
egrid_data.to_pickle(f"{temp_dir}/temp5.pkl")

for year in [2020, 2019, 2018]:
    egrid_year = process_egrid_year(year)
    egrid_data.update(egrid_year)

egrid_data = egrid_data.rename(columns={'ORISPL': 'Plant Code'})
egrid_data.to_pickle(f"{temp_dir}/temp5.pkl")

# Read CEMS plant list
cems_plants = pd.read_pickle(f"{data_dir}/cems_plant_list_19-22.pkl")
cems_plants = cems_plants[['PLANT']].drop_duplicates()
cems_plants = cems_plants.rename(columns={'PLANT': 'Plant Code'})

# Merge with previous data
plant_merged = pd.merge(cems_plants, plant_data, on='Plant Code', how='outer')
plant_merged = pd.merge(plant_merged, egrid_data, on='Plant Code', how='outer')
plant_merged = pd.merge(plant_merged, pd.read_pickle(f"{temp_dir}/temp7.pkl"), on='Plant Code', how='outer')

# Manual fixes for specific plants
mask = plant_merged['Plant Code'] == 55703
columns = ['GHGRP - State', 'FIPSST', 'FIPSCNTY', 'CNTYNAME', 'Balancing Authority Code', 'PSTATABB', 'SUBRGN', 'NERC Region']
values = ['TN', '47', '145', 'Shelby', 'TVA', 'TN', 'RFCW', 'SERC']
plant_merged.loc[mask, columns] = values

# NERC region fixes

plant_merged['NERC Region'] = plant_merged['NERC Region'].fillna(plant_merged['NERC Region'])
state_nerc_map = {
    'NPCC': ['MA', 'NY'],
    'RFC': ['DC', 'NJ', 'OH', 'PA', 'MD', 'WV', 'MI'],
    'SERC': ['NC', 'TN', 'VA', 'SC', 'FL', 'AL', 'KY', 'IL'],
    'TRE': ['TX']
}

for nerc, states in state_nerc_map.items():
    mask = plant_merged['GHGRP - State'].isin(states) & plant_merged['NERC'].isna()
    plant_merged.loc[mask, 'NERC'] = nerc

plant_merged.loc[plant_merged['Plant Code'].isin([50074, 54571]), 'NERC'] = 'RFC'

# BACODE and SUBRGN fixes
bacode_fixes = {
    1393: ('MISO', 'SRMV'),
    1594: ('ISNE', 'NEWE'),
    55328: ('PACW', None),
    54571: ('', None)
}

for plant, (bacode, subrgn) in bacode_fixes.items():
    plant_merged.loc[plant_merged['Plant Code'] == plant, 'BACODE'] = bacode
    if subrgn:
        plant_merged.loc[plant_merged['Plant Code'] == plant, 'SUBRGN'] = subrgn

# Fix SUBRGN for specific plants
plant_merged.loc[plant_merged['Plant Code'].isin([6136, 55098]), 'SUBRGN'] = 'ERCT'

plant_merged.to_pickle(f"{data_dir}/CEMS_unit_characteristics22.pkl")

# Process ZIP-county crosswalk

def download_zip_county():
    url = "https://docs.google.com/spreadsheets/d/1o-LIn-RqIAWH9KB5aAmA_jpT-doGc9kk/edit?usp=sharing&ouid=101460272238898795524&rtpof=true&sd=true"
    output_path = f"{raw_data_dir}/zip_county_122019.xlsx"

    # Get the file ID from the URL
    file_id = url.split('/')[5]

    # Construct the download URL
    download_url = f"https://drive.google.com/uc?id={file_id}"

    # Download the file
    response = requests.get(download_url)
    with open(output_path, 'wb') as f:
            f.write(response.content)

if not os.path.exists(f"{raw_data_dir}/zip_county_122019.xlsx"):
    download_zip_county()


zip_county = pd.read_excel(f"{raw_data_dir}/zip_county_122019.xlsx")
zip_county = zip_county.rename(columns={'ZIP': 'Zip', 'COUNTY': 'fips'})
zip_county[['Zip', 'fips']] = zip_county[['Zip', 'fips']].apply(pd.to_numeric)
zip_county = zip_county.drop_duplicates(subset=['Zip'])
zip_county = zip_county[['Zip', 'fips']]
zip_county.to_pickle(f"{temp_dir}/temp1.pkl")

# Process plant characteristics
plant_chars = pd.read_pickle(f"{data_dir}/CEMS_unit_characteristics22.pkl")
plant_chars['Zip'] = plant_chars['Zip'].replace(' ', np.nan)
plant_chars['Zip'] = pd.to_numeric(plant_chars['Zip'], errors='coerce')
plant_chars = pd.merge(plant_chars, zip_county, on='Zip', how='left')

plant_chars['FIPSST'] = pd.to_numeric(plant_chars['FIPSST'])
plant_chars['FIPSCNTY'] = pd.to_numeric(plant_chars['FIPSCNTY'])
plant_chars.loc[plant_chars['fips'].isna(), 'fips'] = (
    plant_chars['FIPSST'] * 1000 + plant_chars['FIPSCNTY']
)

plant_chars = plant_chars.rename(columns={'Plant Code': 'PLANT'})
cols_to_keep = ['PLANT', 'NERC', 'NERC Region', 'Balancing Authority Code', 
                'Balancing Authority Name', 'PSTATABB', 'BANAME', 'BACODE', 
                'NERC Region', 'SUBRGN', 'fips', 'GHGRP - City', 'GHGRP - State', 'Zip', 'FIPSST']
plant_chars = plant_chars[cols_to_keep].drop_duplicates()
plant_chars.to_pickle(f"{data_dir}/plant_location22.pkl")

# Process EPA facility attributes
epa_facility = pd.read_pickle(
    f"{cemsdir}/facility-attributes.pkl"
)

plant_loc = pd.read_pickle(f"{data_dir}/plant_location22.pkl")
plant_merged = pd.merge(epa_facility, plant_loc, on='PLANT', how='outer')
plant_merged['FIPSST'] = pd.to_numeric(plant_merged['FIPSST'], errors='coerce')
plant_merged['FIPSEPACounty'] = pd.to_numeric(plant_merged['FIPSEPACounty'], errors='coerce')
plant_merged['fipsEPA'] = plant_merged['FIPSST'] * 1000 + plant_merged['FIPSEPACounty']
plant_merged['difffip'] = plant_merged['fips'] - plant_merged['fipsEPA']
plant_merged['fipsEPA'] = plant_merged['fipsEPA'].fillna(plant_merged['fips'])

plant_merged = plant_merged.drop('fips', axis=1)
plant_merged = plant_merged.rename(columns={'fipsEPA': 'fips'})



# Fix specific plant locations
plant_merged.loc[plant_merged['PLANT'] == 50074, ['fips', 'SUBRGN']] = [42045, 'RFCE']

plant_merged.to_pickle(f"{data_dir}/plant_locationEPA22.pkl")

# Process AP3 data
ap3_data = pd.read_pickle(f"{raw_data_dir}/AP3_MDs08_14.pkl")
ap3_plants = ap3_data[ap3_data['PLANT'].notna()].copy()
ap3_plants.to_pickle(f"{temp_dir}/temp5.pkl")

ap3_med_stack = ap3_data[
    (ap3_data['PLANT'].isna()) & 
    (ap3_data['Category'] == 'Med Stack') & 
    (ap3_data['fips'].notna())
].copy()
ap3_med_stack.to_pickle(f"{temp_dir}/temp6.pkl")

# Process plant location data
plant_loc = pd.read_pickle(f"{data_dir}/plant_locationEPA22.pkl")
plant_loc = plant_loc[['PLANT', 'fips', 'PSTATABB', 'GHGRP - State']]

plant_loc['temp1'] = plant_loc.groupby('PSTATABB')['fips'].transform('count')
plant_loc['temp2'] = plant_loc.groupby('PSTATABB')['temp1'].transform('max')
plant_loc['temp3'] = np.where(plant_loc['temp1'] == plant_loc['temp2'], plant_loc['fips'], np.nan)
plant_loc['temp4'] = plant_loc['PSTATABB'].fillna(plant_loc['GHGRP - State'])

plant_loc = plant_loc.sort_values(['temp4', 'temp3'], ascending=[True, False])
plant_loc['temp3'] = plant_loc.groupby('temp4')['temp3'].ffill()
plant_loc.loc[plant_loc['fips'].isna(), 'fips'] = plant_loc['temp3']
plant_loc.loc[(plant_loc['fips'].isna()) & (plant_loc['temp4'] == 'DC'), 'fips'] = 11001

# Merge with AP3 data
plant_loc = pd.merge(plant_loc, ap3_plants[['PLANT', 'NOX_2014', 'SO2_2014']], 
                    on='PLANT', how='left')
plant_loc = plant_loc.rename(columns={'NOX_2014': 'mdnox', 'SO2_2014': 'mdso2'})
plant_loc = plant_loc[['PLANT', 'fips', 'mdnox', 'mdso2']]

plant_loc = pd.merge(plant_loc, ap3_med_stack[['fips', 'NOX_2014', 'SO2_2014']], 
                    on='fips', how='left')
plant_loc.loc[plant_loc['mdnox'].isna(), 'mdnox'] = plant_loc['NOX_2014']
plant_loc.loc[plant_loc['mdso2'].isna(), 'mdso2'] = plant_loc['SO2_2014']
plant_loc = plant_loc[['PLANT', 'mdnox', 'mdso2']].sort_values('PLANT')

# Convert to $ per pound in 2020 dollars
plant_loc['mdnox'] = (plant_loc['mdnox'] / 2000) * 1.1028
plant_loc['mdso2'] = (plant_loc['mdso2'] / 2000) * 1.1028

plant_loc.to_pickle(f"{data_dir}/plant_pollution_damagesEPA22.pkl")

# Final merges
cems_plants = pd.read_pickle(f"{data_dir}/cems_plant_list_19-22.pkl")
cems_plants = cems_plants.drop('yr', axis=1).drop_duplicates()

plant_final = pd.merge(cems_plants, 
                      pd.read_pickle(f"{data_dir}/plant_locationEPA22.pkl"), 
                      on='PLANT', how='left')
plant_final = pd.merge(plant_final, 
                      pd.read_pickle(f"{data_dir}/plant_pollution_damagesEPA22.pkl"), 
                      on='PLANT', how='left')

plant_final = plant_final.rename(columns={'BACODE': 'bacode'})
plant_final.loc[plant_final['PLANT'] == 880079, 'bacode'] = 'TVA'

plant_final = pd.merge(plant_final, 
                      pd.read_pickle(f"{data_dir}/BalancingAuthority_Region_crosswalk21.pkl"), 
                      on='bacode', how='left')

plant_final['INTERCON'] = 'East'
plant_final.loc[plant_final['NERC'] == 'WECC', 'INTERCON'] = 'West'
plant_final.loc[plant_final['NERC'] == 'TRE', 'INTERCON'] = 'Texas'

# Fix specific plant data
plant_fixes = {
    2535: {'fips': 36109, 'SUBRGN': 'NYUP'},  # Lansing NY
    2378: {'fips': 34009, 'SUBRGN': 'PJME'},  # Marmora NJ
    55248: {'fips': 39113, 'SUBRGN': 'RFCW'},  # Dayton OH
    10641: {'fips': 42021, 'SUBRGN': 'RFCW'},  # Ebensburgh PA
    10377: {'fips': 51670, 'SUBRGN': 'SRVC'},  # Hopewell VA
    10384: {'fips': 37065, 'SUBRGN': 'SRVC'},  # Battleboro NC
    10071: {'fips': 51740, 'SUBRGN': 'SRVC'},  # Portsmouth VA
    478: {'fips': 8031, 'SUBRGN': 'RMPA'},    # Denver CO
    880079: {'fips': 47105, 'SUBRGN': 'SRTV'}  # Loudon TN
}

for plant, fixes in plant_fixes.items():
    for col, value in fixes.items():
        plant_final.loc[plant_final['PLANT'] == plant, col] = value

# Region name mapping
region_mapping = {
    'Central': 'CENT',
    'Florida': 'FLA',
    'Mid-Atlantic': 'MIDA',
    'Midwest': 'MIDW',
    'New England': 'NE',
    'New York': 'NY',
    'Southeast': 'SE',
    'Southwest': 'SW',
    'Tennessee': 'TEN',
    'California': 'CAL',
    'Northwest': 'NW',
    'Texas': 'TEX'
}

plant_final['regionname'] = plant_final['region']
plant_final['region'] = plant_final['region'].map(region_mapping).fillna('CAR')

plant_final.loc[plant_final['PLANT'] == 50074, 'PSTATABB'] = 'PA'


plant_final = plant_final.drop(['nercRegion', 'difffip', 'FIPSST'], axis=1)
plant_final['PSTATABB'] = plant_final['PSTATABB'].fillna(plant_final['GHGRP - State'])
plant_final = plant_final.drop('GHGRP - State', axis=1)
plant_final = plant_final.rename(columns={'PSTATABB': 'state'})
plant_final.loc[plant_final['bacode'] == 'OVEC', 'bacode'] = 'PJM'
columns_to_drop = ['Balancing Authority Code', 'BalancingAuthorityName', 'BANAME']
existing_columns = [col for col in columns_to_drop if col in plant_final.columns]
plant_final = plant_final.drop(existing_columns, axis=1)

# Handle timezone data
plant_final = plant_final.rename(columns={'Zip': 'zip'})
plant_final = plant_final.drop('timezone', axis=1)


file_id = "1KGRlVm7jPr2cokqO3bL2tbLV3MkfBMlT"

# Construct the download URL
download_url = f"https://drive.google.com/uc?id={file_id}"

# Download the file
response = requests.get(download_url)



# Save the downloaded file
output_path = os.path.join(data_dir, "zip_timezones.csv")
with open(output_path, 'wb') as f:
    f.write(response.content)


plant_final = pd.merge(plant_final, 
                      pd.read_csv(f"{data_dir}/zip_timezones.csv")[['zip', 'timezone']], 
                      on='zip', how='left')
plant_final = pd.merge(plant_final, 
                      pd.read_csv(f"{data_dir}/state_zone.csv"), 
                      on='state', how='left')
plant_final['timezone'] = plant_final['timezone'].fillna(plant_final['stateZone'])

plant_final = plant_final.drop('stateZone', axis=1)
plant_final = plant_final.rename(columns={'timezone': 'timezonezip'})

# Manual timezone fixes
timezone_fixes = {
    1374: -6,
    2817: -6,
    880079: -5
}

for plant, tz in timezone_fixes.items():
    plant_final.loc[plant_final['PLANT'] == plant, 'timezonezip'] = tz

plant_final['timezone'] = ''
plant_final.loc[plant_final['timezonezip'] == -5, 'timezone'] = 'Eastern'
plant_final.loc[plant_final['timezonezip'] == -6, 'timezone'] = 'Central'
plant_final.loc[plant_final['timezonezip'] == -7, 'timezone'] = 'Mountain'
plant_final.loc[(plant_final['timezonezip'] == -7) & 
                (plant_final['state'] == 'AZ'), 'timezone'] = 'Arizona'
plant_final.loc[plant_final['timezonezip'] == -8, 'timezone'] = 'Pacific'

plant_final.to_pickle(f"{data_dir}/plant_all_data22.pkl")

nums = [1, 2, 4, 5, 6, 7]
for num in nums:
    os.remove(f"{temp_dir}/temp{num}.pkl")
