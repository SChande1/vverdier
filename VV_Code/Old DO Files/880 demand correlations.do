
* run globals_regular.do

*here we both deweatherize and deload, and then run a multivariate regression
* just deweatherize for wind and solar plants


*global levelstorun   sub balance region inter 
global levelstorun    region balance sub
global interstorun     Texas West East
*global interstorun   East

*only run summer months
global monthlow= 6
global monthhigh= 9



************************** loop over all hours
			   **************************


*foreach thehour in $hoursAll{
foreach thehour in   2 {
	
	
foreach level in $levelstorun {

foreach inter in $interstorun {	
	
	
* bring in demand data	

** slightly different procedures for inter, region, balance, and sub
if "`level'"=="sub"{
use "data/Hourly_Sub_Load22.dta", clear
keep  subregion demand utcdate utchour 
qui reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==`thehour'
qui save $temp1, replace

** bring in balance authority data, drop ISO demands
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(bacode, string)
keep if utchour==`thehour'
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
* drop ISO demand, replace with subregion demands
drop demandCISO demandISNE demandMISO demandNYIS demandPJM demandSWPP demandERCO
merge 1:1 utcdate utchour using $temp1, nogen keep(3)
** drop reco as no variation after a few months
drop demandRECO
if "`inter'"=="East" keep utcdate utchour $EastSubCodes
if "`inter'"=="West" keep utcdate utchour $WestSubCodes
if "`inter'"=="Texas" keep utcdate utchour $TexasSubCodes
*merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace
* end level = sub
}

if "`level'"=="balance"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(bacode, string)
keep if utchour==`thehour'
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
if "`inter'"=="East" keep utcdate utchour $EastBaCodesDr 
if "`inter'"=="West" keep utcdate utchour $WestBaCodesDr 
if "`inter'"=="Texas" keep utcdate utchour demandERCO
*merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace
}


if "`level'"== "region"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep region demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==`thehour'
if "`inter'"=="East" keep utcdate utchour demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN 
if "`inter'"=="West" keep utcdate utchour demandCAL demandSW demandNW
if "`inter'"=="Texas" keep utcdate utchour demandTEX
*merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace		
}

if "`level'"=="inter" {
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep region demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==`thehour'
gen demandWest= demandCAL + demandSW + demandNW
gen demandTexas = demandTEX
gen demandEast = demandCAR + demandCENT + demandFLA + demandMIDA + demandMIDW + demandNE + demandNY + demandSE + demandTEN
if "`inter'"=="East" keep utcdate utchour demandEast 
if "`inter'"=="West" keep utcdate utchour demandWest
if "`inter'"=="Texas" keep utcdate utchour demandTexas
*merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace	
}

if "`level'"=="sub" & "`inter'"=="East" global regions  $EastSubCodes
if "`level'"=="sub" & "`inter'"=="West" global regions  $WestSubCodes
if "`level'"=="sub" & "`inter'"=="Texas" global regions  $TexasSubCodes
if "`level'"=="balance" & "`inter'"=="East" global regions  $EastBaCodesDr 
if "`level'"=="balance" & "`inter'"=="West" global regions  $WestBaCodesDr 
if "`level'"=="balance" & "`inter'"=="Texas" global regions  demandERCO
if "`level'"=="region" & "`inter'"=="East" global regions  demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN
if "`level'"=="region" & "`inter'"=="West" global regions  demandCAL demandSW demandNW
if "`level'"=="region" & "`inter'"=="Texas" global regions  demandTEX
if "`level'"=="inter" & "`inter'"=="East" global regions  demandEast
if "`level'"=="inter" & "`inter'"=="West" global regions  demandWest 
if "`level'"=="inter" & "`inter'"=="Texas" global regions  demandTexas

qui gen month = month(utcdate)
qui keep if month >=$monthlow & month <=$monthhigh

dis "hour `thehour' inter `inter' level `level'"
corr $regions

} //end interconnection loop



} //end levels loop


} //end hours loop

