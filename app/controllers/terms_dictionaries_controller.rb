class TermsDictionariesController < ApplicationController
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

  protected
  def resource_params
    params.require(:terms_dictionary).permit(:presence_identifier_character)
  end
end
