module Concerns
  module BatchReencoding
    extend ActiveSupport::Concern

    included do
      def batch_reencoding
        if (in_progress = ZencoderJob.where(state: :submitted).count)
          flash[:info] =
            "There is currently #{in_progress} Zencoder
             #{'Job'.pluralize(in_progress)} in progress."
        end

        @missing_formats = missing_formats
      end

      def batch_reencode
        params = batch_reencode_params
        limit = params[:limit] || Settings.zencoder_test_mode ? 10 : 1000

        respond_to do |format|
          format.json do
            # this should directly raise any errors:
            reencode_missing_formats(params[:formats], limit)

            # send updated missing formats + counts so client knows to continue
            # NOTE: with the mock data the client will just try forever
            render json: missing_formats, status: 200
          end
        end
      end
    end

    private

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
    def missing_formats(only_formats = nil)
      missing = {
        mp3: 178,
        mp4_HD: 12345,
        webm_HD: 12345
      }
      !only_formats ? missing : missing.select { |k, v| formats.include?(k) }
    end

  end
end
