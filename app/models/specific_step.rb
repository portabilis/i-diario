class SpecificStep < ApplicationRecord
  include Discardable

  audited

  belongs_to :classroom
  belongs_to :discipline

  default_scope -> { kept }
end
