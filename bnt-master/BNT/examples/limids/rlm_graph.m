%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca

seed = 0;
rand('state', seed);
randn('state', seed);

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
   
   %The current test decision influences the current utility
   %and the state of the observed symptoms at time t + 1
   dag(test_d(i), [utility(i), S_obs(i + 1)]) = 1;
   
   %The current treatment decision influences the current utility and the
   %the true state and the observed state of the symptom at time t + 1
   dag(treat_d(i), [utility(i), S_true(i + 1)]) = 1;
end

%Need to add the intra timeslice edges for the last timeslice
dag(21, 25) = 1;
dag(22, 23) = 1;
dag(23, [24 25]) = 1;
dag(24, 25) = 1;

%Set node sizes (number of values for each node)
ns = ones(1, N);
ns(S_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
ns(S_obs) = 4;   %1 = Minor, 2 = Moderate, 3 = Severe, 4 = Unobserved
ns(test_d) = 2;  %1 = don't test, 2 = test
ns(treat_d) = 2; %1 = don't treat, 2 = treat
ns(utility) = 1; %Utility for the current timeslice

%Indices in the limid object CPD attribute that pick out the various cpds
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
limid = mk_limid(dag, ns, 'chance', [S_obs S_true], 'decision', [test_d treat_d], 'utility', utility, 'equiv_class', params);

%TODO: Start the parameter sweep here
%Fill in the node CPD's
for i=1:5
  %CPD rows are indexed according to the order of their nodes (so children)
  %are always last
  
  %Chance nodes
  if i == 1
      %First timeslice chance nodes have no parents, so their cpd is just a
      % vector of length equal to the number of possible values
      limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
      limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
  else
      %S_true(t - 1) treat_d(t - 1) S_true(t)
      %1             1              1
      %2             1              1
      %3             1              1
      %1             2              1
      %2             2              1
      %3             2              1
      %1             1              2
      %2             1              2
      %3             1              2
      %1             2              2
      %2             2              2
      %3             2              2
      %1             1              3
      %2             1              3
      %3             1              3
      %1             2              3
      %2             2              3
      %3             2              3
      limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
      %S_true(t - 1) test_d(t - 1) S_obs(t)
      %1             1              1
      %2             1              1
      %3             1              1
      %1             2              1
      %2             2              1
      %3             2              1
      %1             1              2
      %2             1              2
      %3             1              2
      %1             2              2
      %2             2              2
      %3             2              2
      %1             1              3
      %2             1              3
      %3             1              3
      %1             2              3
      %2             2              3
      %3             2              3
      %1             1              4
      %2             1              4
      %3             1              4
      %1             2              4
      %2             2              4
      %3             2              4
      limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
  end
  
  %Decision nodes
  %S_obs test_d
  %1     1
  %2     1
  %3     1
  %4     1
  %1     2
  %2     2
  %3     2
  %4     2
  limid.CPD{test_d_params(i)} = tabular_decision_node(limid, test_d(i));
  
  %S_obs treat_d
  %1     1
  %2     1
  %3     1
  %4     1
  %1     2
  %2     2
  %3     2
  %4     2
  limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i));
  
  %Utility nodes
  %S_true  %test_d %treat_d %utility
  %1       1       1
  %2       1       1
  %3       1       1
  %1       2       1
  %2       2       1
  %3       2       1
  %1       1       2
  %2       1       2
  %3       1       2
  %1       2       2
  %2       2       2
  %3       2       2
  limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i), [1 2 3 4 5 6 7 8 9 10 11 12]);
end

inf_engine = jtree_limid_inf_engine(limid);
max_iter = 1;

disp('Solving the current influence diagram');
[strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);
MEU

%Baseline Policy
% disp('Set up the Baseline strategy for the network and re-solve for the utility');
% limid.CPD{test_d_params(i)} = tabular_decision_node(limid, test_d(i), [1 2 1 2 1 2 1 2]);
% limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i), [1 1 1 1]);
% 
% disp('Solving the influence diagram: Baseline strategy');
% inf_engine = jtree_limid_inf_engine(limid);
% max_iter = 1;
% 
% [strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);
% MEU