* v2 includes subregion load data for some balancing authorities(CISO,ISNE,MISO,NYIS,PJM,SWPP,ERCO)
* regress generation by unit on load by inter, region, and balance
* unconstrained allows negative coefficients
* constrained requires positivity and sum to one over load for a given region
* unconstrained solved by areg in stata
* constrained solved by calling python routine "regular.py"

* run globals_regular.do

*foreach level in sub balance inter region  {
foreach level in sub{

foreach thehour in 1{

** slightly different procedures for inter, region, balance, and sub
if "`level'"=="sub"{
use "data/Hourly_Sub_Load.dta", clear
keep  subregion demand utcdate utchour 
reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==`thehour'
save $temp1, replace

** bring in balance authority data, drop ISO demands
use "data/Hourly_Balancing_Load.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(bacode, string)
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
save $temp1, replace

}
if "`level'"=="balance"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Balancing_Load.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(bacode, string)
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
save $temp1, replace
}


if "`level'"== "region"{
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation.dta", clear
keep region demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==`thehour'
save $temp1, replace		
}

if "`level'"=="inter" {
* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation.dta", clear
keep region demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==`thehour'
gen demandWest= demandCAL + demandSW + demandNW
gen demandTexas = demandTEX
gen demandEast = demandCAR + demandCENT + demandFLA + demandMIDA + demandMIDW + demandNE + demandNY + demandSE + demandTEN
save $temp1, replace
}

* pull one hour of generation data
use "data/hourly/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
gen inter = "East"
replace inter="West" if inlist(region,"CAL","NW","SW")
replace inter="Texas" if region=="TEX"
save $temp2, replace

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
keep if month >=6 & month <=9 

* find number of inuts
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units " $numunits
drop  tmax
save $temp3,replace

/*
* unconstrained regressions for each unit
forvalue j = 1/$numunits{
qui use if idnum==`j' using $temp3, clear
if `j'==100 dis `j'
if `j'==1000 dis `j'
if `j'==2000 dis `j'
if `j'==3000 dis `j'
if `j'==4000 dis `j'

* merge generation data with demand data
qui merge 1:1 utcdate utchour using $temp1, nogen keep(3)

* set up RHS variables depending on which interconnection the plant belongs to
if "`level'"=="sub"{
qui if inter[_n==1]=="East" drop $WestSubCodes $TexasSubCodes 
qui if inter[_n==1]=="West" drop $EastSubCodes $TexasSubCodes
qui if inter[_n==1]=="Texas" drop $EastSubCodes $WestSubCodes
}

if "`level'"=="balance"{
qui if inter[_n==1]=="East" drop $WestBaCodesDr $TexasBaCodes
qui if inter[_n==1]=="West" drop $EastBaCodesDr $TexasBaCodes
qui if inter[_n==1]=="Texas" drop $EastBaCodesDr $WestBaCodesDr
}

if "`level'"=="region"{
qui if inter[_n==1]=="West" drop demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE  demandNY demandSE  demandTEN demandTEX
qui if inter[_n==1]=="East" drop demandCAL demandTEX demandSW demandNW
qui if inter[_n==1]=="Texas" drop demandCAL demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNW demandNY demandSE demandSW demandTEN		
}

if "`level'"=="inter"{
qui if inter[_n==1]=="West" keep netgen demandWest group ID idnum region inter
qui if inter[_n==1]=="East" keep netgen demandEast group ID  idnum region inter
qui if inter[_n==1]=="Texas" keep netgen demandTexas group ID idnum region inter
}

* plant by plant unconstrained regression of generation on load

if _N >0 {
	qui areg netgen demand*, a(group)
	qui for var demand*: gen bnetgenX=_b[X]
	qui keep ID region b* idnum
	qui duplicates drop
	if `j' > 1 append using "data/hourly/coefs_`level'`thehour'.dta"
	sort idnum
	qui save "data/hourly/coefs_`level'`thehour'.dta", replace
	}
}
*/

*** now do constrained regression
* make matrices for transfer to python

* will solve for all units in an interconnection simultaneously such that sum of coeffients for each load region add up to one
foreach inter in    Texas  {
	
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
save $temp4, replace


dis "`inter'"  `ttmax'


	 
	 use "../rawdata/NREL weather/nrel_nsrd_2019.dta", clear
	 destring fips , replace
	 keep if int(fips/1000)==48 
	 gen utcdate=dofc(datetime_utc)
	 format utcdate %td
	 gen utchour=hh(datetime_utc)
	 save $temp7, replace
	 
	 import excel using  "../rawdata/epa/ozone-county-population.xlsx", firstrow clear
	 destring STATEFIPS COUNTYFIPS, replace
	 gen fips = STATEFIPS*1000+COUNTYFIPS
	 keep fips F
	 rename F pop
	 order fips pop
	 save "data/fips_pop2015.dta", replace
	 
	 use $temp7, clear
	 keep fips utcdate utchour temperature windspeed
	 merge m:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen keep(3) keepusing(subBA balanc)
	 merge m:1 fips using "data/fips_pop2015.dta" , nogen keep(3)
	 keep if balanc=="ERCO"
	 collapse (mean) temperature windspeed [aweight=pop], by(subBA utcdate utchour)
	 replace utchour = utchour+1
	 rename temperature tmp
	 rename windspeed wnd
	 reshape wide tmp wnd, i(utcdate utchour) j(subBA) string
	 save $temp8, replace
	 
	 
	 use $temp4, clear
	 qui merge m:1 utcdate utchour using $temp1, nogen keep(3)
	 qui merge m:1 utcdate utchour using $temp8, nogen keep(3)
	 drop $EastSubCodes $WestSubCodes
	 
	 local ttmax=tmax[1]
	 levelsof newid, local(levels)
	 
	 foreach var of varlist netgen demand* {
		qui gen e`var'= .
		foreach j of local levels {
			
			capture drop temp
			qui reg `var' i.group tmp* wnd* if newid==`j'
			qui predict temp, resid
			qui replace e`var' = temp  if newid==`j'
			
		}	
	 }
	 * replace original with orthorgonalized (or residuals)
	 foreach var of varlist netgen demand* {
		drop `var'
		rename e`var' `var'
	 }
	 
	 save "data/texas_subBA_weatherized.dta", replace
	 
	 
	 
local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"

use "data/texas_subBA_weatherized.dta", clear
local ttmax=tmax[1]
local inter="Texas"
local level="sub"

forvalue j= 1/`ttmax'{	 
	 
	 qui use if newid==`j' using "data/texas_subBA_weatherized.dta", clear
	
	 
	 
	** set up RHS variables accoring to interconnetction
	if _N >0 {
		
		if "`level'"=="sub"{
		
		if "`inter'"=="Texas"{
			 qui matrix accum A = netgen $TexasSubCodes,  noconst
			}
		if "`inter'"=="West" {
			qui matrix accum A = netgen $WestSubCodes, deviations  absorb(group) noconst
			}
		if "`inter'"=="East"{
			qui matrix accum A = netgen $EastSubCodes, deviations  absorb(group) noconst
			}
		}
		
		
		if "`level'"=="balance"{
		
		if "`inter'"=="Texas"{
			 qui matrix accum A = netgen $TexasBaCodes, deviations  absorb(group) noconst
			}
		if "`inter'"=="West" {
			qui matrix accum A = netgen $WestBaCodesDr, deviations  absorb(group) noconst
			}
		if "`inter'"=="East"{
			qui matrix accum A = netgen $EastBaCodesDr, deviations  absorb(group) noconst
			}
		}
		
		if "`level'"=="region" {
		if "`inter'"=="Texas"{
			qui matrix accum A = netgen demandTEX, deviations  absorb(group) noconst
			}
		if "`inter'"=="West" {
			qui matrix accum A = netgen demandCAL demandNW demandSW, deviations  absorb(group) noconst
			}
		if "`inter'"=="East"{
			qui matrix accum A = netgen demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN, deviations  absorb(group) noconst
			}
		}
			
		if "`level'"=="inter" {
		if "`inter'"=="Texas"{
			qui matrix accum A = netgen demandTexas, deviations  absorb(group) noconst
			}
		if "`inter'"=="West" {
			qui matrix accum A = netgen demandWest, deviations  absorb(group) noconst
			}
		if "`inter'"=="East"{
			qui matrix accum A = netgen demandEast, deviations  absorb(group) noconst
			}
		}
			
			
		matrix XX = A[2...,2...]
	
		matrix yX= A[1,2...]
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[idnum[1]]
			drop _all
			qui svmat XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[idnum[1]]
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat XX
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
	qui rename BO btildaRECO
	qui rename BP btildaCSWS
	qui rename BQ btildaEDE
	qui rename BR btildaGRDA
	qui rename BS btildaINDN
	qui rename BT btildaKACY
	qui rename BU btildaKCPL
	qui rename BV btildaLES
	qui rename BW btildaMPS
	qui rename BX btildaNPPD
	qui rename BY btildaOKGE
	qui rename BZ btildaOPPD
	
	qui rename CA btildaSECI
	qui rename CB btildaSPRM
	qui rename CC btildaSPS
	qui rename CD btildaWAUE
	qui rename CE btildaWFEC
	qui rename CF btildaWR
	
	
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
					
dfafddfdf
					
					
save "$tempdir/coef`inter'.dta", replace

}

* put coefficients from all three interconnections into a single file
use $tempdir/coefTexas, clear
append using $tempdir/coefWest
append using $tempdir/coefEast

* save file with coefficients for each hour and level
save "data/hourly/coefsconstrained_`level'`thehour'.dta", replace

foreach inter in East West Texas{
	capture erase $tempdir/coef`inter'.dta
}

* end each hour
}

* end each level
}
