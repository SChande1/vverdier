global scc=50

foreach thehour in $hoursShort{

foreach level in inter region balance sub{

clear
save $temp6, emptyok replace

foreach case in con uncon{
	
** first calculate weighted average damages for plants in residual
		** check this merge: a few cemsfuel different from fuel in residual plant list (fuel created in 110 vs fuel created in 70)
use "data/plant_unit_marginal_emissions22.dta", clear
rename plant PLANT
rename cemsfuel Fuel
merge 1:1 PLANT unitid Fuel using  "data/hourly22/plants_in_residual`thehour'.dta", nogen keep(3)
merge m:1 PLANT using "data/plant_pollution_damagesEPA22.dta", nogen keep(3)
gen mdco2 = $scc*0.907185
gen damnox = wnoxrate*mdnox
gen damso2 = wso2rate*mdso2
gen damco2 = wco2rate*mdco2
collapse (mean)  damnox damso2 damco2 [aweight=netgen], by (region Fuel)
replace Fuel = strlower(Fuel)
save $temp10, replace


** next bring in estimated coefficients and multiply to get damages
use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear
if "`case'"=="con" merge 1:1 idnum using "data/hourly22/coefsconstrained_`level'`thehour'_uni.dta", nogen keep(3)
if "`case'"=="uncon" merge 1:1 idnum using "data/hourly22/coefs_`level'`thehour'.dta", nogen keep(3)
keep if strpos(ID,"Resid")
gen regiontmp = ustrpos(ID,"_")
gen regiontmp2 = ustrrpos(ID,"_")
gen idlen=strlen(ID)
if "`case'"=="con" gen region = substr(ID,1,regiontmp-1)
gen Fuel = substr(ID,regiontmp2+1,idlen)
merge 1:m region Fuel using $temp10, nogen keep(3)
drop regiontmp regiontmp2 idlen

if "`case'"=="con" & "`level'"=="region"{
foreach reg in $AllRegions {
	gen nox`reg'=damnox*btilda`reg'
	gen so2`reg'=damso2*btilda`reg'
	gen co2`reg'=damco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="region"{
foreach reg in $AllRegions {
	gen nox`reg'=damnox*bnetgendemand`reg'
	gen so2`reg'=damso2*bnetgendemand`reg'
	gen co2`reg'=damco2*bnetgendemand`reg'
}
}

if "`case'"=="con" & "`level'"=="inter"{
foreach reg in Texas West East {
	gen nox`reg'=damnox*btilda`reg'
	gen so2`reg'=damso2*btilda`reg'
	gen co2`reg'=damco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="inter"{
foreach reg in Texas West East {
	gen nox`reg'=damnox*bnetgendemand`reg'
	gen so2`reg'=damso2*bnetgendemand`reg'
	gen co2`reg'=damco2*bnetgendemand`reg'
}
}

if "`case'"=="con" & "`level'"=="balance"{
foreach reg in $AllBAcodes {
	gen nox`reg'=damnox*btilda`reg'
	gen so2`reg'=damso2*btilda`reg'
	gen co2`reg'=damco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="balance"{
foreach reg in $AllBAcodes {
	gen nox`reg'=damnox*bnetgendemand`reg'
	gen so2`reg'=damso2*bnetgendemand`reg'
	gen co2`reg'=damco2*bnetgendemand`reg'
}
}

if "`case'"=="con" & "`level'"=="sub"{
foreach reg in $AllsubBAcodes {
	gen nox`reg'=damnox*btilda`reg'
	gen so2`reg'=damso2*btilda`reg'
	gen co2`reg'=damco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="sub"{
foreach reg in $AllsubBAcodes {
	gen nox`reg'=damnox*bnetgendemand`reg'
	gen so2`reg'=damso2*bnetgendemand`reg'
	gen co2`reg'=damco2*bnetgendemand`reg'
}
}


if "`level'"=="region" collapse (sum) noxCAL - co2TEX
if "`level'"=="inter" collapse (sum) noxTexas - co2East
if "`level'"=="balance" collapse (sum) noxAEC - co2ERCO
if "`level'"=="sub" collapse (sum) noxAEC - co2WEST
save $temp10, replace


** now repeat for plants not in the residual

use "data/plant_unit_marginal_emissions22.dta", clear
rename plant PLANT
merge m:1 PLANT using "data/plant_pollution_damagesEPA22.dta" ,nogen keep(1 3)
merge 1:1 PLANT unitid using "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta",nogen keep ( 3)
if "`case'"=="con" merge 1:1 idnum using "data/hourly22/coefsconstrained_`level'`thehour'_uni.dta", nogen keep (1 2 3)
if "`case'"=="uncon" merge 1:1 idnum using "data/hourly22/coefs_`level'`thehour'.dta", nogen keep (1 2 3)

* nox (and so2) damages are nox rate (lbs/mwh) * mdnox ($/lbs) * coefficent (mwh/mwh)
* md co2 d scc$/metric ton * 0.907185 metric ton/short ton  = $/short ton
* co2 damages are co2 rate (short tons/mwh) * mdco2 $/short ton * coefficent (mwh/mwh)
gen mdco2 =$scc*0.907185

if "`case'"=="con" & "`level'"=="region"{
foreach reg in $AllRegions{
	gen nox`reg'=wnoxrate*mdnox*btilda`reg'
	gen so2`reg'=wso2rate*mdso2*btilda`reg'
	gen co2`reg'=wco2rate*mdco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="region"{
foreach reg in $AllRegions{
	gen nox`reg'=wnoxrate*mdnox*bnetgendemand`reg'
	gen so2`reg'=wso2rate*mdso2*bnetgendemand`reg'
	gen co2`reg'=wco2rate*mdco2*bnetgendemand`reg'
}
}
if "`case'"=="con" & "`level'"=="inter"{
foreach reg in Texas West East{
	gen nox`reg'=wnoxrate*mdnox*btilda`reg'
	gen so2`reg'=wso2rate*mdso2*btilda`reg'
	gen co2`reg'=wco2rate*mdco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="inter"{
foreach reg in Texas West East{
	gen nox`reg'=wnoxrate*mdnox*bnetgendemand`reg'
	gen so2`reg'=wso2rate*mdso2*bnetgendemand`reg'
	gen co2`reg'=wco2rate*mdco2*bnetgendemand`reg'
}
}	

if "`case'"=="con" & "`level'"=="balance"{
foreach reg in $AllBAcodes {
	gen nox`reg'=wnoxrate*mdnox*btilda`reg'
	gen so2`reg'=wso2rate*mdso2*btilda`reg'
	gen co2`reg'=wco2rate*mdco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="balance"{
foreach reg in $AllBAcodes {
	gen nox`reg'=wnoxrate*mdnox*bnetgendemand`reg'
	gen so2`reg'=wso2rate*mdso2*bnetgendemand`reg'
	gen co2`reg'=wco2rate*mdco2*bnetgendemand`reg'
}
}
if "`case'"=="con" & "`level'"=="sub"{
foreach reg in $AllsubBAcodes {
	gen nox`reg'=wnoxrate*mdnox*btilda`reg'
	gen so2`reg'=wso2rate*mdso2*btilda`reg'
	gen co2`reg'=wco2rate*mdco2*btilda`reg'
}
}
if "`case'"=="uncon" & "`level'"=="sub"{
foreach reg in $AllsubBAcodes {
	gen nox`reg'=wnoxrate*mdnox*bnetgendemand`reg'
	gen so2`reg'=wso2rate*mdso2*bnetgendemand`reg'
	gen co2`reg'=wco2rate*mdco2*bnetgendemand`reg'
}
}	


if "`level'"=="region" collapse (sum) noxCAL - co2TEX
if "`level'"=="inter" collapse (sum) noxTexas - co2East
if "`level'"=="balance" collapse (sum) noxAEC - co2ERCO
if "`level'"=="sub" collapse (sum) noxAEC - co2WEST
* add residual and nonresidual 
append using $temp10
if "`level'"=="region" collapse (sum) noxCAL - co2TEX
if "`level'"=="inter" collapse (sum) noxTexas - co2East
if "`level'"=="balance" collapse (sum) noxAEC - co2ERCO
if "`level'"=="sub" collapse (sum) noxAEC - co2WEST

if "`case'"=="con" gen constrained= 1
if "`case'"=="uncon" gen constrained=0
append using $temp6
save $temp6, replace

* end each case 
}

** make some maps

use $temp6, clear
drop co2* nox*
xpose, clear varname
gen n =_n
rename  v1 so2un
rename  v2 so2con
rename _varname `level'
replace `level' = subinstr(`level',"so2","",.)
save $temp,replace

use $temp6, clear
drop so2* nox*
xpose, clear varname
gen n =_n
rename  v1 co2un
rename  v2 co2con
rename _varname `level'
replace `level' = subinstr(`level',"co2","",.)
save $temp1,replace

