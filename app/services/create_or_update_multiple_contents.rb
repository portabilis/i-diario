class CreateOrUpdateMultipleContents
  attr_accessor :lessons_to_create, :base_content
  attr_reader :create

  def initialize(lessons_to_create, base_content, create)
    @lessons_to_create = lessons_to_create
    @base_content = base_content
    @create = create
  end

  def call
    return create_multiple if create

    update_multiple
  end

  private

  def create_multiple
    ActiveRecord::Base.transaction do
      lessons_to_create.each do |class_number|
        discipline_content = base_content.dup
        discipline_content.content_record = base_content.content_record.dup
        discipline_content.content_record.contents = base_content.content_record.contents.map(&:dup)
        discipline_content.class_number = class_number
        discipline_content.save
      end
    end
  end

  def update_multiple
    ActiveRecord::Base.transaction do
      lessons_to_create.each do |class_number|
        discipline_content = base_content.dup
        discipline_content.content_record = base_content.content_record.dup
        discipline_content.content_record.contents = base_content.content_record.contents.map(&:dup)
        discipline_content.class_number = class_number
        discipline_content.save
      end

      base_content.save
    end
  end
end
