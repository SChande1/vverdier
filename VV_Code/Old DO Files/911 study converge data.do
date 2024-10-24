use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(bacode, string)
keep if utchour==10
* drop BA's with no data (generation only ba's: see EIA_REference_Tables.xlsx column F)
drop demandAVRN
drop demandDEAA
drop demandEEI
drop demandGLHB
drop demandGRID
drop demandGRIF
*note GRMA was retired in 2018
drop demandGWA
drop demandHGMA
drop demandSEPA
drop demandWWA
drop demandYAD
**missing data causes a problem in the areg below because one of the RHS variables (demandXXX) could be all missing
** nsb retired in 1/8/2020
replace demandNSB=0 if demandNSB==.
** aec retired in 9/1/2021
replace demandAEC=0 if demandAEC==.
replace demandPSEI=0 if demandPSEI==.
replace demandSEC=0 if demandSEC==.

save $temp1, replace

