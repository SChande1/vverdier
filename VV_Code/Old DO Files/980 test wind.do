



*foreach thehour in $hoursAll {
foreach thehour in 23{

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

keep if ID=="ERCO_All_wind"



qui merge 1:1 utcdate utchour using $temp1, nogen keep(3)




save $temp2, replace

dfads

use $temp2, clear
sort utcdate utchour
gen t = _n

gen demandFWESplusWEST = demandFWES + demandWEST
gen demandFWESplusWESTplusNRTH = demandFWESplusWEST + demandNRTH
label var demandFWESplusWEST "load FarWest + West"
label var demandFWESplusWESTplusNRTH "load FarWest + West + North"
label var netgen "wind generation"
label var demandFWES "load FarWest"
gen diff1 = 1 if (netgen - demandFWES <0)
gen diff2 = 1 if (netgen - demandFWESplusWEST <0)
gen diff3 = 1 if (netgen - demandFWESplusWESTplusNRTH <0)
tab diff1
tab diff2
tab diff3

twoway (line netgen t) (line  demandFWES t) (line demandFWESplusWEST t) (line demandFWESplusWESTplusNRTH t)

*collapse (sum) netgen demandFWES demandFWESplusWEST demandFWESplusWESTplusNRTH
*gen diff = netgen - demandFWESplusWESTplusNRTH
*sum diff

}
