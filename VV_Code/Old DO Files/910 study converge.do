

/*
global EastBaCodesfinal demandAEC demandAECI demandCPLE demandCPLW demandDUK demandFMPP demandFPC demandFPL demandGVL demandHST demandISNE demandJEA demandLGEE demandMISO demandNSB demandNYIS demandPJM  demandSC demandSCEG demandSEC demandSOCO demandSPA demandSWPP demandTAL demandTEC demandTVA

global WestBaCodesfinal  demandAVA demandAZPS demandBANC  demandBPAT demandCHPD demandCISO demandDOPD demandEPE demandGCPD demandIID demandIPCO demandLDWP demandNEVP demandNWMT demandPACE demandPACW demandPGE demandPNM demandPSCO demandPSEI demandSCL demandSRP demandTEPC demandTIDC demandTPWR demandWACM      demandWALC demandWAUW
*/

foreach num in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 21 22 23 24{
*foreach num in 1 6{
use "data/hourly22/converge500sub`num.dta'", clear
gen t = _n 
rename A A`num'
if `num' > 1 merge 1:1 t using $temp1, nogen keep(3)
save "$temp1", replace
}

*use "data/weather22/Texas_balance_23_weatherized.dta", clear
*use "data/weather22/West_balance_23_weatherized.dta", clear
*use "data/weather22/East_balance_23_weatherized.dta", clear

*COAS EAST FWES NCEN NRTH SCEN SOUT WEST

gen bacode = ""
replace bacode = "demandCOAS" in 1
replace bacode = "demandEAST" in 2
replace bacode = "demandFWES" in 3
replace bacode = "demandNCEN" in 4
replace bacode = "demandNRTH" in 5
replace bacode = "demandSCEN" in 6
replace bacode = "demandSOUT" in 7
replace bacode = "demandWEST" in 8




local ct = 9
foreach code in $WestSubCodes{
replace bacode ="`code'" in `ct'
local ct = `ct'+1
}

foreach code in $EastSubCodes{
replace bacode ="`code'" in `ct'
local ct = `ct'+1
}

afasdf





foreach num in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 21 22 23 24{
*foreach num in 1 2 3 4 5 6 7 8 9 10 11{
replace A`num'=0 if A`num'<100000
replace A`num'= A`num'/100000
}
gen totnotconv = A1+A2+A3+A4+A5+A6+A7+A8+A9+A10+A11+A12+A13+A14+A15+A16+A17+A18+A19+A20+A21+A22+A23+A24
keep bacode totnotconv
save $temp1, replace



use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(bacode, string)
keep if utchour==2
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

collapse (mean) d*

xpose, clear varname

rename _varname bacode
rename v1 meandemand
merge 1:1 bacode using $temp1, nogen keep(3)

scatter totnotconv meandemand
sort meandemand
dafasf



foreach num in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 21 23 24{
*foreach num in 1 2 3 4 5 6 7 8 9 10 11{
use "data/hourly22/convergeregion`num.dta'", clear
gen t = _n 
rename A A`num'
if `num' > 1 merge 1:1 t using $temp1, nogen keep(3)
save "$temp1", replace
}
