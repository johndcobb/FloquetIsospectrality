using HomotopyContinuation

@var v[1:3,1:3,1:3]

lsGens8 =  include("./cache/lsGens8.jl")
lsGens7 = include("./cache/lsGens7.jl")
lsGens6 = include("./cache/lsGens6.jl")


F = System([lsGens8; lsGens7; lsGens6])
res = solve(F)
