** create weather data
* now using open meto data instead of NREL

* run "00 globals_regular.do"
import delimited using "../rawdata/open meteo weather/solar_data.csv", clear varname(1) // rowrange(1:1000)
drop v3 d* wind*100m temp
rename shortwave_radiation ghi 
rename windspeed_10m windspeed
*rename windspeed_100m highwind
*rename temp temperature
gen utcdate = date(substr(hourlytime,2,10),"YMD")
format utcdate %td
gen utchour = real(substr(hourlytime,13,2))+1
drop hourlytime 
order state county utcdate utchour 
save $temp10, replace

import delimited using "../rawdata/open meteo weather/state_codes.csv", clear varnames(1)
keep state code
save "data/state_codes.dta", replace

import delimited using "../rawdata/open meteo weather/counties.csv", clear varnames(1)
rename state code
keep code fips county
merge m:1 code using "data/state_codes.dta", keep(3) nogen
drop code
replace county = subinstr(county," ","_",.)
replace state = subinstr(state," ","_",.)
** note the ones that do not match are in alaska
merge 1:m state county using $temp10, keep(3) nogen
sort fips utcdate utchour
drop state county
save "data/open meteo.dta", replace

* need population to aggregate up from county to level of analysis
import excel using  "../rawdata/epa/ozone-county-population.xlsx", firstrow clear
destring STATEFIPS COUNTYFIPS, replace
gen fips = STATEFIPS*1000+COUNTYFIPS
rename STATETERRITORYNAME statename
keep fips F statename
rename F pop
order fips pop statename
save "data/fips_pop2015.dta", replace




exit

** test correlation with NOAA data/open
use "data/open meteo.dta", clear
rename ghi ghi2
rename temperature temperature2
rename windspeed windspeed2
merge 1:1 fips utcdate utchour using "data/nrel_nsrd.dta", keep(3)
sort fips utcdate utchour 
gen time = _n
xtset fips time 
/* 
reg ghi l.ghi2 
reg ghi ghi2
reg ghi f.ghi2 

reg windspeed l.windspeed2
reg windspeed windspeed2
reg windspeed f.windspeed2

reg temperature l.temperature2 
reg temperature temperature2
reg temperature f.temperature2 
*/
reg windspeed l.highwind
reg windspeed highwind
reg windspeed f.highwind
