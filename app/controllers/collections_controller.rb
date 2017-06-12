class CollectionsController < ApplicationController
  before_action :find_collection, except: [:index]

  def index
    @collections = Collection.page(params[:page]).per(16)
    @collections = @collections.by_title(params[:search_terms]) \
      if params[:search_terms].present?
  end

  def show
  end

  def media_entries
    @media_entries = @collection.media_entries.page(params[:page]).per(16)
  end

  def collections
    @collections = @collection.collections.page(params[:page]).per(16)
  end

  private

  def find_collection
    @collection = Collection.find params[:id]
    @user = @collection.responsible_user
  end
end
