class DescriptiveExamStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :descriptive_exam, except: [:descriptive_exam_id, :dependence]

  belongs_to :descriptive_exam
  belongs_to :student

  scope :by_classroom_and_step,
        lambda { |classroom_id, step_id| where('descriptive_exams.classroom_id' => classroom_id,
                                               'descriptive_exams.school_calendar_step_id' => step_id)
                                        .includes(:descriptive_exam) }

  scope :by_classroom_and_classroom_step,
        lambda { |classroom_id, classroom_step_id| where('descriptive_exams.classroom_id' => classroom_id,
                                                          'descriptive_exams.school_calendar_classroom_step_id' => classroom_step_id)
                                                  .includes(:descriptive_exam)}

  scope :by_classroom,
        lambda { |classroom_id| where('descriptive_exams.classroom_id' => classroom_id)
                                .includes(:descriptive_exam) }
  scope :by_classroom_and_discipline,
        lambda { |classroom_id, discipline_id| where('descriptive_exams.classroom_id' => classroom_id,
                                                     'descriptive_exams.discipline_id' => discipline_id)
                                .includes(:descriptive_exam) }

  scope :by_classroom_discipline_and_step,
        lambda { |classroom_id, discipline_id, step_id| where('descriptive_exams.classroom_id' => classroom_id,
                                                     'descriptive_exams.discipline_id' => discipline_id,
                                                     'descriptive_exams.school_calendar_step_id' => step_id)
                                .includes(:descriptive_exam) }

  scope :by_classroom_discipline_and_classroom_step,
        lambda { |classroom_id, discipline_id, classroom_step_id| where('descriptive_exams.classroom_id' => classroom_id,
                                                              'descriptive_exams.discipline_id' => discipline_id,
                                                              'descriptive_exams.school_calendar_classroom_step_id' => classroom_step_id)
                                                        .includes(:descriptive_exam) }

  validates :descriptive_exam, :student, presence: true
end
