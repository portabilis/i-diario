class CustomRoundingTableValue < ActiveRecord::Base
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  belongs_to :custom_rounding_table

  has_enumeration_for :action, with: RoundingTableAction

  validates :label, :action, presence: true
  validates_presence_of :exact_decimal_place, if: :action_exact_decimal_place

  scope :ordered, -> { order(arel_table[:label].desc) }

  def to_s
    label
  end

  def action_exact_decimal_place
    (action == RoundingTableAction::SPECIFIC)
  end
end
