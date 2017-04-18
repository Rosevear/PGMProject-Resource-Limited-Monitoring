%CMPUT 650: Probabilistic Graphical Models
%Course Project: Resource Limited Monitoring
%Cody Rosevear, Hayden Barker
%Department Of Computing Science
%University Of Alberta
%Edmonton, AB, T6G 2E8, Canada
%rosevear@ualberta.ca, hsbarker@ualberta.ca

ITERATE_DISEASE = 0;
ITERATE_UTILITY = 1;

%These are the disease/utility profiles used when one is held constant and
%the other is varied
FIXED_DISEASE = [0.95 0.80 0.75 0.04 0.15 0.10 0.01 0.05 0.10];
FIXED_UTILITY = [-35 -60 -85];

FIXED_DISEASE2 = [0.80 0.70 0.20 0.15 0.20 0.50 0.05 0.10 0.30];
FIXED_UTILITY2 = [-45 -70 -95];

DISEASE_PROFILES = [0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33 0.33; 0.95 0.80 0.75 0.04 0.15 0.10 0.01 0.05 0.10; 0.80 0.70 0.20 0.15 0.20 0.50 0.05 0.10 0.30; 0.20 0.10 0.05 0.60 0.40 0.30 0.20 0.50 0.65];
UTILITY_PROFILES = [-35 -60 -85; -45 -70 -95; -11 -12 -13; -30 -65 -90; -30 -65 -90; -35 -35 -35; -10 -10 -10];

if ITERATE_DISEASE == 1
    NUM_ITERATIONS = size(DISEASE_PROFILES, 1);
elseif ITERATE_UTILITY == 1
    NUM_ITERATIONS = size(UTILITY_PROFILES, 1);
else
    NUM_ITERATIONS = 1200;
end

SECOND_ISSUE_UTILITY_OFFSET = 5;
SECOND_ISSUE_RAND_SEED_OFFSET = 10;
N = 25;
max_expected_utilities = zeros(NUM_ITERATIONS, 1);
strategies = repmat(struct('strategy_matrix', []), 1, NUM_ITERATIONS);

