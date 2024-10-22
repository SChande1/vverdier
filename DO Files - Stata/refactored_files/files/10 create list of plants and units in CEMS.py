import pandas as pd
import os
import glob
import downloads.globals_regular as gr

# Define global variables (assuming these are defined elsewhere)
cemsdir = gr.config['cems_dir']
tempdir = gr.config['temp_dir']
cemsdirreg = gr.config['cems_dirreg']
datadir = gr.config['data_dir']

def process_state_file(state, year):
    df = pd.read_csv(f"{cemsdir}/cems-{year}/{year}{state}01.csv")
    df.to_pickle(f"{tempdir}/temp_{state}.pkl")

    for month in range(2, 13):
        month_df = pd.read_csv(f"{cemsdir}/cems-{year}/{year}{state}{month:02d}.csv")
        month_df.to_pickle(f"{tempdir}/temp_{state}_{month:02d}.pkl")
        df = pd.read_pickle(f"{tempdir}/temp_{state}.pkl")
        df = pd.concat([df, month_df], ignore_index=True)
        df.to_pickle(f"{tempdir}/temp_{state}.pkl")
        os.remove(f"{tempdir}/temp_{state}_{month:02d}.pkl")

    df.to_pickle(f"{tempdir}/{state}{year}-full.pkl")
    os.remove(f"{tempdir}/temp_{state}.pkl")

def process_year(year):
    states = ['al', 'ar', 'az', 'ca', 'co', 'ct', 'dc', 'de', 'fl', 'ga', 'ia', 'id', 'il', 'in', 'ks', 'ky', 'la', 'ma', 'md', 'me', 'mi', 'mn', 'mo', 'ms', 'mt', 'nc', 'nd', 'ne', 'nh', 'nj', 'nm', 'nv', 'ny', 'oh', 'ok', 'or', 'pa', 'ri', 'sc', 'sd', 'tn', 'tx', 'ut', 'va', 'vt', 'wa', 'wi', 'wv', 'wy']

    for state in states:
        process_state_file(state, year)

    for state in states:
        df = pd.read_pickle(f"{tempdir}/{state}{year}-full.pkl")
        print(f"Processing {state} for {year}")

        df = df.rename(columns={
            'so2_masslbs': 'SO2MASS',
            'nox_masslbs': 'NOXMASS',
            'co2_masstons': 'CO2MASS',
            'so2_mass': 'SO2MASS',
            'nox_mass': 'NOXMASS',
            'co2_mass': 'CO2MASS',
            'heat_input': 'HEAT',
            'gload': 'GLOAD',
            'orispl': 'PLANT',
            'op_hour': 'HOUR'
        })

        df['unitid'] = df['unitid'].astype(str).str.lstrip('0')
        df['maxgload'] = df.groupby('PLANT')['GLOAD'].transform('max')
        df = df[df['maxgload'] != 0]
        df['yr'] = year

        df = df[['PLANT', 'unitid', 'yr']].sort_values(['PLANT', 'unitid', 'yr']).drop_duplicates()

        if state != 'al':
            previous_df = pd.read_pickle(f"{tempdir}/emissions_co2_unit_{year}.pkl")
            df = pd.concat([previous_df, df], ignore_index=True)

        df.to_pickle(f"{tempdir}/emissions_co2_unit_{year}.pkl")

    df.to_pickle(f"{cemsdirreg}/plants and units in cems {year}.pkl")
    os.remove(f"{tempdir}/emissions_co2_unit_{year}.pkl")

    for state in states:
        os.remove(f"{tempdir}/{state}{year}-full.pkl")

def process_2022():
    states = ['al', 'ar', 'az', 'ca', 'co', 'ct', 'dc', 'de', 'fl', 'ga', 'ia', 'id', 'il', 'in', 'ks', 'ky', 'la', 'ma', 'md', 'me', 'mi', 'mn', 'mo', 'ms', 'mt', 'nc', 'nd', 'ne', 'nh', 'nj', 'nm', 'nv', 'ny', 'oh', 'ok', 'or', 'pa', 'ri', 'sc', 'sd', 'tn', 'tx', 'ut', 'va', 'vt', 'wa', 'wi', 'wv', 'wy']

    for state in states:
        df = pd.read_csv(f"{cemsdir}/cems-2022/emissions-hourly-2022-{state}.csv")
        print(f"Processing {state} for 2022")

        df = df.rename(columns={
            'grossloadmw': 'GLOAD',
            'facilityid': 'PLANT'
        })

        df['unitid'] = df['unitid'].astype(str).str.lstrip('0')
        df['maxgload'] = df.groupby('PLANT')['GLOAD'].transform('max')
        df = df[df['maxgload'] != 0]
        df['yr'] = 2022

        df = df[['PLANT', 'unitid', 'yr']].sort_values(['PLANT', 'unitid', 'yr']).drop_duplicates()

        if state != 'al':
            previous_df = pd.read_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")
            df = pd.concat([previous_df, df], ignore_index=True)

        df.to_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")

    df.to_pickle(f"{cemsdirreg}/plants and units in cems 2022.pkl")
    os.remove(f"{tempdir}/emissions_co2_unit_2022.pkl")

def make_plant_list():
    for year in range(2019, 2023):
        df = pd.read_pickle(f"{cemsdirreg}/plants and units in cems {year}.pkl")
        df = df.drop('unitid', axis=1).drop_duplicates()
        df.to_pickle(f"{cemsdirreg}/plants in cems {year}.pkl")

if __name__ == "__main__":
    for year in [2019, 2020, 2021]:
        process_year(year)
    process_2022()
    make_plant_list()
