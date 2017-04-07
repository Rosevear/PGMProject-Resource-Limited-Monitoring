%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca
addpath(genpathKPM(pwd))

disp('Constructing the influence diagram');

%we number nodes down and to the right
S_true = [1 5 9];
S_obs = [2 6 10];
test_d = [3 7 11];
utility = [4 8 12];

%TODO: Ass final intratimeslice edges

N = 12;
dag = zeros(N);

%Construct the bayesian net's edges
for i = 1:2
   %The current true symptom influences the current uitility and the state of
   %the true symptom and the observed symptom at time t + 1
   dag(S_true(i), [utility(i) , S_true(i + 1), S_obs(i + 1)]) = 1;
   
   %The current observed symptom influences the current test and treatment
   %decision nodes
   dag(S_obs(i), test_d(i)) = 1;
   
   %The current test decision influences the current treatment and utility
   %and the state of the observed symptoms at time t + 1
   dag(test_d(i), [utility(i), S_obs(i + 1)]) = 1;
   
   %The current treatment decision influences the current utility and the
   %the true state and the observed state of the symptom at time t + 1
   %dag(treat_d(i), [utility(i), S_obs(i + 1), S_true(i + 1)]) = 1;
end

%Set node sizes (number of values for each node)
ns(2:25) = 10;
ns = ones(1, N);
ns(utility) = 1;
ns
 
%Indices in the limid CPD attribute that pick out the various cpds
util_param = 1;
S_true_params = 2;
S_obs_params = 3;
test_d_param = 4:6;

%Params(i) = j signifies that node i has a cpd defined at limid.CPD(i)
params = ones(1, N);
params(S_true) = S_true_params;
params(S_obs) = S_obs_params;
params(test_d) = test_d_param;
params(utility) = util_param;

%Make the influence diagram
limid = mk_limid(dag, ns, 'chance', [S_obs S_true], 'decision', test_d, 'utility', utility, 'equiv_class', params);

%Utility CPD
limid.CPD{util_param} = tabular_utility_node(limid, utility(1));

%Symptom CPDs
limid.CPD{S_true_params} = tabular_CPD(limid, S_true(1));
limid.CPD{S_obs_params} = tabular_CPD(limid, S_obs(1));

%Decision CPD
for i=1:3
  limid.CPD{test_d_param(i)} = tabular_decision_node(limid, test_d(i));
  %limid.CPD{treat_d_param(i)} = tabular_decision_node(limid, treat_d(i));
end

inf_engine = jtree_limid_inf_engine(limid);
max_iter = 1;

disp('Solving the current influence diagram');
[strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);

% % check results match those in the paper (p. 22)
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


% for e=approx(:)'
%   for i=1:3
%     approxeq(strategy{exact(1)}{d(i)}, strategy{e}{d(i)})
%     dispcpt(strategy{e}{d(i)})
%   end
% end
