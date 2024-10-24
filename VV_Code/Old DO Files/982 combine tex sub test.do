


*only run summer months
global monthlow= 6
global monthhigh= 9


* bring in texas sub region demand data	

use "data/Hourly_Sub_Load22.dta", clear
keep if inter=="Texas"
keep  subregion demand utcdate utchour 
reshape wide demand, i(utcdate utchour) j(subregion, string)
gen month = month(utcdate)

keep if month >=$monthlow & month <=$monthhigh


gen demandBWES = demandSOUT + demandFWES + demandWEST + demandNRTH
gen demandBSOU = demandSCEN + demandEAST

drop demandSOUT demandFWES demandWEST demandNRTH demandSCEN demandEAST

*collapse (sum) demand*, by(utchour)
*collapse (sum)  demand*



save "$tempdir/hourlycomsub.dta", replace



* run globals_regular.do

*here we both deweatherize and deload, and then run a multivariate regression
* just deweatherize for wind and solar plants



*global levelstorun   sub balance region inter 
global levelstorun    comsub 
global interstorun    Texas 
*global interstorun   East

*only run summer months
global monthlow= 6
global monthhigh= 9



if 0{
**************************** create weather data
* need population to aggregate up from county to level of analysis
import excel using  "../rawdata/epa/ozone-county-population.xlsx", firstrow clear
destring STATEFIPS COUNTYFIPS, replace
gen fips = STATEFIPS*1000+COUNTYFIPS
rename STATETERRITORYNAME statename
keep fips F statename
rename F pop
order fips pop statename
save "data/fips_pop2015.dta", replace

* raw weather data from open meteo
use "data/open meteo.dta", clear
gen month = month(utcdate)
keep if month >=$monthlow & month <=$monthhigh

keep fips utcdate utchour wnd ghi
merge m:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen keep(3) 
merge m:1 fips using "data/fips_pop2015.dta" , nogen keep(3)
merge m:1 fips using "data/fips_to_county_names.dta", nogen keep(3)
drop reg_egrid bal_egrid statename name
save $temp7, replace

}
************************** loop over all hours
			   **************************


