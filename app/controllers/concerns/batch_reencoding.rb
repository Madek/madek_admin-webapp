module Concerns
  module BatchReencoding
    extend ActiveSupport::Concern

    LOCK_KEY = 'global_lock_for_batch_reencoding'.freeze
    LOCK_MSG = 'Locked by another user! Wait 5 minutes.'.freeze

    included do

      def batch_reencoding
        return fail_global_lock unless ensure_global_lock

        if ((in_progress = ZencoderJob.where(state: :submitted).count) > 0)
          level = in_progress > 1000 ? :error : :info
          flash[level] =  "There is currently #{in_progress} Zencoder
                          #{'Job'.pluralize(in_progress)} in progress."
        end

        @missing_formats = missing_formats
      end

      def batch_reencode
        respond_to do |format|
          format.json do
            params = batch_reencode_params
            limit = params[:limit] || Settings.zencoder_test_mode ? 10 : 1000

            # fail if already locked for another user,
            # otherwise lock for the current user
            return fail_global_lock unless ensure_global_lock
            set_global_lock

            # NOTE: this shouldn't take too long; and raise errors if any
            reencode_missing_formats(params[:formats], limit)

            # send a 'wait' command if we hit the rate limit
            if should_wait_for_zencoder_ratelimit
              return render(status: 420, plain: 'Waiting because of Rate Limit')
            end

            # send updated counts so client knows to continue
            render status: 200, json: missing_formats(params[:formats])
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
        understood: params.permit(:understood)[:understood] == '1',
        formats: params.permit(formats: missing_formats.keys).fetch(:formats, [])
          .map { |k, v| k if v == '1' }.compact
      }
      if p[:formats].empty?
        raise ActionController::ParameterMissing, 'no formats!'
      end
      raise Errors::ForbiddenError, 'must accept warning!' unless p[:understood]
      p
    end

    # MOCK
    def reencode_missing_formats(formats, limit)
      puts [formats, limit]
      sleep 3
      # @media_files = MediaFile
      #                  .with_missing_conversions(audio_codecs)
      #                  .where('zencoder_jobs.created_at < ?', params[:timestamp])
      #                  .limit(limit)
      # media_files_count = @media_files.to_a.size
      #
      # @media_files.each do |mf|
      #   unless encode(mf, only_missing: true)
      #     flash[:error] = mf.zencoder_jobs.first.try(:error)
      #   end
      # end
      true
    end

    # MOCK
    def missing_formats(formats = nil)
      missing = {
        mp3: 178,
        mp4_HD: 12345,
        webm_HD: 12345
      }
      !formats ? missing : missing.select { |k, v| formats.include?(k.to_s) }
    end

    # MOCK
    def should_wait_for_zencoder_ratelimit
      # should look at the request from the last time and check if we should wait
      # ZencoderJob.where…
      true # rand < 0.3
    end
  end
end
