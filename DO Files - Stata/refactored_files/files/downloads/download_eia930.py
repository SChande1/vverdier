import requests, json, csv, pandas as pd, os, shutil, openpyxl
from concurrent.futures import ThreadPoolExecutor
from globals_regular import config

#DEFINE EXCELS SUBDIR PATH FOR ALL DOWNLOADED EXCELS, CREATES EXCELS SUBDIR IF ONE DOES NOT ALREADY EXIST
subfolder_path = os.path.join(config['rawdata_dir'], 'EIA930')
regional_path = os.path.join(subfolder_path, 'Regional')
month_path = os.path.join(subfolder_path, 'Month')


def main():
    # Create subdirectories if they don't exist
    for path in [subfolder_path,month_path, regional_path]:
        os.makedirs(path, exist_ok=True)
    # Download six-month files in parallel
    years = ["2022", "2021", "2020", "2019"]
    periods = ['Jan_Jun', 'Jul_Dec']

    # Download six-month files
    for year in years:
        for period in periods:
            if not os.path.exists(os.path.join(month_path, f'EIA930_BALANCE_{year}_{period}.csv')):
                with ThreadPoolExecutor() as executor:
                    executor.map(lambda period: download_six_month_file(year, period), periods)
            else:
                print(f'EIA930_BALANCE_{year}_{period}.csv already exists')

    # Download region files in parallel
    regions = ["CAL","CAR","CENT","FLA","MIDA","MIDW","NE","NW","NY","SE","SW","TEN","TEX", "US48"]

    for region in regions:
        if not os.path.exists(os.path.join(regional_path, f'Region_{region}.csv')):
            with ThreadPoolExecutor() as executor:
                executor.map(download_region_file, regions)
        else:
            print(f'Region_{region}.csv already exists')

    #convert regional excels to csv
    for region in regions:
        if not os.path.exists(os.path.join(regional_path, f'Region_{region}.csv')):
            convert_excel_to_csv(region)
        else:
            print(f'Region_{region}.csv already exists')



            
# Function to download and process six-month files
def download_six_month_file(year, period):
    url = f'https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/EIA930_BALANCE_{year}_{period}.csv'
    csv_file = f'EIA930_BALANCE_{year}_{period}.csv'
    r = requests.get(url, allow_redirects=True)
    
    file_path = os.path.join(month_path, csv_file)
    with open(file_path, 'wb') as f:
        f.write(r.content)
        

        
# Function to download and process region files
def download_region_file(region):
    url = f'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/Region_{region}.xlsx'
    r = requests.get(url, allow_redirects=True)
    
    excel_file_path = os.path.join(regional_path, f'Region_{region}.xlsx')
    csv_file_path = os.path.join(regional_path, f'Region_{region}.csv')
    
    with open(excel_file_path, 'wb') as file:
        file.write(r.content)
    
    
#convert regional excels to csv
def convert_excel_to_csv(region):
    excel_file_path = os.path.join(regional_path, f'Region_{region}.xlsx')
    csv_file_path = os.path.join(regional_path, f'Region_{region}.csv')
    pd.read_excel(excel_file_path).to_csv(csv_file_path, index=False)
    os.remove(excel_file_path)

# main()