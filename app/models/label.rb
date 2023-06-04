class Label < ApplicationRecord
  COLORS = %w(#9121AD #AD2121 #AD6421 #C9AC13 #21AD27 #21A5AD #212FAD #BC62D2 #D26262 #C88F5A #D8BC59 #5AB8CD
              #5AB8CD #6274D2 #7A7A7A)

  belongs_to :labelable, polymorphic: true

  before_create :set_color

  private

  def set_color
    self.color = COLORS.sample
  end
end
