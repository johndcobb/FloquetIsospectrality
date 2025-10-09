loadPackage "SpechtModule";

K = QQ;
n = 3;

perm = permutations n;

var = toSequence(reverse(toList(x_1..x_n)));
P = K[var, MonomialOrder=>GLex];

-- elem is the list of the first n elementary symmetric polynomials in n variables:
elem = {};
for i from 1 to n do (
el = 0;
ls = subsets(toList(1..n),i);
for j from 0 to length(ls)-1 do (
mon = 1;
for k from 0 to (i-1) do (
mon = mon*x_((ls_j)_k);
);
el = el + mon;
);
elem = append(elem,el);
);
I = ideal(elem);

artin = sub(basis(P/I),P);

w = {};
for i from 1 to n do (
w = append(w,1);
);
for i from 0 to (n-1)*n! do (
w = append(w,0);
);
Ahelp = K[var,a_1..a_((n-1)*n!),t, MonomialOrder=>{Weights=>w, GLex}];

pert = {};
l = 1;
for i from 2 to n do (
monshelp = select(drop(flatten entries artin,1), pol -> ((degree(pol))_0 <= (i-1)) );
mons = {};
for j from 0 to length(monshelp)-1 do (
mons = append(mons, sub(monshelp_j,Ahelp) * t^(i-(degree(monshelp_j))_0) );
);
monsMat = matrix {mons};
f = ( (matrix {toList(a_l..a_(l+length(mons)-1))}) * (transpose monsMat) )_(0,0);
pert = append(pert,f);
l = l + length(mons);
);

w = drop(w,-((n-1)*n!-l+1));
A = K[var,a_1..a_(l-1),t, MonomialOrder=>{Weights=>w, GLex}];
pert = flatten entries sub(matrix {pert}, A);

artin = sub(artin,A);

A2 = K[a_1..a_(l-1)][t][Y][var];
use A;

lsCharPols = {};

mltplr = sub(x_1,A);

N = n!-1;

gbTrace = 3;

for j from 0 to N do (

J = sub(ideal(elem_0),A);
for i from 1 to n-1 do (
J = J + ideal(sub(elem_i,A) + sub(permutePolynomial(perm_j, sub(pert_(i-1), A2)), A) );
);

(something,C) = coefficients( sub((mltplr*artin) % J, A2), Monomials=>sub(artin, A2));
charPol = det(Y*id_(A2^n!) - C);
lsCharPols = join( lsCharPols, drop(flatten entries (coefficients(sub(charPol, coefficientRing A2)))_1, 1) );
);

Rel = ideal(lsCharPols);
decompose Rel

