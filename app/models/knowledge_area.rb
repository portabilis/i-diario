class KnowledgeArea < ActiveRecord::Base
  acts_as_copy_target

  has_many :disciplines, dependent: :destroy

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :by_discipline_id, lambda { |discipline_id| joins(:disciplines).where(disciplines: { id: discipline_id }) }

  def to_s
    description
  end
end
