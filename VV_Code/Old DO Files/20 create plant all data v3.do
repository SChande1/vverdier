
* v3 updates to include 2022
* make master plant file with plant orispl codes, fips, interconnection, NERC Regions, NERC subregions, EIA 930 regions, Balancing Authority Code, so2 and nox damages in dollars per pound in 2020 dollars

* use  new crosswalk from BA to region downloaded 11/30/22
clear
import excel "../rawdata/eia930/EIA930_Reference_Tables.xlsx", firstrow
rename BACode bacode
rename BAName baname_930
rename TimeZone timezone
rename RegionCountryName region
keep bacode baname_930 timezone region
save "data/BalancingAuthority_Region_crosswalk21.dta", replace


* make master list of all plants in CEMS data from 2019-2021 
clear
use "$cemsdirreg/plants in cems 2019.dta", clear
append using "$cemsdirreg/plants in cems 2020.dta"
append using "$cemsdirreg/plants in cems 2021.dta"
append using "$cemsdirreg/plants in cems 2022.dta"
save "data/cems_plant_list_19-22.dta", replace

* epa file with plant, name, state and city
import excel using "../rawdata/epa/oris-ghgrp_crosswalk_public_ry14_final.xlsx", clear first cellrange(a4)
gen PlantCode = real(ORISCODE)
drop if PlantCode==.
keep PlantCode GHGRPState FACILITYNAME	GHGRPCity
sort PlantCode 
drop if PlantCode == PlantCode[_n-1]
save $temp7, replace

* EIA 860 information about plants
import excel using "../rawdata/EIA860/2___Plant_Y2021.xlsx", clear cellrange(A2) first 
keep PlantCode PlantName City State Zip County Latitude Longitude NERCRegion BalancingAuthorityCode BalancingAuthorityName
save $temp2, replace

import excel using "../rawdata/EIA860/3_1_Generator_Y2021.xlsx", clear cellrange(A2:BU23419) first sheet(Operable)
keep PlantCode Technology PrimeMover NameplateCapacityMW 
save $temp3, replace
import excel using "../rawdata/EIA860/3_1_Generator_Y2021.xlsx", clear cellrange(A2) first sheet(Retired and Canceled)
keep PlantCode Technology PrimeMover NameplateCapacityMW 
destring NameplateCapacityMW, force replace 
append using $temp3
gen type = "Coal" if strpos(Technology, "Coal")>0
replace type = "Base" if strpos(Technology, "Natural Gas")>0
replace type = "Base" if inlist(Technology,"Landfill Gas","Other Gases","Other Waste Biomass") // exclude "Wood/Wood Waste Biomass"
replace type = "Peak" if strpos(Technology, "Natural Gas")>0 & PrimeMover=="GT"
replace type = "CCGT" if Technology=="Natural Gas Fired Combined Cycle"
rename NameplateCapacityMW cap
keep PlantCode type cap
drop if type==""
collapse (sum) cap,by(PlantCode type)
reshape wide cap, i(PlantCode) j(type) string
merge 1:1 PlantCode using $temp2, nogen keep(3)
save $temp4, replace

* egrid data. Use 2021 first, then older data to replace any missing
import excel using "../rawdata/egrid/egrid2021_data.xlsx", clear sheet(PLNT21) cellrange(A2) first
*keep PSTATABB	PNAME	ORISPL	SECTOR	BANAME	BACODE	NERC	SUBRGN	SRNAME	ISORTO	FIPSST	FIPSCNTY	CNTYNAME	LAT	LON	PLPRMFL	PLFUELCT	COALFLAG	CAPFAC	NAMEPCAP
keep PSTATABB	PNAME	ORISPL		BANAME	BACODE	NERC	SUBRGN	SRNAME		FIPSST	FIPSCNTY	CNTYNAME		PLFUELCT NAMEPCAP
save $temp5, replace

import excel using "../rawdata/egrid/egrid2020_data.xlsx", clear sheet(PLNT20) cellrange(A2) first
keep 	ORISPL			BACODE	
merge 1:1 ORISPL using $temp5, update replace nogen
save $temp5, replace

import excel using "../rawdata/egrid/egrid2019_data.xlsx", clear sheet(PLNT19) cellrange(A2) first
keep 	ORISPL			BACODE	
merge 1:1 ORISPL using $temp5, update replace nogen
save $temp5, replace

import excel using "../rawdata/egrid/egrid2018_data_v2.xlsx", clear sheet(PLNT18) cellrange(A2) first
keep 	ORISPL			BACODE	
merge 1:1 ORISPL using $temp5, update replace nogen
save $temp5, replace

