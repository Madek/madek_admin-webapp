class Test::AuditsController < ApplicationController
  def test1
  end

  def test2
    Group.create!(name: "Test Group")
    render(plain: "Submit OK")
  end

  def test3
    raise "Something went wrong"
  end
end
