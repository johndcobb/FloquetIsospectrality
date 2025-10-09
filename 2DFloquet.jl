using HomotopyContinuation

@var x[1:9]

E =  include("./cache/E3x3.jl")

F = System([E])
res = solve(F)
