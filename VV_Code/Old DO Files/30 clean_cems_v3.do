
** data at the unit level by year

** run globals_regular.do

clear

*STEP 1: Merge monthly state files together so for each state 
* we have one file (instead of 50x12 we have 50 files)
foreach year in  2019 2020 2021 {

cd "$cemsdir/cems-`year'"

foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
	import delimited using `year'`state'01.csv,clear
	
	save $tempdir/temp_`state'.dta,replace // get first month for each state and save it
	
	** now loop over other months
	foreach month in  02 03 04 05 06 07 08 09 10 11 12{
		
		import delimited using `year'`state'`month'.csv,clear
		save $tempdir/temp_`state'_`month'.dta,replace
		use $tempdir/temp_`state'.dta,clear
		
		append using $tempdir/temp_`state'_`month'.dta, force // force used for DC error
		
		save $tempdir/temp_`state'.dta,replace
		
		capture erase $tempdir/temp_`state'_`month'.dta
		
	}
	
	save $tempdir/`state'`year'-full.dta , replace
	
	capture erase $tempdir/temp_`state'.dta
	
}


*Step 2: process each state file

foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
	
	use $tempdir/`state'`year'-full.dta, clear

	display "`state'"
	display "`year'"
	
	capture rename so2_masslbs SO2MASS
	capture rename nox_masslbs NOXMASS
	capture rename co2_masstons CO2MASS
	capture rename so2_mass SO2MASS
	capture rename nox_mass NOXMASS
	capture rename co2_mass CO2MASS
	rename gload GLOAD
	rename orispl PLANT
	rename op_hour HOUR
	
	*drop plants with no gload
	bysort PLANT: egen maxgload=max(GLOAD)
	drop if maxgload==0|maxgload==.

	capture tostring unitid, replace
	
	qui replace unitid = substr(unitid, indexnot(unitid, "0"), .)   
	
	capture drop DATE
	** first digit is month, next two are the day of that month
		
	gen double DATE = real(substr(trim(op_date),1,2)) * 100 + real(substr(trim(op_date),4,2)) + real(substr(trim(op_date),7,4)) * 10000 
	gen yr= int(DATE/10000)
	
	keep PLANT unitid DATE HOUR SO2MASS CO2MASS NOXMASS GLOAD 
	order PLANT unitid DATE HOUR SO2MASS CO2MASS NOXMASS GLOAD 
	compress
	sort PLANT unitid DATE HOUR
	
	if "`state'"!="al" append using $tempdir/emissions_co2_unit_`year'.dta
	save $tempdir/emissions_co2_unit_`year'.dta, replace
	
}	// loop by state


*** clean up: move emissions_co2_unit file
*** delete state-year files

save "$cemsdirreg/emissions_all_unit_`year'.dta", replace
capture erase $tempdir/emissions_co2_unit_`year'.dta

foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
	capture erase  $tempdir/`state'`year'-full.dta
}

cd "$datadir"
cd ..

}	// loop by year



* 2022 cems is already grouped by state



foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
	
	import delimited "$cemsdir/cems-2022/emissions-hourly-2022-`state'.csv", clear

	display "`state'"
	display "`year'"
	
	
	capture rename so2masslbs SO2MASS
	capture rename noxmasslbs NOXMASS
	capture rename co2massshorttons CO2MASS
	rename grossloadmw GLOAD
	rename facilityid PLANT
	rename hour HOUR
	
	*drop plants with no gload
	bysort PLANT: egen maxgload=max(GLOAD)
	drop if maxgload==0|maxgload==.

	capture tostring unitid, replace
	
	qui replace unitid = substr(unitid, indexnot(unitid, "0"), .)   
	
	capture drop DATE
	
	** in 2022 date is now in year-month-day format
	gen double DATE = real(substr(trim(date),9,2)) + real(substr(trim(date),6,2))*100 + real(substr(trim(date),1,4)) * 10000 
	gen yr= int(DATE/10000)
	
	keep PLANT unitid DATE HOUR SO2MASS CO2MASS NOXMASS GLOAD 
	order PLANT unitid DATE HOUR SO2MASS CO2MASS NOXMASS GLOAD 
	compress
	sort PLANT unitid DATE HOUR
	
	if "`state'"!="al" append using $tempdir/emissions_co2_unit_`year'.dta
	save $tempdir/emissions_co2_unit_`year'.dta, replace
	
}	// loop by state


*** clean up: move emissions_co2_unit file
*** delete state-year files

save "$cemsdirreg/emissions_all_unit_2022.dta", replace
capture erase $tempdir/emissions_co2_unit_`year'.dta



foreach year in  2019 2020 2021 2022 {
if `year' == 2019 use "$cemsdirreg/emissions_all_unit_`year'.dta", clear
else append using "$cemsdirreg/emissions_all_unit_`year'.dta"
save "$tempdir/temp.dta", replace
}

	merge m:1 PLANT using "$datadir/plant_all_data22.dta", nogen keep(1 3) keepusing(timezonezip)
	
	replace HOUR=HOUR+1
	
	drop if DATE==.
	
foreach X in SO2MASS CO2MASS NOXMASS GLOAD {
	g temp = .
	sort PLANT unitid DATE HOUR
	replace temp = `X'[_n+timezonezip] if PLANT==PLANT[_n+timezonezip]  & unitid==unitid[_n+timezonezip]
	replace `X' = temp
	drop temp
}
rename DATE UTCDATE
rename HOUR UTCHOUR 
label var UTCDATE "Universal standard time's date"
label var UTCHOUR "Universal standard time's hour"
drop timezonezip
save "$cemsdirreg/emissions_all_unit_allyears22.dta", replace
capture erase "$tempdir/temp.dta"
