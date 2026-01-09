# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IeducarStudentTransferDataFetcher, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }
  let!(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
  let!(:unity) { create(:unity) }
  let!(:discipline) { create(:discipline) }
  let!(:classroom) do
    create(
      :classroom,
      :with_classroom_semester_steps,
      :score_type_numeric_and_concept_create_rule,
      unity: unity
    )
  end
  let!(:student_enrollment_classroom) do
    create(
      :student_enrollment_classroom,
      classrooms_grade: classroom.classrooms_grades.first,
      joined_at: classroom.calendar.classroom_steps.first.start_at
    )
  end
  let(:student) { student_enrollment_classroom.student_enrollment.student }
  let!(:teacher_discipline_classroom) do
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      score_type: ScoreTypes::NUMERIC
    )
  end
  let(:teacher) { teacher_discipline_classroom.teacher }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  subject { described_class.new(student: student, classroom: classroom) }

  describe '#post_to_ieducar!' do
    let(:first_step) { classroom.calendar.classroom_steps.first }

    before do
      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when student is enrolled in classroom' do
      it 'does not raise error when successfully sending data' do
        expect { subject.post_to_ieducar! }.not_to raise_error
      end
    end

    context 'with numerical scores' do
      let!(:avaliation) do
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          test_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
      let!(:daily_note_student) do
        create(
          :daily_note_student,
          student_id: student.id,
          daily_note: daily_note,
          note: 8.5
        )
      end

      it 'sends numerical scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end

    end

    context 'with school term recovery scores' do
      let!(:avaliation) do
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          test_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
      let!(:daily_note_student) do
        create(
          :daily_note_student,
          student_id: student.id,
          daily_note: daily_note,
          note: 5.0
        )
      end
      let!(:recovery_diary_record) do
        recovery_record = build(
          :recovery_diary_record,
          :with_teacher_discipline_classroom,
          unity: unity,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id
        )
        recovery_record.students << build(:recovery_diary_record_student, student: student, score: 7.0, recovery_diary_record: recovery_record)
        recovery_record.save!

        create(
          :school_term_recovery_diary_record,
          step_id: first_step.id,
          step_number: first_step.to_number,
          recovery_diary_record: recovery_record
        )
      end

      it 'sends recovery scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end
    end

    context 'with conceptual scores' do
      let!(:conceptual_exam) do
        exam = build(
          :conceptual_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          student: student,
          teacher_id: teacher.id,
          step_number: first_step.to_number
        )
        exam.step_id = first_step.id
        exam.conceptual_exam_values << build(:conceptual_exam_value, discipline: discipline, value: 'A', conceptual_exam: exam)
        exam.save!
        exam
      end

      before do
        classroom.first_exam_rule.update(score_type: ScoreTypes::CONCEPT)
        teacher_discipline_classroom.update(score_type: ScoreTypes::CONCEPT)
      end

      it 'sends conceptual scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end
    end

    context 'with absences (general frequency)' do
      let!(:daily_frequency) do
        create(
          :daily_frequency,
          :without_discipline,
          classroom: classroom,
          teacher_id: teacher.id,
          frequency_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_frequency_student) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student_id: student.id,
          present: false
        )
      end

      it 'sends absences to i-Educar' do
        absence_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-geral.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(absence_stub).to have_been_requested.at_least_once
      end

    end

    context 'with absences by discipline' do
      let!(:daily_frequency) do
        create(
          :daily_frequency,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          frequency_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_frequency_student) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student_id: student.id,
          present: false
        )
      end

      before do
        classroom.first_exam_rule.update(frequency_type: FrequencyTypes::BY_DISCIPLINE)
      end

      it 'sends absences grouped by discipline' do
        absence_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-por-componente.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(absence_stub).to have_been_requested.at_least_once
      end
    end

    context 'with descriptive exams' do
      let!(:descriptive_exam) do
        exam = create(
          :descriptive_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE,
          step_number: first_step.to_number
        )
        exam.step_id = first_step.id
        exam.save!
        exam
      end
      let!(:descriptive_exam_student) do
        create(
          :descriptive_exam_student,
          descriptive_exam: descriptive_exam,
          student: student,
          value: 'Aluno demonstrou excelente desempenho'
        )
      end

      before do
        classroom.first_exam_rule.update(opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
      end

      it 'sends descriptive exams to i-Educar' do
        descriptive_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=pareceres.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(descriptive_stub).to have_been_requested.at_least_once
      end
    end

    context 'with student using differentiated exam rule' do
      before do
        student.update(uses_differentiated_exam_rule: true)
        differentiated_rule = create(
          :exam_rule,
          score_type: ScoreTypes::CONCEPT,
          opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE
        )
        classroom.first_exam_rule.update(differentiated_exam_rule: differentiated_rule)
      end

      it 'uses differentiated exam rule for the student' do
        expect(subject.send(:exam_rule)).to eq(classroom.first_exam_rule.differentiated_exam_rule)
      end
    end
  end
end
