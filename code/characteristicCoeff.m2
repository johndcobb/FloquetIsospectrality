---- my goal is to create a very fast parallelizable algorithm to pull off the k^th coefficient of the characteristic polynomial of a matrix.

--- characteristicCoeffs takes in a matrix M and a nonnegative integer k and returns the k^th coefficient of the characteristic polynomial of M.
--- It does this by taking the trace of powers of M and then using newton's identities.
--- If you already have computed some of the previous coefficients, this will help in the computation of the next computation. You can pass them in as a list.
--- k describes how many more coefficients to find, in addition to the previous coefficients.
characteristicCoeffs = method()
characteristicCoeffs(Matrix, List, ZZ, Ring) := RingElement => (M,prevCoeffs,k, R) -> (
    n := numcols M;
    K := k + length prevCoeffs - 1; -- the last index of the list of coefficients we want to find.

    -- the following just puts the prevCoeffs into the correct ring and also gets rid of the alternating signs.
    prevCoeffsFixed := matrix{for idx from 0 to length prevCoeffs - 1 list (-1_R)^(idx+n)*promote(prevCoeffs_idx, R)};

    newtonIds := newtonIdentitySymmetry(n,R);

    traces := matrix{{n}};
    if K > 0 then traces = traces |  matrix{for i from 1 to K list trace(M^i)}; -- if this is the bottleneck, we may need to store the traces or only compute what we need...

    subvalues := mutableMatrix(prevCoeffsFixed | (vars R)_{length(prevCoeffs)..n} | traces | matrix{toList((n-K):1_R)} );
    partialNewtonIds := apply(newtonIds, e -> sub(e,matrix subvalues));
    result := for idx from 0 to K list subvalues_(0,idx) = sub(partialNewtonIds_idx, matrix subvalues);

    -- now we need to build in the alternating signs and project back to the original ring.
    proj := map(ring(M), R, matrix{toList((numcols vars R):1_(ring(M)))});
    for idx from 0 to K list proj((-1)^(n+idx)*result_idx)
)
characteristicCoeffs(Matrix, List, ZZ) := RingElement => (M, prevCoeffs, k) -> (
    e := local e;
    p := local p;
    n := numRows M;
    R := (ring M)[e_0..e_n, p_0..p_n];
    characteristicCoeffs(M,prevCoeffs,k,R)
)
characteristicCoeffs(Matrix, ZZ) := RingElement => (M,k) -> characteristicCoeffs(M, {(-1_(ring M))^(numcols M)}, k-1)
characteristicCoeffs(Matrix, ZZ, Ring) := RingElement => (M,k,R) -> characteristicCoeffs(M, {(-1_(ring M))^(numcols M)}, k-1, R)

--- If you already have computed some of the previous coefficients, this will help in the computation of the next computation.

newtonIdentitySymmetry = method()
-- newtonIdentitySymmetry takes in an integer k and n and returns list of the 1,2,,...,kth elementary symmetric polynomials in n variables in terms of the
-- elementary symmmetric polynomials and sum of powers of degrees (k-1) and lower.
newtonIdentitySymmetry(ZZ, Ring) := List => (k, R) -> (
    if k < 1 then error "k need to be positive integers";
    use R;
    maxIdx := (numColumns vars R) // 2;
    p := i -> if i < maxIdx then R_(i+maxIdx) else error("Index out of bounds");
    e := i -> if i < maxIdx then R_(i) else error("Index out of bounds");
    ({1_R} | (for i from 1 to k list (1/i)*(sum((for j from 1 to i list (-1)^(j-1)*e(i-j)*p(j))))))
)
newtonIdentitySymmetry(ZZ) := List => k -> (
    e := local e;
    p := local p;
    newtonIdentitySymmetry(k, QQ[e_0..e_k, p_0..p_k])
)
