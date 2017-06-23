require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Dashboard' do
  scenario 'Resource Statistics' do
    visit root_path

    expect(page).to have_css '.statistics a'

    within '.statistics' do
      expect_link "#{drafts_count} drafts",
                  media_entries_path(filter: { is_published: 0 })
      expect_link "#{MediaEntry.count} entries", media_entries_path
      expect_link "#{Collection.count} sets", collections_path
      expect_link "#{MediaFile.count} mediafiles", media_files_path
      expect_link "#{MetaDatum.count} metadata", meta_datums_path
      expect_link "#{Keyword.count} keywords", keywords_path
      expect_link "#{Person.count} people", people_path
      expect_link "#{Vocabulary.count} vocabularies", vocabularies_path
      expect_link "#{MetaKey.count} metakeys", meta_keys_path
      expect_link "#{Context.count} contexts", contexts_path
      expect_link "#{User.count} users", users_path
      expect_link "#{Group.count} groups", groups_path
      expect_link "#{ApiClient.count} api-clients", api_clients_path
    end
  end

  scenario 'Showing link to Assistant section' do
    allow(Settings)
      .to receive_message_chain('feature_toggles.admin_sql_reports')
      .and_return('on my own risk')

    visit root_path

    expect(page).to have_link 'Go to the section', href: assistant_path

    allow(Settings)
      .to receive_message_chain('feature_toggles.admin_sql_reports')
      .and_return('')

    visit root_path

    expect(page).not_to have_link 'Go to the section', href: assistant_path
  end

  def drafts_count
    MediaEntry.unscoped.not_published.count
  end

  def expect_link(text, path)
    expect(page).to have_link(text, href: path)
  end
end
