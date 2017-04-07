%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca

addpath(genpathKPM(pwd))
disp('Constructing the influence diagram');

%Number the nodes top to bottom then left to right
S_true = [1 6 11 16 21];
S_obs = [2 7 12 17 22];
test_d = [3 8 13 18 23];
treat_d = [4 9 14 19 24];
utility = [5 10 15 20 25];

N = 25;
dag = zeros(N);

%Construct the influence diagram's edges
%The diagram is a static snapshot of 5 time slices
for i=1:4
   %The current true symptom influences the current uitility and the state of
   %the true symptom and the observed symptom at time t + 1
   dag(S_true(i), [utility(i) , S_true(i + 1), S_obs(i + 1)]) = 1;
   
   %The current observed symptom influences the current test and treatment
   %decision nodes
   dag(S_obs(i), [test_d(i), treat_d(i)]) = 1;
   
   %The current test decision influences the current treatment and utility
   %and the state of the observed symptoms at time t + 1
   dag(test_d(i), [treat_d(i), utility(i), S_obs(i + 1)]) = 1;
   
   %The current treatment decision influences the current utility and the
   %the true state and the observed state of the symptom at time t + 1
   dag(treat_d(i), [utility(i), S_obs(i + 1), S_true(i + 1)]) = 1;
end

%Need to add the edges for the last timeslice
dag(21, 25) = 1;
dag(22, 23) = 1;
dag(23, [24 25]) = 1;
dag(24, 25) = 1;

%Set node sizes (number of values for each node)
ns = 2 * ones(1, N);
ns(utility) = 1;

%Indices in the limid CPD attribute that pick out the various cpds
S_true_params = 1:5;
S_obs_params = 6:10;
test_d_params = 11:15;
treat_d_params = 16:20;
util_params = 21:25;

%Params(i) = j signifies that node i has a CPD defined at limid.CPD(i)
params = ones(1, N);
params(S_true) = S_true_params;
params(S_obs) = S_obs_params;
params(test_d) = test_d_params;
params(treat_d) = treat_d_params;
params(utility) = util_params;

%Make the influence diagram
limid = mk_limid(dag, ns, 'chance', [S_obs S_true], 'decision', [test_d treat_d], 'utility', utility, 'equiv_class', params, 'discrete', discrete_nodes);

%Fill in the node CPD's
for i=1:5
  
  %Chance
  limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
  limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
  
  %Decision
  limid.CPD{test_d_params(i)} = tabular_decision_node(limid, test_d(i));
  limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i));
  
  %Utility
  limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i));
end

inf_engine = jtree_limid_inf_engine(limid);
max_iter = 1;

disp('Solving the current influence diagram');
[strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);
MEU