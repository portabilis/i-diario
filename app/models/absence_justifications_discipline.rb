class AbsenceJustificationsDiscipline < ActiveRecord::Base
  audited

  belongs_to :discipline
  belongs_to :absence_justification
end
