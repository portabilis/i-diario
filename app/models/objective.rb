class Objective < ApplicationRecord
  audited
  has_associated_audits

  has_many :teaching_plans, dependent: :restrict_with_error

  validates :description, presence: true

  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :find_and_order_by_id_sequence, lambda { |ids|
    joins("join unnest('{#{ids.join(',')}}'::int[]) WITH ORDINALITY t(id, ord) USING (id)").order('t.ord')
  }

  attr_accessor :is_editable

  def to_s
    description
  end
end
