class AssistantsController < ApplicationController

  layout '_base', only: [:sql_reports]

  def show
    sql_snippets if feature_toggle_sql_reports
    render locals: { sections: [
      (:sql_reports if feature_toggle_sql_reports)
    ].compact }
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

  def feature_toggle_sql_reports
    Settings.feature_toggles.admin_sql_reports == 'on my own risk'
  end

  def sql_snippets
    @sql_snippets ||= YAML.load_file(
      Rails.root.join('config', 'sql_snippets.yml')
    )['sql_snippets'].map do |snippet|
      [
        snippet['title'],
        [snippet['description'], prepare_query(snippet['query'])].join("\n\n")
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
