class ContentRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited

  belongs_to :classroom
  belongs_to :teacher
  attr_writer :unity_id
  attr_accessor :contents_tags

  has_one :discipline_content_record
  has_and_belongs_to_many :contents, dependent: :destroy
  accepts_nested_attributes_for :contents

  validates :unity_id, presence: true
  validates :classroom, presence: true
  validates :record_date, presence: true
  validates :teacher, presence: true
  validate :at_least_one_content

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  private

  def at_least_one_content
    if content_ids.blank?
      errors.add(:contents, :at_least_one_content)
    end
  end
end
