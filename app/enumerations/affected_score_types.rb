class AffectedScoreTypes < EnumerateIt::Base
  associate_values :step_average,
                   :step_recovery_score,
                   :both
end
