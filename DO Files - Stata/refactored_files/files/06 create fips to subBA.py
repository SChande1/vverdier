import pandas as pd




# Create ISNE subregions
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']

# ISNE 
# use subregion to state mapping https://www.iso-ne.com/about/key-stats/maps-and-diagrams/#load-zones
# verified by comparing 2019_smd_hoursly.xlsx to Hourly_Sub_Load.dta"
# 4001 Maine  fips 23
# 4002 New Hampsire fips 33
# 4003 Vermont fips 50
# 4004 Connecticut fips 09
# 4005 Rhode Island fips 44
# 4006 SE Mass fips 25
# 4007 WC Mass fips 25
# 4008 NE Mass fips 25

df = df[df['bacode']=='ISNE']

df['subBA'] = ''
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 23000) & (df['fips'] < 24000), 'subBA'] = '4001'
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 33000) & (df['fips'] < 34000), 'subBA'] = '4002'
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 50000) & (df['fips'] < 51000), 'subBA'] = '4003'
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 9000) & (df['fips'] < 10000), 'subBA'] = '4004'
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 44000) & (df['fips'] < 45000), 'subBA'] = '4005'
df.loc[(df['bacode']=='ISNE') & (df['fips'] > 25000) & (df['fips'] < 26000), 'subBA'] = '4006'

# MASS fips are approximate
# NE includes boston (Suffolk county, Middlesex, Essex)
df.loc[(df['subBA']=='4006') & (df['fips'].isin([25025, 25017, 25009])), 'subBA'] = '4008'
# WC includes (Berkshire, Franklin, Hampshire, Hampden, Worcester)
df.loc[(df['subBA']=='4006') & (df['fips'].isin([25003, 25011, 25013, 25015, 25027])), 'subBA'] = '4007'

df = df[['fips', 'subBA']]
df.to_stata('temp1.dta')

# MISO
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='MISO']
df.to_stata('temp2.dta')

df = pd.read_excel("../rawdata/mapchart/miso zones fips.xlsx")
name_replacements = {
    'DeKalb': 'De Kalb',
    'DeSoto': 'De Soto', 
    'McCook': 'Mccook',
    'Fond du Lac': 'Fond Du Lac',
    'LaGrange': 'La Grange',
    'LaMoure': 'La Moure',
    'LaSalle': 'La Salle',
    'LaPorte': 'La Porte',
    'Lake of the Woods': 'Lake Of The Woods',
    'McCracken': 'Mccracken',
    'McDonough': 'Mcdonough',
    'McHenry': 'Mchenry',
    'McLean': 'Mclean',
    'McLeod': 'Mcleod',
    'Sainte Genevieve': 'Ste. Genevieve',
    'St John the Baptist': 'St John The Baptist'
}

for old_name, new_name in name_replacements.items():
    df['name'] = df['name'].replace(old_name, new_name)

df.loc[df['name']=='St Louis Co', 'state'] = 'MO'
df.loc[df['name']=='St Louis Co', 'name'] = 'St Louis City'
df.loc[df['name']=='Lac qui Parle', 'name'] = 'Lac Qui Parle'

df = pd.merge(df, pd.read_stata('temp2.dta'), on=['name', 'state'])
df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]
df.to_stata('temp2.dta')

# ERCOT
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='ERCO']
df.to_stata('temp3.dta')

df = pd.read_excel("../rawdata/mapchart/erco zones fips.xlsx")
name_replacements = {
    'DeWitt': 'De Witt',
    'McMullen': 'Mcmullen',
    'McLennan': 'Mclennan',
    'McCulloch': 'Mcculloch'
}

for old_name, new_name in name_replacements.items():
    df['name'] = df['name'].replace(old_name, new_name)

df = pd.merge(df, pd.read_stata('temp3.dta'), on=['name', 'state'])
df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]
df.to_stata('temp3.dta')

# NYIS
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='NYIS']
df.to_stata('temp4.dta')

df = pd.read_excel("../rawdata/mapchart/nyis zones fips.xlsx")
df = pd.merge(df, pd.read_stata('temp4.dta'), on=['name', 'state'])
df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]
df.to_stata('temp4.dta')

# PJM
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='PJM']
df.to_stata('temp5.dta')

df = pd.read_excel("../rawdata/mapchart/pjm zones fips.xlsx")
df['state'] = df['state'].str.strip()

