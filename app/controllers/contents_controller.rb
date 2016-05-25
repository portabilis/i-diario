class ContentsController < ApplicationController
  respond_to :json


  def index
    if params[:fetch_for_discipline_records]
      teacher = current_teacher
      classroom = Classroom.find(params[:classroom_id])
      discipline = Discipline.find(params[:discipline_id])
      date = params[:date]
      return unless teacher && classroom && discipline && date
      @contents = ContentsForDisciplineRecordFetcher.new(teacher, classroom, discipline, date).fetch
    elsif params[:fetch_for_knowledge_area_records]
      teacher = current_teacher
      classroom = Classroom.find(params[:classroom_id])
      knowledge_area = KnowledgeArea.find(params[:knowledge_area_id])
      date = params[:date]
      return unless teacher && classroom && knowledge_area && date
      @contents = ContentsForKnowledgeAreaRecordFetcher.new(teacher, classroom, knowledge_area, date).fetch
    else
      @contents = apply_scopes(Content).ordered
    end
    respond_with(@contents)
  end
end
