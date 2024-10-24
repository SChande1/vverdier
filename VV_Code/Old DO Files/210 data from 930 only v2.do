
*global AllRegions CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX

global monthlow= 6
global monthhigh= 9

* set up temp 5
clear
set obs 22
gen type = ""
replace type = "gencoal" in 1
replace type = "gengas" in 2
replace type = "gennuke" in 3
replace type = "genoil" in 4
replace type = "gensun" in 5
replace type = "genwater" in 6
replace type = "genwind" in 7
replace type = "cal" in 8
replace type = "car" in 9
replace type = "cent" in 10
replace type = "fla" in 11
replace type = "mida" in 12
replace type = "midw" in 13
replace type = "ne" in 14
replace type = "nw" in 15
replace type = "ny" in 16
replace type = "se" in 17
replace type = "sw" in 18
replace type = "ten" in 19
replace type = "tex" in 20
replace type = "mex" in 21
replace type = "can" in 22
save $temp5, replace 

* do this loop to set up the globals below
* look to see which generation types and imports have nonzero values
foreach region in $AllRegions{
qui use "data/Hourly_Regional_Load_Generation22.dta", clear
qui keep if region=="`region'"
qui gen  year= year(utcdate)
qui drop if year == 2022
qui keep if utchour==23
qui gen month = month(utcdate)
qui keep if month >= $monthlow 
qui keep if month <= $monthhigh
dis "`region'"
sum
}

* imports from other regions
global CAL_imports nw sw mex
global CAR_imports mida se ten 
global CENT_imports midw nw sw tex can 
global FLA_imports se
global MIDA_imports car midw ny ten
global MIDW_imports cent mida se ten can
global NE_imports ny can
global NW_imports cal cent sw can
global NY_imports mida ne can
global SE_imports car fla midw ten
global SW_imports cal cent nw 
global TEN_imports car mida midw se
global TEX_imports cent mex 

* control variables for regression
global CAL_demands demandNW demandSW 
global CAR_demands demandMIDA demandSE demandTEN
global CENT_demands demandMIDW demandNW demandSW demandTEX 
global FLA_demands demandSE
global MIDA_demands demandCAR demandMIDW demandNY demandTEN
global MIDW_demands demandCENT demandSE demandTEN
global NE_demands demandNY
global NW_demands demandCAL demandCENT demandSW
global NY_demands demandMIDA demandNE
global SE_demands demandCAR demandFLA demandMIDW demandTEN
global SW_demands demandCAL demandCENT demandNW
global TEN_demands demandCAR demandMIDA demandMIDW demandSE
global TEX_demands demandCENT

* generation types
global CAL_generation gencoal gengas gennuke genoil genwater gensun genwind
global CAR_generation gencoal gengas gennuke genoil genwater gensun
global CENT_generation gencoal gengas gennuke genoil genwater gensun genwind
global FLA_generation gencoal gengas gennuke genoil genwater gensun
global MIDA_generation gencoal gengas gennuke genoil genwater gensun genwind
global MIDW_generation gencoal gengas gennuke genwater gensun genwind
global NE_generation gencoal gengas gennuke genoil genwater gensun genwind 
global NW_generation gencoal gengas gennuke genoil genwater gensun genwind
global NY_generation  gengas gennuke genoil genwater gensun genwind
global SE_generation gencoal gengas gennuke genoil genwater gensun
global SW_generation gencoal gengas gennuke  genwater gensun genwind
global TEN_generation gencoal gengas gennuke  genwater gensun 
global TEX_generation gencoal gengas gennuke genwater gensun genwind



global thehour= 23

foreach region in $AllRegions {
*foreach region in NE{
dis " `region' $`region'_demands"

*only run summer months
global monthlow= 6
global monthhigh= 9

* bring in all data
foreach region2 in $AllRegions{ 
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region2'"
gen  year= year(utcdate)
drop if year == 2022
keep if utchour== $thehour
gen month = month(utcdate)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep utcdate utchour demand  year month
sort utcdate utchour
rename demand demand`region2'
if "`region2'"=="CAL" {
	save $temp2, replace
}
else{
	merge 1:1 utcdate utchour using $temp2, nogen
	save $temp2, replace
}
}

dis "`region'"
*drop current region
drop demand`region'
save $temp2, replace

* bring in data for current region2
use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="`region'"
gen  year= year(utcdate)
drop if year == 2022
keep if utchour== $thehour
gen month = month(utcdate)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep utcdate utchour demand $`region'_generation $`region'_imports year month
sort utcdate utchour
* set up fixed effects by yr, month, day of week, hour
gen moyr = year*100+month
gen dow = dow(utcdate)
capture drop group
egen group = group(year month dow utchour)


** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
foreach imp in $`region'_imports {
replace `imp' = -`imp'
}
save $temp1, replace


use $temp1, clear
merge 1:1 utcdate utchour using $temp2, nogen
save $temp4, replace


local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach generate in $`region'_generation $`region'_imports  {
	dis "generation  `generate'"
	
	*use $temp1, clear
	use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		*local varstouse `region' demand demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandSE demandTEN i.group
		*local varstouse `region' demand demandCAR demandCENT  demandMIDA demandMIDW demandNE demandSE  i.group
		local varstouse `generate' demand $`region'_demands constant i.group
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
qui rename B btilda`region'

gen type = ""
local ctr = 1
foreach thetype in $`region'_generation $`region'_imports {
replace type = "`thetype'" in `ctr'
local ctr = `ctr'+1
}

merge 1:1 type using $temp5, nogen keep(1 2 3)

save $temp5, replace

}

use $temp5, clear
order type btildaNE btildaNY btildaMIDA btildaCAR btildaTEN btildaCENT btildaFLA btildaSE btildaMIDW btildaNW btildaSW btildaCAL btildaTEX

gen num = 1
replace num = 1 if type=="gencoal"
replace num = 2 if type=="gengas"
replace num = 3 if type=="gennuke"
replace num = 4 if type=="gensun"
replace num= 5 if type=="genwater"
replace num = 6 if type=="genwind"
replace num = 7 if type=="genoil"
replace num = 8 if type=="ne"
replace num = 9 if type=="ny"
replace num = 10 if type=="mida"
replace num = 11 if type=="car"
replace num = 12 if type=="ten"
replace num = 13 if type=="cent"
replace num = 14 if type=="fla"
replace num = 15 if type=="se"
replace num = 16 if type=="midw"
replace num = 17 if type=="nw"
replace num = 18 if type =="sw"
replace num = 19 if type =="cal"
replace num = 20 if type =="tex"
replace num = 21 if type =="can"
replace num = 22 if type =="mex"
sort num

* put in order like valentin's spreadsheet 
save $temp6, replace
use $temp6, clear
keep if num < 8
save $temp7, replace
use $temp6, clear
keep if num > 7
save $temp9, replace
use $temp7, clear
collapse (sum) btilda*
gen type = "Total"
save $temp8, replace
use $temp7, clear
append using $temp8
append using $temp9

save "data/cross_region_generation_930only.dta", replace





