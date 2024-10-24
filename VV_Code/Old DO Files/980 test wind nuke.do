
clear
save $temp10, emptyok replace

foreach thehour in $hoursAll {
*foreach thehour in 23 24{

** slightly different procedures for inter, region, balance, and sub

use "data/Hourly_Sub_Load.dta", clear
keep  subregion demand utcdate utchour 
keep if inlist(subregion,"COAS","EAST","FWES","NCEN","NRTH","SCEN","SOUT","WEST")
reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==`thehour'

save $temp1, replace


* pull one hour of generation data
use "data/hourly/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
gen inter = "East"
replace inter="West" if inlist(region,"CAL","NW","SW")
replace inter="Texas" if region=="TEX"

keep if region=="TEX"

**** just do  summer  months
gen month = month(utcdate)
keep if month>=6 & month<=9

keep if ID=="ERCO_All_wind"
rename netgen netgenwind
save $temp6, replace

* pull one hour of generation data
use "data/hourly/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
gen inter = "East"
replace inter="West" if inlist(region,"CAL","NW","SW")
replace inter="Texas" if region=="TEX"

keep if region=="TEX"

**** just do  summer  months
gen month = month(utcdate)
keep if month>=6 & month<=9
keep if ID=="ERCO_All_nuke"
rename netgen netgennuke
save $temp7, replace


qui merge 1:1 utcdate utchour using $temp1, nogen keep(3)
qui merge 1:1 utcdate utchour using $temp6, nogen keep(3)



save $temp2, replace


use $temp2, clear
gen localhour = utchour - 5
if localhour < 1 replace localhour = localhour + 24
sort utcdate utchour
gen t = _n



gen demand1 = demandWEST + demandNRTH
gen demand2 = demand1 + demandFWES

label var demand1 "load  West + North"
label var demand2 "load  West + North + Far West"
label var netgenwind "wind generation"
label var demandWEST "load West"
* about half of nuke comes from comanche peak (which is in central TX- other plant is south of houston)
replace netgennuke = netgennuke/2
gen diff1 = 1 if (netgenwind - (demandWEST-netgennuke) <0)
gen diff2 = 1 if (netgenwind - (demand1-netgennuke) <0)
gen diff3 = 1 if (netgenwind - (demand2 -netgennuke) <0)
gen diff4 = 1 if (netgenwind - (demandWEST) <0)
gen diff5 = 1 if (netgenwind - (demand1) <0)
gen diff6 = 1 if (netgenwind - (demand2) <0)


dis "***********************************"
dis "utc hour `thehour'" 
replace diff1 = 0 if diff1==.
replace diff2 = 0 if diff2==.
replace diff3 = 0 if diff3==.
replace diff4 = 0 if diff4==.
replace diff5 = 0 if diff5==.
replace diff6 = 0 if diff6==.
collapse (sum) diff1 diff2 diff3 diff4 diff5 diff6, by (localhour)
append using $temp10
save $temp10, replace


*twoway (line netgenwind t) (line  demandFWES t) (line demandFWESplusWEST t) (line demandFWESplusWESTplusNRTH  t)

*collapse (sum) netgen demandFWES demandFWESplusWEST demandFWESplusWESTplusNRTH
*gen diff = netgen - demandFWESplusWESTplusNRTH
*sum diff
}


use $temp10, clear
