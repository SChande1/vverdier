*import   excel using "$eparaw/unit characteristics/EPADownload/facility_07-27-2018_141508048.xlsx", clear firstr
*import   delimited using "$eparaw/unit characteristics/EPADownload/facility_06-01-2020_202726376.csv", clear 
*import   delimited using "$eparaw/unit characteristics/EPADownload/facility_06-22-2022_142653463.csv", clear

import excel using "../rawdata/CEMS/facility-attributes-1996-2022-downloaded-05-02-2023.xlsx", first clear
replace UnitID="4-1" if UnitID==" 1-Apr"
replace UnitID="8-1" if UnitID==" 1-Aug"
replace UnitID="2-1" if UnitID==" 1-Feb"
replace UnitID="1-1" if UnitID==" 1-Jan"
replace UnitID="7-1" if UnitID==" 1-Jul"
replace UnitID="6-1" if UnitID==" 1-Jun"
replace UnitID="3-1" if UnitID==" 1-Mar"
replace UnitID="5-1" if UnitID==" 1-May"
replace UnitID="4-2" if UnitID==" 2-Apr"
replace UnitID="2-2" if UnitID==" 2-Feb"
replace UnitID="1-2" if UnitID==" 2-Jan"
replace UnitID="7-2" if UnitID==" 2-Jul"
replace UnitID="6-2" if UnitID==" 2-Jun"
replace UnitID="3-2" if UnitID==" 2-Mar"
replace UnitID="5-2" if UnitID==" 2-May"

rename FacilityID	PLANT
rename Year yr
*old list, but this does not capture all plants in CEMS
*keep if inlist(sourcecategory,"Electric Utility","Small Power Producer","Cogeneration")
keep if inlist(SourceCategory,"Electric Utility","Small Power Producer","Cogeneration","Industrial Boiler","Industrial Turbine","Petroleum Refinery","Institutional","Pulp & Paper Mill")
gen Fuel="Other"
replace Fuel="Coal" if inlist(PrimaryFuelType, "Coal", "Coal Refuse", "Coal, Coal Refuse", "Coal, Natural Gas", "Coal, Other Gas", "Coal, Pipeline Natural Gas","Coal, Wood")
replace Fuel="Gas" if inlist(PrimaryFuelType,"Natural Gas", "Pipeline Natural Gas", "Natural Gas, Pipeline Natural Gas", "Other Gas")
rename UnitID unitid
rename SourceCategory Source
keep PLANT unitid yr  Fuel Source
replace unitid = substr(unitid, indexnot(unitid, "0"), .) 
save $temp2, replace

clear
use "$cemsdirreg/plants and units in cems 2019.dta", clear
append using "$cemsdirreg/plants and units in cems 2020.dta"
append using "$cemsdirreg/plants and units in cems 2021.dta"
append using "$cemsdirreg/plants and units in cems 2022.dta"
save "data/cems_plant_unit_list_19-22.dta", replace

merge 1:1 PLANT unitid yr using $temp2, keep(1 3) nogen
* this plant,unit is in cems in 2019, but not listed in "facilty attributes" in that year
replace Fuel="Gas" if PLANT==60589 & unitid=="CT-1" & yr==2019

 
save "data/cems_units_fuel_19-22.dta", replace 


