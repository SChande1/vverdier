import downloads.globals_regular as globals_regular
import os, zipfile, requests

rawdata_dir = globals_regular.config['rawdata_dir']
EIA923_path = os.path.join(rawdata_dir, 'EIA923')

used_files = [
        "EIA923_Schedules_2_3_4_5_M_12_2019_Final_Revision.xlsx",
        "EIA923_Schedules_2_3_4_5_M_12_2020_Final_Revision.xlsx",
        "EIA923_Schedules_2_3_4_5_M_12_2021_Final_Revision.xlsx",
        "EIA923_Schedules_2_3_4_5_M_12_2022_Final_Revision.xlsx",
    ]
years = [2019, 2020, 2021, 2022]

def main():
    if not os.path.exists(EIA923_path):
        os.makedirs(EIA923_path)

    

    # Download and unzip the data
    for year in years:
        url = f"https://www.eia.gov/electricity/data/eia923/archive/xls/f923_{year}.zip"
        response = requests.get(url)
        zip_path = os.path.join(EIA923_path, f"f923_{year}.zip")
        with open(zip_path, "wb") as f:
            f.write(response.content)

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(EIA923_path)
        os.remove(zip_path)
        
    #Remove unused files
    

    for filename in os.listdir(EIA923_path):
        if filename not in used_files:
            os.remove(os.path.join(EIA923_path, filename))

#main()