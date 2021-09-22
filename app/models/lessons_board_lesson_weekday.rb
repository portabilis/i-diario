class LessonsBoardLessonWeekday < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :teacher_discipline_classroom
  belongs_to :lessons_board_lesson

  default_scope -> { kept }

  scope :by_classroom, ->(classroom_id) { joins(:teacher_discipline_classroom)
                                          .where(teacher_discipline_classrooms: { classroom_id: classroom_id }) }

  scope :by_teacher, ->(teacher_id) { joins(:teacher_discipline_classroom)
                                      .where(teacher_discipline_classrooms: { teacher_id: teacher_id }) }
  scope :by_teacher_discipline_classroom, ->(teacher_discipline_classroom_id) { where(teacher_discipline_classroom_id:
                                                                                      teacher_discipline_classroom_id) }
  scope :by_discipline, ->(discipline_id) { joins(teacher_discipline_classroom: [:discipline])
                                            .where(disciplines: { id: discipline_id }) }
  scope :by_weekday, ->(weekday) { where(weekday:  weekday) }

  scope :by_period, ->(period) { joins(lessons_board_lesson: [:lessons_board])
                                 .where(lessons_boards: { period: period }) }
end
