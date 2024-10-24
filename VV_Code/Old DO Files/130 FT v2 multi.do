
** graph of regional loads in the east interconnection
use "data/Hourly_Regional_Load_Generation22.dta", clear
order region utctime date utchour
sort region utctime date utchour
gen month = month(utcdate)
gen yr = year(utcdate)
keep if yr==2019
* trim data for now
**** just do hour 17 in summer 
keep if month >=5 & month <=9  
* utc hour 21 is 5pm in new york
keep if utchour ==21
bysort region: gen num = _n

*CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX

twoway (line demand num if region =="CAR" ) ( line demand num if region=="CENT") ( line demand num if region=="FLA") (line demand num if region =="MIDA" ) ( line demand num if region=="MIDW") ( line demand num if region=="NE") (line demand num if region =="NY" ) ( line demand num if region=="SE") ( line demand num if region=="TEN"), xtitle("Date") ytitle("Electricity Load (MWh)") legend( symxsize(4) region(lwidth(none)) pos(3) col(1) label(1 "Carolinas") label(2 "Central") label(3 "Florida") label(4 "MidAtlantic") label(5 "MidWest") label(6 "New England") label(7 "New York") label(8 "SouthEast") label(9 "Tennessee")) graphregion(color(white))

graph export "latex22/EastRegionalLoads.png", replace


** Table of marginal fuel type by region
use "data/coefs_fuel_region22.dta", clear
keep if utchour==23

capture file close myfile
file open myfile using "latex22/table-fuel-type_uncon23.tex", write replace

