

* valentin code- easier because OLS files have plant info so do have to re-create
*use "$tempdir/coefsconstrained_region23.dta", clear
*merge 1:1 idnum using "$tempdir/coefs_region23.dta"
*collapse (sum) btilda* bnetgen*, by(region)




use "data/fips_to_region_crosswalk.dta", clear
keep balancingauthoritycode region
duplicates drop
drop if region==""
rename balancingauthoritycode bacode
rename region regionA
save $temp1, replace

* check with other method of bacode to region crosswalk
*use "data/Hourly_Balancing_load22.dta", clear
*keep bacode region
*duplicates drop
*merge 1:1 bacode using $temp1

*** multivariate

foreach lreg in $AllRegions {
*foreach lreg in CAL{
	local thehour = 23

	use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear
	merge 1:1 idnum using "data/hourly22/coefsconstrained_region`thehour'.dta", nogen keep(2 3)
	
	merge m:1 PLANT  using "data/plant_all_data22", nogen keep(1 3) keepusing (zip fips region)
	gen bacode = substr(ID,1,strpos(ID,"_")-1)
	merge m:1 bacode using $temp1, nogen keep (1  3)
	replace regionA = "NW" if bacode == "AVRN"
	replace regionA = "NW" if bacode == "GRID"
	replace regionA = "NW" if bacode == "GWA"
	replace regionA = "SE" if bacode == "SEPA"
	replace regionA = "SW" if bacode == "WALC"
	replace regionA = "NW" if bacode == "WAUW"
	replace regionA = "NW" if bacode == "WWA"
	replace regionA = "CAR" if bacode =="YAD"
	replace regionA = "CENT" if bacode == "SPA"
	replace regionA = bacode if regionA=="" & region==""
	replace region = regionA if region ==""
	*replace regionA = substr(ID,1,strpos(ID,"_Trade")-6) if regionA=="" & region==""
	collapse (sum) btilda`lreg', by(region)
	if "`lreg'"=="CAL" {
		save $temp2, replace
	}
	else{
		merge 1:1 region using $temp2, nogen keep(3)
		save $temp2, replace
	}
}

order region btildaNE btildaNY btildaMIDA btildaCAR btildaTEN btildaCENT btildaFLA btildaSE btildaMIDW btildaNW btildaSW btildaCAL btildaTEX

gen num = 1
replace num = 1 if region=="NE"
replace num = 2 if region=="NY"
replace num = 3 if region=="MIDA"
replace num = 4 if region=="CAR"
replace num = 5 if region=="TEN"
replace num = 6 if region=="CENT"
replace num = 7 if region=="FLA"
replace num = 8 if region=="SE"
replace num = 9 if region=="MIDW"
replace num = 10 if region=="NW"
replace num = 11 if region =="SW"
replace num = 12 if region =="CAL"
replace num = 13 if region =="TEX"
sort num




dfafadsf


** univariate

foreach lreg in $AllRegions {
*foreach lreg in CAL{
	local thehour = 23

	use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear
	*merge 1:1 idnum using "data/hourly22/coefsconstrained_region`thehour'.dta", nogen keep(2 3)
	merge 1:1 idnum using "data/hourly22/coefsconstrained_region`thehour'_uni_allinoneV5.dta", nogen keep(2 3)
	
	merge m:1 PLANT  using "data/plant_all_data22", nogen keep(1 3) keepusing (zip fips region)
	gen bacode = substr(ID,1,strpos(ID,"_")-1)
	merge m:1 bacode using $temp1, nogen keep (1  3)
	replace regionA = "NW" if bacode == "AVRN"
	replace regionA = "NW" if bacode == "GRID"
	replace regionA = "NW" if bacode == "GWA"
	replace regionA = "SE" if bacode == "SEPA"
	replace regionA = "SW" if bacode == "WALC"
	replace regionA = "NW" if bacode == "WAUW"
	replace regionA = "NW" if bacode == "WWA"
	replace regionA = "CAR" if bacode =="YAD"
	replace regionA = "CENT" if bacode == "SPA"
	replace regionA = bacode if regionA=="" & region==""
	replace region = regionA if region ==""
	*replace regionA = substr(ID,1,strpos(ID,"_Trade")-6) if regionA=="" & region==""
	collapse (sum) btildademand`lreg', by(region)
	if "`lreg'"=="CAL" {
		save $temp2, replace
	}
	else{
		merge 1:1 region using $temp2, nogen keep(3)
		save $temp2, replace
	}
}

