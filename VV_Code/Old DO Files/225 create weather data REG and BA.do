
*global AllRegions CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX

global monthlow= 6
global monthhigh= 9



global AllDemands demandCAL demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNW demandNY demandSE demandSW demandTEN demandTEX

global thehour= 23

global interstorun Texas West East


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

*** create weather for  East, West, Texas 

foreach inter in $interstorun  {

	display "working on inter `inter'"
	
	use $temp7 if utchour==$thehour, clear

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

	display "working on inter `inter'"
	
	use $temp7 if utchour==$thehour, clear

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

use $temp5, clear
merge 1:1 utcdate utchour using $temp6, nogen keep(3)
merge 1:1 utcdate utchour using $temp8, nogen keep(3)
gen year = year(utcdate)
*drop if year== 2022
save "data/weather_by_ba.dta", replace
