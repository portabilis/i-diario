class TeacherReportCardForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :status

  validates :unity_id, :classroom_id, :discipline_id, :status, presence: true
end
