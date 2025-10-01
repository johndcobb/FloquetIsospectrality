clearAll
load "physicsstuff.m2"
p=nextPrime(101000)
curprime = 2
primeskip = 1000
--needsPackage "NumericalAlgebraicGeometry";


a= 3
b = 3
c = 3
p=nextPrime(p+primeskip+random(10000))
denseData = BlockPeriodicMatrix3DLapI(a,b,c,p);
use denseData_1
specmap = map (denseData_1, denseData_1, join({x_1,x_2,x_3,z+6,y_1,y_2,y_3},q_1 .. q_(a*b*c)))
toString(specmap denseData_0)
smat = specmap denseData_0;
DF = time det(smat);
use denseData_1;
varsss = new List from (a*b*c):0
specmappp = map (denseData_1, denseData_1, join({x_1,x_2,x_3,z,y_1,y_2,y_3},varsss))
time DF2 = DF - (specmappp DF)
monomials(DF2,Variables=>{x_1,x_2,x_3,z});
K = coefficients(DF2,Variables=>{x_1,x_2,x_3,z});
KL = entries K_1_0;
KLu = unique KL;
#KLu
print(#KLu)
KLu
I = ideal(KLu);
time degree I
print(degree I)
--elimvars = new List from q_1..q_(a*b*c-1)
--eI = time eliminate(elimvars,I)
--print(eI)
