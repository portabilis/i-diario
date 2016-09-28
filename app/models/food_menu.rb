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

  FOOD_COMPOSITION_ATTRIBUTES = [:kilocalories, :proteins, :lipids, :dietary_fiber, :calcium, :magnesium,
    :iron, :zinc, :vitamin_c, :carbohydrate, :sodium, :phosphor, :potassium]

  FOOD_COMPOSITION_ATTRIBUTES.each do |method|
      define_method method do
        (quantity * (food.send(method) || 0.0))
      end
  end

end
