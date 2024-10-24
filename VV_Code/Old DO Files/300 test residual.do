
***  run "globals_regular.do"
*only run summer months

global monthlow= 6
global monthhigh= 9
* number of observations needed to avoid being put in the residual 
global numobsneed=0

foreach thehour in $hoursAll {
if 1 {
** pull one hour for now
use if UTCHOUR==`thehour' using "../rawdata/CEMS/emissions_all_unit_allyears22.dta", clear
gen int yr=int(UTCDATE/10000)
gen month = int(UTCDATE/100)-int(UTCDATE/10000)*100
merge m:1 PLANT unitid yr using "data/cems_units_fuel_19-22.dta", keep(1 3) nogen keepusing(Fuel)
merge m:1 PLANT Fuel month yr using "data/gross_to_net_generation22.dta", keep(1 3) nogen
sort PLANT unitid UTCDATE UTCHOUR
gen netgen = Gratio * GLOAD
*replace netgen = Sratio * SO2MASS if netgen == .
*replace netgen = Nratio * NOXMASS if netgen == .
*replace netgen = Cratio * CO2MASS if netgen == .
replace netgen = 0 if GLOAD == 0 & netgen == .
recode netgen .=0
*egen moyrnetgen=sum(netgen/1000),by(PLANT unitid month yr)
** next line will drop some units. May be different by hour. This creates need for hour by hour crosswalk from idnum to plant, unit
*keep if moyrnetgen>0	// don't do if need info on starting up
** We got rid of this because it would require having different weather data for each unit as it is conditional on the sample fixed effects. so instead we just moved the plants that rarely produce to a residual.
*
** drop plants that do not have any generation in months of interest
keep if month >= $monthlow & month<= $monthhigh
egen aggnetgen = sum(netgen), by(PLANT unitid)
drop if aggnetgen == 0

keep PLANT unitid Fuel UTCDATE UTCHOUR netgen GLOAD
merge m:1 PLANT using "$datadir/plant_all_data22.dta", nogen keep(1 3) keepusing(region bacode)
gen utcdate = mdy(int(UTCDATE/100)-int(UTCDATE/10000)*100,UTCDATE-int(UTCDATE/100)*100,int(UTCDATE/10000))
format utcdate %td
drop UTCDATE
rename UTCHOUR utchour

*DROP 2022 FOR NOW, BRING IN ONCE FINAL DATA VAILABLE
capture drop year
gen year = year(utcdate)
keep if year<2022
drop year

** Several units operate less than 200 hours over four summers. With fixed effects by year-month-dow-hour and three weather variables for each of the 42 states in the Eastern Interconnection, we perfectly predict netgen in the orthonalizing weather step. We lump these rarely generating units in with the residuals from the 930 data.
gen posnetgen = netgen > 0
egen totsummerpos = sum(posnetgen * inrange(month(utcdate),$monthlow,$monthhigh)),by(PLANT unitid)
* keep all plants in temp file  to make list of plants in residual at the bottom
save $temp10, replace
keep if totsummerpos >= $numobsneed
save $temp4, replace
collapse (sum) netgen GLOAD,by(bacode utcdate utchour Fuel)
reshape wide netgen GLOAD,i(utcdate utchour bacode) j(Fuel) string
save $temp5, replace
}

** Flag regions where data issues
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep region utcdate utchour ng sumng
gen ratio = sumng/ng
gen flag = 0
replace flag = 1 if ratio > 1.1 | ratio < 0.9 
keep region utcdate utchour flag 
keep if utchour==`thehour'
save $temp2, replace

*** generate nonCEMS residual generation for coal, gas, other at regional level
use "data/Hourly_Balancing_Load22.dta", clear
replace genother = genother + genoil
keep  region bacode utcdate utchour gengas gencoal genother
order region bacode utcdate utchour gengas gencoal genother

*this merge will only keep months in range of interest
merge 1:1 bacode utcdate utchour using $temp5, nogen keep(3)
sort bacode utcdate utchour

** ercot classified some gas as other some days. add to gas and assume previous days' actual other other
gen smpl = 0
replace smpl = 1 if bacode=="ERCO" & ((utcdate==mdy(12,18,2019) & utchour>=7) | (utcdate==mdy(12,19,2019) &utchour<=6))
replace smpl = 1 if bacode=="ERCO" & ((utcdate==mdy(1,8,2020) & utchour>=7) | (utcdate==mdy(1,9,2020) &utchour<=6))
replace smpl = 1 if bacode=="ERCO" & ((utcdate==mdy(1,15,2020) & utchour>=7) | (utcdate==mdy(1,16,2020) &utchour<=6))
replace smpl = 1 if bacode=="ERCO" & ((utcdate==mdy(1,22,2020) & utchour>=7) | (utcdate==mdy(1,23,2020) &utchour<=6))
replace gengas = gengas+genother if smpl
replace genother = genother[_n-24] if smpl
replace gengas = gengas-genother if smpl 

recode netgenCoal .=0
recode netgenGas .=0
recode netgenOther .=0

gen residgencoal = gencoal-netgenCoal
gen residgengas = gengas-netgenGas
gen residgenother = genother-netgenOther



asdfasdfs




format gen* netgen* GLOAD* resid* %9.0fc
keep bacode region utcdate utchour resid*
reshape long residgen,i(bacode region utcdate utchour) j(Fuel) string
gen ID = bacode + "_Resid_" + Fuel
rename residgen netgen
keep ID utcdate utchour bacode region netgen
order ID utcdate utchour bacode region netgen
save $temp6, replace

** generate trade variables at regional level 
foreach region in CAL NW SW TEX CENT MIDW NE NY {
use "data/Hourly_Regional_Load_Generation22.dta", clear

*DROP 2022 FOR NOW, BRING IN ONCE FINAL DATA VAILABLE
capture drop year
gen year = year(utcdate)
keep if year<2022
drop year

keep if region=="`region'"
if region=="CAL" keep region utcdate utchour genMEXtoCAL 
if region=="NW" keep region utcdate utchour genCANtoNW genCENTtoNW
if region=="SW" keep region utcdate utchour genCENTtoSW
if region=="TEX" keep region utcdate utchour genCENTtoTEX genMEXtoTEX
if region=="CENT" keep region utcdate utchour genCANtoCENT genTEXtoCENT genNWtoCENT genSWtoCENT
if region=="MIDW" keep region utcdate utchour genCANtoMIDW
if region=="NE" keep region utcdate utchour genCANtoNE
if region=="NY" keep region utcdate utchour genCANtoNY

keep if utchour==`thehour'
reshape long gen,i(region utcdate utchour) j(Fuel) string
gen ID = region + "_Trade_" + Fuel
rename gen netgen
** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exports
replace netgen = netgen*(-1)
keep ID utcdate utchour region netgen
order ID utcdate utchour region netgen
gen month = month(utcdate)
keep if month >=$monthlow & month <=$monthhigh
append using $temp6
save $temp6, replace
} // end region loop

** generate nuke, sun, wind, water generation variables by balancing authority (but need to keep region tag)
use "data/Hourly_Balancing_load22.dta", clear
keep bacode utcdate utchour gensun genwind gennuke genwater region
keep if utchour==`thehour'

*DROP 2022 FOR NOW, BRING IN ONCE FINAL DATA VAILABLE
capture drop year
gen year = year(utcdate)
keep if year<2022
drop year


reshape long gen,i(bacode utcdate utchour region) j(Fuel)string
gen ID = bacode + "_All_"+ Fuel
rename gen netgen
keep ID utcdate utchour region netgen bacode
order ID utcdate utchour region netgen bacode
gen month = month(utcdate)
keep if month >=$monthlow & month <= $monthhigh
append using $temp6
recode netgen .=0
** merge in flagged hours where eia 930 agg data not reliable 
*Should we add nogen keep(3) here?
merge m:1 region utcdate utchour using $temp2

replace netgen=. if flag
drop flag
** drop aggregated generation units that do not have any generation during the months of interest
egen aggnetgen = sum(netgen), by(ID)
drop if aggnetgen == 0
save $temp6, replace



*** bring in CEMS Plant data
use $temp4, clear
tostring PLANT, gen(ID)
replace ID = ID + "_" + unitid


*DROP 2022 FOR NOW, BRING IN ONCE FINAL DATA VAILABLE
capture drop year
gen year = year(utcdate)
keep if year<2022

keep ID utcdate utchour region netgen PLANT unitid bacode
order ID utcdate utchour region netgen PLANT unitid bacode
append using $temp6

* look at residuals
keep  if strpos(ID,"Resid")>0

save $temp10, replace
use $temp10, clear
gen netgensqr = netgen*netgen
collapse (sum) netgensqr, by(bacode)
merge 1:1 bacode using "data/BalancingAuthority_Region_crosswalk21.dta", nogen keep(1 3)
collapse (sum) netgensq, by(region)
sort netgensqr
kfahfhadhf


** generate idnum to track units 
sort ID utcdate utchour
egen idnum = group(ID)
drop month
save "data/hourly22/Hourly_Unit_and_Regional_Generation`thehour'.dta", replace

* create plant unit num to idnum crosswalk
keep ID PLANT unitid idnum
duplicates drop
replace PLANT= idnum*100 if PLANT==.
* save hour specific crosswalk
save "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", replace

/*
** make list of units that were put into the residual
use $temp10, clear

*gen index = 1 if totsummerpos >= $numobsneed
*collapse(sum) netgen , by (index)

keep if totsummerpos < $numobsneed
gen month = month(utcdate)
keep if month >= $monthlow & month <= $monthhigh
collapse (sum) netgen , by(PLANT unitid region Fuel)
save "data/hourly22/plants_in_residual`thehour'.dta", replace
*/
* end each thehour
}


