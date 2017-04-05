% pigs model from Lauritzen and Nilsson, 2001

seed = 0;
rand('state', seed);
randn('state', seed);

% we number nodes down and to the right
h = [1 5 9 13];
t = [2 6 10];
d = [3 7 11];
u = [4 8 12 14];

N = 14;
dag = zeros(N);

% causal arcs
for i=1:3
  dag(h(i), [t(i) h(i+1)]) = 1;
  dag(d(i), [u(i) h(i+1)]) = 1;
end
dag(h(4), u(4)) = 1;

% information arcs
fig = 3;
switch fig
 case 0,
  % no info arcs
 case 1,
   % no-forgetting policy (figure 1)
   for i=1:3
     dag(t(i), d(i:3)) = 1;
   end
 case 2,
  % reactive policy (figure 2)
  for i=1:3
    dag(t(i), d(i)) = 1;
  end
 case 7,
  % omniscient policy (figure 7: di has access to hidden state h(i-1))
  dag(t(1), d(1)) = 1;
  for i=2:3
    %dag([h(i-1) t(i-1) d(i-1)], d(i)) = 1;
    dag([h(i-1) d(i-1)], d(i)) = 1; % t(i-1) is redundant given h(i-1)
  end
end

ns = 2*ones(1,N);
ns(u) = 1;

% parameter tying
params = ones(1,N);
uparam = 1;
final_uparam = 2;
tparam = 3;
h1_param = 4;
hparam = 5;
dparams = 6:8;

params(u(1:3)) = uparam;
params(u(4)) = final_uparam;
params(t) = tparam;
params(h(1)) = h1_param;
params(h(2:end)) = hparam;
params(d) = dparams;

limid = mk_limid(dag, ns, 'chance', [h t], 'decision', d, 'utility', u, 'equiv_class', params);

% h = 1 means healthy, h = 2 means diseased
% d = 1 means don't treat, d = 2 means treat
% t = 1 means test shows healthy, t = 2 means test shows diseased


  limid.CPD{final_uparam} = tabular_utility_node(limid, u(4));
  limid.CPD{uparam} = tabular_utility_node(limid, u(1)); % costs have negative utility!
  
  % h  P(t=1) P(t=2)
  % 1  0.9   0.1
  % 2  0.2   0.8
  limid.CPD{tparam} = tabular_CPD(limid, t(1));
  
  % P(h1)
  limid.CPD{h1_param} = tabular_CPD(limid, h(1));
  
  % hi di P(hj=1) P(hj=2),  j = i+1, i=1:3
  % 1  1  0.8     0.2
  % 2  1  0.1     0.9
  % 1  2  0.9     0.1
  % 2  2  0.5     0.5
  limid.CPD{hparam} = tabular_CPD(limid, h(2));

% Decision nodes get assigned uniform policies by default
for i=1:3
  limid.CPD{dparams(i)} = tabular_decision_node(limid, d(i));
end


inference_engine = jtree_limid_inf_engine(limid);
max_iter = 1;
[strategy, MEU, niter] = solve_limid(inference_engine, 'max_iter', max_iter);
MEU
strategy

% check results match those in the paper (p. 22)
% direct_policy = eye(2); % treat iff test is positive
% never_policy = [1 0; 1 0]; % never treat
% tol = 1e-0; % results in paper are reported to 0dp
% for e=exact(:)'
%   switch fig
%    case 2, % reactive policy
%     assert(approxeq(MEU(e), 727, tol));
%     assert(approxeq(strategy{e}{d(1)}(:), never_policy(:)))
%     assert(approxeq(strategy{e}{d(2)}(:), direct_policy(:)))
%     assert(approxeq(strategy{e}{d(3)}(:), direct_policy(:)))
%    case 1, assert(approxeq(MEU(e), 729, tol));
%    case 7, assert(approxeq(MEU(e), 732, tol));
%   end
% end
% 
% 
% for e=approx(:)'
%   for i=1:3
%     approxeq(strategy{exact(1)}{d(i)}, strategy{e}{d(i)})
%     dispcpt(strategy{e}{d(i)})
%   end
% end

