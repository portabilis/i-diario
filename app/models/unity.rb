class Unity < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable

  has_enumeration_for :unit_type, with: UnitTypes, create_helpers: true

  belongs_to :author, class_name: "User"
  has_one :address, as: :source, inverse_of: :source
  has_one :absence_justification, dependent: :restrict_with_error

  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***Request", dependent: :restrict_with_error
  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***", dependent: :restrict_with_error
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***", dependent: :restrict_with_error
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***",dependent: :restrict_with_error
  has_many :***REMOVED***_distribution_unities
  has_many :unity_equipments
  has_many :***REMOVED***, through: :***REMOVED***_distribution_unities
  has_many :***REMOVED***, through: :***REMOVED***_unities
  has_many :moved_***REMOVED***, dependent: :restrict_with_error
  has_many :***REMOVED***, dependent: :restrict_with_error
  has_many :***REMOVED***, dependent: :restrict_with_error
  has_many :classrooms, dependent: :restrict_with_error
  has_many :teacher_discipline_classrooms, through: :classrooms, dependent: :restrict_with_error
  has_many :user_roles

  has_and_belongs_to_many :***REMOVED***
  has_and_belongs_to_many :***REMOVED***
  has_and_belongs_to_many :custom_rounding_tables

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  accepts_nested_attributes_for :unity_equipments, allow_destroy: true

  validates :author, :name, :unit_type, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true
  validate :uniqueness_of_equipments

  scope :ordered, -> { order(arel_table[:name].asc) }
  scope :by_api_codes, lambda { |codes|
    where(arel_table[:api_code].in(codes))
  }
  scope :with_api_code, -> { where(arel_table[:api_code].not_eq("")) }
  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :by_unity, -> unity { where(id: unity) }

  #search scopes
  scope :search_name, lambda { |search_name| where("unaccent(name) ILIKE unaccent(?)", "%#{search_name}%") }
  scope :unit_type, lambda { |unit_type| where(unit_type: unit_type) }
  scope :phone, lambda { |phone| where("unaccent(phone) ILIKE unaccent(?)", "%#{phone}%") }
  scope :email, lambda { |email| where("unaccent(email) ILIKE unaccent(?)", "%#{email}%") }
  scope :responsible, lambda { |responsible| where("unaccent(responsible) ILIKE unaccent(?)", "%#{responsible}%") }
  scope :by_school_group, lambda { |school_group| joins(:***REMOVED***).where(***REMOVED***_unities: { school_group_id: school_group })  }
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
end
