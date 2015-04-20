class Teacher < ActiveRecord::Base
  acts_as_copy_target

  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true

  def to_s
    name
  end
end
