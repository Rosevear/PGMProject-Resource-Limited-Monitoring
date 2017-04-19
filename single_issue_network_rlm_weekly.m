%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca

ITERATE_DISEASE = 1;
ITERATE_UTILITY = 0;

%These are the disease/utility profiles used when one is held constant and
%the other is varied
FIXED_DISEASE = [0.85 0.75 0.65 0.95 0.80 0.75 0.10 0.15 0.20 0.04 0.15 0.10 0.05 0.10 0.15 0.01 0.05 0.10];
FIXED_UTILITY = [-25 -50 -75 -30 -55 -80 -35 -60 -85 -1000 -1000 -1000];

DISEASE_PROFILES = [0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33; 0.85 0.75 0.65 0.95 0.80 0.75 0.10 0.15 0.20 0.04 0.15 0.10 0.05 0.10 0.15 0.01 0.05 0.10; 0.40 0.10 0.05 0.80 0.70 0.20 0.50 0.40 0.15 0.15 0.20 0.50 0.10 0.60 0.80 0.05 0.10 0.30; 0.10 0.05 0.01 0.20 0.10 0.05 0.50 0.25 0.04 0.60 0.40 0.30 0.40 0.70 0.95 0.20 0.50 0.65];
UTILITY_PROFILES = [-25 -50 -75 -30 -55 -80 -35 -60 -85 -1000 -1000 -1000; -35 -60 -85 -30 -65 -90 -45 -70 -95 -1000 -1000 -1000; -1 -2 -3 -6 -7 -8 -11 -12 -13 -1000 -1000 -1000; -35 -60 -85 -45 -70 -95 -30 -65 -90 -1000 -1000 -1000; -25 -25 -25 -30 -30 -30 -35 -35 -35 -1000 -1000 -1000; -10 -10 -10 -10 -10 -10 -10 -10 -10 -1000 -1000 -1000];

if ITERATE_DISEASE == 1
    RUN_TYPE = 'disease';
    NUM_ITERATIONS = size(DISEASE_PROFILES, 1);
elseif ITERATE_UTILITY == 1
    RUN_TYPE = 'utility';
    NUM_ITERATIONS = size(UTILITY_PROFILES, 1);
else
    NUM_ITERATIONS = 1200;
end

