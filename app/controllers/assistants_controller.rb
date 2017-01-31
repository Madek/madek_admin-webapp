class AssistantsController < ApplicationController

  layout '_base', only: [:sql_reports]

  def show
    render locals: { sections: [
      (:sql_reports if feature_toggle_sql_reports)
    ].compact }
  end

  def sql_reports
    raise ForbiddenError, 'Feature not enabled!' unless feature_toggle_sql_reports
    query = params.permit(:query).fetch(:query, 'SELECT 1').strip.presence
    if query && params[:do] != 'Edit'
      start_time = Time.now.utc
      pg_results = execute_sql_sandboxed(query)
      query_time = Time.now.utc - start_time
    end
    render locals: { query: query, pg_results: pg_results, query_time: query_time }
  end

  def execute_sql_sandboxed(query)
    pg_results = nil
    begin
    ActiveRecord::Base.transaction do
      pg_results = ActiveRecord::Base.connection.execute(query)
      raise ActiveRecord::Rollback
    end
    rescue => e
      pg_results = e
    end
    pg_results.as_json
  end

  private

  def feature_toggle_sql_reports
    Settings.feature_toggles.admin_sql_reports == 'on my own risk'
  end

end
