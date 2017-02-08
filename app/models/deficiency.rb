class Deficiency < ActiveRecord::Base
  audited

  include Audit

  validates :name, presence: true

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
