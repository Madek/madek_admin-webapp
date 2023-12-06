require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Collections' do
  let!(:collection_of_a_delegation) do
    create(:collection_with_title,
           responsible_delegation: create(:delegation),
           responsible_user: nil)
  end

  scenario 'Filtering by collection name' do
    visit collections_path
    fill_in 'search_terms', with: 'zhdk'
    click_button 'Apply'
    names = all('table tbody tr').map do |tr|
      expect(tr.find('th:first').text.downcase).to have_content 'zhdk'
    end
    expect(find_field('search_terms')[:value]).to eq 'zhdk'
    expect(names).to eq names.sort
  end

  scenario 'linking to Meta Datums list' do
    collection = Collection.first
    visit collection_path(collection)

    expect(page).to have_content collection.title

    click_link "Meta Datums: #{collection.meta_data.count}"

    expect(current_path).to eq meta_datums_path
    expect(page).to have_field('search_term', with: collection.id)
    expect(page).to have_select('search_by', selected: 'Collection ID')
    expect(page).to have_content "Meta Datums (#{collection.meta_data.count})"
  end

  scenario 'Searching for an entry of a delegation renders without error' do
    visit collections_path
    fill_in "search_terms", with: collection_of_a_delegation.title
    click_button 'Apply'
    expect(page).to have_css "tr[id='#{collection_of_a_delegation.id}']"
  end

  scenario 'Filtering by responsible_entity_id and creator_id attribute (user)', browser: :firefox do
    user = create(:user)
    collection = create(:collection,
                         creator: user,
                         responsible_delegation: nil,
                         responsible_user: user)

    visit collections_path

    fill_in "filter[responsible_entity_id]", with: user.id
    click_button 'Apply'
    expect(page).to have_css "table tr[id='#{collection.id}']"
    expect(all("table tr[id]").count).to eq 1
    expect(find("h1")).to have_content "Sets (1)"

    click_link 'Reset'

    fill_in "filter[creator_id]", with: user.id
    click_button 'Apply'
    expect(page).to have_css "table tr[id='#{collection.id}']"
    expect(all("table tr[id]").count).to eq 1
    expect(find("h1")).to have_content "Sets (1)"
  end

  scenario 'Filtering by responsible_entity_id (delegation)', browser: :firefox do
    delegation = create(:delegation)
    user = create(:user)
    collection = create(:collection,
                         creator: user,
                         responsible_delegation: delegation,
                         responsible_user: nil)

    visit collections_path

    fill_in "filter[responsible_entity_id]", with: delegation.id
    click_button 'Apply'
    expect(page).to have_css "table tr[id='#{collection.id}']"
    expect(all("table tr[id]").count).to eq 1
    expect(find("h1")).to have_content "Sets (1)"
  end

  scenario 'Show page of a collection from a delegation renders without error' do
    visit collection_path(collection_of_a_delegation)
    expect(page).to have_content collection_of_a_delegation.title
  end

  scenario 'Show page of a collection\'s entries from a delegation renders without error' do
    visit media_entries_collection_path(collection_of_a_delegation)
    expect(page).to have_content collection_of_a_delegation.title
  end
end
