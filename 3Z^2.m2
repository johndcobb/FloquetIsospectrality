load("physicsstuff.m2")

E = createPerturbationIdeal(3,3)
saveValue(flatten entries gens E, "E3x3.m2")
decompose E
ring E

load("code/physicsstuff.m2")

E = createPerturbationIdeal(3,4)
