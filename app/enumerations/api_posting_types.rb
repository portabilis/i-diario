class ApiPostingTypes < EnumerateIt::Base
  associate_values :absence,
    :conceptual_exam,
    :descriptive_exam,
    :numerical_exam,
    :final_recovery,
    :school_term_recovery

  sort_by :none
end
