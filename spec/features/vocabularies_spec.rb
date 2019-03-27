require 'spec_helper'
require 'spec_helper_feature'
require_relative 'shared/admin_comments'

feature 'Admin Vocabularies' do
  let(:vocabulary) { create :vocabulary }
  let(:collection_path) { vocabularies_path }

  scenario 'Adding a vocabulary' do
    visit vocabularies_path

    click_link 'Create Vocabulary'
    expect(current_path).to eq new_vocabulary_path

    fill_in 'vocabulary[id]', with: 'test-id'
    fill_in 'vocabulary[labels][de]', with: 'label DE'
    fill_in 'vocabulary[labels][en]', with: 'label EN'
    fill_in 'vocabulary[descriptions][de]', with: 'description DE'
    fill_in 'vocabulary[descriptions][en]', with: 'description EN'
    fill_in 'vocabulary[admin_comment]', with: 'new admin comment'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    filter('test-id')
    within "[data-id='test-id']" do
      click_link 'Details'
    end

    expect(page).to have_content 'Id test-id'
    expect(page).to have_content 'Labels ' \
                                 '{"de"=>"label DE", "en"=>"label EN"}'
    expect(page).to have_content 'Descriptions ' \
                                 '{"de"=>"description DE", ' \
                                 '"en"=>"description EN"}'
    expect(page).to have_content 'Admin comment new admin comment'
    expect(page).to have_content 'Enabled for public view true'
    expect(page).to have_content 'Enabled for public use true'
  end

  scenario 'Editing a vocabulary' do
    visit vocabularies_path

    filter(vocabulary.id)

    within "[data-id='#{vocabulary.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_vocabulary_path(vocabulary)
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_view]'
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_use]'

    fill_in 'vocabulary[labels][de]', with: 'new label DE'
    fill_in 'vocabulary[labels][en]', with: 'new label EN'
    fill_in 'vocabulary[descriptions][de]', with: 'new description DE'
    fill_in 'vocabulary[descriptions][en]', with: 'new description EN'
    fill_in 'vocabulary[admin_comment]', with: 'new admin comment'
    uncheck 'vocabulary[enabled_for_public_view]'
    uncheck 'vocabulary[enabled_for_public_use]'

    click_button 'Save'

    expect(current_path).to eq vocabulary_path(vocabulary)
    expect(page).to have_content 'Labels ' \
                                 '{"de"=>"new label DE", "en"=>"new label EN"}'
    expect(page).to have_content 'Descriptions ' \
                                 '{"de"=>"new description DE", ' \
                                 '"en"=>"new description EN"}'
    expect(page).to have_content 'Admin comment new admin comment'
    expect(page).to have_content 'Enabled for public view false'
    expect(page).to have_content 'Enabled for public use false'
  end

  scenario 'Changing position' do
    visit vocabularies_path

    expect_order %w(archhist
                    forschung_zhdk
                    landschaftsvisualisierung
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    within find('table tr[data-id="forschung_zhdk"]') do
      click_link 'Move down'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist
                    landschaftsvisualisierung
                    forschung_zhdk
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    paginate_to 2
    expect_order %w(madek_core)

    within find('table tr[data-id="madek_core"]') do
      click_link 'Move down'
    end
    expect(page).to have_css('.alert-success')
    paginate_to 2
    expect_order %w(madek_core)

    paginate_to 1

    within find('table tr[data-id="archhist"]') do
      click_link 'Move up'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist
                    landschaftsvisualisierung
                    forschung_zhdk
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    within find('table tr[data-id="forschung_zhdk"]') do
      click_link 'Move up'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist
                    forschung_zhdk
                    landschaftsvisualisierung
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    within find('table tr[data-id="archhist"]') do
      click_link 'Move to top'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist
                    forschung_zhdk
                    landschaftsvisualisierung
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    paginate_to 2

    within find('table tr[data-id="madek_core"]') do
      click_link 'Move to top'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core
                    archhist
                    forschung_zhdk
                    landschaftsvisualisierung
                    performance_artefakte
                    supplylines
                    columns
                    toni
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core)

    paginate_to 2

    within find('table tr[data-id="media_set"]') do
      click_link 'Move to bottom'
    end
    expect(page).to have_css('.alert-success')
    paginate_to 2
    expect_order %w(media_set)

    paginate_to 1

    within find('table tr[data-id="toni"]') do
      click_link 'Move to bottom'
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core
                    archhist
                    forschung_zhdk
                    landschaftsvisualisierung
                    performance_artefakte
                    supplylines
                    columns
                    vfo
                    zett
                    zhdk_bereich
                    media_content
                    nutzung
                    copyright
                    media_object
                    core
                    media_set)

    paginate_to 2
    expect_order %w(toni)
  end

  include_examples 'display admin comments on overview page'

  def expect_order(order)
    expect(
      all('table tr[data-id]').map { |tr| tr['data-id'] }
    ).to eq(order)
  end

  def filter(search_term)
    fill_in 'search_term', with: search_term
    click_button 'Apply'
  end

  def paginate_to(page)
    within '.pagination' do
      click_link page
    end
  end
end
