class AbsenceJustificationsStudent < ActiveRecord::Base
  audited

  belongs_to :student
  belongs_to :absence_justification
end
