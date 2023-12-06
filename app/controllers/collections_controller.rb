class CollectionsController < ApplicationController
  before_action :find_collection, except: [:index]

  def index
    @collections = Collection.page(page_params).per(16)
    @collections = filter(@collections)
  end

  def show
  end

  def media_entries
    @media_entries = @collection.media_entries.page(page_params).per(16)
  end

  def collections
    @collections = @collection.collections.page(page_params).per(16)
  end

  private

  def find_collection
    @collection = Collection.find params[:id]
    @user = @collection.responsible_user
    @delegation = @collection.responsible_user
    @responsible_entity = @user || @delegation
  end

  def filter(collections)
    if params[:search_terms].present?
      collections = collections.search_with(params[:search_terms])
    end
    if (param_value = params[:filter].try(:[], :responsible_entity_id)).present?
      validate_uuid!(param_value)
      collections = 
        collections.where(responsible_user_id: param_value)
        .or(collections.where(responsible_delegation_id: param_value))
    end
    if (param_value = params[:filter].try(:[], :creator_id)).present?
      validate_uuid!(param_value)
      collections = collections.where(creator_id: param_value)
    end
    collections
  end
end
