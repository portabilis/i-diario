class StudentDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2_remote(name)
    students = Student.by_name(name).ordered.map { |student|
      { id: student.id, description: student.to_s }
    }

    students.to_json
  end

  def self.data_for_search_autocomplete(students)
    structured_students = students.map do |student|
      { id: student.id, value: student.to_s }
    end
    structured_students.to_json
  end
end