use $temp6, clear
drop co2* so2*
xpose, clear varname
gen n =_n
rename  v1 noxun
rename  v2 noxcon
rename _varname `level'
replace `level' = subinstr(`level',"nox","",.)
save $temp2,replace

merge 1:1 n using $temp, nogen keep(3)
merge 1:1 n using $temp1, nogen keep(3)
drop if `level'=="constrained"
save $temp3, replace

use "$raw/Maps/US_County_LowRes_2013data_Stata11.dta", clear
drop if inlist(statefp,2,15) | statefp>56
gen fips = statefp*1000+countyfp
keep _ID fips

if "`level'"=="region" {
merge 1:1 fips using "data/fips_to_region_crosswalk.dta", nogen 
encode region,gen(regionn)
*replace region=reg_egrid if region==""
replace reg_egrid=region if reg_egrid==""
encode reg_egrid,gen(regionn2)
merge m:1 region using $temp3 
}
if "`level'"== "inter"{
merge 1:1 fips using "data/fips_to_region_crosswalk.dta", nogen 
gen inter="East"
replace inter="Texas" if region=="TEX"
replace inter="West" if inlist(region,"CAL","SW","NW")
merge m:1 inter using $temp3 
}

if "`level'"=="balance"{
merge 1:1 fips using "data/fips_to_region_crosswalk.dta", nogen 
rename balancingauthoritycode balance
merge m:1 balance using $temp3
* get rid of small negative numbers
replace co2con = 0.0001 if co2con < 0
}

