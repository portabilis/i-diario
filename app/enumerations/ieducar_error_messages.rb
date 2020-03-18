class IeducarErrorMessages < EnumerateIt::Base
  associate_values must_have_scores_on_previous_steps: 1000,
                   teacher_must_have_scores_on_previous_steps: 1001,
                   coordinator_must_have_scores_on_previous_steps: 1002,
                   score_higher_than_allowed: 1003,
                   score_lower_than_allowed: 1004,
                   exam_score_higher_than_allowed: 1005,
                   student_not_enrolled_in_classroom: 1006,
                   exam_rule_not_defined_for_grade: 1007,
                   exam_rule_dont_allow_general_absence: 1008,
                   discipline_dont_enrolled_in_school_levels: 1009,
                   discipline_not_exists_for_school_class: 1010,
                   school_class_doesnt_alow_frequency_by_discipline: 1011
end
