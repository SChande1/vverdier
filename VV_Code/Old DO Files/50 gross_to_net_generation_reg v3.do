do "00 globals-regular.do"

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

collapse (sum) GLOAD Cmass Smass Nmass ngen, by(PLANT Fuel)

capture drop Gratio
gen Gratio = ngen/GLOAD
winsor2 Gratio, by(Fuel) replace cuts(20 80)
replace Gratio = 1 if Gratio>1

foreach info in C S N {
	capture drop `info'ratio
	gen `info'ratio = `info'mass/ngen
	winsor2 `info'ratio, by(Fuel) replace cuts(20 80)
}

keep PLANT Fuel Cratio Sratio Nratio Gratio

save "data/gross_to_net_generation22_new.dta", replace

*end

 




