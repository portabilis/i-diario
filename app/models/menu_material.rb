class Menu***REMOVED*** < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :***REMOVED***

  belongs_to :***REMOVED***
  belongs_to :material

  has_one :measuring_unit, through: :material

  validates :material_id, presence: true
  validates :quantity, numericality: true
end
