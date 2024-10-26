import os

config = {
    "base_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier",
    "base1_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata",
    "base2_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files",
    "temp_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\temp_dir",
    "cems_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\cems_dir",
    "cems_dirreg": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\cems_dirreg",
    "data_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\data_dir",
    "rawdata_dir": r"C:\Users\shrey\Desktop\UNC CH Verdier\DO Files - Stata\refactored_files\rawdata_dir",
    "api_key_EIA": "gye6WLyAis3V6mBRbCsyWOv1JnPiOyR25mb1rQEz",
    "api_key_EPA": "PtmHdxj8oRfC0iZktCjTNuwet0aDS8lhsrnfgPND"
}

def main():
    for path in config.values():
        if not os.path.exists(path):
            os.makedirs(path)

# Regions
AllRegions = ["CAL", "CAR", "CENT", "FLA", "MIDA", "MIDW", "NE", "NW", "NY", "SE", "SW", "TEN", "TEX"]
RegionsEast = ["CAR", "CENT", "FLA", "MIDA", "MIDW", "NE", "NY", "SE", "TEN"]
RegionsWest = ["CAL", "NW", "SW"]
RegionsTexas = ["TEX"]

# Hours
hoursShort = [1, 17, 23, 24]
hoursAll = list(range(1, 25))

# BA Codes
EastBaCodes = ["demandAEC", "demandCPLW", "demandSOCO", "demandEEI", "demandSC", "demandGLHB", "demandMISO", "demandNYIS", "demandFPC", "demandSEC", "demandFPL", "demandFMPP", "demandSEPA", "demandNSB", "demandISNE", "demandDUK", "demandSCEG", "demandHST", "demandPJM", "demandAECI", "demandYAD", "demandSWPP", "demandTAL", "demandLGEE", "demandGVL", "demandCPLE", "demandTEC", "demandSPA", "demandTVA", "demandJEA"]
WestBaCodes = ["demandWAUW", "demandDEAA", "demandDOPD", "demandBANC", "demandBPAT", "demandNWMT", "demandPNM", "demandPACW", "demandHGMA", "demandSCL", "demandIID", "demandIPCO", "demandWALC", "demandGWA", "demandGCPD", "demandPGE", "demandPSEI", "demandTIDC", "demandNEVP", "demandGRID", "demandEPE", "demandAVA", "demandLDWP", "demandAVRN", "demandSRP", "demandWACM", "demandTEPC", "demandCISO", "demandGRIF", "demandCHPD", "demandPSCO", "demandAZPS", "demandTPWR", "demandPACE", "demandWWA"]
TexasBaCodes = ["demandERCO"]

# BA Codes with some dropped due to no data
EastBaCodesDr = ["demandAEC", "demandCPLW", "demandSOCO", "demandSC", "demandMISO", "demandNYIS", "demandFPC", "demandSEC", "demandFPL", "demandFMPP", "demandNSB", "demandISNE", "demandDUK", "demandSCEG", "demandHST", "demandPJM", "demandAECI", "demandSWPP", "demandTAL", "demandLGEE", "demandGVL", "demandCPLE", "demandTEC", "demandSPA", "demandTVA", "demandJEA"]
WestBaCodesDr = ["demandWAUW", "demandDOPD", "demandBANC", "demandBPAT", "demandNWMT", "demandPNM", "demandPACW", "demandSCL", "demandIID", "demandIPCO", "demandWALC", "demandGCPD", "demandPGE", "demandPSEI", "demandTIDC", "demandNEVP", "demandEPE", "demandAVA", "demandLDWP", "demandSRP", "demandWACM", "demandTEPC", "demandCISO", "demandCHPD", "demandPSCO", "demandAZPS", "demandTPWR", "demandPACE"]

