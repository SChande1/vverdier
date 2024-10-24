
** Texas 

use "data/coefs_fuel_region22.dta", clear
keep if case=="con"
keep Fuel utchour btildaTEX
keep if Fuel =="Wind" | Fuel=="Sun"
collapse (sum) btildaTEX, by(utchour)
*  six hour difference in summer between utc and texas- but need to check begining vs end of hour
capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 6
replace localhour = localhour + 24 if localhour < 1
save $temp, replace 


import delimited using "$rawreg/EnergyOnline/20220101-20230101 ERCOT Real-time Price.csv", clear delimit(",") case(lower) varname(1)
gen time = clock(date, "MDYhms")
format time %tc
drop date
gen date = dofc(time)
format date %td
gen hour = hh(time)+1
collapse (mean) price,by(zone date hour)
reshape wide price, i(date hour) j(zone) string
gen month=month(date)
keep if month > 5 & month < 10
rename hour localhour
gen negativeprice= 0
global ct = 0
replace negativeprice = 1 if (priceLZ_AEN < $ct) | (priceLZ_CPS < $ct) | (priceLZ_HOUSTON < $ct) | (priceLZ_LCRA < $ct) |(priceLZ_NORTH < $ct) | (priceLZ_RAYBN < $ct) | (priceLZ_SOUTH < $ct ) | (priceLZ_WEST < $ct)
* describe prices
sum pri*,d
table month, stat(mean negativeprice)
*table localhour if month==3, stat(mean negativeprice)
collapse (sum) negativeprice, by(localhour)
replace negativeprice = negativeprice/122

merge 1:1 localhour using $temp, nogen keep(3)
scatter btildaTEX negativeprice negativeprice, xtitle("percent of hour with zero prices in any ERCOT load zone") ytitle("percent wind on margin") legend(off)
reg btildaTEX negativeprice

kdfhdahf



** California

use "data/coefs_fuel_region22.dta", clear
keep if case=="con"
keep Fuel utchour btildaCAL
keep if Fuel =="Wind" | Fuel=="Sun" 
collapse (sum) btildaCAL, by(utchour)
*  eight hour difference in summer between utc and cal- but need to check begining vs end of hour
capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 8
replace localhour = localhour + 24 if localhour < 1
save $temp, replace 


import delimited using "$rawreg/EnergyOnline/20220101-20230101 CAISO Real-time Price.csv", clear delimit(",") case(lower) varname(1)
gen time = clock(date, "MDYhms")
format time %tc
drop date
gen date = dofc(time)
format date %td
gen hour = hh(time)+1
collapse (mean) price,by(hub date hour)
replace hub = "N" if hub == "TH_NP15"
replace hub = "S" if hub == "TH_SP15"
replace hub = "Z" if hub == "TH_ZP26"
reshape wide price, i(date hour) j(hub) string
gen month=month(date)
*keep if month > 5 & month < 10
rename hour localhour
gen negativeprice= 0
global ct = 0
replace negativeprice = 1 if (priceN < $ct) | (priceS < $ct) | (priceZ < $ct) 
* describe prices
sum pri*,d
table month, stat(mean negativeprice)
table month if localhour==11, stat(mean negativeprice)
table localhour if month==4, stat(mean negativeprice priceN)

collapse (sum) negativeprice, by(localhour)
replace negativeprice = negativeprice/122


merge 1:1 localhour using $temp, nogen keep(3)
scatter btildaCAL negativeprice negativeprice, xtitle("percent of hour with zero prices in any CAL load zone") ytitle("percent wind on margin") legend(off)


asdfasfasd

** MISO

use "data/coefs_fuel_region22.dta", clear
keep if case=="con"
keep Fuel utchour btildaMIDW
keep if Fuel =="Wind" | Fuel=="Sun" 
collapse (sum) btildaMIDW, by(utchour)
*  eight hour difference in summer between utc and cal- but need to check begining vs end of hour
capture drop localhour
gen localhour = utchour
replace localhour = localhour  - 6
replace localhour = localhour + 24 if localhour < 1
save $temp, replace 



