class Deficiency < ActiveRecord::Base
  audited

  include Audit

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true

  def to_s
    name
  end
end
