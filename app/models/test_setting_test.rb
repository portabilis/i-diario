class TestSettingTest < ApplicationRecord
  acts_as_copy_target

  audited associated_with: :test_setting, except: :test_setting_id

  belongs_to :test_setting

  has_many :avaliations, dependent: :restrict_with_error

  validates :description, presence: true
  validates :weight, presence: true

  def to_s
    description
  end
end
