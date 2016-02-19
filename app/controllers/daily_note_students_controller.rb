class DailyNoteStudentsController < ApplicationController

  respond_to :json, only: [:index]

  def index
    @daily_note_students = apply_scopes(DailyNoteStudent).ordered

    respond_with @daily_note_students
  end
end
