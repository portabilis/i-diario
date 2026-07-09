# frozen_string_literal: true

# Atribui o sequencial de exibição dos alunos numerando, de forma independente, os alunos
# regulares e os em dependência — cada grupo reinicia em 1 (regra de ordenação do i-Educar:
# matrículas de dependência aparecem ao final da turma com sequência própria). Mantém a ordem
# recebida e espera objetos que respondam a `dependence` e `display_sequence=`.
class StudentsDisplaySequencer
  def self.call(students)
    new(students).call
  end

  def initialize(students)
    @students = students
  end

  def call
    normal_sequence = 0
    dependence_sequence = 0

    @students.each do |student|
      if student.dependence
        dependence_sequence += 1
        student.display_sequence = dependence_sequence
      else
        normal_sequence += 1
        student.display_sequence = normal_sequence
      end
    end

    @students
  end
end
