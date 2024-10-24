
* run globals_regular.do

* v2 calculates specification alternatives controls/nocontrols  and fixed effects A/B

*global levelstorun    sub balance region inter 
global levelstorun    region

global interstorun    Texas West East
*global interstorun    West

*only run summer months
*global monthlow= 6
*global monthhigh= 9

global runhours $hoursAll
*global runhours 1 



global runpython 1
global runOLS 0

  
* code frmo save_plant_fuel.do
		   
** make a single fuel for each unit		   
use "$regloc/data/cems_units_fuel_19-22.dta", clear
drop yr
duplicates drop
* plants with num >1 switched fuel
bysort PLANT unitid: egen num=count(Fuel)
* almost all switched to gas
replace Fuel="Gas" if num==2
drop Source
duplicates drop

duplicates report PLANT unitid 

save "data/cems_units_single_fuel.dta", replace
		   
			   

			   
************************** loop over all hours, summer and winter
			   **************************

foreach season in summer winter {	   
	
if "`season'"=="summer"{
	use "$regloc/data/open meteo_summer.dta"
	save $temp7, replace
}	
if "`season'"=="winter"{
	use "$regloc/data/open meteo_winter.dta"
	save $temp7, replace
}	
		

foreach fixed in yxw yxmxd {
foreach control in weather none {	 		
		
foreach thehour in $runhours {
	dis "hour `thehour'"
	dis "fixed " "`fixed'"
	dis "control " "`control'"

*code from create_data_1.do

	
use "data/hourly22/`season'/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear


drop _merge
merge m:1 PLANT unitid using "data/cems_units_single_fuel", keep(1 3)


*Drop residuals
*drop if strpos(ID,"Resid")>0

*Missing from CEMS is zero generation
replace netgen = 0 if netgen==.

sort ID utcdate utchour

drop aggnetgen

capture drop composite
gen composite = 1 if strpos(ID,"All")>0 | strpos(ID,"Trade")>0 | strpos(ID,"Resid")>0
replace composite = 0 if composite == .
***** create plant by fuel aggregate (aggregate over unitid)
gen nmissing = 1 if netgen!=.
egen nmissing_plant = sum(nmissing) if !composite, by(PLANT Fuel utcdate utchour)
egen netgen_plant = sum(netgen) if !composite, by(PLANT Fuel utcdate utchour)
replace netgen_plant = . if !composite&nmissing_plant==0
sort utcdate utchour PLANT Fuel unitid 
capture drop temp
gen temp = 1
replace temp = temp[_n-1]+1 if  _n>1 & PLANT==PLANT[_n-1] & Fuel==Fuel[_n-1] & !composite


***** drop number 1
drop if temp>1&!composite

replace netgen_plant = netgen if composite

drop netgen
rename netgen_plant netgen
drop nmissing_plant
drop nmissing
drop temp
	
	
* temp fix	
*drop if idnum == 3912
*drop if idnum == 1000
	
* original code started here
	
* pull one hour of generation data
*use "$regloc/data/hourly22/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
*sort ID utcdate utchour
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


if "`fixed'"== "yxw"{
capture drop week
epiweek utcdate, epiw(week) epiy(yr2)
replace week = week-1 if dow==0
drop yr2
egen group = group(yr week)
}
if "`fixed'"=="yxmxd"{
egen group = group(yr month dow)
}


if "`season'"=="summer" {
	qui keep if inlist(month,5,6,7,8,9,10)
}
if "`season'"=="winter" {
	qui keep if inlist(month,1,2,3,4,11,12)
}
*qui keep if month >=$monthlow & month <=$monthhigh

*** drop data anomiles
drop _merge
merge m:1 region utcdate utchour using "data/flag_eia930.dta", keep(3) nogen
drop if flag_netgen|flag_demand



* find number of units
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units (before dropping those with less than 100 obs)" $numunits
qui drop  tmax
qui save $temp3, replace
qui save "data/hourly22/`season'/plant_info_hour`thehour'_`control'_`fixed'.dta", replace





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





if "`inter'"=="East"{
	qui merge m:1 utcdate utchour using $temp5, nogen keep(3)
}
if "`inter'"=="West"{
	qui merge m:1 utcdate utchour using $temp6, nogen keep(3)
}
if "`inter'"=="Texas"{
	qui merge m:1 utcdate utchour using $temp8, nogen keep(3)
}	
	
*local ttmax=tmax[1]
*qui levelsof newid, local(countit)	

qui save $temp10, replace

* bring in demand data	

** slightly different procedures for inter, region, balance, and sub
if "`level'"=="sub"{
use "$regloc/data/Hourly_Sub_Load22.dta", clear
qui keep  subregion demand utcdate utchour 
qui reshape wide demand, i(utcdate utchour) j(subregion, string)
qui keep if utchour==`thehour'
qui save $temp1, replace

** bring in balance authority data, drop ISO demands
use "$regloc/data/Hourly_Balancing_Load22.dta", clear
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
use "$regloc/data/Hourly_Balancing_Load22.dta", clear
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
use "$regloc/data/Hourly_Regional_Load_Generation22.dta", clear
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
use "$regloc/data/Hourly_Regional_Load_Generation22.dta", clear
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



use $temp11, clear

* drop units with little data
* so need to set up inference stuff because want enough for both sub-samples
*save indicator for groups for inference
			set seed 339487731
			
			
			if "`fixed'"== "yxw"{
			egen group3 = group(yr week)
			}
			if "`fixed'"=="yxmxd"{
			egen group3 = group(yr month dow)
			}
			sort group3
			capture drop temp
			gen temp = runiform() if _n==1 | (group3!=group3[_n-1]&_n>1)
			replace temp = temp[_n-1] if _n>1 & group3==group3[_n-1]&_n>1
			gen sample_index = 1 if temp<=.5
			replace sample_index = 2 if temp>.5
			
			*Only keep plants with at least 100 observations in both sub-samples
			capture drop temp
			gen temp = (netgen!=.) if sample_index==1
			egen n_nonmissing1 = sum(temp), by(idnum)
			capture drop temp
			gen temp = (netgen!=.) if sample_index==2
			egen n_nonmissing2 = sum(temp), by(idnum)
			tab idnum if n_nonmissing1<100|n_nonmissing2<100
			local temp = r(r)
			
			di "Dropping `temp' plants because not enough observations"
			****** drop number 2 
			
			drop if n_nonmissing1<100|n_nonmissing2<100

* calculate number of units
* creat new id for loop 
qui egen newid=group(idnum)
qui egen tmax=max(newid)
local ttmax=tmax[1]	
qui levelsof newid, local(countit)	


save $temp11, replace


*dis "working on `countit' (or `ttmax') plants in the `inter' interconnection"

dis "working on `ttmax' plants in the `inter' interconnection"



local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "Running OLS and/or creating matrices for python"
forvalue j= 1/`ttmax'{
	 
	 qui use if newid==`j' using $temp11, clear
	 if `j'==100 dis "     plant `j'"
	 if `j'==200 dis "     plant `j'"
	 if `j'==500 dis "     plant `j'"
	 if `j'==1000 dis "     plant `j'"
	 if `j'==2000 dis "     plant `j'"
	 *gen windORsun=0
	 *qui replace windORsun = 1 if strpos(ID,"sun") | strpos(ID,"wind")
	
***** have some netgens==0 now. not sure why, need to fixe this???
	 
	** set up RHS variables according to interconnection
	
	*** drop if all observations are all zero
	
	qui su netgen
	local Np = r(N)
	local mean = r(mean)
	
	* this drops some trade and residual variables...
	*old version: if `Np'> 50 & `mean' >0 { this was a mistake because it dropped trade, for example
	if  `mean' != 0 {
	
	
	if _N >0 {
		
		/*
		qui gen constant = 1
		if windORsun[1] == 1{
		local curbacode = bacode[1]
		local varstouse netgen $regions constant i.group wnd`curbacode' ghi`curbacode'
		}
		if windORsun[1] == 0{
		local varstouse netgen $regions constant i.group 
		}
		*/
		
		* some plants are defined at regional level (residual coal, trade and so on)
		
		qui gen constant= 1
		
		if bacode[1]== "" {
			local curbacode = region[1]
		}
		else {
			local curbacode = bacode[1]
		}

		qui save $temp4, replace
* OLS	
		if $runOLS ==1 {
		*qui reg netgen $regions i.group wnd`curbacode' ghi`curbacode'
		qui reghdfe netgen $regions wnd`curbacode' ghi`curbacode', absorb(group)
		qui for var $regions: gen bnetgenX=_b[X]
		qui for var $regions: gen senetgenX=_se[X]
		qui keep ID region b* se* idnum
		qui save $temp9, replace
		qui keep ID region b* idnum
		qui duplicates drop
		if `j' > 1 append using "$tempdir/OLScoef`inter'.dta"
		sort idnum
		qui save "$tempdir/OLScoef`inter'.dta", replace
		qui use $temp9, clear
		qui keep ID region se* idnum
		qui duplicates drop
		if `j' > 1 append using "$tempdir/OLSse`inter'.dta"
		sort idnum
		qui save "$tempdir/OLSse`inter'.dta", replace
		} // end if runOLS
* Regularized

		if $runpython==1{

		qui use $temp4, clear
	
		if "`control'"=="weather" {
		local varstouse netgen $regions constant i.group wnd`curbacode' ghi`curbacode'
		}
		if "`control'"=="none" {
		local varstouse netgen $regions constant i.group 
		}
		
		
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		local numreg: word count $regions
		local endreg = `numreg'+1
		local startweather=`endreg'+1
		local numcol=`=colsof(data)'
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2..`endreg']
		matrix w = data[1...,`startweather'..`numcol']
		* these are very slow
		*matselrc data y, c(1)
		*matselrc data x, c(2/`endreg')
		*matselrc data w, c(`startweather'/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[idnum[1]]
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[idnum[1]]
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
	* end if runpython
	}
	* end if N
	}
	* end if mean !=0
	}
	
	
	
}
dis "total plants processed for python " `cot'

if $runpython ==1 {

* dump big column matrices into excel files to transfer to python
* also transfer list of unit numbers
*A1 is cell number

** XX matrix is stored as a stata dta file
use "$tempdir/bigmattemp.dta"
qui export excel "../python/XX.xlsx", nolabel replace
** yX and unitnums are stored as matrices
qui putexcel set "../python/yX.xlsx", replace
qui putexcel A1=matrix(TEX_yX)
qui putexcel set "../python/unitnums.xlsx", replace
qui putexcel A1=matrix(unitnums)





**** call python to do constrained regression
dis "call python"
qui cd "../python"

** version 3 uses sparse matrices to save memory and relaxes the convergence criteria from 1e-12 to 1e-9
** version 4 uses upper diagonal sparse matrix for P (which is all OSPQ needs). THis saves memory for the "Sub" case
python script "regular_v4.py"
qui cd "../stata"

* import coefficients from python output
qui import   excel using "../python/temp_output.xlsx",  clear firstr 

* number of coefficinets depends on level: sub balance, region, or interconnection

if "`level'" == "sub"{

*global TexasSubCodes demandCOAS demandEAST demandFWES demandNCEN demandNRTH demandSCEN demandSOUT demandWEST
	
if "`inter'" =="Texas"{
	qui rename  A idnum
	qui rename  B btildaCOAS
	qui rename  C btildaEAST
	qui rename  D btildaFWES
	qui rename  E btildaNCEN
	qui rename  F btildaNRTH
	qui rename  G btildaSCEN
	qui rename  H btildaSOUT
	qui rename  I btildaWEST
}

*global WestSubCodes demandWAUW  demandDOPD demandBANC demandBPAT demandNWMT demandPNM demandPACW  demandSCL demandIID demandIPCO demandWALC  demandGCPD demandPGE demandPSEI demandTIDC demandNEVP  demandEPE demandAVA demandLDWP  demandSRP demandWACM demandTEPC demandCHPD demandPSCO demandAZPS demandTPWR demandPACE demandPGAE demandSCE demandSDGE demandVEA

if  "`inter'"== "West" {
	
	qui rename A idnum
	qui rename B btildaWAUW  
	qui rename C btildaDOPD
	qui rename D btildaBANC
	qui rename E btildaBPAT
	qui rename F btildaNWMT
	qui rename G btildaPNM
	qui rename H btildaPACW 
	qui rename I btildaSCL
	qui rename J btildaIID
	qui rename K btildaIPCO
	qui rename L btildaWALC
	qui rename M btildaGCPD
	qui rename N btildaPGE
	qui rename O btildaPSEI
	qui rename P btildaTIDC
	qui rename Q btildaNEVP
	qui rename R btildaEPE
	qui rename S btildaAVA
	qui rename T btildaLDWP 
	qui rename U btildaSRP
	qui rename V btildaWACM
	qui rename W btildaTEPC
	qui rename X btildaCHPD
	qui rename Y btildaPSCO
	qui rename Z btildaAZPS
	qui rename AA btildaTPWR
	qui rename AB btildaPACE
	qui rename AC btildaPGAE
	qui rename AD btildaSCE
	qui rename AE btildaSDGE
	qui rename AF btildaVEA

			}

*global EastSubCodes demandAEC demandCPLW demandSOCO  demandSC  demandFPC demandSEC demandFPL demandFMPP  demandNSB  demandDUK demandSCEG demandHST  demandAECI   demandTAL demandLGEE demandGVL demandCPLE demandTEC demandSPA demandTVA demandJEA demand4001 demand4002 demand4003 demand4004 demand4005 demand4006 demand4007 demand4008 demand1 demand27 demand35 demand4 demand6 demand8910 demandZONA demandZONB demandZONC demandZOND demandZONE demandZONF demandZONG demandZONH demandZONI demandZONJ demandZONK demandAE demandAEP demandAP demandATSI demandBC demandCE demandDAY demandDEOK demandDOM demandDPL demandDUQ demandEKPC demandJC demandME demandPE demandPEP demandPL demandPN demandPS demandRECO demandCSWS demandEDE demandGRDA demandINDN demandKACY demandKCPL demandLES demandMPS demandNPPD demandOKGE demandOPPD demandSECI demandSPRM demandSPS demandWAUE demandWFEC demandWR
		
if "`inter'"=="East"{
	qui rename A idnum
	qui rename B btildaAEC 
	qui rename C btildaCPLW
	qui rename D btildaSOCO
	qui rename E btildaSC
	qui rename F btildaFPC
	qui rename G btildaSEC
	qui rename H btildaFPL
	qui rename I btildaFMPP
	qui rename J btildaNSB
	qui rename K btildaDUK
	qui rename L btildaSCEG
	qui rename M btildaHST
	qui rename N btildaAECI
	qui rename O btildaTAL 
	qui rename P btildaLGEE
	qui rename Q btildaGVL
	qui rename R btildaCPLE
	qui rename S btildaTEC
	qui rename T btildaSPA
	qui rename U btildaTVA
	qui rename V btildaJEA
	qui rename W btilda4001
	qui rename X btilda4002
	qui rename Y btilda4003
	qui rename Z btilda4004
	
	qui rename AA btilda4005
	qui rename AB btilda4006
	qui rename AC btilda4007
	qui rename AD btilda4008
	qui rename AE btilda1
	qui rename AF btilda27
	qui rename AG btilda35
	qui rename AH btilda4
	qui rename AI btilda6
	qui rename AJ btilda8910
	qui rename AK btildaZONA
	qui rename AL btildaZONB
	qui rename AM btildaZONC
	qui rename AN btildaZOND
	qui rename AO btildaZONE
	qui rename AP btildaZONF
	qui rename AQ btildaZONG
	qui rename AR btildaZONH
	qui rename AS btildaZONI
	qui rename AT btildaZONJ
	qui rename AU btildaZONK
	qui rename AV btildaAE
	qui rename AW btildaAEP
	qui rename AX btildaAP
	qui rename AY btildaATSI
	qui rename AZ btildaBC
* dropped RECO because no variation in demand (was between PS and CSWS)
	qui rename BA btildaCE
	qui rename BB btildaDAY
	qui rename BC btildaDEOK
	qui rename BD btildaDOM
	qui rename BE btildaDPL
	qui rename BF btildaDUQ
	qui rename BG btildaEKPC
	qui rename BH btildaJC
	qui rename BI btildaME
	qui rename BJ btildaPE
	qui rename BK btildaPEP
	qui rename BL btildaPL
	qui rename BM btildaPN
	qui rename BN btildaPS
	*qui rename BO btildaRECO
	qui rename BO btildaCSWS
	qui rename BP btildaEDE
	qui rename BQ btildaGRDA
	qui rename BR btildaINDN
	qui rename BS btildaKACY
	qui rename BT btildaKCPL
	qui rename BU btildaLES
	qui rename BV btildaMPS
	qui rename BW btildaNPPD
	qui rename BX btildaOKGE
	qui rename BY btildaOPPD
	
	qui rename BZ btildaSECI
	qui rename CA btildaSPRM
	qui rename CB btildaSPS
	qui rename CC btildaWAUE
	qui rename CD btildaWFEC
	qui rename CE btildaWR
	
	
			}
* end if level is sub
}




if "`level'" == "balance"{
	
if "`inter'" =="Texas"{
	qui rename  A idnum
	qui rename  B btildaERCO
}

* lists with some BA codes dropped due to no data
*global WestBaCodesDr demandWAUW  demandDOPD demandBANC demandBPAT demandNWMT demandPNM demandPACW  demandSCL demandIID demandIPCO demandWALC  demandGCPD demandPGE demandPSEI demandTIDC demandNEVP  demandEPE demandAVA demandLDWP  demandSRP demandWACM demandTEPC demandCISO  demandCHPD demandPSCO demandAZPS demandTPWR demandPACE 

if  "`inter'"== "West" {
	
	qui rename A idnum
	qui rename B btildaWAUW  
	qui rename C btildaDOPD
	qui rename D btildaBANC
	qui rename E btildaBPAT
	qui rename F btildaNWMT
	qui rename G btildaPNM
	qui rename H btildaPACW 
	qui rename I btildaSCL
	qui rename J btildaIID
	qui rename K btildaIPCO
	qui rename L btildaWALC
	qui rename M btildaGCPD
	qui rename N btildaPGE
	qui rename O btildaPSEI
	qui rename P btildaTIDC
	qui rename Q btildaNEVP
	qui rename R btildaEPE
	qui rename S btildaAVA
	qui rename T btildaLDWP 
	qui rename U btildaSRP
	qui rename V btildaWACM
	qui rename W btildaTEPC
	qui rename X btildaCISO
	qui rename Y btildaCHPD
	qui rename Z btildaPSCO
	qui rename AA btildaAZPS
	qui rename AB btildaTPWR
	qui rename AC btildaPACE

			}

*global EastBaCodesDr demandAEC demandCPLW demandSOCO  demandSC  demandMISO demandNYIS demandFPC demandSEC demandFPL demandFMPP  demandNSB demandISNE demandDUK demandSCEG demandHST demandPJM demandAECI  demandSWPP demandTAL demandLGEE demandGVL demandCPLE demandTEC demandSPA demandTVA demandJEA 
		
if "`inter'"=="East"{
	qui rename A idnum
	qui rename B btildaAEC 
	qui rename C btildaCPLW
	qui rename D btildaSOCO
	qui rename E btildaSC
	qui rename F btildaMISO
	qui rename G btildaNYIS
	qui rename H btildaFPC
	qui rename I btildaSEC
	qui rename J btildaFPL
	qui rename K btildaFMPP
	qui rename L btildaNSB
	qui rename M btildaISNE
	qui rename N btildaDUK
	qui rename O btildaSCEG
	qui rename P btildaHST
	qui rename Q btildaPJM
	qui rename R btildaAECI
	qui rename S btildaSWPP
	qui rename T btildaTAL 
	qui rename U btildaLGEE
	qui rename V btildaGVL
	qui rename W btildaCPLE
	qui rename X btildaTEC
	qui rename Y btildaSPA
	qui rename Z btildaTVA
	qui rename AA btildaJEA
	
			}
* end if level is balance
}
			
			
if "`level'" == "region"{			

if "`inter'" =="Texas"{
	qui rename  A idnum
	qui rename  B btildaTEX
}

* demandCAL demandSW demandNW

if  "`inter'"== "West" {
	qui rename A idnum
	qui rename B btildaCAL 
	qui rename C btildaSW 
	qui rename D btildaNW
			}
*demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN
if "`inter'"=="East"{
	qui rename A idnum
	qui rename B btildaCAR
	qui rename C btildaCENT
	qui rename D btildaFLA
	qui rename E btildaMIDA
	qui rename F btildaMIDW
	qui rename G btildaNE
	qui rename H btildaNY
	qui rename I btildaSE
	qui rename J btildaTEN
			}		
			
}			
			
if "`level'" == "inter"{
if "`inter'" =="Texas"{
	qui rename  A idnum
	qui rename  B btildaTexas
}

if  "`inter'"== "West" {
	qui rename A idnum
	qui rename B btildaWest 
	
			}

if "`inter'"=="East"{
	qui rename A idnum
	qui rename B btildaEast
			}
}		
					
qui save "$tempdir/coef`inter'.dta", replace

qui import excel using "../python/temp_converge.xlsx",  clear firstr 
qui gen inter = "`inter'"
qui save "$tempdir/converge`inter'.dta", replace

** need to match up lagrange multiplier to corresponding demand variable

qui import excel using "../python/temp_lm.xlsx",  clear firstr 
qui gen inter = "`inter'"
qui gen region = ""
local jcount=1
foreach regvar in $regions {
qui replace region="`regvar'" in `jcount'
local jcount = `jcount'+1
}

qui save "$tempdir/lm`inter'.dta", replace

} // end if runpython

} //end interconnection loop

