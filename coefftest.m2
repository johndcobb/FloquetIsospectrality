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


k = 7;
fifthCoeff0 = characteristicCoeffs(M0,k);
fifthCoeffV = characteristicCoeffs(MV,k);
fifthSpectral = fifthCoeffV_0 - fifthCoeff0_0;
length fifthSpectral
saveValue(fifthSpectral, "example.m2");


elapsedTime characteristicCoeffs(MV, 5); -- 1.2 seconds
prevResult = elapsedTime characteristicCoeffs(MV, 6); -- 7.9 seconds
elapsedTime characteristicCoeffs(MV, 7); -- 48 seconds
elapsedTime characteristicCoeffs(MV, 7, prevResult_0, prevResult_1); -- 38 seconds 
elapsedTime characteristicCoeffs(MV, 8);





R = QQ[y]
M = matrix{{1,2*y,5},{7,4,5},{5,2,7}}
S = (ring M)[x];
charPoly = det(M - x*map(S^(numRows M),S^(numRows M),1))

prevCoeffs = characteristicCoeffs(M, 3)
characteristicCoeffs(M, 4,prevCoeffs_0, prevCoeffs_1)