using ParallelSparseMatMul
include("stokes_flow/solve_stokes.jl")
# include("graphs/flowplot.jl")
include("helpers/helper_functions.jl")

# domain = int(input("Choose problem (1/lid-driven cavity, 2/brinkman): "))
# msize = int(input("Mesh size: "))
msize = 6
domain = 2
(xst, kparams) = solve_stokes(domain, msize)
println("done")
# doplot = input("Create plot? (y/n): ")
#
# if doplot == "y"
#   flowplot(xst, kparams)
# end

sol = xst;
x = kparams["x"]; y = kparams["y"];
xy = kparams["xy"]; xyp = kparams["xyp"]; mv = kparams["mv"]; bound = kparams["bound"]
ae = kparams["ae"]; bxe = kparams["bxe"]; bye = kparams["bye"]; bbxe = kparams["bbxe"]; bbye = kparams["bbye"]
nvtx = length(xy[:, 1]); nu = 2nvtx; np = 3length(xyp[:, 1])

u = sol[1:nu]
p = sol[nu+1:end]
ux = reshape(u[1:nvtx], length(x), length(y))'
uy = reshape(u[nvtx+1:end], length(x), length(y))'

writecsv("$(homedir())/Documents/brinkman-stokes/julia-parallel/matrix-free-tensor/temp/sol/x.csv", x)
writecsv("$(homedir())/Documents/brinkman-stokes/julia-parallel/matrix-free-tensor/temp/sol/y.csv", y)
writecsv("$(homedir())/Documents/brinkman-stokes/julia-parallel/matrix-free-tensor/temp/sol/ux.csv", ux)
writecsv("$(homedir())/Documents/brinkman-stokes/julia-parallel/matrix-free-tensor/temp/sol/uy.csv", uy)
