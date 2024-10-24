*** run globals_regular.do




clear
save "$tempdir/temp.dta", emptyok replace



*** Imports 2019 EIA923 Data ***
import   excel using "../rawdata//EIA923/EIA923_Schedules_2_3_4_5_M_12_2019_Final.xlsx", sheet(Page 1 Generation and Fuel Data) cellrange(A6) clear firstr 
gen yr=2019
ren  	 PlantId PLANT
ren 	 NetGenerationMegawatthours NGEN
ren NetgenJanuary ngen1
ren NetgenFebruary ngen2
ren NetgenMarch ngen3
ren NetgenApril ngen4
ren NetgenMay ngen5
ren NetgenJune ngen6
ren NetgenJuly ngen7
ren NetgenAugust ngen8
ren NetgenSeptember ngen9
ren NetgenOctober ngen10
ren NetgenNovember ngen11
ren NetgenDecember ngen12
ren Elec_MMBtuJanuary input1
ren Elec_MMBtuFebruary input2
ren Elec_MMBtuMarch input3
ren Elec_MMBtuApril input4
ren Elec_MMBtuMay input5
ren Elec_MMBtuJune input6
ren Elec_MMBtuJuly input7
ren Elec_MMBtuAugust input8
ren Elec_MMBtuSeptember input9
ren Elec_MMBtuOctober input10
ren Elec_MMBtuNovember input11
ren Elec_MMBtuDecember input12
ren		 AERFuelType  AERFTYPE
ren PlantState State
gen  FTYPE= "GAS"   if inlist(AERFTYPE, "NG", "OOG")
*** EIA treats Petroleum Coke plants as other, CEMS calls them coal
replace  FTYPE= "COAL"  if inlist(AERFTYPE,"COL","PC","WOC")
replace  FTYPE= "OIL"   if inlist(AERFTYPE,"DFO","WOO","RFO")
replace  FTYPE= "NUKE"  if inlist(AERFTYPE, "NUC")
replace  FTYPE= "SOLAR" if inlist(AERFTYPE, "SUN")
replace  FTYPE= "WIND" if inlist(AERFTYPE, "WND")
replace  FTYPE= "HYDRO" if inlist(AERFTYPE, "HYC")
replace  FTYPE= "OTHER" if FTYPE==""
drop if inlist(State, "HI", "AK")
replace NERCRegion = "ERCOT" if NERCRegion =="TRE"
encode NERCRegion, gen (nNERC) 
egen mediannercstate=mode(nNERC) , by (State)
replace NERCRegion = "ERCOT" if NERCRegion=="" & mediannercstate ==1
replace NERCRegion = "FRCC" if NERCRegion=="" & mediannercstate == 2
replace NERCRegion = "MRO" if NERCRegion=="" & mediannercstate ==3
replace NERCRegion = "NPCC" if NERCRegion=="" & mediannercstate ==4
replace NERCRegion = "RFC" if NERCRegion=="" & mediannercstate ==5
replace NERCRegion = "SERC" if NERCRegion=="" & mediannercstate ==6
replace NERCRegion = "SPP" if NERCRegion=="" & mediannercstate ==7
replace NERCRegion = "WECC" if NERCRegion=="" & mediannercstate ==8
gen ccgt=inlist(ReportedPrimeMover, "CA","CS","CT")
destring ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12, replace
destring input1 input2 input3 input4 input5 input6 input7 input8 input9 input10 input11 input12, replace
keep yr FTYPE PLANT NGEN NERCRegion State ccgt ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 input*

save "$tempdir/temp.dta", replace

