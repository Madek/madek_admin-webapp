# rubocop:disable Metrics/MethodLength
class AssistantsController < ApplicationController
  layout '_base', only: %i(sql_reports)

  def show
    sql_snippets if feature_toggle_sql_reports
    render locals: { sections: [
      (:sql_reports if feature_toggle_sql_reports)
    ].compact }
  end

  def batch_translate
    @langs = AppSetting.available_locales
    @meta_keys = MetaKey.all.reorder(:id)
    @context_keys = ContextKey.all
    @post_path = batch_translate_assistant_path
  end

  def batch_translate_update
    langs = AppSetting.available_locales
    fields = %i(label description hint).map(&:to_s).map(&:pluralize)
                                       .map { |f| { f => langs } }
    permitted_fields = [:id, { _original: fields }].concat(fields)
    num_updated = { meta_keys: 0, context_keys: 0 }
    err = nil

    # NOTE: params only work wrapped as JSON! (problem between apache and Rack)
    #       for relative simplicity, the form-encoded data is left as a string
    posted = ActionController::Parameters.new(
      Rack::Utils.parse_nested_query(params['formString']))

    ActiveRecord::Base.transaction do
      begin
        [MetaKey, ContextKey].each do |klass|
          type = klass.name.underscore.pluralize.to_sym
          rows = posted.permit(type => permitted_fields).fetch(type, [])
          rows.each do |row|
            if _has_changes = row[:_original].any? { |k, v| v != row[k] }
              klass.find(row[:id]).update!(row.except('_original'))
              num_updated[type] += 1
            end
          end
        end
      rescue => e
        err = e # dont swallow errors, re-raise later!
        raise ActiveRecord::Rollback
      end
    end
    raise err if err

    flash[:success] = "Updated #{num_updated[:meta_keys]} MetaKey(s) " \
                      "and #{num_updated[:context_keys]} ContextKey(s)"
    flash.keep
    render json: {}, status: 200
  end

  def sql_reports
    raise ForbiddenError, 'Feature not enabled!' unless feature_toggle_sql_reports
    query = params.permit(:query).fetch(:query, 'SELECT 1').strip.presence
    if query && params[:do] != 'Edit'
      start_time = Time.now.utc
      err, res = execute_sql_sandboxed(query)
      query_time = Time.now.utc - start_time
    end
    render locals: {
      query: query, pg_error: err, pg_results: res, query_time: query_time,
      sql_snippets: sql_snippets
    }
  end

  def execute_sql_sandboxed(query)
    pg_err = nil
    pg_res = nil
    begin
      ActiveRecord::Base.transaction do
        pg_res = ActiveRecord::Base.connection.execute(query)
        raise ActiveRecord::Rollback
      end
    rescue => e
      pg_err = e
    end
    [pg_err, pg_res.as_json]
  end

  private

  def sql_snippets
    @sql_snippets ||= YAML.load_file(
      Rails.root.join('config', 'sql_snippets.yml')
    )['sql_snippets'].map do |snippet|
      [
        snippet['title'],
        prepare_query(snippet['query'])
      ]
    end
  end

  def prepare_query(query)
    query.gsub(/(:[a-z_]+:)/) do |match|
      send(match.delete(':'))
    end
  rescue NoMethodError => e
    "-- <code>!! MISSING_QUERY_FRAGMENT: implement [#{e.name}] method</code>"
  end

  def preview_types
    query = []
    Madek::Constants::THUMBNAILS.compact.each_key do |thumb_size|
      query << preview_type(:image, "previews.thumbnail = '#{thumb_size}'")
    end
    Settings.zencoder_video_output_formats.to_h.each_key do |label|
      query << preview_type(:video, "previews.conversion_profile = '#{label}'")
    end
    query.join(' OR ')
  end

  def preview_type(media_type, condition)
    %(NOT EXISTS (
      SELECT NULL FROM media_files AS mf
      INNER JOIN previews ON previews.media_file_id = mf.id
      WHERE mf.id = media_files.id AND previews.media_type = '#{media_type}'
      AND #{condition}
    ))
  end

end
# rubocop:enable Metrics/MethodLength