import excel using "../rawdata/egrid/egrid2016_data.xlsx", clear sheet(PLNT16) cellrange(A2) first
keep 	ORISPL			BACODE	
merge 1:1 ORISPL using $temp5, update replace nogen

rename ORISPL PlantCode
save $temp5, replace

* assign fuel type and NERC regions, merge BACODES and location data

use "data/cems_plant_list_19-22.dta",clear
keep PLANT
duplicates drop
rename PLANT PlantCode 
merge m:1 PlantCode using $temp4, nogen keep(1 3)
merge m:1 PlantCode using $temp5, nogen keep(1 3)
merge m:1 PlantCode using $temp7, nogen keep(1 3) 

*plant code 55703 is in Shelby county Tennesee
replace GHGRPState="TN" if PlantCode==55703
replace FIPSST="47" if PlantCode==55703
replace FIPSCNTY="145" if PlantCode==55703
replace CNTYNAME="Shelby" if PlantCode==55703
replace BACODE="TVA" if PlantCode==55703
replace PSTATABB="TN" if PlantCode==55703
replace SUBRGN="RFCW" if PlantCode==55703
replace NERC ="SERC" if PlantCode==55703

* note: only 6 NERC regions: https://www.nerc.com/AboutNERC/keyplayers/Pages/default.aspx
replace NERC=NERCRegion if NERC==""
replace NERC="NPCC" if inlist(GHGRPState,"MA","NY") & NERC==""
replace NERC="RFC" if inlist(GHGRPState,"DC","NJ","OH","PA","MD","WV","MI") & NERC==""
replace NERC="SERC" if inlist(GHGRPState,"NC","TN","VA","SC","FL","AL","KY","IL") & NERC==""
replace NERC="TRE" if inlist(GHGRPState,"TX") & NERC==""
replace NERC="RFC" if inlist(PlantCode,50074,54571)

**** BACODE and SUBRGN for 1393 and 1594 are missing,  found by matching plants in same GHGRPCity (Westlake,LA and Cambridge, MA)
replace BACODE = "MISO" if inlist(PlantCode,1393)
replace SUBRGN = "SRMV" if inlist(PlantCode,1393)
replace BACODE = "ISNE" if inlist(PlantCode,1594)
replace SUBRGN = "NEWE" if inlist(PlantCode,1594)
**** BACODE for plant 55328 is "CTSO" but this doesn't exist in balancing authority region crosswalk
**** so again match plant in same city (Hermiston OR)
replace BACODE ="PACW" if inlist(PlantCode,55328)
**** BACODE for plant 54571 is listed as "NA", change to missing
replace BACODE ="" if inlist(PlantCode,54571)
**** Two plants have NERC=TRE but no subregion: make them ERCT as will all other plants in TRE
replace SUBRGN = "ERCT" if inlist(PlantCode,6136,55098)
save "data/CEMS_unit_characteristics22.dta", replace

/*
use "data/CEMS_unit_characteristics.dta", clear
rename PlantCode PLANT 
keep PLANT unitid Fuel2
save "data/plant_fuel2_crosswalk.dta", replace
*/

import excel using "../rawdata/HUD/zip_county_122019.xlsx", clear first
rename ZIP Zip
rename COUNTY fips
destring Zip fips, replace
egen tag = tag(Zip)
keep if tag
keep Zip fips
save $temp1, replace


use "data/CEMS_unit_characteristics22.dta", clear
destring Zip, replace
merge m:1 Zip using $temp1, keep(1 3) nogen
*br if Zip==.
rename PlantCode PLANT 
destring FIPSST FIPSCNTY, replace
replace fips=FIPSST*1000+FIPSCNTY if fips==.
keep PLANT NERC NERCRegion BalancingAuthorityCode BalancingAuthorityName PSTATABB BANAME BACODE NERC SUBRGN fips GHGRPCity GHGRPState Zip FIPSST
duplicates drop
save "data/plant_location22.dta", replace



clear
** plant and location data from EPA download
import excel using "../rawdata/CEMS/facility-attributes-1996-2022-downloaded-05-02-2023.xlsx", first clear
keep if inlist(Year,2019,2020,2021,2022)
keep FacilityID FIPSCode NERCRegion
rename FIPSCode FIPSEPACounty
rename FacilityID PLANT
duplicates drop
merge 1:1 PLANT using "data/plant_location22.dta", keep(1 2 3) nogen
gen fipsEPA =FIPSST*1000+FIPSEPACounty
order fips fipsEPA
gen difffip = fips-fipsEPA
replace fipsEPA = fips if fipsEPA==.
drop fips
rename fipsEPA fips
*plant 50074 seems to be in Delware County PA fips 42045
*other plants in this fips are in SUBRGN RFCE
replace fips=42045 if PLANT==50074
replace SUBRGN="RFCE" if PLANT==50074
save "data/plant_locationEPA22.dta", replace


