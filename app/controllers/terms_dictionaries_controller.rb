class TermsDictionariesController < ApplicationController
  after_action :clear_cache_current_terms_dictionary, only: :update

  def edit
    @terms_dictionaries = TermsDictionary.current

    authorize @terms_dictionaries
  end

  def update
    @terms_dictionaries = TermsDictionary.current
    @terms_dictionaries.attributes = resource_params

    authorize @terms_dictionaries

    if @terms_dictionaries.save
      respond_with @terms_dictionaries, location: edit_terms_dictionaries_path
    else
      render :edit
    end
  end

  def history
    @terms_dictionary = TermsDictionary.current

    authorize @terms_dictionary

    respond_with @terms_dictionary
  end

  private

  def resource_params
    params.require(:terms_dictionary).permit(:presence_identifier_character)
  end

  def clear_cache_current_terms_dictionary
    Rails.cache.delete("#{current_entity.id}_current_terms_dictionary")
  end
end
