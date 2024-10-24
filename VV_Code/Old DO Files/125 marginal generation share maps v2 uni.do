
****** make maps of coeffients a the region level

use "$raw/Maps/US_County_LowRes_2013data_Stata11.dta", clear
drop if inlist(statefp,2,15) | statefp>56
gen fips = statefp*1000+countyfp
keep _ID fips
save $temp4, replace



** try proportional symbol map
/* example from stata
  . use "Italy-OutlineData.dta", clear
    . spmap using "Italy-OutlineCoordinates.dta", id(id)                 ///
        title("Pct. Catholics without reservations", size(*0.8))         ///
        subtitle("Italy, 1994-98" " ", size(*0.8))                       ///
        point(data("Italy-RegionsData.dta") xcoord(xcoord)               ///
        ycoord(ycoord) proportional(relig1) fcolor(red) size(*1.5))
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
replace pos= 2
replace neg =1
replace zero = 0
twoway (scatter pos pos, mcolor(none))(scatter pos t, msize(1cm) mcolor(blue)) (scatter neg t, msize(1cm) mcolor(red)) (scatter zero t, msize(1cm) mcolor(black*0.25)), legend(off) graphregion(color(white)) yscale(range(-2 4) lstyle(none)) xscale(lstyle(none)) xlabel(none)  ylabel(none) xtitle("") text(2 1.35 "Positive Share" 1 1.36 "Negative Share" 0 1.305 "Zero Share", size(0.75cm)) name(legend_gr, replace)
graph export "latex22/fig-legend-for-mar-gen.png", replace


foreach lreg in $AllRegions {

foreach localhour in 17 {  // local hour is 5pm, convert to utchour
if inlist("`lreg'","CAR","FLA","MIDA","NE","NY","SE","TEN") local thehour = `localhour' + 4 
if inlist("`lreg'","MIDW","CENT","TEX") local thehour = `localhour' + 5
if inlist("`lreg'","SW") local thehour = `localhour' + 6
if inlist("`lreg'","CAL","NW") local thehour = `localhour' + 7
if `thehour'>24 local thehour= `thehour'-24

capture graph drop gr*

foreach case in uncon con{

use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear

if "`case'"=="con"{
	merge 1:1 idnum using "data/hourly22/coefsconstrained_region`thehour'_uni.dta", nogen keep(2 3)
}
if "`case'"=="uncon"{
	merge 1:1 idnum using "data/hourly22/coefs_region`thehour'.dta", nogen keep(2 3)
}
merge m:1 PLANT  using "data/plant_all_data22", nogen keep(1 3) keepusing (zip fips)

merge m:1 fips using $temp4, keep (1 2 3 )

if "`case'" == "uncon" {
foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
rename bnetgendemand`reg' btilda`reg'
}
}

* put 99 here so collapse does not convert missing to zero
replace btilda`lreg' = 99 if btilda`lreg'==.
* sum coefficients across fips
collapse (sum) btilda* (mean) fips, by (_ID)
* put missing back
replace btilda`lreg' = . if btilda`lreg'>=99

gen group = 1 if btilda`lreg'> 0.00001 // blue
replace group = 2 if btilda`lreg'>=-0.00001 & btilda`lreg' <= 0.00001 // grey
replace group = 3 if btilda`lreg'<-0.00001 // red
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
if $bgr == 111 global colors "blue black*.25 red"
if $bgr == 110 global colors "blue black*.25"
if $bgr == 101 global colors "blue red"

merge 1:1 _ID using "data/Maps/US_County_LowRes_2013centroids_Stata11.dta",keep(3) nogen
save $temp5, replace



*if "`reg'" == "TEX" global gropts  legenda(on) legshow(1) legtitle(Size) leglabel(positive))
*if "`reg'" != "TEX"  global gropts  legenda(off)
global gropts legenda(off)


if "`case'" =="uncon"{
spmap using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", osize(none ..) ndsize(none ..)  id(_ID) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) point(data($temp5 ) xcoord(_X) ycoord(_Y) proportional(btilda`lreg'2) by(group) fcolor($colors) size(*.5) $gropts ) name(gr`case')  title("OLS") graphregion(color(white) margin(none))
}
if "`case'" =="con"{
spmap using "data/Maps/US_County_LowRes_2013coord_Stata11.dta", osize(none ..) ndsize(none ..)  id(_ID) line(data("data/Maps/US_States_LowRes_2015coord_Stata11.dta") select(drop if inlist(_ID,2,3,8,14,15,43,49))) point(data($temp5 ) xcoord(_X) ycoord(_Y) proportional(btilda`lreg'2) by(group) fcolor($colors) size(*.5) $gropts ) name(gr`case')  title("Regularized") graphregion(color(white) margin(none))
}
}
dis "make graph"
global graphoptions graphregion(color(white) margin(zero zero zero zero)) name(temp, replace)
if "`lreg'"=="CAL" graph combine  grcon gruncon, title("California") $graphoptions
if "`lreg'"=="CAR" graph combine  grcon gruncon, title("Carolinas") $graphoptions
if "`lreg'"=="CENT" graph combine  grcon gruncon, title("Central") $graphoptions
if "`lreg'"== "FLA" graph combine  grcon gruncon, title("Florida") $graphoptions
if "`lreg'"=="MIDA" graph combine  grcon gruncon, title("MidAtlantic") $graphoptions
if "`lreg'"=="MIDW" graph combine  grcon gruncon, title("MidWest") $graphoptions
if "`lreg'"=="NE" graph combine  grcon gruncon, title("New England") $graphoptions
if "`lreg'"=="NW" graph combine  grcon gruncon, title("North West") $graphoptions
if "`lreg'"=="NY" graph combine  grcon gruncon, title("New York") $graphoptions
if "`lreg'"=="SE" graph combine  grcon gruncon, title("SouthEast") $graphoptions
if "`lreg'"=="SW" graph combine  grcon gruncon, title("SouthWest") $graphoptions
if "`lreg'"=="TEN" graph combine  grcon gruncon, title("Tennessee") $graphoptions
if "`lreg'"=="TEX" graph combine   grcon gruncon , title("Texas") $graphoptions 
*if "`lreg'"=="TEX" grc1leg   grcon gruncon, title("Texas") $graphoptions position(3) ring(1) row(1)
dis "dispay"
graph display temp, xsize(5) ysize(2)
dis "save"
graph export "Latex22/coeff_map_region2_`lreg'`thehour'.png", replace
}
}

graph export "latex22/EastRegionalLoads.png", replace


