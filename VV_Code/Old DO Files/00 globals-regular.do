
*  1 Stephen laptop; 2 Andy; 3 Erin home pc; 4 Stephen work; 5 Erin home mac; 6 Erin work pc


clear

capture cd "C:\Users\sphollan\Dropbox\Regular\Stata"
if _rc ==0 global user 1
capture cd "/Users/andrewjyates/Dropbox/Regular/Stata"
if _rc ==0 global user 2
capture cd "F:\Dropbox (Dartmouth College)\Regular\Stata"
if _rc ==0 global user 3
capture cd "D:\Dropbox\Regular\Stata"
if _rc ==0 global user 4
capture cd "/Users/d33365v/Dropbox (Dartmouth College)/Regular/Stata"
if _rc==0 global user 5
capture cd "C:\data\Dropbox (Dartmouth College)\Regular\Stata"
if _rc==0 global user 6
capture cd "/Users/andyyates/Dropbox/Regular/Stata"
if _rc==0 global user 7
capture cd "/Users/valentinverdier/Dropbox/Regular/Stata"
if _rc==0 global user 8
capture cd "/proj/econ/vverdier/Regular/Stata"
if _rc==0 global user 9


if $user == 1 global raw "C:\Users\sphollan\Dropbox\Andy Nick Erin\raw data"
if $user == 2 global raw "/Users/andrewjyates/Dropbox/electric cars/raw data"
if $user == 3 global raw "F:\Dropbox (Dartmouth College)\HMMY_Papers\raw data"
if $user == 4 global raw "D:\Dropbox\Andy Nick Erin\raw data"
if $user == 5 global raw "/Users/d33365v/Dropbox (Dartmouth College)/hmmy_papers/raw data"
if $user == 6 global raw "C:\data\Dropbox (Dartmouth College)\HMMY_Papers\raw data"
if $user == 8 global raw "/Users/valentinverdier/Dropbox/electric cars/raw data"
if $user == 9 global raw "/proj/econ/vverdier/Regular/raw"

if $user == 1 global tempdir "C:\Users\sphollan\Documents"
if $user == 2 global tempdir "/Users/andrewjyates/desktop"
if $user == 3 global tempdir "F:\ElecCarSubsidy\Stata"
if $user == 4 global tempdir "C:\Users\sphollan\Documents"
if $user == 5 global tempdir "/Users/d33365v/Documents/Stata"
if $user == 6 global tempdir "C:\Data\ElecCarSubsidy\Stata"
if $user == 7 global tempdir "/Users/andyyates/desktop"
if $user == 8 global tempdir "/Users/valentinverdier/Dropbox/temp_folder_Regular"
if $user == 9 global tempdir "/proj/econ/vverdier/Regular/Stata/vv_temp"

if $user == 2 global cemsdir "/Users/andrewjyates/dropbox/CEMS"
if $user == 3 global cemsdir "F:\Dropbox (Dartmouth College)\CEMS"
if $user == 5 global cemsdir "/Users/d33365v/Dropbox (Dartmouth College)/CEMS"
if $user == 6 global cemsdir "C:\data\Dropbox (Dartmouth College)\CEMS"

if $user == 2 global datadir "/Users/andrewjyates/dropbox/Regular/Stata/data"
if $user == 3 global datadir "F:\Dropbox (Dartmouth College)\Regular\Stata\data"
if $user == 5 global datadir "/Users/d33365v/Dropbox (Dartmouth College)/Regular/Stata/data"
if $user == 6 global datadir "C:\data\Dropbox (Dartmouth College)\Regular\Stata\data"
if $user == 7 global datadir "/Users/andyyates/dropbox/Regular/Stata/data"
if $user == 8 global datadir "/Users/valentinverdier/Dropbox/Regular/Stata/data"
if $user == 9 global datadir "/proj/econ/vverdier/Regular/Stata/data"

if $user == 2 global cemsdirreg "/Users/andrewjyates/Dropbox/Regular/rawdata/CEMS"
if $user == 3 global cemsdirreg "F:\Dropbox (Dartmouth College)\Regular\rawdata\CEMS"
if $user == 5 global cemsdirreg "/Users/d33365v/Dropbox (Dartmouth College)/Regular/rawdata/CEMS"
if $user == 6 global cemsdirreg "C:\data\Dropbox (Dartmouth College)\Regular\rawdata\CEMS"

