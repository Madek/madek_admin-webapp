class Test::AuditsController < ApplicationController
  self.admin_permission_key = :any

  def test1
  end

  def test2
    Group.create!(name: "Test Group")
    render(plain: "Submit OK")
  end

  def test3
    raise "Something went wrong"
  end

  # Regression test for #946: catches a genuine DB-level abort locally (like
  # a real controller's rescue block would), calls `redirect_to` -- which
  # should heal the connection -- and then writes to the DB again. If the
  # heal didn't happen, this write silently fails to persist (connection
  # still aborted at that point), which the spec observes as a missing
  # Group/AuditedChange row, without needing the request itself to crash.
  def test4
    begin
      ActiveRecord::Base.connection.execute('SELECT 1/0')
    rescue ActiveRecord::StatementInvalid
    end

    redirect_to '/admin/test/audits/test1'

    begin
      Group.create!(name: 'Test Group After Redirect')
    rescue ActiveRecord::StatementInvalid
    end
  end
end
