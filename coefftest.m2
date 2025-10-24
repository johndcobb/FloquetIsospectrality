load("code/characteristicCoeff.m2")
load "code/physicsstuff.m2"
a = 3; b = 3; c = 3; p=nextPrime(101000);

--- I wish I could just use this, but it isn't in the form I want.
denseData = BlockPeriodicMatrix3DLapI(a,b,c,p)
--z is "lambda"
-- q potential

MV = sub(denseData_0, {z => 6}) -- divide by x_1x_2x_3
-- set q_1 = - sum of others?
-- goal: Make list smaller.
M0 = sub(MV, for i from 1 to a*b*c list q_i => 0)

-*
This was my attempt to make Andreas's code work with any Matrix. This is really annoying and hard so i'm just going to use his code, since it requires the definition of A, AV, AAV, AAAV, V, etc. 
-----------------------------------------------------
M = MV
L1 = submatrix(M,{0..8},{0..8});
L2 = submatrix(M,{9..17},{9..17});
L3 = submatrix(M,{18..26},{18..26});
E = submatrix(M,{0..8},{9..17});

lsGens = {};
k = 8;
rslt = 0;
for i from k to 9 do (
Ssubsets = subsets(toList(0..8),i);
Tsubsets = subsets(toList(0..8),i-k);
for S in Ssubsets do (
for T in Tsubsets do (
Sc = toList(0..8) - set(S);
Mfinal11 = submatrix(L1,T,S) * submatrix(L2,S,S) * submatrix(L3,S,T) - submatrix(L1,T,S) * submatrix(E,S,T) - submatrix(E,T,S) * submatrix(L3,S,T);
Mfinal12 = submatrix(E,T,Sc) - submatrix(L1,T,S) * submatrix(L2,S,Sc);
Mfinal21 = submatrix(E,Sc,T) - submatrix(L2,Sc,S) * submatrix(L3,S,T);
Mfinal22 = submatrix(L2,Sc,Sc);
Mfinal = (Mfinal11 | Mfinal12) || (Mfinal21 | Mfinal22);
f = (-1)^(9 - i) * det(Mfinal,Strategy=>Bareiss);
rslt = rslt + f;
);
);
);
rslt
(T,C) = coefficients rslt
C
lsGens = append(lsGens,removeConstantTerms(flatten entries rslt));

rslt = w_3^k*rslt;

(T,C) = coefficients sub(rslt,AAAV);
C = sub(C,V);
lsGens = append(lsGens,removeConstantTerms(flatten entries C));
*- 
k = 7;
fifthCoeff0 = characteristicCoeffs(M0,k);
fifthCoeffV = characteristicCoeffs(MV,k);
fifthSpectral = fifthCoeffV_0 - fifthCoeff0_0;
length fifthSpectral
saveValue(fifthSpectral, "lambdagens7.m2");


elapsedTime characteristicCoeffs(MV, 5); -- 1.2 seconds
prevResult = elapsedTime characteristicCoeffs(MV, 6); -- 7.9 seconds
elapsedTime characteristicCoeffs(MV, 7); -- 48 seconds
elapsedTime characteristicCoeffs(MV, 7, prevResult_0, prevResult_1); -- 38 seconds 
elapsedTime characteristicCoeffs(MV, 8); -- 220 seconds 

k=8
resultV = characteristicCoeffs(MV, k);
result0 = characteristicCoeffs(M0, k);
saveValue(resultV_0 - result0_0, "lambdagens8.m2") -- this saves the first k coefficients of lambda into a file.


R = QQ[y]
M = matrix{{1,2*y,5},{7,4,5},{5,2,7}}
S = (ring M)[x];
charPoly = det(M - x*map(S^(numRows M),S^(numRows M),1))

prevCoeffs = characteristicCoeffs(M, 3)
characteristicCoeffs(M, 4,prevCoeffs_0, prevCoeffs_1)