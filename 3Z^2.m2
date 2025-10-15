load("physicsstuff.m2")

E = createPerturbationIdeal(3,3)
saveValue(flatten entries gens E, "E3x3.m2")
decompose E
ring E

load("physicsstuff.m2")


a=3
b=3
c=3
(outMatrix,R,I,Ra,DF) := BlockPeriodicMatrix3DLapI(a,b,c,nextPrime(10000));
    use R;

    specm := map(R,R, {x_1,x_2,x_3,z+4,y_1,y_2,y_3,q_1..q_(a*b*c)});
    smat := specm outMatrix;
    spol := determinant(smat, Strategy => Dynamic);

    specma := map(R,R, join({x_1,x_2,x_3,z,y_1,y_2,y_3}, new List from a*b*c:0));

    DF3 := spol - specma spol; --Here we take the difference of P_v and P_0
    K := unique entries (coefficients(DF3, Variables => {z,x_1,x_2,x_3}))_1_0;

    proj := map(ZZ/(nextPrime(10000))[y_1..y_4,x_1..x_(a*b)], R, {y_1, y_2, y_3, 0, y_4, y_5, y_6, x_1 .. x_(a*b)});

    return ideal(K / proj)