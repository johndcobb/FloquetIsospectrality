K = QQ;
n = 3;

P = K[x_1..x_n];

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


-- The following three ideals give counterexamples for n=3:

J1 = ideal(elem_0);
for i from 2 to n do (
J1 = J1 + ideal(elem_(i-1) + x_1^(i-1));
);
decompose J1

J2 = ideal(elem_0, elem_1 - x_1 - x_2, elem_2 + x_1*x_2 - x_1 - x_2);
decompose J2

J3 = ideal(elem_0, elem_1 - x_2, elem_2 + x_1^2 + x_1*x_2 + x_2);
decompose J3

