require 'rails_helper'

RSpec.describe DeleteDispensedExamsAndFrequenciesService, type: :service do
  describe '#run!' do
    let!(:classroom) { create(:classroom, :score_type_numeric_and_concept) }
    let!(:discipline) { create(:discipline) }
    let!(:other_discipline) { create(:discipline) }
    let(:unity) { create(:unity) }
    let!(:student_enrollment) { create(:student_enrollment) }
    let!(:school_calendar) {
      create(
        :school_calendar,
        :with_semester_steps,
        unity: classroom.unity
      )
    }
    let!(:student_enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        classroom: classroom,
        student_enrollment: student_enrollment
      )
    }
    let(:first_semester) { 1 }
    let(:second_semester) { 2 }
    let(:inexisting_step) { 3 }

    subject do
      DeleteDispensedExamsAndFrequenciesService.new(
        student_enrollment.id,
        discipline.id,
        [first_semester]
      )
    end

    context 'when there are invalid daily note students' do
      let(:avaliation1) {
        create(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          school_calendar: school_calendar
        )
      }
      let(:avaliation2) {
        create(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          school_calendar: school_calendar
        )
      }
      let(:daily_note1) {
        create(:current_daily_note, avaliation: avaliation1)
      }
      let(:daily_note2) {
        create(:current_daily_note, avaliation: avaliation2)
      }
      let!(:daily_note_student1) {
        create(
          :current_daily_note_student,
          daily_note: daily_note1,
          student: student_enrollment.student
        )
      }
      let!(:daily_note_student2) {
        create(
          :current_daily_note_student,
          daily_note: daily_note2,
          student: student_enrollment.student
        )
      }

      it 'destroys invalid daily note students' do
        expect { subject.run! }.to change { DailyNoteStudent.count }.from(2).to(1)
      end

      shared_examples 'invalid_daily_note_students' do
        it 'does not destroy invalid daily note students' do
          expect { subject.run! }.not_to(change { DailyNoteStudent.count })
        end
      end

      context 'when student_enrollment_classroom does not have classroom' do
        before do
          student_enrollment_classroom.update(classroom_id: nil)
        end

        it_behaves_like 'invalid_daily_note_students'
      end

      context 'when steps_fetcher does not find the school_calendar' do
        before do
          school_calendar.update(unity: unity)
        end

        it_behaves_like 'invalid_daily_note_students'
      end

      context 'when step does not exists' do
        subject do
          DeleteDispensedExamsAndFrequenciesService.new(
            student_enrollment.id,
            discipline.id,
            [inexisting_step]
          )
        end

        it_behaves_like 'invalid_daily_note_students'
      end
    end

    context 'when there are invalid recovery diary record students' do
      let!(:recovery_diary_record) {
        create(
          :recovery_diary_record_with_students,
          :current,
          classroom: classroom,
          unity: classroom.unity,
          discipline: discipline
        )
      }
      let!(:recovery_diary_record_student) {
        create(
          :recovery_diary_record_student,
          recovery_diary_record: recovery_diary_record,
          student: student_enrollment.student
        )
      }

      it 'destroys invalid recovery diary record students' do
        expect { subject.run! }.to change { RecoveryDiaryRecordStudent.count }.from(6).to(5)
      end
    end

    context 'when there are invalid conceptual exam values' do
      let!(:conceptual_exam) {
        create(
          :conceptual_exam_with_one_value,
          classroom: classroom,
          step_id: school_calendar.steps.first.id,
          student: student_enrollment.student
        )
      }
      let!(:conceptual_exam_value) {
        create(
          :conceptual_exam_value,
          conceptual_exam: conceptual_exam,
          discipline: discipline
        )
      }

      it 'destroys invalid conceptual exam values' do
        expect { subject.run! }.to change { ConceptualExamValue.count }.from(2).to(1)
      end
    end

    context 'when there are invalid descriptive exam students' do
      let(:descriptive_exam1) {
        create(
          :descriptive_exam,
          :current,
          classroom: classroom,
          discipline: discipline,
          step_id: school_calendar.steps.first.id
        )
      }
      let(:descriptive_exam2) {
        create(
          :descriptive_exam,
          :current,
          classroom: classroom,
          step_id: school_calendar.steps.last.id
        )
      }
      let!(:descriptive_exam_student1) {
        create(
          :descriptive_exam_student,
          descriptive_exam: descriptive_exam1,
          student: student_enrollment.student
        )
      }
      let!(:descriptive_exam_student2) {
        create(
          :descriptive_exam_student,
          descriptive_exam: descriptive_exam2,
          student: student_enrollment.student
        )
      }

      it 'destroys invalid descriptive exam students' do
        expect { subject.run! }.to change { DescriptiveExamStudent.count }.from(2).to(1)
      end
    end

    context 'when there are invalid daily frequency students' do
      let(:daily_frequency1) {
        create(
          :daily_frequency,
          :current,
          classroom: classroom,
          discipline: discipline
        )
      }
      let(:daily_frequency2) {
        create(
          :daily_frequency,
          :current,
          classroom: classroom
        )
      }
      let!(:daily_frequency_student1) {
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency1,
          student: student_enrollment.student
        )
      }
      let!(:daily_frequency_student2) {
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency2,
          student: student_enrollment.student
        )
      }

      it 'destroys invalid daily frequency students' do
        expect { subject.run! }.to change { DailyFrequencyStudent.count }.from(2).to(1)
      end
    end
  end
end
