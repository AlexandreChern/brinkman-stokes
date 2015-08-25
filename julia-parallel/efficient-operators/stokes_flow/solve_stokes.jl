# using IterativeSolvers
# using LinearOperators
using KrylovMethods
# using Gadfly
# reload("stokes_flow/square_stokes.jl")
# reload("stokes_flow/obstacle_stokes.jl")
# reload("stokes_flow/brinkman_stokes.jl")
# reload("stokes_flow/flowbc.jl")
# reload("solvers/mg_diff.jl")
# reload("solvers/m_st_mg.jl")
include("square_stokes.jl")
include("brinkman_stokes.jl")
include("flowbc.jl")
include("../solvers/mg_diff.jl")
include("../solvers/m_st_mg.jl")

###SOLVE_STOKES solve stokes problem
function solve_stokes(domain, msize)

  @time (if domain == 1
    mats = square_stokes(msize)
  elseif domain == 2
    mats = brinkman_stokes(msize)
  else
    error("invalid domain, please try again")
  end)

  A = mats["A"]; B = mats["B"]; Bx = mats["Bx"]; By = mats["By"];
  f = mats["f"]; g = mats["g"]; xy = mats["xy"]; xyp = mats["xyp"];
  bound = mats["bound"]; x = mats["x"]; y = mats["y"];
  Q = mats["Q"]; msize = mats["msize"];
  if domain == 3; kappa = mats["kappa"]; else; kappa = zeros(length(x)*length(y)); end;

  # boundary conditions
  println("imposing (enclosed flow) boundary conditions ...")
  (Ast, Bst, fst, gst) = flowbc(A, B, f, g, xy, bound, domain)
  np = length(gst)
  rhs = vec([fst; gst])

  ## compute solution
  K = [Ast Bst'; Bst spzeros(np, np)]
  M = u -> u

  if domain == 1 || domain == 3
    pc = input("Use GMG preconditioner? (y/n): ")
    if pc == "y"

      nv = size(Ast, 1); np = size(Q, 1); nu = nv/2
      Agal = Ast[1:nu, 1:nu]
      (mgdata, smooth_data, sweeps, stype, npre, npost, nc) = mg_diff(x, y, Agal)

      mparams = {
        "nv" => nv,
        "Q" => Q,
        "mgdata" => mgdata,
        "smooth_data" => smooth_data,
        "nc" => nc,
        "npre" => npre,
        "npost" => npost,
        "sweeps" => sweeps
      }

      # block GMG preconditioner
      M = u -> m_st_mg(u, mparams)
    end
  end

  # tol = 1e-6; maxit = 100;
  restrt = min(100, length(rhs)); tol = 1e-6; maxIter = 1
  @time ((xst, flag, err, iter, resvec) = gmres(
    K, rhs, restrt;
    tol = tol, maxIter = maxIter, M = M, out = 1
  ))

  # xst,convHist = gmres(K, rhs)

  if flag == 0
    println("GMRES reached desired tolerance at iteration $(length(resvec))")
  end

  # p = Gadfly.plot(
  #   x = 1:1:length(resvec), y = log(10, resvec), Geom.line,
  #   Guide.xlabel("Iteration"), Guide.ylabel("log_10(residual)")
  # )
  # outfile = string("graphs/brinkman_iters", msize, ".png")
  # Gadfly.draw(PNG(outfile, 12inch, 6inch), p)
  #
  # outfile = string("output/brinkman_iters", msize, ".csv")
  # writecsv(outfile, log(10, resvec))

  sol = {
    "K" => K, "Ast" => Ast, "Bst" => Bst, "M" => M, "kappa" => kappa,
    "rhs" => rhs, "fst" => fst, "gst" => gst, "xst" => xst
  }

  sol = merge(mats, sol)

end
