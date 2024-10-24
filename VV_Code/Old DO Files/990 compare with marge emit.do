**************************************************************
* this part mimics "create dam co2-2.do" from margemit
use "data/plant_all_data.dta",clear
rename INTERCON INTER
keep INTER PLANT 
duplicates drop
save $temp, replace

use "$cemsdirreg/emissions_all_unit_allyears.dta"
gen yr=int(UTCDATE/10000)
keep if yr==2019
save $temp7, replace
collapse (sum) SO2MASS CO2MASS NOXMASS GLOAD , by (UTCDATE UTCHOUR PLANT)


*** merge with plant info to get interconnection
merge m:1 PLANT  using $temp, keep(1 3) nogen

save $temp1, replace

* CO2 mass in tons, SCC for metric ton
* so multiply CO2MASS by 0.907185
use $temp1, clear
gen CO2_dam= 50.98514*(CO2MASS*0.907185/1000000) 
gen damage=CO2_dam
replace GLOAD=GLOAD/1000

collapse (sum) damage  CO2_dam  CO2MASS GLOAD ,  by(UTCDATE UTCHOUR INTER)

save "data/dam_electric_19_inter_margemit.dta", replace


*** this part uses average emissions rather than emissions from cems
use $temp7, clear
collapse (sum) SO2MASS CO2MASS NOXMASS GLOAD , by (UTCDATE UTCHOUR PLANT unitid)
rename PLANT plant
merge m:1 plant unitid using "data/plant_unit_marginal_emissions.dta",nogen keep (1 3)
rename plant PLANT
merge m:1 PLANT using $temp, keep (1 3) nogen
* wco2 in short tons/mwh
* Gload in MWH
* SCC in dollars per metric ton
* units are $/metric ton * MWH * short tons/MWH * 0.907183 metric ton /short ton * /1000000 = millions of dollars
gen CO2_dam = 50.98514 * GLOAD * wco2rate*0.907185/1000000
gen damage = CO2_dam
replace GLOAD = GLOAD/1000
collapse (sum) damage CO2_dam CO2MASS GLOAD, by (UTCDATE UTCHOUR INTER)
save "data/dam_electrid_19_inter_margemit_average.dta"


