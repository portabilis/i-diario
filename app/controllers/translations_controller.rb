class TranslationsController < ApplicationController
  def form
    @groups = Translation.groups
    @translations = Translation.all

    authorize @translations
  end

  def save
    authorize Translation.new

    params[:translations].each do |id, translation|
      Translation.find(id).update!(translation: translation)
    end

    flash[:success] = 'Dicionário de termos da BNCC foi atualizado com sucesso.'

    redirect_to :translations
  end
end