if $user == 2 global rawreg "/Users/andrewjyates/Dropbox/Regular/rawdata"
if $user == 3 global rawreg "F:\Dropbox (Dartmouth College)\Regular\rawdata"
if $user == 5 global rawreg "/Users/d33365v/Dropbox (Dartmouth College)/Regular/rawdata"
if $user == 6 global rawreg "C:\data\Dropbox (Dartmouth College)\Regular\rawdata"
if $user == 7 global rawreg "/Users/andyyates/Dropbox/Regular/rawdata"
if $user == 8 global rawreg "/Users/valentinverdier/Dropbox/Regular/rawdata"

if $user == 1 global rawkill "C:\Users\sphollan\Dropbox\KillCoal\Raw Data"
if $user == 2 global rawkill "/Users/andrewjyates/Dropbox/KillCoal/Raw Data"
if $user == 3 global rawkill "F:\Dropbox (Dartmouth College)\KillCoal\Raw Data"
if $user == 5 global rawkill "/Users/d33365v/Dropbox (Dartmouth College)/KillCoal/Raw Data"
if $user == 6 global rawkill "C:\data\Dropbox (Dartmouth College)\KillCoal\Raw Data"
if $user == 7 global rawkill "/Users/andy/Dropbox/KillCoal/Raw Data"
if $user == 8 global rawkill "/Users/andrewjyates/Dropbox/KillCoal/Raw Data"

if $user == 1 global rawmarge "C:\Users\sphollan\Dropbox\MargEmitNew\Raw Data"
if $user == 2 global rawmarge "/Users/andrewjyates/Dropbox/MargEmitNew/Raw Data"
if $user == 3 global rawmarge "F:\Dropbox (Dartmouth College)\MargEmitNew\Raw Data"
if $user == 5 global rawmarge "/Users/d33365v/Dropbox (Dartmouth College)/MargEmitNew/Raw Data"
if $user == 6 global rawmarge "C:\data\Dropbox (Dartmouth College)\MargEmitNew\Raw Data"
if $user == 7 global rawmarge "/Users/andyyates/Dropbox/MargEmitNew/Raw Data"


global temp  "$tempdir/temp.dta"
global temp1 "$tempdir/temp1.dta"
global temp2 "$tempdir/temp2.dta"
global temp3 "$tempdir/temp3.dta"
global temp4 "$tempdir/temp4.dta"
global temp5 "$tempdir/temp5.dta"
global temp6 "$tempdir/temp6.dta"
global temp7 "$tempdir/temp7.dta"
global temp8 "$tempdir/temp8.dta"
global temp9 "$tempdir/temp9.dta"
global temp10 "$tempdir/temp10.dta"
global temp11 "$tempdir/temp11.dta"

global AllRegions CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX
global RegionsEast CAR CENT FLA MIDA MIDW NE NY SE TEN
global RegionsWest CAL NW SW
global RegionsTexas TEX

*global hoursShort 1
global hoursShort  1 17 23 24
global hoursAll 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24

global EastBaCodes demandAEC demandCPLW demandSOCO demandEEI demandSC demandGLHB demandMISO demandNYIS demandFPC demandSEC demandFPL demandFMPP demandSEPA demandNSB demandISNE demandDUK demandSCEG demandHST demandPJM demandAECI demandYAD demandSWPP demandTAL demandLGEE demandGVL demandCPLE demandTEC demandSPA demandTVA demandJEA 
global WestBaCodes demandWAUW demandDEAA demandDOPD demandBANC demandBPAT demandNWMT demandPNM demandPACW demandHGMA demandSCL demandIID demandIPCO demandWALC demandGWA demandGCPD demandPGE demandPSEI demandTIDC demandNEVP demandGRID demandEPE demandAVA demandLDWP demandAVRN demandSRP demandWACM demandTEPC demandCISO demandGRIF demandCHPD demandPSCO demandAZPS demandTPWR demandPACE demandWWA
global TexasBaCodes demandERCO