*** Imports 2020 EIA923 Data ***
import   excel using "../rawdata//EIA923/EIA923_Schedules_2_3_4_5_M_12_2020_Final_Revision.xlsx", sheet(Page 1 Generation and Fuel Data) cellrange(A6) clear firstr 
gen yr=2020
ren  	 PlantId PLANT
ren 	 NetGenerationMegawatthours NGEN
ren NetgenJanuary ngen1
ren NetgenFebruary ngen2
ren NetgenMarch ngen3
ren NetgenApril ngen4
ren NetgenMay ngen5
ren NetgenJune ngen6
ren NetgenJuly ngen7
ren NetgenAugust ngen8
ren NetgenSeptember ngen9
ren NetgenOctober ngen10
ren NetgenNovember ngen11
ren NetgenDecember ngen12
ren Elec_MMBtuJanuary input1
ren Elec_MMBtuFebruary input2
ren Elec_MMBtuMarch input3
ren Elec_MMBtuApril input4
ren Elec_MMBtuMay input5
ren Elec_MMBtuJune input6
ren Elec_MMBtuJuly input7
ren Elec_MMBtuAugust input8
ren Elec_MMBtuSeptember input9
ren Elec_MMBtuOctober input10
ren Elec_MMBtuNovember input11
ren Elec_MMBtuDecember input12
ren		 AERFuelType  AERFTYPE
ren PlantState State
gen  FTYPE= "GAS"   if inlist(AERFTYPE, "NG", "OOG")
*** EIA treats Petroleum Coke plants as other, CEMS calls them coal
replace  FTYPE= "COAL"  if inlist(AERFTYPE,"COL","PC","WOC")
replace  FTYPE= "OIL"   if inlist(AERFTYPE,"DFO","WOO","RFO")
replace  FTYPE= "NUKE"  if inlist(AERFTYPE, "NUC")
replace  FTYPE= "SOLAR" if inlist(AERFTYPE, "SUN")
replace  FTYPE= "WIND" if inlist(AERFTYPE, "WND")
replace  FTYPE= "HYDRO" if inlist(AERFTYPE, "HYC")
replace  FTYPE= "OTHER" if FTYPE==""
drop if inlist(State, "HI", "AK")
replace NERCRegion = "ERCOT" if NERCRegion =="TRE"
encode NERCRegion, gen (nNERC) 
egen mediannercstate=mode(nNERC) , by (State)
replace NERCRegion = "ERCOT" if NERCRegion=="" & mediannercstate ==1
replace NERCRegion = "FRCC" if NERCRegion=="" & mediannercstate == 2
replace NERCRegion = "MRO" if NERCRegion=="" & mediannercstate ==3
replace NERCRegion = "NPCC" if NERCRegion=="" & mediannercstate ==4
replace NERCRegion = "RFC" if NERCRegion=="" & mediannercstate ==5
replace NERCRegion = "SERC" if NERCRegion=="" & mediannercstate ==6
replace NERCRegion = "SPP" if NERCRegion=="" & mediannercstate ==7
replace NERCRegion = "WECC" if NERCRegion=="" & mediannercstate ==8
gen ccgt=inlist(ReportedPrimeMover, "CA","CS","CT")
destring ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12, replace
destring input1 input2 input3 input4 input5 input6 input7 input8 input9 input10 input11 input12, replace
keep yr FTYPE PLANT NGEN NERCRegion State ccgt ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 input*

append using "$tempdir/temp.dta"
save "$tempdir/temp.dta", replace


