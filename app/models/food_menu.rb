class ***REMOVED***Menu < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :***REMOVED***

  belongs_to :food
  belongs_to :***REMOVED***

  validates :food_id, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end
