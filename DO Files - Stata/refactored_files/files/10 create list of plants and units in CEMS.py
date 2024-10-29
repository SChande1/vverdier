import pandas as pd
import os
import glob
import downloads.globals_regular as gr

# Define global variables (assuming these are defined elsewhere)
cemsdir = gr.config['cems_dir']
tempdir = gr.config['temp_dir']
cemsdirreg = gr.config['cems_dirreg']
datadir = gr.config['data_dir']
states = gr.us_states


# def process_2022():
#     states = ['al', 'ar', 'az', 'ca', 'co', 'ct', 'dc', 'de', 'fl', 'ga', 'ia', 'id', 'il', 'in', 'ks', 'ky', 'la', 'ma', 'md', 'me', 'mi', 'mn', 'mo', 'ms', 'mt', 'nc', 'nd', 'ne', 'nh', 'nj', 'nm', 'nv', 'ny', 'oh', 'ok', 'or', 'pa', 'ri', 'sc', 'sd', 'tn', 'tx', 'ut', 'va', 'vt', 'wa', 'wi', 'wv', 'wy']

#     for state in states:
#         df = pd.read_csv(f"{cemsdir}/cems-2022/emissions-hourly-2022-{state}.csv")
#         print(f"Processing {state} for 2022")

#         df = df.rename(columns={
#             'grossloadmw': 'GLOAD',
#             'facilityid': 'PLANT'
#         })

#         df['unitid'] = df['unitid'].astype(str).str.lstrip('0')
#         df['maxgload'] = df.groupby('PLANT')['GLOAD'].transform('max')
#         df = df[df['maxgload'] != 0]
#         df['yr'] = 2022

#         df = df[['PLANT', 'unitid', 'yr']].sort_values(['PLANT', 'unitid', 'yr']).drop_duplicates()

#         if state != 'al':
#             previous_df = pd.read_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")
#             df = pd.concat([previous_df, df], ignore_index=True)

#         df.to_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")

#     df.to_pickle(f"{cemsdirreg}/plants and units in cems 2022.pkl")
#     os.remove(f"{tempdir}/emissions_co2_unit_2022.pkl")

def make_plant_list():
    for year in range(2019, 2022):
        df = pd.read_pickle(f"{cemsdirreg}/plants and units in cems {year}.pkl")
        df = df.drop('unitid', axis=1).drop_duplicates()
        df.to_pickle(f"{cemsdirreg}/plants in cems {year}.pkl")


make_plant_list()