class KnowledgeAreaContentRecord < ActiveRecord::Base
  include Audit

  audited
  acts_as_copy_target

  belongs_to :content_record, dependent: :destroy
  accepts_nested_attributes_for :content_record
  has_and_belongs_to_many :knowledge_areas

  scope :by_unity_id, lambda { |unity_id| joins(content_record: :classroom).where(Classroom.arel_table[:unity_id].eq(unity_id) ) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:content_record).where(content_records: { teacher_id: teacher_id }) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:content_record).where(content_records: { classroom_id: classroom_id }) }
  scope :by_knowledge_area_id, lambda { |knowledge_area_id| joins(:knowledge_areas)
                                                            .where(knowledge_areas: {id: knowledge_area_id } )}
  scope :by_classroom_description, lambda { |description| joins(content_record: :classroom).where('classrooms.description ILIKE ?', "%#{description}%" ) }
  scope :by_knowledge_area_description, lambda { |description| joins(:knowledge_areas).where('knowledge_areas.description ILIKE ?', "%#{description}%" ) }
  scope :by_date, lambda { |date| joins(:content_record).where(content_records: { record_date: date.to_date }) }
  scope :ordered, -> { joins(:content_record).order(ContentRecord.arel_table[:record_date].desc) }

  validates :content_record, presence: true
  validates :knowledge_area_ids, presence: true

  validate :uniqueness_of_knowledge_area_content_record
  validate :ensure_is_school_day

  delegate :contents, :classroom, :record_date, to: :content_record
  delegate :grade, to: :classroom

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

  private

  def uniqueness_of_knowledge_area_content_record
    return unless content_record.present? && content_record.classroom.present? && content_record.record_date.present?

    knowledge_area_content_records = KnowledgeAreaContentRecord.by_teacher_id(content_record.teacher_id)
      .by_classroom_id(content_record.classroom_id)
      .by_knowledge_area_id(knowledge_area_ids)
      .by_date(content_record.record_date)

    knowledge_area_content_records = knowledge_area_content_records.where.not(id: id) if persisted?

    if knowledge_area_content_records.any?
      errors.add(:knowledge_area_ids, :knowledge_area_in_use)
    end
  end

  def ensure_is_school_day
    return unless content_record.present? && record_date

    unless content_record.school_calendar.school_day?(record_date, grade, classroom)
      errors.add(:base, "")
      content_record.errors.add(:record_date, :not_school_calendar_day)
    end
  end

end
