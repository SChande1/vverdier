
* run globals_regular.do
** syntax for using .csv direcly
*import delimited "../rawdata/EIA930/webdownload/EIA930_BALANCE_2019_Jan_Jun.csv", case(preserve) groupseparator(,) clear 

*  make load data at the bacode level
if 1 {
clear
save $temp1, emptyok replace
import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2019_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2019_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2020_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2020_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2021_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2021_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2022_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_SUBREGION_2022_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace
}



use $temp1, clear
rename *, lower
rename utctimeatendofhour utctime
gen utcdate=dofc(utctime)
format utcdate %td

gen utchour=Clockpart(utctime,"h")+1  
replace utcdate=utcdate-1 if utchour==24
  
label var utcdate "Universal standard time's date"
label var utchour "Universal standard time's hour"

label var demandmw "Demand (MWh) is the electricity load aggregated across a region's balancing authorities' electric systems"
* Demand is a calculated value representing the amount of electricity load within the balancing authority's electric system. A BA derives its demand value by taking the total metered net electricity generation within its electric system and subtracting the total metered net electricity interchange occurring between the BA and its neighboring BAs.  This column displays in MWh the sum of the demand of the BAs in the region."

rename demandmw demand

gen inter = "East"
replace inter = "West" if balancingauthority=="CISO"
replace inter = "Texas" if balancingauthority=="ERCO" 

rename balancingauthority bacode
gen region = "CAL"
replace region="TEX" if bacode=="ERCO"
replace region="MIDW" if bacode=="MISO"
replace region="MIDA" if bacode =="PJM"
replace region="CENT" if bacode=="SWPP"
replace region="NE" if bacode=="ISNE"
replace region="NY" if bacode=="NYIS"
drop if bacode=="PNM"

**

order bacode utcdate utchour
sort utcdate utchour bacode region
keep utcdate utchour bacode region demand inter subregion

* DOM  has a two crazy outliers. Replace with average of hour before and after
replace demand=(10931 + 9521)/2 if utcdate==22572 & utchour == 3 & subregion=="DOM"
replace demand= (10931 + 9521)/2 if utcdate==22572 & utchour== 4 & subregion=="DOM"
* same for CE
replace demand = (15397 + 15391)/2 if utcdate==22161 & utchour==21 & subregion=="CE"
replace demand = (12121 + 12696)/2 if utcdate==21895  & utchour==22 & subregion=="CE"

save "data/Hourly_Sub_Load22.dta", replace



