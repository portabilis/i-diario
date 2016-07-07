class TeacherReportCardForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id

  validates :unity_id, :classroom_id, :discipline_id, presence: true

end
