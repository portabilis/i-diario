class Deficiency < ActiveRecord::Base
  include Discardable

  audited

  include Audit

  validates :name, presence: true

  default_scope -> { kept }

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
