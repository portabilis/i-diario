class ContentsController < ApplicationController
  respond_to :json

  def index
    @contents = Content.none
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
      knowledge_areas = KnowledgeArea.find(params[:knowledge_area_ids])
      date = params[:date]
      return unless teacher && classroom && knowledge_areas && date
      @contents = ContentsForKnowledgeAreaRecordFetcher.new(teacher, classroom, knowledge_areas, date).fetch
    elsif !params[:merge_objectives_by_code] || params[:filter][:by_description]
      @contents = apply_scopes(Content)
    elsif params[:filter][:start_with_description]
      @contents = Content.start_with_description(params[:filter][:start_with_description])
    end

    if params[:merge_objectives_by_code]
      @contents = @contents + ObjectivesToContentFetcher.fetch(params[:merge_objectives_by_code])
      @contents = @contents.map(&:description).uniq.sort.map{|description| { description: description }}
    end

    respond_with(@contents)
  end
end
