**************************** create weather data
	* don't need this anymore. moved to 73
	* need population to aggregate up from county to level of analysis
	/*
	import excel using  "../rawdata/epa/ozone-county-population.xlsx", firstrow clear
	destring STATEFIPS COUNTYFIPS, replace
	gen fips = STATEFIPS*1000+COUNTYFIPS
	rename STATETERRITORYNAME statename
	keep fips F statename
	rename F pop
	order fips pop statename
	save "data/fips_pop2015.dta", replace
	*/

	* raw weather data from open meteo
	use "data/open meteo.dta", clear
	gen month = month(utcdate)
	keep if month >=$monthlow & month <=$monthhigh

	keep fips utcdate utchour wnd ghi
	merge m:1 fips using "data/fips_to_subBA_crosswalk.dta", nogen keep(3)
	merge m:1 fips using "data/fips_pop2015.dta" , nogen keep(3)
	merge m:1 fips using "data/fips_to_county_names.dta", nogen keep(3)
	merge m:1 fips using "data/county solar wind capacity.dta", nogen keep(1 3)
	recode solarmw .=0
	recode windmw .=0
	drop reg_egrid bal_egrid statename name
	save $temp7, replace
	*end
