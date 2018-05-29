class SpecificStep < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :discipline
end
