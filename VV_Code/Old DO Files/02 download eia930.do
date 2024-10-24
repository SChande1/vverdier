/*
python:
import requests
url = 'https://www.eia.gov/nuclear/outages/#/?day=1/1/2022/Nuclear_Plant_Outages_for_1_1_2022.csv'
r = requests.get(url, allow_redirects=True)
open('testit.csv', 'wb').write(r.content)	
end
*/



* download EIA 930 data using Python
* first run globals_regular

** region files
cd ../rawdata/EIA930/webdownload
python:
import requests
regions = ["CAR","CENT","FLA","MIDA","MIDW","NE","NY","SE","TEN","CAL","NW","SW","TEX", "US48"]
for region in regions:
	url = 'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/Region_'+region+'.xlsx'
	r = requests.get(url, allow_redirects=True)
	open('Region_'+region+'.xlsx', 'wb').write(r.content)	

end
cd ../../../stata


** balancing authority files
cd ../rawdata/EIA930/webdownload
python:
import requests
	
years=["2022","2021","2020","2019"]	
for year in years:
	url = 'https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/EIA930_BALANCE_'+year+'_Jan_Jun.csv'
	r = requests.get(url, allow_redirects=True)
	open('EIA930_BALANCE_'+year+'_Jan_Jun.csv', 'wb').write(r.content)
	url = 'https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/EIA930_BALANCE_'+year+'_Jul_Dec.csv'
	r = requests.get(url, allow_redirects=True)
	open('EIA930_BALANCE_'+year+'_Jul_Dec.csv', 'wb').write(r.content)
	

end
cd ../../../stata

** individual balancing authority files

/*

cd ../rawdata/EIA930/webdownload
python:
import requests
bas=["AEC","AECI","AVA","AVRN","AZPS","BANC","BPAT","CHPD","CISO","CPLE","CPLW","DEAA","DOPD","DUK","EEI","EPE","ERCO","FMPP","FPC","FPL"]
bas1=["GCPD","GLHB","GRID","GRIF","GRMA","GVL","GWA","HGMA","HST","IID","IPCO","ISNE","JEA","LDWP","LGEE","MISO","NEVP","NSB","NWMT","NYIS"]
bas2=["OVEC","PACE","PACW","PGE","PJM","PNM","PSCO","PSEI","SC","SCEG","SCL","SEG","SEPA","SOCO","SPA","SRP","SWPP","TAL","TEC","TECP"]
bas3=["TIDC","TPWR","TVA","WACM","WALC","WAUW","WWA","YAD"]

for ba in bas:
	url = 'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/'+ba+'.xlsx'
	r = requests.get(url, allow_redirects=True)
	open('ba'+ba+'.xlsx', 'wb').write(r.content)
for ba in bas1:
	url = 'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/'+ba+'.xlsx'
	r = requests.get(url, allow_redirects=True)
	open('ba'+ba+'.xlsx', 'wb').write(r.content)
for ba in bas2:
	url = 'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/'+ba+'.xlsx'
	r = requests.get(url, allow_redirects=True)
	open('ba'+ba+'.xlsx', 'wb').write(r.content)
for ba in bas3:
	url = 'https://www.eia.gov/electricity/gridmonitor/knownissues/xls/'+ba+'.xlsx'
	r = requests.get(url, allow_redirects=True)
	open('ba'+ba+'.xlsx', 'wb').write(r.content)	
end

cd ../../../stata

*/

*** subregion files

/*

https://www.eia.gov/electricity/gridmonitor/dashboard/electric_overview/US48/US48
click on "download data" in upper right
then click on 'six month files' 
directly download the .csv files

EIA930_SUBREGION_2018_Jul_Dec.csv
EIA930_SUBREGION_2019_Jan_Jun.csv
EIA930_SUBREGION_2019_Jul_Dec.csv
EIA930_SUBREGION_2020_Jan_Jun.csv
EIA930_SUBREGION_2020_Jul_Dec.csv
EIA930_SUBREGION_2021_Jan_Jun.csv
EIA930_SUBREGION_2021_Jul_Dec.csv
EIA930_SUBREGION_2022_Jan_Jun.csv
*/












