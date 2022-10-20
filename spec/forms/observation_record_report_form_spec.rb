require 'spec_helper_form'
require 'active_record'
require 'postgres-copy'
require 'i18n_alchemy'
require 'app/models/classroom'
require 'app/models/teacher'
require 'app/forms/observation_record_report_form'

RSpec.describe ObservationRecordReportForm do
  let(:frequency_type_resolver) { double(:frequency_type_resolver) }
  let(:observation_record_report_query) { double(:observation_record_report_query) }

  before do
    stub_classroom
    stub_teacher
    stub_frequency_type_resolver
    stub_observation_record_report_query
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teacher_id) }
    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it do
      expect(subject).to(
        validate_date_of(:start_at)
          .is_not_in_future
      )
    end
    it { expect(subject).to validate_presence_of(:end_at) }
    it do
      expect(subject).to(
        validate_date_of(:end_at)
          .is_greater_than_or_equal_to(:start_at)
          .is_not_in_future
      )
    end

    context 'when all attributes are valid' do
      before do
        subject.teacher_id = 1
        subject.unity_id = 1
        subject.classroom_id = 1
        subject.start_at = Time.zone.today
        subject.end_at = Time.zone.today
      end

      it 'should require observation_diary_records to be present' do
        allow(observation_record_report_query).to(
          receive(:observation_diary_records).and_return([])
        )
        allow(subject).to receive(:require_observation_diary_records?).and_return(true)

        subject.valid?

        expect(subject.errors[:observation_diary_records]).to(
          include('Nenhum resultado foi encontrado para os dados informados')
        )
      end
    end

    context 'when any attributes is valid' do
      it 'should not require observation_diary_records to be present' do
        allow(observation_record_report_query).to(
          receive(:observation_diary_records).and_return([])
        )

        subject.valid?

        expect(subject.errors[:observation_diary_records]).not_to(
          include('Nenhum resultado foi encontrado para os dados informados')
        )
      end
    end
  end

  def stub_classroom
    stub_const('Classroom', Class.new)
    allow(Classroom).to receive(:find)
  end

  def stub_teacher
    stub_const('Teacher', Class.new)
    allow(Teacher).to receive(:find)
  end

  def stub_frequency_type_resolver
    stub_const('FrequencyTypeResolver', Class.new)
    allow(FrequencyTypeResolver).to receive(:new).and_return(frequency_type_resolver)
    allow(frequency_type_resolver).to receive(:by_discipline?).and_return(false)
  end

  def stub_observation_record_report_query
    stub_const('ObservationRecordReportQuery', Class.new)
    allow(ObservationRecordReportQuery).to receive(:new).and_return(observation_record_report_query)
  end
end
