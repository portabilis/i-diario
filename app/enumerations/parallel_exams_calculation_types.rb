class ParallelExamsCalculationTypes < EnumerateIt::Base
  associate_values substitution: 1,
                   average: 2,
                   sum: 3

  sort_by :none
end
