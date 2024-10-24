*only run summer months
global monthlow= 6
global monthhigh= 9


*foreach thehour in $hoursAll{
foreach thehour in   9 {
	dis "hour"
* pull one hour of generation data
use "data/hourly22/Hourly_Unit_and_Regional_Generation`thehour'.dta", clear
sort ID utcdate utchour
qui gen inter = "East"
qui replace inter="West" if inlist(region,"CAL","NW","SW")
qui replace inter="Texas" if region=="TEX"
qui save $temp2, replace

* set up fixed effects by yr, month, day of week, hour
use $temp2, clear
gen month = month(utcdate)
gen yr = year(utcdate)
gen moyr = yr*100+month
gen dow = dow(utcdate)
capture drop group
*from import_ERCOT_data.do line 219
egen group = group(yr month dow utchour)

**** just do  summer  months
qui keep if month >=$monthlow & month <=$monthhigh

* find number of units
egen tmax=max(idnum)
global numunits=tmax[1]
dis "number of units " $numunits
qui drop  tmax

keep if region=="TEX"
qui save $temp3, replace
collapse (sum) netgen, by(utcdate utchour)
qui save $temp4, replace



* reshape load data so that we have one set of hours that has all loads
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep region demand utcdate utchour
qui reshape wide demand, i(utcdate utchour) j(region, string)
keep if utchour==`thehour'
gen month = month(utcdate)
qui keep if month >=$monthlow & month <=$monthhigh

*if "`inter'"=="East" keep utcdate utchour demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandNY demandSE demandTEN 
*if "`inter'"=="West" keep utcdate utchour demandCAL demandSW demandNW
keep utcdate utchour demandTEX
save $temp6, replace
merge 1:1 utcdate utchour using $temp4, nogen keep(3)
qui save $temp11, replace	
scatter demandTEX netgen

use $temp6, clear
merge 1:m utcdate utchour using $temp3, nogen keep(3)
egen newid=group(idnum)
egen tmax=max(newid)
local ttmax=tmax[1]	


qui save $temp9, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
dis "`ttmax' plants"
forvalue j= 1/`ttmax'{
	 
	 qui use if newid==`j' using $temp9, clear
	 
	** set up RHS variables according to interconnection
	if _N >0 {
		
		qui matrix accum A = netgen demandTEX, noconst
		dis "plant `j'  num obs" r(N)
		if r(N) != 488 dis "not equal to 488"
		matrix XX = A[2...,2...]
	
		matrix yX= A[1,2...]
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[idnum[1]]
			drop _all
			qui svmat XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[idnum[1]]
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
	}
	
}
dis "total" `cot'
* dump big column matrices into excel files to transfer to python
* also transfer list of unit numbers
*A1 is cell number

** XX matrix is stored as a stata dta file
use "$tempdir/bigmattemp.dta"
export excel "../python/XX.xlsx", nolabel replace
** yX and unitnums are stored as matrices
qui putexcel set "../python/yX.xlsx", replace
qui putexcel A1=matrix(TEX_yX)
qui putexcel set "../python/unitnums.xlsx", replace
qui putexcel A1=matrix(unitnums)

**** call python to do constrained regression
dis "call python"
qui cd "../python"

** version 3 uses sparse matrices to save memory and relaxes the convergence criteria from 1e-12 to 1e-9
** version 4 uses upper diagonal sparse matrix for P (which is all OSPQ needs). THis saves memory for the "Sub" case
python script "regular_v4.py"
qui cd "../stata"


* import coefficients from python output
qui import   excel using "../python/temp_output.xlsx",  clear firstr 

* number of coefficinets depends on level: sub balance, region, or interconnection

qui rename  A idnum
qui rename  B btildaTEX

sum btildaTEX if btildaTEX > 0
dis r(sum)

qui import excel using "../python/temp_lm.xlsx",  clear firstr 

dis "lagrange multiplier"
dis A[1]
*** now unconstrained
dis "creating matrices for python"
dis "`ttmax' plants"
forvalue j= 1/`ttmax'{
	 
	 qui use if newid==`j' using $temp9, clear
if _N >0 {
	
	qui reg netgen demandTEX
	dis "plant `j' numobs" e(N)
	if e(N) != 488 dis "not equal to 488"
	qui for var demandTEX: gen bnetgenX=_b[X]
	qui keep ID region b* idnum
	qui duplicates drop
	if `j' > 1 append using "$tempdir/coefTEX.dta"
	sort idnum
	qui save "$tempdir/coefTEX.dta", replace
	}	
}

use $tempdir/coefTEX.dta, clear
sum bnetgendemandTEX if bnetgendemandTEX>0
dis "sum of positive coefficients"
dis r(sum)

	
}



