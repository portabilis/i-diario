# frozen_string_literal: true

class LearningObjectivesAndSkillsCsvImporter
  attr_reader :records, :step, :modes_by_grade,
              :imported_count, :removed_count, :errors

  def initialize(records:, step:, modes_by_grade:)
    @records = records
    @step = step
    @modes_by_grade = modes_by_grade
    @imported_count = 0
    @removed_count = 0
    @errors = []
  end

  def import
    ActiveRecord::Base.transaction do
      remove_existing_for_replace_grades
      process_records

      raise ActiveRecord::Rollback if errors.any?
    end

    errors.empty?
  end

  private

  def remove_existing_for_replace_grades
    replace_grades = modes_by_grade.select { |_, mode| mode == 'replace' }.keys

    replace_grades.each do |grade|
      remove_grade_from_existing(grade)
    end
  end

  # Para cada registro que contém a série sendo substituída:
  # - Se pertence APENAS a essa série → apaga o registro
  # - Se pertence a outras séries também → remove só essa série do array
  def remove_grade_from_existing(grade)
    scope = LearningObjectivesAndSkill.where(step: step).where('? = ANY(grades)', grade)

    scope.find_each do |record|
      remaining_grades = record.grades - [grade]

      if remaining_grades.empty?
        record.delete
      else
        record.update_columns(grades: remaining_grades)
      end

      @removed_count += 1
    end
  end

  def process_records
    records.each_with_index do |record_attrs, index|
      objective = LearningObjectivesAndSkill.new(record_attrs)

      if objective.save
        @imported_count += 1
      else
        @errors << {
          row: index + 1,
          code: record_attrs[:code],
          messages: objective.errors.full_messages
        }
      end
    end
  end
end