name_replacements = {
    'DeKalb': 'De Kalb',
    'DuPage': 'Du Page',
    'Baltimore County': 'Baltimore',
    'McCreary': 'Mccreary',
    'McDowell': 'Mcdowell',
    'McHenry': 'Mchenry',
    'McKean': 'Mckean',
    "Queen Anne s": "Queen Annes",
    "Prince George s": "Prince Georges",
    "St Mary s": "St Marys",
    'Winchester': 'Winchester City',
    'Williamsburg': 'Williamsburg City',
    'Waynesboro': 'Waynesboro City',
    'Virginia Beach': 'Virginia Beach City',
    'Suffolk': 'Suffolk City',
    'Staunton': 'Staunton City',
    'Salem': 'Salem City',
    'Radford': 'Radford City',
    'Petersburg': 'Petersburg City',
    'Buena Vista': 'Buena Vista City',
    'Charlottesville': 'Charlottesville City',
    'Chesapeake': 'Chesapeake City',
    'Colonial Heights': 'Colonial Heights Cit',
    'Covington': 'Covington City',
    'Danville': 'Danville City',
    'Emporia': 'Emporia City',
    'Fairfax': 'Fairfax City',
    'Fredericksburg': 'Fredericksburg City',
    'Galax': 'Galax City',
    'Harrisonburg': 'Harrisonburg City',
    'Lexington': 'Lexington City',
    'Lynchburg': 'Lynchburg City',
    'Manassas': 'Manassas City',
    'Manassas Park': 'Manassas Park City',
    'Martinsville': 'Martinsville City',
    'Fairfax Co': 'Fairfax',
    'Isle of Wight': 'Isle Of Wight',
    'King and Queen': 'King And Queen',
    'Falls Church': 'Falls Church City',
    'Hampton': 'Hampton City',
    'Hopewell': 'Hopewell City',
    'Newport News': 'Newport News City',
    'Norfolk': 'Norfolk City',
    'Poquoson': 'Poquoson City',
    'Portsmouth': 'Portsmouth City',
    'Alexandria': 'Alexandria City'
}

for old_name, new_name in name_replacements.items():
    df.loc[df['name']==old_name, 'name'] = new_name

df.loc[df['name']=='Bedford Co', 'state'] = 'VA'
df.loc[(df['name']=='Bedford Co') & (df['state']=='VA'), 'name'] = 'Bedford'
df.loc[(df['name']=='Fairfax') & (df['subregion']=='DOM'), 'state'] = 'VA'
df.loc[(df['name']=='Franklin Co') & (df['subregion']=='DOM'), 'state'] = 'VA'
df.loc[(df['name']=='Franklin Co') & (df['state']=='VA'), 'name'] = 'Franklin City'
df.loc[df['name']=='Roanoke Co', 'state'] = 'VA'
df.loc[df['name']=='Richmond Co', 'state'] = 'VA'
df.loc[df['name']=='Roanoke Co', 'name'] = 'Roanoke City'
df.loc[df['name']=='Richmond Co', 'name'] = 'Richmond City'

df = pd.merge(df, pd.read_stata('temp5.dta'), on=['name', 'state'], how='right', indicator=True)
df = df[df['_merge'].isin([2,3])]

# Bedford city VA - give it same code as Bedford county
df.loc[df['fips']==51515, 'subregion'] = 'AEP'
df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]

# RECO maps to only one county in NJ. The data is not very good - for the entire summer there is no
# variation in load. So we drop it in the regressions. So just assign this county to PS instead (which is right next door)
df.loc[df['subBA']=='RECO', 'subBA'] = 'PS'
df.to_stata('temp5.dta')

# Check CISO
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='CISO']
df.to_stata('temp6.dta')

df = pd.read_excel("../rawdata/mapchart/ciso zones fips.xlsx")
df = pd.merge(df, pd.read_stata('temp6.dta'), on=['name', 'state'])
df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]
df.to_stata('temp6.dta')

# Check SWPP
df = pd.read_stata("data/fips_to_region_crosswalk.dta")
df['bacode'] = df['balancingauthoritycode']
df2 = pd.read_stata("data/fips_to_county_names.dta")
df = pd.merge(df, df2, on='fips', how='outer', indicator=True)
df = df[df['_merge'].isin([1,3])]
df = df[df['bacode']=='SWPP']
df.to_stata('temp7.dta')

df = pd.read_excel("../rawdata/mapchart/swpp zones fips.xlsx")

name_replacements = {
    'McClain': 'Mcclain',
    'McCone': 'Mccone', 
    'McCurtain': 'Mccurtain',
    'McDonald': 'Mcdonald',
    'McIntosh': 'Mcintosh',
    'McKenzie': 'Mckenzie',
    'McPherson': 'Mcpherson',
    'Oglala Lakota': 'Shannon'  # fips 46113 "Shannon" has been changed to fips 46102 Oglala Lakota
}

for old_name, new_name in name_replacements.items():
    df['name'] = df['name'].replace(old_name, new_name)

df = pd.merge(df, pd.read_stata('temp7.dta'), on=['name', 'state'])

# Give new Shannon same subBA as old Shannon
df.loc[df['fips']==46102, 'subregion'] = 'WAUE'

df = df.rename(columns={'subregion': 'subBA'})
df = df[['fips', 'subBA']]
df.to_stata('temp7.dta')

# Combine all temp files
df1 = pd.read_stata('temp1.dta')
df2 = pd.read_stata('temp2.dta')
df3 = pd.read_stata('temp3.dta')
df4 = pd.read_stata('temp4.dta')
df5 = pd.read_stata('temp5.dta')
df6 = pd.read_stata('temp6.dta')
df7 = pd.read_stata('temp7.dta')

df = pd.concat([df1, df2, df3, df4, df5, df6, df7])

df2 = pd.read_stata("data/fips_to_region_crosswalk.dta")
df = pd.merge(df, df2, on='fips', how='outer')
df.loc[df['subBA']=='', 'subBA'] = df['balancingauthoritycode']

df.to_stata("data/fips_to_subBA_crosswalk.dta")
