


capture graph drop gr*

foreach level in inter region balance sub {
	use "data/coefs_fuel_`level'22.dta", clear
keep if inlist(Fuel,"Coal","Gas")
 collapse (sum) btilda*, by (case utchour)
reshape long btilda, i(case utchour) j(`level') string
*two (histogram btilda if case=="con", color(red%50) frequency) ( histogram btilda if case=="uncon", color(blue%50) frequency), legend(order(1 "Regular" 2 "OLS")) graphregion(color(white)) xtitle("Coal + Gas Coefficient") title("Region")
histogram btilda if case=="uncon", color(red%50) percent title("OLS `level'") graphregion(color(white)) name(grols`level') xtitle("Coal + Gas Coefficient")
histogram btilda if case=="con", color(red%50) percent title("Regular `level'") graphregion(color(white)) name(greg`level') xtitle("Coal + Gas Coefficient")
	
} 
 graph combine grolsinter greginter grolsregion gregregion , cols(2)
 graph export "latex22/fossilcoeffdensity1.png", replace
 graph combine grolsbalance gregbalance grolssub gregsub, cols(2)
 graph export "latex22/fossilcoeffdensity2.png", replace


 
 
 
 
 
 use "data/coefs_fuel_inter22.dta", clear
 merge 1:1 case utchour Fuel using "data/coefs_fuel_region22.dta"
 
 twoway (line btildaCAL utchour if Fuel=="Coal" & case=="con") (line btildaSW utchour if Fuel=="Coal"& case=="con" ) (line btildaNW utchour if Fuel=="Coal" & case=="con") (line btildaWest utchour if Fuel=="Coal" & case=="con")
 
gen sqdev = (btildaCAL - btildaWest)^2 + (btildaNW - btildaWest)^2 + (btildaSW - btildaWest)^2
line sqdev utchour if Fuel=="Coal" & case=="con"


 
 keep if inlist(Fuel,"Coal","Gas")
 collapse (sum) btildaEast btildaWest btildaTexas, by (case utchour)
 reshape long btilda, i(case utchour) j(inter) string

 two (histogram btilda if case=="con", color(red%50) frequency) ( histogram btilda if case=="uncon", color(blue%50) frequency), legend(order(1 "Regular" 2 "OLS")) graphregion(color(white)) xtitle("Coal + Gas Coefficient") title("Interconnection")

 
 
use "data/coefs_fuel_region22.dta", clear
keep if inlist(Fuel,"Coal","Gas")
 collapse (sum) btilda*, by (case utchour)
reshape long btilda, i(case utchour) j(region) string
two (histogram btilda if case=="con", color(red%50) frequency) ( histogram btilda if case=="uncon", color(blue%50) frequency), legend(order(1 "Regular" 2 "OLS")) graphregion(color(white)) xtitle("Coal + Gas Coefficient") title("Region")
histogram btilda if case=="con", color(red%50) frequency
histogram btilda if case=="uncon", color(blue%50) frequency





use "data/coefs_fuel_balance22.dta", clear
keep if inlist(Fuel,"Coal","Gas")
 collapse (sum) btilda*, by (case utchour)
reshape long btilda, i(case utchour) j(balance) string
histogram btilda if case=="con", color(red%50) frequency
histogram btilda if case=="uncon", color(blue%50) frequency


two (histogram btilda if case=="con", color(red%50) frequency) ( histogram btilda if case=="uncon", color(blue%50) frequency), legend(order(1 "Regular" 2 "OLS")) graphregion(color(white)) xtitle("Coal + Gas Coefficient") title("Region")


use "data/coefs_fuel_sub22.dta", clear
keep if inlist(Fuel,"Coal","Gas")
 collapse (sum) btilda*, by (case utchour)
reshape long btilda, i(case utchour) j(sub) string
histogram btilda if case=="con", color(red%50) frequency
histogram btilda if case=="uncon", color(blue%50) frequency

two (histogram btilda if case=="con", color(red%50)) ( histogram btilda if case=="uncon", color(blue%50)), legend(order(1 "Regular" 2 "OLS")) graphregion(color(white)) xtitle("Coal + Gas Coefficient") title("Region")
