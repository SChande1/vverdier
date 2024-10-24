do "00 globals-regular.do"
set scheme plotplain

*maps

*Same as Andy's file but change paths so as not to erase previous results
****** make maps of coeffients a the region level

use "$raw/Maps/US_County_LowRes_2013data_Stata11.dta", clear
drop if inlist(statefp,2,15) | statefp>56
gen fips = statefp*1000+countyfp
keep _ID fips
save $temp4, replace



** try proportional symbol map
/* example from stata
  .* use "Italy-OutlineData.dta", clear
   * . spmap using "Italy-OutlineCoordinates.dta", id(id)                 ///
   *     title("Pct. Catholics without reservations", size(*0.8))         ///
   *     subtitle("Italy, 1994-98" " ", size(*0.8))                       ///
   *     point(data("Italy-RegionsData.dta") xcoord(xcoord)               ///
   *     ycoord(ycoord) proportional(relig1) fcolor(red) size(*1.5))
*/
use "data/Maps/US_County_LowRes_2013coord_Stata11.dta", clear 
collapse (mean) _X _Y, by(_ID)
save "data/Maps/US_County_LowRes_2013centroids_Stata11.dta", replace 


* make a dummy graph to serve as legend
capture graph drop legend_gr
use "data/coefs_fuel_inter22.dta", clear
gen t = _n
keep if t==1
keep btildaTexas btildaEast btildaWest t
rename btildaTexas pos
rename btildaEast neg
rename btildaWest zero
replace pos= 3
replace neg =1.5
replace zero = 0
gen extreme = 4
twoway (scatter t extreme, mcolor(none))(scatter t zero, msize(1cm) mcolor(blue) msymbol(circle)) (scatter  t neg, msize(1cm) mcolor(red) msymbol(circle)) (scatter  t pos, msize(1cm) mcolor(black*0.25) msymbol(circle)), legend(off) graphregion(color(white)) yscale(range(-2 4) lstyle(none)) xscale(lstyle(none)) xlabel(none)  ylabel(none) xtitle("") ytitle("") text(1 .75 "Positive Share" 1 2.25 "Negative Share" 1 3.65 "Zero Share", size(0.5cm)) name(legend_gr, replace) 
graph export "${tempdir}/latex22/fig-legend-for-mar-gen.png", replace width(1500)

local nameCAL California
local nameCAR Carolinas
local nameFLA Florida
local nameMIDA Mid-Atlantic
local nameMIDW Midwest
local nameNE New England
local nameNY New York
local nameTEN Tennessee
local nameSE Southeast
local nameSW Southwest
local nameNW Northwest
local nameTEX Texas

local name1 Commonwealth Ed. Co.
local name2 Kentucky-Ohio-W.Va
local name3 W.Pa-W.Va
local name4 Dominion-Maryland-Del.
local name5 E.Pa-NJ

foreach lreg in 1 2 3 4 5 {
	if "`lreg'" != "CENT" {
	local thehour = 23

capture graph drop gr*

foreach case in  con {

use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear

if "`case'"=="con"{
	merge 1:1 idnum using "${tempdir}/coefsconstrained_region`thehour'_PJM.dta", nogen keep(2 3)
	merge 1:1 idnum using "${tempdir}/coefs_region`thehour'_PJM.dta", nogen  keepusing(region)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "${tempdir}/coefs_region`thehour'_PJM.dta", nogen keep(2 3)
}

merge m:1 PLANT  using "data/plant_all_data22", nogen keep(1 3) keepusing (zip fips)

merge m:1 fips using $temp4, nogen keep(1 3)

merge m:1 _ID using "data/Maps/US_County_LowRes_2013centroids_Stata11.dta",keep(1 3) nogen


*CHANGE LATER***********
*For now, average longitude and latitude at region level (doing it weighted at BA or sub-BA level would probably be pretty good)

egen _X_fake = mean(_X), by(region)
egen _Y_fake = mean(_Y), by(region)

su _ID
local max = r(max)
encode region, gen(region_n)

replace _ID = `max'+region_n if _ID==.
replace _X = _X_fake if _X==.
replace _Y = _Y_fake if _Y==.

************************

if "`case'" == "uncon" {
foreach reg in CAL CAR  FLA MIDA MIDW NE NW NY SE SW TEN TEX{
rename bnetgenx`reg' btilda`reg'
}
}

* put 99 here so collapse does not convert missing to zero
replace btilda`lreg' = 99 if btilda`lreg'==.
* sum coefficients across fips
collapse (sum) btilda* (mean) fips _X _Y, by (_ID)
* put missing back
replace btilda`lreg' = . if btilda`lreg'>=99

gen group = 1 if btilda`lreg'> 0.00001 
* // blue
replace group = 2 if btilda`lreg'>=-0.00001 & btilda`lreg' <= 0.00001 
* // grey
replace group = 3 if btilda`lreg'<-0.00001 
* // red
gen btilda`lreg'2= btilda`lreg' if group == 1 
sum btilda`lreg'
replace btilda`lreg'2 = r(max)/20 if group == 2
replace btilda`lreg'2 = -btilda`lreg' if group == 3
tab group
count if group==1
gen blue = r(N)>0
count if group==2
gen grey = r(N)>0
count if group==3
gen red = r(N)>0
gen color = blue*100+grey*10+red
global bgr = color[1] 
disp "color code is " $bgr
if $bgr == 111 global colors "blue black*0 red"
if $bgr == 110 global colors "blue black%0"
if $bgr == 101 global colors "blue red"

save $temp5, replace

*if "`reg'" == "TEX" global gropts  legenda(on) legshow(1) legtitle(Size) leglabel(positive))
*if "`reg'" != "TEX"  global gropts  legenda(off)
global gropts legenda(off)


if "`case'" =="con"{
spmap using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", osize(none ..) ndsize(none ..)  id(_ID) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) point(data($temp5 ) xcoord(_X) ycoord(_Y) proportional(btilda`lreg'2) by(group) fcolor($colors) size(*.5) $gropts ) xsize(2.5) ysize(2) saving(${tempdir}/gr`lreg'map_PJM, replace)   graphregion(color(white) margin(none))

}
}
}
}

