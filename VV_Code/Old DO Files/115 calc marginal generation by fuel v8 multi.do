
*** marginal generation by fuel for each of inter, region, balance, sub

foreach zone in  inter region balance sub  {
	
	clear
	save $temp2, emptyok replace

	foreach case in con uncon  {
		foreach thehour in $hoursAll{
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
				merge 1:1 idnum using "data/hourly22/coefsconstrained_`zone'`thehour'.dta", nogen keep(2 3)
			}
			if "`case'"=="uncon"{
				merge 1:1 idnum using "data/hourly22/coefs_`zone'`thehour'.dta", nogen keep(2 3)
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

			if "`zone'"=="region"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
				
			}

			
			if "`zone'"=="inter"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in East West Texas{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in East West Texas{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			if "`zone'"=="balance"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in $AllBAcodes{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in $AllBAcodes{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			if "`zone'"=="sub"{
				if "`case'"=="con"{
					collapse (sum) btilda*, by (Fuel)
					foreach reg in $AllsubBAcodes{
						replace btilda`reg' = 0 if abs(btilda`reg') < 0.00001
					}
				}
				if "`case'"=="uncon"{
					collapse (sum) bnetgendemand*, by (Fuel)
					foreach reg in $AllsubBAcodes{
						replace bnetgendemand`reg' = 0 if abs(bnetgendemand`reg') < 0.00001
						rename bnetgendemand`reg' btilda`reg'
					}
				}
			}

			gen case ="`case'"
			gen utchour=`thehour'
			append using $temp2
			save $temp2, replace
		* end foreach thehour
		}
	* end foreach case
	}
save "data/coefs_fuel_`zone'22.dta", replace
* end foreach zone
}






