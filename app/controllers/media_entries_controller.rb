class MediaEntriesController < ApplicationController
  include HandleIsDeletedParam

  def index
    # Default scope for admin webapp.
    # It differs from the default scope in the model.
    @media_entries = MediaEntry.unscoped.not_deleted

    if params[:filter].present?
      @media_entries = filter(@media_entries.unscoped)
    end

    @media_entries = @media_entries.ordered.page(page_params).per(16)
  end

  def show
    @media_entry = MediaEntry.unscoped.find_by_id_or_custom_url_id_or_raise(params[:id])
  end

  def restore
    @media_entry = MediaEntry.unscoped.find_by_id_or_custom_url_id_or_raise(params[:id])
    @media_entry.update!(deleted_at: nil)
    flash[:success] = 'Media-Entry restored successfully.'
    redirect_to media_entry_path(@media_entry)
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
    media_entries = handle_is_deleted_param(media_entries)
    media_entries
  end
end
