
*global AllRegions CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX

global monthlow= 6
global monthhigh= 9



global AllDemands $EastBaCodes $WestBaCodes $TexasBAcodes



global thehour= 23



*only run summer months
global monthlow= 6
global monthhigh= 9

* bring in all data
foreach ba in $AllBAcodes{ 
use "data/Hourly_Balancing_Load_22_imports.dta", clear
keep if bacode=="`ba'"
gen  year= year(utcdate)
drop if year == 2022
keep if utchour== $thehour
gen month = month(utcdate)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep utcdate utchour demand gencoal gengas gennuke genoil genwater gensun genwind genother   year month
sort utcdate utchour
rename demand demand`ba'
foreach var in gencoal gengas gennuke genoil genwater gensun genwind genother {
	rename `var' `var'`ba'
}
if "`ba'"=="AEC" {
	save $temp2, replace
}
else{
	merge 1:1 utcdate utchour using $temp2, nogen
	save $temp2, replace
}
}


* set up fixed effects by yr, month, day of week, hour
use $temp2, clear
gen moyr = year*100+month
gen dow = dow(utcdate)
qui capture drop group
*from import_ERCOT_data.do line 219
egen group = group(year month dow utchour)
save $temp3, replace





*** now do generation by fuel type


local cot=0
* loop through all regions
* create yX and XX matrices for each region generation
* stack them in column vectors
dis "creating matrices for python"
foreach generate in $AllBAcodes {
	foreach type in coal gas nuke oil water sun wind other{
	dis "generation  `generate'"
	
	*use $temp1, clear
	use $temp3, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		*local varstouse `region' demand demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandSE demandTEN i.group
		*local varstouse `region' demand demandCAR demandCENT  demandMIDA demandMIDW demandNE demandSE  i.group
		local varstouse gen`type'`generate' $AllDemands constant i.group
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
	
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2..56]
		matrix w = data[1...,57..`numcol']
		
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


global AllBAcodes  AEC CPLW SOCO  SC  MISO NYIS FPC SEC FPL FMPP  NSB ISNE DUK SCEG HST PJM AECI  SWPP TAL LGEE GVL CPLE TEC SPA TVA JEA WAUW DOPD BANC BPAT NWMT PNM PACW  SCL IID IPCO WALC GCPD PGE PSEI TIDC NEVP  EPE AVA LDWP  SRP WACM TEPC CISO  CHPD PSCO AZPS TPWR PACE ERCO

foreach va in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD{
	qui rename `va' btilda
}
qui rename A idnum
qui rename B btildaCAL
qui rename C btildaCAR
qui rename D btildaCENT
qui rename E btildaFLA
qui rename F btildaMIDA
qui rename G btildaMIDW
qui rename H btildaNE
qui rename I btildaNW
qui rename J btildaNY
qui rename K btildaSE
qui rename L btildaSW
qui rename M btildaTEN
qui rename N btildaTEX

gen bacode=""
gen fueltype=""
local ctr = 1
* coal gas nuke oil water sun wind other
foreach region in $AllBAcodes{
	foreach type in coal gas nuke oil water sun wind other{
	replace fueltype = "`region'`type'" in `ctr'
	replace region = "`region'" in `ctr'
	local ctr = `ctr'+1
	}
}

order idnum region fueltype

save $temp6, replace
* aggegate up from fuel types to region
use $temp6, clear

collapse (sum) btilda*, by(region)
