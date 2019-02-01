class RoundingTableValue < ActiveRecord::Base
  acts_as_copy_target

  audited

  belongs_to :rounding_table

  has_enumeration_for :action, with: RoundingTableAction

  validates :label, :rounding_table_api_code, presence: true

  scope :ordered, -> { order(arel_table[:value].desc) }

  def to_s
    if description.present?
      "#{description} (#{label})"
    else
      label
    end
  end
end
