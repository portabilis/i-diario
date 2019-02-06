class IeducarErrorMessages < EnumerateIt::Base
  associate_values must_have_scores_on_previous_steps: 1000,
                   teacher_must_have_scores_on_previous_steps: 1001,
                   coordinator_must_have_scores_on_previous_steps: 1002,
                   score_higher_than_allowed: 1003,
                   score_lower_than_allowed: 1004,
                   exam_score_higher_than_allowed: 1005
end
