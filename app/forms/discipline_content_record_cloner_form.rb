class DisciplineContentRecordClonerForm
  include ActiveModel::Model

  attr_accessor :classroom_ids, :discipline_content_record_id

  validates :discipline_content_record_id, :classroom_ids, presence: true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          Classroom.where(id: classroom_ids.split(",")).each do |classroom|
            new_content_record = discipline_content_record.dup
            new_content_record.content_record = discipline_content_record.content_record.dup
            new_content_record.content_record.contents = discipline_content_record.content_record.contents
            new_content_record.content_record.classroom = classroom
            new_content_record.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        message.slice!("Disciplina ")
        message = "Turma #{e.record.content_record.try(:classroom)}: #{message}"
        errors.add(:classroom_ids, message)
        return false
      end
    end
  end

  def discipline_content_record
    @discipline_content_record ||= DisciplineContentRecord.find(discipline_content_record_id)
  end
end
