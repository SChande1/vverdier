use "data/fips_to_county_names.dta", clear
replace name=strlower(name)
drop if state=="AK"
drop if state=="PR"
drop if state=="HI"
drop if state=="VI"
drop if state=="GU"
replace name="dekalb" if name=="de kalb"
replace name="desoto" if name=="de soto"
replace name="dewitt" if name=="de witt"
replace name="lagrange" if name=="la grange"
replace name="lamoure" if name=="la moure"
replace name="laporte" if name=="la porte"
replace name="lasalle" if name=="la salle" & state=="IL"
replace name="dupage" if name=="du page"
replace name="miami dade" if name=="miami-dade"
replace name="colonial heights city" if name=="colonial heights cit"
replace name="o'brien" if name=="o brien"
replace name="district of columbia" if name=="washington" & state=="DC"
replace name="st  helena" if name=="st helena" & state=="LA"
replace name="ste genevieve" if name=="ste. genevieve" & state=="MO"
save $temp7, replace

import excel "$raw/EIA_861/f8612020/Sales_Ult_Cust_2020.xlsx", clear firstrow cellrange(A3)
*keep if State=="CA"
keep UtilityName BACode
rename BACode BACodeSales
duplicates drop
save $temp2, replace

import excel "$raw/EIA_861/f8612020/Service_Territory_2020.xlsx", clear firstrow
*keep if State=="CA"
rename County name
replace name=strlower(name)
rename State state
drop if state=="AK"
drop if state=="HI"
drop if state=="PR"
drop if state=="VI"
drop if state=="GU"

merge m:1 name state using $temp7, keep (1 3) nogen
save $temp1, replace




use "data/fips_to_subBA_crosswalk.dta", clear
gen bacode=balancingauthoritycode
merge 1:1 fips using $temp7, keep(1 3) nogen
*keep if state=="CA"
keep fips subBA region bacode name state

merge 1:m fips using $temp1, keep( 1 2 3) nogen
sort fips

tab UtilityName

merge m:m UtilityName using $temp2, keep (1 2 3)

order fips bacode subBA BACodeSales
sort fips



*keep if UtilityName =="Pacific Gas & Electric Co." | UtilityName=="Southern California Edison Co" | UtilityName=="San Diego Gas & Electric Co"
*sort fips

