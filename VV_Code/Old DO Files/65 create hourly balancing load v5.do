
* run globals_regular.do
** syntax for using .csv direcly
*import delimited "../rawdata/EIA930/webdownload/EIA930_BALANCE_2019_Jan_Jun.csv", case(preserve) groupseparator(,) clear 

*  make load data at the bacode level
if 1 {
clear
save $temp1, emptyok replace
import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2019_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2019_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2020_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2020_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2021_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2021_Jul_Dec.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2022_Jan_Jun.xlsx", cellrange(A1) clear firstrow
append using $temp1
save $temp1, replace

import excel using "../rawdata/EIA930/webdownload/EIA930_Balance_2022_Jul_Dec.xlsx", cellrange(A1) clear firstrow
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
label var netgenerationmwfromsolar "Net generation (MWh) from solar energy reported by the balancing authority"
label var netgenerationmwfromwind "Net generation (MWh) from wind reported by the balancing authority"
label var netgenerationmwfromnuclear "Net generation (MWh) from nuclear reported by the balancing authority"
label var netgenerationmwfromhydropo "Net generation (MWh) from hydroelectric power reported by the balancing authority"

rename demandmwadjusted demand
rename netgenerationmwfromcoala gencoal
rename ai gengas
rename aj gennuke
rename ak genoil
rename al genwater
rename am gensun
rename netgenerationmwfromwinda genwind
rename ao ngoth 
rename netgenerationmwfromunknown ngunk

* can't add if there is missing data
replace ngunk=0 if ngunk==.
gen genother=ngoth+ngunk
drop ngoth ngunk
gen inter = "East"
replace inter = "West" if inlist(region,"CAL","NW","SW")
replace inter = "Texas" if region=="TEX" 

rename balancingauthority bacode
order bacode utcdate utchour
sort utcdate utchour bacode region
keep utcdate utchour bacode region demand inter gencoal gengas gennuke genoil genwater gensun genwind genother

** bacodes AZPS and SRP have almost identical 4GW capacity generation from nuke throughout 2019. This is almost certainly an
** an errror, as there is only one 4GW plant in Arizona (and only 8 GW total in the western interconnection)
** this error is confirmed by looking at the Nuclear outage data from EIA (see "04 read EIA nuke v2.do" )
** nuke generation from AZPS disappears on Dec 4 2019 at 8am, but remains in SRP
** so zero out all nuke generation from AZPS
replace gennuke = 0 if bacode =="AZPS"
save "data/Hourly_Balancing_Load22.dta", replace





