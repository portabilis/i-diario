require 'rails_helper'

RSpec.describe ObservationRecordReportQuery, type: :query do
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:exam_rule) { create(:exam_rule, :frequency_type_by_discipline) }
  let(:classroom_one) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :by_discipline,
      exam_rule: exam_rule,
      discipline: discipline,
      teacher: teacher
    )
  }
  let(:classroom_two) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :by_discipline,
      exam_rule: exam_rule,
      discipline: discipline,
      teacher: teacher
    )
  }
  let(:start_at) { Date.current }
  let(:end_at) { Date.current + 15.days }

  subject do
    ObservationRecordReportQuery.new(
      classroom_one.unity.id,
      teacher.id,
      classroom_one.id,
      discipline.id,
      start_at,
      end_at,
      1
    )
  end

  describe '#observation_diary_records' do
    it 'should filter by teacher_id' do
      skip "Teacher id is not used anymore, it uses current user teacher id"
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
      teacher: teacher,
      classroom: classroom_one,
      discipline: classroom_one.disciplines.first
    }

    attributes.delete(attribute) unless attribute == :nothing
    attributes[:classroom] = classroom_two if attribute == :classroom
    attributes[:date] = Date.current - 20.days if attribute == :date

    create(
      :observation_diary_record,
      :with_teacher_discipline_classroom,
      :with_notes,
      attributes
    )
  end
end
