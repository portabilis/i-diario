require 'rails_helper'

RSpec.describe AbsenceJustificationReport, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    school_calendar = create(:school_calendar, :with_one_step, year: 2016)
    teacher = create(:teacher)
    unity = create(:unity)
    classroom = create(:classroom)

    absence_justification_report_form = AbsenceJustificationReportForm.new(
      unity_id: unity,
      school_calendar_year: school_calendar,
      current_teacher_id: teacher,
      classroom_id: classroom,
      absence_date: '19/04/2016',
      absence_date_end: '20/04/2016'
    )

    absence_justifications = AbsenceJustification.all
    allow(absence_justification_report_form).to receive(:absence_justifications).and_return(absence_justifications)

    subject = AbsenceJustificationReport.build(
      entity_configuration,
      absence_justification_report_form
    ).render

    expect(subject).to be_truthy
  end
end
