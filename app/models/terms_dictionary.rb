class TermsDictionary < ActiveRecord::Base
  acts_as_copy_target
  audited

  include Audit

  validates :presence_identifier_character, presence: true, length: { is: 1 }

  def self.current
    self.first.presence || new
  end
end
