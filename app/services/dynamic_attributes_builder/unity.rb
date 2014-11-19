module DynamicAttributesBuilder
  class Unity < Base

    private

    def columns
      @model.columns.select do |column|
        'name' == column.name
      end
    end
  end
end
