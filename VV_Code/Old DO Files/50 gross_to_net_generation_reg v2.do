***  before running this program run "globals_regular.do"

use  "../rawdata/CEMS/emissions_all_unit_allyears22.dta", clear
gen int yr=int(UTCDATE/10000)
gen month = int(UTCDATE/100)-int(UTCDATE/10000)*100
order PLANT unitid UTCDATE month UTCHOUR
save $temp1, replace


use $temp1, clear
merge m:1 PLANT unitid yr using "data/cems_units_fuel_19-22.dta", keep(1 3) nogen
collapse (sum) CO2MASS NOXMASS SO2MASS GLOAD , by(PLANT Fuel yr month)
save $temp2, replace

use "data/EIA923_2019_22.dta", clear
drop if inlist(FTYPE,"HYDRO","NUKE","SOLAR","WIND")
gen Fuel = "Other"	// Oil is in other because CEMS units only defined for coal, gas, and other
replace Fuel = "Coal" if FTYPE == "COAL"
replace Fuel = "Gas" if FTYPE == "GAS"
collapse (sum) NGEN ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 (mean) ccgt, by (PLANT Fuel yr)
reshape long ngen, i (PLANT Fuel  yr) j(month)

merge 1:1 PLANT Fuel month yr using $temp2, keep(3) nogen

save $temp3, replace

use $temp3, clear
rename CO2MASS Cmass
rename SO2MASS Smass
rename NOXMASS Nmass
rename GLOAD Gmass

egen annualNgen= sum(ngen), by (PLANT Fuel)
egen annualNgenF= sum(ngen), by ( Fuel)
foreach info in C S N G {
gen `info'ratio = ngen/`info'mass
* average by plant fuel 
egen annual`info' = sum(`info'mass), by (PLANT Fuel)
gen  annual`info'Ratio = annualNgen/annual`info'
* average by fuel 
egen annual`info'F = sum(`info'mass), by ( Fuel)
gen  annual`info'RatioF = annualNgenF/annual`info'F
replace `info'ratio = annual`info'Ratio if ngen<=0 
replace `info'ratio = annual`info'RatioF if annual`info'Ratio<=0
winsor2 `info'ratio, by(Fuel) replace cuts(10 90)
}
keep PLANT Fuel month yr Cratio Sratio Nratio Gratio
save "data/gross_to_net_generation22.dta", replace


 




