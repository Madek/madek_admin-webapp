require 'spec_helper'
require 'spec_helper_feature'

def meta_datum_types
  {
    'MetaDatum::Text' => :meta_key_text,
    'MetaDatum::TextDate' => :meta_key_text_date,
    'MetaDatum::Keywords' => :meta_key_keywords,
    'MetaDatum::People' => :meta_key_people
  }
end

feature 'Admin Meta Keys' do
  let(:meta_key_keywords) { create(:meta_key_keywords, is_extensible_list: true) }
  let(:vocabulary) { Vocabulary.find('archhist') }

  scenario 'Sorting meta keys by ID by default' do
    visit meta_keys_path

    expect(find_field('sort_by')[:value]).to eq 'id'
  end

  scenario 'Sorting meta keys by Name part' do
    visit meta_keys_path

    select 'Name part', from: 'Sort by'
    click_button 'Apply'

    expect(page).to have_select('sort_by', selected: 'Name part')
  end

  context 'Editing' do

    scenario 'Editing MetaKey (Text) via Edit button' do
      meta_key = create(:meta_key_text)
      visit meta_key_path(meta_key)

      click_link 'Edit'

      expect(current_path).to eq edit_meta_key_path(meta_key)
      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'
      expect(page).to have_content 'Text type'

      fill_in 'meta_key[label]', with: 'new label'
      fill_in 'meta_key[description]', with: 'new description'
      fill_in 'meta_key[hint]', with: 'new hint'
      expect(page).to \
        have_select('meta_key[text_type]', selected: [meta_key.text_type])
      select 'block', from: 'meta_key[text_type]'

      click_button 'Save'
      expect(current_path).to eq meta_key_path(meta_key)
      expect(page).to have_css('.alert-success')

      visit edit_meta_key_path(meta_key)

      expect(page).to have_field 'meta_key[label]', with: 'new label'
      expect(page).to have_field 'meta_key[description]', with: 'new description'
      expect(page).to have_field 'meta_key[hint]', with: 'new hint'
      expect(page).to have_select 'meta_key[text_type]', selected: 'block'
    end

    scenario 'Proper values for selects' do
      visit edit_meta_key_path(meta_key_keywords)

      expect(page).to have_select(
        'Meta datum object type',
        selected: meta_key_keywords.meta_datum_object_type)
      expect(find_field('meta_key[keywords_alphabetical_order]', with: 'true'))
        .to be_checked
    end

    scenario 'No changing Vocabulary when editing' do
      visit edit_meta_key_path(meta_key_keywords)

      expect(page).not_to have_select('Vocabulary')
      expect(page).to have_selector(
        '.form-control-static samp', text: meta_key_keywords.vocabulary_id)
    end

    scenario 'No changing type when used in MetaData' do
      visit edit_meta_key_path(meta_key_keywords)
      expect(page).to have_select('Meta datum object type', disabled: false)

      create(:meta_datum_keywords, meta_key: meta_key_keywords)

      visit edit_meta_key_path(meta_key_keywords)
      expect(page).to have_select('Meta datum object type', disabled: true)
    end

    scenario "Uncheck 'Extensible?' checkbox for MetaDatum::Keywords" do
      visit edit_meta_key_path(meta_key_keywords)

      expect(page).to have_checked_field 'Extensible?'
      select 'MetaDatum::TextDate', from: 'Meta datum object type'
      click_button 'Save'

      expect(page).to have_css('.alert-success')

      visit edit_meta_key_path(meta_key_keywords)

      expect(page).to have_select('Meta datum object type',
                                  selected: 'MetaDatum::TextDate')
      expect(page).not_to have_field 'Extensible?'
    end

    meta_datum_types.except('MetaDatum::Keywords').each do |type, factory|
      scenario "Do not display 'Extensible?' checkbox for #{type}" do
        meta_key = create(factory)

        visit edit_meta_key_path(meta_key)

        expect(page).not_to have_field 'Extensible?'
      end
    end

    scenario 'Change Allowed Subtypes for MetaDatum::People' do
      meta_key = create(:meta_key_people)

      visit edit_meta_key_path(meta_key)

      expect(page).to have_content 'Allowed Subtypes'
      expect(page).to have_checked_field 'Person'
      expect(page).to have_checked_field 'PeopleGroup'
      expect(page).to have_no_checked_field 'PeopleInstitutionalGroup'

      uncheck 'Person'
      uncheck 'PeopleGroup'
      check 'PeopleInstitutionalGroup'
      click_button 'Save'

      expect(page).to have_css '.alert-success'

      visit edit_meta_key_path(meta_key)

      expect(page).to have_no_checked_field 'Person'
      expect(page).to have_no_checked_field 'PeopleGroup'
      expect(page).to have_checked_field 'PeopleInstitutionalGroup'
    end

    meta_datum_types.except('MetaDatum::People').each do |type, factory|
      scenario "Do not display 'Allowed Subtypes' checkboxes for #{type}" do
        meta_key = create(factory)

        visit edit_meta_key_path(meta_key)

        expect(page).not_to have_content 'Allowed Subtypes'
        expect(page).not_to have_css(
          'input[type="checkbox"][name="meta_key[allowed_people_subtypes][]"]')
        expect(page).not_to have_field 'Person'
        expect(page).not_to have_field 'PeopleGroup'
        expect(page).not_to have_field 'PeopleInstitutionalGroup'
      end
    end
  end

  context 'Creating' do
    scenario 'meta key with MetaDatum::People type' do
      visit meta_keys_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[label]', with: Faker::Lorem.word
      fill_in 'meta_key[description]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hint]', with: Faker::Lorem.sentence
      select 'MetaDatum::People', from: 'meta_key[meta_datum_object_type]'

      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'

      click_button 'Save'

      expect(page).to have_content 'New Meta Key'
      expect(page).to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'
      expect(page).not_to have_content 'Text type'

      check 'PeopleGroup'
      click_button 'Save'

      expect(page).to have_css('.alert-success')
      expect(page).to have_content 'Edit Meta Key'
    end

    scenario 'meta key with MetaDatum::Keywords type' do
      visit meta_keys_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[label]', with: Faker::Lorem.word
      fill_in 'meta_key[description]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hint]', with: Faker::Lorem.sentence
      select 'MetaDatum::Keywords', from: 'meta_key[meta_datum_object_type]'

      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'

      click_button 'Save'

      expect(page).to have_css('.alert-info')

      expect(page).to have_content 'New Meta Key'
      expect(page).to have_content 'Keywords alphabetical order'
      expect(page).to have_content 'Extensible?'
      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Text type'

      click_button 'Save'

      expect(page).to have_css('.alert-success')
      expect(page).to have_content 'Edit Meta Key'
    end

    scenario 'meta key with MetaDatum::Text type' do
      visit meta_keys_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[label]', with: Faker::Lorem.word
      fill_in 'meta_key[description]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hint]', with: Faker::Lorem.sentence
      select 'MetaDatum::Text', from: 'meta_key[meta_datum_object_type]'
      select 'block', from: 'meta_key[text_type]'

      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'

      click_button 'Save'

      expect(page).to have_css('.alert-success')
      expect(page).to have_content 'Edit Meta Key'
    end

    scenario 'meta key with MetaDatum::TextDate type' do
      visit meta_keys_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[label]', with: Faker::Lorem.word
      fill_in 'meta_key[description]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hint]', with: Faker::Lorem.sentence
      select 'MetaDatum::TextDate', from: 'meta_key[meta_datum_object_type]'

      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'

      click_button 'Save'

      expect(page).to have_css('.alert-success')
      expect(page).to have_content 'Edit Meta Key'
    end
  end

  scenario 'Changing position in scope of a vocabulary' do
    visit vocabulary_path(vocabulary)

    click_link 'Edit'

    expect_order %w(archhist:ca_thema
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial)

    within find('table tr[data-id="archhist:ca_thema"]') do
      find('.move-down').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_thema
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial)

    within find('table tbody tr[data-id="archhist:ca_kontext"]') do
      find('.move-up').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_ausgangsmaterial)
  end

  scenario "Show 'Is extensible list' row for MetaDatum::Keywords" do
    visit meta_key_path(meta_key_keywords)

    expect(page).to have_content 'Is extensible list'
  end

  scenario "Don't show 'Is extensible list' for non MetaDatum::Keywords" do
    meta_key = create(:meta_key_text)

    visit meta_key_path(meta_key)

    expect(page).not_to have_content 'Is extensible list'
  end

  scenario "Show 'Allowed Subtypes' for MetaDatum::People" do
    meta_key = create(:meta_key_people)

    visit meta_key_path(meta_key)

    expect(page).to have_content 'Allowed Subtypes'
  end

  scenario "Don't show 'Allowed Subtypes' for non MetaDatum::People" do
    meta_key = create(:meta_key_text)

    visit meta_key_path(meta_key)

    expect(page).not_to have_content 'Allowed Subtypes'
  end

  scenario 'view/index: show contexts which meta key is used in' do
    meta_key = create(:meta_key_text)
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'foo'))
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'bar'))

    visit meta_keys_path(search_term: meta_key.id)

    expect(page).to have_content ': bar, foo'
    expect(page).to have_link 'bar', href: context_path('bar')
    expect(page).to have_link 'foo', href: context_path('foo')
  end

  scenario 'view/show: show contexts which meta key is used in' do
    meta_key = create(:meta_key_text)
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'foo'))
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'bar'))

    visit meta_key_path(meta_key)

    expect(page).to have_content ': bar, foo'
    expect(page).to have_link 'bar', href: context_path('bar')
    expect(page).to have_link 'foo', href: context_path('foo')
  end

  scenario 'Show where meta keys are enabled for in scope of vocabulary' do
    meta_key_1 = create(:meta_key_text, id: 'archhist:enabled_for_all')
    meta_key_2 = create(:meta_key_text, id: 'archhist:disabled_for_media_entries',
                                        is_enabled_for_media_entries: false)
    meta_key_3 = create(:meta_key_text, id: 'archhist:disabled_for_collections',
                                        is_enabled_for_collections: false)
    meta_key_4 = create(:meta_key_text, id: 'archhist:disabled_for_filter_sets',
                                        is_enabled_for_filter_sets: false)
    visit vocabulary_path(vocabulary)

    expect(page).to have_content 'Enabled for'

    within '#meta_keys_list' do
      within "[data-id='#{meta_key_1.id}']" do
        expect(page).to have_content 'Entries, Sets, Filtersets'
      end

      within "[data-id='#{meta_key_2.id}']" do
        expect(page).to have_content 'Sets, Filtersets'
        expect(page).not_to have_content 'Entries, '
      end

      within "[data-id='#{meta_key_3.id}']" do
        expect(page).to have_content 'Entries, Filtersets'
      end

      within "[data-id='#{meta_key_4.id}']" do
        expect(page).to have_content 'Entries, Sets'
        expect(page).not_to have_content ', Filtersets'
      end
    end
  end

  def expect_order(order, limit = 4)
    expect(
      all('table tr[data-id]').map { |tr| tr['data-id'] }[0, limit]
    ).to eq(order)
  end

  def selected_value_from_boolean(value)
    value == true ? 'Yes' : 'No'
  end
end
