class TermsDictionary < ActiveRecord::Base
  acts_as_copy_target
  audited

  include Audit

  validates :presence_identifier_character, presence: true, length: { is: 1 }

  def self.current
    Rails.cache.fetch('current_terms_dictionary', expires_in: 5.minutes) do
      self.first || new
    end
  end
end
