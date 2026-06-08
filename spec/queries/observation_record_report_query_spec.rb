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
  let(:current_user) {
    create(
      :user_with_user_role,
      admin: false,
      teacher_id: teacher.id,
      current_school_year: classroom_one.year
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
      current_user.id
    )
  end

  describe '#observation_diary_records' do
    it 'should filter by teacher_id when provided' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:teacher)

      query = ObservationRecordReportQuery.new(
        classroom_one.unity.id,
        teacher.id,
        classroom_one.id,
        discipline.id,
        start_at,
        end_at,
        current_user.id
      )

      expect(query.observation_diary_records).to include(observation_diary_record_one)
      expect(query.observation_diary_records).not_to include(observation_diary_record_two)
    end

    it 'should not filter by teacher_id when not provided' do
      observation_diary_record_one = create_observation_diary_record
      observation_diary_record_two = create_observation_diary_record_with_different(:teacher)

      query = ObservationRecordReportQuery.new(
        classroom_one.unity.id,
        nil,
        classroom_one.id,
        discipline.id,
        start_at,
        end_at,
        current_user.id
      )

      expect(query.observation_diary_records).to include(observation_diary_record_one)
    end

    it 'should filter by student_id when provided' do
      student = create(:student)
      other_student = create(:student)

      observation_diary_record = create_observation_diary_record
      note = observation_diary_record.notes.first
      create(:observation_diary_record_note_student, observation_diary_record_note: note, student: student)

      observation_diary_record_other = create_observation_diary_record_with_different(:date,
                                                                                     date: Date.current - 1.day)
      other_note = observation_diary_record_other.notes.first
      create(:observation_diary_record_note_student, observation_diary_record_note: other_note, student: other_student)

      query = ObservationRecordReportQuery.new(
        classroom_one.unity.id,
        teacher.id,
        classroom_one.id,
        discipline.id,
        start_at,
        end_at,
        current_user.id,
        student.id
      )

      expect(query.observation_diary_records).to include(observation_diary_record)
      expect(query.observation_diary_records).not_to include(observation_diary_record_other)
    end

    it 'should not filter by student_id when not provided' do
      observation_diary_record = create_observation_diary_record

      expect(subject.observation_diary_records).to include(observation_diary_record)
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

  def create_observation_diary_record_with_different(attribute, overrides = {})
    attributes = {
      teacher: teacher,
      classroom: classroom_one,
      discipline: classroom_one.disciplines.first
    }

    attributes.delete(attribute) unless attribute == :nothing
    attributes[:classroom] = classroom_two if attribute == :classroom
    attributes[:date] = Date.current - 20.days if attribute == :date
    attributes.merge!(overrides)

    create(
      :observation_diary_record,
      :with_teacher_discipline_classroom,
      :with_notes,
      attributes
    )
  end
end
