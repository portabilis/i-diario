class AvaliationRecoveryLowestNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    step_id = (params[:filter] || []).delete(:by_step_id)

    @avaliation_recovery_lowest_notes = apply_scopes(AvaliationRecoveryLowestNote)
                                            .includes(
                                              recovery_diary_record: [
                                                :unity,
                                                :classroom,
                                                :discipline
                                              ]
                                            )
                                            .by_classroom_id(current_user_classroom)
                                            .by_discipline_id(current_user_discipline)
                                            .ordered

    if step_id.present?
      @avaliation_recovery_lowest_notes = @avaliation_recovery_lowest_notes.by_step_id(
        current_user_classroom,
        step_id
      )
      params[:filter][:by_step_id] = step_id
    end

    authorize @avaliation_recovery_lowest_notes
  end

  def new
    @avaliation_recovery_lowest_note = AvaliationRecoveryLowestNote.new.localized
    @avaliation_recovery_lowest_note.build_recovery_diary_record
    @avaliation_recovery_lowest_note.recovery_diary_record.unity = current_unity

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(avaliation_recovery_lowest_note_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create; end

  def edit; end

  def update; end

  def destroy; end
end
