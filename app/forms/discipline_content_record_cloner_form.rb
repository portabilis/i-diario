class DisciplineContentRecordClonerForm< ApplicationRecord
  has_no_table

  attr_accessor :discipline_content_record_id, :teacher

  validates :discipline_content_record_id, presence: true
  has_many :discipline_content_record_item_cloner_form
  accepts_nested_attributes_for :discipline_content_record_item_cloner_form, allow_destroy: true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          @classrooms = Classroom.where(id: discipline_content_record_item_cloner_form.map(&:classroom_id).uniq)

          discipline_content_record_item_cloner_form.each_with_index do |item, index|
            @current_item_index = index

            new_content_record = discipline_content_record.dup
            new_content_record.teacher_id = teacher.id
            new_content_record.content_record = discipline_content_record.content_record.dup
            new_content_record.content_record.teacher = teacher
            # `contents` is a deferred association so the original association is prepended with `original_`
            new_content_record.content_record.original_contents = discipline_content_record.content_record.contents
            new_content_record.content_record.classroom = @classrooms.find_by_id(item.classroom_id)
            new_content_record.content_record.record_date = item.record_date

            new_content_record.save!
          end

          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s

        message.slice!("A validação falhou: ")
        message.slice!("Disciplina ")

        errors.add(:classroom_id, "Turma #{e.record.content_record.try(:classroom)}: #{message}")
        discipline_content_record_item_cloner_form[@current_item_index].errors.add(:classroom_id, message)

        return false
      end
    end
  end

  def discipline_content_record
    @discipline_content_record ||= DisciplineContentRecord.find(discipline_content_record_id)
  end
end
