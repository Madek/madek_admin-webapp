require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Vocabularies' do
  let(:vocabulary) { create :vocabulary }

  scenario 'Editing a vocabulary' do
    visit vocabularies_path

    filter(vocabulary.id)

    within "[data-id='#{vocabulary.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_vocabulary_path(vocabulary)
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_view]'
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_use]'

    fill_in 'vocabulary[label]', with: 'new label'
    fill_in 'vocabulary[description]', with: 'new description'
    fill_in 'vocabulary[admin_comment]', with: 'new admin comment'
    uncheck 'vocabulary[enabled_for_public_view]'
    uncheck 'vocabulary[enabled_for_public_use]'

    click_button 'Save'

    expect(current_path).to eq vocabulary_path(vocabulary)
    expect(page).to have_content 'Label new label'
    expect(page).to have_content 'Description new description'
    expect(page).to have_content 'Admin comment new admin comment'
    expect(page).to have_content 'Enabled for public view false'
    expect(page).to have_content 'Enabled for public use false'
  end

  scenario 'Changing position' do
    visit vocabularies_path

    expect_order %w(archhist forschung_zhdk landschaftsvisualisierung
                    performance_artefakte)

    within find('table tr[data-id="forschung_zhdk"]') do
      click_link 'Move down'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist landschaftsvisualisierung forschung_zhdk
                    performance_artefakte)

    within find('table tbody tr[data-id="landschaftsvisualisierung"]') do
      click_link 'Move up'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(landschaftsvisualisierung archhist forschung_zhdk
                    performance_artefakte)
  end

  def expect_order(order, limit = 4)
    expect(
      all('table tr[data-id]').map { |tr| tr['data-id'] }[0, limit]
    ).to eq(order)
  end

  def filter(search_term)
    fill_in 'search_term', with: search_term
    click_button 'Apply'
  end
end