* lists with some BA codes dropped due to no data
global EastBaCodesDr demandAEC demandCPLW demandSOCO  demandSC  demandMISO demandNYIS demandFPC demandSEC demandFPL demandFMPP  demandNSB demandISNE demandDUK demandSCEG demandHST demandPJM demandAECI  demandSWPP demandTAL demandLGEE demandGVL demandCPLE demandTEC demandSPA demandTVA demandJEA 

global WestBaCodesDr demandWAUW  demandDOPD demandBANC demandBPAT demandNWMT demandPNM demandPACW  demandSCL demandIID demandIPCO demandWALC  demandGCPD demandPGE demandPSEI demandTIDC demandNEVP  demandEPE demandAVA demandLDWP  demandSRP demandWACM demandTEPC demandCISO  demandCHPD demandPSCO demandAZPS demandTPWR demandPACE 
global TexasBaCodes demandERCO

* 82 east subBA
* subregion codes (replace demand for CISO,ISNE,MISO,NYIS,PJM,SWPP,ERCO with subregion demands)
* dropped RECO because no variationn in demand (was between PS and CSWS)
global EastSubCodes demandAEC demandCPLW demandSOCO  demandSC  demandFPC demandSEC demandFPL demandFMPP  demandNSB  demandDUK demandSCEG demandHST  demandAECI   demandTAL demandLGEE demandGVL demandCPLE demandTEC demandSPA demandTVA demandJEA demand4001 demand4002 demand4003 demand4004 demand4005 demand4006 demand4007 demand4008 demand1 demand27 demand35 demand4 demand6 demand8910 demandZONA demandZONB demandZONC demandZOND demandZONE demandZONF demandZONG demandZONH demandZONI demandZONJ demandZONK demandAE demandAEP demandAP demandATSI demandBC demandCE demandDAY demandDEOK demandDOM demandDPL demandDUQ demandEKPC demandJC demandME demandPE demandPEP demandPL demandPN demandPS  demandCSWS demandEDE demandGRDA demandINDN demandKACY demandKCPL demandLES demandMPS demandNPPD demandOKGE demandOPPD demandSECI demandSPRM demandSPS demandWAUE demandWFEC demandWR

*31 west subBA
global WestSubCodes demandWAUW  demandDOPD demandBANC demandBPAT demandNWMT demandPNM demandPACW  demandSCL demandIID demandIPCO demandWALC  demandGCPD demandPGE demandPSEI demandTIDC demandNEVP  demandEPE demandAVA demandLDWP  demandSRP demandWACM demandTEPC demandCHPD demandPSCO demandAZPS demandTPWR demandPACE demandPGAE demandSCE demandSDGE demandVEA

* 8 tex subBA
global TexasSubCodes demandCOAS demandEAST demandFWES demandNCEN demandNRTH demandSCEN demandSOUT demandWEST

global AllBAcodes  AEC CPLW SOCO  SC  MISO NYIS FPC SEC FPL FMPP  NSB ISNE DUK SCEG HST PJM AECI  SWPP TAL LGEE GVL CPLE TEC SPA TVA JEA WAUW DOPD BANC BPAT NWMT PNM PACW  SCL IID IPCO WALC GCPD PGE PSEI TIDC NEVP  EPE AVA LDWP  SRP WACM TEPC CISO  CHPD PSCO AZPS TPWR PACE ERCO
global NE_bacode 


* dropped RECO because no variationn in demand (was between PS and CSWS)
global AllsubBAcodes  AEC CPLW SOCO  SC  FPC SEC FPL FMPP  NSB  DUK SCEG HST  AECI   TAL LGEE GVL CPLE TEC SPA TVA JEA 4001 4002 4003 4004 4005 4006 4007 4008 1 27 35 4 6 8910 ZONA ZONB ZONC ZOND ZONE ZONF ZONG ZONH ZONI ZONJ ZONK AE AEP AP ATSI BC CE DAY DEOK DOM DPL DUQ EKPC JC ME PE PEP PL PN PS CSWS EDE GRDA INDN KACY KCPL LES MPS NPPD OKGE OPPD SECI SPRM SPS WAUE WFEC WR WAUW  DOPD BANC BPAT NWMT PNM PACW  SCL IID IPCO WALC  GCPD PGE PSEI TIDC NEVP  EPE AVA LDWP  SRP WACM TEPC CHPD PSCO AZPS TPWR PACE PGAE SCE SDGE VEA COAS EAST FWES NCEN NRTH SCEN SOUT WEST

