import pandas as pd, requests, os, sys, json
from datetime import date, datetime, timezone
import globals_regular as gr
import downloads.globals_regular as gr

states = gr.us_states
cemsdir = gr.config['cems_dir']
api_key_EPA = gr.config['api_key_EPA']
url_base = r'https://api.epa.gov/easey/bulk-files/emissions/hourly/state/emissions-hourly-'


parameters = {
    'api_key': api_key_EPA,
}

def main():
    r = requests.get(r"https://api.epa.gov/easey/camd-services/bulk-files", params=parameters)

    print("Status code: "+str(r.status_code))
    if (int(r.status_code) > 399):
        sys.exit("Error message: "+r.json()['error']['message'])

    resjson = r.content.decode('utf8').replace("'", '"')
    bulkFiles = json.loads(resjson)

    dfBulkFiles = pd.DataFrame(bulkFiles)
    dfBulkFiles.to_csv(os.path.join(cemsdir, 'bulk_files.csv'), index=False)



    hourlyEmissionsFiles = [
        fileObj for fileObj in bulkFiles 
        if "emissions-hourly-" in fileObj['filename']
        and "q" not in fileObj['filename'].lower()
        and any(year in fileObj['filename'] for year in ['2019', '2020', '2021'])
    ]


    print('Number of files to download: '+str(len(hourlyEmissionsFiles)))


    downloadMB = sum(int(fileObj['megaBytes']) for fileObj in hourlyEmissionsFiles)
    print('Total size of files to download: '+str(downloadMB)+' MB')



    for state in states:
        if not os.path.exists(os.path.join(cemsdir, state)):
            os.makedirs(os.path.join(cemsdir, state), exist_ok=True)
        for year in ['2019', '2020', '2021']:
            if not os.path.exists(os.path.join(cemsdir, state, year + '.csv')):
                url = url_base + year + '-' + state.lower() + '.csv'
                response = requests.get(url)
                file_path = os.path.join(cemsdir, state, year + '.csv')
                with open(file_path, 'wb') as f:
                    f.write(response.content)
