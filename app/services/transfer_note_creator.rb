class TransferNoteCreator
  attr_reader :daily_note_students

  def initialize(transfer_note, daily_note_students_attributes)
    @transfer_note = transfer_note
    @attributes = Array(daily_note_students_attributes&.values)
    @daily_note_students = build_daily_note_students
  end

  def save
    transfer_note_valid = @transfer_note.valid?
    # map (não all?) para popular os erros em todos os inputs inválidos, não só no primeiro
    students_valid = @daily_note_students.map(&:valid?).all?
    has_any_note = @daily_note_students.any? { |record| record.attributes['note'].present? }

    # adicionado após o valid? acima, senão seria limpo na próxima validação
    @transfer_note.errors.add(:base, :at_least_one_note_required) unless has_any_note

    return false unless transfer_note_valid && students_valid && has_any_note

    persist!

    true
  end

  private

  def persist!
    ActiveRecord::Base.transaction do
      @transfer_note.save!

      @daily_note_students.each do |record|
        record.assign_attributes(transfer_note_id: @transfer_note.id)
        record.save!
      end
    end
  end

  def build_daily_note_students
    existing = existing_daily_note_students

    @attributes.map do |data|
      key = [data[:daily_note_id].to_s, data[:student_id].to_s]
      record = (existing[key] ||
        DailyNoteStudent.new(daily_note_id: data[:daily_note_id], student_id: data[:student_id])).localized

      record.assign_attributes(
        note: data[:note],
        # não usar nil: o proxy do i18n_alchemy chama Date._strptime no valor e quebra com nil;
        # a string vazia passa direto e o ActiveRecord a converte para nil (des-descarta o registro)
        discarded_at: '',
        active: true
      )

      record
    end
  end

  # Pré-carrega em uma única query os DailyNoteStudent existentes das notas enviadas,
  # indexados por [daily_note_id, student_id]. A ordenação + ||= mantêm, por chave, a linha
  # kept de maior id (para não colidir no des-descarte, já que o índice único é parcial).
  def existing_daily_note_students
    return {} if @attributes.empty?

    records = {}
    DailyNoteStudent.with_discarded
                    .where(daily_note_id: @attributes.map { |data| data[:daily_note_id] },
                           student_id: @attributes.map { |data| data[:student_id] })
                    .order('discarded_at ASC NULLS FIRST, id DESC')
                    .each { |record| records[[record.daily_note_id.to_s, record.student_id.to_s]] ||= record }
    records
  end
end