** economic damages of local pollutants using AP3
** use fips codes from "changes" : $raw/CEMS/unit characteristics/EPADownload/facility_06-01-2020_202726376.xlsx
** units are $ per short ton in year 2014 dollars
u "Data/AP3_MDs08_14.dta" , clear
keep if PLANT<.
save $temp5, replace
u "Data/AP3_MDs08_14.dta" , clear
keep if PLANT==. & Category=="Med Stack"
drop if fips==.
save $temp6, replace
use "Data/plant_locationEPA22.dta", clear
keep PLANT fips PSTATABB GHGRPState
egen temp1=count(fips),by(PSTATABB)
egen temp2=max(temp1),by(PSTATABB)
gen temp3= fips if temp1==temp2
gen temp4=PSTATABB 
replace temp4=GHGRPState if temp4==""
gsort temp4 -temp3
replace temp3=temp3[_n-1] if temp4==temp4[_n-1]
replace fips=temp3 if fips==.
replace fips= 11001 if fips==. & temp4=="DC"
merge 1:1 PLANT using $temp5, keepusing(NOX_2014 SO2_2014) nogen keep(1 3)
rename NOX_2014 mdnox
rename SO2_2014 mdso2
keep PLANT fips mdnox mdso2
merge m:1 fips using $temp6, keepusing(NOX_2014 SO2_2014) nogen keep(1 3)
replace mdnox= NOX_2014 if mdnox==.
replace mdso2= SO2_2014 if mdso2==.
keep PLANT mdnox mdso2
sort PLANT
sum
** convert to $ per pound in year 2020 dollars
** cems has emissions of nox and sox in pounds
replace mdnox = (mdnox/2000)*1.1028
replace mdso2 = (mdso2/2000)*1.1028
save "Data/plant_pollution_damagesEPA22.dta", replace


* final merges: plant list, plant locations, plant damages, clean up missing data

use "data/cems_plant_list_19-22.dta", clear
*drop if yr ==2021
drop yr
duplicates drop
merge 1:1 PLANT using "data/plant_locationEPA22.dta", keep(1 3) nogen
*gen diff=(BalancingAuthorityCode==BACODE)
merge 1:1 PLANT using "data/plant_pollution_damagesEPA22.dta", keep(1 3) nogen
* These plants are listed in CEMS, but they don't ever have any generation (gload) during 2019-2021, so drop them
*drop if PLANT==54571
*drop if PLANT==880004
rename BACODE bacode
** plant 880079 is missing bacode; it is in Loudon TN all other TN plants have BACODE "TVA"
replace bacode="TVA" if PLANT==880079
merge m:1 bacode using "data/BalancingAuthority_Region_crosswalk21.dta", keep(1 3) nogen
gen INTERCON = "East"
replace INTERCON="West" if NERC =="WECC"
replace INTERCON="Texas" if NERC=="TRE" 
*plant 2535 is in Lansing NY, which is in Tompkins County also assing SUBRGN="NYUP" which is most of new york except long island
replace fips = 36109 if PLANT==2535
replace SUBRGN="NYUP" if PLANT==2535
** plant 2378 is in Marmora NJ which is in Cape May county NJ also assign SUBRGN="PJME" which is most of new jersey
replace fips=34009 if PLANT==2378
replace SUBRGN="PJME" if PLANT==2378
** plant 55248 is in Dayton OH which is in Montgomery County also assing SUBRGN="RFCW" which is all of Ohio
replace fips= 39113 if PLANT==55248
replace SUBRGN="RFCW" if PLANT==55248
** plant 10641 is in Ebensburgh PA which is in Cambria County also assign SUBRGN="RFCW" which is western pa? (Ebensburgh is west of Chambersburg which is in RFCW)
replace fips = 42021 if PLANT==10641
replace SUBRGN="RFCW" if PLANT==10641
** plant 10377 is in Hopewell VA which has fips 51670 also assign SUBRGN=="SRVC" which is south east virginia
replace fips=51670 if PLANT==10377
replace SUBRGN="SRVC" if PLANT==10377
** plant 10384 is Battleboro NC which is in Edgecombe county also assign SUBRGN=="SRVC"  which is eastern NC
replace fips=37065 if PLANT==10384
replace SUBRGN="SRVC" if PLANT==10384
** plant 10071 is Portsmouth Va which is fips 51740 also assing SUBRGN="SRVC"which is sout east virginia
replace fips=51740 if PLANT==10071
replace SUBRGN="SRVC" if PLANT==10071
** plant 478 is Denver CO which is fips 08031 also assign SUBRGN=="RMPA" which is all of Colorado
replace fips=08031 if PLANT==478
replace SUBRGN="RMPA" if PLANT==478
** plant 880079 is Loudon TN which is fips 47105 also assign SUBRGN=="SRTV" which is all of Tennessee
replace fips=47105 if PLANT==880079
replace SUBRGN="SRTV" if PLANT==880079


