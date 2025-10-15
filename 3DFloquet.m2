load "physicsstuff.m2"
a = 3; b = 3; c = 3; p=nextPrime(101000);

denseData = BlockPeriodicMatrix2DLapI(a,b,p)

R  = denseData_1;
specmap = map (R, R, join({x_1,x_2,z+4,y_1,y_2},q_1 .. q_(a*b)));
LV = specmap denseData_0;
specmap0 = map (denseData_1, denseData_1, join({x_1,x_2,z,y_1,y_2},  new List from (a*b):0))
L0 = specmap0 LV;



P = createPerturbationIdeal(a,b)







denseData = BlockPeriodicMatrix3DLapI(a,b,c,p);

R  = denseData_1;
specmap = map (R, R, join({x_1,x_2,x_3,z+6,y_1,y_2,y_3},q_1 .. q_(a*b*c)));
LV = specmap denseData_0;
specmap0 = map (denseData_1, denseData_1, join({x_1,x_2,x_3,z,y_1,y_2,y_3},  new List from (a*b*c):0))
L0 = specmap0 LV;

-- I want to solve det(L0) = det(LV), I think.



time DF2 = DF - (specmappp LV)
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
