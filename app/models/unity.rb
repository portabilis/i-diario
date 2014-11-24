class Unity < ActiveRecord::Base
  audited

  include Audit

  has_enumeration_for :unit_type, with: UnitTypes, create_helpers: true

  belongs_to :author, class_name: "User"
  has_one :address, as: :source, inverse_of: :source

  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***Request"
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***Request"
  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***"
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***"
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***"
  has_many :***REMOVED***_distribution_unities
  has_many :***REMOVED***, through: :***REMOVED***_distribution_unities

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  validates :author, :name, :unit_type, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
