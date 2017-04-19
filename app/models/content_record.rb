class ContentRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited associated_with: [:discipline_content_record, :knowledge_area_content_record]
  has_associated_audits

  belongs_to :classroom
  belongs_to :teacher
  attr_writer :unity_id
  attr_writer :contents_tags

  has_one :discipline_content_record
  has_one :knowledge_area_content_record
  has_and_belongs_to_many :contents, dependent: :destroy
  accepts_nested_attributes_for :contents

  validates :unity_id, presence: true
  validates :classroom, presence: true
  validates :record_date, presence: true
  validates :teacher, presence: true
  validate :at_least_one_content

  def school_calendar
    CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end

  def unity
    return unless unity_id
    Unity.find(unity_id)
  end

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter::tags_to_json(@contents_tags)
    end
  end

  def contents_ordered
    contents.order(' "content_records_contents"."id" ')
  end

  private

  def at_least_one_content
    if content_ids.blank?
      errors.add(:contents, :at_least_one_content)
    end
  end
end