for iteration = 1:NUM_ITERATIONS
    addpath(genpathKPM(pwd))
    disp('Constructing the influence diagram for iteration ' + string(iteration));

    %Number the nodes top to bottom then left to right
    S_true =   [1 5 9 13 17];
    S2_true =  [2 6 10 14 18];
    treat_d =  [3 7 11 15 19];
    utility =  [4 8 12 16 20 21 22 23 24 25];

    dag = zeros(N);

    %Construct the influence diagram's edges
    %The diagram is a static snapshot of 5 time slices
    for i=1:4
        %FIRST ISSUE NODES
        
       %The current true symptom influences the current uitility and the state of
       %the true symptom and the observed symptom at time t + 1
       dag(S_true(i), [utility(i) , S_true(i + 1)]) = 1;
       
       %SECOND ISSUE NODES
       %The current true symptom influences the current uitility and the state of
       %the true symptom and the observed symptom at time t + 1
       dag(S2_true(i), [utility(i + SECOND_ISSUE_UTILITY_OFFSET) , S2_true(i + 1)]) = 1;
     
       %We use a single set of treatment nodes to represent the baseline
       %(since we can only pick one per day given daily rlm limit of 1 we don't need 10)
       %We alternate between treating diseases, but have only 3 treatments
       %this time so we treat on the 1 3 5 days, alternating diseases still
       if mod(i, 2) == 1
           if i ~= 3
                dag(treat_d(i), [utility(i), S_true(i + 1)]) = 1;
           else
               dag(treat_d(i), [utility(i + SECOND_ISSUE_UTILITY_OFFSET), S_true(i + 1)]) = 1;
           end
       end
    end

    %Need to add the intra timeslice edges for the last timeslice
    dag(17, 20) = 1;
    dag(19, 20) = 1;
    
    %Need to do the same for the other issue
    dag(18, 25) = 1;

    %Set node sizes (number of values for each node)
    ns = ones(1, N);
    ns(S_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
    ns(treat_d) = 1; %1 = treat
    ns(S2_true) = 3;  %1 = Minor, 2 = Moderate,  3 = Severe
    ns(utility) = 1; %Utility for the current timeslice

    %Indices in the limid object CPD attribute that pick out the various cpds
    S_true_params = 1:5;
    treat_d_params = 6:10;
    
    %Second issue nodes
    S2_true_params = 11:15;
    
    util_params = 16:25;

    %Params(i) = j signifies that node i has a CPD defined at limid.CPD(i)
    params = ones(1, N);
    params(S_true) = S_true_params;
    params(treat_d) = treat_d_params;
    
    %Second issue nodes
    params(S2_true) = S2_true_params;
    
    params(utility) = util_params;

    %Make the influence diagram
    limid = mk_limid(dag, ns, 'chance', [S_true S2_true], 'decision', treat_d, 'utility', utility, 'equiv_class', params);

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
          %we use a randomly generated cpd
          limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i));
      else
          if ITERATE_DISEASE == 1
              limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i), DISEASE_PROFILES(iteration, :));
          else
              limid.CPD{S_true_params(i)} = tabular_CPD(limid, S_true(i), FIXED_DISEASE);
          end
      end
      
      %To ensure that the CPD's for the issues are never exactly the same
      seed = iteration + SECOND_ISSUE_RAND_SEED_OFFSET;
      rand('state', seed);
      randn('state', seed);
      
      %Chance nodes: issue 2
      if i == 1
          %First timeslice chance nodes have no parents, so their cpd is just a
          % vector of length equal to the number of possible values
          %we use a randomly generated cpd
          limid.CPD{S2_true_params(i)} = tabular_CPD(limid, S2_true(i));
      else
          if ITERATE_DISEASE == 1 && iteration < NUM_ITERATIONS
              limid.CPD{S2_true_params(i)} = tabular_CPD(limid, S2_true(i), DISEASE_PROFILES(iteration + 1, :));
          else
              limid.CPD{S2_true_params(i)} = tabular_CPD(limid, S2_true(i), FIXED_DISEASE2);
          end
      end
          
      %Decision nodes
      limid.CPD{treat_d_params(i)} = tabular_decision_node(limid, treat_d(i));

      %Utility nodes: Issue 1
      if ITERATE_UTILITY == 1
          limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i), UTILITY_PROFILES(iteration, :));
      else
          limid.CPD{util_params(i)} = tabular_utility_node(limid, utility(i), FIXED_UTILITY);
      end

      %Utility nodes: Issue 2
      if ITERATE_UTILITY == 1 && iteration < NUM_ITERATIONS
          limid.CPD{util_params(i + SECOND_ISSUE_UTILITY_OFFSET)} = tabular_utility_node(limid, utility(i + SECOND_ISSUE_UTILITY_OFFSET), UTILITY_PROFILES(iteration + 1, :));
      else
          limid.CPD{util_params(i + SECOND_ISSUE_UTILITY_OFFSET)} = tabular_utility_node(limid, utility(i + SECOND_ISSUE_UTILITY_OFFSET), FIXED_UTILITY2);
      end
    end

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
stat_summary_file = fopen('multiple_issue_network_stats_baseline.txt', 'W');
fprintf(stat_summary_file, 'Stat Summary File For Multiple Issue Network\n');
fprintf(stat_summary_file, 'Min: Max Expected Utility: ' + string(min_utility) + '\n');
fprintf(stat_summary_file, 'Max: Max Expected Utility: ' + string(max_utility) + '\n');
fprintf(stat_summary_file, 'Range: Max Expected Utility: ' + string(range) + '\n');
fprintf(stat_summary_file, 'Mean: Max Expected Utility: ' + string(mean_utility) + '\n');
fprintf(stat_summary_file, 'Standard Deviation: Max Expected Utility: ' + string(standard_deviation) + '\n');
fprintf(stat_summary_file, 'Mean: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
fprintf(stat_summary_file, 'Standard Deviation: Strategy Similarity: ' + string(mean_strategy_similarity) + '\n');
fclose(stat_summary_file);