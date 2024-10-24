








foreach thehour in 9 {
	
	
dis "balance"


use "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_balance`thehour'.dta", clear

*foreach var in $AllBAcodes {
*
*qui rename btilda`var' btilda`var'A
*}

qui merge 1:1 idnum using  "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_balance`thehour'_uni_allinoneV5.dta"

foreach var in $AllBAcodes {
qui gen diff`var'=btilda`var'-btildademand`var'
sum diff`var'
scatter btilda`var' btildademand`var' btildademand`var'
}
	
	
gjg	
	
	
	
	
	
use "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_inter`thehour'.dta", clear
rename btildaTexas btildaTexasA
rename btildaWest btildaWestA
rename btildaEast btildaEastA
qui merge 1:1 idnum using  "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_inter`thehour'_fast.dta"
gen difftex = btildaTexas - btildaTexasA
sum difftex
gen diffw = btildaWest-btildaWestA
sum diffw
gen diffe = btildaEast - btildaEastA
sum diffe

dis "now region"

use "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_region`thehour'.dta", clear
qui rename btildaTEX btildaTEXA
qui rename btildaCAL btildaCALA
qui rename btildaSW btildaSWA
qui rename btildaNW btildaNWA
qui rename btildaCENT btildaCENTA
qui rename btildaMIDA btildaMIDAA
qui rename btildaMIDW btildaMIDWA
qui rename btildaCAR btildaCARA
qui rename btildaNE btildaNEA
qui rename btildaSE btildaSEA
qui rename btildaFLA btildaFLAA
qui rename btildaTEN btildaTENA
qui rename btildaNY btildaNYA

qui merge 1:1 idnum using  "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_region`thehour'_fast.dta"


foreach var in TEX CAL SW NW CENT MIDA MIDW CAR NE SE FLA TEN NY{
qui gen diff`var'=btilda`var'-btilda`var'A
sum diff`var'
}





*br btildaNSB btildaNSBA if btildaNSBA> 0.01
*fkhahfd

dis "now sub"


use "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_sub`thehour'.dta", clear

foreach var in $AllsubBAcodes{
rename btilda`var' btilda`var'A
}

qui merge 1:1 idnum using  "/Users/Andy/Dropbox/Regular/Stata/data/hourly22/coefsconstrained_sub`thehour'_fast.dta"

foreach var in $AllsubBAcodes{
gen diff`var'=btilda`var'-btilda`var'A
sum diff`var'
}

}

