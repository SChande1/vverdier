*! version 11.0.0  11Jan2016
program define myregress11, eclass sortpreserve
    version 14
 
    syntax varlist(numeric ts fv) [if] [in] [, noCONStant ]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
 
    fvexpand `indepvars' 
    local cnames `r(varlist)'
 
    tempname b V N rank df_r
 
    mata: mywork("`depvar'", "`cnames'", "`touse'", "`constant'", ///
       "`b'", "`V'", "`N'", "`rank'", "`df_r'") 
 
    if "`constant'" == "" {
        local cnames `cnames' _cons
    }
 
    matrix colnames `b' = `cnames'
    matrix colnames `V' = `cnames'
    matrix rownames `V' = `cnames'
 
    ereturn post `b' `V', esample(`touse') buildfvinfo
    ereturn scalar N       = `N'
    ereturn scalar rank    = `rank'
    ereturn scalar df_r    = `df_r'
    ereturn local  cmd     "myregress11"
 
    ereturn display
 
end
 
mata:
 
void mywork( string scalar depvar,  string scalar indepvars, 
             string scalar touse,   string scalar constant,  
             string scalar bname,   string scalar Vname,     
             string scalar nname,   string scalar rname,     
             string scalar dfrname) 
{
 
    real vector y, b, e, e2
    real matrix X, XpXi
    real scalar n, k
 
    y    = st_data(., depvar, touse)
    X    = st_data(., indepvars, touse)
    n    = rows(X)
 
    if (constant == "") {
        X    = X,J(n,1,1)
    }
 
    XpXi = quadcross(X, X)
    XpXi = invsym(XpXi)
    b    = XpXi*quadcross(X, y)
    e    = y - X*b
    e2   = e:^2
    k    = cols(X) - diag0cnt(XpXi)
    V    = (quadsum(e2)/(n-k))*XpXi
 
    st_matrix(bname, b')
    st_matrix(Vname, V)
    st_numscalar(nname, n)
    st_numscalar(rname, k)
    st_numscalar(dfrname, n-k)
 
}
 
end

. sysuse auto

global vars weight rep78 

myregress11(mpg $vars)
