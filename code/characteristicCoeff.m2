---- my goal is to create a very fast parallelizable algorithm to pull off the k^th coefficient of the characteristic polynomial of a matrix.

--- characteristicCoeffs takes in a matrix M and a nonnegative integer k and returns the k^th coefficient of the characteristic polynomial of M.
--- It does this by taking the trace of powers of M and then using newton's identities.
--- If you already have computed some of the previous coefficients, this will help in the computation of the next computation. You can pass them in as a list.
--- k describes how many coefficients to find.
characteristicCoeffs = method()
characteristicCoeffs(Matrix, ZZ, List,List) := Sequence => (M, k, prevCoeffs, prevTraces) -> (
    e := local e;
    p := local p;
    n := numRows M;
    R := (ring M)[e_0..e_n, p_0..p_n];

    -- we don't have enough traces, we need to compute some more.
    if length prevTraces == 0 then prevTraces = {n}; 
    if length prevTraces - k <= 0 then (
        prevTraces = prevTraces | for i from length prevTraces to k-1 list trace(M^i);
    );
    tracesFixed := matrix{apply(prevTraces, t -> promote(t,R))};

    -- the following just puts the prevCoeffs into the correct ring and also gets rid of the alternating signs.
    if length prevCoeffs == 0 then prevCoeffs = {(-1)^n};
    prevCoeffsFixed := matrix{for idx from 0 to length prevCoeffs - 1 list (-1_R)^(idx+n)*promote(prevCoeffs_idx, R)};

    newtonIds := newtonIdentitySymmetry(n,R);

    subvalues := mutableMatrix(prevCoeffsFixed | (vars R)_{length(prevCoeffs)..n} | tracesFixed | (vars R)_{n+length prevTraces+1..2*n+1} );
    partialNewtonIds := apply(newtonIds, e -> sub(e,matrix subvalues));
    result := for idx from 0 to k-1 list subvalues_(0,idx) = sub(partialNewtonIds_idx, matrix subvalues);

    -- now we need to build in the alternating signs and project back to the original ring.
    proj := map(ring(M), R, matrix{toList((numcols vars R):1_(ring(M)))});
    (for idx from 0 to k-1 list proj((-1)^(n+idx)*result_idx), prevTraces)
)
characteristicCoeffs(Matrix, ZZ, List) := Sequence => (M, k, prevCoeffs) -> (
    characteristicCoeffs(M,k,prevCoeffs,{})
)
characteristicCoeffs(Matrix, ZZ) := List => (M,k) -> characteristicCoeffs(M, k, {})
characteristicCoeffs(Matrix) := List => M -> characteristicCoeffs(M,numcols M)

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
