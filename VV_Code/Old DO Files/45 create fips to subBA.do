

* create INSE subregions

use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
* ISNE 
* use subregion to state mapping https://www.iso-ne.com/about/key-stats/maps-and-diagrams/#load-zones
* verified by comparing 2019_smd_hoursly.xlsx to Hourly_Sub_Load.dta"
* 4001 Maine  fips 23
* 4002 New Hampsire fips 33
* 4003 Vermont fips 50
* 4004 Connecticut fips 09
* 4005 Rhode Island fips 44
* 4006 SE Mass fips 25
* 4007 WC Mass fips 25
* 4008 NE Mass fips 25

keep if bacode=="ISNE"

gen subBA=""
replace subBA = "4001" if bacode=="ISNE" & fips >23000 & fips < 24000
replace subBA = "4002" if bacode=="ISNE" & fips >33000 & fips < 34000
replace subBA = "4003" if bacode=="ISNE" & fips >50000 & fips < 51000
replace subBA = "4004" if bacode=="ISNE" & fips >9000 & fips < 10000
replace subBA = "4005" if bacode=="ISNE" & fips >44000 & fips < 45000
replace subBA = "4006" if bacode=="ISNE" & fips >25000 & fips < 26000

* MASS fips are approximate
* NE includes boston (Suffolk county, Middlesex, Essex)
replace subBA ="4008" if subBA=="4006" & (fips == 25025 | fips== 25017 | fips==25009)
* WC includes (Berkshire, Franklin, Hampshire, Hampden, Worcester)
replace subBA ="4007" if subBA=="4006" & (fips == 25003 | fips== 25011 | fips==25013 | fips==25015 | fips==25027)
keep fips subBA
save $temp1, replace


***  miso
use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="MISO"
save $temp2, replace

import excel "../rawdata/mapchart/miso zones fips.xlsx", clear firstrow
replace name="De Kalb" if name=="DeKalb"
replace name="De Soto" if name=="DeSoto"
replace name="Mccook" if name=="McCook"
replace name="Fond Du Lac" if name=="Fond du Lac"
replace name="La Grange" if name=="LaGrange"
replace name="La Moure" if name=="LaMoure"
replace name="La Salle" if name=="LaSalle"
replace name="La Porte" if name=="LaPorte"
replace name="Lake Of The Woods" if name=="Lake of the Woods"
replace name="Mccracken" if name=="McCracken"
replace name="Mcdonough" if name=="McDonough"
replace name="Mchenry" if name=="McHenry"
replace name="Mclean" if name=="McLean"
replace name="Mcleod" if name=="McLeod"
replace name="Ste. Genevieve" if name=="Sainte Genevieve"
replace name="St John The Baptist" if name=="St John the Baptist"

replace state="MO" if name=="St Louis Co"
replace name="St Louis City" if name=="St Louis Co"
replace name="Lac Qui Parle" if name=="Lac qui Parle"
merge 1:1 name state using $temp2
rename subregion subBA
keep fips subBA
save $temp2, replace

 
*** ercot

use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="ERCO"
save $temp3, replace

import excel "../rawdata/mapchart/erco zones fips.xlsx", clear firstrow
replace name="De Witt" if name=="DeWitt"
replace name="Mcmullen" if name=="McMullen"
replace name="Mclennan" if name=="McLennan"
replace name="Mcculloch" if name=="McCulloch"
merge 1:1 name state using $temp3
rename subregion subBA
keep fips subBA
save $temp3, replace

***  nyis
use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="NYIS"
save $temp4, replace
import excel "../rawdata/mapchart/nyis zones fips.xlsx", clear firstrow
merge 1:1 name state using $temp4
rename subregion subBA
keep fips subBA
save $temp4, replace


*** PJM
use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="PJM"
save $temp5, replace

