class Teacher < ActiveRecord::Base
  acts_as_copy_target

  has_many :users
  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def to_s
    name
  end
end
