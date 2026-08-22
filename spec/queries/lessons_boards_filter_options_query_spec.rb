require 'rails_helper'

RSpec.describe LessonsBoardsFilterOptionsQuery, type: :query do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:current_year) { Date.current.year }
  let(:previous_year) { current_year - 1 }

  let(:unity_a) { create(:unity) }
  let(:unity_b) { create(:unity) }
  let(:unity_previous_year) { create(:unity) }
  let(:unity_without_lessons_board) { create(:unity) }

  let(:grade_a) { create(:grade) }
  let(:grade_b) { create(:grade) }

  let(:classroom_a) { create(:classroom, unity: unity_a, year: current_year) }
  let(:classroom_b) { create(:classroom, unity: unity_b, year: current_year) }
  let(:classroom_previous_year) { create(:classroom, unity: unity_previous_year, year: previous_year) }

  let(:classrooms_grade_a) { create(:classrooms_grade, classroom: classroom_a, grade: grade_a) }
  let(:classrooms_grade_b) { create(:classrooms_grade, classroom: classroom_b, grade: grade_b) }
  let(:classrooms_grade_previous_year) do
    create(:classrooms_grade, classroom: classroom_previous_year, grade: grade_a)
  end

  let!(:lessons_board_a) { create(:lessons_board, classrooms_grade: classrooms_grade_a) }
  let!(:lessons_board_b) { create(:lessons_board, classrooms_grade: classrooms_grade_b) }
  let!(:lessons_board_previous_year) { create(:lessons_board, classrooms_grade: classrooms_grade_previous_year) }

  # Turma sem quadro de aula: nunca pode aparecer em nenhuma das listas de opções
  let!(:classrooms_grade_without_lessons_board) do
    create(:classrooms_grade, classroom: create(:classroom, unity: unity_without_lessons_board, year: current_year))
  end

  subject(:query) { described_class.new(LessonsBoard.all) }

  describe '#unities' do
    it 'returns only unities with lessons boards on the given year' do
      expect(query.unities(year: current_year).to_a).to contain_exactly(unity_a, unity_b)
    end

    it 'returns unities from every year when year is blank' do
      expect(query.unities(year: '').to_a).to contain_exactly(unity_a, unity_b, unity_previous_year)
    end

    it 'keeps the selected unity even when it has no lessons board on the given year' do
      options = query.unities(year: current_year, selected_id: unity_previous_year.id.to_s)

      expect(options.to_a).to contain_exactly(unity_a, unity_b, unity_previous_year)
    end

    it 'does not return unities of discarded lessons boards' do
      lessons_board_b.discard

      expect(query.unities(year: current_year).to_a).to contain_exactly(unity_a)
    end

    it 'does not return unities outside of the received relation' do
      restricted_query = described_class.new(LessonsBoard.by_unity(unity_a.id))

      expect(restricted_query.unities(year: current_year).to_a).to contain_exactly(unity_a)
    end

    # A relação chega ordenada do controller e SELECT DISTINCT não aceita ORDER BY de coluna fora
    # da projeção, então a consulta precisa descartar a ordenação recebida.
    it 'accepts an ordered relation' do
      ordered_query = described_class.new(LessonsBoard.all.order('lessons_boards.id'))

      expect(ordered_query.unities(year: current_year).to_a).to contain_exactly(unity_a, unity_b)
    end

    it 'resolves the options with two queries' do
      expect(count_queries { query.unities(year: current_year).to_a }).to eq(2)
    end
  end

  describe '#grades' do
    it 'returns only grades with lessons boards on the given year' do
      expect(query.grades(year: current_year).to_a).to contain_exactly(grade_a, grade_b)
    end

    it 'returns only grades of the given unity' do
      expect(query.grades(year: current_year, unity_id: unity_a.id.to_s).to_a).to contain_exactly(grade_a)
    end

    it 'returns grades from every year when year is blank' do
      expect(query.grades(year: '', unity_id: unity_previous_year.id.to_s).to_a).to contain_exactly(grade_a)
    end

    it 'resolves the options with a single query' do
      expect(count_queries { query.grades(year: current_year, unity_id: unity_a.id.to_s).to_a }).to eq(1)
    end
  end

  describe '#classrooms' do
    it 'returns only classrooms with lessons boards on the given year' do
      expect(query.classrooms(year: current_year).to_a).to contain_exactly(classroom_a, classroom_b)
    end

    it 'returns only classrooms of the given unity and grade' do
      options = query.classrooms(year: current_year, unity_id: unity_a.id.to_s, grade_id: grade_a.id.to_s)

      expect(options.to_a).to contain_exactly(classroom_a)
    end

    it 'returns no classroom when the grade has no lessons board on the given unity' do
      options = query.classrooms(year: current_year, unity_id: unity_a.id.to_s, grade_id: grade_b.id.to_s)

      expect(options.to_a).to eq([])
    end

    it 'resolves the options with a single query' do
      expect(count_queries { query.classrooms(year: current_year).to_a }).to eq(1)
    end
  end
end
