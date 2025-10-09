K = QQ;
Qtilde = 9;
Dbound = 3;

AA = K[z_1..z_Dbound,w_1..w_Dbound,L];
inv = ideal(z_1*w_1-1);
for i from 2 to Dbound do (
inv = inv + ideal(z_i*w_i-1);
);
A = AA/inv;

createMatrixWithoutVs = method()
createMatrixWithoutVs(ZZ) := Matrix => D -> (
use A;
M := M;
if (D == 1) then (
M = id_(A^3);
M = (-L)*M;
M = mutableMatrix M;
M_(0,2) = w_1;
M_(2,0) = z_1;
return (matrix M);
);
Mdiag := createMatrixWithoutVs(D-1);
N := 3^(D-1);
E := id_(A^N);
M = (Mdiag | E) | (w_D*E);
M = M || ((E | Mdiag) | E);
M = M || ((z_D*E) | (E | Mdiag));
return M;
);

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

removeConstantTerms = method()
removeConstantTerms(List) := List => ls -> (
rslt := {};
for i from 0 to length(ls)-1 do (
f := someTerms(ls_i,-1,1);
if( (degree(f))_0 == 0) then (
rslt = append(rslt, ls_i - f);
) else (
rslt = append(rslt, ls_i);
);
);
return rslt;
);


-- Coefficient of w_3^k = z_3^(-k) (for 6 <= k <= 8) in all other variables, k = |S| - |T|:
M = createMatrixWithVs(Dbound,{});
L1 = submatrix(M,{0..8},{0..8});
L2 = submatrix(M,{9..17},{9..17});
L3 = submatrix(M,{18..26},{18..26});
E = submatrix(M,{0..8},{9..17});

-- try more later.
lsGens = {};
for k from 6 to 6 do (
rslt = 0;
for i from k to Qtilde do (
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
f = (-1)^(Qtilde - i) * det(Mfinal,Strategy=>Bareiss);
rslt = rslt + f;
);
);
);
rslt = w_3^k*rslt;

(T,C) = coefficients sub(rslt,AAAV);
C = sub(C,V);
lsGens = append(lsGens,removeConstantTerms(flatten entries C));
);

-- lsGens is a list of three lists of some of the coefficients of the dispersion polynomial (minus constant terms),
-- hence I is a subideal of the ideal of all spectral invariants:
I = ideal(flatten lsGens);

use V;
load("physicsstuff.m2");
saveValue(lsGens_0, "lsGens6.m2")


-- Selecting the lowest degree parts of the entries of lsGens and making some ideals out of them: 
V1 = K[v_ls1..v_ls3, MonomialOrder=>{Weights=>toList(27:-1)}, Global=>false];
lsGensLeast = {};
for i from 0 to length(flatten lsGens)-1 do (
lsGensLeast = append(lsGensLeast, leadTerm(1,sub((flatten lsGens)_i,V1)) );
);
lsGensLeast = delete(sub(0,V1),lsGensLeast);
ILeast = sub(ideal(lsGensLeast),V);
lsGensLeast = flatten entries gens ILeast;
lsGensLeast1 = select(lsGensLeast, p -> (degree(p))_0 == 1);
lsGensLeast2 = select(lsGensLeast, p -> (degree(p))_0 == 2);
ILeast1 = ideal(lsGensLeast1);
ILeast2 = ideal(lsGensLeast2);

