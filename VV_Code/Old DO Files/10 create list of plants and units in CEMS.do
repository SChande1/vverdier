
** data at the unit level by year

** run globals_regular.do



clear


*STEP 1: Merge monthly state files together so for each state 
* we have one file (instead of 50x12 we have 50 files)
foreach year in  2019 2020 2021 {

	
	
*global year = 2020

cd "$cemsdir/cems-`year'"

foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
*foreach state in al ar ca co ct {
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
*foreach state in al ar ca co ct {
	
	use $tempdir/`state'`year'-full.dta, clear
	

	
	display "`state'"
	display "`year'"
	
	
	qui if 1{
	capture rename so2_masslbs SO2MASS
	capture rename nox_masslbs NOXMASS
	capture rename co2_masstons CO2MASS
	capture rename so2_mass SO2MASS
	capture rename nox_mass NOXMASS
	capture rename co2_mass CO2MASS
	capture rename heat_input HEAT
	rename gload GLOAD
	*rename op_date D
	rename orispl PLANT
	rename op_hour HOUR
	
	capture tostring unitid, replace
	
	qui replace unitid = substr(unitid, indexnot(unitid, "0"), .)   
	
	*drop plants with no gload
	bysort PLANT: egen maxgload=max(GLOAD)
	drop if maxgload==0|maxgload==.
	
	
	gen yr = `year'

	
	keep PLANT unitid  yr
	sort PLANT unitid  yr
	
	capture duplicates drop
	
	
	}
	
	
	
	if "`state'"!="al" append using $tempdir/emissions_co2_unit_`year'.dta
	save $tempdir/emissions_co2_unit_`year'.dta, replace
	
}


*** clean up: 
*** delete state-year files


save "$cemsdirreg/plants and units in cems `year'.dta", replace
capture erase $tempdir/emissions_co2_unit_`year'.dta

foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
capture erase  $tempdir/`state'`year'-full.dta
}

cd $datadir
cd ..

}


* 2022 cems is already grouped by state


foreach state in al ar az ca co ct dc de fl ga ia id il in ks ky la ma md me mi mn mo ms mt nc nd ne nh nj nm nv ny oh ok or pa ri sc sd tn tx ut va vt wa wi wv wy{
*foreach state in al ar ca co ct {
	
	import delimited "$cemsdir/cems-2022/emissions-hourly-2022-`state'.csv", clear

	display "`state'"

	qui if 1{
	
	rename grossloadmw GLOAD
	*rename op_date D
	rename facilityid PLANT
	capture tostring unitid, replace
	qui replace unitid = substr(unitid, indexnot(unitid, "0"), .)   
	*drop plants with no gload
	bysort PLANT: egen maxgload=max(GLOAD)
	drop if maxgload==0|maxgload==.
	
	gen yr = 2022
	
	keep PLANT unitid  yr
	sort PLANT unitid  yr
	
	capture duplicates drop
	
	
	}
	
	
	
	if "`state'"!="al" append using $tempdir/emissions_co2_unit_2022.dta
	save $tempdir/emissions_co2_unit_2022.dta, replace
	
}
save "$cemsdirreg/plants and units in cems 2022.dta", replace
capture erase $tempdir/emissions_co2_unit_2022.dta


*** make list of plants without units

foreach year in 2019 2020 2021 2022{
use "$cemsdirreg/plants and units in cems `year'.dta", clear
drop unitid
duplicates drop
save "$cemsdirreg/plants in cems `year'.dta"
}
