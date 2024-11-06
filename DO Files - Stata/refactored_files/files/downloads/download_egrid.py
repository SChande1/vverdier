import os, requests, downloads.globals_regular as gr

rawdata_dir = gr.config['rawdata_dir']
os.makedirs(f"{rawdata_dir}/egrid", exist_ok=True)

urls = {
    2018: "https://www.epa.gov/sites/default/files/2020-03/egrid2018_data_v2.xlsx",
    2019: "https://www.epa.gov/sites/default/files/2021-02/egrid2019_data.xlsx", 
    2020: "https://www.epa.gov/system/files/documents/2022-09/eGRID2020_Data_v2.xlsx",
    2021: "https://www.epa.gov/system/files/documents/2023-01/eGRID2021_data.xlsx",
    2022: "https://www.epa.gov/system/files/documents/2024-01/egrid2022_data.xlsx"
}

for year, url in urls.items():
    response = requests.get(url)
    output_path = f"{rawdata_dir}/egrid/egrid{year}_data.xlsx"
    with open(output_path, 'wb') as f:
        f.write(response.content)
