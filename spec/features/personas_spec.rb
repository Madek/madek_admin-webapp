# This feature is solely used for conveniently extending the personas dump
# data via:
# 1. Create what you need via factories inside this spec.
# 2. Run the feature spec.
# 3. Dump the data into a new version of personas dump.
#
# IMPORTANT: Don't forget to remove the binding.pry and keep the spec passing for CI.

require 'spec_helper'
require 'spec_helper_feature'

feature 'Modify personas dump' do
  scenario 'do' do
    # User.all.map do |user|
    #   FactoryBot.create(:media_entry_with_title, responsible_user: user, deleted_at: Time.now)
    #   FactoryBot.create(:collection_with_title, responsible_user: user, deleted_at: Time.now)
    # end
  end
end
