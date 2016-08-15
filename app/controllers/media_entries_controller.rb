class MediaEntriesController < ApplicationController
  def index
    @media_entries = MediaEntry.unscoped.ordered.page(params[:page]).per(16)
    filter
  end

  def show
    @media_entry = MediaEntry.unscoped.find(params[:id])
  end

  private

  def filter
    if params[:search_term].present?
      @media_entries = @media_entries.search_with(params[:search_term])
    end
    if (param_value = params[:filter].try(:[], :is_published)).present?
      scope_name = param_value == '1' ? :published : :not_published
      @media_entries = @media_entries.send(scope_name)
    end
  end
end