# Subregion codes
EastSubCodes = ["demandAEC", "demandCPLW", "demandSOCO", "demandSC", "demandFPC", "demandSEC", "demandFPL", "demandFMPP", "demandNSB", "demandDUK", "demandSCEG", "demandHST", "demandAECI", "demandTAL", "demandLGEE", "demandGVL", "demandCPLE", "demandTEC", "demandSPA", "demandTVA", "demandJEA", "demand4001", "demand4002", "demand4003", "demand4004", "demand4005", "demand4006", "demand4007", "demand4008", "demand1", "demand27", "demand35", "demand4", "demand6", "demand8910", "demandZONA", "demandZONB", "demandZONC", "demandZOND", "demandZONE", "demandZONF", "demandZONG", "demandZONH", "demandZONI", "demandZONJ", "demandZONK", "demandAE", "demandAEP", "demandAP", "demandATSI", "demandBC", "demandCE", "demandDAY", "demandDEOK", "demandDOM", "demandDPL", "demandDUQ", "demandEKPC", "demandJC", "demandME", "demandPE", "demandPEP", "demandPL", "demandPN", "demandPS", "demandCSWS", "demandEDE", "demandGRDA", "demandINDN", "demandKACY", "demandKCPL", "demandLES", "demandMPS", "demandNPPD", "demandOKGE", "demandOPPD", "demandSECI", "demandSPRM", "demandSPS", "demandWAUE", "demandWFEC", "demandWR"]
WestSubCodes = ["demandWAUW", "demandDOPD", "demandBANC", "demandBPAT", "demandNWMT", "demandPNM", "demandPACW", "demandSCL", "demandIID", "demandIPCO", "demandWALC", "demandGCPD", "demandPGE", "demandPSEI", "demandTIDC", "demandNEVP", "demandEPE", "demandAVA", "demandLDWP", "demandSRP", "demandWACM", "demandTEPC", "demandCHPD", "demandPSCO", "demandAZPS", "demandTPWR", "demandPACE", "demandPGAE", "demandSCE", "demandSDGE", "demandVEA"]
TexasSubCodes = ["demandCOAS", "demandEAST", "demandFWES", "demandNCEN", "demandNRTH", "demandSCEN", "demandSOUT", "demandWEST"]

AllBAcodes = ["AEC", "CPLW", "SOCO", "SC", "MISO", "NYIS", "FPC", "SEC", "FPL", "FMPP", "NSB", "ISNE", "DUK", "SCEG", "HST", "PJM", "AECI", "SWPP", "TAL", "LGEE", "GVL", "CPLE", "TEC", "SPA", "TVA", "JEA", "WAUW", "DOPD", "BANC", "BPAT", "NWMT", "PNM", "PACW", "SCL", "IID", "IPCO", "WALC", "GCPD", "PGE", "PSEI", "TIDC", "NEVP", "EPE", "AVA", "LDWP", "SRP", "WACM", "TEPC", "CISO", "CHPD", "PSCO", "AZPS", "TPWR", "PACE", "ERCO"]
NE_bacode = []

AllsubBAcodes = ["AEC", "CPLW", "SOCO", "SC", "FPC", "SEC", "FPL", "FMPP", "NSB", "DUK", "SCEG", "HST", "AECI", "TAL", "LGEE", "GVL", "CPLE", "TEC", "SPA", "TVA", "JEA", "4001", "4002", "4003", "4004", "4005", "4006", "4007", "4008", "1", "27", "35", "4", "6", "8910", "ZONA", "ZONB", "ZONC", "ZOND", "ZONE", "ZONF", "ZONG", "ZONH", "ZONI", "ZONJ", "ZONK", "AE", "AEP", "AP", "ATSI", "BC", "CE", "DAY", "DEOK", "DOM", "DPL", "DUQ", "EKPC", "JC", "ME", "PE", "PEP", "PL", "PN", "PS", "CSWS", "EDE", "GRDA", "INDN", "KACY", "KCPL", "LES", "MPS", "NPPD", "OKGE", "OPPD", "SECI", "SPRM", "SPS", "WAUE", "WFEC", "WR", "WAUW", "DOPD", "BANC", "BPAT", "NWMT", "PNM", "PACW", "SCL", "IID", "IPCO", "WALC", "GCPD", "PGE", "PSEI", "TIDC", "NEVP", "EPE", "AVA", "LDWP", "SRP", "WACM", "TEPC", "CHPD", "PSCO", "AZPS", "TPWR", "PACE", "PGAE", "SCE", "SDGE", "VEA", "COAS", "EAST", "FWES", "NCEN", "NRTH", "SCEN", "SOUT", "WEST"]

# Canadian and Mexico BA codes
BA_Canada = ["AESO", "BCHA", "HQT", "IESO", "MHEB", "NBSO", "SPC"]
BA_Mexico = ["CEN", "CFE"]


def count_items(items):
    return len(items)

