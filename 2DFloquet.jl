using HomotopyContinuation

@var x[1:9] y[1:4]

E =  include("./cache/E3x3.jl")

F = System(E)
res = solve(F; start_system =:total_degree)
