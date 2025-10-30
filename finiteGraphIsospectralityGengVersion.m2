-- ==================== graph6 decoding ====================

-- all unordered pairs (i<j)
allPairs = n -> (
    P := {};
    for i from 1 to n-1 do
        for j from i+1 to n do P = append(P, {i,j});
    P
);

-- decode a single graph6 line (handles n <= 62 case)
g6toEdges = (s) -> (
    if #s == 0 then return {};
    n := (ascii(s#0))#0 - 63;        -- first char encodes n (e.g. 'E' -> 6)
    if n <= 1 then return {};
    m := (n*(n-1)) // 2;

    bits := new MutableList from for k from 0 to m-1 list 0;
    bitpos := 0;

    -- unpack chars s#1, s#2, ... each carries 6 bits (MSB first)
    for t from 1 to #s-1 do (
        v := (ascii(s#t))#0 - 63;
        if v < 0 or v > 63 then error "invalid graph6 character";
        for b from 0 to 5 do (        -- <-- replaced 'downTo' with 'by -1'
            if bitpos < m then (
                bits#bitpos = (v // (2^(5-b))) % 2;  -- (v >> b) & 1
                bitpos = bitpos + 1;
            )
        )
    );
    if bitpos < m then error "truncated graph6 line";

    P := allPairs n;
    edges := {};
    for idx from 0 to m-1 do if bits#idx == 1 then edges = append(edges, P#idx);
    edges
);

-- read whole file, split into nonempty lines, map decoder
readGraph6File = fileName -> (
    L := lines get fileName;
    L = select(L, s -> #s > 0);
    apply(L, g6toEdges)
);


-- Optional: run geng to produce a temp file of unlabeled graphs on n vertices
-- options:
--   connectedOnly => true/false
--   edgeBounds    => null or a 2-list {lo,hi} to bound edge count
runGeng = method(Options => {connectedOnly => false, edgeBounds => null});

runGeng ZZ := opts -> (n) -> (
    file := "geng_n" | toString n | ".g6";
    cmd := "nauty-geng ";
    if opts.connectedOnly then cmd = cmd | "-c ";
    if opts.edgeBounds =!= null then (
        lo := opts.edgeBounds#0; hi := opts.edgeBounds#1;
        cmd = cmd | toString n | " " | toString lo | ":" | toString hi | " > " | file
    ) else (
        cmd = cmd | toString n | " > " | file
    );
    run cmd;  -- <-- note: run "..." works without parentheses too
    file
);

-- Example usage:
-- file = runGeng(6, connectedOnly=>true);   -- unlabeled connected graphs on 6 vertices in graph6
-- graphs = readGraph6File file;             -- list of edge lists
-- =============== Bitset helpers ===============
-- allPairs reused

-- Map edge {i,j} (i<j) to its bit index
edgeIndexMap = n -> (
    M := new MutableHashTable;
    idx := 0;
    for i from 1 to n-1 do
        for j from i+1 to n do (
            M#{i,j} = idx;
            idx = idx + 1;
        );
    M
);

-- ========= tiny integer bit ops over the lowest m bits =========
bitOrM = (a, b, m) -> (
    r := 0_ZZ; p := 1_ZZ; x := a; y := b;
    for k from 0 to m-1 do (
        ak := x % 2; x = x // 2;
        bk := y % 2; y = y // 2;
        if ak == 1 or bk == 1 then r = r + p;
        p = p * 2;
    ); r
);

-- popcount( Emask AND NOT rem ) over m bits
popcountKept = (Emask, rem, m) -> (
    c := 0; e := Emask; r := rem;
    for k from 0 to m-1 do (
        ek := e % 2; rk := r % 2;
        if ek == 1 and rk == 0 then c = c + 1;
        e = e // 2; r = r // 2;
    ); c
);

-- ========= masks (return m, no fullMask needed) =========
buildMasks = (n, edges) -> (
    m := (n*(n-1)) // 2;
    idx := new MutableHashTable;
    t := 0;
    for i from 1 to n-1 do for j from i+1 to n do ( idx#{i,j} = t; t = t + 1 );
    Emask := 0_ZZ;
    Inc   := new MutableHashTable; for i from 1 to n do Inc#i = 0_ZZ;
    scan(edges, e -> (
        u := e#0; v := e#1; if u > v then (w := u; u = v; v = w);
        b := 2^(idx#{u,v});
        Emask = Emask + b;
        Inc#u = Inc#u + b; Inc#v = Inc#v + b;
    ));
    (Emask, Inc, m)
);

-- ========= remaining-edges using our helpers =========
remainingEdgesCount = (J, Emask, Inc, m) -> (
    rem := 0_ZZ;
    scan(J, i -> rem = bitOrM(rem, Inc#i, m));
    popcountKept(Emask, rem, m)
);

-- ========= combinatorics helpers =========
fact = n -> ( if n < 0 then error "factorial negative"; if n <= 1 then 1 else product toList(2..n) );
chooseK = (L, k) -> (
    if k < 0 then return {};
    if k == 0 then return { {} };
    if k > #L then return {};
    h := L#0; t := drop(L,1);
    apply(chooseK(t, k-1), S -> {h} | S) | chooseK(t, k)
);

-- ========= your two-vertex version (fixed) =========
sumRWithV0bitset = (n, edges, v0, v1) -> (
    if v0 < 1 or v0 > n or v1 < 1 or v1 > n or v0 == v1 then error "bad v0/v1";
    (Emask, Inc, m) := buildMasks(n, edges);
    base := select(toList(1..n), i -> i =!= v0 and i =!= v1);

    total := 0;
    for k from 1 to n-2 do (
        s1 := 0;
        scan(chooseK(base, k),     J -> s1 = s1 + remainingEdgesCount(J, Emask, Inc, m));

        s2 := 0;
        scan(chooseK(base, k-1),   J -> (
            s2 = s2 + remainingEdgesCount(J | {v0}, Emask, Inc, m);
            s2 = s2 + remainingEdgesCount(J | {v1}, Emask, Inc, m)
        ));

        s3 := 0;
        scan(chooseK(base, k-2),   J -> s3 = s3 + remainingEdgesCount(J | {v0,v1}, Emask, Inc, m));

        total = total
              + fact(k+1) * fact(n-k-2) * s1
              - fact(k)   * fact(n-k-1) * s2
              + fact(k-1) * fact(n-k)   * s3;
    );
    total
);

sumRAnyV0Nonzero = (n, edges) -> (
    for v0 from 1 to n-1 do (
        for v1 from v0+1 to n do (
            if sumRWithV0bitset(n, edges, v0, v1) =!= 0 then return true
        )
    );
    false
);

-- Convenience
sumRv1bitset = (n, edges) -> sumRWithV0bitset(n, edges, 1);

n=9
-- Example usage:

-- Generate unlabeled graphs (requires 'geng'):
file = runGeng(n, connectedOnly=>false);        -- CHANGE n here (careful with size!)
Gs   = readGraph6File file;                     -- list of edge-list graphs

-- Split by sumR at v0=1 using the faster bitset version:
zeros := {};
nonzeros := {};

-- Simpler: you already know n used in geng, so
scan(Gs, E -> (
    if sumRAnyV0Nonzero(n, E) == false then zeros = append(zeros, E)
    else nonzeros = append(nonzeros, E)
));
#zeros; #nonzeros;
zeros
nonzeros    
