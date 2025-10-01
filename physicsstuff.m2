topLevelMode = Standard

BlockPeriodicMatrix1DLap = method(TypicalValue => List)
BlockPeriodicMatrix1DLap(ZZ) := (Sequence) => (a)-> (
    local outMatrix;
    local R;
    R = ZZ/(nextPrime(10000))[x_1,z,y_1,q_1 .. q_(a)];
    local currow;
    local toprow;
    local botrow;
    toprow = flatten {{2 + q_1-z,-1},(new List from (a-3):0_R), {-y_1}};
    botrow = flatten {{-x_1},(new List from (a-3):0_R), {-1,2 + q_a-z}};
    outMatrix = {toprow};
    for i from 2 to a-1 do(
    currow = flatten{(new List from (i-2):0_R), {-1,2+q_i-z,-1}, (new List from (a-i-1):0_R)};
    outMatrix = append(outMatrix,currow);
    );
    outMatrix = append(outMatrix,botrow);
    outMatrix = matrix(outMatrix);
    return (outMatrix,R)
)

createPerturbationIdeal = method()
createPerturbationIdeal(ZZ) := Ideal => a -> (
    local denseData;
    (denseDataMat,R) = BlockPeriodicMatrix1DLap(a);
    specm = map (R, R, {1,z + 2,1,q_1 .. q_(a)}); --Here we are adding 2 to make the spectral problem fit our original problem as
    -- in the code we are using the graph laplacian, but in the problem we add 2 to the eigenvalues to get the spectral problem.
    --we also fix the quaismomentum to 1
    smat = specm denseDataMat; --densedata_0 in this case is the spectral problem matrix
    spol = det(smat); --Here we take the determinant to get P_v
    use R;
    varsss = new List from a:0;
    specma = map (R, R, join({1,z,1},varsss));
    
    DF2 = spol - specma spol; --Here we take the difference of P_v and P_0
    K = coefficients(DF2,Variables=>{z});
    KL = entries K_1_0;
    KLu = unique KL; -- allows us to extract the coefficients of the polynomial in z
    proj = map(ZZ/(nextPrime(10000))[x_1 .. x_a], R, {0,0,0, x_1 .. x_(a)}); -- lets forget the variables that aren't in the ideal
    return ideal(KLu / proj)
)

---- after some experimenting, this is how to get a sparse polynomial of degree d
sparsehomogeneous = (d,R) -> ((matrix{for i from 1 to binomial(n+d-1,d) list random(0,1)}*transpose(basis(d,R)))_0)_0

sparseinhomogeneous = (d,R) -> sum(for i from 1 to d list sparsehomogeneous(i,R))

elementarySymmetric = (R) -> (for k from 1 to numgens R list sum (apply(subsets(flatten entries vars R, k), S -> product S)))

symmetrization = method()
symmetrization(Ideal) := Ideal => I -> (
    R = ring I;
    -- Generate all permutations of variables
    allPerms := permutations flatten entries vars R;
    
    -- Create the intersection of all permuted ideals
    symmetricIdeal := I;
    for perm in allPerms do (
        -- Create ring map for this permutation
        phi := map(R, R, perm);
        -- Intersect with the permuted ideal
        symmetricIdeal = intersect(symmetricIdeal, phi(I));
    );
    
    return symmetricIdeal
)

createRandomPerturbationIdeal = method()
createRandomPerturbationIdeal(ZZ) := Ideal => a -> (
    R = ZZ/(nextPrime(10000))[x_1 .. x_a];
    EList = elementarySymmetric(R);
    FList = for d from 0 to a-1 list sparseinhomogeneous(d,R);
    IList = EList + FList;
    return ideal(IList)
)



