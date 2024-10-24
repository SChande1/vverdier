import pandas as pd, requests, os, sys, json
from datetime import date, datetime, timezone
import globals_regular as gr


cemsdir = gr.config['cems_dir']
api_key_EPA = gr.config['api_key_EPA']
url_base = 'https://api.epa.gov/easey/bulk-files/'
aware_dt = datetime(2014, 1, 1, 0, 0, 0, tzinfo=timezone.utc)


parameters = {
    'api_key': api_key_EPA,
}

dateToday = date.today()
month, year = (dateToday.month-1, dateToday.year) if dateToday.month != 1 else (12, dateToday.year-1)
prevMonth = dateToday.replace(day=1, month=month, year=year)
# timeOfLastDownload = datetime.fromisoformat(str(prevMonth)+"T00:00:00.000Z"[:-1] + '+00:00')

r = requests.get(r"https://api.epa.gov/easey/camd-services/bulk-files", params=parameters)

print("Status code: "+str(r.status_code))
if (int(r.status_code) > 399):
    sys.exit("Error message: "+r.json()['error']['message'])

resjson = r.content.decode('utf8').replace("'", '"')
bulkFiles = json.loads(resjson)

dfBulkFiles = pd.DataFrame(bulkFiles)
dfBulkFiles.to_csv(os.path.join(cemsdir, 'bulk_files.csv'), index=False)

emissionsFiles = [fileObj for fileObj in bulkFiles if (fileObj['metadata']['dataType']=="Emissions")]
hourlyEmissionsFiles = [fileObj for fileObj in emissionsFiles if (fileObj['metadata']['dataSubType']=="Hourly") and (int(fileObj['metadata']['year']) >= 2014)]


print('Number of files to download: '+str(len(hourlyEmissionsFiles)))


downloadMB = sum(int(fileObj['megaBytes']) for fileObj in hourlyEmissionsFiles)
print('Total size of files to download: '+str(downloadMB)+' MB')

if len(hourlyEmissionsFiles) > 0:
    # loop through all files and download them
    for fileObj in hourlyEmissionsFiles:
        url = url_base + fileObj['s3Path']
        print('Full path to file on S3: ' + url)
        # download and save file
        response = requests.get(url)

        # save file to disk in the data folder
        if not os.path.exists(os.path.join(cemsdir, fileObj['metadata']['stateCode'])):
            os.makedirs(os.path.join(cemsdir, fileObj['metadata']['stateCode']))

        file_path = os.path.join(cemsdir, fileObj['metadata']['stateCode'], fileObj['metadata']['year'] + '.csv')
        with open(file_path, 'wb') as f:
            f.write(response.content)

        # Remove the fileObj from hourlyEmissionsFiles
        hourlyEmissionsFiles.remove(fileObj)
else:
    print('No files to download')
