class ***REMOVED***Menu < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :***REMOVED***

  belongs_to :food, -> { includes(:food_***REMOVED***) }
  belongs_to :***REMOVED***

  validates :food_id, presence: true
  validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: 999999.99 }

  validate :food_must_have_***REMOVED***

  def food_must_have_***REMOVED***
    return unless food

    errors.add(:food_id, :food_must_have_***REMOVED***) if food.food_***REMOVED***.empty?
  end
end
