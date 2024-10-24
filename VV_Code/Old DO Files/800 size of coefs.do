*foreach level in sub inter region balance {
	
clear
save $temp3, emptyok replace
	
foreach level in inter region balance sub  {

	
foreach thehour in $hoursAll {
dis "hour `thehour'"
		
use "data/cems_units_fuel_19-22.dta", clear
qui drop yr
qui duplicates drop
* plants with num >1 switched fuel
bysort PLANT unitid: egen num=count(Fuel)
* almost all switched to gas
qui replace Fuel="Gas" if num==2
qui duplicates drop
* only 60589 stays because it doesn't have a "source" for one year
qui drop if PLANT==60589 & Source==""

qui merge m:1 PLANT unitid using "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", nogen keep (2 3)

qui merge 1:1 idnum using "data/hourly22/coefsconstrained_`level'`thehour'.dta", nogen keep(2 3)

/*
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
*/


foreach var of varlist btilda* {
qui replace `var'=0 if `var' <0.75
qui replace `var'=0 if `var'==.
}

*foreach var of varlist btilda*{
*	tab ID if `var'> 0.7
*}
egen sum = rowtotal(btilda*)
keep if sum > 0.7
gen hour = `thehour'
gen level = "`level'"
drop num Source 
order PLANT unitid Fuel ID idnum hour level
append using $temp3
save $temp3, replace
}
}