for iteration = 1:NUM_ITERATIONS
    seed = iteration;
    rand('state', seed);
    randn('state', seed);

    addpath(genpathKPM(pwd))
    disp('Constructing the influence diagram for iteration ' + string(iteration));

    %Number the nodes top to bottom then left to right
    S_true = [1 6 11 16 21];
    S_obs = [2 7 12 17 22];
    test_d = [3 8 13 18 23];
    treat_d = [4 9 14 19 24];
    utility = [5 10 15 20 25];
    rlm_utility = 26;

    N = 26;
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
    dag(22, [23 24]) = 1;
    dag(23, 25) = 1;
    dag(24, 25) = 1;
    
    %Hook up all of the decsion nodes to the rlm_utility node
    for i = 1:5
        dag(test_d(i), 26) = 1;
        dag(treat_d(i), 26) = 1;
    end

    %Set node sizes (number of values for each node)
    ns = ones(1, N);
    ns(S_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
    ns(S_obs) = 4;   %1 = Minor, 2 = Moderate, 3 = Severe, 4 = Unobserved
    ns(test_d) = 2;  %1 = don't test, 2 = test
    ns(treat_d) = 2; %1 = don't treat, 2 = treat
    ns(utility) = 1; %Utility for the current timeslice
    ns(rlm_utility) = 1;

    %Indices in the limid object CPD attribute that pick out the various cpds
    S_true_params = 1:5;
    S_obs_params = 6:10;
    test_d_params = 11:15;
    treat_d_params = 16:20;
    util_params = 21:25;
    rlm_utility_params = 26;

    %Params(i) = j signifies that node i has a CPD defined at limid.CPD(i)
    params = ones(1, N);
    params(S_true) = S_true_params;
    params(S_obs) = S_obs_params;
    params(test_d) = test_d_params;
    params(treat_d) = treat_d_params;
    params(utility) = util_params;
    params(rlm_utiliy) = rlm_utility_params;

    %Make the influence diagram
    limid = mk_limid(dag, ns, 'chance', [S_obs S_true], 'decision', [test_d treat_d], 'utility', [utility rlm_utility], 'equiv_class', params);

    %Search the parameter space of the CPD's
    for i=1:5
      %CPD rows are indexed according to the order of their nodes (so children)
      %are always last

       %Chance nodes
      if i == 1
          %First timeslice chance nodes have no parents, so their cpd is just a
          % vector of length equal to the number of possible values
          %we use a randomly generated cpd
          limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
          limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
      else
          if ITERATE_DISEASE == 1
              limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i), DISEASE_PROFILES(iteration, :));
          else
              limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i), FIXED_DISEASE);
          end
      end
      limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
      

      %Decision nodes
      limid.CPD{test_d_params(i)} = tabular_decision_node(limid, test_d(i));
      limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i));

       %Utility nodes
      if ITERATE_UTILITY == 1
          limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i), UTILITY_PROFILES(iteration, :));
      else
          limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i), FIXED_UTILITY);
      end
    end
    
    %TODO: Add weekly rlm
    limid.CPD{rlm_utility_params} = tabular_utility_node(limid, 26);

    inf_engine = jtree_limid_inf_engine(limid);
    max_iter = 1;

    disp('Solving the influence diagram for iteration ' + string(iteration));
    [strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);
    max_expected_utilities(iteration) = MEU;
    MEU
    
    %Extract the decision nodes from the strategy array and convert it into
    %a matrix (from a cell array)
    cur_strategy = cell2mat(strategy(~cellfun(@isempty, strategy)));
    strategies(iteration).strategy_matrix = cur_strategy;
end

%Compile some statistics regarding utility
min_utility = min(max_expected_utilities);
max_utility = max(max_expected_utilities);
range = max_utility - min_utility;
mean_utility = mean(max_expected_utilities);
standard_deviation = std(max_expected_utilities);

%Measure the degree of variation across strategies for different
%parametrizations of the network
strategy_pairs = nchoosek(1:NUM_ITERATIONS, 2);
num_pairs = length(strategy_pairs);
strategy_similarities = zeros(1, num_pairs);
for i = 1:num_pairs
    cur_pairs = strategy_pairs(i, :);
    strat1_index = cur_pairs(1); 
    strat2_index = cur_pairs(2);
    strat1 = strategies(strat1_index).strategy_matrix;
    strat2 = strategies(strat2_index).strategy_matrix;
    %TODO: Look into other metrics mayhaps
    strategy_similarities(i) = 100 * numel(find(strat1 == strat2)) / numel(strat1);
end

mean_strategy_similarity = mean(strategy_similarities);
strategy_similarity_standard_deviation = std(strategy_similarities);


%Write them to a file for safekeeping
stat_summary_file = fopen('single_issue_network_' + string(RUN_TYPE) + '_rlm_weekly_stats.txt', 'W');
fprintf(stat_summary_file, 'Min: Max Expected Utility: ' + string(min_utility) + '\n');
fprintf(stat_summary_file, 'Max: Max Expected Utility: ' + string(max_utility) + '\n');
fprintf(stat_summary_file, 'Range: Max Expected Utility: ' + string(range) + '\n');
fprintf(stat_summary_file, 'Mean: Max Expected Utility: ' + string(mean_utility) + '\n');
fprintf(stat_summary_file, 'Standard Deviation: Max Expected Utility: ' + string(standard_deviation) + '\n');
fprintf(stat_summary_file, 'Mean: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
fprintf(stat_summary_file, 'Standard Deviation: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
fclose(stat_summary_file);