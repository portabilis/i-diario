require 'rails_helper'

RSpec.describe Api::DisciplineRecordsQuery do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity) }
  let(:course) { create(:course) }
  let(:grade) { create(:grade, course: course) }
  let(:discipline) { create(:discipline) }
  let(:classroom) do
    create(:classroom, :with_classroom_semester_steps, unity: unity, year: year)
  end
  let!(:classrooms_grade) do
    create(:classrooms_grade, classroom: classroom, grade: grade)
  end

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  describe '#classroom_ids' do
    it 'resolves classroom_ids filtered by all parameters' do
      query = described_class.new(
        unities: [unity.api_code],
        courses: [course.api_code],
        grades: [grade.api_code],
        disciplines: [discipline.api_code],
        year: year
      )

      expect(query.classroom_ids).to include(classroom.id)
    end

    it 'resolves classroom_ids filtered only by year' do
      query = described_class.new(
        unities: [],
        courses: [],
        grades: [],
        disciplines: [],
        year: year
      )

      expect(query.classroom_ids).to include(classroom.id)
    end

    it 'does not include classrooms from other unities' do
      other_unity = create(:unity)
      other_classroom = create(:classroom, :with_classroom_semester_steps, unity: other_unity, year: year)
      create(:classrooms_grade, classroom: other_classroom, grade: grade)

      query = described_class.new(
        unities: [unity.api_code],
        courses: [],
        grades: [],
        disciplines: [],
        year: year
      )

      expect(query.classroom_ids).to include(classroom.id)
      expect(query.classroom_ids).not_to include(other_classroom.id)
    end

    it 'infers grade_ids from courses when grades are not specified' do
      query = described_class.new(
        unities: [],
        courses: [course.api_code],
        grades: [],
        disciplines: [],
        year: year
      )

      expect(query.classroom_ids).to include(classroom.id)
    end
  end

  describe '#discipline_ids' do
    it 'resolves discipline api_codes to internal ids' do
      query = described_class.new(
        unities: [],
        courses: [],
        grades: [],
        disciplines: [discipline.api_code],
        year: year
      )

      expect(query.discipline_ids).to eq([discipline.id])
    end

    it 'returns nil when no disciplines are specified' do
      query = described_class.new(
        unities: [],
        courses: [],
        grades: [],
        disciplines: [],
        year: year
      )

      expect(query.discipline_ids).to be_nil
    end
  end

end
