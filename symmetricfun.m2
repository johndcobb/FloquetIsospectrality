restart
load "physicsstuff.m2"

n=9

P = createPerturbationIdeal(n)
R = ring P;
EList = elementarySymmetric(R)
IList = flatten entries gens P
FList = for d from 0 to n-1 list (-1)^d*((-1)^(d+1)*EList_d + IList_d) -- only works for our perturbation ideal, not the random one


P = createRandomPerturbationIdeal(n)
R = ring P;
EList = elementarySymmetric(R)
IList = flatten entries gens P
FList = for d from 0 to n-1 list (IList_d-EList_d) -- only works for our perturbation ideal, not the random one
R = ring P;

k = floor((n-1)/2)
specialize = map(R,R, {x_1..x_(k) | apply(reverse(x_1..x_k), x -> -1*x) | sequence(0)} )

specialize(P)


counterexample1 = ideal(EList + {0,  - x_1 -x_2, x_1*x_2 - x_1 - x_2})
assert(symmetrization(counterexample1) != counterexample1)


--FList = for d from 0 to n-1 list sparseinhomogeneous(d,R)
--IList = EList + FList

--degree tangentCone ideal EList == n! --true
--degree tangentCone ideal IList

E = i -> ideal(EList_{0..i-1})
A = i -> ideal(IList_{i-1..n-1})
I = i -> E(i-1) + A(i)
J = i -> E(i-1) + A(i+1)

for i from 1 to n list isSubset(I(i), I(i+1))

for i from 1 to n+1 list degree tangentCone I(i)

k = 3
degree tangentCone I(k)
degree tangentCone I(k-1)
test = E(k-2) + IList_(k-2) + ideal(EList_{k-1..n-1})
degree tangentCone test
conjecture = all(for i from 1 to n list 
(
    Ismaller := degree tangentCone I(i-1);
    Ismaller <= degree tangentCone I(i) and  Ismaller <= degree tangentCone (E(i-2) + IList_(i-2) + ideal(EList_{i-1..n-1}))
))

F = i -> E(i-1) + IList_(i-1) + ideal(EList_{i..n-1})

smallest = degree tangentCone P;
for i from 1 to n list (
    smallest <= degree tangentCone F(i)
)


E(k-2) + FList_(k-2) + ideal(EList_{k-1..n-1})

intersect(test, I(k))  == 


I(1) == P
I(n+1) == ideal EList
for i from 1 to n+1 list degree tangentCone I(i)

-- so from I(4) to I(5) we have a jump.
I(5) + FList_3 == I(5)
m = ideal flatten entries vars R
length R^1/localize(I(5), m)

degree tangentCone quotient(E(4),FList_3)
degree tangentCone E(4)
-----------


isSubset(I(4), I(5))
isSubset(J(3), I(3)) 
isSubset(J(3), I(4))

k = 5
I(k) + EList_(k-1) == I(k) + FList_(k-1)

degree tangentCone (I(k) + EList_(k-1))
degree tangentCone (I(k))
I(k) + EList_(k-1) == A(k) + E(k)
k = 3
tangentCone I(k) == (degree tangentCone E(k-1)) * degree(tangentCone A(k))
-- I(1)  is the ideal I care about

-- The inequality I want to show is an equality is the following:
k = 3
degree tangentCone( I(k) + EList_(k-1) ) == (degree tangentCone E(k-1))*(degree tangentCone ideal EList_(k-1) + FList_(k-1))*(degree tangentCone A(k+1))
degree tangentCone I(k) == (degree tangentCone E(k-1))*(degree tangentCone ideal A(k))
product(flatten entries gens A(k) / ideal / tangentCone / degree)
degree tangentCone A(k)

needsPackage "ReesAlgebra"
normalCone A(k) == tangentCone A(k)
degree ideal normalCone A(k)


tangentCone(ideal EList_{2..n-1})
tangentCone(A(3))

degree tangentCone ideal(EList + {0,0, EList_1, EList_2})

needsPackage "Depth"
isRegularSequence(flatten entries gens I(n)) -- true
isRegularSequence(flatten entries gens A(n)) -- true
degree tangentCone I(n) -- 24
product flatten degrees I(n) -- 5! = multiplication of all the degrees.
depth(I(4))

assert(I(1) == ideal IList)
assert(I(n+1) == ideal EList) -- true
-- and we have proven that mult(I(n)) < n!.
assert(degree tangentCone I(n) < (n)!)
-- we know that E(k-1) + A(k) == I(k)
E(2) + A(3) == I(3) -- true


test = ideal quotient(I(4):ideal FList_4)
degree tangentCone test
I(4)

intersect(E(3), ideal FList_2) == E(3)*(ideal FList_2) -- true

for i from 1 to n+1 list degree tangentCone I(i)
FList_{2}

I(1) == ideal IList

