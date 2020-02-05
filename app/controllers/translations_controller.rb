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

    Rails.cache.delete(Translation::CACHE_KEY)

    redirect_to :translations
  end
end
