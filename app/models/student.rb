class Student < Portabilis::Model
  has_and_belongs_to_many :users

  validates :name, presence: true
  validates :api_code, presence: true, if: :api?

  def to_s
    name
  end
end