*** Imports 2021 EIA923 Data ***
import   excel using "../rawdata//EIA923/EIA923_Schedules_2_3_4_5_M_12_2021_Final.xlsx", sheet(Page 1 Generation and Fuel Data) cellrange(A6) clear firstr 
gen yr=2021
ren  	 PlantId PLANT
ren 	 NetGenerationMegawatthours NGEN
ren NetgenJanuary ngen1
ren NetgenFebruary ngen2
ren NetgenMarch ngen3
ren NetgenApril ngen4
ren NetgenMay ngen5
ren NetgenJune ngen6
ren NetgenJuly ngen7
ren NetgenAugust ngen8
ren NetgenSeptember ngen9
ren NetgenOctober ngen10
ren NetgenNovember ngen11
ren NetgenDecember ngen12
ren Elec_MMBtuJanuary input1
ren Elec_MMBtuFebruary input2
ren Elec_MMBtuMarch input3
ren Elec_MMBtuApril input4
ren Elec_MMBtuMay input5
ren Elec_MMBtuJune input6
ren Elec_MMBtuJuly input7
ren Elec_MMBtuAugust input8
ren Elec_MMBtuSeptember input9
ren Elec_MMBtuOctober input10
ren Elec_MMBtuNovember input11
ren Elec_MMBtuDecember input12
ren		 AERFuelType  AERFTYPE
ren PlantState State
gen  FTYPE= "GAS"   if inlist(AERFTYPE, "NG", "OOG")
*** EIA treats Petroleum Coke plants as other, CEMS calls them coal
replace  FTYPE= "COAL"  if inlist(AERFTYPE,"COL","PC","WOC")
replace  FTYPE= "OIL"   if inlist(AERFTYPE,"DFO","WOO","RFO")
replace  FTYPE= "NUKE"  if inlist(AERFTYPE, "NUC")
replace  FTYPE= "SOLAR" if inlist(AERFTYPE, "SUN")
replace  FTYPE= "WIND" if inlist(AERFTYPE, "WND")
replace  FTYPE= "HYDRO" if inlist(AERFTYPE, "HYC")
replace  FTYPE= "OTHER" if FTYPE==""
drop if inlist(State, "HI", "AK")
replace NERCRegion = "ERCOT" if NERCRegion =="TRE"
encode NERCRegion, gen (nNERC) 
egen mediannercstate=mode(nNERC) , by (State)
replace NERCRegion = "ERCOT" if NERCRegion=="" & mediannercstate ==1
replace NERCRegion = "FRCC" if NERCRegion=="" & mediannercstate == 2
replace NERCRegion = "MRO" if NERCRegion=="" & mediannercstate ==3
replace NERCRegion = "NPCC" if NERCRegion=="" & mediannercstate ==4
replace NERCRegion = "RFC" if NERCRegion=="" & mediannercstate ==5
replace NERCRegion = "SERC" if NERCRegion=="" & mediannercstate ==6
replace NERCRegion = "SPP" if NERCRegion=="" & mediannercstate ==7
replace NERCRegion = "WECC" if NERCRegion=="" & mediannercstate ==8
gen ccgt=inlist(ReportedPrimeMover, "CA","CS","CT")
destring ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12, replace
destring input1 input2 input3 input4 input5 input6 input7 input8 input9 input10 input11 input12, replace
keep yr FTYPE PLANT NGEN NERCRegion State ccgt ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 input*

append using "$tempdir/temp.dta"
save "$tempdir/temp.dta", replace

*** Imports 2022 EIA923 Data ***
import   excel using "../rawdata//EIA923/EIA923_Schedules_2_3_4_5_M_12_2022_Final.xlsx", sheet(Page 1 Generation and Fuel Data) cellrange(A6) clear firstr 
gen yr=2022
ren  	 PlantId PLANT
ren 	 NetGenerationMegawatthours NGEN
ren NetgenJanuary ngen1
ren NetgenFebruary ngen2
ren NetgenMarch ngen3
ren NetgenApril ngen4
ren NetgenMay ngen5
ren NetgenJune ngen6
ren NetgenJuly ngen7
ren NetgenAugust ngen8
ren NetgenSeptember ngen9
ren NetgenOctober ngen10
ren NetgenNovember ngen11
ren NetgenDecember ngen12
ren Elec_MMBtuJanuary input1
ren Elec_MMBtuFebruary input2
ren Elec_MMBtuMarch input3
ren Elec_MMBtuApril input4
ren Elec_MMBtuMay input5
ren Elec_MMBtuJune input6
ren Elec_MMBtuJuly input7
ren Elec_MMBtuAugust input8
ren Elec_MMBtuSeptember input9
ren Elec_MMBtuOctober input10
ren Elec_MMBtuNovember input11
ren Elec_MMBtuDecember input12
ren		 AERFuelType  AERFTYPE
ren PlantState State
gen  FTYPE= "GAS"   if inlist(AERFTYPE, "NG", "OOG")
*** EIA treats Petroleum Coke plants as other, CEMS calls them coal
replace  FTYPE= "COAL"  if inlist(AERFTYPE,"COL","PC","WOC")
replace  FTYPE= "OIL"   if inlist(AERFTYPE,"DFO","WOO","RFO")
replace  FTYPE= "NUKE"  if inlist(AERFTYPE, "NUC")
replace  FTYPE= "SOLAR" if inlist(AERFTYPE, "SUN")
replace  FTYPE= "WIND" if inlist(AERFTYPE, "WND")
replace  FTYPE= "HYDRO" if inlist(AERFTYPE, "HYC")
replace  FTYPE= "OTHER" if FTYPE==""
drop if inlist(State, "HI", "AK")
replace NERCRegion = "ERCOT" if NERCRegion =="TRE"
encode NERCRegion, gen (nNERC) 
egen mediannercstate=mode(nNERC) , by (State)
replace NERCRegion = "ERCOT" if NERCRegion=="" & mediannercstate ==1
replace NERCRegion = "FRCC" if NERCRegion=="" & mediannercstate == 2
replace NERCRegion = "MRO" if NERCRegion=="" & mediannercstate ==3
replace NERCRegion = "NPCC" if NERCRegion=="" & mediannercstate ==4
replace NERCRegion = "RFC" if NERCRegion=="" & mediannercstate ==5
replace NERCRegion = "SERC" if NERCRegion=="" & mediannercstate ==6
replace NERCRegion = "SPP" if NERCRegion=="" & mediannercstate ==7
replace NERCRegion = "WECC" if NERCRegion=="" & mediannercstate ==8
gen ccgt=inlist(ReportedPrimeMover, "CA","CS","CT")
destring ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12, replace
destring input1 input2 input3 input4 input5 input6 input7 input8 input9 input10 input11 input12, replace
keep yr FTYPE PLANT NGEN NERCRegion State ccgt ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 input*