import delimited using "$rawreg/EnergyOnline/20220101-20230101 MISO Actual Energy Price.csv", clear delimit(",") case(lower) varname(1)
gen time = clock(date, "MDYhms")
format time %tc
drop date
gen date = dofc(time)
format date %td
gen hour = hh(time)+1
rename lmp price
collapse (mean) price,by(hub date hour)
replace hub = "AR" if hub == "ARKANSAS.HUB"
replace hub = "IL" if hub == "ILLINOIS.HUB"
replace hub = "IN" if hub == "INDIANA.HUB"
replace hub = "LA" if hub == "LOUISIANA.HUB"
replace hub = "IN" if hub == "MICHIGAN.HUB"
replace hub = "MN" if hub == "MINN.HUB"
replace hub = "MS" if hub == "MS.HUB"
replace hub = "TX" if hub == "TEXAS.HUB"
collapse (mean) price, by(hub date hour)
reshape wide price, i(date hour) j(hub) string
gen month=month(date)
keep if month > 5 & month < 10
rename hour localhour
gen negativeprice= 0
global ct = 0
foreach v in AR IL IN LA IN MN MS TX {
replace negativeprice = 1 if (price`v' < $ct)  
}
collapse (sum) negativeprice, by(localhour)
replace negativeprice = negativeprice/122


merge 1:1 localhour using $temp, nogen keep(3)
scatter btildaMIDW negativeprice negativeprice, xtitle("percent of hour with zero prices in any MIDW load zone") ytitle("percent wind on margin") legend(off)

asdfasdfa




keep if year(date)==`y'
if `y'>2013 append using temp
sort date hour
save $temp, replace

** read prices for other markets
import delimited using "$rawreg/FERC/xx", clear

asdf

from JEPreliability

save ferc714lambda, replace
import delimited using "$raw/FERC714/Part 2 Schedule 6 - Balancing Authority Hourly System Lambda.csv", clear
merge m:1 respondent_id using ferc714lambda.dta, keep(3) nogen
save ferc714lambda, replace

** make Table 2
use ferc714lambda, clear
replace respondent_name=trim(respondent_name)
gen market = ""
replace market = "CAISO" if respondent_name=="California Independent System Operator"
replace market = "ERCOT" if respondent_name=="ERCOT"
replace market = "ISONE" if respondent_name=="ISO New England Inc."
replace market = "MISO" if respondent_name=="MISO"
replace market = "NYISO" if respondent_name=="New York Independent System Operator, Inc."
replace market = "PJM" if respondent_name=="PJM Interconnection LLC"
replace market = "SPP" if respondent_name=="Southwest Power Pool (SPP)"
gen date=date(reverse(substr(reverse(lambda_date),8,.)),"MDY")
format date %td
keep market date hour*
drop if market==""
drop hour*f
forvalues x = 1/9 {
	rename hour0`x' hour`x'
}
reshape long hour, i(market date) j(hr)
rename hour price
drop if price==0
keep if year(date)>2012
format price %9.2f
reshape wide price, i(date hr) j(market) string
foreach x in ERCOT ISONE MISO NYISO PJM SPP {
	rename price`x' `x'
	label var `x' "`x'"
}
rename hr hour
merge 1:1 date hour using temp
gen CAISO = (priceN+priceS+priceZ)/3
order date hour CAISO ERCOT 
label var CAISO "CAISO (California)"
label var ERCOT "ERCOT (Texas)"
label var ISONE "ISO-NE (New England)"
label var MISO "MISO (Midwest)"
label var NYISO "NYISO (New York)"
label var PJM "PJM (Mid-Atlantic)"
label var SPP "SPP (Southwest)"
** from http://repec.org/bocode/e/estout/hlp_estout.html and
** from https://medium.com/the-stata-guide/the-stata-to-latex-guide-6e7ed5622856
est clear  // clear the stored estimates
estpost tabstat CAISO-SPP, c(stat) stat(mean sd min p10 median p90 max) 
cd "$results"
capture erase "$results/Tab2.tex"
esttab using "$results/Tab2.tex", replace cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min p10 p50 p90 max") nonumber nomtitle nonote noobs label collabels("Mean" "SD" "Min" "P10" "Median" "P90" "Max")
ereturn list // list the stored locals
capture erase cd "$dta/temp.dta"







***************************************************

from long run





* for non-market regions (CAR, FLA, NW, SE, SW, and TEN), use FERC data on system lambdas
insheet using "../rawdata/ferc714/Part 1 Schedule 1 - Identification Certification.csv", clear
keep if report_yr==2019
keep respondent_id plan_area_name company_addr poc_phone
*gen areacode =substr(poc_phone,1,3)
*destring(areacode), replace
*merge m:1 areacode using data\area_codes.dta, keep(1 3) // source: https://www.bennetyee.org/ucsd-pages/area.html
*rename state phstate
*rename company_addr c
*split c, p(,)
keep respondent_id plan_area_name 
duplicates drop
save $temp1, replace 
insheet using "../rawdata/ferc714/Part 3 Schedule 3 - Planning Area Forecast Demand.csv", clear
keep if report_yr==2019
keep if plan_year==2020
keep respondent_id summer_forecast
merge 1:1 respondent_id using $temp1, nogen
save $temp1, replace
insheet using "../rawdata/ferc714/Respondent IDs.csv", clear
keep respondent_id eia_code
replace eia_code=14354 if respondent_id==307 & eia_code==0 // PacifiCorp
replace eia_code=18195 if respondent_id==299 // Southern Power Company
replace eia_code=59504 if respondent_id==257 // Southwest Power Pool
replace eia_code=2775 if respondent_id==125 // California ISO
replace eia_code=25470 if respondent_id==272 // WAPA region
drop if eia_code==0
merge 1:1 respondent_id using $temp1, nogen
save $temp1, replace
import excel using "../rawdata/eia861/Utility_Data_2019.xlsx", first sheet("States") cellrange(A2:AG3339) clear
rename *, lower
rename utilitynumber eia_code
keep eia_code utilityname state nercregion
duplicates drop
drop if eia_code == 88888
save data/ferc714_state.dta, replace
merge 1:m eia_code using $temp1, keep(2 3) nogen
order respondent_id plan_area_name
gen region = ""
replace region = "CAR" if inlist(state,"NC","SC") & nercregion=="SERC"
replace region = "FLA" if nercregion=="FRCC"
replace region = "NW" if nercregion=="WECC" & inlist(state,"CA","AZ","NM")==0
replace region = "SE" if nercregion=="SERC" & inlist(state,"NC","SC","TN")==0
replace region = "SW" if inlist(state,"AZ","NM") & nercregion=="WECC"
replace region = "TEN" if state=="TN"
sort respondent_id
save data/ferc714_info.dta, replace

insheet using "../rawdata/ferc714/Part 2 Schedule 6 - Balancing Authority Hourly System Lambda.csv", clear
keep if report_yr==2019
egen totlam=sum(hour01),by(respondent_id)
*table respondent_id if totlam>0,c(mean hour01 mean hour12)
merge m:1 respondent_id using data/ferc714_info.dta, nogen keep(1 3)
drop if region==""
drop if totlam==0
gen temp = lambda_date 
split temp, p(" ")
drop temp temp2
rename temp1 temp
split temp, p("/")
destring temp*, replace
gen date = mdy(temp1,temp2,temp3)
format date %td
drop temp*
/*
order respondent_id region plan_area_name state summer_forecast
sort respondent_id lambda_date
egen tag=tag(respondent_id)
sort region state plan_area_name
br if tag
*/
keep region date hour01-hour25 summer_forecast
collapse (mean) hour* [w=summer_forecast],by(region date)
order region date
sort region date
forvalue n = 1/9 {
	rename hour0`n' hour`n'
	}
reshape long hour, i(region date) j(h)
rename hour price
rename h hour
drop if hour==25 & price ==0
append using $temp
collapse (mean) price, by(region date hour)
sort region date hour
save data/prices.dta, replace
