class SpecificStep < ActiveRecord::Base
  include Discard::Model

  audited

  belongs_to :classroom
  belongs_to :discipline
end
