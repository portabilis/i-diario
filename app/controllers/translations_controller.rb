class TranslationsController < ApplicationController
  def form
    @groups = Translation.groups
    @translations = Translation.all
    @subgroups_by_group = @groups.each_with_object({}) do |group, hash|
      hash[group] = Translation.subgroups(group)
    end

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
