class RoundedAvaliations < EnumerateIt::Base
  associate_values :numerical_exam,
                   :school_term_recovery,
                   :final_recovery
end