append using "$tempdir/temp.dta"
save "data/EIA923_2019_22.dta", replace

erase "$tempdir/temp.dta"



dafdfafdsfs


*** do internal consistency check on data for  ngen vs mmbtu (input for electricity)

use "data/EIA923_2019_21.dta", clear
drop if inlist(FTYPE,"HYDRO","NUKE","SOLAR","WIND")
gen Fuel = "Other"
replace Fuel = "Coal" if FTYPE == "COAL"
replace Fuel = "Gas" if FTYPE == "GAS"
collapse (sum) NGEN ngen1 ngen2 ngen3 ngen4 ngen5 ngen6 ngen7 ngen8 ngen9 ngen10 ngen11 ngen12 input1 input2 input3 input4 input5 input6 input7 input8 input9 input10 input11 input12 (mean) ccgt, by (PLANT Fuel yr)
reshape long ngen input, i (PLANT Fuel  yr) j(month)
keep if Fuel=="Coal"

*scatter ngen input

keep if input>0 & ngen>0
save $temp1, replace
use $temp1, clear

gen coef=.
gen rsqr=.

levelsof PLANT , local (lev)
foreach i of local lev{
	count if PLANT == `i'
	if r(N)>10 {
	qui reg ngen input if PLANT==`i'
	replace coef= _b[input] if PLANT==`i'
	replace rsqr = e(r2) if PLANT==`i'
	}
}
keep PLANT coef* rsq*
duplicates drop
sum coef* rsq*,d
sort rsqr
scatter rsqr coef

use $temp1, clear
** below 0.75
scatter ngen input if PLANT==57937 
scatter ngen input if PLANT==57937 & yr ==2021
scatter ngen input if PLANT==60
scatter ngen input if PLANT==60 & yr==2019
scatter ngen input if PLANT==50933
scatter ngen input if PLANT==50879
scatter ngen input if PLANT==2018

** around 0.9
scatter ngen input if PLANT==10379

** exactly 1
scatter ngen input if PLANT==50806


*** of the 11 plants that have rsqr less than 0.90
*** 57937, 50933, 50879, 2018, 50628 ,54618, 1073, 50447   are not in the CEMS data
*** 60, 2103 are in the CEMS data, but have an rsqr of 0.99 for netgen on GLOAD
*** 2098 is a gas plant in CEMS(as defined by EPA plant characteristics) but has coal generation in 923
