class AbsenceJustificationsStudent < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :student
  belongs_to :absence_justification

  default_scope -> { kept }
end