def print_counts():
    print(f"Number of subBA's: {count_items(AllsubBAcodes)}")
    print(f"Number of BA's: {count_items(AllBAcodes)}")
    print(f"Number of subBA's in East: {count_items(EastSubCodes)}")
    print(f"Number of subBA's in West: {count_items(WestSubCodes)}")
    print(f"Number of subBA's in Texas: {count_items(TexasSubCodes)}")

# BA codes by region
CAL_BA = ["BANC", "IID", "LDWP", "PGAE", "SCE", "SDGE", "TIDC", "VEA"]
CAR_BA = ["CPLE", "CPLW", "DUK", "SC", "SCEG", "YAD"]
CENT_BA = ["CSWS", "EDE", "GRDA", "INDN", "KACY", "KCPL", "LES", "MPS", "NPPD", "OKGE", "OPPD", "SECI", "SPA", "SPRM", "SPS", "WAUE", "WFEC", "WR"]
FLA_BA = ["FMPP", "FPC", "FPL", "GVL", "JEA", "SEC", "TAL", "TEC"]
MIDA_BA = ["AE", "AEP", "AP", "ATSI", "BC", "CE", "DAY", "DEOK", "DOM", "DPL", "DUQ", "EKPC", "JC", "ME", "PE", "PEP", "PL", "PN", "PS"]
MIDW_BA = ["1", "27", "35", "4", "6", "8910"]
NE_BA = ["4001", "4002", "4003", "4004", "4005", "4006", "4007", "4008"]
NW_BA = ["AVA", "AVRN", "BPAT", "CHPD", "DOPD", "GCPD", "GRID", "GWA", "IPCO", "NEVP", "NWMT", "PACE", "PACW", "PGE", "PSCO", "PSEI", "SLC", "TPWR", "WACM", "WWA", "WAUW"]
NY_BA = ["ZONA", "ZONB", "ZONC", "ZOND", "ZONE", "ZONF", "ZONG", "ZONH", "ZONI", "ZONJ", "ZONK"]
SE_BA = ["AEC", "SEPA", "SOCO"]
SW_BA = ["AZPS", "EPE", "PNM", "SRP", "TEPC", "WALC"]
TEN_BA = ["TVA"]
TEX_BA = ["COAS", "EAST", "FWES", "NCEN", "NRTH", "SCEN", "SOUT", "WEST"]

# BA codes without BAs that do not have loads
CAL_BA2 = ["BANC", "IID", "LDWP", "PGAE", "SCE", "SDGE", "TIDC", "VEA"]
CAR_BA2 = ["CPLE", "CPLW", "DUK", "SC", "SCEG"]
CENT_BA2 = ["CSWS", "EDE", "GRDA", "INDN", "KACY", "KCPL", "LES", "MPS", "NPPD", "OKGE", "OPPD", "SECI", "SPA", "SPRM", "SPS", "WAUE", "WFEC", "WR"]
FLA_BA2 = ["FMPP", "FPC", "FPL", "GVL", "JEA", "SEC", "TAL", "TEC"]
MIDA_BA2 = ["AE", "AEP", "AP", "ATSI", "BC", "CE", "DAY", "DEOK", "DOM", "DPL", "DUQ", "EKPC", "JC", "ME", "PE", "PEP", "PL", "PN", "PS"]
MIDW_BA2 = ["1", "27", "35", "4", "6", "8910"]
NE_BA2 = ["4001", "4002", "4003", "4004", "4005", "4006", "4007", "4008"]
NW_BA2 = ["AVA", "BPAT", "CHPD", "DOPD", "GCPD", "IPCO", "NEVP", "NWMT", "PACE", "PACW", "PGE", "PSCO", "PSEI", "TPWR", "WACM", "WAUW"]
NY_BA2 = ["ZONA", "ZONB", "ZONC", "ZOND", "ZONE", "ZONF", "ZONG", "ZONH", "ZONI", "ZONJ", "ZONK"]
SE_BA2 = ["AEC", "SOCO"]
SW_BA2 = ["AZPS", "EPE", "PNM", "SRP", "TEPC", "WALC"]
TEN_BA2 = ["TVA"]
TEX_BA2 = ["COAS", "EAST", "FWES", "NCEN", "NRTH", "SCEN", "SOUT", "WEST"]

#state codes
us_states = [
    'AL', 'AK', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD',
    'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'NE', 'NH', 'NJ', 
    'NM','NV', 'NY', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WV', 'WI', 'WY'
]

#for later use
monthlow = 6
monthhigh = 9