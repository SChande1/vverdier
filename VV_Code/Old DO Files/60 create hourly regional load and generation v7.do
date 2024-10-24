
***  run "globals_regular.do"

if 1 {
* make "data/Hourly_Regional_Load_Generation.dta"
clear
save $temp, replace emptyok
foreach Region in $AllRegions {
*foreach Region in MIDA {
	display "`Region'"
	import excel using "../rawdata/EIA930/webdownload/Region_`Region'.xlsx", first sheet("Published Hourly Data") cellrange(A1) clear
	keep if year(Localdate)>= 2019
	keep if year(Localdate)<= 2022
	append using $temp
	save $temp, replace
	}
}
use $temp, clear
rename *, lower

label var localdate "Local date"
* The date (using the specified local time zone) for which data has been reported"
label var hour	"Local hour"
* The hour number for the day.  Hour 1 corresponds to the time period 12:00 AM - 1:00 AM"
gen utcdate=dofc(utctime)
format utcdate %td
gen utchour=Clockpart(utctime,"h")+1  
replace utcdate=utcdate-1 if utchour==24

save $temp, replace

clear
save $temp7, emptyok replace

foreach thehour in $hoursAll  {

use $temp, clear
keep if utchour==`thehour'
label var utcdate "Universal standard time's date"
label var utchour "Universal standard time's hour"
label var d "Demand (MW) is the electricity load aggregated across a region's balancing authorities’ electric systems"
* Demand is a calculated value representing the amount of electricity load within the balancing authority’s electric system. A BA derives its demand value by taking the total metered net electricity generation within its electric system and subtracting the total metered net electricity interchange occurring between the BA and its neighboring BAs.  This column displays in MWh the sum of the demand of the BAs in the region."
label var df "Forecast demand (MW)"
label var ngcol "Net hourly generation (MWh) from coal energy reported by the balancing authority"
label var ngng "Net hourly generation (MWh) from natural gas energy reported by the balancing authority"
label var ngoil "Net hourly generation (MWh) from oil energy reported by the balancing authority"
label var ngsun "Net hourly generation (MWh) from solar energy reported by the balancing authority"
label var ngwnd "Net hourly generation (MWh) from wind reported by the balancing authority"
label var ngnuc "Net hourly generation (MWh) from nuclear reported by the balancing authority"
label var ngwat "Net hourly generation (MWh) from hydroelectric power reported by the balancing authority"

rename localdate date

foreach v of varlist ng* cal-mex {
	recode `v' .=0
}
rename d demand
rename ngng gengas
rename ngsun gensun
rename ngwnd genwind
rename ngnuc gennuke
rename ngwat genwater
rename ngcol gencoal
rename ngoil genoil
gen genother=ngoth+ngunk
label var genother "Net hourly generation (MWh) from other energy reported by the balancing authority"
drop ngoth ngunk

*** set up trade variables

*** Inter=="West"
gen genMEXtoCAL=mex if region=="CAL"    
gen genCANtoNW=can if region=="NW"
gen genCENTtoNW=cent if region=="NW"
gen genCENTtoSW=cent if region=="SW"
*** Inter=="Texas"
gen genCENTtoTEX=cent if region=="TEX"
gen genMEXtoTEX=mex if region=="TEX"
*** Inter=="East"
gen genCANtoCENT=can if region=="CENT"
gen genCANtoMIDW=can if region=="MIDW"
gen genCANtoNE=can if region=="NE"
gen genCANtoNY=can if region=="NY"
gen genTEXtoCENT=tex if region=="CENT"
gen genNWtoCENT=nw if region=="CENT"
gen genSWtoCENT=sw if region=="CENT" 



gen regionname = ""
replace regionname = "California" if region == "CAL"
replace regionname = "Carolinas" if region == "CAR"
replace regionname = "Central" if region == "CENT"
replace regionname = "Florida"	if region == 	"FLA"
replace regionname = "Mid-Atlantic"	if region == 	"MIDA"
replace regionname = "Midwest"	if region == 	"MIDW"
replace regionname = "New England"	if region == 	"NE"
replace regionname = "New York"	if region == 	"NY"
replace regionname = "Northwest"	if region == 	"NW"
replace regionname = "Southeast"	if region == 	"SE"
replace regionname = "Southwest"	if region == 	"SW"
replace regionname = "Tennessee"	if region == 	"TEN"
replace regionname = "Texas"	if region == 	"TEX"
sort region date hour
append using $temp7
save $temp7, replace
}
save "data/Hourly_Regional_Load_Generation22.dta", replace








