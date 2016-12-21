class MediaFilesController < ApplicationController
  include Concerns::BatchReencoding

  SORTERS = %i(
    created_at media_type uploader size
  ).freeze

  helper_method :conversion_profiles

  def index
    @media_types = MediaFile.distinct.pluck(:media_type).sort
    @extensions = MediaFile.distinct.pluck(:extension).reject(&:empty?).sort
    @sorters = prepare_sorters
    @media_files = MediaFile
                    .includes(:media_entry, uploader: [:person])
                    .page(params[:page])
                    .per(16)
    filter
    sort
  end

  def show
    @media_file = MediaFile.find(params[:id])
    @media_entry = MediaEntry.unscoped.find(@media_file.media_entry_id)
    @zencoder_jobs = @media_file.zencoder_jobs if @media_file.previews_zencoder?
  end

  def reencode
    media_file = MediaFile.find(params[:id])
    encode(media_file)
    redirect_to media_file_path(media_file), flash: {
      info: 'The Media File was successfully sent to reencode.'
    }
  rescue => e
    render plain: e.message
  end

  def reencode_missing # simple batch request ALL missing
    limit = Settings.zencoder_test_mode ? 10 : 1000
    @media_files = MediaFile
                     .with_missing_conversions(conversion_profiles)
                     .where('zencoder_jobs.created_at < ?', params[:timestamp])
                     .rewhere(
                       media_files: { media_type: filter_value(:media_type) }
                     )
                     .limit(limit)
    media_files_count = @media_files.to_a.size

    flash[:info] = "Batch re-encoding is in progress: #{media_files_count} \
                    #{'file'.pluralize(media_files_count)}, (#{total_size} GB)"

    @media_files.each do |mf|
      unless encode(mf, only_missing: true)
        flash[:error] = mf.zencoder_jobs.first.try(:error)
      end
    end

    redirect_to :back
  end

  private

  def filter
    sanitize_filter_params
    filter_by_column
    if term = filter_value(:search_term, '').presence
      term.strip!
      @media_files =
        if UUIDTools::UUID_REGEXP =~ term
          @media_files.with_id_or_uploader_id(term)
        else
          @media_files.with_filename_like(term)
        end
    end
    filter_by_conversion_status
  end

  def filter_by_column
    %i(media_type extension).each do |column|
      if filter_value(column, '').present?
        @media_files = @media_files.where(column => params[:filter][column])
      end
    end
  end

  def filter_by_conversion_status
    @media_files =
      case filter_value(:conversion_status, '')
      when 'missing'
        in_progress = ZencoderJob.where(state: :submitted).count
        flash[:info] =
          "There is already #{in_progress} Zencoder
           #{'Job'.pluralize(in_progress)} in progress."
        @media_files.with_missing_conversions(conversion_profiles)
      when 'failed'
        @media_files.with_failed_conversions
      else
        @media_files
      end
  end

  def sanitize_filter_params
    params.fetch(:filter, {}).each do |key, value|
      if value.empty? || value == '(all)'
        params[:filter] = params[:filter].except(key)
      end
    end
  end

  def sort
    sort_param, dir = params
                        .fetch(:sort_by, '')
                        .match(/(.+)_(asc|desc)/)
                        .captures

    @media_files =
      if sort_param == 'uploader'
        @media_files.sort_by_uploader(dir)
      else
        @media_files.order(sort_param => dir)
      end
  rescue
    default_sorting
  end

  def default_sorting
    @media_files = @media_files.order(:created_at)
  end

  def total_size
    (@media_files.pluck('media_files.size').sum.to_f / 1024 / 1024 / 1024)
      .round(2)
  end

  def prepare_sorters
    [].tap do |sorters|
      SORTERS.each do |type|
        %i(asc desc).each do |dir|
          sorters << ["#{type} (#{dir})", [type, dir].join('_')]
        end
      end
    end
  end
end
