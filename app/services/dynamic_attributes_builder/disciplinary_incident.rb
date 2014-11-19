module DynamicAttributesBuilder
  class DisciplinaryIncident < Base

    private

    def columns
      @model.columns.select do |column|
        %w(student_name, date, kind, description).include?(column)
      end
    end
  end
end
