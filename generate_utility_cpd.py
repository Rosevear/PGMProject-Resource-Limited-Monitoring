import itertools
decision_combinations = list(itertools.product([0, 1], repeat = 10))

pseudo_cpd = [ for combination in decision_combinations]
