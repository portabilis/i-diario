class AbsenceJustificationsDiscipline < ApplicationRecord
  audited

  belongs_to :discipline
  belongs_to :absence_justification
end