--a by b vertex  fundamental domains for the 2x2 matrix
--and return matrix representation for a general laplace beltrami operator
-- on an action adjacent dense graph
BlockPeriodicMatrix2DLapI = method(TypicalValue => List)
BlockPeriodicMatrix2DLapI(ZZ,ZZ,ZZ) := (Sequence) => (a,b,p)-> (
     local edges; local toteEdges; local invFuncs; local toMatrixList, local toRowList; local zList; local outList; local outMatrix;
     local curIndex;
     local R;
     local W;
     local I;
     local adjpoly;
     local yirep;
     invFuncs = {};

     R = ZZ/p[x_1,x_2,z,y_1,y_2,q_1 .. q_(a*b)];
     for i from 1 to 2 do(
        invFuncs = append(invFuncs, x_i*y_i -1);     
     );     
     I = ideal (toSequence invFuncs);
     toMatrixList = new MutableList;
     zList = {};
     for i from 0 to a*b-1 do(
     zList = append(zList, 0);
     );     
     --make a double nested list so that we can convert this to a matrix later, make it nxn
     for i from 1 to a*b do( -- declare like this so that all rows are unique objects
     toMatrixList = append(toMatrixList, new MutableList from (a*b):0_R);
     );       
     --okay so lets iterate through each bipartite graph
     --we will look at all the edges connected to a node one at a time, going through the nodes not part of the complete subgraph
     -- this will require one loop to go through each bipartite graph and another loop to go through each node and another
     --for the n edges on each node
     --it will then require one more loop after these nested loops to account for the edges in the complete graph
     
     --yirep to represent y_i
     yirep = new MutableList;
     for i from 1 to 2 do(
     yirep = append(yirep,1_R);
     ); 
     --need yirep in this way so can indentify y_i = adjpoly_i
     for i from 0 to 1 do(
     for j from 1 to 2 do(
         if ((i +1) != j) then(
              yirep#i = yirep#i* (x_j)_R;    
          );
        );
     );

--for the rest need to still multiply by all terms, use adjpoly
     adjpoly = 1_R;
     for i from 1 to 2 do(
     adjpoly = adjpoly*(x_i)_R;
    ); 
 
     for j from 0 to a-1 do( --vertical edges leaving FD
  k = a*b-a+j;
 (toMatrixList#j)#j = (toMatrixList#j)#j + adjpoly;
                 (toMatrixList#k)#k = (toMatrixList#k)#k + adjpoly;
                 (toMatrixList#j)#k = (toMatrixList#j)#k - x_2*adjpoly;
                 (toMatrixList#k)#j = (toMatrixList#k)#j - yirep#1;      
              ); 
     for j from 0 to b-1 do( --horizontal edges leaving FD
  l = 1 + a*j -1;
  k = a*(j+1) - 1;
          curIndex = a+j+1;
         (toMatrixList#l)#l = (toMatrixList#l)#l + adjpoly;
                 (toMatrixList#k)#k = (toMatrixList#k)#k + adjpoly;
                 (toMatrixList#k)#l = (toMatrixList#k)#l - x_1*adjpoly;
                 (toMatrixList#l)#k = (toMatrixList#l)#k - yirep#0;
              );
      --need to remember to subtract from each diagonal by w
     for j from 0 to a*b-1 do( --going through nodes of a particular partition
              toMatrixList#j#j = toMatrixList#j#j - z*adjpoly + q_(j+1)*adjpoly;
         );
     -- right internal edges
curIndex = 1;
      for j from 0 to b-1 do( --
for k from 0 to a-2 do( --going through the edges
cur = j*a + k;
adj = j*a + k + 1;
(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + adjpoly;
                 (toMatrixList#adj)#adj = (toMatrixList#adj)#adj + adjpoly;
(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - adjpoly;
                 (toMatrixList#adj)#cur = (toMatrixList#adj)#cur - adjpoly;
curIndex = curIndex+1;
);
         );   

     -- down internal edges
curIndex  = 1;
for j from 0 to a-1 do( --
for k from 0 to b-2 do( --going through the edges
cur = j + k*a;
adj = j + k*a + a;
(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + adjpoly;
                (toMatrixList#adj)#adj = (toMatrixList#adj)#adj + adjpoly;
(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - adjpoly;
                (toMatrixList#adj)#cur = (toMatrixList#adj)#cur - adjpoly;
curIndex = curIndex +1;
);
         );        
     
     
     for j from 0 to a*b-1 do (
     toMatrixList#j = new List from toMatrixList#j;
     );    
    
     toMatrixList = new List from toMatrixList;
     outMatrix = matrix(toMatrixList);
     
--     stdio << theideals;
--     stdio << dims;
--     stdio << degs;
local DF;
local Ra;
    DF = {};    
 --   DF = append(DF, sub(det(outMatrix,Strategy => Cofactor),R));
 --   for i from 1 to 2 do (
 --   DF = append(DF,(diff(x_i, DF_0)));
 --   );
     Ra = ZZ/p[x_1,x_2,z,y_1,y_2];
     return (outMatrix,R,I,Ra,DF)
     )



BlockPeriodicMatrix3DLapI = method(TypicalValue => List)
BlockPeriodicMatrix3DLapI(ZZ,ZZ,ZZ,ZZ) := (Sequence) => (a,b,c,p)-> (
     local edges; local toteEdges; local invFuncs; local toMatrixList, local toRowList; local zList; local outList; local outMatrix;
     local curIndex;
     local R;
     local W;
     local I;
     local adjpoly;
     local yirep;
     invFuncs = {};

     R = ZZ/p[x_1,x_2,x_3,z,y_1,y_2,y_3,q_1 .. q_(a*b*c)];
     for i from 1 to 3 do(
        invFuncs = append(invFuncs, x_i*y_i -1);     
     );     
     I = ideal (toSequence invFuncs);
     toMatrixList = new MutableList;
     zList = {};
     for i from 0 to a*b*c-1 do(
     zList = append(zList, 0);
     );     
     --make a double nested list so that we can convert this to a matrix later, make it nxn
     for i from 1 to a*b*c do( -- declare like this so that all rows are unique objects
     toMatrixList = append(toMatrixList, new MutableList from (a*b*c):0_R);
     );         
     --okay so lets iterate through each bipartite graph
     --we will look at all the edges connected to a node one at a time, going through the nodes not part of the complete subgraph
     -- this will require one loop to go through each bipartite graph and another loop to go through each node and another
     --for the n edges on each node
     --it will then require one more loop after these nested loops to account for the edges in the complete graph
     
     --yirep to represent y_i
     yirep = new MutableList;
     for i from 1 to 3 do(
     yirep = append(yirep,1_R);
     ); 
     e = {1_R, 1_R, 1_R,1_R,1_R};
     --need yirep in this way so can indentify y_i = adjpoly_i
     for i from 0 to 2 do(
     for j from 1 to 3 do(
         if ((i +1) != j) then(
              yirep#i = yirep#i* (x_j)_R;    
          );
         );
     );

--for the rest need to still multiply by all terms, use adjpoly
     adjpoly = 1_R;
     for i from 1 to 3 do(
     adjpoly = adjpoly*(x_i)_R;
     ); 
    for i from 0 to c-1 do(
    	for j from 0 to a-1 do( --vertical edges leaving FD
	    ji = i*a*b + j;
  	    k = (i+1)*a*b-a+j;
	    (toMatrixList#(ji))#(ji) = (toMatrixList#(ji))#(ji) + e_2*adjpoly;
            (toMatrixList#(k))#(k) = (toMatrixList#(k))#(k) + e_2*adjpoly;
            (toMatrixList#(k))#(ji) = (toMatrixList#(k))#(ji) - x_2*e_2*adjpoly;
            (toMatrixList#(ji))#(k) = (toMatrixList#(ji))#(k) - yirep#1*e_2;      
	    ); 	
	);
    for i from 0 to c-1 do(
     for j from 0 to b-1 do( --horizontal edges leaving FD
  l =  a*j + a*b*i;
  k = a*(j+1) - 1 + a*b*i;
      	 li = l;
	 ki = k;
         (toMatrixList#li)#li = (toMatrixList#li)#li + e_3*adjpoly;
                 (toMatrixList#ki)#ki = (toMatrixList#ki)#ki + e_3*adjpoly;
                 (toMatrixList#ki)#li = (toMatrixList#ki)#li - x_1*e_3*adjpoly;
                 (toMatrixList#li)#ki = (toMatrixList#li)#ki - yirep#0*e_3;
              );
	  );
    for i from 0 to a-1 do(	  
    for j from 0 to b-1 do( --3rd dim edges leaving FD
  l = a*j+i;
  k = (c-1)*a*b + l;
      	 li = l;
	 ki = k;
         (toMatrixList#li)#li = (toMatrixList#li)#li + e_4*adjpoly;
                 (toMatrixList#ki)#ki = (toMatrixList#ki)#ki + e_4*adjpoly;
                 (toMatrixList#ki)#li = (toMatrixList#ki)#li - x_3*e_4*adjpoly;
                 (toMatrixList#li)#ki = (toMatrixList#li)#ki - yirep#2*e_4;
              );
	  );
      --need to remember to subtract from each diagonal by w
     for j from 0 to a*b*c-1 do( --going through nodes of a particular partition also adding internal domain edges
	      ji = j;	      
	      toMatrixList#ji#ji = toMatrixList#ji#ji - z*adjpoly + q_(ji+1)*adjpoly;	      	      
         );
     -- right internal edges
for i from 0 to c-1 do(
for j from 0 to b-1 do( --
for k from 0 to a-2 do( --going through the edges
    cur = a*b*i + j*a + k; --will be 2nd edge for cur
    cur = cur;
    adj = a*b*i + j*a + k + 1; -- will be 1st edge for adj
    adj = adj;
    (toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_3*adjpoly;
    (toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_3*adjpoly;
    (toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_3*adjpoly;
    (toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_3*adjpoly;
);
         );   
);
     -- down internal edges
for i from 0 to c-1 do(
for j from 0 to a-1 do( --
for k from 0 to b-2 do( --going through the edges
    	cur = a*b*i + j + k*a; -- will be 2nd vert for cur
    	adj = a*b*i + j + k*a + a; --will be 1st vert for adj
	cur = cur;
	adj = adj;
    	(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_2*adjpoly;
    	(toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_2*adjpoly;
    	(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_2*adjpoly;
    	(toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_2*adjpoly;
);
         );    
     );    
for i from 0 to a-1 do( --3d edging
for j from 0 to b-1 do( --
for k from 0 to c-2 do( --going through the edges
    	cur = i + j*a + k*a*b; -- will be 2nd vert for cur
    	adj = i + j*a + k*a*b + a*b; --will be 1st vert for adj
	cur = cur;
	adj = adj;
    	(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_4*adjpoly;
    	(toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_4*adjpoly;
    	(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_4*adjpoly;
    	(toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_4*adjpoly;
);
         );    
     );         
         
     
     
     for j from 0 to a*b*c-1 do (
     toMatrixList#j = new List from toMatrixList#j;
     );    
    
     toMatrixList = new List from toMatrixList;
     outMatrix = matrix(toMatrixList);
     
--     stdio << theideals;
--     stdio << dims;
--     stdio << degs;
local DF;
local Ra;
    DF = {};    
--    DF = append(DF, sub(det(outMatrix,Strategy => Cofactor),R));
--    for i from 1 to 3 do (
--    DF = append(DF,(diff(x_i, DF_0)));
 --   );
     Ra = ZZ/p[x_1,x_2,z,y_1,y_2];
     return (outMatrix,R,I,Ra,DF)
     )
 



 --a by b vertex  fundamental domains for the 2x2 matrix
--and return matrix representation for a general laplace beltrami operator
-- on an action adjacent dense graph
BlockPeriodicMatrix3DLap = method(TypicalValue => List)
BlockPeriodicMatrix3DLap(ZZ,ZZ,ZZ) := (Sequence) => (a,b,c)-> (
     local edges; local toteEdges; local invFuncs; local toMatrixList, local toRowList; local zList; local outList; local outMatrix;
     local curIndex;
     local R;
     local W;
     local I;
     local adjpoly;
     local yirep;
     invFuncs = {};

     R = QQ[x_1,x_2,x_3,z,y_1,y_2,y_3,q_1 .. q_(a*b*c)];
     for i from 1 to 3 do(
        invFuncs = append(invFuncs, x_i*y_i -1);     
     );     
     I = ideal (toSequence invFuncs);
     toMatrixList = new MutableList;
     zList = {};
     for i from 0 to a*b*c-1 do(
     zList = append(zList, 0);
     );     
     --make a double nested list so that we can convert this to a matrix later, make it nxn
     for i from 1 to a*b*c do( -- declare like this so that all rows are unique objects
     toRowList = new MutableList;
     for j from 1 to a*b*c do (
     toRowList = append(toRowList, R_zList - R_zList);
     );
     toMatrixList = append(toMatrixList, toRowList);
     );       
     --okay so lets iterate through each bipartite graph
     --we will look at all the edges connected to a node one at a time, going through the nodes not part of the complete subgraph
     -- this will require one loop to go through each bipartite graph and another loop to go through each node and another
     --for the n edges on each node
     --it will then require one more loop after these nested loops to account for the edges in the complete graph
     
     --yirep to represent y_i
     yirep = new MutableList;
     for i from 1 to 3 do(
     yirep = append(yirep,1_R);
     ); 
     e = {1_R, 1_R, 1_R,1_R,1_R};
     --need yirep in this way so can indentify y_i = adjpoly_i
     for i from 0 to 2 do(
     for j from 1 to 3 do(
         if ((i +1) != j) then(
              yirep#i = yirep#i* (x_j)_R;    
          );
         );
     );

--for the rest need to still multiply by all terms, use adjpoly
     adjpoly = 1_R;
     for i from 1 to 3 do(
     adjpoly = adjpoly*(x_i)_R;
     ); 
    for i from 0 to c-1 do(
    	for j from 0 to a-1 do( --vertical edges leaving FD
	    ji = i*a*b + j;
  	    k = (i+1)*a*b-a+j;
	    (toMatrixList#(ji))#(ji) = (toMatrixList#(ji))#(ji) + e_2*adjpoly;
            (toMatrixList#(k))#(k) = (toMatrixList#(k))#(k) + e_2*adjpoly;
            (toMatrixList#(k))#(ji) = (toMatrixList#(k))#(ji) - x_2*e_2*adjpoly;
            (toMatrixList#(ji))#(k) = (toMatrixList#(ji))#(k) - yirep#1*e_2;      
	    ); 	
	);
    for i from 0 to c-1 do(
     for j from 0 to b-1 do( --horizontal edges leaving FD
  l =  a*j + a*b*i;
  k = a*(j+1) - 1 + a*b*i;
      	 li = l;
	 ki = k;
         (toMatrixList#li)#li = (toMatrixList#li)#li + e_3*adjpoly;
                 (toMatrixList#ki)#ki = (toMatrixList#ki)#ki + e_3*adjpoly;
                 (toMatrixList#ki)#li = (toMatrixList#ki)#li - x_1*e_3*adjpoly;
                 (toMatrixList#li)#ki = (toMatrixList#li)#ki - yirep#0*e_3;
              );
	  );
    for i from 0 to a-1 do(	  
    for j from 0 to b-1 do( --3rd dim edges leaving FD
  l = a*j+i;
  k = (c-1)*a*b + l;
      	 li = l;
	 ki = k;
         (toMatrixList#li)#li = (toMatrixList#li)#li + e_4*adjpoly;
                 (toMatrixList#ki)#ki = (toMatrixList#ki)#ki + e_4*adjpoly;
                 (toMatrixList#ki)#li = (toMatrixList#ki)#li - x_3*e_4*adjpoly;
                 (toMatrixList#li)#ki = (toMatrixList#li)#ki - yirep#2*e_4;
              );
	  );
      --need to remember to subtract from each diagonal by w
     for j from 0 to a*b*c-1 do( --going through nodes of a particular partition also adding internal domain edges
	      ji = j;	      
	      toMatrixList#ji#ji = toMatrixList#ji#ji - z*adjpoly + q_(ji+1)*adjpoly;	      	      
         );
     -- right internal edges
for i from 0 to c-1 do(
for j from 0 to b-1 do( --
for k from 0 to a-2 do( --going through the edges
    cur = a*b*i + j*a + k; --will be 2nd edge for cur
    cur = cur;
    adj = a*b*i + j*a + k + 1; -- will be 1st edge for adj
    adj = adj;
    (toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_3*adjpoly;
    (toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_3*adjpoly;
    (toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_3*adjpoly;
    (toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_3*adjpoly;
);
         );   
);
     -- down internal edges
for i from 0 to c-1 do(
for j from 0 to a-1 do( --
for k from 0 to b-2 do( --going through the edges
    	cur = a*b*i + j + k*a; -- will be 2nd vert for cur
    	adj = a*b*i + j + k*a + a; --will be 1st vert for adj
	cur = cur;
	adj = adj;
    	(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_2*adjpoly;
    	(toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_2*adjpoly;
    	(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_2*adjpoly;
    	(toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_2*adjpoly;
);
         );    
     );    
for i from 0 to a-1 do( --3d edging
for j from 0 to b-1 do( --
for k from 0 to c-2 do( --going through the edges
    	cur = i + j*a + k*a*b; -- will be 2nd vert for cur
    	adj = i + j*a + k*a*b + a*b; --will be 1st vert for adj
	cur = cur;
	adj = adj;
    	(toMatrixList#cur)#cur = (toMatrixList#cur)#cur + e_4*adjpoly;
    	(toMatrixList#adj)#adj = (toMatrixList#adj)#adj + e_4*adjpoly;
    	(toMatrixList#cur)#adj = (toMatrixList#cur)#adj - e_4*adjpoly;
    	(toMatrixList#adj)#cur = (toMatrixList#adj)#cur - e_4*adjpoly;
);
         );    
     );         
         
     
     
     for j from 0 to a*b*c-1 do (
     toMatrixList#j = new List from toMatrixList#j;
     );    
    
     toMatrixList = new List from toMatrixList;
     outMatrix = matrix(toMatrixList);
     
--     stdio << theideals;
--     stdio << dims;
--     stdio << degs;
local DF;
local Ra;
    DF = {};    
--    DF = append(DF, sub(det(outMatrix,Strategy => Cofactor),R));
--    for i from 1 to 3 do (
--    DF = append(DF,(diff(x_i, DF_0)));
 --   );
     Ra = QQ[x_1,x_2,z,y_1,y_2];
     return (outMatrix,R,I,Ra,DF)
     )