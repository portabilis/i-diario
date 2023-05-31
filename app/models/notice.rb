class Notice < ApplicationRecord
  has_enumeration_for :kind, with: NoticeTypes, create_scopes: true

  belongs_to :noticeable, polymorphic: true

  validates :kind, :text, presence: true

  def self.texts
    pluck('notices.text').compact.uniq
  end
end
