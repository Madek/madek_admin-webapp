class MediaEntriesController < ApplicationController
  def index
    @media_entries = MediaEntry.unscoped.ordered.page(page_params).per(16)
    @media_entries = filter(@media_entries)
  end

  def show
    @media_entry = MediaEntry.unscoped.find(params[:id])
  end

  private

  def filter(media_entries)
    if params[:search_term].present?
      media_entries = media_entries.search_with(params[:search_term])
    end
    if (param_value = params[:filter].try(:[], :is_published)).present?
      scope_name = param_value == '1' ? :published : :not_published
      media_entries = media_entries.send(scope_name)
    end
    if (param_value = params[:filter].try(:[], :responsible_entity_id)).present?
      validate_uuid!(param_value)
      media_entries = 
        media_entries.where(responsible_user_id: param_value)
        .or(media_entries.where(responsible_delegation_id: param_value))
    end
    if (param_value = params[:filter].try(:[], :creator_id)).present?
      validate_uuid!(param_value)
      media_entries = media_entries.where(creator_id: param_value)
    end
    media_entries
  end
end
