class Deficiency < ActiveRecord::Base
  audited

  include Audit

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
