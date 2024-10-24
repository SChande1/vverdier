sysuse auto, clear

foreach var in mpg weight {
qui gen e`var'= .
}

reg mpg weight foreign rep78
gen sample = e(sample)

foreach var in mpg weight{
	capture drop temp
	reg `var' foreign rep78, noconstant
	predict temp, resid
	replace e`var'=temp if sample
	
}

reg empg eweight

mata
Z=y=X=.

st_view(Z, ., "mpg weight foreign rep78", 0)
st_subview(y, Z, ., 1)
st_subview(X, Z, ., (2\.))

XX = cross(X,1 , X,1)
Xy = cross(X,1 , y,0)
b = invsym(XX)*Xy
end
mata:b

reg mpg weight foreign rep78

global thevars  mpg weight foreign rep78

mata
Z=y1=y2=W=.
/* st_view(Z,.,"mpg weight foreign rep78",0) */
st_view(Z,.,$thevars,0)
st_subview(y1,Z,.,1)
st_subview(y2,Z,.,2)
st_subview(W,Z,.,(3\.))
WW = cross(W,W)
MY1 = cross(W,y1)
MY2 =cross(W,y2)
WWINV = invsym(WW)
e1 = y1 - W*WWINV * MY1
e2 = y2 - W*WWINV * MY2
*final terms we want for python
xx=cross(e2,e2)
yx=cross(e2,e1)
end
mata:e1
mata:e2