if $runpython==1 {
* put coefficients from all three interconnections into a single file
use $tempdir/coefTexas, clear
qui append using $tempdir/coefWest
qui append using $tempdir/coefEast

* save file with coefficients for each hour and level
save "data/hourly22/`season'/coefsconstrained_`level'`thehour'_`control'_`fixed'.dta", replace

* put converge info from all three interconnections into a single file
use $tempdir/convergeTexas, clear
qui append using $tempdir/convergeWest
qui append using $tempdir/convergeEast

* save file with converge info for each hour and level
save "data/hourly22/`season'/converge_`level'`thehour'_`control'_`fixed'.dta", replace

* put lagrange multipliers from all three interconnections into a single file
use $tempdir/lmTexas, clear
qui append using $tempdir/lmWest
qui append using $tempdir/lmEast

* save file with lagrange multiplier for each hour and level
save "data/hourly22/`season'/LM_`level'`thehour'_`control'_`fixed'.dta", replace

} // end if runpython 

foreach inter in East West Texas{
	capture erase $tempdir/coef`inter'.dta
	capture erase $tempdir/converge`inter'.dta
	capture erase $tempdir/lm`inter'.dta
}


if $runOLS==1{
** clean up OLS
* put coefficients from all three interconnections into a single file
use $tempdir/OLScoefTexas, clear
qui append using $tempdir/OLScoefWest
qui append using $tempdir/OLScoefEast

* save file with coefficients for each hour and level
save "data/hourly22/coefs_`level'`thehour'_`control'_`fixed'.dta", replace


*put se from all three interconnections into a single files
use $tempdir/OLSseTexas, clear
qui append using $tempdir/OLSseWest
qui append using $tempdir/OLSseEast

* save file with coefficients for each hour and level
save "data/hourly22/se_`level'`thehour'_`control'_`fixed'.dta", replace

foreach inter in East West Texas{
	capture erase $tempdir/OLScoef`inter'.dta
	capture erase $tempdir/OLSse`inter'.dta
}

} // end if runOLS

} //end levels loop


} //end hours loop

} // end controls effects loop

} // end fixed effects loop

} // end season loop