if "`level'"=="sub"{
merge 1:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen 
rename subBA sub
merge m:1 sub using $temp3
* get rid of small negative numbers
replace co2con = 0.0001 if co2con < 0
}

if "`level'" !="sub" {
spmap co2con using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", id(_ID) osize(none ..) ndsize(none ..) fcolor(red*2 red*1 red*0.5 red*0.25 blue*0.05 blue*0.15 blue*0.25 blue*0.35 blue*0.45 blue*0.55 blue*0.65 blue*0.75 blue ) clmethod(custom) clbreaks(-2000 -700 -200 -70 0 10 20 25 30 35 40 80 700 1200) legend(on) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) 
graph export "Latex22/map_c02_con_`level'`thehour'.png", replace

spmap co2un using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", id(_ID) osize(none ..) ndsize(none ..) fcolor(red*2 red*1 red*0.5 red*0.25 blue*0.05 blue*0.15 blue*0.25 blue*0.35 blue*0.45 blue*0.55 blue*0.65 blue*0.75 blue ) clmethod(custom) clbreaks(-2000 -700 -200 -70 0 10 20 25 30 35 40 80 700 1200) legend(on) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) 
graph export "Latex22/map_c02_uncon_`level'`thehour'.png", replace

}

if "`level'"=="sub" {
spmap co2con using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", id(_ID) osize(none ..) ndsize(none ..) fcolor(green yellow red*2 red*1 red*0.5 red*0.25 blue*0.05 blue*0.15 blue*0.25 blue*0.35 blue*0.45 blue*0.55 blue*0.65 blue*0.75 blue cyan lime ) clmethod(custom) clbreaks(-80000 -10000 -2000 -700 -200 -70 0 10 20 25 30 35 40 80 700 1200 10000 80000) legend(on) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) 
graph export "Latex22/map_c02_con_sub`thehour'.png", replace

spmap co2un using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", id(_ID) osize(none ..) ndsize(none ..) fcolor(green yellow red*2 red*1 red*0.5 red*0.25 blue*0.05 blue*0.15 blue*0.25 blue*0.35 blue*0.45 blue*0.55 blue*0.65 blue*0.75 blue cyan lime )  clmethod(custom) clbreaks(-80000 -10000 -2000 -700 -200 -70 0 10 20 25 30 35 40 80 700 1200 10000 80000 ) legend(on) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49)))
graph export "Latex22/map_c02_uncon_sub`thehour'.png", replace
}


* end each level
}
* end each hour
}