foreach thehour in $hoursAll{
*foreach thehour in   9 {
	dis "hour"
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
capture drop group
*from import_ERCOT_data.do line 219
egen group = group(yr month dow utchour)

**** just do  summer  months
qui keep if month >=$monthlow & month <=$monthhigh

* find number of units
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units " $numunits
qui drop  tmax
qui save $temp3,replace




*** create weather for  East, West, Texas 

foreach inter in   $interstorun  {

	*display "working on inter `inter'"
	
	use $temp7 if utchour==`thehour', clear

if "`inter'"=="East"{
	qui keep if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") 

	collapse (mean)  wnd ghi [aweight=pop], by(balancingauthoritycode utcdate utchour)
	qui reshape wide  wnd ghi, i(utcdate utchour) j(balancingauthoritycode) string
qui save $temp5, replace
}

if "`inter'"=="West"{
	qui keep if (region=="CAL" | region=="NW" | region=="SW" ) 	

	collapse (mean)  wnd ghi [aweight=pop], by(balancingauthoritycode utcdate utchour)
	qui reshape wide  wnd ghi, i(utcdate utchour) j(balancingauthoritycode) string
qui save $temp6, replace
}

if "`inter'"=="Texas"{
	qui keep if region=="TEX" 

	collapse (mean)  wnd ghi [aweight=pop], by(balancingauthoritycode utcdate utchour)
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
	keep if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") 

	collapse (mean)  wnd ghi [aweight=pop], by(region utcdate utchour)
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
	keep if (region=="CAL" | region=="NW" | region=="SW" ) 	

	collapse (mean)  wnd ghi [aweight=pop], by(region utcdate utchour)
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
	keep if region=="TEX" 

	collapse (mean)  wnd ghi [aweight=pop], by(region utcdate utchour)
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
egen newid=group(idnum)
egen tmax=max(newid)
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
merge 1:m utcdate utchour using $temp10, nogen keep(3)
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
merge 1:m utcdate utchour using $temp10, nogen keep(3)
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
merge 1:m utcdate utchour using $temp10, nogen keep(3)
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
merge 1:m utcdate utchour using $temp10, nogen keep(3)
qui save $temp11, replace	
}


if "`level'"=="comsub"{
use "$tempdir/hourlycomsub.dta", clear
keep if utchour==`thehour'
if "`inter'"=="Texas" keep utcdate utchour demandNCEN demandCOAS demandBSOU demandBWES
merge 1:m utcdate utchour using $temp10, nogen keep(3)
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
if "`level'"=="comsub" & "`inter'"=="Texas" global regions demandNCEN demandCOAS demandBSOU demandBWES

clear
save "$tempdir/tempcoef`inter'.dta", replace emptyok

use $temp11, clear


*dis "working on `countit' (or `ttmax') plants in the `inter' interconnection"

dis "working on `ttmax' plants in the `inter' interconnection"



local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
forvalue j= 1/`ttmax'{
*forvalue j = 152/154{	 
	 qui use if newid==`j' using $temp11, clear
	 if `j'==100 dis "plant `j'"
	 if `j'==200 dis "plant `j'"
	 if `j'==500 dis "plant `j'"
	 if `j'==1000 dis "plant `j'"
	 *gen windORsun=0
	 *qui replace windORsun = 1 if strpos(ID,"sun") | strpos(ID,"wind")
	
	** set up RHS variables according to interconnection
	if _N >0 {
		
		* control for fixed effects and weather
		/*
		if 1{
		qui gen constant = 1
		
		if windORsun[1] == 1{
		local curbacode = bacode[1]
		dis "plant `j' curbacode `curbacode'"
		*local varstouse netgen $regions constant i.group wnd`curbacode' ghi`curbacode'
		local varstouse netgen $regions constant i.group wndERCO ghiERCO
		dis "vars to use  `varstouse'"
		}
		
		
		if windORsun[1] == 0{
		local varstouse netgen $regions constant i.group 
		dis "vars to use  `varstouse'"
		}
		*/
		
		*if `j'==152 dkfhafh
		*local varstouse netgen $regions constant i.group
		*local varstouse netgen $regions constant i.group wndERCO ghiERCO 
		
		* some plants are defined at regional level (residual coal, trade and so on)
		
		qui gen constant= 1
		
		if bacode[1]== "" {
			local curbacode = region[1]
		}
		else {
			local curbacode = bacode[1]
		}
	
		local varstouse netgen $regions constant i.group wnd`curbacode' ghi`curbacode'
		
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		local numreg: word count $regions
		local endreg = `numreg'+1
		local startweather=`endreg'+1
		local numcol=`=colsof(data)'
		*dis "numreg `numreg'"
		*dis "endreg `endreg'"
		*dis "startweather `startweather'"
		*dis "numcol `numcol'"
		matselrc data y, c(1)
		matselrc data x, c(2/`endreg')
		matselrc data w, c(`startweather'/`numcol')
		
		local then `=rowsof(x)'
		local dim `=rowsof(y)'
		*dis "plant `j' num obs x `then' num obs y `dim'"
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		
		matrix XX = x'*M*x
		matrix Xy= x'*M*y
		matrix yX = Xy'
		
		*local dimm (`= rowsof(M)',`=colsof(M)') 
		*dis "size of m `dimm'"
		*matrix list XX
		*matrix list yX
		*matrix list y
		
		
		
		
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
	}
	
		
	
	
}
dis "total" `cot'

* dump big column matrices into excel files to transfer to python
* also transfer list of unit numbers
*A1 is cell number

** XX matrix is stored as a stata dta file
use "$tempdir/bigmattemp.dta"
export excel "../python/XX.xlsx", nolabel replace
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

* texas comsub order demandNCEN demandCOAS demandBSOU demandBWES

if "`level'" == "comsub"{
if "`inter'"== "Texas"{
	qui rename A idnum
	qui rename B btildaNCEN
	qui rename C btildaCOAS
	qui rename D btildaBSOU
	qui rename E btildaBWES
	
}
}


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

if  "`inter'"== "West" {
	qui rename A idnum
	qui rename B btildaCAL 
	qui rename C btildaNW 
	qui rename D btildaSW
			}

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
					
save "$tempdir/coef`inter'.dta", replace

qui import excel using "../python/temp_converge.xlsx",  clear firstr 
gen inter = "`inter'"
save "$tempdir/converge`inter'.dta", replace

** need to match up lagrange multiplier to corresponding demand variable

qui import excel using "../python/temp_lm.xlsx",  clear firstr 
gen inter = "`inter'"
gen region = ""
local jcount=1
foreach regvar in $regions {
replace region="`regvar'" in `jcount'
local jcount = `jcount'+1
}

save "$tempdir/lm`inter'.dta", replace


} //end interconnection loop


* put coefficients from all three interconnections into a single file
use $tempdir/coefTexas, clear
*append using $tempdir/coefWest
*append using $tempdir/coefEast

* save file with coefficients for each hour and level
save "data/hourly22/coefsconstrained_`level'`thehour'.dta", replace

* put converge info from all three interconnections into a single file
use $tempdir/convergeTexas, clear
*append using $tempdir/convergeWest
*append using $tempdir/convergeEast

* save file with converge info for each hour and level
save "data/hourly22/converge_`level'`thehour'.dta", replace

* put lagrange multipliers from all three interconnections into a single file
use $tempdir/lmTexas, clear
*append using $tempdir/lmWest
*append using $tempdir/lmEast

* save file with lagrange multiplier for each hour and level
save "data/hourly22/LM_`level'`thehour'.dta", replace


foreach inter in East West Texas{
	capture erase $tempdir/coef`inter'.dta
	capture erase $tempdir/converge`inter'.dta
	capture erase $tempdir/lm`inter'.dta
}

} //end levels loop


} //end hours loop




*** analyze data


*** marginal generation by fuel for each of inter, region, balance, sub

foreach zone in   comsub  {
	
	clear
	save $temp2, emptyok replace

	foreach case in con   {
		foreach thehour in $hoursAll{
			use "data/cems_units_fuel_19-22.dta", clear
			drop yr
			duplicates drop
			* plants with num >1 switched fuel
			bysort PLANT unitid: egen num=count(Fuel)
			* almost all switched to gas
			replace Fuel="Gas" if num==2
			duplicates drop
			* only 60589 stays because it doesn't have a "source" for one year
			drop if PLANT==60589 & Source==""

			merge m:1 PLANT unitid using "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", nogen keep (2 3)

			if "`case'"=="con"{
				merge 1:1 idnum using "data/hourly22/coefsconstrained_`zone'`thehour'.dta", nogen keep(2 3)
			}
			if "`case'"=="uncon"{
				merge 1:1 idnum using "data/hourly22/coefs_`zone'`thehour'.dta", nogen keep(2 3)
			}

			replace Fuel="Other" if strpos(ID,"balance")
			replace Fuel="Nuke" if strpos(ID,"nuke")
			replace Fuel="Sun" if strpos(ID,"sun")
			replace Fuel="Trade" if strpos(ID,"Trade")
			replace Fuel="Hydro" if strpos(ID,"water")
			replace Fuel="Wind" if strpos(ID,"wind")
			* put residual coal and residual gas in with gas and coal
			replace Fuel="Coal" if strpos(ID,"coal")
			replace Fuel="Gas" if strpos(ID,"gas")
			replace Fuel="Other" if strpos(ID,"other")

			if "`zone'"=="region"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
				
			}

			
			if "`zone'"=="inter"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in East West Texas{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in East West Texas{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			if "`zone'"=="balance"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in $AllBAcodes{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in $AllBAcodes{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			if "`zone'"=="sub"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in $AllsubBAcodes{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in $AllsubBAcodes{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			
			if "`zone'"=="comsub"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in NCEN COAS BSOU BWES {

						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in $AllsubBAcodes{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}
			
			gen case ="`case'"
			gen utchour=`thehour'
			append using $temp2
			save $temp2, replace
		* end foreach thehour
		}
	* end foreach case
	}
save "data/coefs_fuel_`zone'22.dta", replace
* end foreach zone
}


*** graph results

use "data/coefs_fuel_comsub22.dta", replace
capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 5
replace localhour = localhour + 24 if localhour < 1
sort localhour

replace Fuel = "remainder" if inlist(Fuel,"Hydro","Nuke","Other","Trade")
collapse (sum) btilda*, by (utchour case Fuel localhour)

sort localhour

foreach sub in NCEN COAS BSOU BWES{
*foreach reg in SW {


capture graph drop gr*

global gropts graphregion(color(white)) xtitle("Hour ") ytitle("Marginal generation share") legend(off)

twoway (line btilda`sub' localhour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btilda`sub' localhour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("Regularized") name(grcon) xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))


global grcombopts graphregion(color(white) margin(zero zero zero zero)) name(temp, replace)
if "`sub'"=="COAS" graph combine  grcon,  title("Coast") $grcombopts
if "`sub'"== "NCEN" graph combine  grcon , title("North Central") $grcombopts
if "`sub'"=="BSOU" graph combine  grcon,  title("Big South") $grcombopts
if "`sub'"== "BWES" graph combine  grcon , title("Big West") $grcombopts
*graph display temp, xsize(5) ysize(2)
graph export "latex22/fig-fuel-coefs`sub'_texas_test.png", replace
}

