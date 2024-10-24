*do 00 globals-regular.do
*** pretest results using OLS univariate regression

clear
save $temp3, replace emptyok 
foreach thehour in $hoursAll {
	dis "hour `thehour'"
	foreach level in sub balance region inter {
	
		
	if "`level'"=="sub" {
		foreach sub in $AllsubBAcodes{
			use "data/hourly22/coefs_uni_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "sub"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp3
			save $temp3, replace
			
			}
		
		}
		if "`level'"=="balance" {
		foreach sub in $AllBAcodes{
			use "data/hourly22/coefs_uni_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "balance"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp3
			save $temp3, replace
			
			}
		
		}
		if "`level'"=="region" {
		foreach sub in $AllRegions{
			use "data/hourly22/coefs_uni_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "region"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp3
			save $temp3, replace
			
			}
		
		}
		if "`level'"=="inter" {
		foreach sub in East West Texas{
			use "data/hourly22/coefs_uni_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "inter"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp3
			save $temp3, replace
			
			}
		
		}
		
	}
		
	
}

use $temp3, clear
* check to mail sure fail corresponds to first being bigger than 1
sum first if fail==1
collapse (sum)fail,  by (level hour)
gen failper = 0
*** 121 subregions, 55 balance , 13 region , 3 inters
replace failper = fail/121 if level == "sub"
replace failper = fail/55 if level == "balance"
replace failper = fail/13 if level =="region"
replace failper = fail/3 if level == "inter"
twoway (scatter failper hour if level=="sub") (scatter failper hour if level =="balance") (scatter failper hour if level =="region") (scatter failper hour if level =="inter", msize(tiny) ), ytitle("Percent of Demand Variables That Fail Condition") xtitle("hour") legend( order( 1 "sub" 2 "balance" 3 "region" 4 "inter" )) graphregion(color(white))
graph export "latex22/ols-pretest_uni.png", replace






*** pretest results using OLS multivariate regression
*** this is not directly applicable to the rule of thumb because rule of thumb based on univariate regression with no controls
clear
save $temp1, replace emptyok 
foreach thehour in $hoursAll {
	dis "hour `thehour'"
	foreach level in sub balance region inter {
	
		
	if "`level'"=="sub" {
		foreach sub in $AllsubBAcodes{
			use "data/hourly22/coefs_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "sub"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp1
			save $temp1, replace
			
			}
		
		}
		if "`level'"=="balance" {
		foreach sub in $AllBAcodes{
			use "data/hourly22/coefs_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "balance"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp1
			save $temp1, replace
			
			}
		
		}
		if "`level'"=="region" {
		foreach sub in $AllRegions{
			use "data/hourly22/coefs_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "region"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp1
			save $temp1, replace
			
			}
		
		}
		if "`level'"=="inter" {
		foreach sub in East West Texas{
			use "data/hourly22/coefs_`level'`thehour'", clear
			gsort -bnetgendemand`sub'
			dis "`sub'"
			dis bnetgendemand`sub'[1]
			dis bnetgendemand`sub'[2]
			global fail = 0
			if bnetgendemand`sub'[1] > 1 + bnetgendemand`sub'[2] global fail = 1
			
			global first = bnetgendemand`sub'[1]
			global second = bnetgendemand`sub'[2]
			keep if _n < 2
			gen level = "inter"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen first = $first
			gen second = $second
			keep level hour subcode fail first second
			append using $temp1
			save $temp1, replace
			
			}
		
		}
		
	}
		
	
}

use $temp1, clear
* check to mail sure fail corresponds to first being bigger than 1
sum first if fail==1
collapse (sum)fail,  by (level hour)
gen failper = 0
*** 121 subregions, 55 balance , 13 region , 3 inters
replace failper = fail/121 if level == "sub"
replace failper = fail/55 if level == "balance"
replace failper = fail/13 if level =="region"
replace failper = fail/3 if level == "inter"
twoway (scatter failper hour if level=="sub") (scatter failper hour if level =="balance") (scatter failper hour if level =="region") (scatter failper hour if level =="inter", msize(tiny)), ytitle("Percent of Demand Variables That Fail Condition") xtitle("hour") legend( order( 1 "sub" 2 "balance" 3 "region" 4 "inter" )) graphregion(color(white))
graph export "latex22/ols-pretest19-21.png", replace




* compare pretest results to actual results
clear
save $temp2, replace emptyok 
foreach thehour in $hoursAll {
	dis "hour `thehour'"
	foreach level in sub balance region inter {
	
		
	if "`level'"=="sub" {
		foreach sub in $AllsubBAcodes{
			use "data/hourly22/coefsconstrained_`level'`thehour'", clear
			gsort -btilda`sub'
			dis "`sub'"
			
			global fail = 0
			if btilda`sub'[1] >= 0.999  global fail = 1
			
			global firstcon = btilda`sub'[1]
			
			keep if _n < 2
			gen level = "sub"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen firstcon = $firstcon
			
			keep level hour subcode fail firstcon 
			append using $temp2
			save $temp2, replace
			
			}
		
		}
		if "`level'"=="balance" {
		foreach sub in $AllBAcodes{
			use "data/hourly22/coefsconstrained_`level'`thehour'", clear
			gsort -btilda`sub'
			dis "`sub'"
			
			global fail = 0
			if btilda`sub'[1] >= 0.999  global fail = 1
			
			global firstcon = btilda`sub'[1]
			
			keep if _n < 2
			gen level = "balance"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen firstcon = $firstcon
			
			keep level hour subcode fail firstcon
			append using $temp2
			save $temp2, replace
			
			}
		
		}
		if "`level'"=="region" {
		foreach sub in $AllRegions{
			use "data/hourly22/coefsconstrained_`level'`thehour'", clear
			gsort -btilda`sub'
			dis "`sub'"
			
			global fail = 0
			if btilda`sub'[1] >= 0.999  global fail = 1
			
			global firstcon = btilda`sub'[1]

			keep if _n < 2
			gen level = "region"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen firstcon = $firstcon
			
			keep level hour subcode fail firstcon 
			append using $temp2
			save $temp2, replace
			
			}
		
		}
		if "`level'"=="inter" {
		foreach sub in East West Texas{
			use "data/hourly22/coefsconstrained_`level'`thehour'", clear
			gsort -btilda`sub'
			dis "`sub'"
			
			global fail = 0
			if btilda`sub'[1] >= 0.999  global fail = 1
			
			global firstcon = btilda`sub'[1]
			
			keep if _n < 2
			gen level = "inter"
			gen hour = `thehour'
			gen subcode = "`sub'"
			gen fail = $fail
			gen firstcon = $firstcon
			
			keep level hour subcode fail firstcon 
			append using $temp2
			save $temp2, replace
			
			}
		
		}
		
	}
		
	
}
use $temp2, clear
rename fail failcon
merge 1:1 level hour subcode using $temp1

tab failcon if fail==1
tab fail if failcon==1
