class Student < Portabilis::Model
  validates :name, presence: true
  validates :api_code, presence: true, if: :api?

  def to_s
    name
  end
end
