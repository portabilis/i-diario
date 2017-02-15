class EventCoverageType < EnumerateIt::Base
  associate_values :by_unity, :by_course, :by_grade, :by_classroom

  sort_by :none
end
