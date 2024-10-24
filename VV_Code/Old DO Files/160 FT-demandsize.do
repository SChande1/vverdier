

use "data/Hourly_Sub_Load22.dta", clear
keep  subregion demand utcdate utchour 
qui reshape wide demand, i(utcdate utchour) j(subregion, string)
*keep if utchour==`thehour'
qui save $temp1, replace

** bring in balance authority data, drop ISO demands
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(bacode, string)
*keep if utchour==`thehour'
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

collapse (mean) demand*
xpose, clear varname

rename _varname sub
replace sub=subinstr(sub,"demand","",.)
rename v1 demand
save $temp3, replace




use "$raw/Maps/US_County_LowRes_2013data_Stata11.dta", clear
drop if inlist(statefp,2,15) | statefp>56
gen fips = statefp*1000+countyfp
keep _ID fips
merge 1:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen 
rename subBA sub
merge m:1 sub using $temp3

kdensity demand
histogram demand, percent title("Ba Subregions") xtitle("Average Demand")

spmap demand using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", id(_ID) osize(none ..) ndsize(none ..) fcolor(red*2 red*1 red*0.5 red*0.25 green blue*0.15 blue*0.25 blue*0.35 blue*0.45 blue*0.55 blue*0.65 blue*0.75 blue ) clmethod(custom) clbreaks(50 150 200 400 1000 1500 2000 5000 10000 15000 20000 25000 30000) legend(on) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) 

