require 'rails_helper'

RSpec.describe ObservationRecordReport, type: :report do
  let(:unity) { build_stubbed(:unity) }
  let(:classroom) { build_stubbed(:classroom) }
  let(:discipline) { build_stubbed(:discipline) }
  let(:teacher) { build_stubbed(:teacher) }
  let(:observation_diary_record) { double(:observation_diary_record) }
  let(:observation_diary_record_note) { double(:observation_diary_record_note) }

  let(:entity_configuration) { build_stubbed(:entity_configuration) }
  let(:form) {
    double(:observation_record_report_form,
           discipline_id: discipline.id,
           classroom_id: classroom.id
    )
  }

  before do
    stub_form
    stub_observation_diary_record
  end

  subject { ObservationRecordReport.new(entity_configuration, form) }

  it 'should be renderable' do
    rendered_pdf = subject.build.render
    text_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

    expect(text_analysis.strings).to include(unity.to_s)
    expect(text_analysis.strings).to include(classroom.to_s)
    expect(text_analysis.strings).to include(discipline.to_s)
    expect(text_analysis.strings).to include(teacher.to_s)
    expect(text_analysis.strings).to include(observation_diary_record.date)
    expect(text_analysis.strings).to include(observation_diary_record_note.description)
  end

  context 'when student filter is applied' do
    let(:student) { build_stubbed(:student) }
    let(:student_note) { double(:student_note) }
    let(:other_note) { double(:other_note) }

    before do
      allow(form).to receive(:student).and_return(student)
      allow(form).to receive(:student_id).and_return(student.id)
      allow(observation_diary_record).to receive(:notes).and_return([student_note, other_note])
      allow(student_note).to receive(:students).and_return([student])
      allow(student_note).to receive(:description).and_return('Student note')
      allow(other_note).to receive(:students).and_return([])
      allow(other_note).to receive(:description).and_return('Other note')
    end

    it 'should include student name in header' do
      rendered_pdf = subject.build.render
      text_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

      expect(text_analysis.strings).to include(student.to_s)
    end

    it 'should only include notes related to the student' do
      rendered_pdf = subject.build.render
      text_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

      expect(text_analysis.strings).to include('Student note')
      expect(text_analysis.strings).not_to include('Other note')
    end
  end

  def stub_form
    allow(form).to receive(:unity).and_return(unity)
    allow(form).to receive(:classroom).and_return(classroom)
    allow(form).to receive(:discipline).and_return(discipline)
    allow(form).to receive(:teacher).and_return(teacher)
    allow(form).to receive(:student).and_return(nil)
    allow(form).to receive(:student_id).and_return(nil)
    allow(form).to receive(:start_at).and_return('01/04/2016')
    allow(form).to receive(:end_at).and_return('30/04/2016')
    allow(form).to receive(:observation_diary_records).and_return([observation_diary_record])
  end

  def stub_observation_diary_record
    allow(observation_diary_record).to receive(:notes).and_return([observation_diary_record_note])
    allow(observation_diary_record).to receive(:localized).and_return(observation_diary_record)
    allow(observation_diary_record).to receive(:date).and_return('01/04/2016')
    allow(observation_diary_record_note).to receive(:students).and_return([])
    allow(observation_diary_record_note).to receive(:description).and_return('Note description example')
  end
end
