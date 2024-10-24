

* first compare sum of sub loads to balancing load
use "data/Hourly_Sub_Load", clear
keep if region=="TEX"
gen month=month(utcdate)
keep if month>=6 & month<=9
reshape wide demand, i(utcdate utchour) j(subregion) string
save $temp10, replace

use "data/Hourly_Balancing_Load.dta"
keep if region=="TEX"
gen month=month(utcdate)
keep if month>=6 & month<=9
keep demand utcdate utchour
merge 1:1 utcdate utchour using $temp10, nogen keep(3)
gen demandtot=demandCOAS + demandEAST + demandFWES + demandNCEN + demandNRTH + demandSCEN + demandSOUT + demandWEST
gen diff = demand-demandtot
sum diff
line demand demandtot


* nowcompare weighted ave of subba coefs to ba coefs by fuel

use "data/Hourly_Sub_Load", clear
keep if region=="TEX"
gen month=month(utcdate)
keep if month>=6 & month<=9
collapse (mean) demand, by (subregion utchour)
reshape wide demand, i(utchour) j(subregion) string
save $temp10, replace

use "data/Hourly_Balancing_Load.dta"
keep if region=="TEX"
gen month=month(utcdate)
keep if month>=6 & month<=9



use "data/coefs_fuel_sub.dta", clear
keep if case == "con"
keep Fuel utchour btildaCOAS btildaEAST btildaFWES btildaNCEN btildaNRTH btildaSCEN btildaSOUT btildaWEST
merge m:1 utchour using $temp10

gen sumdemand = demandCOAS + demandEAST + demandFWES + demandNCEN + demandNRTH + demandSCEN + demandSOUT + demandWEST
foreach var in COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
	gen weighted`var'= btilda`var'* demand`var'
}

gen weightedave= (weightedCOAS + weightedEAST + weightedFWES + weightedNCEN + weightedNRTH + weightedSCEN + weightedSOUT + weightedWEST)/sumdemand
keep Fuel utchour weightedave
save $temp9, replace


use "data/coefs_fuel_balance", clear
keep if case=="con"
keep utchour Fuel btildaERCO
merge 1:1 Fuel utchour using $temp9, nogen keep(3)
save $temp8, replace
* check, should be the same for ERCO and TEX
use "data/coefs_fuel_region", clear
keep if case=="con"
keep utchour Fuel btildaTEX
merge 1:1 Fuel utchour using $temp8, nogen keep(3)

label var btildaTEX "TEX estimates"
label var weightedave "Weighted Average of TEX subregions"
gen t=_n
twoway (line btildaTEX t) (line weightedave t)
