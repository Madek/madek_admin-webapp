module BatchReencoding
  extend ActiveSupport::Concern

  MEDIA_TYPES = [:audio, :video].freeze
  LOCK_KEY = 'global_lock_for_batch_reencoding'.freeze
  LOCK_MSG = 'Locked by another user! Wait 5 minutes.'.freeze

  included do

    def batch_reencoding
      return fail_global_lock unless ensure_global_lock

      if (in_progress = ZencoderJob.where(state: :submitted).count).positive?
        level = in_progress > 1000 ? :error : :info
        flash[level] =  "There is currently #{in_progress} Zencoder
                        #{'Job'.pluralize(in_progress)} in progress."
      end

      @missing_formats = missing_formats_counts
    end

    def batch_reencode
      respond_to do |format|
        format.json do
          params = batch_reencode_params
          formats = params[:formats]
          limit = params[:limit] || Settings.zencoder_test_mode ? 1 : 100
          start = params[:start_time]

          # fail if already locked for another user,
          # otherwise lock for the current user
          return fail_global_lock unless ensure_global_lock
          set_global_lock

          batch_reencode_missing_formats(formats, limit, start)

          # send a 'wait' command if we hit the rate limit
          if (msg = should_wait_for_zencoder_ratelimit)
            return render(status: 420, plain: "WAIT! (Rate Limit?) \n\n#{msg}")
          end

          # send updated counts so client knows to continue
          render status: 200, json: missing_formats_counts(formats, start)
        end
      end
    end

  end

  private

  def set_global_lock
    cache_store.fetch(LOCK_KEY, expires_in: 5.minutes) { session[:session_id] }
  end

  def get_global_lock
    cache_store.fetch(LOCK_KEY)
  end

  def ensure_global_lock
    !get_global_lock || get_global_lock == session[:session_id]
  end

  def fail_global_lock
    render(status: 423, plain: LOCK_MSG)
  end

  def batch_reencode_params
    p = {
      start_time: timestamp_param,
      understood: params.permit(:understood)[:understood] == '1',
      formats: params.permit(formats: conversion_profiles.values.flatten)
        .fetch(:formats, [])
        .map { |k, v| k.to_sym if v == '1' }.compact
    }
    if p[:formats].empty?
      raise ActionController::ParameterMissing, 'no formats!'
    end
    raise Errors::ForbiddenError, 'must accept warning!' unless p[:understood]
    p
  end

  def timestamp_param
    Time.at(params.permit(:start_time)[:start_time].to_i).utc
  end

  # query missing
  def media_files_missing_formats(profiles = nil, start_time = nil)
    profiles ||= conversion_profiles

    # allow formats as flat list, but match to audio/video:
    if profiles.is_a?(Array)
      profiles = conversion_profiles.map { |k, v| [k, v & profiles] }.to_h
    end

    MediaFile
      .with_missing_conversions(profiles)
      .with_no_jobs_after(start_time || Time.now.utc)
  end

  # data for form
  def missing_formats_counts(formats = [], start = nil)
    conversion_profiles.map do |type, profiles|
      profiles.map do |profile|
        next if formats.any? and !formats.include?(profile)
        count = media_files_missing_formats([profile], start).count
        [profile, count] unless count.zero?
      end.compact.to_h
    end.reduce(&:merge)
  end

  # do 1 batch of re-encoding
  def batch_reencode_missing_formats(formats, limit, start_time)
    missing = media_files_missing_formats(formats, start_time).limit(limit)
    return unless missing.count.positive?
    missing.each { |mf| encode(mf, only_missing: true) }
  end

  def encode(media_file, only_missing: false)
    ActiveRecord::Base.transaction do
      media_file.previews.destroy_all unless only_missing
      profiles = only_missing ? media_file.missing_profiles : false
      next true if only_missing and profiles.empty?
      ZencoderRequester.new(media_file, only_profiles: profiles).process
    end
  end

  def conversion_profiles
    @_conversion_profiles ||= MEDIA_TYPES.map do |type|
      [type, Settings.send("zencoder_#{type}_output_formats").to_h.keys]
    end.to_h
  end

  # MOCK
  def should_wait_for_zencoder_ratelimit
    # should look at the request from the last time and check if we should wait
    # ZencoderJob.where…

    # very simple version:
    ZencoderJob.order(:updated_at).last.try(:error)
  end

end
