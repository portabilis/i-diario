class CalculationTypes < EnumerateIt::Base
  associate_values :substitution,
                   :sum,
                   :substitution_if_greater,
                   :integral
end
