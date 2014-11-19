module DynamicAttributesBuilder
  class Base
    def initialize(model)
      @model = model
      @fields = build_field_infos_collection
    end

    def each
      @fields.each do |field|
        yield field
      end
    end

    private

    def build_field_infos_collection
      columns.inject({}) do |result, column|
        column_name = column.name.to_sym

        result[column_name] = {
          :name => @model.human_attribute_name(column_name),
          :type => column_type(column),
          :options => enumeration(column)
        }

        result
      end
    end

    def columns
      @model.columns
    end

    def column_type(column)
      if @model.enumerations[column.name.to_sym].present?
        :enumeration
      elsif is_relation?(column)
        :relation
      elsif %w[integer decimal].include?(column.type)
        :integer
      else
        column.type
      end
    end

    def is_relation?(column)
      @foreing_keys ||= @model.reflect_on_all_associations.map(&:foreign_key)
      @foreing_keys.include?(column.name)
    end

    def enumeration(column)
      enumeration = @model.enumerations[column.name.to_sym]

      return nil if enumeration.blank?

      @model.enumerations[column.name.to_sym].to_a.inject({}) do |result, collection|
        result.merge(collection.last => collection.first)
      end
    end
  end
end
