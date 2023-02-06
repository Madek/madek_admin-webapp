class MetaDatumsController < ApplicationController
  def index
    @meta_datums = MetaDatum.includes(:meta_key)
    filter
    @meta_datums = @meta_datums.page(page_params).per(16)
  end

  private

  def filter
    if (search_term = params[:search_term]&.strip).present?
      filter_method = {
        id: :with_id,
        string: :with_string,
        media_entry_id: :of_media_entry,
        collection_id: :of_collection,
        meta_key_id: :of_meta_key
      }.fetch(params[:search_by].to_sym)

      @meta_datums = @meta_datums.public_send(filter_method, search_term)
    end

    if (type = params[:type]).present?
      @meta_datums = @meta_datums.where(type: type)
    end
  end
end