gen regionname="CAR"
replace regionname="CENT" if region=="Central"
replace regionname="FLA" if region=="Florida"
replace regionname="MIDA" if region=="Mid-Atlantic"
replace regionname="MIDW" if region=="Midwest"
replace regionname="NE" if region=="New England"
replace regionname="NY" if region=="New York"
replace regionname="SE" if region=="Southeast"
replace regionname="SW" if region=="Southwest"
replace regionname="TEN" if region=="Tennessee"
replace regionname="CAL" if region=="California"
replace regionname="NW" if region=="Northwest"
replace regionname="TEX" if region=="Texas"

rename region temp
rename regionname region
rename temp regionname

*replace bacode="PACW" if bacode=="AVRN"
replace PSTATABB="PA" if PLANT==50074
drop NERCRegion difffip FIPSEPACounty FIPSST
replace PSTATABB = GHGRPState if PSTATABB == ""
drop GHGRPState
rename PSTATABB state
*for plants with both BalancingAuthorityCode and bacode,  seven plants have disagreement between BalancingAuthorityCode and bacode: 2 have bacodes "ovec", which does not show up in generation data, so move them to PJM (their BalancingAthorityCode) 
replace bacode="PJM" if bacode =="OVEC"
drop BalancingAuthorityCode
drop BalancingAuthorityName
drop BANAME

* refine timezones. Use zip instead of bacode
rename Zip zip
* drop timezone based on bacode
drop timezone 
merge m:1 zip using "data/zip_timezones.dta", keep(1 3) nogen keepusing(zip timezone)
*use state timezone if zip timezone is missing
merge m:1 state using "data/state_Zone.dta", keep(1 3) nogen
replace timezone = stateZone if timezone==.
drop stateZone
rename timezone timezonezip
replace timezonezip = -6 if PLANT == 1374
replace timezonezip = -6 if PLANT == 2817
replace timezonezip = -5 if PLANT == 880079
gen timezone=""
replace timezone="Eastern" if timezonezip==-5
replace timezone="Central" if timezonezip==-6
replace timezone="Mountain" if timezonezip==-7
replace timezone="Arizona" if timezonezip==-7 & state=="AZ"
replace timezone="Pacific" if timezonezip==-8
save "data/plant_all_data22.dta", replace


/* debugging stuff below

*merge m:1 zip using "data/zip_timezones.dta", keep(1 3) nogen 
*br if State !=state & state!=""
* plant 55135 is in wisconsin, not iowa.  Looks like HUD zip-county mapping is incorrect for this one. There is a Winnebago county in both iowa and wisconsin.
* but timezone is the same either way



use "data/plant_all_data.dta", clear
strdist BANAME baname_930 , gen(diffba1)
br PLANT BANAME baname_930 diffba1 if diffba1>20
strdist BalancingAuthorityName baname_930, gen (diffba2)
br BalancingAuthorityName baname_930 diffba2 if diffba2 >20

use "data/plant_all_data.dta", clear
keep bacode 
duplicates drop 
gen num=_n
save "data/bacode-plantdata.dta", replace


import excel using "../rawdata/EIA930/webdownload/Balance_2019_Jan_Jun.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
save "data/bacode-gendata.dta", replace

import excel using "../rawdata/EIA930/webdownload/Balance_2019_Jul_Dec.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
append using "data/bacodes-gendata.dta"
save "data/bacode-gendata.dta", replace

import excel using "../rawdata/EIA930/webdownload/Balance_2020_Jan_Jun.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
append using "data/bacodes-gendata.dta"
save "data/bacode-gendata.dta", replace

import excel using "../rawdata/EIA930/webdownload/Balance_2020_Jul_Dec.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
append using "data/bacodes-gendata.dta"
save "data/bacode-gendata.dta", replace

import excel using "../rawdata/EIA930/webdownload/Balance_2021_Jan_Jun.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
append using "data/bacodes-gendata.dta"
save "data/bacode-gendata.dta", replace

import excel using "../rawdata/EIA930/webdownload/Balance_2021_Jul_Dec.xlsx", cellrange(A1) clear firstrow
keep BalancingAuthority
duplicates drop
append using "data/bacodes-gendata.dta"
save "data/bacode-gendata.dta", replace

duplicates drop
gen numa=_n
save "data/bacode-gendata.dta", replace

use "data/bacode-gendata.dta", clear
rename BalancingAuthority bacode
merge 1:1 bacode using "data/bacodes-plantdata.dta"

*/
