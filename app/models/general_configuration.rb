class GeneralConfiguration < ActiveRecord::Base
  has_enumeration_for :security_level, with: SecurityLevels

  validates :security_level, presence: true

  def self.current
    self.first.presence || new
  end
end