foreach beta in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX {
if "`beta'"=="CAL" file write myfile "California" 
if "`beta'"=="CAR" file write myfile "Carolinas" 
if "`beta'"=="CENT" file write myfile "Central" 
if "`beta'"=="FLA" file write myfile "Florida"
if "`beta'"=="MIDA" file write myfile "MidAtlantic" 
if "`beta'"=="MIDW" file write myfile "MidWest"
if "`beta'"=="NE" file write myfile "New England" 
if "`beta'"=="NW" file write myfile "North West"
if "`beta'"=="NY" file write myfile "New York"
if "`beta'"=="SE" file write myfile "SouthEast" 
if "`beta'"=="SW" file write myfile "SouthWest"
if "`beta'"=="TEN" file write myfile "Tennessee" 
if "`beta'"=="TEX" file write myfile "Texas"

foreach n in 1 2 3 4 5 6 7 8 {
file write myfile " & "  %4.3fc (btilda`beta'[`n'])
}
file write myfile "\\" _n
}
capture file close myfile

capture file close myfile
file open myfile using "latex22/table-fuel-type_con23.tex", write replace

foreach beta in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX {
if "`beta'"=="CAL" file write myfile "California" 
if "`beta'"=="CAR" file write myfile "Carolinas" 
if "`beta'"=="CENT" file write myfile "Central" 
if "`beta'"=="FLA" file write myfile "Florida"
if "`beta'"=="MIDA" file write myfile "MidAtlantic" 
if "`beta'"=="MIDW" file write myfile "MidWest"
if "`beta'"=="NE" file write myfile "New England" 
if "`beta'"=="NW" file write myfile "North West"
if "`beta'"=="NY" file write myfile "New York"
if "`beta'"=="SE" file write myfile "SouthEast" 
if "`beta'"=="SW" file write myfile "SouthWest"
if "`beta'"=="TEN" file write myfile "Tennessee" 
if "`beta'"=="TEX" file write myfile "Texas" 
foreach n in 9 10 11 12 13 14 15 16  {
file write myfile " & "  %4.3fc (btilda`beta'[`n'])
}
file write myfile "\\" _n
}
capture file close myfile



**** graph of wind coeficient in Texas interconnection by hour
**** graph of all fuels coefficients in Texas by hour

clear
save $temp3, emptyok replace
foreach case in con uncon  {
foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24{
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

if "`case'"=="con"{
	merge 1:1 idnum using "data/hourly22/coefsconstrained_inter`thehour'.dta", nogen keep(2 3)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "data/hourly22/coefs_inter`thehour'.dta", nogen keep(2 3)
}
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

if "`case'"=="con"{
collapse (sum) btilda*, by (Fuel)
foreach reg in East West Texas{
replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
}
}
if "`case'"=="uncon"{
collapse (sum) bnetgendemand*, by (Fuel)
foreach reg in East West Texas{
replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
rename bnetgendemand`reg' btilda`reg'
}
}
gen case ="`case'"
gen utchour=`thehour'
append using $temp3
save $temp3, replace
}
}
line btildaTexas utchour if case=="con" & Fuel=="Wind"  , graphregion(color(white)) xtitle("UTC Hour (Dallas local time + 5/6 hours)") ytitle("Coefficient of Wind generation")

twoway (line btildaTexas utchour if case=="con" & Fuel=="Wind")  (line btildaTexas utchour if case=="con" & Fuel=="Gas") (line btildaTexas utchour if case=="con" & Fuel=="Coal") , graphregion(color(white)) xtitle("UTC Hour (Dallas local time + 5/6 hours)") ytitle("Marginal generation share") legend(label(1 "Wind") label(2 "Gas") label(3 "Coal"))



**** graph of all fuel coefficients in region by hour

clear
save $temp3, emptyok replace
foreach case in con uncon  {
foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24{
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

if "`case'"=="con"{
	merge 1:1 idnum using "data/hourly22/coefsconstrained_region`thehour'.dta", nogen keep(2 3)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "data/hourly22/coefs_region`thehour'.dta", nogen keep(2 3)
}
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

if "`case'"=="con"{
collapse (sum) btilda*, by (Fuel)
foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
}
}

if "`case'"=="uncon"{
collapse (sum) bnetgendemand*, by (Fuel)
foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
rename bnetgendemand`reg' btilda`reg'
}
}
gen case ="`case'"
gen utchour=`thehour'
append using $temp3
save $temp3, replace
}
}
*** add last four fuels into remainder
replace Fuel = "remainder" if inlist(Fuel,"Hydro","Nuke","Other","Trade")
collapse (sum) btilda*, by (utchour case Fuel)

foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
*foreach reg in SW {

capture drop btildamin
capture drop btildamax 
egen btildamin = min(btilda`reg' * (case=="uncon"))
egen btildamax = max(btilda`reg' * (case=="uncon"))
replace btildamax = max(1,btildamax)
global max =btildamax[1]
global min =btildamin[1]

capture drop localhour
gen localhour = utchour
if inlist("`reg'","CAR","FLA","MIDA","NE","NY","SE","TEN") replace localhour = localhour - 4 
if inlist("`reg'","MIDW","CENT","TEX") replace localhour = localhour  - 5
if inlist("`reg'","SW") replace localhour = localhour - 6
if inlist("`reg'","CAL","NW") replace localhour = localhour - 7
replace localhour = localhour + 24 if localhour < 1
sort localhour

capture graph drop gr*

*scatter btilda`reg' utchour if case=="con" & Fuel=="Wind"  , graphregion(color(white)) xtitle("UTC Hour") ytitle("Coefficient of Wind generation") title("`reg' Region")

global gropts graphregion(color(white)) xtitle("Hour ") ytitle("Marginal generation share") legend(off)

twoway (line btilda`reg' localhour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btilda`reg' localhour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("Regularized") name(grcon) xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))

twoway (line btilda`reg' localhour if case=="uncon" & Fuel=="Wind", lcolor(green) lwidth(thick))  (line btilda`reg' localhour if case=="uncon" & Fuel=="Gas",lcolor(sienna) lwidth(thick)) (line btilda`reg' localhour if case=="uncon" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`reg' localhour if case=="uncon" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("OLS") name(gruncon) xlabel(1 6 12 18 24) ylabel(, angle(0)) yscale(range($min $max)) //ylabel(-2.1 -1 0 1 2 2.8, angle(0))

global grcombopts graphregion(color(white) margin(zero zero zero zero)) name(temp, replace)
if "`reg'"=="CAL" graph combine  grcon gruncon, title("California") $grcombopts
if "`reg'"=="CAR" graph combine  grcon gruncon, title("Carolinas") $grcombopts
if "`reg'"=="CENT" graph combine  grcon gruncon, title("Central") $grcombopts
if "`reg'"== "FLA" graph combine  grcon gruncon, title("Florida") $grcombopts
if "`reg'"=="MIDA" graph combine  grcon gruncon, title("MidAtlantic") $grcombopts
if "`reg'"=="MIDW" graph combine  grcon gruncon, title("MidWest") $grcombopts
if "`reg'"=="NE" graph combine  grcon gruncon, title("New England") $grcombopts
if "`reg'"=="NW" graph combine  grcon gruncon, title("North West") $grcombopts
if "`reg'"=="NY" graph combine  grcon gruncon, title("New York") $grcombopts
if "`reg'"=="SE" graph combine  grcon gruncon, title("SouthEast") $grcombopts
if "`reg'"=="SW" graph combine  grcon gruncon, title("SouthWest") $grcombopts
if "`reg'"=="TEN" graph combine grcon gruncon, title("Tennessee") $grcombopts
if "`reg'"=="TEX" graph combine grcon gruncon, title("Texas") $grcombopts
graph display temp, xsize(5) ysize(2)
graph export "latex22/fig-fuel-coefs`reg'.png", replace
}
** legend only 
twoway (line btildaTEX utchour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btildaTEX utchour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), graphregion(color(white)) legend(label(1 "Wind") label(2 "Gas") label(3 "Coal") label(4 "Sun") label(5 "Other") col(1) size(14pt))
graph export "latex22/fig-fuel-coefsLEGEND.png", replace



*** compare with SPP data for "fuel on the margin"

use "data/sppwind.dta", clear
replace hour = hour+1
save $temp4, replace
use "data/sppwindw.dta", clear
replace hour = hour+1
save $temp5, replace

use $temp3, clear
keep btildaCENT utchour case Fuel
keep if case=="con" & Fuel=="Wind"
rename utchour hour
merge 1:1 hour using $temp4, nogen keep(3)
merge 1:1 hour using $temp5, nogen keep(3)
rename hour utchour

twoway (line wind utchour) (line btildaCENT utchour) (line windw utchour), ///
legend(label(1 "SPP reported 2019") label(2 "Estimated 2019-2021") label(3 "SPP reported 2019 (weighted)")) ///
 ytitle("SPP (CENT) Wind Percent Marginal") xtitle("UCT Hour") graphregion(color(white))

 
 
 
**** Texas subBA graphs for marginal generation by fuel


clear
save $temp3, emptyok replace
foreach case in con uncon  {
foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24{
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

if "`case'"=="con"{
	merge 1:1 idnum using "data/hourly22/coefsconstrained_sub`thehour'.dta", nogen keep(2 3)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "data/hourly22/coefs_sub`thehour'.dta", nogen keep(2 3)
}
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


if "`case'"=="con"{
keep Fuel btildaCOAS btildaEAST btildaFWES btildaNCEN btildaNRTH btildaSCEN btildaSOUT btildaWEST

collapse (sum) btilda*, by (Fuel)
foreach sub in COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
}
}

if "`case'"=="uncon"{
keep Fuel bnetgendemandCOAS bnetgendemandEAST bnetgendemandFWES bnetgendemandNCEN bnetgendemandNRTH bnetgendemandSCEN bnetgendemandSOUT bnetgendemandWEST

collapse (sum) bnetgendemand*, by (Fuel)
foreach sub in COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
replace bnetgendemand`sub' = 0 if abs(bnetgendemand`sub') < 0.00001
rename bnetgendemand`sub' btilda`sub'
}
}
gen case ="`case'"
gen utchour=`thehour'
append using $temp3
save $temp3, replace
}
}

*** add last four fuels into remainder
replace Fuel = "remainder" if inlist(Fuel,"Hydro","Nuke","Other","Trade")
collapse (sum) btilda*, by (utchour case Fuel)

foreach sub in COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
*foreach reg in SW {

capture drop btildamin
capture drop btildamax 
egen btildamin = min(btilda`sub' * (case=="uncon"))
egen btildamax = max(btilda`sub' * (case=="uncon"))
replace btildamax = max(1,btildamax)
global max =btildamax[1]
global min =btildamin[1]

capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 5
replace localhour = localhour + 24 if localhour < 1
sort localhour

capture graph drop gr*

*scatter btilda`reg' utchour if case=="con" & Fuel=="Wind"  , graphregion(color(white)) xtitle("UTC Hour") ytitle("Coefficient of Wind generation") title("`reg' Region")

global gropts graphregion(color(white)) xtitle("Hour ") ytitle("Marginal generation share") legend(off)

twoway (line btilda`sub' localhour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btilda`sub' localhour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("Regularized") name(grcon) xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))

twoway (line btilda`sub' localhour if case=="uncon" & Fuel=="Wind", lcolor(green) lwidth(thick))  (line btilda`sub' localhour if case=="uncon" & Fuel=="Gas",lcolor(sienna) lwidth(thick)) (line btilda`sub' localhour if case=="uncon" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`sub' localhour if case=="uncon" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`sub' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("OLS") name(gruncon) xlabel(1 6 12 18 24) ylabel(, angle(0)) yscale(range($min $max)) //ylabel(-2.1 -1 0 1 2 2.8, angle(0))

global grcombopts graphregion(color(white) margin(zero zero zero zero)) name(temp, replace)
if "`sub'"=="COAS" graph combine  grcon gruncon, title("Coast") $grcombopts
if "`sub'"=="EAST" graph combine  grcon gruncon, title("East") $grcombopts
if "`sub'"=="FWES" graph combine  grcon gruncon, title("Far West") $grcombopts
if "`sub'"== "NCEN" graph combine  grcon gruncon, title("North Central") $grcombopts
if "`sub'"=="NRTH" graph combine  grcon gruncon, title("North") $grcombopts
if "`sub'"=="SCEN" graph combine  grcon gruncon, title("South Central") $grcombopts
if "`sub'"=="SOUT" graph combine  grcon gruncon, title("South") $grcombopts
if "`sub'"=="WEST" graph combine  grcon gruncon, title("West") $grcombopts
graph display temp, xsize(5) ysize(2)
graph export "latex22/fig-fuel-coefs`sub'.png", replace
}
** legend only 
*twoway (line btildaTEX utchour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btildaTEX utchour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btildaTEX utchour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), graphregion(color(white)) legend(label(1 "Wind") label(2 "Gas") label(3 "Coal") label(4 "Sun") label(5 "Other") col(1) size(14pt))
*graph export "latex/fig-fuel-coefsLEGEND.png", replace
																						
	
	
**** All subBA graphs for marginal generation by fuel
**** don't do unconstrained case

clear
save $temp3, emptyok replace

foreach thehour in $hoursAll {
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

merge 1:1 idnum using "data/hourly22/coefsconstrained_sub`thehour'.dta", nogen keep(2 3)

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
foreach sub in $AllsubBAcodes {
replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
}


gen utchour=`thehour'
append using $temp3
save $temp3, replace
}

use $temp3, clear

*** add last four fuels into remainder
replace Fuel = "remainder" if inlist(Fuel,"Hydro","Nuke","Other","Trade")
collapse (sum) btilda*, by (utchour Fuel)

foreach sub in $AllsubBAcodes{
 
/*
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

capture graph drop gr*

global gropts graphregion(color(white)) xtitle("Hour ") ytitle("Marginal generation share") legend(off)

twoway (line btilda`sub' localhour if  Fuel=="Wind",lcolor(green) lwidth(thick))  (line btilda`sub' localhour if  Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btilda`sub' localhour if  Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`sub' localhour if  Fuel=="Sun", lcolor(yellow) lwidth(thick)) (line btilda`sub' localhour  if Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts title("`sub'") name(grcon) xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0)) 


graph export "latex22/subBA/fig-fuel-coefs`sub'.png", replace
}






*** plot all coefficents for each fuel for each level



foreach level in sub inter region balance {

clear
save $temp3, emptyok replace

	
foreach thehour in $hoursAll {
		
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



*foreach sub in $AllsubBAcodes {
*replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
*}

gen utchour=`thehour'
append using $temp3
save $temp3, replace
* end $hoursAll
}
		

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
																						
	
	
	

*** plot all coefficents for each fuel for sub only  at interconnection level



foreach level in sub  {
	foreach inter in East West Texas{

clear
save $temp3, emptyok replace

	
foreach thehour in $hoursAll {
		
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

if "`inter'"=="Texas"{
	foreach var in AEC CPLW SOCO  SC  FPC SEC FPL FMPP  NSB  DUK SCEG HST  AECI   TAL LGEE GVL CPLE TEC SPA TVA JEA 4001 4002 4003 4004 4005 4006 4007 4008 1 27 35 4 6 8910 ZONA ZONB ZONC ZOND ZONE ZONF ZONG ZONH ZONI ZONJ ZONK AE AEP AP ATSI BC CE DAY DEOK DOM DPL DUQ EKPC JC ME PE PEP PL PN PS  CSWS EDE GRDA INDN KACY KCPL LES MPS NPPD OKGE OPPD SECI SPRM SPS WAUE WFEC WR WAUW  DOPD BANC BPAT NWMT PNM PACW  SCL IID IPCO WALC  GCPD PGE PSEI TIDC NEVP  EPE AVA LDWP  SRP WACM TEPC CHPD PSCO AZPS TPWR PACE PGAE SCE SDGE VEA {
	drop btilda`var'
	}	
}

if "`inter'"=="East"{
	foreach var in WAUW  DOPD BANC BPAT NWMT PNM PACW  SCL IID IPCO WALC  GCPD PGE PSEI TIDC NEVP  EPE AVA LDWP  SRP WACM TEPC CHPD PSCO AZPS TPWR PACE PGAE SCE SDGE VEA COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
	drop btilda`var'
	}
}

if "`inter'"=="West"{ 
	foreach var in AEC CPLW SOCO  SC  FPC SEC FPL FMPP  NSB  DUK SCEG HST  AECI   TAL LGEE GVL CPLE TEC SPA TVA JEA 4001 4002 4003 4004 4005 4006 4007 4008 1 27 35 4 6 8910 ZONA ZONB ZONC ZOND ZONE ZONF ZONG ZONH ZONI ZONJ ZONK AE AEP AP ATSI BC CE DAY DEOK DOM DPL DUQ EKPC JC ME PE PEP PL PN PS  CSWS EDE GRDA INDN KACY KCPL LES MPS NPPD OKGE OPPD SECI SPRM SPS WAUE WFEC WR COAS EAST FWES NCEN NRTH SCEN SOUT WEST{
		drop btilda`var'
	}
}
collapse (sum) btilda*, by (Fuel)



*foreach sub in $AllsubBAcodes {
*replace btilda`sub' = 0 if abs(btilda`sub') < 0.00001
*}

gen utchour=`thehour'
append using $temp3
save $temp3, replace
* end $hoursAll
}
		

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


scatter btilda localhour  , msize (tiny)	graphregion(color(white)) title("`fuel': `inter'") xtitle("Local Hour")	ytitle("Coefficient") name(gr`fuel') xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))


				
}																					
graph combine grCoal grGas grHydro grNuke grSun grWind grTrade grOther
graph export "latex22/fuel_scatter`level'`inter'_temp.png", replace																						
																						
}	
	
}	
	