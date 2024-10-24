import excel using "$rawreg/eia860/3_1_Generator_Y2021.xlsx", first cellrange(A2) sheet(Operable) clear
rename *, lower
keep plantcode nameplatecapacitymw energysource1
gen solarmw = nameplatecapacitymw * (energysource1=="SUN")
gen windmw = nameplatecapacitymw * (energysource1=="WND")
collapse (sum) solarmw windmw, by(plantcode)
drop if plantcode==.
save $temp, replace

import excel using "$rawreg/egrid/eGRID2021_data.xlsx", first cellrange(A2) sheet(PLNT21) clear
rename *, lower
keep orispl fipsst fipscnty
rename orispl plantcode
gen fips = real(fipsst)*1000+real(fipscnty)
keep plantcode fips 
duplicates drop
merge 1:1 plantcode using $temp, keep(3) nogen
* none of the plants missing fips have solar or wind capacity
collapse (sum) solarmw windmw, by(fips)
save "data/county solar wind capacity.dta", replace
*end
