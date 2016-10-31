class TermsDictionary < ActiveRecord::Base
  audited

  include Audit

  validates :presence_identifier_character, presence: true, length: { is: 1 }

  def self.current
    self.first.presence || new
  end
end