order region btildademandNE btildademandNY btildademandMIDA btildademandCAR btildademandTEN btildademandCENT btildademandFLA btildademandSE btildademandMIDW btildademandNW btildademandSW btildademandCAL btildademandTEX

gen num = 1
replace num = 1 if region=="NE"
replace num = 2 if region=="NY"
replace num = 3 if region=="MIDA"
replace num = 4 if region=="CAR"
replace num = 5 if region=="TEN"
replace num = 6 if region=="CENT"
replace num = 7 if region=="FLA"
replace num = 8 if region=="SE"
replace num = 9 if region=="MIDW"
replace num = 10 if region=="NW"
replace num = 11 if region =="SW"
replace num = 12 if region =="CAL"
replace num = 13 if region =="TEX"
sort num



*** look at subregion estimates



use "data/fips_to_region_crosswalk.dta", clear
keep balancingauthoritycode region
duplicates drop
drop if region==""
rename balancingauthoritycode bacode
rename region regionA
save $temp1, replace

use "data/fips_to_subBA_crosswalk.dta", clear
keep subBA region
duplicates drop
sort region subBA
save $temp4, replace


*** multivariate

foreach lreg in $AllRegions {
*foreach lreg in CAL{
	local thehour = 23

	use "data/hourly22/plant_unit_to_idnum_crosswalk`thehour'.dta", clear
	merge 1:1 idnum using "data/hourly22/coefsconstrained_sub`thehour'.dta", nogen keep(2 3)
	
	merge m:1 PLANT  using "data/plant_all_data22", nogen keep(1 3) keepusing (zip fips region)
	gen bacode = substr(ID,1,strpos(ID,"_")-1)
	merge m:1 bacode using $temp1, nogen keep (1  3)
	replace regionA = "NW" if bacode == "AVRN"
	replace regionA = "NW" if bacode == "GRID"
	replace regionA = "NW" if bacode == "GWA"
	replace regionA = "SE" if bacode == "SEPA"
	replace regionA = "SW" if bacode == "WALC"
	replace regionA = "NW" if bacode == "WAUW"
	replace regionA = "NW" if bacode == "WWA"
	replace regionA = "CAR" if bacode =="YAD"
	replace regionA = "CENT" if bacode == "SPA"
	replace regionA = bacode if regionA=="" & region==""
	replace region = regionA if region ==""
	*replace regionA = substr(ID,1,strpos(ID,"_Trade")-6) if regionA=="" & region==""
	save $temp3, replace
	
	foreach sreg in CAL{
		
		local thecount=0
		   foreach ba in $`sreg'_BA {
				dis "`ba'"
				use $temp3, clear
				collapse (sum) btilda`ba', by (region)
				if `thecount'==0 {
					save $temp5, replace
				}
				else {
				merge 1:1 region using $temp5, nogen keep (3)
				save $temp5, replace
				
				
				}
				local thecount = `thecount'+1
		   }
		
	}
	use $temp3, replace
	collapse (sum) btildaBANC, by(region)
	fsdafd
	if "`lreg'"=="CAL" {
		save $temp2, replace
	}
	else{
		merge 1:1 region using $temp2, nogen keep(3)
		save $temp2, replace
	}
}

order region btildaNE btildaNY btildaMIDA btildaCAR btildaTEN btildaCENT btildaFLA btildaSE btildaMIDW btildaNW btildaSW btildaCAL btildaTEX

gen num = 1
replace num = 1 if region=="NE"
replace num = 2 if region=="NY"
replace num = 3 if region=="MIDA"
replace num = 4 if region=="CAR"
replace num = 5 if region=="TEN"
replace num = 6 if region=="CENT"
replace num = 7 if region=="FLA"
replace num = 8 if region=="SE"
replace num = 9 if region=="MIDW"
replace num = 10 if region=="NW"
replace num = 11 if region =="SW"
replace num = 12 if region =="CAL"
replace num = 13 if region =="TEX"
sort num



