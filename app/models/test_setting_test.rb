class TestSettingTest < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :test_setting, except: :test_setting_id

  belongs_to :test_setting

  has_many :avaliations, dependent: :restrict_with_error

  has_enumeration_for :test_type, with: TestTypes

  validates :description, :weight, :test_type, presence: true
  validates :weight, numericality: true

  def to_s
    description
  end
end
