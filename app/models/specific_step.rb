class SpecificStep < ActiveRecord::Base
  audited

  belongs_to :classroom
  belongs_to :discipline
end
