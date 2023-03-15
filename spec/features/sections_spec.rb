require 'spec_helper'
require 'spec_helper_feature'

feature 'Sections' do

  let(:meta_key) { create :meta_key_keywords }
  let(:keyword_1) { create :keyword, term: "Karakal", meta_key: meta_key }
  let(:keyword_2) { create :keyword, term: "Jaguar", meta_key: meta_key }
  let(:collection_1) { create :collection_with_title, title: "Cats" }

  scenario 'Configure sections (happy path)', browser: :firefox do
    keyword_1
    keyword_2

    visit app_settings_path

    # Configure meta key
    within "[data-id='section_meta_key_id']" do
      click_link 'Edit'
    end

    fill_in 'app_setting[section_meta_key_id]', with: meta_key.id
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within "[data-id='section_meta_key_id']" do
      expect(page).to have_content(meta_key.id)
      click_on 'View/edit section labels'
    end

    # Index
    expect(all('table[data-test-id=sections-table] tbody tr[data-id] td:first-child').map(&:text)).to eq ['Jaguar', 'Karakal']
    within "tr[data-id='#{keyword_1.id}']" do
      expect(page).to have_text("Karakal Create", normalize_ws: true)
      click_link 'Create'
    end

    # Create
    fill_in 'section_labels_de', with: "Karakal"
    fill_in 'section_labels_en', with: "Caracal"
    fill_in 'section[color]', with: "pink"
    fill_in 'section[index_collection_id]', with: collection_1.id
    click_button 'Save'

    within "tr[data-id='#{keyword_1.id}']" do
      expect(page).to have_text("Karakal Karakal Caracal pink Cats Edit", normalize_ws: true)
      click_link 'Edit'
    end

    # Edit
    fill_in 'section_labels_de', with: "Floppa"
    fill_in 'section_labels_en', with: "Floppa"
    fill_in 'section[color]', with: "beige"
    fill_in 'section[index_collection_id]', with: ""
    click_button 'Save'

    within "tr[data-id='#{keyword_1.id}']" do
      expect(page).to have_text("Karakal Floppa beige Edit", normalize_ws: true)
    end

    # Delete
    within "tr[data-id='#{keyword_1.id}']" do
      accept_confirm do
        click_link 'Remove'
      end
    end
    
    within "tr[data-id='#{keyword_1.id}']" do
      expect(page).to have_text("Karakal Create", normalize_ws: true)
    end
    
  end
end