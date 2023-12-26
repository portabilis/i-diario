class CreateMultipleContents
  attr_accessor :lessons_to_create, :base_content

  def initialize(lessons_to_create, base_content)
    @lessons_to_create = lessons_to_create
    @base_content = base_content
  end

  def call
    create_multiple
  end

  private

  def create_multiple
    ActiveRecord::Base.transaction do
      lessons_to_create.each do |class_number|
        discipline_content = base_content.dup
        discipline_content.content_record = base_content.content_record.dup
        discipline_content.class_number = class_number
        discipline_content.save
      end
    end
  end
end
