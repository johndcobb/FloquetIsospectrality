load("code/characteristicCoeff.m2")
load "code/physicsstuff.m2"
a = 3; b = 3; c = 3; p=nextPrime(101000);

--- this isn't what I want.
denseData = BlockPeriodicMatrix3DLapI(a,b,c,p)


--- this is what I want, but its really ugly, I want to just say LV(3,3,3) and get it.
K = QQ;
Qtilde = 9;
Dbound = 3;

AA = K[z_1..z_Dbound,w_1..w_Dbound,L];
inv = ideal(z_1*w_1-1);
for i from 2 to Dbound do (
inv = inv + ideal(z_i*w_i-1);
);
A = AA/inv;

ls1 = {};
ls3 = {};
for i from 1 to Dbound do (
ls1 = append(ls1,1);
ls3 = append(ls3,3);
);
V = K[v_ls1..v_ls3];
AAAV = V[L,w_1..w_Dbound,z_1..z_Dbound];
AAV = V[L][w_1..w_Dbound,z_1..z_Dbound];
AV = AAV/sub(inv,AAV);

createMatrixWithVs = method()
createMatrixWithVs(ZZ,List) := Matrix => (D,ls) -> (
use AV;
M := M;
if (D == 1) then (
M = id_(AV^3);
M = (-L)*M;
M = M + diagonalMatrix( { v_(append(ls,1)), v_(append(ls,2)), v_(append(ls,3)) } );
M = mutableMatrix M;
M_(0,2) = w_1;
M_(2,0) = z_1;
M = matrix M;
return M;
);
Mdiag1 := createMatrixWithVs(D-1, append(ls,1));
Mdiag2 := createMatrixWithVs(D-1, append(ls,2));
Mdiag3 := createMatrixWithVs(D-1, append(ls,3));
N := 3^(D-1);
E := id_(AV^N);
M = (Mdiag1 | E) | (w_D*E);
M = M || ((E | Mdiag2) | E);
M = M || ((z_D*E) | (E | Mdiag3));
return M;
);

MV = sub(createMatrixWithVs(3,{}), {L => 0})
M0 = sub(MV, flatten flatten for i from 1 to 3 list for j from 1 to 3 list for k from 1 to 3 list v_{i,j,k} => 0 )

characteristicCoeffs(MV,4)
characteristicCoeffs(M0,4)

characteristicCoeffs(M,4)

R = QQ[y]
M = matrix{{1,2*y,5},{7,4,5},{5,2,7}}
S = (ring M)[x];
charPoly = det(M - x*map(S^(numRows M),S^(numRows M),1))

prevCoeffs = characteristicCoeffs(M, 2)
characteristicCoeffs(M,prevCoeffs,1) 
characteristicCoeffs(M, 3)