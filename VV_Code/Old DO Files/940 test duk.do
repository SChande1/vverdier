
clear
save $temp10, emptyok replace


*** first look at just DUK nuke, before and after weatherizing

*foreach thehour in $hoursAll {
foreach thehour in 17{


use "data/Hourly_Balancing_Load.dta", clear

keep  bacode demand utcdate utchour 
keep if inlist(bacode,"DUK")

*reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==`thehour'

save $temp1, replace



* pull one hour of generation data
use "data/hourly/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
gen inter = "East"
replace inter="West" if inlist(region,"CAL","NW","SW")
replace inter="Texas" if region=="TEX"

keep if region=="CAR"
keep if ID=="DUK_All_nuke"
merge 1:1 utcdate utchour using $temp1, nogen keep(3)
gen month=month(utcdate)
reg netgen demand
reg netgen demand if month>=6 & month <=9
cor netgen demand if month>=6 & mont <=9


use "data/weather/East_balance_17_weatherized", clear
keep if ID=="DUK_All_nuke"
reg netgen demandDUK
cor netgen demandDUK



}

*now DUK

use "data/hourly/coefsconstrained_balance23.dta", clear
merge 1:1 idnum using "data/hourly/plant_unit_to_idnum_crosswalk23.dta"

keep btildaDUK idnum ID
sort btildaDUK 


use "data/weather/East_balance_17_weatherized", clear
keep if strpos(ID,"nuke")
keep if inter=="East"
corr netgen demandDUK if ID=="MISO_All_nuke"
corr netgen demandDUK if ID=="SWPP_All_nuke"
corr netgen demandDUK if ID=="DUK_All_nuke"
corr netgen demandDUK if ID=="CPLE_All_nuke"
corr netgen demandDUK if ID=="CPLW_All_nuke"
corr netgen demandDUK if ID=="SCEG_All_nuke"
corr netgen demandDUK if ID=="BPAT_All_nuke"


** now FMPP

use "data/hourly/coefsconstrained_balance23.dta", clear
merge 1:1 idnum using "data/hourly/plant_unit_to_idnum_crosswalk23.dta"

keep btildaFMPP idnum ID
sort btildaFMPP 

use "data/weather/East_balance_17_weatherized", clear
*keep if strpos(ID,"nuke")
keep if inter=="East"
corr netgen demandFMPP if ID=="PJM_All_nuke"
corr netgen demandFMPP if ID=="SE_Resid_coal"
corr netgen demandFMPP if ID=="MIDW_Resid_gas"

reg netgen demandFMPP if ID=="PJM_All_nuke"
reg netgen demandFMPP if ID=="SE_Resid_coal"

