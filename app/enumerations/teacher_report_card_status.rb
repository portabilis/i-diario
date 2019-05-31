class TeacherReportCardStatus < EnumerateIt::Base
  associate_values all: 0,
    approved: 1,
    disapproved: 2,
    studying: 3,
    transferred: 4,
    reclassified: 5,
    abandonment: 6,
    under_exam: 7,
    approved_with_exam: 8,
    approved_without_exam: 10

  sort_by :none
end