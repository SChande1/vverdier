
global thehour= 23

qui use "data/Hourly_Balancing_Load22_imports.dta", clear
qui keep if bacode=="ERCO"
qui gen  year= year(utcdate)
qui drop if year == 2022
qui keep if utchour== $thehour
qui gen month = month(utcdate)
qui keep if month >= $monthlow 
qui keep if month <= $monthhigh
qui keep utcdate utchour demand  
qui sort utcdate utchour



use "data/Hourly_Regional_Load_Generation22.dta", clear
keep if region=="TEX"
gen  year= year(date)
drop if year == 2022
keep if hour== $thehour
gen month = month(date)
keep if month >= $monthlow 
keep if month <= $monthhigh
keep date hour demand 
rename demand demandReg
rename date utcdate
rename hour utchour
merge 1:1 utcdate utchour using $temp1, nogen