*Fuel by hour

clear
save $temp3, emptyok replace
foreach case in con   {
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
	merge 1:1 idnum using "$tempdir/coefsconstrained_region`thehour'_PJM.dta", nogen keep(2 3)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "$tempdir/coefs_region`thehour'_PJM.dta", nogen keep(2 3)
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
foreach reg in  1 2 3 4 5 {
replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
}
}

if "`case'"=="uncon"{
collapse (sum) bnetgenx*, by (Fuel)
foreach reg in CAL CAR FLA MIDA MIDW NE NW NY SE SW TEN TEX{
replace bnetgenx`reg' = 0 if abs(bnetgenx`reg') < 0.00001
rename bnetgenx`reg' btilda`reg'
}
}
gen case ="`case'"
gen utchour=`thehour'
append using $temp3
save $temp3, replace
}
}
*** add last four fuels into remainder
replace Fuel = "remainder" if inlist(Fuel,"Other")
collapse (sum) btilda*, by (utchour case Fuel)

foreach reg in  1 2 3 4 5 {
*foreach reg in SW {

capture drop btildamin
capture drop btildamax 
egen btildamin = min(btilda`reg' * (case=="uncon"))
egen btildamax = max(btilda`reg' * (case=="uncon"))
replace btildamax = max(1,btildamax)
global max =btildamax[1]
global min =btildamin[1]

capture drop localhour
gen localhour = utchour - 4
replace localhour = localhour + 24 if localhour < 1
sort localhour

capture graph drop gr*

*scatter btilda`reg' utchour if case=="con" & Fuel=="Wind"  , graphregion(color(white)) xtitle("UTC Hour") ytitle("Coefficient of Wind generation") title("`reg' Region")

global gropts graphregion(color(white)) xtitle("Hour (local time)") ytitle("Marginal generation share") legend(off)

twoway (line btilda`reg' localhour if case=="con" & Fuel=="Wind",lcolor(green) lwidth(thick))  (line btilda`reg' localhour if case=="con" & Fuel=="Gas", lcolor(sienna) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Coal", lcolor(black) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Sun", lcolor(orange) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Hydro", lcolor(blue) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Nuke", lcolor(purple) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="Trade", lcolor(pink) lwidth(thick)) (line btilda`reg' localhour if case=="con" & Fuel=="remainder", lcolor(gray) lwidth(thick)), $gropts  xsize(2.5) ysize(2) saving(${tempdir}/grcon`reg'_fuel_PJM.gph, replace) xlabel(1 6 12 18 24) ylabel(0(.2)1, angle(0))


}


*Combine

foreach reg in 1 2 3 4 5 {
global graphoptions graphregion(color(white) margin(zero zero zero zero)) name(temp, replace)
graph combine  ${tempdir}/grcon`reg'_fuel_PJM.gph ${tempdir}/gr`reg'map_PJM.gph, title("`name`reg''") $graphoptions
graph display temp, xsize(5) ysize(2)
graph export "${tempdir}/latex22/coeff_map_region2_`reg'_PJM.png", replace width(1500)
}



*end

