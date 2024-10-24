

. sysuse auto

local vars weight rep78 

mata: X = st_data(.,"`vars'",0)
mata: st_matrix("XX",X)

matrix list XX

