use  "../rawdata/CEMS/emissions_all_unit_allyears22.dta", clear
gen int yr=int(UTCDATE/10000)
collapse (sum) GLOAD, by(PLANT unitid yr)
merge m:1 PLANT unitid yr using "data/cems_units_fuel_19-22.dta", keep(1 3) nogen
collapse (sum) GLOAD, by(PLANT Fuel yr)
save $temp1, replace

use "data/EIA923_2019_22.dta", clear
gen Fuel = "Other"	// Oil is in other because CEMS units only defined for coal, gas, and other
replace Fuel = "Coal" if FTYPE == "COAL"
replace Fuel = "Gas" if FTYPE == "GAS"
collapse (sum) NGEN (mean) ccgt, by (PLANT Fuel yr FTYPE)
merge m:1 PLANT Fuel yr using $temp1
tab FTYPE Fuel
su
table FTYPE _m, stat(sum NGEN)
table FTYPE yr, stat(sum NGEN)
egen Fuel_total = sum(NGEN),by(FTYPE)
egen Fuel_total2 = sum(NGEN),by(FTYPE yr)
egen total = sum(NGEN)
egen total2= sum(NGEN),by(yr)
gen Fuel_share= Fuel_total/total
gen Fuel_share2= Fuel_total2/total2
table FTYPE yr, stat(mean Fuel_share2)

egen CEMS_share = sum(NGEN*(GLOAD>0&GLOAD<.)),by(FTYPE)
replace CEMS_share = CEMS_share / Fuel_total 
egen CEMS_share2 = sum(NGEN*(GLOAD>0&GLOAD<.)),by(FTYPE yr)
replace CEMS_share2 = CEMS_share2 / Fuel_total2
table FTYPE, stat(mean CEMS_share)
table FTYPE yr, stat(mean CEMS_share2)

gen FTYPE2 = FTYPE 
replace FTYPE2 = "CEMS " + FTYPE if GLOAD>0&GLOAD<. & inlist(FTYPE,"COAL","GAS","OTHER")
egen Fuel_share3 = sum(NGEN),by(FTYPE2 yr)
replace Fuel_share3=Fuel_share3/total2
table FTYPE2 yr, stat(mean Fuel_share3)
/*
        |      Mean
--------+----------
Fuel    |          
  Coal  |  .9733323
  Gas   |  .8779214
  Other |  .0402859
  Total |   .501182
-------------------

        |                     Fuel                  
        |      Coal        Gas      Other      Total
--------+-------------------------------------------
yr      |                                           
  2019  |  .9739997    .901979   .0401226   .4964566
  2020  |   .974337   .9023222   .0331473   .4907268
  2021  |  .9747443   .8963035   .0463259   .4986422
  2022  |  .9700904   .8146397   .0414249   .5603794
  Total |  .9735241   .8859143   .0400342   .5046205
*/