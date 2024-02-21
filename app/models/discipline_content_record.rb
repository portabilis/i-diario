class DisciplineContentRecord < ActiveRecord::Base
  include Audit
  include ColumnsLockable
  include TeacherRelationable
  include Translatable

  not_updatable only: :discipline_id
  teacher_relation_columns only: :discipline

  audited associated_with: :content_record,
          except: [:content_record_id]
  acts_as_copy_target

  before_destroy :valid_for_destruction?

  belongs_to :content_record, dependent: :destroy
  accepts_nested_attributes_for :content_record

  belongs_to :discipline

  delegate :classroom_id, :classroom, to: :content_record

  scope :by_unity_id, lambda { |unity_id|
    joins(content_record: :classroom).where(Classroom.arel_table[:unity_id].eq(unity_id))
  }
  scope :by_teacher_id, lambda { |teacher_id|
    joins(:content_record).where(content_records: { teacher_id: teacher_id })
  }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(:content_record).where(content_records: { classroom_id: classroom_id })
  }
  scope :by_discipline_id, lambda { |discipline_id|
    where(discipline_id: discipline_id)
  }
  scope :by_classroom_description, lambda { |description|
    joins(content_record: :classroom).where(
      'unaccent(classrooms.description) ILIKE unaccent(?)', "%#{description}%"
    )
  }
  scope :by_discipline_description, lambda { |description|
    joins(:discipline).merge(Discipline.by_description(description))
  }
  scope :by_date, lambda { |date|
    joins(:content_record).where(content_records: { record_date: date.to_date })
  }
  scope :by_date_range, lambda { |start_at, end_at|
    joins(:content_record).where(
      'content_records.record_date <= ? AND content_records.record_date >= ?', end_at, start_at
    )
  }

  scope :ordered, -> { joins(:content_record).order(ContentRecord.arel_table[:record_date].desc) }
  scope :order_by_content_record_date, -> { joins(:content_record).order(ContentRecord.arel_table[:record_date]) }
  scope :by_author, lambda { |author_type, current_teacher_id|
    if author_type == PlansAuthors::MY_PLANS
      joins(:content_record).merge(ContentRecord.where(teacher_id: current_teacher_id))
    else
      joins(:content_record).merge(ContentRecord.where.not(teacher_id: current_teacher_id))
    end
  }
  scope :by_class_number, lambda { |class_number| where(class_number: class_number) }
  scope :order_by_classroom, lambda {
    joins(content_record: :classroom).order(Classroom.arel_table[:description].desc)
  }

  validates :class_number, presence: true, if: -> { allow_class_number? }
  validates :content_record, presence: true
  validates :discipline, presence: true

  validate :uniqueness_of_discipline_content_record
  validate :ensure_is_school_day
  validate :uniqueness_of_class_number, if: -> { allow_class_number? }

  delegate :contents, :record_date, :classroom, to: :content_record
  delegate :grades, to: :classroom

  private

  def allow_class_number?
    GeneralConfiguration.first.allow_class_number_on_content_records
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      content_record.validation_type = :destroy
      content_record.valid?
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')
      if content_record.errors[:record_date].include?(forbidden_error)
        errors.add(:base, forbidden_error)
        false
      else
        true
      end
    end
  end

  def uniqueness_of_discipline_content_record
    return if allow_class_number?
    return unless content_record.present? && content_record.classroom.present? && content_record.record_date.present?

    discipline_content_records = DisciplineContentRecord.by_teacher_id(content_record.teacher_id)
      .by_classroom_id(content_record.classroom_id)
      .by_discipline_id(discipline_id)
      .by_date(content_record.record_date)

    discipline_content_records = discipline_content_records.where.not(id: id) if persisted?

    if discipline_content_records.any?
      errors.add(:discipline_id, :discipline_in_use)
    end
  end

  def uniqueness_of_class_number
    discipline_content_record = DisciplineContentRecord.by_teacher_id(content_record.teacher_id)
                                                       .by_classroom_id(content_record.classroom_id)
                                                       .by_discipline_id(discipline_id)
                                                       .by_date(content_record.record_date)
                                                       .by_class_number(class_number)
                                                       .exists?

    if discipline_content_record
      errors.add(:class_number, I18n.t('activerecord.errors.models.discipline_content_record.attributes.discipline_id.class_number_in_use'))
    end
  end


  def ensure_is_school_day
    return unless content_record.present? &&
                  content_record.school_calendar.present? &&
                  record_date.present?

    grades.each do |grade|
      unless content_record.school_calendar.school_day?(record_date, grade, classroom_id, discipline)
        errors.add(:base, "")
        content_record.errors.add(:record_date, :not_school_calendar_day)
      end
    end
  end
end
