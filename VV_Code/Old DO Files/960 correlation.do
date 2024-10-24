use "data/Hourly_Sub_Load.dta", clear
keep  subregion demand utcdate utchour 
reshape wide demand, i(utcdate utchour) j(subregion, string)
keep if utchour==1
save $temp1, replace



use "data/hourly/Hourly_Unit_and_Regional_Generation1.dta", clear
sort ID utcdate utchour
keep if ID=="ERCO_All_wind"

merge 1:1 utcdate utchour using $temp1
corr netgen demandFWES
corr netgen demandNRTH
corr netgen demandWEST


gen month = month(utcdate)
/*
***** just do  summer  months
keep if month >=6 & month <=9 
corr netgen demandFWES
corr netgen demandNRTH
corr netgen demandWEST
corr netgen demandNCEN
*/
gen yr = year(utcdate)
gen moyr = yr*100+month
gen dow = dow(utcdate)
egen group = group(yr month dow utchour)

foreach v in netgen demandFWES demandNRTH demandWEST demandNCEN {
qui capture drop `v'e
qui reg `v' i.group
disp e(r2)
qui predict `v'e, resid
}
corr netgen demandFWES demandNRTH demandWEST demandNCEN
corr netgene demandFWESe demandNRTHe demandWESTe demandNCENe
corr netgen demandFWES demandNRTH demandWEST demandNCEN if inrange(month,6,9)
corr netgene demandFWESe demandNRTHe demandWESTe demandNCENe if inrange(month,6,9)
