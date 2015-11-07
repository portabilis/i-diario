class DailyNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :avaliation

  has_many :students, -> { includes(:student).order('students.name') }, class_name: 'DailyNoteStudent', dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, presence: true
  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :avaliation, presence: true

  validate :avaliation_date_must_be_less_than_or_equal_to_today

  scope :by_unity_classroom_discipline_and_avaliation_test_date_between,
        lambda { |unity_id, classroom_id, discipline_id, start_at, end_at| where(unity_id: unity_id,
                                                                                 classroom_id: classroom_id,
                                                                                 discipline_id: discipline_id,
                                                                                 'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                                                    .where.not(students: { id: nil })
                                                                                    .includes(:avaliation, students: :student) }

  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_test_date_between, lambda { |start_at, end_at| includes(:avaliation, students: :student).where('avaliations.test_date': start_at.to_date..end_at.to_date) }

  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_avaliation_test_date, -> { order('avaliations.test_date') }

  private

  def avaliation_date_must_be_less_than_or_equal_to_today
    return unless avaliation

    if avaliation.test_date > Date.today
      errors.add(:avaliation, :must_be_less_than_or_equal_to_today)
    end
  end
end
