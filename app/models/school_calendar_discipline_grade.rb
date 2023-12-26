class SchoolCalendarDisciplineGrade < ApplicationRecord
  belongs_to :school_calendar
  belongs_to :discipline
  belongs_to :grade
end
