





foreach level in sub balance region inter {
	clear
	save $temp1, replace emptyok
	
	foreach thehour in $hoursAll {
	*foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 {

		use "data/hourly22/se_`level'`thehour'.dta", clear
	
		gen inter = "East"
		replace inter="Texas" if region=="TEX"
		replace inter="West" if inlist(region,"CAL","SW","NW")
		gen hour = `thehour'
		append using $temp1
		save $temp1, replace
		
	}
	
	capture graph drop gr*
	foreach theint in Texas West East {
		clear
		save $temp2, replace emptyok
		foreach thehour in $hoursAll {
		*foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 {
			use $temp1, clear
			keep if inter=="`theint'"
			keep if hour==`thehour'
			keep se* 
			foreach var of varlist _all{
				sum `var'
				gen max`var' = r(max)
			}
			keep max*
			duplicates drop
			gen num = _n
			reshape long maxsenetgendemand, i(num) j(new) string
			gen hour = `thehour'
			append using $temp2
			save $temp2, replace
		}
			
			
		scatter maxsenetgendemand hour, graphregion(color(white)) xtitle("UTC Hour") ytitle("MAX OLS Standard Error") title("`theint': `level'") name(gr`theint')
			
		
		}
	graph combine grTexas grEast grWest 
	graph export "latex22/se`level'.png", replace			
}



*keep ID and plant information for the max


foreach level in region  {
	clear
	save $temp1, replace emptyok
	
	foreach thehour in $hoursAll {
	*foreach thehour in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 {

		
		*get list of variable names
		use "data/hourly22/se_`level'`thehour'.dta", clear
		
		foreach var of varlist _all {
			use "data/hourly22/se_`level'`thehour'.dta", clear
			
			if inlist("`var'","ID","region","idnum") {
				
			}
			else {
				egen max`var'= max(`var')
				keep if `var'== max`var'
				gen inter = "East"
				replace inter="Texas" if region=="TEX"
				replace inter="West" if inlist(region,"CAL","SW","NW")
				gen hour = `thehour'
				gen demandarea = "`var'"
				keep ID region idnum inter hour `var' demandarea
				rename `var' maxSE
				append using $temp1
				save $temp1, replace
			}
			
		}
		
		
	}
	
		
}
sort maxSE
save $temp1, replace



