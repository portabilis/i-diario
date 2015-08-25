class KnowledgeArea < ActiveRecord::Base
  acts_as_copy_target

  has_many :disciplines, dependent: :destroy

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  def to_s
    description
  end
end
