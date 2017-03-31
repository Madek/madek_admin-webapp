require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Dashboard' do
  scenario 'Statistics' do
    visit root_path

    expect(page).to have_css '.statistics a'

    within '.statistics' do
      expect_link "#{drafts_count} drafts",
                  media_entries_url(filter: { is_published: 0 })
      expect_link "#{MediaEntry.count} entries", media_entries_url
      expect_link "#{Collection.count} sets", collections_url
      expect_link "#{FilterSet.count} filtersets", filter_sets_url
      expect_link "#{MediaFile.count} mediafiles", media_files_url
      expect_link "#{MetaDatum.count} metadata", meta_datums_url
      expect_link "#{Keyword.count} keywords", keywords_url
      expect_link "#{Person.count} people", people_url
      expect_link "#{Vocabulary.count} vocabularies", vocabularies_url
      expect_link "#{MetaKey.count} metakeys", meta_keys_url
      expect_link "#{Context.count} contexts", contexts_url
      expect_link "#{User.count} users", users_url
      expect_link "#{Group.count} groups", groups_url
      expect_link "#{ApiClient.count} api-clients", api_clients_url
    end
  end

  def drafts_count
    MediaEntry.unscoped.not_published.count
  end

  def expect_link(text, path)
    expect(page).to have_link(text, path)
  end
end
