
*global AllRegions CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX



global monthlow= 6
global monthhigh= 9




*code to generate ba trading partners
* just need to run once, and copy the text output to create the global variables defined below

if 0{
foreach ba in $AllBAcodes{
	 qui import excel using "../rawdata/EIA930/BA files web download/`ba'.xlsx", cellrange(A1) clear firstrow
	 qui capture drop CO2Emissions*
	 qui capture drop Subregion*
	 qui lookfor $AllBAcodes
	 foreach var in `r(varlist)' {
		qui rename `var' demand`var'
	}
	qui keep demand*
	* this resets r(varlist)
	qui ds
	dis "global `ba'_demands " r(varlist)

}
}


* Use BA trading partners demands as control variable for regression
global AEC_demands demandMISO demandSOCO
global CPLW_demands demandDUK demandPJM demandTVA
global SOCO_demands demandAEC demandDUK demandFPC demandFPL demandMISO demandSC demandSCEG demandTAL demandTVA
global SC_demands demandCPLE demandDUK demandSCEG demandSOCO
global MISO_demands demandAEC demandAECI demandLGEE demandPJM demandSOCO demandSPA demandSWPP demandTVA
global NYIS_demands demandISNE demandPJM
global FPC_demands demandFMPP demandFPL demandGVL demandNSB demandSEC demandSOCO demandTAL demandTEC
global SEC_demands demandFPC demandFPL demandJEA demandTEC
global FPL_demands demandFMPP demandFPC demandGVL demandHST demandJEA demandNSB demandSEC demandSOCO demandTEC
global FMPP_demands demandFPC demandFPL demandJEA demandTEC
global NSB_demands demandFPC demandFPL
global ISNE_demands demandNYIS
global DUK_demands demandCPLE demandCPLW demandPJM demandSC demandSCEG demandSOCO demandTVA
global SCEG_demands demandCPLE demandDUK demandSC demandSOCO
global HST_demands demandFPL
global PJM_demands demandCPLE demandCPLW demandDUK demandLGEE demandMISO demandNYIS demandTVA
global AECI_demands demandMISO demandSPA demandSWPP demandTVA
global SWPP_demands demandAECI demandEPE demandERCO demandMISO demandPNM demandPSCO demandSPA demandWACM demandWAUW
global TAL_demands demandFPC demandSOCO
global LGEE_demands demandMISO demandPJM demandTVA
global GVL_demands demandFPC demandFPL
global CPLE_demands demandDUK demandPJM demandSC demandSCEG
global TEC_demands demandFMPP demandFPC demandFPL demandSEC
global SPA_demands demandAECI demandMISO demandSWPP
global TVA_demands demandAECI demandCPLW demandDUK demandLGEE demandMISO demandPJM demandSOCO
global JEA_demands demandFMPP demandFPL demandSEC
global WAUW_demands demandNWMT demandSWPP demandWACM
global DOPD_demands demandBPAT demandCHPD
global BANC_demands demandBPAT demandCISO demandTIDC
global BPAT_demands demandAVA demandBANC demandCHPD demandCISO demandDOPD demandGCPD demandIPCO demandLDWP demandNEVP demandNWMT demandPACW demandPGE demandPSEI demandSCL demandTPWR
global NWMT_demands demandAVA demandBPAT demandIPCO demandPACE demandWAUW
global PNM_demands demandAZPS demandEPE demandPSCO demandSRP demandSWPP demandTEPC demandWACM
global PACW_demands demandAVA demandBPAT demandCISO demandGCPD demandIPCO demandPACE demandPGE
global SCL_demands demandBPAT demandPSEI
global IID_demands demandAZPS demandCISO demandWALC
global IPCO_demands demandAVA demandBPAT demandNEVP demandNWMT demandPACE demandPACW
global WALC_demands demandAZPS demandCISO demandIID demandLDWP demandNEVP demandSRP demandTEPC demandWACM
global GCPD_demands demandAVA demandBPAT demandPACW demandPSEI
global PGE_demands demandBPAT demandPACW
global PSEI_demands demandBPAT demandCHPD demandGCPD demandSCL demandTPWR
global TIDC_demands demandBANC demandCISO
global NEVP_demands demandBPAT demandCISO demandIPCO demandLDWP demandPACE demandWALC
global EPE_demands demandPNM demandSWPP demandTEPC
global AVA_demands demandBPAT demandCHPD demandGCPD demandIPCO demandNWMT demandPACW
global LDWP_demands demandAZPS demandBPAT demandCISO demandNEVP demandPACE demandWALC
global SRP_demands demandAZPS demandCISO demandPNM demandTEPC demandWALC
global WACM_demands demandAZPS demandPACE demandPNM demandPSCO demandSWPP demandWALC demandWAUW
global TEPC_demands demandAZPS demandEPE demandPNM demandSRP demandWALC
global CISO_demands demandAZPS demandBANC demandBPAT demandIID demandLDWP demandNEVP demandPACW demandSRP demandTIDC demandWALC
global CHPD_demands demandAVA demandBPAT demandDOPD demandPSEI
global PSCO_demands demandPNM demandSWPP demandWACM
global AZPS_demands demandCISO demandIID demandLDWP demandPACE demandPNM demandSRP demandTEPC demandWACM demandWALC
global TPWR_demands demandBPAT demandPSEI
global PACE_demands demandAZPS demandIPCO demandLDWP demandNEVP demandNWMT demandPACW demandWACM
global ERCO_demands demandSWPP




