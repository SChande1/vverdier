
* run globals_regular.do

*here we both deweatherize and deload, and then run a multivariate regression
* just deweatherize for wind and solar plants

global levelstorun    sub balance region inter 
*global levelstorun    sub

global interstorun    Texas West East
*global interstorun    Texas 

*only run summer months
global monthlow= 6
global monthhigh= 9

global runhours $hoursAll
*global runhours 9 

global runweather 1

*global runpython 0
*global runOLS 1 


if $runweather {
	
**************************** create weather data


* raw weather data from open meteo
use "data/open meteo.dta", clear
gen month = month(utcdate)
keep if month >=$monthlow & month <=$monthhigh

keep fips utcdate utchour wnd ghi
merge m:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen keep(3) 
merge m:1 fips using "data/fips_pop2015.dta" , nogen keep(3)
merge m:1 fips using "data/fips_to_county_names.dta", nogen keep(3)
merge m:1 fips using "data/county solar wind capacity.dta", nogen keep(1 3)
recode solarmw .=0
recode windmw .=0
drop reg_egrid bal_egrid statename name
save $temp7, replace
}

************************** loop over all hours
			   **************************

foreach thehour in $runhours {
	dis "hour `thehour'"
* pull one hour of generation data
use "data/hourly22/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
qui gen inter = "East"
qui replace inter="West" if inlist(region,"CAL","NW","SW")
qui replace inter="Texas" if region=="TEX"
qui save $temp2, replace

* set up fixed effects by yr, month, day of week, hour
use $temp2, clear
gen month = month(utcdate)
gen yr = year(utcdate)
gen moyr = yr*100+month
gen dow = dow(utcdate)
qui capture drop group
*from import_ERCOT_data.do line 219
egen group = group(yr month dow utchour)

**** just do  summer  months
qui keep if month >=$monthlow & month <=$monthhigh

* find number of units
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units " $numunits
qui drop  tmax
qui save $temp3, replace




*** create weather for  East, West, Texas 

foreach inter in   $interstorun  {

	*display "working on inter `inter'"
	
	use $temp7 if utchour==`thehour', clear

if "`inter'"=="East"{
	qui keep if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") 
* we weight by county capacity of wind or solar, respectively, for wind speed and ghi. If a market does not have any capacity, we just use population weights like before
	egen Awnd = sum(wnd * windmw), by(balancingauthoritycode utcdate utchour)
	egen denom1 = sum(windmw), by(balancingauthoritycode utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(balancingauthoritycode utcdate utchour)
	egen denom2 = sum(pop), by(balancingauthoritycode utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(balancingauthoritycode utcdate utchour)
	egen denom3 = sum(solarmw), by(balancingauthoritycode utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(balancingauthoritycode utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(balancingauthoritycode utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide  wnd ghi, i(utcdate utchour) j(balancingauthoritycode) string
qui save $temp5, replace
}

if "`inter'"=="West"{
	qui keep if (region=="CAL" | region=="NW" | region=="SW" ) 	
	egen Awnd = sum(wnd * windmw), by(balancingauthoritycode utcdate utchour)
	egen denom1 = sum(windmw), by(balancingauthoritycode utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(balancingauthoritycode utcdate utchour)
	egen denom2 = sum(pop), by(balancingauthoritycode utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(balancingauthoritycode utcdate utchour)
	egen denom3 = sum(solarmw), by(balancingauthoritycode utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(balancingauthoritycode utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(balancingauthoritycode utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide  wnd ghi, i(utcdate utchour) j(balancingauthoritycode) string
qui save $temp6, replace
}

if "`inter'"=="Texas"{
	qui keep if region=="TEX" 
	egen Awnd = sum(wnd * windmw), by(balancingauthoritycode utcdate utchour)
	egen denom1 = sum(windmw), by(balancingauthoritycode utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(balancingauthoritycode utcdate utchour)
	egen denom2 = sum(pop), by(balancingauthoritycode utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(balancingauthoritycode utcdate utchour)
	egen denom3 = sum(solarmw), by(balancingauthoritycode utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(balancingauthoritycode utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(balancingauthoritycode utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide wnd ghi, i(utcdate utchour) j(balancingauthoritycode) string
qui save $temp8, replace
}

* note east, west , texas temp 5 6 8



} // end inter loop


*** create weather for generation only balancing authorities: AVRN (NW), DEAA(SW), EEI (MIDW), GLHB (MIDW), GRID (NW), GRIF(SW), GWA(NW), HGMA(SW), SEPA(SE), WWA (NW), YAD(CAR)
*** also, HST(FLA) is limited generation
*** finally NSB (FLA) SPA (CENT) WALC (SW) WAUW (NW) are missing from "fips_to_region_crosswalk.dta". Need to go back to long run to figure out why
*** for now, collapse weather to region level for these
*** region comes from  from "EIA930 Reference Tables.xlsx"


foreach inter in   $interstorun  {

	*display "working on inter `inter'"
	
	use $temp7 if utchour==`thehour', clear

if "`inter'"=="East"{
	qui keep if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") 
	egen Awnd = sum(wnd * windmw), by(region utcdate utchour)
	egen denom1 = sum(windmw), by(region utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(region utcdate utchour)
	egen denom2 = sum(pop), by(region utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(region utcdate utchour)
	egen denom3 = sum(solarmw), by(region utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(region utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(region utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide  wnd ghi, i(utcdate utchour) j(region) string
qui merge 1:1 utcdate utchour using $temp5, nogen keep(3)
gen wndSEPA = wndSE
gen ghiSEPA = ghiSE
gen wndYAD = wndCAR
gen ghiYAD = ghiCAR
gen wndEEI = wndMIDW
gen ghiEEI = ghiMIDW
gen wndGLHB = wndMIDW
gen ghiGLHB = ghiMIDW
gen wndHST = wndFLA
gen ghiHST = ghiFLA
gen wndNSB = wndFLA
gen ghiNSB = ghiFLA
gen wndSPA = wndCENT
gen ghiSPA = ghiCENT
qui save $temp5, replace
}

if "`inter'"=="West"{
	qui keep if (region=="CAL" | region=="NW" | region=="SW" ) 	
	egen Awnd = sum(wnd * windmw), by(region utcdate utchour)
	egen denom1 = sum(windmw), by(region utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(region utcdate utchour)
	egen denom2 = sum(pop), by(region utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(region utcdate utchour)
	egen denom3 = sum(solarmw), by(region utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(region utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(region utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide  wnd ghi, i(utcdate utchour) j(region) string
qui merge 1:1 utcdate utchour using $temp6, nogen keep(3)
gen wndAVRN = wndNW
gen ghiAVRN = ghiNW
gen wndDEAA = wndSW
gen ghiDEAA = ghiSW
gen wndGRID = wndNW
gen ghiGRID = ghiNW
gen wndGRIF = wndSW
gen ghiGRIF = ghiSW
gen wndGWA = wndNW
gen ghiGWA = ghiNW
gen wndHGMA = wndSW
gen ghiHGMA = ghiSW
gen wndWWA = wndNW
gen ghiWWA = ghiNW
gen wndWALC = wndSW
gen ghiWALC = ghiSW
gen wndWAUW = wndNW
gen ghiWAUW = ghiNW

qui save $temp6, replace
}

if "`inter'"=="Texas"{
	qui keep if region=="TEX" 
	egen Awnd = sum(wnd * windmw), by(region utcdate utchour)
	egen denom1 = sum(windmw), by(region utcdate utchour)
	egen Awnd2 = sum(wnd * pop), by(region utcdate utchour)
	egen denom2 = sum(pop), by(region utcdate utchour)
	egen Aghi = sum(ghi * solarmw), by(region utcdate utchour)
	egen denom3 = sum(solarmw), by(region utcdate utchour)
	egen Aghi2 = sum(ghi * pop), by(region utcdate utchour)
	qui replace Awnd = Awnd / denom1 if denom1>0
	qui replace Awnd = Awnd2 / denom2 if denom1==0
	qui replace Aghi = Aghi / denom3 if denom3>0
	qui replace Aghi = Aghi2 / denom2 if denom3==0
	collapse (mean)  Awnd Aghi, by(region utcdate utchour)
	rename Awnd wnd
	rename Aghi ghi
	qui reshape wide wnd ghi, i(utcdate utchour) j(region) string
qui merge 1:1 utcdate utchour using $temp8, nogen keep(3)
qui save $temp8, replace
}

* note east, west , texas temp 5 6 8

} // end inter loop


foreach level in $levelstorun {

foreach inter in $interstorun {

* bring in all units in the interconnection
if "`inter'"=="East"{
	use if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") using $temp3, clear
}
if "`inter'"=="West"{
	use if (region=="CAL" | region=="NW" | region=="SW" ) using $temp3, clear
}
if "`inter'"=="Texas"{
	use if region=="TEX"  using $temp3, clear
}	

* calculate number of units
* creat new id for loop 
qui egen newid=group(idnum)
qui egen tmax=max(newid)
local ttmax=tmax[1]	


if "`inter'"=="East"{
	qui merge m:1 utcdate utchour using $temp5, nogen keep(3)
}
if "`inter'"=="West"{
	qui merge m:1 utcdate utchour using $temp6, nogen keep(3)
}
if "`inter'"=="Texas"{
	qui merge m:1 utcdate utchour using $temp8, nogen keep(3)
}	
	
local ttmax=tmax[1]
qui levelsof newid, local(countit)	

qui save $temp10, replace

* bring in demand data	

** slightly different procedures for inter, region, balance, and sub
if "`level'"=="sub"{
use "data/Hourly_Sub_Load22.dta", clear
qui keep  subregion demand utcdate utchour 
qui reshape wide demand, i(utcdate utchour) j(subregion, string)
qui keep if utchour==`thehour'
qui save $temp1, replace

** bring in balance authority data, drop ISO demands
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
qui drop if bacode==""
qui keep bacode demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(bacode, string)
qui keep if utchour==`thehour'
* drop BA's with no data (generation only ba's: see EIA_REference_Tables.xlsx column F)
qui drop demandAVRN
qui drop demandDEAA
qui drop demandEEI
qui drop demandGLHB
qui drop demandGRID
qui drop demandGRIF
*note GRMA was retired in 2018
qui drop demandGWA
qui drop demandHGMA
qui drop demandSEPA
qui drop demandWWA
qui drop demandYAD
**missing data causes a problem in the areg below because one of the RHS variables (demandXXX) could be all missing
** nsb retired in 1/8/2020
qui replace demandNSB=0 if demandNSB==.
** aec retired in 9/1/2021
qui replace demandAEC=0 if demandAEC==.
qui replace demandPSEI=0 if demandPSEI==.
qui replace demandSEC=0 if demandSEC==.
* drop ISO demand, replace with subregion demands
qui drop demandCISO demandISNE demandMISO demandNYIS demandPJM demandSWPP demandERCO
qui merge 1:1 utcdate utchour using $temp1, nogen keep(3)
** drop reco as no variation after a few months
qui drop demandRECO
qui if "`inter'"=="East" keep utcdate utchour $EastSubCodes
qui if "`inter'"=="West" keep utcdate utchour $WestSubCodes
qui if "`inter'"=="Texas" keep utcdate utchour $TexasSubCodes
qui merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace
* end level = sub
}

if "`level'"=="balance"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
qui drop if bacode==""
qui keep bacode demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(bacode, string)
qui keep if utchour==`thehour'
* drop BA's with no data (generation only ba's: see EIA_REference_Tables.xlsx column F)
qui drop demandAVRN
qui drop demandDEAA
qui drop demandEEI
qui drop demandGLHB
qui drop demandGRID
qui drop demandGRIF
*note GRMA was retired in 2018
qui drop demandGWA
qui drop demandHGMA
qui drop demandSEPA
qui drop demandWWA
qui drop demandYAD
**missing data causes a problem in the areg below because one of the RHS variables (demandXXX) could be all missing
** nsb retired in 1/8/2020
qui replace demandNSB=0 if demandNSB==.
** aec retired in 9/1/2021
qui replace demandAEC=0 if demandAEC==.
qui replace demandPSEI=0 if demandPSEI==.
qui replace demandSEC=0 if demandSEC==.
qui if "`inter'"=="East" keep utcdate utchour $EastBaCodesDr 
qui if "`inter'"=="West" keep utcdate utchour $WestBaCodesDr 
qui if "`inter'"=="Texas" keep utcdate utchour demandERCO
qui merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace
}


if "`level'"== "region"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation22.dta", clear
qui keep region demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(region, string)
qui keep if utchour==`thehour'
qui if "`inter'"=="East" keep utcdate utchour demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN 
qui if "`inter'"=="West" keep utcdate utchour demandCAL demandSW demandNW
qui if "`inter'"=="Texas" keep utcdate utchour demandTEX
qui merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace		
}

if "`level'"=="inter" {
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation22.dta", clear
qui keep region demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(region, string)
qui keep if utchour==`thehour'
qui gen demandWest= demandCAL + demandSW + demandNW
qui gen demandTexas = demandTEX
qui gen demandEast = demandCAR + demandCENT + demandFLA + demandMIDA + demandMIDW + demandNE + demandNY + demandSE + demandTEN
qui if "`inter'"=="East" keep utcdate utchour demandEast 
qui if "`inter'"=="West" keep utcdate utchour demandWest
qui if "`inter'"=="Texas" keep utcdate utchour demandTexas
qui merge 1:m utcdate utchour using $temp10, nogen keep(3)
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

qui clear

qui save "$tempdir/tempcoef`inter'.dta", replace emptyok


dis "working on `ttmax' plants in the `inter' interconnection"


* loop through all units in the interconnection


forvalue j= 1/`ttmax'{
	if `j'==100 dis "plant `j'"
	if `j'==200 dis "plant `j'"
	if `j'==500 dis "plant `j'"
	if `j'==1000 dis "plant `j'"
	if `j'==2000 dis "plant `j'"
	
	qui use if newid==`j' using $temp11, clear
	
	
	foreach region in $regions {
	

		* simple univariate regression; retain OLS coefficient
		qui reg netgen `region'
		qui for var `region': gen bnetgenX=_b[X]
		
	} // end region loop
		
		qui keep if _n < 2
		qui keep ID inter region b* idnum
		if `j' == 1  {
			qui save "$tempdir/OLScoef`inter'.dta", replace
		}
		else {
			append using "$tempdir/OLScoef`inter'.dta"
			qui save "$tempdir/OLScoef`inter'.dta", replace
		}

} //end j loop


} //end interconnection loop


use $tempdir/OLScoefTexas, clear
sort idnum
save $tempdir/OLScoefTexas, replace

use $tempdir/OLScoefWest, clear
sort idnum
save $tempdir/OLScoefWest, replace

use $tempdir/OLScoefEast, clear
sort idnum
save $tempdir/OLScoefEast, replace

use $tempdir/OLScoefTexas, clear
qui append using $tempdir/OLScoefWest
qui append using $tempdir/OLScoefEast


* save file with coefficients for each hour and level
save "data/hourly22/coefs_uni_`level'`thehour'.dta", replace


} //end levels loop


} //end hours loop

