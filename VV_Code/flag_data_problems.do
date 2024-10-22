*THIS IS NOT LOOKING GREAT... SHOULD WE JUST GO "BY HAND" OVER GLARING ISSUES? NAMELY WITH CENTRAL, MIDW...
do "00 globals-regular.do"
local count = 1
foreach ba in $AllBAcodes {
	if `count' == 1 {
		use vv_data/`ba'.dta, clear
		local count = `count'+1
	}
	else {
		append using vv_data/`ba'.dta
	}
}
rename BA BACode
merge m:1 BACode using vv_data/BA_region_crosswalk.dta
keep if _merge==3
drop _merge

rename RegionCountryCode region

gen utcdate = dofc(UTCtime)
gen year = year(utcdate)
gen month = month(utcdate)
gen day = day(utcdate)
gen dow = dow(utcdate)

gen hour = hh(UTCtime)
gen minute = mm(UTCtime)

tab hour if minute>0

gen utchour = round(hour+minute/60)

duplicates report BACode utcdate utchour

egen average_netgen = mean(AdjustedNG), by(BACode)

gen large_BA = average_netgen>2000

sort BACode utcdate utchour

*three hours in a row without an update for large BAs

capture drop flag_netgen
gen flag_netgen = 0 
replace flag_netgen = 1 if AdjustedNG>2000&large_BA&AdjustedNG!=.&BACode==BACode[_n-1]&AdjustedNG==AdjustedNG[_n-1]&BACode==BACode[_n-2]&AdjustedNG==AdjustedNG[_n-2]
replace flag_netgen =1 if flag_netgen[_n+1]==1&BACode==BACode[_n+1]

capture drop flag_demand
gen flag_demand = 0 
replace flag_demand = 1 if AdjustedD>2000&large_BA&AdjustedD!=.&BACode==BACode[_n-1]&AdjustedD==AdjustedD[_n-1]&BACode==BACode[_n-2]&AdjustedD==AdjustedD[_n-2]
replace flag_demand =1 if flag_demand[_n+1]==1&BACode==BACode[_n+1]

*SWPP % of problems
if 0==1 {
	keep if BACode=="SWPP"
	keep if month>=$monthlow & month <= $monthhigh
	keep if year>=2019 & year<= 2022
	gen flag = flag_demand | flag_netgen
	breakkk
}

*five hours in a row without an update for small BAs

collapse (sum) flag_netgen flag_demand, by(region utcdate utchour)
replace flag_netgen = flag_netgen>0
replace flag_demand = flag_demand>0

replace utcdate = utcdate-1 if utchour == 0
replace utchour = 24 if utchour == 0

save $tempdir/flag_eia930.dta, replace

forvalues h = 1/24 {
unique utcdate if flag_netgen & utchour == `h'
}
forvalues h = 1/24 {
unique utcdate if flag_demand & utchour == `h'
}


*end
