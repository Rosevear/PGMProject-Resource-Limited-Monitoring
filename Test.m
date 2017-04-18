%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca

NUM_ITERATIONS = 1200;
SECOND_ISSUE_UTILITY_OFFSET = 5;
SECOND_ISSUE_RAND_SEED_OFFSET = 10;
N = 55;
max_expected_utilities = zeros(NUM_ITERATIONS, 1);
strategies = repmat(struct('strategy_matrix', []), 1, NUM_ITERATIONS);

for iteration = 1:NUM_ITERATIONS
    addpath(genpathKPM(pwd))
    disp('Constructing the influence diagram for iteration ' + string(iteration));

    %Number the nodes top to bottom then left to right
%     S_true =      [1 13 25 37 49];
%     S_obs =       [2 14 26 38 50];
%     S2_true =     [3 15 27 39 51];
%     S2_obs =      [4 16 28 40 52];
%     test_d =      [5 17 29 41 53];
%     treat_d =     [6 18 30 42 54];
%     test2_d =     [7 19 31 43 55];
%     treat2_d =    [8 20 32 44 56];
%     d_count =     [9 21 33 45 57];
    %d_count2 =    [10 22 34 46 58];
    %d_count_sum = [11 23 35 47 59];
    %utility =     [12 24 36 48 60 61 62 63 64 65];
    
    S_true =      [1 11 21 31 41];
    S_obs =       [2 12 22 32 42];
    S2_true =     [3 13 23 33 43];
    S2_obs =      [4 14 24 34 44];
    test_d =      [5 15 25 35 45];
    treat_d =     [6 16 26 36 46];
    test2_d =     [7 17 27 37 47];
    treat2_d =    [8 18 28 38 48];
    d_count =     [9 19 29 39 49];
    utility =     [10 20 30 40 50 51 52 53 54 55];

    dag = zeros(N);

    %Construct the influence diagram's edges
    %The diagram is a static snapshot of 5 time slices
    for i=1:5
        %FIRST ISSUE NODES
        if i < 5

           %The current true symptom influences the current uitility and the state of
           %the true symptom and the observed symptom at time t + 1
           dag(S_true(i), [utility(i) , S_true(i + 1), S_obs(i + 1)]) = 1;
           
           %The current test decision influences the current utility and
           %the current decision count
           %and the state of the observed symptoms at time t + 1
           dag(test_d(i), [utility(i), d_count(i), S_obs(i + 1)]) = 1;

           %The current treatment decision influences the current utility and the
           %the true state and the observed state of the symptom at time t + 1
           dag(treat_d(i), [utility(i), d_count(i), S_true(i + 1)]) = 1;
        else
            
           %The current true symptom influences the current uitility
           dag(S_true(i), utility(i)) = 1;

           %The current test decision influences the current utility
           %and the decision count
           dag(test_d(i), [utility(i), d_count(i)]) = 1;

           %The current treatment decision influences the current utility
           %and the current timeslice count
           dag(treat_d(i), [utility(i), d_count(i)]) = 1;
        end
        
        %The current observed symptom influences the current test and treatment
        %decision nodes
        dag(S_obs(i), [test_d(i), treat_d(i)]) = 1;
        
        %The current decision count for this issue influences the total
        %decision count for this timeslice
        %dag(d_count(i), d_count_sum(i)) = 1;
        
        %SECOND ISSUE NODES
        if i < 5
           %The current true symptom influences the current uitility and the state of
           %the true symptom and the observed symptom at time t + 1
           dag(S2_true(i), [utility(i + SECOND_ISSUE_UTILITY_OFFSET), S2_true(i + 1), S2_obs(i + 1)]) = 1;

           %The current observed symptom influences the current test and treatment
           %decision nodes
           dag(S2_obs(i), [test2_d(i), treat2_d(i)]) = 1;

           %The current test decision influences the current utility
           %and the state of the observed symptoms at time t + 1
           dag(test2_d(i), [utility(i + SECOND_ISSUE_UTILITY_OFFSET), S2_obs(i + 1)]) = 1;

           %The current treatment decision influences the current utility and the
           %the true state and the observed state of the symptom at time t + 1
           dag(treat2_d(i), [utility(i + SECOND_ISSUE_UTILITY_OFFSET), S2_true(i + 1)]) = 1;
        else
           %The current true symptom influences the current uitility
           dag(S2_true(i), utility(i + SECOND_ISSUE_UTILITY_OFFSET)) = 1;

           %The current test decision influences the current utility
           dag(test2_d(i), utility(i + SECOND_ISSUE_UTILITY_OFFSET)) = 1;

           %The current treatment decision influences the current utility
           dag(treat2_d(i), utility(i + SECOND_ISSUE_UTILITY_OFFSET)) = 1;
        end
       
        %The current observed symptom influences the current test and treatment
        %decision nodes
        dag(S_obs(i), [test_d(i), treat_d(i)]) = 1;
        dag(S2_obs(i), [test2_d(i), treat2_d(i)]) = 1;
        
        %The current decision count for this issue influences the total
        %decision count for this timeslice
        %dag(d_count2(i), d_count_sum(i)) = 1;
    end

    %Set node sizes (number of values for each node)
    ns = ones(1, N);
    ns(S_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
    ns(S_obs) = 4;   %1 = Minor, 2 = Moderate, 3 = Severe, 4 = Unobserved
    ns(test_d) = 2;  %1 = don't test, 2 = test
    ns(treat_d) = 2; %1 = don't treat, 2 = treat
    ns(d_count) = 4; %Count of how many actions performed so far
    
    ns(S2_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
    ns(S2_obs) = 4;   %1 = Minor, 2 = Moderate, 3 = Severe, 4 = Unobserved
    ns(test2_d) = 2;  %1 = don't test, 2 = test
    ns(treat2_d) = 2; %1 = don't treat, 2 = treat
    %ns(d_count2) = 4; %Count of how many actions performed so far
    
    %ns(d_count_sum) = 4; %Count of total actions for both issues
    ns(utility) = 1; %Utility for the current timeslice

    %Indices in the limid object CPD attribute that pick out the various cpds
    S_true_params = 1:5;
    S_obs_params = 6:10;
    test_d_params = 11:15;
    treat_d_params = 16:20;
    d_count_params = 21:25;
    
    %Second issue nodes
    S2_true_params = 26:30;
    S2_obs_params = 31:35;
    test2_d_params = 36:40;
    treat2_d_params = 41:45;
    %d_count2_params = 46:50;
    
    %d_count_sum_params = 51:55;
    util_params = 46:55;

    %Params(i) = j signifies that node i has a CPD defined at limid.CPD(i)
    params = ones(1, N);
    params(S_true) = S_true_params;
    params(S_obs) = S_obs_params;
    params(test_d) = test_d_params;
    params(treat_d) = treat_d_params;
    params(d_count) = d_count_params;
    
    %Second issue nodes
    params(S2_true) = S2_true_params;
    params(S2_obs) = S2_obs_params;
    params(test2_d) = test2_d_params;
    params(treat2_d) = treat2_d_params;
    %params(d_count2) = d_count2_params;
    
    %params(d_count_sum) = d_count_sum_params;
    params(utility) = util_params;
    
    %Make the influence diagram
    limid = mk_limid(dag, ns, 'chance', [S_obs S_true S2_obs S2_true d_count], 'decision', [test_d treat_d test2_d treat2_d], 'utility', utility, 'equiv_class', params);

    %Search the parameter space of the CPD's
    for i=1:5
      %CPD rows are indexed according to the order of their nodes (so children)
      %are always last

      seed = iteration;
      rand('state', seed);
      randn('state', seed);
      
       %Chance nodes
      if i == 1
          %First timeslice chance nodes have no parents, so their cpd is just a
          % vector of length equal to the number of possible values
          limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
          limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
      else
          limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
          limid.CPD{S_obs_params(i)} = tabular_CPD(limid, S_obs(i));
      end
      
      %Count nodes
      limid.CPD{d_count_params(i)} = tabular_CPD(limid, d_count(i));
      %limid.CPD{d_count2_params(i)} = tabular_CPD(limid, d_count2(i));
      %limid.CPD{d_count_sum(i)} = tabular_CPD(limid, d_count_sum(i));
      
      %To ensure that the CPD's for the issues are never exactly the same
      seed = iteration + SECOND_ISSUE_RAND_SEED_OFFSET;
      rand('state', seed);
      randn('state', seed);
      
      limid.CPD{S2_true_params(i)} = tabular_CPD(limid, S2_true(i));
      limid.CPD{S2_obs_params(i)} = tabular_CPD(limid, S2_obs(i));
          
      %Decision nodes
      limid.CPD{test_d_params(i)} = tabular_decision_node(limid, test_d(i));
      limid.CPD{test2_d_params(i)} = tabular_decision_node(limid, test2_d(i));
      limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i));
      limid.CPD{treat2_d_params(i)} = tabular_decision_node(limid, treat2_d(i));

      %Utility nodes
      limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i));
      limid.CPD{util_params(i + SECOND_ISSUE_UTILITY_OFFSET)} = tabular_utility_node(limid, utility(i + SECOND_ISSUE_UTILITY_OFFSET));
    end

    inf_engine = jtree_limid_inf_engine(limid);
    max_iter = 1;

    disp('Solving the influence diagram for iteration ' + string(iteration));
    [strategy, MEU, niter] = solve_limid(inf_engine, 'max_iter', max_iter);
    max_expected_utilities(iteration) = MEU;
    MEU
    
    %Extract the decision nodes from the strategy array and convert it into
    %a matrix (from a cell array)
    %cur_strategy = cell2mat(strategy(~cellfun(@isempty, strategy)));
    %strategies(iteration).strategy_matrix = cur_strategy;
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
stat_summary_file = fopen('rlm_multiple_issue_network_stats.txt', 'W');
fprintf(stat_summary_file, 'Stat Summary File For Multiple Issue Network\n');
fprintf(stat_summary_file, 'Min: Max Expected Utility: ' + string(min_utility) + '\n');
fprintf(stat_summary_file, 'Max: Max Expected Utility: ' + string(max_utility) + '\n');
fprintf(stat_summary_file, 'Range: Max Expected Utility: ' + string(range) + '\n');
fprintf(stat_summary_file, 'Mean: Max Expected Utility: ' + string(mean_utility) + '\n');
fprintf(stat_summary_file, 'Standard Deviation: Max Expected Utility: ' + string(standard_deviation) + '\n');
%fprintf(stat_summary_file, 'Mean: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
%fprintf(stat_summary_file, 'Standard Deviation: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
fclose(stat_summary_file);