* canadian and mexico ba codes 

global BA_Canada AESO BCHA HQT IESO MHEB NBSO SPC 

global BA_Mexico CEN CFE



global types 1

if 0 {
ssc install spmap, replace
ssc install winsor2, replace
ssc install cfout, replace
set type double, permanently
}

*** basic data about number of BA's and subBA'some
local count = 0
foreach var in $AllsubBAcodes{
	 local count = `count'+1
}
dis "Number of subBA's `count'"

local count = 0
foreach var in $AllBAcodes{
	 local count = `count'+1
}
dis "Number of BA's `count'"

local count = 0
foreach var in $EastSubCodes{
	local count = `count'+1
}
dis "Number of subBA's in East `count'"

local count = 0
foreach var in $WestSubCodes{
	local count = `count'+1
}
dis "Number of subBA's in West `count'"

local count = 0
foreach var in $TexasSubCodes{
	local count = `count'+1
}
dis "Number of subBA's in Texas `count'"

*basub codes by region

global CAL_BA BANC IID LDWP PGAE SCE SDGE TIDC VEA
global CAR_BA CPLE CPLW DUK SC SCEG YAD
global CENT_BA CSWS EDE GRDA INDN KACY KCPL LES MPS NPPD OKGE OPPD SECI SPA SPRM SPS WAUE WFEC WR
global FLA_BA FMPP FPC FPL GVL JEA SEC TAL TEC
global MIDA_BA AE AEP AP ATSI BC CE DAY DEOK DOM DPL DUQ EKPC JC ME PE PEP PL PN PS
global MIDW_BA 1 27 35 4 6 8910
global NE_BA 4001 4002 4003 4004 4005 4006 4007 4008
global NW_BA AVA AVRN BPAT CHPD DOPD GCPD GRID GWA IPCO NEVP NWMT PACE PACW PGE PSCO PSEI SLC TPWR WACM WWA WAUW
global NY_BA ZONA ZONB ZONC ZOND ZONE ZONF ZONG ZONH ZONI ZONJ ZONK
global SE_BA AEC SEPA SOCO
global SW_BA AZPS EPE PNM SRP TEPC WALC
global TEN_BA TVA
global TEX_BA COAS EAST FWES NCEN NRTH SCEN SOUT WEST

*basub codes without basubs that do not have loads

global CAL_BA2 BANC IID LDWP PGAE SCE SDGE TIDC VEA
global CAR_BA2 CPLE CPLW DUK SC SCEG
global CENT_BA2 CSWS EDE GRDA INDN KACY KCPL LES MPS NPPD OKGE OPPD SECI SPA SPRM SPS WAUE WFEC WR
global FLA_BA2 FMPP FPC FPL GVL JEA SEC TAL TEC
global MIDA_BA2 AE AEP AP ATSI BC CE DAY DEOK DOM DPL DUQ EKPC JC ME PE PEP PL PN PS
global MIDW_BA2 1 27 35 4 6 8910
global NE_BA2 4001 4002 4003 4004 4005 4006 4007 4008
global NW_BA2 AVA BPAT CHPD DOPD GCPD IPCO NEVP NWMT PACE PACW PGE PSCO PSEI TPWR WACM WAUW
global NY_BA2 ZONA ZONB ZONC ZOND ZONE ZONF ZONG ZONH ZONI ZONJ ZONK
global SE_BA2 AEC SOCO
global SW_BA2 AZPS EPE PNM SRP TEPC WALC
global TEN_BA2 TVA
global TEX_BA2 COAS EAST FWES NCEN NRTH SCEN SOUT WEST
*end
global monthlow= 6
global monthhigh= 9