import excel "../rawdata/mapchart/pjm zones fips.xlsx", clear firstrow
replace state= stritrim(state)
replace name="De Kalb" if name=="DeKalb"
replace name="Du Page" if name=="DuPage"
replace name="Baltimore" if name=="Baltimore County"
replace name="Mccreary" if name=="McCreary"
replace name="Mcdowell" if name=="McDowell"
replace name="Mchenry" if name=="McHenry"
replace name="Mckean" if name=="McKean"
replace name="Queen Annes" if name=="Queen Anne s"
replace name="Prince Georges" if name=="Prince George s"
replace name="St Marys" if name=="St Mary s"
replace name="Winchester City" if name=="Winchester"
replace name="Williamsburg City" if name=="Williamsburg"
replace name="Waynesboro City" if name=="Waynesboro"
replace name="Virginia Beach City" if name=="Virginia Beach"
replace name="Suffolk City" if name=="Suffolk"
replace name="Staunton City" if name=="Staunton"
replace name="Salem City" if name=="Salem" & state =="VA"
replace name="Radford City" if name=="Radford"
replace name="Petersburg City" if name=="Petersburg"
replace name="Buena Vista City" if name=="Buena Vista"
replace name="Charlottesville City" if name=="Charlottesville"
replace name="Chesapeake City" if name=="Chesapeake"
replace name="Colonial Heights Cit" if name=="Colonial Heights"
replace name="Covington City" if name=="Covington"
replace name="Danville City" if name=="Danville"
replace name="Emporia City" if name=="Emporia"
replace name="Fairfax City" if name=="Fairfax"
replace name="Fredericksburg City" if name=="Fredericksburg"
replace name="Galax City" if name=="Galax"
replace name="Harrisonburg City" if name=="Harrisonburg"
replace name="Lexington City" if name=="Lexington"
replace name="Lynchburg City" if name=="Lynchburg"
replace name="Manassas City" if name=="Manassas"
replace name="Manassas Park City" if name=="Manassas Park"
replace name="Martinsville City" if name=="Martinsville"
replace name="Fairfax" if name=="Fairfax Co"0
replace name="Isle Of Wight" if strpos(name,"Isle of Wight")>0
replace name="King And Queen" if name=="King and Queen"
replace name="Falls Church City" if name=="Falls Church"
replace name="Hampton City" if name=="Hampton"
replace name="Hopewell City" if name=="Hopewell"
replace name="Newport News City" if name=="Newport News"
replace name="Norfolk City" if name=="Norfolk"
replace name="Poquoson City" if name=="Poquoson"
replace name="Portsmouth City" if name=="Portsmouth"
replace name="Alexandria City" if name=="Alexandria"

replace state="VA" if name=="Bedford Co"
replace name="Bedford" if name=="Bedford Co" & state=="VA"
replace state="VA" if name=="Fairfax" & subregion=="DOM"
replace state="VA" if name=="Franklin Co" & subregion=="DOM"
replace name="Franklin City" if name=="Franklin Co" & state=="VA"
replace state="VA" if name=="Roanoke Co" 
replace state="VA" if name=="Richmond Co" 
replace name="Roanoke City" if name=="Roanoke Co"
replace name="Richmond City" if name=="Richmond Co"

merge 1:1 name state using $temp5, keep (2 3)
*bedford city VA- give it same code as bedford county
replace subregion="AEP" if fips==51515
rename subregion subBA
keep fips subBA
**** RECO maps to only one county in NJ. The data is not very good- for the entire summer there is no 
**** variation in load. So we drop it in the regressions. So just assign this county to PS instead (which is right next door) 
replace subBA="PS" if subBA=="RECO"
save $temp5, replace



* check ciso
use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="CISO"
save $temp6, replace

import excel "../rawdata/mapchart/ciso zones fips.xlsx", clear firstrow

merge 1:1 name state using $temp6
rename subregion subBA
keep fips subBA
save $temp6, replace



* check swpp
use "data/fips_to_region_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using "data/fips_to_county_names.dta", keep(1 3) nogen
keep if bacode=="SWPP"
save $temp7, replace

import excel "../rawdata/mapchart/swpp zones fips.xlsx", clear firstrow
replace name="Mcclain" if name=="McClain"
replace name="Mccone" if name=="McCone"
replace name="Mccurtain" if name=="McCurtain"
replace name="Mcdonald" if name=="McDonald"
replace name="Mcintosh" if name=="McIntosh"
replace name="Mckenzie" if name=="McKenzie"
replace name="Mcpherson" if name=="McPherson"
*fips 46113 "Shannon" has been changed to fips 46102 Oglala Lakota
* so switch name back to shannon to match with crosswalk data
replace name="Shannon" if name=="Oglala Lakota"


merge 1:1 name state using $temp7
* give new shannon same subBA as old shannon 
replace subregion = "WAUE" if fips == 46102
*

rename subregion subBA
keep fips subBA
save $temp7, replace

use $temp1, clear
append using $temp2
append using $temp3
append using $temp4
append using $temp5
append using $temp6
append using $temp7
merge 1:1 fips using  "data/fips_to_region_crosswalk.dta" , nogen keep (1 2 3)
replace subBA = balancingauthoritycode if subBA==""

save "data/fips_to_subBA_crosswalk.dta", replace


*use "data/fips_to_subBA_crosswalk.dta", replace
*keep subBA
*duplicates drop
