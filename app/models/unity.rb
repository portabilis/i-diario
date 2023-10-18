class Unity < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable
  include Discardable

  has_enumeration_for :unit_type, with: UnitTypes, create_helpers: true

  belongs_to :author, class_name: "User"
  has_one :address, as: :source, inverse_of: :source
  has_one :absence_justification, dependent: :restrict_with_error

  has_many :unity_equipments
  has_many :classrooms, dependent: :restrict_with_error
  has_many :teacher_discipline_classrooms, through: :classrooms, dependent: :restrict_with_error
  has_many :user_roles, dependent: :destroy
  has_many :school_calendars, dependent: :restrict_with_error

  has_and_belongs_to_many :maintenance_adjustments
  has_and_belongs_to_many :custom_rounding_tables

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  accepts_nested_attributes_for :unity_equipments, allow_destroy: true

  validates :author, :name, :unit_type, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true
  validate :uniqueness_of_equipments

  default_scope -> { kept }

  scope :by_id, ->(id) { where(id: id) }
  scope :ordered, -> { order(arel_table[:name].asc) }
  scope :by_api_codes, -> (codes) { where(arel_table[:api_code].in(codes)) }
  scope :with_api_code, -> { where(arel_table[:api_code].not_eq("")) }
  scope :by_teacher, -> (teacher_id) { joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).distinct }
  scope :by_year, -> (year) { joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { year: year }).distinct }
  scope :by_teacher_with_school_calendar_year, lambda {
    joins(:teacher_discipline_classrooms, :school_calendars)
      .where(TeacherDisciplineClassroom.arel_table[:year].eq(SchoolCalendar.arel_table[:year])).distinct
  }
  scope :by_date, lambda { |date|
    joins(school_calendars: :steps).where(
      '? BETWEEN start_at AND end_at', date.to_date
    )
  }
  scope :by_posting_date, lambda { |date|
    joins(school_calendars: :steps).where(
      '? BETWEEN start_date_for_posting AND end_date_for_posting', date.to_date
    )
  }
  scope :by_posting_date_in_classroom, lambda { |date|
    joins(school_calendars: { classrooms: :classroom_steps }).where(
      '? BETWEEN start_date_for_posting AND end_date_for_posting', date.to_date
    )
  }
  scope :by_unity, -> unity { where(id: unity) }
  scope :by_user_id, ->(user_id) { joins(:user_roles).where(user_roles: { user_id: user_id }) }
  scope :by_infrequency_tracking_permission, lambda {
    role_ids = RolePermission.where(
      feature: :infrequency_trackings,
      permission: :change
    ).pluck(:role_id)

    joins(:user_roles).where(user_roles: { role_id: role_ids })
  }

  #search scopes
  scope :search_name, lambda { |search_name| where("unaccent(name) ILIKE unaccent(?)", "%#{search_name}%") }
  scope :unit_type, lambda { |unit_type| where(unit_type: unit_type) }
  scope :phone, lambda { |phone| where("unaccent(phone) ILIKE unaccent(?)", "%#{phone}%") }
  scope :email, lambda { |email| where("unaccent(email) ILIKE unaccent(?)", "%#{email}%") }
  scope :responsible, lambda { |responsible| where("unaccent(responsible) ILIKE unaccent(?)", "%#{responsible}%") }
  scope :by_id, lambda { |unity_id| where(id: unity_id) }

  def to_s
    name
  end

  def uniqueness_of_equipments
    # necessário devido a bug relatado https://github.com/rails/rails/issues/20676
    return if unity_equipments.reject(&:marked_for_destruction?).blank?

    if any_duplicated_equipment?
      errors.add(:unity_equipments, :uniqueness_of_items)

      duplicated_equipments = unity_equipments.reject(&:marked_for_destruction?).select do |equipment|
        unity_equipments.any? { |i| !i.eql?(equipment) && i.code.eql?(equipment.code) }
      end
      duplicated_equipments.each { |equipment| equipment.errors.add(:code, :taken) }
    end
  end

  def any_duplicated_equipment?
    unity_equipments.reject(&:marked_for_destruction?).group_by { |equipment| equipment.code }.count != unity_equipments.reject(&:marked_for_destruction?).count
  end

  def self.to_select
    ordered.map do |unity|
      OpenStruct.new(
        id: unity.id,
        name: unity.name,
        text: unity.name
      )
    end
  end
end
