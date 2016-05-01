require 'rails_helper'

RSpec.describe ObservationRecordReportQuery, type: :query do
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2016) }
  let(:exam_rule) { create(:exam_rule, frequency_type: FrequencyTypes::BY_DISCIPLINE) }
  let(:classroom_one) { create(:classroom, exam_rule: exam_rule) }
  let(:classroom_two) { create(:classroom, exam_rule: exam_rule) }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }

  let(:teacher_id) { teacher.id }
  let(:classroom_id) { classroom_one.id }
  let(:discipline_id) { discipline.id }
  let(:start_at) { '01/04/2016' }
  let(:end_at) { '15/04/2016' }

  subject do
    ObservationRecordReportQuery.new(
      teacher_id,
      classroom_id,
      discipline_id,
      start_at,
      end_at
    )
  end

  describe '#observation_diary_records' do
    it 'should filter by teacher_id' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:teacher)

      expect(subject.observation_diary_records).to include(observation_diary_record_one)
      expect(subject.observation_diary_records).not_to include(observation_diary_record_two)
    end

    it 'should filter by classroom_id' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:classroom)

      expect(subject.observation_diary_records).to include(observation_diary_record_one)
      expect(subject.observation_diary_records).not_to include(observation_diary_record_two)
    end

    it 'should filter by discipline_id' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:discipline)

      expect(subject.observation_diary_records).to include(observation_diary_record_one)
      expect(subject.observation_diary_records).not_to include(observation_diary_record_two)
    end

    it 'should filter by date' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:date)

      expect(subject.observation_diary_records).to include(observation_diary_record_one)
      expect(subject.observation_diary_records).not_to include(observation_diary_record_two)
    end
  end

  def create_observation_diary_record
    create_observation_diary_record_with_different(:nothing)
  end

  def create_observation_diary_record_with_different(attribute)
    attributes = {
      school_calendar: school_calendar,
      teacher: teacher,
      classroom: classroom_one,
      discipline: discipline,
      date: '01/04/2016'
    }

    attributes.delete(attribute) unless attribute == :nothing
    attributes[:classroom] = classroom_two if attribute == :classroom
    attributes[:date] = '20/04/2016' if attribute == :date

    create(
      :observation_diary_record_with_notes,
      attributes
    )
  end
end
