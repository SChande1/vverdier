
***** interconnection



***** make figures
***** unconstrained histograms
foreach thehour in $hoursShort{
*foreach thehour in $hoursAll{
use "data/hourly/coefs_inter`thehour'.dta", clear

label var bnetgendemandWest West
label var bnetgendemandEast East
label var bnetgendemandTexas Texas


foreach region in East West Texas {
	egen sum`region'=sum(bnetgendemand`region')
}

capture graph drop gr_gen*

foreach region in East West Texas { 
local thesum=sum`region'[1]
histogram bnetgendemand`region', percent bin(20) graphregion(color(white)) name(gr_gen`region') title("Total Sum of Coeffients: "`thesum') legend(off)
}

graph combine gr_genWest gr_genEast gr_genTexas
graph export "latex/naive_inter`thehour'.png", replace



*** compare constrained and unconstrained usign scatter
use "data/hourly/coefs_inter`thehour'.dta", clear
label var bnetgendemandWest "West Unconstrained"
label var bnetgendemandEast "East Unconstrained"
label var bnetgendemandTexas "Texas Unconstrained"


merge 1:1 idnum using "data/hourly/coefsconstrained_inter`thehour'.dta"


label var btildaEast "East Constrained"
label var btildaWest "West Constrained"
label var btildaTexas "Texas Constrained"

capture graph drop gr_gen*

foreach region in East West Texas { 

scatter btilda`region' bnetgendemand`region', graphregion(color(white)) name(gr_gen`region')  legend(off)
}

graph combine gr_genEast gr_genWest gr_genTexas
graph export "latex/scatter_inter`thehour'.png", replace

}


if 0{
*** check to see if solution just shifts all coefficients down by the  lagrange multiplier (which would be the case with one rhs variable and a full panel)

*** compare constrained and unconstrained usign scatter
use "data/hourly/coefs_inter23.dta", clear
label var bnetgendemandWest "West Unconstrained"
label var bnetgendemandEast "East Unconstrained"
label var bnetgendemandTexas "Texas Unconstrained"


merge 1:1 idnum using "data/hourly/coefsconstrained_inter23.dta"


label var btildaEast "East Constrained"
label var btildaWest "West Constrained"
label var btildaTexas "Texas Constrained"

capture graph drop gr_gen*

foreach region in Texas { 

twoway (scatter btilda`region' bnetgendemand`region', msize(tiny)) (scatter bnetgendemand`region' bnetgendemand`region', msize(tiny)), graphregion(color(white)) name(gr_gen`region')  legend(off)

}

gen diff = bnetgendemandTexas- btildaTexas

br bnetgendemandTexas btildaTexas diff

tab diff if btildaTexas > 0.00001

}

* test that sum of coefficients add to one for each regionn
use "/Users/andrewjyates/Dropbox/Regular/Stata/data/hourly/coefsconstrained_region23.dta", clear

foreach reg in $AllRegions{
	sum btilda`reg'
	dis r(sum)
}


***** region
*foreach thehour in $hoursAll{
foreach thehour in $hoursShort{

***** make figures
***** unconstrained histograms
use "data/hourly/coefs_region`thehour'.dta", clear

label var bnetgendemandCAL California
label var bnetgendemandCAR Carolinas
label var bnetgendemandCENT Central
label var bnetgendemandFLA Florida
label var bnetgendemandMIDA MidAtlantic
label var bnetgendemandMIDW MidWest
label var bnetgendemandNE "New England"
label var bnetgendemandNW NorthWest
label var bnetgendemandNY "New York"
label var bnetgendemandSE SouthEast
label var bnetgendemandSW SouthWest
label var bnetgendemandTEN Tennessee
label var bnetgendemandTEX Texas

foreach region in $AllRegions{
	egen sum`region'=sum(bnetgendemand`region')
}

capture graph drop gr_gen*

foreach region in $AllRegions { 
local thesum=sum`region'[1]
histogram bnetgendemand`region', percent bin(20) graphregion(color(white)) name(gr_gen`region') title("Total Sum of Coeffients: "`thesum') legend(off)
}

graph combine gr_genCAR gr_genCENT gr_genFLA gr_genMIDA
graph export "latex/naive1-`thehour'.png", replace

graph combine gr_genMIDW gr_genNE gr_genNY gr_genSE 
graph export "latex/naive2-`thehour'.png", replace

graph combine gr_genTEN gr_genCAL gr_genNW gr_genSW gr_genTEX
graph export "latex/naive3-`thehour'.png", replace


*** compare constrained and unconstrained usign scatter
use "data/hourly/coefs_region`thehour'.dta", clear
label var bnetgendemandCAL "California Unconstrained"
label var bnetgendemandCAR "Carolinas Unconstrained"
label var bnetgendemandCENT "Central Unconstrained"
label var bnetgendemandFLA "Florida Unconstrained"
label var bnetgendemandMIDA "MidAtlantic Unconstrained"
label var bnetgendemandMIDW "MidWest Unconstrained"
label var bnetgendemandNE "New England Unconstrained"
label var bnetgendemandNW "NorthWest Unconstrained"
label var bnetgendemandNY "New York Unconstrained"
label var bnetgendemandSE "SouthEast Unconstrained"
label var bnetgendemandSW "SouthWest Unconstrained"
label var bnetgendemandTEN "Tennessee Unconstrained"
label var bnetgendemandTEX "Texas Unconstrained"

merge 1:1 idnum using "data/hourly/coefsconstrained_region`thehour'.dta"


label var btildaCAL "California Constrained"
label var btildaCAR "Carolinas Constrained"
label var btildaCENT "Central Constrained"
label var btildaFLA "Florida Constrained"
label var btildaMIDA "MidAtlantic Constrained"
label var btildaMIDW "MidWest Constrained"
label var btildaNE "New England Constrained"
label var btildaNW "NorthWest Constrained"
label var btildaNY "New York Constrained"
label var btildaSE "SouthEast Constrained"
label var btildaSW "SouthWest Constrained"
label var btildaTEN "Tennessee Constrained"
label var btildaTEX "Texas Constrained"

capture graph drop gr_gen*

foreach region in $AllRegions { 

scatter btilda`region' bnetgendemand`region' , graphregion(color(white)) name(gr_gen`region')  legend(off)
}

graph combine gr_genCAR gr_genCENT gr_genFLA gr_genMIDA
graph export "latex/scatter1-`thehour'.png", replace

graph combine gr_genMIDW gr_genNE gr_genNY gr_genSE 
graph export "latex/scatter2-`thehour'.png", replace

graph combine gr_genTEN gr_genCAL gr_genNW gr_genSW gr_genTEX
graph export "latex/scatter3-`thehour'.png", replace


}

