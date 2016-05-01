require 'spec_helper_lite'

require 'enumerate_it'
require 'app/enumerations/frequency_types'
require 'app/services/frequency_type_resolver'

RSpec.describe FrequencyTypeResolver, type: :service do
  let(:current_school_calendar_fetcher) { double(:current_school_calendar_fetcher) }
  let(:exam_rule) { double(:exam_rule) }
  let(:classroom) { double(:classroom) }
  let(:teacher) { double(:teacher) }
  let(:teacher_discipline_classroom) { nil }


  before do
    stub_current_school_year_fetcher
    stub_exam_rule
    stub_classroom
    stub_teacher
    stub_teacher_discipline_classroom
  end

  subject do
    FrequencyTypeResolver.new(classroom, teacher)
  end

  describe '#resolve' do
    context 'when classroom frequency type is by discipline' do
      let(:frequency_type) { FrequencyTypes::BY_DISCIPLINE }

      it 'should return FrequencyTypes::BY_DISCIPLINE' do
        expect(subject.resolve).to be(FrequencyTypes::BY_DISCIPLINE)
      end
    end

    context 'when classroom frequency type is general' do
      let(:frequency_type) { FrequencyTypes::GENERAL }

      context 'when the teacher can register frequency to the classroom by discipline' do
        let(:teacher_discipline_classroom) { double(:teacher_discipline_classroom) }

        it 'should return FrequencyTypes::BY_DISCIPLINE' do
          expect(subject.resolve).to be(FrequencyTypes::BY_DISCIPLINE)
        end
      end

      context 'when the teacher cannot register frequency to the classroom by discipline' do
        let(:teacher_discipline_classroom) { nil }

        it 'should return FrequencyTypes::GENERAL' do
          expect(subject.resolve).to be(FrequencyTypes::GENERAL)
        end
      end
    end
  end

  def stub_exam_rule
    allow(exam_rule).to receive(:frequency_type).and_return(frequency_type)
  end

  def stub_classroom
    allow(classroom).to receive(:exam_rule).and_return(exam_rule)
    allow(classroom).to receive(:id).and_return(2)
    allow(classroom).to receive(:unity_id).and_return(3)
  end

  def stub_teacher
    allow(teacher).to receive(:id).and_return(1)
  end

  def stub_teacher_discipline_classroom
    stub_const('TeacherDisciplineClassroom', Class.new)
    allow(TeacherDisciplineClassroom).to(
      receive(:find_by).with(
          teacher_id: 1,
          classroom_id: 2,
          year: 2016,
          allow_absence_by_discipline: 1,
          active: true
        )
        .and_return(teacher_discipline_classroom)
    )
  end

  def stub_current_school_year_fetcher
    stub_const('CurrentSchoolYearFetcher', Class.new)
    allow(CurrentSchoolYearFetcher).to(
      receive(:new).with(3).and_return(current_school_calendar_fetcher)
    )
    allow(current_school_calendar_fetcher).to receive(:fetch).and_return(2016)
  end
end
