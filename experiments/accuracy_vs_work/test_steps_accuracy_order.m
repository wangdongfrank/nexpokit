
rng(1); % reset the random generator

ntrials = 25;
topks = [10,25,100,1000];
nets = [11:16];
nsteps = 10;
nmults = [2 5 10 15 25 50];
storetols = [1e-4 1e-5];

clear record recordnn recordeffmv recordts recordtsnn ...
    recordtau recordtaunn recordtstau recordtstaunn recordstol

for network_id=nets;
    name = graphnames(network_id);
    A = load_graph(name);
    P = sparse(normout(A)');
    n = size(P,1);
    %p = randperm(n); % generate a random list of nodes
    % Pick nodes propotional to their degree by using miniverts on the
    % edges.
    [~,miniverts] = find(A);
    % each vertex appears in miniverts with the probability of its degree
    % so we want a random set of miniverts
    pmv = randperm(numel(miniverts));
    p = zeros(ntrials,1);
    pickedverts = zeros(n,1);
    curmv = 1;
    for i=1:ntrials
        while p(i) == 0
            if curmv > nnz(A)
                error('could not find enough verts!');
            end
            v = miniverts(pmv(curmv));
            curmv = curmv + 1;
            if pickedverts(v), continue; end
            p(i) = v;
            pickedverts(v) = 1;
        end
    end
    maxsteps = ceil(logspace(2,log10(10*n),nsteps));
    tols = logspace(-2,-8,nsteps);
    
    for t=1:ntrials
        j = p(t); % get the tth entry in the random list, it's a ranodm node!
        
        xtrue = kmatexp(P,j,ceil(10*log(n)/log(2))); % compute the exact solution
        [~,px] = sort(xtrue,'descend');
        xtruenn = xtrue; % remove neighbors and self
        xtruenn(j) = -Inf;
        xtruenn(logical(A(:,j))) = -Inf;
        [~,pxnn] = sort(xtruenn,'descend');
        nleft = sum(isfinite(xtruenn));
        
        for ti=1:numel(storetols)
            [~,~,npushest] = gexpmq_mex(P,j,11,storetols(ti),50*n);
            recordstol(network_id,ti,t) = npushest/nnz(A);
        end
        
        for si=1:nsteps
            ns = maxsteps(si);
            tol = tols(si);            
            [xapprox asteps npushes] = gexpmq_mex(P,j,11,tol,ns);
            
            
            
            [~,pxa] = sort(xapprox,'descend');
            xapproxnn = xapprox;
            xapproxnn(j) = -Inf;
            xapproxnn(logical(A(:,j))) = -Inf;
            [~,pxann] = sort(xapproxnn,'descend');
            
            recordeffmv(network_id,si,t) = npushes/nnz(A);
            
            for ki=1:numel(topks)
                k = min(topks(ki),n);
                record(network_id,si,t,ki) = numel(intersect(px(1:k),pxa(1:k)))/k;
                recordtau(network_id,si,t,ki) = corr(xapprox(px(1:k)),xtrue(px(1:k)),'type','Kendall');
            end
            
            for ki=1:numel(topks)
                k = min(topks(ki),nleft);
                recordnn(network_id,si,t,ki) = numel(intersect(pxnn(1:k),pxann(1:k)))/k;
                recordtaunn(network_id,si,t,ki) = corr(xapproxnn(pxnn(1:k)),xtruenn(pxnn(1:k)),'type','Kendall');
            end
        end
        
        for nmi = 1:numel(nmults)
            nterms = nmults(nmi);
            
            xapprox = kmatexp(P,j,nterms);
            
            [~,pxa] = sort(xapprox,'descend');
            xapproxnn = xapprox;
            xapproxnn(j) = -Inf;
            xapproxnn(logical(A(:,j))) = -Inf;
            [~,pxann] = sort(xapproxnn,'descend');
            
            for ki=1:numel(topks)
                k = min(topks(ki),n);
                recordts(network_id,nmi,t,ki) = numel(intersect(px(1:k),pxa(1:k)))/k;
                recordtstau(network_id,nmi,t,ki) = corr(xapprox(px(1:k)),xtrue(px(1:k)),'type','Kendall');
            end
            
            for ki=1:numel(topks)
                k = min(topks(ki),nleft);
                recordtsnn(network_id,nmi,t,ki) = numel(intersect(pxnn(1:k),pxann(1:k)))/k;
                recordtstaunn(network_id,nmi,t,ki) = corr(xapproxnn(pxnn(1:k)),xtruenn(pxnn(1:k)),'type','Kendall');
            end
        end
    end
end
save 'test_steps_accuracy.mat' record recordnn recordeffmv ...
    recordts recordtsnn recordtau recordtaunn recordtstau recordtstaunn ...
    recordstol ...
    nsteps nmults ntrials topks nets storetols;