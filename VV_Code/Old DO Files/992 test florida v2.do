


*** check 75 by just running miso all wind


* raw weather data from NREL
use "data/nrel_nsrd.dta", clear
*destring fips , replace
*keep if int(fips/1000)==48 
*gen utcdate=dofc(datetime_utc)
*format utcdate %td
gen month = month(utcdate)
*gen utchour=hh(datetime_utc)
keep if month >=6 & month <=9

keep fips utcdate utchour temperature windspeed ghi
merge m:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen keep(3) 
merge m:1 fips using "data/fips_pop2015.dta" , nogen keep(3)
merge m:1 fips using "data/fips_to_county_names.dta", nogen keep(3)
rename temperature tmp
rename windspeed wnd
drop reg_egrid bal_egrid statename name
save $temp7, replace


* pull one hour of generation data
use "data/hourly/Hourly_Unit_and_Regional_Generation23.dta", clear
sort ID utcdate utchour
keep if ID=="MISO_All_wind"
save $temp2, replace

* set up fixed effects by yr, month, day of week, hour
use $temp2, clear
gen month = month(utcdate)
gen yr = year(utcdate)
gen moyr = yr*100+month
gen dow = dow(utcdate)
capture drop group
*from import_ERCOT_data.do line 219
egen group = group(yr month dow utchour)

**** just do  summer  months
keep if month >=6 & month <=9

* find number of inuts
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units " $numunits
drop  tmax
save $temp3,replace


*** now do othorgonalization procedure for generation 
*** only need to do this once because does not depend on levels
*** save weather variables for East, West, Texas for use below with demand

use $temp7 if utchour == 23, clear
keep if (region=="CAR" | region=="CENT" | region=="FLA" | region=="MIDA" | region=="MIDW" | region=="NE" | region=="NY" | region=="SE" | region=="TEN") 
collapse (mean) tmp wnd ghi [aweight=pop], by(state utcdate utchour)
qui reshape wide tmp wnd ghi, i(utcdate utchour) j(state) string
save $temp5, replace

use $temp3, clear
egen newid=group(idnum)
egen tmax=max(newid)
local ttmax=tmax[1]

qui merge m:1 utcdate utchour using $temp5, nogen keep(3)

local ttmax=tmax[1]
qui levelsof newid, local(countit)


keep ID utcdate utchour netgen 

save $temp4, replace



**** now look at demands

* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation.dta", clear
keep region demand utcdate utchour
reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==23
save $temp1, replace	

* set up fixed effects by yr, month, day of week, hour
use $temp1, clear
gen month = month(utcdate)
gen yr = year(utcdate)
gen moyr = yr*100+month
gen dow = dow(utcdate)
capture drop group
*from import_ERCOT_data.do line 219
egen group = group(yr month dow utchour)
save $temp1, replace


use $temp1, clear

** bring in weather variables for this interconnection

qui merge 1:1 utcdate utchour using $temp5, nogen keep(3)

drop demandCAL demandTEX demandSW demandNW

merge 1:1 utcdate utchour using $temp4 , nogen

dis "working on demands"
*regress all demand variables on wind and temperature and fixed effect and get the residuals

areg demandFLA tmp* wnd* ghi*, a(group )
predict edemandFLA, resid
areg netgen tmp* wnd* ghi*, a(group )
predict enetgen, resid
	
corr netgen demandFLA
corr enetgen edemandFLA

areg netgen demandFLA tmp* wnd* ghi*, a(group )
reg netgen demandFLA tmp* wnd* ghi*
areg netgen demandFLA , a(group )
areg netgen demandFLA  wnd* ghi*, a(group )
