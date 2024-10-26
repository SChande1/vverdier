import globals_regular as globals_regular, os, requests, time, pandas as pd, numpy as np



rawdata_dir = globals_regular.config['rawdata_dir']
EIANuke_path = os.path.join(rawdata_dir, 'EIANuke')
api_key = globals_regular.config['api_key']

dfs_capacity = []
dfs_outages = []


def main():
    if not os.path.exists(EIANuke_path):
        os.makedirs(EIANuke_path)
    download_EIANuke_Capacity()
    download_EIANuke_Outage()


def download_EIANuke_Capacity():
    dec_bool = 0
    years = list(range(2007, 2023))
    months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
    month_end = ['02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '01']
    for year in years:
        for month in months:
            if month == '12':
                dec_bool = 1
            else:
                dec_bool = 0
            url = f"https://api.eia.gov/v2/nuclear-outages/facility-nuclear-outages/data/?api_key={api_key}&frequency=daily&data[0]=capacity&start={year}-{month}-01&end={year+dec_bool}-{month_end[int(month)-1]}-01&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=5000"
            r = requests.get(url, allow_redirects=True)
           # Parse the JSON response
            json_data = r.json()
            # Assuming the data is under a key 'response' or similar
            records = json_data.get('response', {}).get('data', [])
            
            # Convert to DataFrame
            df = pd.DataFrame(records)
            dfs_capacity.append(df)

    # Concatenate all dataframes
    df_capacity = pd.concat(dfs_capacity)
    
    # Sort by 'period' column
    df_capacity_sorted = df_capacity.sort_values(by='period')
    
    # Write the sorted DataFrame to CSV
    df_capacity_sorted.to_csv(os.path.join(EIANuke_path, 'EIANuke_capacity.csv'), index=False)

def download_EIANuke_Outage():
    dec_bool = 0
    years = list(range(2007, 2023))
    months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
    month_end = ['02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '01']
    for year in years:
        for month in months:
            if month == '12':
                dec_bool = 1
            else:
                dec_bool = 0
            url = f"https://api.eia.gov/v2/nuclear-outages/facility-nuclear-outages/data/?api_key={api_key}&frequency=daily&data[0]=outage&start={year}-{month}-01&end={year+dec_bool}-{month_end[int(month)-1]}-01&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=5000"
            r = requests.get(url, allow_redirects=True)
            # Parse the JSON response
            json_data = r.json()
            # Assuming the data is under a key 'response' or similar
            records = json_data.get('response', {}).get('data', [])
            
            # Convert to DataFrame
            df = pd.DataFrame(records)
            dfs_outages.append(df)

    # Concatenate all dataframes
    df_outage = pd.concat(dfs_outages)
    
    # Sort by 'period' column
    df_outage_sorted = df_outage.sort_values(by='period')
    
    # Write the sorted DataFrame to CSV
    df_outage_sorted.to_csv(os.path.join(EIANuke_path, 'EIANuke_outage.csv'), index=False)
            

# main()