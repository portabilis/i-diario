class ContentRecord < ActiveRecord::Base
  include Audit
  audited except: [:teacher_id]
  has_associated_audits

  acts_as_copy_target

  attr_accessor :record_date_copy

  belongs_to :classroom
  belongs_to :teacher
  attr_writer :unity_id
  attr_writer :contents_tags

  has_one :discipline_content_record
  has_one :knowledge_area_content_record
  has_many :content_records_contents, dependent: :destroy
  has_many :contents, through: :content_records_contents
  accepts_nested_attributes_for :contents

  validates :unity_id, presence: true
  validates :classroom, presence: true
  validates :record_date, presence: true, school_calendar_day: true
  validates :teacher, presence: true
  validate :at_least_one_content, :record_date_valid

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

  # necessario pois quando inserida uma data invalida, o controller considera
  # o valor de record_date como nil e a mensagem mostrada é a de que não pode
  # ficar em branco, quando deve mostrar a de que foi inserida uma data invalida
  def record_date_valid
    return if record_date_copy.nil?
    begin
      record_date_copy.to_date
    rescue ArgumentError
      errors[:record_date].clear
      errors.add(:record_date, "deve ser uma data válida")
    end
  end
end