* do again to include mexican and canandian ba codes that trade with a few ba's (ISNE, ERCO,....)
if 0{
foreach ba in $AllBAcodes{
	qui import excel using "../rawdata/EIA930/BA files web download/`ba'.xlsx", cellrange(A1) clear firstrow
	
	qui capture drop CO2Emissions*
	qui capture drop Subregion*
	rename *, lower
	qui lookfor $AllBAcodes $BA_Canada $BA_Mexico
	dis "global `ba'_imports " r(varlist)

}
}
* imports from other BA's: other BA trading partners plus mexico and canada
global AEC_imports miso soco
global CPLW_imports duk pjm tva
global SOCO_imports aec duk fpc fpl miso sc sceg tal tva
global SC_imports cple duk sceg soco
global MISO_imports aec aeci ieso lgee mheb pjm soco spa swpp tva
global NYIS_imports hqt ieso isne pjm
global FPC_imports fmpp fpl gvl nsb sec soco tal tec
global SEC_imports fpc fpl jea tec
global FPL_imports fmpp fpc gvl hst jea nsb sec soco tec
global FMPP_imports fpc fpl jea tec
global NSB_imports fpc fpl
global ISNE_imports hqt nbso nyis
global DUK_imports cple cplw pjm sc sceg soco tva
global SCEG_imports cple duk sc soco
global HST_imports fpl
global PJM_imports cple cplw duk lgee miso nyis tva
global AECI_imports miso spa swpp tva
global SWPP_imports aeci epe erco miso pnm psco spa spc wacm wauw
global TAL_imports fpc soco
global LGEE_imports miso pjm tva
global GVL_imports fpc fpl
global CPLE_imports duk pjm sc sceg
global TEC_imports fmpp fpc fpl sec
global SPA_imports aeci miso swpp
global TVA_imports aeci cplw duk lgee miso pjm soco
global JEA_imports fmpp fpl sec
global WAUW_imports nwmt swpp wacm
global DOPD_imports bpat chpd
global BANC_imports bpat ciso tidc
global BPAT_imports ava banc bcha chpd ciso dopd gcpd ipco ldwp nevp nwmt pacw pge psei scl tpwr
global NWMT_imports aeso ava bpat ipco pace wauw
global PNM_imports azps epe psco srp swpp tepc wacm
global PACW_imports ava bpat ciso gcpd ipco pace pge
global SCL_imports bpat psei
global IID_imports azps ciso walc
global IPCO_imports ava bpat nevp nwmt pace pacw
global WALC_imports azps ciso iid ldwp nevp srp tepc wacm
global GCPD_imports ava bpat pacw psei
global PGE_imports bpat pacw
global PSEI_imports bpat chpd gcpd scl tpwr
global TIDC_imports banc ciso
global NEVP_imports bpat ciso ipco ldwp pace walc
global EPE_imports pnm swpp tepc
global AVA_imports bpat chpd gcpd ipco nwmt pacw
global LDWP_imports azps bpat ciso nevp pace walc
global SRP_imports azps ciso pnm tepc walc
global WACM_imports azps pace pnm psco swpp walc wauw
global TEPC_imports azps epe pnm srp walc
global CISO_imports azps banc bpat cen cfe iid ldwp nevp pacw srp tidc walc
global CHPD_imports ava bpat dopd psei
global PSCO_imports pnm swpp wacm
global AZPS_imports ciso iid ldwp pace pnm srp tepc wacm walc
global TPWR_imports bpat psei
global PACE_imports azps ipco ldwp nevp nwmt pacw wacm
global ERCO_imports cen cfe swpp

