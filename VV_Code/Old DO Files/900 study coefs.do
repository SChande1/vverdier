

** read in demand data for hour 1 sub
local thehour=1
use "data/Hourly_Sub_Load22.dta", clear
keep  subregion demand utcdate utchour 
reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==`thehour'
save $temp1, replace

** bring in balance authority data, drop ISO demands
use "data/Hourly_Balancing_Load22.dta", clear
** some data in jan 1 is missing bacode
drop if bacode==""
keep bacode demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(bacode, string)
keep if utchour==`thehour'
* drop BA's with no data (generation only ba's: see EIA_REference_Tables.xlsx column F)
drop demandAVRN
drop demandDEAA
drop demandEEI
drop demandGLHB
drop demandGRID
drop demandGRIF
*note GRMA was retired in 2018
drop demandGWA
drop demandHGMA
drop demandSEPA
drop demandWWA
drop demandYAD
**missing data causes a problem in the areg below because one of the RHS variables (demandXXX) could be all missing
** nsb retired in 1/8/2020
replace demandNSB=0 if demandNSB==.
** aec retired in 9/1/2021
replace demandAEC=0 if demandAEC==.
replace demandPSEI=0 if demandPSEI==.
replace demandSEC=0 if demandSEC==.
* drop ISO demand, replace with subregion demands
drop demandCISO demandISNE demandMISO demandNYIS demandPJM demandSWPP demandERCO
merge 1:1 utcdate utchour using $temp1, nogen keep(3)
** drop reco as no variation after a few months
drop demandRECO

* calc total demand by sub
collapse (sd) demand*
*collapse (sum) demand*
xpose, clear varname
rename _varname name
rename v1 size
replace size = size 
save $temp1, replace



*compare uni with uni all in one

use "data/hourly22/coefsconstrained_sub1_uni.dta", clear
merge 1:1 idnum using "data/hourly22/coefsconstrained_sub1_uni_allinone.dta",nogen keep(3)
merge 1:1 idnum using "data/hourly22/plant_unit_to_idnum_crosswalk1.dta"

