 use  "/Users/andrewjyates/Desktop/test2235-3.dta", clear
 reg netgen i.group tmp* wnd* ghi* if newid==2235
 
 use  "/Users/andrewjyates/Desktop/crash.dta", clear
 sort group
 reg netgen i.group tmp* wnd* ghi* if newid==2235
 
 use  "/Users/andrewjyates/Desktop/crash.dta", clear
 reg netgen i.group tmp* wnd* ghi* if newid==2235
 
 
 
 
 
 use "/Users/andrewjyates/Desktop/crash.dta", clear
  
 rename tmp* tmp*1
 rename wnd* wnd*1
 rename ghi* ghi*1
 rename netgen netgen1
 rename group group1
 
 merge 1:1 utcdate utchour newid using  "/Users/andrewjyates/Desktop/test2235-3.dta"
 
 reg netgen i.group tmp* wnd* ghi* if newid==2235
 
 *reg netgen1 i.group1 tmp*1 wnd*1 ghi*1 if newid==2235
 

 
 
use  "/Users/andrewjyates/Desktop/test2235-3.dta", clear
reg netgen i.group tmp* wnd* ghi* if newid==2235
 
rename tmp* tmp*1
rename wnd* wnd*1
rename ghi* ghi*1
rename netgen netgen1
rename group group1
 
dis "first"
reg netgen1 i.group1 tmp*1 wnd*1 ghi*1 if newid==2235
 
 
merge 1:1 utcdate utchour newid using  "/Users/andrewjyates/Desktop/crash.dta"

dis "second"
reg netgen i.group tmp* wnd* ghi* if newid==2235

reg netgen1 i.group1 tmp* wnd* ghi* if newid==2235

dis "third"
reg netgen1 i.group1 tmp*1 wnd*1 ghi*1 if newid==2235




* comapre

use "/Users/andrewjyates/Desktop/crash.dta", clear
  
 rename tmp* tmp*1
 rename wnd* wnd*1
 rename ghi* ghi*1
 rename netgen netgen1
 rename group group1
 
 merge 1:1 utcdate utchour newid using  "/Users/andrewjyates/Desktop/test2235-3.dta"
 
 gen diffng = netgen - netgen1
 sum diffng
 gen diffgroup = group - group1
 sum diffgroup
 
 
