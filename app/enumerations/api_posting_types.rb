class ApiPostingTypes < EnumerateIt::Base
  associate_values :absences,
    :conceptual_exams,
    :descriptive_exams,
    :numerical_exams,
    :final_recoveries

  sort_by :none
end