* put bacodes (including cananda and mexico) in a list
clear
set obs 1
gen bacode = "xx"
save $temp6, replace
foreach bab in $AllBAcodes{
	foreach name in $`bab'_imports{
		clear
		set obs 1
		gen bacode=""
		replace bacode = "`name'"
		append using $temp6
		save $temp6, replace
	}
}
sort bacode
duplicates drop
drop if bacode=="xx"
rename bacode type
save $temp6, replace


* set up temp 5 with generation and all bacodes
clear
set obs 7
gen type = ""
replace type = "gencoal" in 1
replace type = "gengas" in 2
replace type = "gennuke" in 3
replace type = "genoil" in 4
replace type = "gensun" in 5
replace type = "genwater" in 6
replace type = "genwind" in 7
append using $temp6
save $temp5, replace 




* generation types
global All_BA_generation gencoal gengas gennuke genoil genwater gensun genwind



global thehour= 23

foreach region in $AllBAcodes {
*foreach region in NE{
dis " `region' $`region'_demands"

*only run summer months
global monthlow= 6
global monthhigh= 9

* bring in all data
foreach region2 in $AllBAcodes{ 
qui use "data/Hourly_Balancing_Load22_imports.dta", clear
qui keep if bacode=="`region2'"
qui gen  year= year(utcdate)
qui drop if year == 2022
qui keep if utchour== $thehour
qui gen month = month(utcdate)
qui keep if month >= $monthlow 
qui keep if month <= $monthhigh
qui keep utcdate utchour demand  year month
qui sort utcdate utchour
qui rename demand demand`region2'
if "`region2'"=="AEC" {
	qui save $temp2, replace
}
else{
	qui merge 1:1 utcdate utchour using $temp2, nogen
	qui save $temp2, replace
}
}

*dis "`region'"
*drop current region
qui drop demand`region'
qui save $temp2, replace

* bring in data for current region2
qui use "data/Hourly_Balancing_Load22_imports.dta", clear
qui keep if bacode=="`region'"
qui gen  year= year(utcdate)
qui drop if year == 2022
qui keep if utchour== $thehour
qui gen month = month(utcdate)
qui keep if month >= $monthlow 
qui keep if month <= $monthhigh
qui keep utcdate utchour demand $All_BA_generation $`region'_imports year month
qui sort utcdate utchour
* set up fixed effects by yr, month, day of week, hour
qui gen moyr = year*100+month
qui gen dow = dow(utcdate)
qui capture drop group
qui egen group = group(year month dow utchour)


** negative means imports, so multiply by -1 to indicate generation from imports
** increase in load on average should increase imports, decreases in load should decrease imports/exportsgn
foreach imp in $`region'_imports {
qui replace `imp' = -`imp'
}

* replacing missing generation with zeros
foreach gen in $All_BA_generation{
	qui replace `gen' = 0 if `gen'==.
}
* replacing missing imports with zeros
foreach imp in $`region'_imports{
	qui replace `imp' = 0 if `imp'==.
}
qui save $temp1, replace


