
*** plot all coefficents for each fuel for each level



foreach level in region  {

clear
save $temp3, emptyok replace

	
*foreach thehour in $hoursAll {
foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 {
		
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

merge 1:1 idnum using "data/hourly22/coefsconstrained_`level'`thehour'.dta", nogen keep(2 3)

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


collapse (sum) btilda*, by (Fuel)

keep Fuel btildaTEX

*foreach sub in $AllsubBAcodes {
*replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
*}

gen utchour=`thehour'
append using $temp3
save $temp3, replace
* end $hoursAll
}



clear
save $temp4, emptyok replace

	
*foreach thehour in $hoursAll {
foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16{
		
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

merge 1:1 idnum using "data/hourly22/coefsconstrained_`level'`thehour'_fullweather_texonly.dta", nogen keep(2 3)

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


collapse (sum) btilda*, by (Fuel)

keep Fuel btildaTEX

*foreach sub in $AllsubBAcodes {
*replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
*}

gen utchour=`thehour'
append using $temp4
save $temp4, replace
* end $hoursAll
}
rename btildaTEX btildaTex_fullweather

merge 1:1  Fuel utchour using $temp3

	
fdahfds

capture graph drop gr*

foreach fuel in Coal Gas Hydro Nuke Other Sun Trade Wind{
use $temp3, clear


/* need different way to calculate local hour- columns are btildaCOAS, btildaEAST and so on. So hours will be different for different columns... perhaps leave in utchour
capture drop localhour
gen localhour = utchour
if inlist("`reg'","CAR","FLA","MIDA","NE","NY","SE","TEN") replace localhour = localhour - 4 
if inlist("`reg'","MIDW","CENT","TEX") replace localhour = localhour  - 5
if inlist("`reg'","SW") replace localhour = localhour - 6
if inlist("`reg'","CAL","NW") replace localhour = localhour - 7
replace localhour = localhour + 24 if localhour < 1
sort localhour 
 */

capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 5
replace localhour = localhour + 24 if localhour < 1
sort localhour

keep if Fuel == "`fuel'"

reshape long btilda, i(localhour) j(name) string 


scatter btilda localhour  , msize (tiny)	graphregion(color(white)) title("`fuel'") xtitle("Local Hour")	ytitle("Coefficient") name(gr`fuel') xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))


				
}																					
graph combine grCoal grGas grHydro grNuke grSun grWind grTrade grOther
graph export "latex22/fuel_scatter`level'_temp.png", replace																						
																						
}																						
																						
	