************************************************************************
** this part reproduces "60 create hourly regional load and generation"
** for all hours, but only 2019
** calll it hourly regional load and generation margemit
if 1 {
* make "data/Hourly_Regional_Load_Generation.dta"
clear
save $temp, replace emptyok
foreach Region in $AllRegions {
*foreach Region in MIDA {
	display "`Region'"
	import excel using "../rawdata/EIA930/webdownload/Region_`Region'.xlsx", first sheet("Published Hourly Data") cellrange(A1) clear
	keep if year(Localdate)>= 2019
	keep if year(Localdate)< 2020
	append using $temp
	save $temp, replace
	}
}
use $temp, clear
rename *, lower

label var localdate "Local date"
* The date (using the specified local time zone) for which data has been reported"
label var hour	"Local hour"
* The hour number for the day.  Hour 1 corresponds to the time period 12:00 AM - 1:00 AM"
gen utcdate=dofc(utctime)
format utcdate %td
gen utchour=Clockpart(utctime,"h")+1  
replace utcdate=utcdate-1 if utchour==24

label var utcdate "Universal standard time's date"
label var utchour "Universal standard time's hour"
label var d "Demand (MW) is the electricity load aggregated across a region's balancing authorities' electric systems"
* Demand is a calculated value representing the amount of electricity load within the balancing authority's electric system. A BA derives its demand value by taking the total metered net electricity generation within its electric system and subtracting the total metered net electricity interchange occurring between the BA and its neighboring BAs.  This column displays in MWh the sum of the demand of the BAs in the region."
label var df "Forecast demand (MW)"
label var ngcol "Net hourly generation (MWh) from coal energy reported by the balancing authority"
label var ngng "Net hourly generation (MWh) from natural gas energy reported by the balancing authority"
label var ngoil "Net hourly generation (MWh) from oil energy reported by the balancing authority"
label var ngsun "Net hourly generation (MWh) from solar energy reported by the balancing authority"
label var ngwnd "Net hourly generation (MWh) from wind reported by the balancing authority"
label var ngnuc "Net hourly generation (MWh) from nuclear reported by the balancing authority"
label var ngwat "Net hourly generation (MWh) from hydroelectric power reported by the balancing authority"

rename localdate date

foreach v of varlist ng* cal-mex {
	recode `v' .=0
}
rename d demand
rename ngng gengas
rename ngsun gensun
rename ngwnd genwind
rename ngnuc gennuke
rename ngwat genwater
rename ngcol gencoal
rename ngoil genoil
gen genother=ngoth+ngunk
label var genother "Net hourly generation (MWh) from other energy reported by the balancing authority"
drop ngoth ngunk
/*
** the demand data in the 930 are not consistent with its definition so we redefine it to be consistent for extreme outliers (6 sigma). 
** the variable balancengdti reports the reported net generation less demand less exports (total interchange)
** this should be zero as demand is defined as total net generation less exports. however there are reporting errors.

su balancengdti,d
egen regse_bal = sd(balancengdti),by(region) 
replace demand = ng-ti if ng<. & ti<. & abs(balancengdti)>6*regse_bal
** by definition, balancngdti is now zero for these observations
replace balancengdti=0 if ng<. & ti<. & abs(balancengdti)>6*regse_bal
drop regse_bal
*/
** 930 has the following definitions
** NG = D + Ti + balancengdti. 
** 		NG = net generation, D = demand, Ti = trade, balancengdti = error
**
** Ti = sumtrade + balancetitrade
** 		Ti = trade, sumtrade = cal + car + cent + fla + mida + midw + ne + nw + ny + se + sw + ten + tex + can + mex, balancetitrade= error
**
** ng = sumng + balanceng
**		ng = net generation, sumng = gencoal + gengas + gennuke+ genoil+genwater+gensun+genwind, balanceng = error
**
** For a given region in a given interconnection, we want to define a "other trade" generation variable equal to trade from
** regions in other interconnections + errors in this trade and thus maintain adding up constraint
** re-write so that extra variable is on the generation side of the equation
** NG -(Ti + balancengdti) = D
** substitute in Ti equation
** NG -( sumtrade + balancetitrade + balancengdti) = D
** this suggests defining othertrade = -(sumtrade + balancetitrade + balancengdti)
**  But, we don't want to include trade from within interconnection in sumtrade
**  and error in balancetitrade includes internal error within the interconnection and external error outside the interconnection
**  balancetitrade = interror + exterror
**  so we want external trade plus external error in sumtrade
**  For EAST we have othertrade = -( (sumtrade- car -cent -fla -mida -midw -ne -ny -se -ten)  + balancengdti + exterror )
**  For WEST we have othertrade = -( (sumtrade- cal - sw - nw)  + balancdngdti + exterror)
**  For TEXAS we have othertrade = -(sumtrade + balancetitrade + balancdngdti )

** calculate internal error: interror

** temporarily save data 

save "$tempdir/save1.dta", replace

keep cal car cent fla mida midw ne nw ny se sw ten tex utcdate utchour region
reshape wide cal car cent fla mida midw ne nw ny se sw ten tex, i(utcdate utchour) j(region) string
** west interconnection: cal, nw, sw
** nwCAL is trade from nw to Cal
** calNW is trade from cal to NW
** these should sum to zero but they don't because of error
gen errorCAL = nwCAL + swCAL + calNW + calSW
gen errorNW = swNW + calNW + nwCAL + nwSW
gen errorSW =  calSW + nwSW + swCAL + swNW
*** texas
gen errorTEX= 0
** east interconnection: same structure but now 9 regions: car cent fla mida midw ne ny se ten
gen errorCAR = centCAR + flaCAR + midaCAR + midwCAR + neCAR + nyCAR + seCAR + tenCAR + carCENT + carFLA + carMIDA + carMIDW + carNE + carNY + carSE + carTEN
gen errorCENT= carCENT + flaCENT + midaCENT + midwCENT + neCENT + nyCENT + seCENT + tenCENT + centCAR + centFLA + centMIDA + centMIDW +centNE +centNY + centSE + centTEN
gen errorFLA = carFLA + centFLA + midaFLA + midwFLA + neFLA + nyFLA + seFLA + tenFLA + flaCAR + flaCENT + flaMIDA + flaMIDW + flaNE + flaNY + flaSE + flaTEN
gen errorMIDA= carMIDA + centMIDA + flaMIDA + midwMIDA + neMIDA + nyMIDA + seMIDA + tenMIDA + midaCAR + midaCENT + midaFLA + midaMIDW + midaNE + midaNY + midaSE + midaTEN
gen errorMIDW= carMIDW + centMIDW + flaMIDW + midaMIDW + neMIDW + nyMIDW + seMIDW + tenMIDW + midwCAR + midwCENT + midwFLA + midwMIDA + midwNE + midwNY + midwSE + midwTEN
gen errorNE  = carNE + centNE + flaNE + midaNE + midwNE + nyNE + seNE + tenNE + neCAR + neCENT + neFLA + neMIDA + neMIDW + neNY + neSE + neTEN
gen errorNY  = carNY + centNY + flaNY + midaNY + midwNY + neNY + seNY + tenNY + nyCAR + nyCENT + nyFLA + nyMIDA + nyMIDW + nyNE + nySE + nyTEN
gen errorSE  = carSE + centSE + flaSE + midaSE + midwSE + neSE + nySE + tenSE + seCAR + seCENT + seFLA + seMIDA + seMIDW + seNE + seNY + seTEN
gen errorTEN = carTEN + centTEN + flaTEN + midaTEN + midwTEN + neTEN + nyTEN + seTEN + tenCAR + tenCENT + tenFLA + tenMIDA + tenMIDW + tenNE + tenNY + tenSE

reshape long error, i(utcdate utchour) j(region) string
keep utcdate utchour region error
**divide by 2 to avoid double counting
replace error= error/2
save "$tempdir/error1.dta", replace

** merge internal error into data
use "$tempdir/save1.dta", clear
merge 1:1 utcdate utchour region using "$tempdir/error1.dta", nogen keep(1 2 3)
rename error interror
recode interror .=0
gen othertrade = -(sumtrade + balancetitrade + balancengdti)
** subtract out within interconnection data from sumtrade and interior error from balancetitrade
replace othertrade = othertrade + car + cent + fla + mida + midw + ne + ny + se + ten -interror if inlist(region,"CAR","CENT","FLA","MIDA","MIDW","NE","NY","SE","TEN")
replace othertrade = othertrade + cal + sw + nw - interror if inlist(region,"CAL","NW","SW")


gen regionname = ""
replace regionname = "California" if region == "CAL"
replace regionname = "Carolinas" if region == "CAR"
replace regionname = "Central" if region == "CENT"
replace regionname = "Florida"	if region == 	"FLA"
replace regionname = "Mid-Atlantic"	if region == 	"MIDA"
replace regionname = "Midwest"	if region == 	"MIDW"
replace regionname = "New England"	if region == 	"NE"
replace regionname = "New York"	if region == 	"NY"
replace regionname = "Northwest"	if region == 	"NW"
replace regionname = "Southeast"	if region == 	"SE"
replace regionname = "Southwest"	if region == 	"SW"
replace regionname = "Tennessee"	if region == 	"TEN"
replace regionname = "Texas"	if region == 	"TEX"
sort region date hour
save "data/Hourly_Regional_Load_Generation_margemit.dta", replace






**********************************************************
* this part mimics FT-marginaldamages1.do from margemit


set more off

*******************************************************************************************************************
****   create variables that demean the fixed effects
*******************************************************************************************************************

global case =1
*global case =2

if $case == 2 {
use "data/dam_electric_19_inter_margemit.dta", clear
}
if $case == 1 {
use "data/dam_electrid_19_inter_margemit_average.dta", clear
}
rename UTCDATE utcdate
rename UTCHOUR utchour
replace damage=CO2_dam*100 // in millions of cents
gen yr=int(utcdate/10000)
gen month = int((utcdate-yr*10000)/100)
gen day = int(utcdate -yr*10000 - month*100)
rename utcdate DATE
save $temp, replace



* reshape load data so that we have one set of hours that has all loads

use "data/Hourly_Regional_Load_Generation_margemit.dta", clear
keep region demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(region, string)
gen demandWest= demandCAL + demandSW + demandNW
gen demandTexas = demandTEX
gen demandEast = demandCAR + demandCENT + demandFLA + demandMIDA + demandMIDW + demandNE + demandNY + demandSE + demandTEN
keep utcdate utchour demandWest demandTexas demandEast
gen yr =year(utcdate)
gen month=month(utcdate)
gen day = day(utcdate)
save $temp1, replace

use $temp, clear
merge m:1 yr month day utchour using "$temp1", nogen keep (1 3)
keep if yr==2019




rename demandWest loadWEST
rename demandEast loadEAST
rename demandTexas loadERCOT
rename utchour HOUR
replace INTER="EAST" if INTER=="East"
replace INTER="WECC" if INTER=="West"
replace INTER="ERCOT" if INTER=="Texas"
* convert MWH to  millons of KWh
replace loadWEST = loadWEST/1000
replace loadEAST = loadEAST/1000
replace loadERCOT = loadERCOT/1000

gen double moyr=int(DATE/100)*100
egen moyrHR=group(moyr HOUR)
*gen day=inlist(HOUR,9,10,11,12,13,14,15,16,17,18)
gen mo=int(DATE/100)-int(DATE/10000)*100
*gen hot=inlist(mo,5,6,7,8,9,10)
for var  loadERCOT loadEAST loadWEST: gen tX=X*(yr-2019)
sort INTER DATE HOUR
gen t=_n
tsset t
capture drop *_err
gen dmgERCOT = damage if INTER=="ERCOT"
gen gldERCOT = GLOAD if INTER=="ERCOT"
gen tgldERCOT =gldERCOT*(yr-2010)
for var dmgERCOT loadERCOT tloadERCOT gldERCOT tgldERCOT: qui areg X if INTER=="ERCOT", a(moyrHR) \ predict X_err, resid
label var loadERCOT_err "Load"
label var tloadERCOT_err "Load Trend"
label var gldERCOT_err "Fossil Gen"
label var tgldERCOT_err "Fossil Gen Trend"
gen dmgEAST = damage if INTER=="EAST"
gen gldEAST = GLOAD if INTER=="EAST"
gen tgldEAST =gldEAST*(yr-2010)
for var dmgEAST loadEAST tloadEAST gldEAST tgldEAST   : qui areg X if INTER=="EAST", a(moyrHR) \ predict X_err, resid
label var loadEAST_err "Load"
label var tloadEAST_err "Load Trend"
label var gldEAST_err "Fossil Gen"
label var tgldEAST_err "Fossil Gen Trend"
gen dmgWEST = damage if INTER=="WECC"
gen gldWEST = GLOAD if INTER=="WECC"
gen tgldWEST=gldWEST*(yr-2010)
for var dmgWEST loadWEST tloadWEST gldWEST tgldWEST : qui areg X if INTER=="WECC", a(moyrHR) \ predict X_err, resid
label var loadWEST_err "Load"
label var tloadWEST_err "Load Trend"
label var gldWEST_err "Fossil Gen"
label var tgldWEST_err "Fossil Gen Trend"
save $tempdir/erin_temp.dta, replace



* sqrt n/n-k is std. err. times 1.0168

global adjust = 1.0168


matrix loadtab = J(12,1,.)
matrix loadtabB = J(3,2,.)
matrix loadtabSEsq = J(3,2,.)

newey dmgEAST_err loadEAST_err tloadEAST_err if INTER=="EAST", force lag($lag)
	estimates store tndEAST
	matrix loadtab[1,1] = _b[loadEAST_err]
	matrix loadtab[2,1] = _se[loadEAST_err]*$adjust
	matrix loadtab[3,1] = _b[tloadEAST_err]
	matrix loadtab[4,1] = _se[tloadEAST_err]*$adjust
	matrix loadtabB[1,1]= loadtab[1,1]
	matrix loadtabB[1,2]= loadtab[3,1]
	matrix loadtabSEsq[1,1]= loadtab[2,1]^2
	matrix loadtabSEsq[1,2] = loadtab[4,1]^2
	
newey dmgWEST_err loadWEST_err tloadWEST_err if INTER=="WECC", force lag($lag)
	estimates store tndWEST
	matrix loadtab[5,1] = _b[loadWEST_err]
	matrix loadtab[6,1] = _se[loadWEST_err]*$adjust
	matrix loadtab[7,1] = _b[tloadWEST_err]
	matrix loadtab[8,1] = _se[tloadWEST_err]*$adjust
	matrix loadtabB[2,1]= loadtab[5,1]
	matrix loadtabB[2,2]= loadtab[7,1]
	matrix loadtabSEsq[2,1]= loadtab[6,1]^2
	matrix loadtabSEsq[2,2] = loadtab[8,1]^2
	
newey dmgERCOT_err loadERCOT_err tloadERCOT_err if INTER=="ERCOT", force lag($lag)
	estimates store tndERCOT
	matrix loadtab[9,1] = _b[loadERCOT_err]
	matrix loadtab[10,1] = _se[loadERCOT_err]*$adjust
	matrix loadtab[11,1] = _b[tloadERCOT_err]
	matrix loadtab[12,1] = _se[tloadERCOT_err]*$adjust
	matrix loadtabB[3,1]= loadtab[9,1]
	matrix loadtabB[3,2]= loadtab[11,1]
	matrix loadtabSEsq[3,1]= loadtab[10,1]^2
	matrix loadtabSEsq[3,2] = loadtab[12,1]^2
	


matrix bigtab = J(20,3,.)
global ctr = 0 

foreach y in  2019{

newey2 dmgEAST_err loadEAST_err  if INTER=="EAST" & yr==`y', force lag($lag)
	matrix bigtab[2*(`y'-2019)+1,1] = _b[loadEAST_err]
	matrix bigtab[2*(`y'-2019)+2,1] = _se[loadEAST_err]*$adjust
	estimates store yr`y'EAST
	


newey2  dmgWEST_err loadWEST_err if INTER=="WECC" & yr==`y', force lag($lag)
	matrix bigtab[2*(`y'-2019)+1,2] = _b[loadWEST_err]
	matrix bigtab[2*(`y'-2019)+2,2] = _se[loadWEST_err]*$adjust
	estimates store yr`y'WEST

newey2 dmgERCOT_err loadERCOT_err  if INTER=="ERCOT" & yr ==`y', force lag($lag)
	matrix bigtab[2*(`y'-2019)+1,3] = _b[loadERCOT_err]
	matrix bigtab[2*(`y'-2019)+2,3] = _se[loadERCOT_err]*$adjust
	estimates store yr`y'ERCOT
}




matrix list bigtab
matrix list loadtab
matrix list loadtabB




matrix ltd ==loadtab
matrix btd = bigtab



capture file close myfile
if $case == 2{
file open myfile using "latex/table-MD-carbon_margemit.tex", write replace
}

if $case == 1{
file open myfile using "latex/table-MD-carbon_margemit_average.tex", write replace
}

forvalues i = 1(2) 3 {
if `i'==1  file write myfile "2019 "

forvalues j = 1(1) 3 {
   file write myfile " & " %9.3fc (bigtab[`i',`j'])
}   
file write myfile "\\" _n
forvalues j = 1(1) 3 {
   file write myfile " & ( \hspace{-0.1in} "   %9.3fc (bigtab[`i'+1,`j']) ")" 
} 
file write myfile "\\ [1ex] " _n

}

capture file close myfile


afsfadsfd
