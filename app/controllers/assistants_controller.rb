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
      err, res = execute_sql_sandboxed(query)
      query_time = Time.now.utc - start_time
    end
    render locals: {
      query: query, pg_error: err, pg_results: res, query_time: query_time
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

end
