require 'rails_helper'

RSpec.describe AbsenceAdjustmentsService, type: :service do
  let!(:year) { Date.current.year }
  let!(:unities) { create_list(:unity, 2) }
  let!(:teacher) { create(:teacher) }

  subject do
    AbsenceAdjustmentsService.new(unities, year)
  end

  describe '#adjust' do
    context 'when exists absence by discipline and should be general absence' do
      let!(:discipline) { create(:discipline) }
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom,
          :score_type_numeric,
          teacher: teacher,
          discipline: discipline,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          discipline: discipline,
          class_number: 1
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :by_discipline,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          discipline: discipline,
          class_number: 2
        )
      }

      it 'needs to adjust to be general absence' do
        expect(subject.daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be true
        FrequencyTypeDefiner.any_instance.stub(:define_frequency_type).and_return(FrequencyTypes::GENERAL)
        subject.adjust
        expect(subject.daily_frequencies_by_type(FrequencyTypes::GENERAL).exists?).to be false
      end

      it 'keeps one daily_frequency converted to general per date and destroys the duplicates' do
        FrequencyTypeDefiner.any_instance.stub(:define_frequency_type).and_return(FrequencyTypes::GENERAL)
        expect(DailyFrequency.count).to eq(2)
        subject.adjust
        # A primeira (classroom, disc) de cada data vira geral (discipline_id=NULL);
        # demais class_numbers no mesmo par (classroom, disc, date) são destruídas.
        remaining = DailyFrequency.all
        expect(remaining.count).to eq(1)
        expect(remaining.first.discipline_id).to be_nil
        expect(remaining.first.class_number).to be_nil
      end

      context 'when classroom has multiple classrooms_grades and frequencies on multiple dates' do
        let!(:daily_frequency_date2_cn1) {
          create(
            :daily_frequency,
            unity: classroom.unity,
            classroom: classroom,
            school_calendar: school_calendar,
            discipline: discipline,
            class_number: 1,
            frequency_date: daily_frequency_1.frequency_date.prev_day
          )
        }
        let!(:daily_frequency_date2_cn2) {
          create(
            :daily_frequency,
            unity: classroom.unity,
            classroom: classroom,
            school_calendar: school_calendar,
            discipline: discipline,
            class_number: 2,
            frequency_date: daily_frequency_1.frequency_date.prev_day
          )
        }

        it 'preserves one general frequency per date' do
          FrequencyTypeDefiner.any_instance.stub(:define_frequency_type).and_return(FrequencyTypes::GENERAL)
          expect(DailyFrequency.count).to eq(4)
          subject.adjust
          remaining = DailyFrequency.all
          expect(remaining.count).to eq(2)
          expect(remaining.pluck(:discipline_id).uniq).to eq([nil])
          expect(remaining.pluck(:class_number).uniq).to eq([nil])
          expect(remaining.pluck(:frequency_date).uniq).to match_array([
            daily_frequency_1.frequency_date,
            daily_frequency_1.frequency_date.prev_day
          ])
        end
      end
    end

    context 'when exists general absence and should be absence by discipline' do
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom,
          :by_discipline_create_rule,
          teacher: teacher,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          :without_discipline,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :without_discipline,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          frequency_date: daily_frequency_1.frequency_date.prev_day
        )
      }
      let!(:user) { create(:user, teacher: teacher) }

      it 'needs to adjust to be absence by discipline' do
        add_user_to_audit(daily_frequency_1)
        add_user_to_audit(daily_frequency_2)

        expect(subject.daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be true
        subject.adjust
        expect(subject.daily_frequencies_by_type(FrequencyTypes::BY_DISCIPLINE).exists?).to be false
      end

      context 'when teacher has multiple disciplines' do
        let!(:discipline_1) { create(:discipline) }
        let!(:discipline_2) { create(:discipline) }
        let!(:discipline_3) { create(:discipline) }
        let!(:grade) { classroom.classrooms_grades.first.grade }
        let!(:teacher_discipline_classroom_1) {
          create(
            :teacher_discipline_classroom,
            classroom: classroom,
            teacher: teacher,
            discipline: discipline_1,
            grade: grade
          )
        }
        let!(:teacher_discipline_classroom_2) {
          create(
            :teacher_discipline_classroom,
            classroom: classroom,
            teacher: teacher,
            discipline: discipline_2,
            grade: grade
          )
        }
        let!(:teacher_discipline_classroom_3) {
          create(
            :teacher_discipline_classroom,
            classroom: classroom,
            teacher: teacher,
            discipline: discipline_3,
            grade: grade
          )
        }
        let!(:student) { create(:student) }
        let!(:daily_frequency_student) {
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency_1,
            student: student,
            present: false
          )
        }

        before do
          daily_frequency_1.update(owner_teacher_id: teacher.id)
        end

        it 'creates one frequency for each teacher discipline' do
          # 1 disciplina da factory + 3 disciplinas criadas no teste = 4 total
          teacher_disciplines_count = classroom.teacher_discipline_classrooms.by_teacher_id(teacher.id).count

          subject.adjust

          created_frequencies = DailyFrequency.where(
            classroom_id: classroom.id,
            frequency_date: daily_frequency_1.frequency_date
          )
          expect(created_frequencies.count).to eq(teacher_disciplines_count)
          expect(created_frequencies.pluck(:discipline_id)).to include(discipline_1.id, discipline_2.id, discipline_3.id)
        end

        it 'preserves DailyFrequencyStudent for each new frequency' do
          subject.adjust

          # Verifica todas as frequências criadas de todas disciplinas vinculadas ao professor
          new_frequencies = DailyFrequency.where(
            classroom_id: classroom.id,
            frequency_date: daily_frequency_1.frequency_date
          )

          new_frequencies.each do |frequency|
            expect(frequency.students.count).to eq(1)
            expect(frequency.students.first.student_id).to eq(student.id)
            expect(frequency.students.first.present).to eq(false)
          end
        end

        it 'destroys the original general frequency' do
          original_id = daily_frequency_1.id

          subject.adjust

          expect(DailyFrequency.find_by(id: original_id)).to be_nil
        end
      end

      context 'when a frequency by discipline already exists with class_number different from default' do
        let!(:existing_discipline) { create(:discipline) }
        let!(:grade) { classroom.classrooms_grades.first.grade }
        let!(:teacher_discipline_classroom_existing) {
          create(
            :teacher_discipline_classroom,
            classroom: classroom,
            teacher: teacher,
            discipline: existing_discipline,
            grade: grade
          )
        }
        let!(:student) { create(:student) }
        let!(:original_student) {
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency_1,
            student: student,
            present: false
          )
        }
        let!(:existing_by_discipline_frequency) {
          create(
            :daily_frequency,
            unity: classroom.unity,
            classroom: classroom,
            school_calendar: school_calendar,
            discipline: existing_discipline,
            frequency_date: daily_frequency_1.frequency_date,
            period: daily_frequency_1.period,
            class_number: 3
          )
        }
        let!(:existing_student) {
          create(
            :daily_frequency_student,
            daily_frequency: existing_by_discipline_frequency,
            student: student,
            present: true
          )
        }

        before do
          daily_frequency_1.update(owner_teacher_id: teacher.id)
        end

        it 'does not raise PG::UniqueViolation when reusing the existing frequency' do
          expect { subject.adjust }.not_to raise_error
        end

        it 'preserves the existing student record without duplicating' do
          subject.adjust

          existing_by_discipline_frequency.reload
          expect(existing_by_discipline_frequency.students.count).to eq(1)
          expect(existing_by_discipline_frequency.students.first.student_id).to eq(student.id)
          # Atributos do lançamento manual são preservados (present=true).
          expect(existing_by_discipline_frequency.students.first.present).to eq(true)
        end

        it 'destroys the original general frequency' do
          original_id = daily_frequency_1.id

          subject.adjust

          expect(DailyFrequency.find_by(id: original_id)).to be_nil
        end
      end
    end

    context 'when exists general absence should be absence by discipline because teacher is for a specific area' do
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom_specific,
          :score_type_numeric,
          teacher: teacher,
          unity: unities.first
        )
      }
      let(:school_calendar) { classroom.calendar.school_calendar }
      let!(:daily_frequency_1) {
        create(
          :daily_frequency,
          :without_discipline,
          :with_teacher,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          teacher: teacher,
        )
      }
      let!(:daily_frequency_2) {
        create(
          :daily_frequency,
          :without_discipline,
          :with_teacher,
          unity: classroom.unity,
          classroom: classroom,
          school_calendar: school_calendar,
          teacher: teacher,
          frequency_date: daily_frequency_1.frequency_date.prev_day
        )
      }
      let!(:user) { create(:user, teacher: teacher) }

      it 'needs to adjust to be absence by discipline when teacher is for a specific area' do
        expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be true
        subject.adjust
        expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be false
      end

      context 'when frequency by discipline already exists with same students' do
        let!(:student) { create(:student) }
        let!(:discipline) { classroom.teacher_discipline_classrooms.first.discipline }
        let!(:daily_frequency_student_1) {
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency_1,
            student: student,
            present: true
          )
        }
        let!(:existing_daily_frequency_by_discipline) {
          create(
            :daily_frequency,
            unity: classroom.unity,
            classroom: classroom,
            school_calendar: school_calendar,
            discipline: discipline,
            frequency_date: daily_frequency_1.frequency_date,
            period: daily_frequency_1.period,
            class_number: 1
          )
        }
        let!(:existing_daily_frequency_student) {
          create(
            :daily_frequency_student,
            daily_frequency: existing_daily_frequency_by_discipline,
            student: student,
            present: false
          )
        }

        it 'does not raise duplicate key error when student already exists' do
          expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be true
          expect { subject.adjust }.not_to raise_error
          expect(subject.daily_frequencies_general_when_teacher_has_specific_area.exists?).to be false
        end

        it 'destroys the general frequency' do
          subject.adjust
          expect(DailyFrequency.find_by(id: daily_frequency_1.id)).to be_nil
        end
      end
    end
  end

  def add_user_to_audit(daily_frequency)
    audit = Audited::Audit.where(
      auditable_type: 'DailyFrequency',
      auditable_id: daily_frequency.id
    ).first
    audit.update(user_id: user.id)
  end
end
