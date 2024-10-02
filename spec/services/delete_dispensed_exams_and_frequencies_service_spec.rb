require 'rails_helper'

RSpec.describe DeleteDispensedExamsAndFrequenciesService, type: :service do
  describe '#run!' do
    let!(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_numeric_and_concept_create_rule,
        :with_student_enrollment_classroom,
      )
    }
    let!(:discipline) { create(:discipline) }
    let!(:school_calendar) { classroom.calendar.school_calendar }
    let!(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
    let!(:student_enrollment) { student_enrollment_classroom.student_enrollment }
    let(:first_semester) { 1 }
    let(:second_semester) { 2 }
    let(:inexisting_step) { 3 }
    let!(:user) { create(:user, :with_user_role_administrator) }

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
          discipline: discipline
        )
      }
      let(:avaliation2) {
        create(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom
        )
      }
      let(:daily_note1) {
        create(:daily_note, avaliation: avaliation1)
      }
      let(:daily_note2) {
        create(:daily_note, avaliation: avaliation2)
      }
      let!(:daily_note_student1) {
        create(
          :daily_note_student,
          daily_note: daily_note1,
          student: student_enrollment.student
        )
      }
      let!(:daily_note_student2) {
        create(
          :daily_note_student,
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

      context 'when student_enrollment_classroom does not have classrooms grade' do
        before do
          student_enrollment_classroom.update(classrooms_grade_id: nil)
        end

        it_behaves_like 'invalid_daily_note_students'
      end

      context 'when steps_fetcher does not find the school_calendar' do
        before do
          school_calendar.update(unity: create(:unity))
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
          :recovery_diary_record,
          :with_teacher_discipline_classroom,
          :with_students,
          classroom: classroom,
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
      let(:current_user) { create(:user) }
      let!(:classrooms_grade1) { create(:classrooms_grade, :score_type_numeric_and_concept, :with_classroom_semester_steps) }
      let!(:student_enrollment_classroom1) { create(:student_enrollment_classroom, classrooms_grade: classrooms_grade1) }
      let!(:conceptual_exam) {
        conceptual_exam = create(
          :conceptual_exam,
          :with_teacher_discipline_classroom,
          :with_one_value,
          classroom: classrooms_grade1.classroom,
          student: student_enrollment_classroom1.student_enrollment.student
        )
        current_user.current_classroom_id = conceptual_exam.classroom_id
        allow_any_instance_of(ConceptualExam).to receive(:current_user).and_return(current_user)

        conceptual_exam
      }
      let!(:conceptual_exam_value) {
        create(
          :conceptual_exam_value,
          conceptual_exam: conceptual_exam,
          discipline: discipline
        )
      }

      it 'destroys invalid conceptual exam values' do
        skip "Its not deleting"
        subject do
          DeleteDispensedExamsAndFrequenciesService.new(
            student_enrollment_classroom1.student_enrollment.id,
            discipline.id,
            [classrooms_grade1.classroom.calendar.classroom_steps.first]
          )
        end
        expect { subject.run! }.to change { ConceptualExamValue.count }.from(2).to(1)
      end
    end

    context 'when there are invalid descriptive exam students' do
      let(:descriptive_exam1) {
        create(
          :descriptive_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          step: classroom.calendar.classroom_steps.first
        )
      }
      let(:descriptive_exam2) {
        create(
          :descriptive_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          step: classroom.calendar.classroom_steps.last
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
          classroom: classroom,
          discipline: discipline
        )
      }
      let(:daily_frequency2) {
        create(
          :daily_frequency,
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
