
* do globals-regular.do

import   excel using "../rawdata//EIA Nuke/NUC_STATUS_cap.xlsx", firstrow clear
replace PlantName=strtrim(PlantName)
save $temp1, replace

import   excel using "../rawdata//EIA Nuke/NUC_STATUS_out.xlsx", firstrow clear
replace PlantName=strtrim(PlantName)
save $temp2, replace

use $temp2, clear
merge 1:1 date PlantName using $temp1 ,nogen keep(3)

keep if date < 20220101
drop if PlantName=="U.S. nuclear"

** https://www.eia.gov/nuclear/outages/  shows 3 plants in west 2 plants in texas currently operating (2/26/2023)
** tab PlantName shows 6 plants that don't have data over the full three years of the sample. These are all in the east (Pilgrim Nuclear
** Power Station, Three Mile Island, Indian Point 2 and 3, Duane Arnold, River Bend Station  )
** note all decommisioned plants are in the east
** note: regions are approximate
gen inter="East"
replace inter="West" if inlist(PlantName,"Columbia Generating Station","Diablo Canyon","Palo Verde")
replace inter="Texas" if inlist(PlantName,"Comanche Peak","South Texas Project")
gen region="MIDA"
replace region="CAL" if PlantName=="Diablo Canyon"
replace region="NW" if PlantName=="Columbia Generating Station"
replace region="SW" if PlantName=="Palo Verde"
replace region="TEX" if inlist(PlantName,"Comanche Peak","South Texas Project")
replace region="NE" if inlist(PlantName,"Millstone","Seabrook","Pilgrim Nuclear Power Station")
replace region="NY" if inlist(PlantName,"Indian Point 2","Indian Point 3","James A Fitzpatrick","R. E. Ginna Nuclear Power Plant","Nine Mile Point Nuclear Station")
replace region="FLA" if inlist(PlantName,"St Lucie","Turkey Point")
replace region="CENT" if inlist(PlantName,"Cooper","Wolf Creek Generating Station")
replace region="CAR" if inlist(PlantName,"V C Summer","Harris","Oconee","Catawba","McGuire","H B Robinson","Brunswick")
replace region="MIDW" if inlist(PlantName,"Waterford 3","Prairie Island","Point Beach","Monticello","Grand Gulf")
replace region="MIDW" if inlist(PlantName,"Donald C Cook","Arkansas Nuclear One") 
replace region="MIDW" if inlist(PlantName,"Duane Arnold","Callaway","LaSalle Generating Station","River Bend Station")
*"Quad Cities Generating Station","Byron Generating Station", "Dresden Generating Station","Braidwood Generation Station", "Clinton Power Station",
replace region="SE" if inlist(PlantName,"Vogtle","Joseph M Farley","Edwin I Hatch")
replace region="TEN" if inlist(PlantName,"Sequoyah","Watts Bar Nuclear Plant","Browns Ferry")

** calculate utchour and utcdate to reflect timezone of plant, given that reactor "status is collected between 4am and 8am each day"
** and "all times are based on Eastern Time"
** so assume all times are 6am Eastern time. Then shift by twelve hours so that the status at 6 am accounts for previous 12 hours and
** the next twelve hours
** east coast is utc - 5
** but for now just assume starting time is 1 am utc
gen utcdate = daily(string(date, "%8.0f"), "YMD") 
format date %8.0f 
format utcdate %td 
expand 24

* starting hour is 6am eastern time = 11 am utc; -12 hours shift so just shift by one hour
sort date PlantName
by date PlantName, sort: gen hour = 1 if _n==1
replace hour = hour[_n-1]+1 if missing(hour)
gen utchour = hour
gen generation = cap - out
rename PlantName unitid
gen PLANT = .
drop date hour

save "data/nuclear_generation.dta", replace



** check consistency with eia930 data
** first interconnection

foreach inter in East Texas West{
use "data/Hourly_Regional_Load_Generation.dta", clear
gen inter="East"
replace inter="West" if inlist(region,"CAL","SW","NW")
replace inter="Texas" if inlist(region,"TEX")
collapse (sum) gennuke, by (utcdate utchour inter)
*keep if utcdate > 21550
keep if inter=="`inter'"
save $temp3, replace

use "data/nuclear_generation.dta", clear
*keep if utcdate > 21550
keep if inter=="`inter'"
collapse (sum) generation, by (utcdate utchour)

merge 1:1 utcdate utchour using $temp3
reg generation gennuke

}

** so problem with west

** now regions

foreach region in $AllRegions{
use "data/Hourly_Regional_Load_Generation.dta", clear
collapse (sum) gennuke, by (utcdate utchour region)
*keep if utcdate > 21550
keep if region=="`region'"
save $temp3, replace

use "data/nuclear_generation.dta", clear
*keep if utcdate > 21550
keep if region=="`region'"
collapse (sum) generation, by (utcdate utchour)

merge 1:1 utcdate utchour using $temp3
dis "`region''"
reg generation gennuke
if "`region'"=="NY"{
	dfadfad
}
}




*** look at whole country
use "data/Hourly_Regional_Load_Generation.dta", clear
gen inter="East"
replace inter="West" if inlist(region,"CAL","SW","NW")
replace inter="Texas" if inlist(region,"TEX")
collapse (sum) gennuke, by (utcdate utchour )
keep if utcdate > 21550
gen t=_n
save $temp3, replace

use "data/nuclear_generation.dta", clear
keep if date > 20190101
collapse (sum) generation, by (date hour)
gen t=_n
merge 1:1 t using $temp3

scatter generation gennuke
