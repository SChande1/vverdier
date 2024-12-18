import pandas as pd
import os
import downloads.globals_regular as globals_regular

# Assuming globals are defined elsewhere
cemsdir = globals_regular.config['cems_dir']
tempdir = globals_regular.config['temp_dir']
cemsdirreg = globals_regular.config['cems_dirreg']
datadir = globals_regular.config['data_dir']
states = globals_regular.us_states


def process_year(year):
    

    # used for converting all month files into a full year state pkl file
    for state in states:

        os.makedirs(f"{tempdir}/{state}", exist_ok=True)
        
        df = pd.read_csv(f"{cemsdir}/{state}/{year}.csv", low_memory=False)    
        df.to_pickle(f"{tempdir}/{state}/emissions_co2_unit_{year}.pkl")
        

years = [2019, 2020, 2021]


for year in years:
    process_year(year)
    df_year = []

    for state in states:
        df = pd.read_pickle(f"{tempdir}/{state}/emissions_co2_unit_{year}.pkl")
        
        print(f"Processing {state} for {year}")
        
        rename_dict = {
            'SO2 Mass (lbs)': 'SO2MASS',
            'NOx Mass (lbs)': 'NOXMASS',
            'CO2 Mass (short tons)': 'CO2MASS',
            'Heat Input (mmBtu)': 'HEAT',
            'Gross Load (MW)': 'GLOAD',
            'Facility ID': 'PLANT',
            'Hour': 'HOUR',
            'Unit ID': 'unitid'
        }
        df.rename(columns=rename_dict, inplace=True)
        
    
        
        df['maxgload'] = df.groupby('PLANT')['GLOAD'].transform('max')
        df = df[df['maxgload'] != 0]
        
        df['unitid'] = df['unitid'].astype(str).str.lstrip('0')
        # print(df.columns)
        
        df['DATE'] = pd.to_datetime(df['Date']).dt.strftime('%Y%m%d').astype(int)
        df['yr'] = df['DATE'] // 10000
        
        df = df[['PLANT', 'unitid', 'DATE', 'HOUR', 'SO2MASS', 'CO2MASS', 'NOXMASS', 'GLOAD', 'yr']]
        df = df.sort_values(['PLANT', 'unitid', 'DATE', 'HOUR']).drop_duplicates()
        

        df.to_pickle(f"{tempdir}/{state}/emissions_co2_unit_{year}.pkl")
    
        df_year.append(df)
    
    df_year = pd.concat(df_year, ignore_index=True)
    df_year.to_pickle(f"{cemsdirreg}/plants and units in cems {year}.pkl")



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^UN COMMENT THIS ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    
# def process_2022():
#     states = ['al', 'ar', 'az', 'ca', 'co', 'ct', 'dc', 'de', 'fl', 'ga', 'ia', 'id', 'il', 'in', 'ks', 'ky', 'la', 'ma', 'md', 'me', 'mi', 'mn', 'mo', 'ms', 'mt', 'nc', 'nd', 'ne', 'nh', 'nj', 'nm', 'nv', 'ny', 'oh', 'ok', 'or', 'pa', 'ri', 'sc', 'sd', 'tn', 'tx', 'ut', 'va', 'vt', 'wa', 'wi', 'wv', 'wy']
    
#     for state in states:
#         df = pd.read_csv(f"{cemsdir}/cems-2022/emissions-hourly-2022-{state}.csv")
        
#         print(f"Processing {state} for 2022")
        
#         rename_dict = {
#             'so2masslbs': 'SO2MASS', 'noxmasslbs': 'NOXMASS', 'co2massshorttons': 'CO2MASS',
#             'grossloadmw': 'GLOAD', 'facilityid': 'PLANT', 'hour': 'HOUR'
#         }
#         df.rename(columns=rename_dict, inplace=True)
        
#         df['maxgload'] = df.groupby('PLANT')['GLOAD'].transform('max')
#         df = df[df['maxgload'] != 0]
        
#         df['unitid'] = df['unitid'].astype(str).str.lstrip('0')
        
#         df['DATE'] = pd.to_datetime(df['date']).dt.strftime('%Y%m%d').astype(int)
#         df['yr'] = df['DATE'] // 10000
        
#         df = df[['PLANT', 'unitid', 'DATE', 'HOUR', 'SO2MASS', 'CO2MASS', 'NOXMASS', 'GLOAD']]
#         df = df.sort_values(['PLANT', 'unitid', 'DATE', 'HOUR'])
        
#         if state != 'al':
#             previous_df = pd.read_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")
#             df = pd.concat([previous_df, df], ignore_index=True)
        
#         df.to_pickle(f"{tempdir}/emissions_co2_unit_2022.pkl")
    
#     df.to_pickle(f"{cemsdirreg}/emissions_all_unit_2022.pkl")
#     os.remove(f"{tempdir}/emissions_co2_unit_2022.pkl")

def combine_years():
    dfs = []
    states = globals_regular.us_states
    for year in range(2019, 2022):
        for state in states:
            df = pd.read_pickle(f"{tempdir}/{state}/emissions_co2_unit_{year}.pkl")
            dfs.append(df)
            
    
        combined_df = pd.concat(dfs, ignore_index=True)

        plant_data = pd.read_pickle(f"{datadir}/plant_all_data22.pkl")

        combined_df = combined_df.merge(plant_data[['PLANT', 'timezonezip']], on='PLANT', how='left')
        
        combined_df.to_csv(f"{cemsdirreg}/plants and units in cems all years.csv")

        combined_df['HOUR'] = combined_df['HOUR'] + 1
        combined_df = combined_df.dropna(subset=['DATE'])
        combined_df = combined_df.dropna(subset=['timezonezip'])

        combined_df['timezonezip'] = combined_df['timezonezip'].astype(int)


            
        for col in ['SO2MASS', 'CO2MASS', 'NOXMASS', 'GLOAD']:
            print(f"Processing {col}...")
            
            # Process each group separately to save memory
            for (plant, unit), group in combined_df.groupby(['PLANT', 'unitid']):
                if len(group) > 0:
                    timezone = int(group['timezonezip'].iloc[0])  # Get timezone for this group
                    combined_df.loc[group.index, col] = group[col].shift(timezone)
                
                # Clean up memory
                del group
                import gc
                gc.collect()

        # Continue with the rest of your code...
        combined_df = combined_df.rename(columns={'DATE': 'UTCDATE', 'HOUR': 'UTCHOUR'})
        combined_df['UTCDATE'] = combined_df['UTCDATE'].astype(int)
        combined_df['UTCHOUR'] = combined_df['UTCHOUR'].astype(int)
        
        combined_df = combined_df.drop(columns=['timezonezip'])
        
        
        combined_df.to_pickle(f"{cemsdirreg}/emissions_all_unit_{year}.pkl")
    dfs2 = []
    for year in range(2019, 2022):
        df = pd.read_pickle(f"{cemsdirreg}/emissions_all_unit_{year}.pkl")
        dfs2.append(df)
        os.remove(f"{cemsdirreg}/emissions_all_unit_{year}.pkl")

    combined_df2 = pd.concat(dfs2, ignore_index=True)
    combined_df2.to_pickle(f"{cemsdirreg}/emissions_all_unit_allyears21.pkl")

combine_years()