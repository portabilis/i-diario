class Deficiency < ActiveRecord::Base
  include Discard::Model

  audited

  include Audit

  validates :name, presence: true

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
