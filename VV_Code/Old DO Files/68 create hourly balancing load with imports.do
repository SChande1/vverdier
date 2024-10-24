
* run globals_regular.do

*  make load data at the bacode level including imports from other BA's (including canada and mexico)

*foreach ba in AEC CPLW {
foreach ba in $AllBAcodes{
dis "`ba'"
import excel using "../rawdata/EIA930/BA files web download/`ba'.xlsx", cellrange(A1) clear firstrow
keep if year(Localdate)>= 2019
keep if year(Localdate)<= 2022
rename *, lower
gen utcdate=dofc(utctime)
format utcdate %td
gen utchour=Clockpart(utctime,"h")+1  
replace utcdate=utcdate-1 if utchour==24
label var utcdate "Universal standard time's date"
label var utchour "Universal standard time's hour"
label var d "Demand (MW) is the electricity load aggregated across a region's balancing authorities' electric systems"
* Demand is a calculated value representing the amount of electricity load within the balancing authority's electric system. A BA derives its demand value by taking the total metered net electricity generation within its electric system and subtracting the total metered net electricity interchange occurring between the BA and its neighboring BAs.  This column displays in MWh the sum of the demand of the BAs in the region."
label var df "Forecast demand (MW)"
label var ngcol "Net hourly generation (MWh) from coal energy reported by the balancing authority"
label var ngng "Net hourly generation (MWh) from natural gas energy reported by the balancing authority"
label var ngoil "Net hourly generation (MWh) from oil energy reported by the balancing authority"
label var ngsun "Net hourly generation (MWh) from solar energy reported by the balancing authority"
label var ngwnd "Net hourly generation (MWh) from wind reported by the balancing authority"
label var ngnuc "Net hourly generation (MWh) from nuclear reported by the balancing authority"
label var ngwat "Net hourly generation (MWh) from hydroelectric power reported by the balancing authority"
**** use adjusted data (EIA 930 replaces negative and very extreme entries with imputed values)
rename localdate date
rename adjustedd demand
rename adjustednggen gengas
rename adjustedsungen gensun
rename adjustedwndgen genwind
rename adjustednucgen gennuke
rename adjustedwatgen genwater
rename adjustedcolgen gencoal
rename adjustedoilgen genoil
replace adjustedunkgen=0 if adjustedunkgen==.
gen genother=adjustedothgen+adjustedunkgen
label var genother "Net hourly generation (MWh) from other energy reported by the balancing authority"
drop adjustedothgen adjustedunkgen
rename ba bacode
*keep bacode  utcdate utchour bacode demand gengas gensun genwind gennuke genwater gencoal genoil miso soco
*order utcdate utchour bacode demand gencoal gengas genoil gennuke gensun genwind genwater miso soco
keep bacode  utcdate utchour bacode demand gengas gensun genwind gennuke genwater gencoal genoil $`ba'_imports
order utcdate utchour bacode demand gencoal gengas genoil gennuke gensun genwind genwater $`ba'_imports
if "`ba'" != "AEC" append using $temp1
save $temp1, replace
}

use $temp1, clear

** bacodes AZPS and SRP have almost identical 4GW capacity generation from nuke throughout 2019. This is almost certainly an
** an errror, as there is only one 4GW plant in Arizona (and only 8 GW total in the western interconnection)
** this error is confirmed by looking at the Nuclear outage data from EIA (see "04 read EIA nuke v2.do" )
** nuke generation from AZPS disappears on Dec 4 2019 at 8am, but remains in SRP
** so zero out all nuke generation from AZPS
replace gennuke = 0 if bacode =="AZPS"
save "data/Hourly_Balancing_Load22_imports.dta", replace





