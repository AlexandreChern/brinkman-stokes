# require("stokes_flow/afunbc.jl")
# require("stokes_flow/bfunbc.jl")
# require("stokes_flow/btfunbc.jl")
using LinearOperators
reload("stokes_flow/afunbc.jl")
reload("stokes_flow/bfunbc.jl")
reload("stokes_flow/btfunbc.jl")

###KFUNBC matrix-free stiffness operator
function kfunbc(u, kparams)

    xy = kparams["xy"]; xyp = kparams["xyp"]
    nvtx = length(xy[:, 1]); nu = 2nvtx; np = 3length(xyp[:, 1])

    A = LinearOperator(nu+np, Float64,  u -> afunbc(u, kparams))
    B = LinearOperator(nu+np, Float64, u -> bfunbc(u, kparams))
    Bt = LinearOperator(nu+np, Float64, u -> btfunbc(u, kparams))

    w = A*u + B*u + Bt*u
    
end