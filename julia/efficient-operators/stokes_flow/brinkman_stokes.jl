# load required packages and functions
using MAT
using Distances
reload("stokes_flow/stokes_brinkman_q2p1.jl")
reload("grids/q2p1grid.jl")
reload("grids/channel_domain.jl")
include("../helpers/helper_functions.jl")
include("../../julia-homg/Basis.jl")
include("../../julia-homg/Hexmesh.jl")
include("../../julia-homg/Xform.jl")
include("../../julia-homg/Grids.jl")
include("../../julia-homg/Tensor.jl")
include("../../julia-homg/Refel.jl")

###SQUARE_STOKES set up flow problem in unit square domain
function brinkman_stokes(msize)

    # generate Q2 grid for square channel
    channel_grid = channel_domain(msize)
    grid = q2p1grid(channel_grid)

    # stokes q2-p1 matrix generator
    mv = channel_grid["mv"]
    stokes_grid = merge(grid, {"mv" => mv})

    xy = stokes_grid["xy"]
    nu = 2length(xy[:, 1])
    stokes_mats = stokes_brinkman_q2p1(stokes_grid)

    bounds = {
      "bound" => channel_grid["bound"],
      "bndxy" => channel_grid["bndxy"],
      "bnde" => channel_grid["bnde"],
      "obs" => channel_grid["obs"]
    }

    msize = channel_grid["msize"];
    # order = int(input("Polynomial order: "))
    order = 2;
    # dim = int(input("Dimension: "));
    dim = 2;
    nelems = [2^(msize-1)]
    m = Mesh.Hexmesh(tuple(repmat(nelems, 1, dim)...), Xform.identity)
    dof = prod([m.nelems...]*order + 1)

    # brinkman obstacles
    # centers = [
    #   0.15 0.15
    #   0.17 0.45
    #   0.15 0.8
    #   0.37 0.25
    #   0.4  0.55
    #   0.55 0.85
    #   0.7  0.4
    #   0.7  0.8
    #   0.8  0.1
    #   0.9  0.35
    # ]
    centers = [
      0.15 0.2
      0.17 0.45
      0.15 0.8
      0.3  0.3
      0.4  0.55
      0.4  0.8
      0.7  0.4
      0.7  0.8
      0.8  0.1
      0.9  0.35
    ]
    K,M = Mesh.assemble_poisson_brinkman(m, order, centers)
    k1,k2 = size(K)
    A = [K spzeros(k1,k2); spzeros(k1,k2) K]
    G = [M spzeros(k1,k2); spzeros(k1,k2) M]
    stokes_mats["A"] = A
    stokes_mats["G"] = G

    # keys(mats) =
    # {"A", "B", "G", "Q", "Bx", "By", "f", "g", "x", "y", "xyp", "bound"}
    mats = merge(stokes_mats, grid, bounds)
end
