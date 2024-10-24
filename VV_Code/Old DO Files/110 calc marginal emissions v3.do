if 1 {

* egrid data. Use 2021 first, then older data to replace any missing (for example plant 2076 is only active in 2019)

import excel "../rawdata/egrid/egrid2021_data.xlsx", firstrow cellrange(A2) sheet(PLNT21) clear
rename * , lower
*nox and so2 in lbs per mwh
*co2 and in lbs/mwh
keep orispl plnoxrta plso2rta plco2rta plfuelct
* change co2 to tons/mwh
replace plco2rta = plco2rta/2000
rename plnoxrta noxrate
rename plso2rta so2rate
rename plco2rta co2rate
rename orispl plant
rename plfuelct egridfuel
gen mergefuel = "Other"
replace mergefuel = "Coal" if egridfuel=="COAL"
replace mergefuel = "Gas" if egridfuel=="GAS"
save $temp4, replace

*egridfuel noxrate so2rate co2rate mergefuel

import excel using "../rawdata/egrid/egrid2020_data.xlsx", clear sheet(PLNT20) cellrange(A2) first
rename * , lower
*nox and so2 in lbs per mwh
*co2 and in lbs/mwh
keep orispl plnoxrta plso2rta plco2rta plfuelct
* change co2 to tons/mwh
replace plco2rta = plco2rta/2000
rename plnoxrta noxrate
rename plso2rta so2rate
rename plco2rta co2rate
rename orispl plant
rename plfuelct egridfuel
gen mergefuel = "Other"
replace mergefuel = "Coal" if egridfuel=="COAL"
replace mergefuel = "Gas" if egridfuel=="GAS"
merge 1:1 plant using $temp4, update nogen
save $temp4, replace

import excel using "../rawdata/egrid/egrid2019_data.xlsx", clear sheet(PLNT19) cellrange(A2) first
rename * , lower
*nox and so2 in lbs per mwh
*co2 and in lbs/mwh
keep orispl plnoxrta plso2rta plco2rta plfuelct
* change co2 to tons/mwh
replace plco2rta = plco2rta/2000
rename plnoxrta noxrate
rename plso2rta so2rate
rename plco2rta co2rate
rename orispl plant
rename plfuelct egridfuel
gen mergefuel = "Other"
replace mergefuel = "Coal" if egridfuel=="COAL"
replace mergefuel = "Gas" if egridfuel=="GAS"
merge 1:1 plant using $temp4, update nogen
save $temp4, replace

}





use "data/cems_units_fuel_19-22.dta", clear 
rename *, lower 

bysort plant unitid: egen minyr = min(yr)

** keep first year for each plant. 
keep if yr == minyr
rename fuel cemsfuel
egen anygas=max(cemsfuel=="Gas"),by(plant)
egen anycoal=max(cemsfuel=="Coal"),by(plant)
egen anyother=max(cemsfuel=="Other"),by(plant)
egen numfuel=rsum(any*)
gen mergefuel = cemsfuel if numfuel==1
merge m:1 plant mergefuel using $temp4, keep(1 3) nogen
order plant unitid cemsfuel egridfuel so2rate noxrate co2rate
encode egridfuel, gen(fuel2) 
table fuel2, stat(mean so2rate) stat( median so2rate) 
table fuel2, stat(mean co2rate) stat( median co2rate) 
table fuel2, stat(mean noxrate) stat( median noxrate) 
** this is based only on single fuel plants, median rate from egrid
** fill in multifuel plants
foreach e in so2 nox co2 {
	egen med`e'rate = median(`e'rate), by (mergefuel)
	gsort cemsfuel -mergefuel
	replace med`e'rate= med`e'rate[_n-1] if cemsfuel==cemsfuel[_n-1] & med`e'rate==.
	gen w`e'rate = `e'rate 
	winsor2 w`e'rate if `e'rate<., cuts(10 90) replace
	replace w`e'rate = med`e'rate if numfuel>1
}
keep plant unitid cemsfuel w*rate
save "data/plant_unit_marginal_emissions22.dta", replace
