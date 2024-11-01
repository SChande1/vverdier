import requests, os, zipfile

import globals_regular as gr

subfolder_path = f"{gr.config['rawdata_dir']}/EIA860"

def download_eia860():
    url = "https://www.eia.gov/electricity/data/eia860/archive/xls/eia8602021.zip"
    r = requests.get(url, allow_redirects=True)
    if not os.path.exists(subfolder_path):
        os.makedirs(subfolder_path)
    zip_path = os.path.join(subfolder_path, 'eia8602021.zip')
    
    # Save zip file
    with open(zip_path, 'wb') as file:
        file.write(r.content)
    
    # Unzip the file
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(subfolder_path)
        
    # Remove the zip file after extraction
    os.remove(zip_path)

download_eia860()