matrix rsq = J(121,1,.)
local cc = 1
foreach var in $AllsubBAcodes{
	reg btilda`var' btildademand`var'
	dis e(r2)
	matrix rsq[`cc',1]=e(r2)
	local cc = `cc'+1
}
matrix list rsq

clear

svmat rsq

gen name = ""

local cc = 1
foreach var in $AllsubBAcodes{
	replace name = "demand`var'" in `cc'
	local cc = `cc'+1
}
merge 1:1 name using $temp1


scatter rsq1 size, xtitle("Std of demand") ytitle("Rsq of uni and uni_all_in_one") title("Hour 1") graphregion(color(white))

reg rsq1 size



*compare uni with multivariate

use "data/hourly22/coefsconstrained_sub1.dta", clear
rename btilda* btilda*A
merge 1:1 idnum using "data/hourly22/coefsconstrained_sub1_uni.dta",nogen keep(3)
merge 1:1 idnum using "data/hourly22/plant_unit_to_idnum_crosswalk1.dta"

matrix rsq = J(121,1,.)
local cc = 1
foreach var in $AllsubBAcodes{
	reg btilda`var'A btilda`var'
	dis e(r2)
	matrix rsq[`cc',1]=e(r2)
	local cc = `cc'+1
}
matrix list rsq

clear

svmat rsq

gen name = ""

local cc = 1
foreach var in $AllsubBAcodes{
	replace name = "demand`var'" in `cc'
	local cc = `cc'+1
}
merge 1:1 name using $temp1


scatter rsq1 size, xtitle("Std of demand") ytitle("Rsq of uni multi") title("Hour 1") graphregion(color(white))

reg rsq1 size








foreach hour in $hoursAll{
dis "`hour'"
use "/Users/andrewjyates/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_sub`hour'_uni.dta"
foreach sb in $AllsubBAcodes{
qui sum btilda`sb'
if r(sum) > 1.00001 dis "error `sb' `hour'"
}
}




use "/Users/andrewjyates/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_sub6_uni.dta", clear
sum btildaMPS




* compare multi with uni one hour


capture graph drop gr*
foreach region in $AllRegions{
** compare cal hour 23 uni and multivariate
use "data/hourly22/coefsconstrained_region23_uni.dta", clear
keep idnum btilda`region'
rename btilda`region' btilda`region'uni
drop if btilda`region'==.
save $temp1, replace

use "data/hourly22/coefsconstrained_region23.dta", clear
keep idnum btilda`region'
drop if btilda`region'==.
merge 1:1 idnum using $temp1, nogen keep(3)
*merge 1:1 idnum using "data/hourly22/plant_unit_to_idnum_crosswalk23.dta"

scatter btilda`region' btilda`region'uni btilda`region'uni, title("`region' uni vs multi") name(gr`region') graphregion(color(white))
* compare two methods for getting univariate estimates
}

graph combine grCAL grCAR grCENT grFLA , cols(2)
graph combine grMIDA grMIDW grNE grNW , cols(2)
graph combine grNY grSE grSW grTEN, cols(2)



** all hours 
clear
save $temp, emptyok replace

foreach thehour in $hoursAll{
	use "data/hourly/coefsconstrained_region`thehour'_west_methodB.dta", clear
	rename btildaCAL btildaCAL1
	rename btildaSW btildaSW1
	rename btildaNW btildaNW1
	gen hour = `thehour'
	append using $temp
	save $temp, replace
}

clear
save $temp1, emptyok replace
foreach thehour in $hoursAll{
	use "data/hourly/coefsconstrained_region`thehour'_west.dta", clear
	gen hour = `thehour'
	append using $temp1
	save $temp1, replace
}
 
merge 1:1 idnum hour using $temp

reg btildaCAL1 btildaCAL
reg btildaSW1 btildaSW
reg btildaNW1 btildaNW

scatter btildaCAL1 btildaCAL , graphregion(color(white)) msize(small) xtitle("deweatherized, nuisence") ytitle("dewetherized and deloaded") title("CAL")
scatter btildaSW1 btildaSW , graphregion(color(white))  msize(small) xtitle("deweatherized, nuisence") ytitle("deweatherized and deloaded") title("SW")
scatter btildaNW1 btildaNW , graphregion(color(white))  msize(small) xtitle("deweatherized, nuisence") ytitle("deweatherized and deloaded")  title("NW")




* compare univariate with multivariate
*** all hours

clear
save $temp2, emptyok replace

foreach thehour in $hoursAll{
	use "data/hourly/coefsconstrained_region`thehour'.dta", clear
	gen hour = `thehour'
	append using $temp2
	save $temp2, replace
}

merge 1:1 idnum hour using $temp

reg btildaCAL1 btildaCAL
reg btildaSW1 btildaSW
reg btildaNW1 btildaNW

two (scatter btildaCAL1 btildaCAL, msize(small)) (line btildaCAL btildaCAL), graphregion(color(white)) title("CAL") xtitle("Multivariate") ytitle("Univariate") legend ( label(1 "comparison") label(2 "45 degree Line"))
btildaCAL

two (scatter btildaSW1 btildaSW, msize(small) ) (line btildaSW btildaSW ), xlabel(0(0.1)0.3) ylabel(0(0.1)0.3)  graphregion(color(white)) title("SW") xtitle("Multivariate") ytitle("Univariate") legend ( label(1 "comparison") label(2 "45 degree Line")) 

two (scatter btildaNW1 btildaNW, msize(small)) (line btildaNW btildaNW), graphregion(color(white)) title("NW") xtitle("Multivariate") ytitle("Univariate") legend ( label(1 "comparison") label(2 "45 degree Line")) xlabel(0(0.05)0.10 ) ylabel(0(0.05)0.10 )

