class StudentEnrollmentStatus < EnumerateIt::Base
  associate_values approved: 1,
                   repproved: 2,
                   studying: 3,
                   transferred: 4,
                   reclassified: 5,
                   abandonment: 6,
                   excepted_transferred_or_abandonment: 9,
                   all: 10,
                   approved_with_dependency: 12,
                   approve_by_council: 13,
                   disapproved_by_faults: 14,
                   deceased: 15

  sort_by :none
end