qui use $temp1, clear
qui merge 1:1 utcdate utchour using $temp2, nogen
qui save $temp4, replace


qui local cot=0
* loop through all units in the interconnection
* create yX and XX matrices for each unit
* stack them in column vectors
dis "creating matrices for python"
foreach generate in $All_BA_generation $`region'_imports  {
	dis "generation  `generate'"
	
	*use $temp1, clear
	qui use $temp4, clear
	qui gen constant = 1

	
		*local varstouse  `region' demand constant i.group 
		*local varstouse `region' demand demandCAR demandCENT demandFLA demandMIDA demandMIDW demandNE demandSE demandTEN i.group
		*local varstouse `region' demand demandCAR demandCENT  demandMIDA demandMIDW demandNE demandSE  i.group
		local varstouse `generate' demand $`region'_demands constant i.group
		* zero means exclude missing
		mata: data  = st_data(.,"`varstouse'",0)
		mata: st_matrix("data",data)
		
		local numcol=`=colsof(data)'
		
	
		*See help matrix extraction  
		matrix y = data[1...,1]
		matrix x = data[1...,2]
		matrix w = data[1...,3..`numcol']
		
		*matselrc data y, c(1)
		*matselrc data x, c(2)
		*matselrc data w, c(3/`numcol')
		
		
		local dim `=rowsof(y)'
		matrix Id=I(`dim')
		matrix M = Id - w*invsym(w'*w)*w'
		
		matrix XX = x'*M*x
		*matrix Xy= x'*M*y
		*matrix yX = Xy'
		matrix yX = y'*M*x
		
		
		** stata can't handle big matrices, so save  XX matrix as a  .dta file
		** and append new XX matrix for each unit 
		** store yX and idnums directly as matrices and append new ones for each unit
		
		if `cot'==0 {
			matrix TEX_yX=yX
			matrix unitnums=[`cot']
			drop _all
			qui svmat double XX 
			qui save "$tempdir/bigmattemp.dta", replace
		}
		else {
			
			
			matrix TEX_yX= TEX_yX\yX
			matrix temp=[`cot']
			matrix unitnums=unitnums\temp
			drop _all
			qui svmat double XX
			qui save "$tempdir/mattemp.dta", replace
			qui use "$tempdir/bigmattemp.dta", clear
			qui append using "$tempdir/mattemp.dta"
			qui save  "$tempdir/bigmattemp.dta", replace
			
		}
		
		local cot=`cot'+1
	}
	

dis "total" `cot'
* dump big column matrices into excel files to transfer to python
* also transfer list of unit numbers
*A1 is cell number

** XX matrix is stored as a stata dta file
use "$tempdir/bigmattemp.dta"
export excel "../python/XX.xlsx", nolabel replace
** yX and unitnums are stored as matrices
qui putexcel set "../python/yX.xlsx", replace
qui putexcel A1=matrix(TEX_yX)
qui putexcel set "../python/unitnums.xlsx", replace
qui putexcel A1=matrix(unitnums)


**** call python to do constrained regression
dis "call python"
qui cd "../python"

** version 3 uses sparse matrices to save memory and relaxes the convergence criteria from 1e-12 to 1e-9
** version 4 uses upper diagonal sparse matrix for P (which is all OSPQ needs). THis saves memory for the "Sub" case
python script "regular_v4.py"
qui cd "../stata"

* import coefficients from python output
qui import   excel using "../python/temp_output.xlsx",  clear firstr 

* doing one at a time, so only one coefficient vector returned
qui rename A idnum
qui rename B btilda`region'

qui gen type = ""
qui local ctr = 1
foreach thetype in $All_BA_generation $`region'_imports {
qui replace type = "`thetype'" in `ctr'
qui local ctr = `ctr'+1
}

qui merge 1:1 type using $temp5, nogen keep(1 2 3)

save $temp5, replace
save "tempcross.dta", replace

}

save "data/cross_balance_generation_930only.dta"






