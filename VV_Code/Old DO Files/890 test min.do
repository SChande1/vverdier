
clear

if 0{

use "test min data.dta"

gen ey=.
*** try to reproduce finding that coef loads up on one
foreach j in 1 2 {
	capture drop temp
	
	reg y1demeaned xdemeaned if plant==`j'
	
	*if "`region'"=="CAL" qui reg `var' i.group  wnd* ghi* demandSW demandNW if newid==`j'
	*display "plant `j' rsquared  " e(r2) 
	qui predict temp, resid
	qui replace ey = temp  if plant==`j'

}	

drop y1demeaned
rename ey y1demeaned



gen ex=.
capture drop temp
reg xdemeaned xdemeaned if plant==1
*if "`region'" =="CAL" qui reg demand`region' i.group wnd* ghi* demandSW demandNW if newid==1
qui predict temp, resid
qui replace ex= temp
drop xdemeaned
rename ex xdemeaned

save $temp11, replace


}

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
forvalue j= 1/2{
	 
	 qui use if plant==`j' using "test min data.dta", clear
	 *qui use if plant==`j' using $temp11, clear
	  
	** set up RHS variables according to interconnection
	if _N >0 {
		
		
		qui matrix accum A = y1demeaned xdemeaned  `region',    noconst
		
		matrix XX = A[2...,2...]
	
		matrix yX= A[1,2...]
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[plant[1]]
			drop _all
			qui svmat XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[plant[1]]
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

* doing one at a time, so only one coefficient vector returned
qui rename A idnum
qui rename B btilda`region'
