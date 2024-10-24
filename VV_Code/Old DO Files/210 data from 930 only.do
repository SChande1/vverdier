* first do new york
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

* non NY regions in the east
foreach region in CAR CENT FLA MIDA MIDW NE  SE  TEN{ 
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region'"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demand`region'
if "`region'"=="CAR" {
	save $temp2, replace
}
else{
	merge 1:1 date hour using $temp2, nogen
	save $temp2, replace
}
}


use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="NY"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind mida midw ne can year month
sort date hour
sum gencoal
sum genoil
sum gensun
sum midw
drop gencoal gensun
drop midw
* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
replace can = -can
replace mida = -mida
replace ne = - ne
save $temp1, replace


use $temp1, clear
merge 1:1 date hour using $temp2, nogen
save $temp4, replace


local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gengas gennuke genoil genwater genwind mida ne can  {
	dis "Region `region'"
	
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		*local varstouse `region' demand demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandSE demandTEN i.group
		*local varstouse `region' demand demandCAR demandCENT  demandMIDA demandMIDW demandNE demandSE  i.group
		local varstouse `region' demand demandMIDA demandNE constant i.group
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		*reg `region' demand demandMIDA demandNE i.group
		*dfdsffsda
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaNY

gen type = ""
replace type ="gengas" in 1
replace type ="gennuke" in 2
replace type ="genoil" in 3
replace type ="genwater" in 4
replace type ="genwind" in 5
replace type = "MIDA" in 6
replace type ="NE" in 7
replace type ="CAN" in 8

br 
asdf
}

****** california
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="NW"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demandNW
save $temp2, replace

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="SW"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demandSW
save $temp3, replace


use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="CAL"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind nw sw mex year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
replace mex = -mex
replace nw = -nw
replace sw = -sw
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
merge 1:1 date hour using $temp3, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genoil genwater gensun genwind nw sw mex  {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandNW demandSW constant i.group

		*reg `varstouse'
		*if "`region'"=="nw" asdf
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaCAL

*gencoal gengas gennuke genoil genwater gensun genwind nw sw mex
gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genoil" in 4
replace type ="genwater" in 5
replace type = "gensun" in 6
replace type ="genwind" in 7
replace type ="nw" in 8
replace type ="sw" in 9
replace type ="mex" in 10

br 
asdf
}

****** california multivariate with full equality constraints
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="NW"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demandNW
save $temp2, replace

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="SW"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demandSW
save $temp3, replace


use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="CAL"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind nw sw mex year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
replace mex = -mex
replace nw = -nw
replace sw = -sw
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
merge 1:1 date hour using $temp3, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genoil genwater gensun genwind nw sw mex  {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandNW demandSW constant i.group
		
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2..4]
		matrix w = data[1...,5..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
*python script "regular_v4.py"
python script "regular_equality_cons.py"
qui cd "../stata"

* import coefficients from python output
qui import   excel using "../python/temp_output.xlsx",  clear firstr 

* doing one at a time, so only one coefficient vector returned
qui rename A idnum
qui rename B btildaCAL
qui rename C btildaNW
qui rename D btildaSW

*gencoal gengas gennuke genoil genwater gensun genwind nw sw mex
gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genoil" in 4
replace type ="genwater" in 5
replace type = "gensun" in 6
replace type ="genwind" in 7
replace type ="nw" in 8
replace type ="sw" in 9
replace type ="mex" in 10

br
asdf 
}


****** mida
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

foreach region in CAR CENT FLA MIDW NE NY SE TEN{ 
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region'"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demand`region'
if "`region'"=="CAR" {
	save $temp2, replace
}
else{
	merge 1:1 date hour using $temp2, nogen
	save $temp2, replace
}
}

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="MIDA"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind car midw ny ten year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
foreach v in car midw ny ten {
replace `v'= -`v'
}
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genoil genwater gensun genwind car midw ny ten {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandCAR demandMIDW demandNY demandTEN constant i.group
		*local varstouse  `region' demand demandCAR demandMIDW demandNY demandTEN demandFLA demandCENT demandNE demandSE constant i.group

		*reg `varstouse'
		*if "`region'"=="nw" asdf
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaCAL

*gencoal gengas gennuke genoil genwater gensun genwind nw sw mex
gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genoil" in 4
replace type ="genwater" in 5
replace type = "gensun" in 6
replace type ="genwind" in 7
replace type ="car" in 8
replace type ="midw" in 9
replace type ="ny" in 10
replace type ="ten" in 11

br 
asdf
}


****** texas
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="CENT"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demandCENT
save $temp2, replace

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="TEX"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genwater gensun genwind cent mex year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
replace mex = -mex
replace cent = -cent
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genwater gensun genwind cent mex  {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandCENT constant i.group

		*reg `varstouse'
		*if "`region'"=="nw" asdf
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaCAL

*gencoal gengas gennuke genoil genwater gensun genwind nw sw mex
gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genwater" in 4
replace type = "gensun" in 5
replace type ="genwind" in 6
replace type ="cent" in 7
replace type ="mex" in 8

br 
asdf
}


****** sw
if 0 {
*only run summer months
global monthlow= 6
global monthhigh= 9

foreach region in CAL CENT NW { 
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region'"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demand`region'
if "`region'"!="CAL" merge 1:1 date hour using $temp2, nogen
save $temp2, replace
}

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="SW"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind cal cent nw year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
replace cal = -cal
replace cent = -cent
replace nw = -nw
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genoil genwater gensun genwind cal cent nw {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandCAL demandCENT demandNW constant i.group

		*reg `varstouse'
		*if "`region'"=="nw" asdf
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaCAL

*gencoal gengas gennuke genoil genwater gensun genwind nw sw mex
gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genoil" in 4
replace type ="genwater" in 5
replace type = "gensun" in 6
replace type ="genwind" in 7
replace type ="cal" in 8
replace type ="cent" in 9
replace type ="nw" in 10

br 
asdf
}




****** NE
if 1 {
*only run summer months
global monthlow= 6
global monthhigh= 9

foreach region in CAR CENT FLA MIDA MIDW NY SE TEN {
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region'"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand  year month
sort date hour
rename demand demand`region'
if "`region'"!="CAR" merge 1:1 date hour using $temp2, nogen
save $temp2, replace
}

use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="NE"
gen  year= year(date)
drop if year == 2022
keep if hour==23
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand gencoal gengas gennuke genoil genwater gensun genwind ny can year month
sort date hour

* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(date)
capture drop group
egen group = group(year month dow hour)

** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
foreach v in ny can {
replace `v'= -`v'
}
save $temp1, replace

use $temp1, clear
merge 1:1 date hour using $temp2, nogen
save $temp4, replace

local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach region in gencoal gengas gennuke genoil genwater gensun genwind ny can {
	dis "Region `region'"
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		local varstouse  `region' demand demandNY constant i.group 
		*local varstouse  `region' demand demandCAR demandMIDW demandNY demandTEN demandFLA demandCENT demandNE demandMIDA constant i.group

		
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
		
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
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
qui rename B btildaCAL

*gencoal gengas gennuke genoil genwater gensun genwind ny can

gen type = ""
replace type ="gencoal" in 1
replace type ="gengas" in 2
replace type ="gennuke" in 3
replace type ="genoil" in 4
replace type ="genwater" in 5
replace type = "gensun" in 6
replace type = "genwind" in 7
replace type ="ny" in 8
replace type ="can" in 9

br 
asdf
}
