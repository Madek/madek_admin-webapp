require 'spec_helper'
require 'spec_helper_feature'
require_relative 'shared/admin_comments'

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
  let(:meta_key) { create(:meta_key_text) }
  let(:collection_path) { meta_keys_path }

  scenario 'Sorting meta keys by ID by default' do
    visit collection_path

    expect(find_field('sort_by')[:value]).to eq 'id'
  end

  scenario 'Sorting meta keys by Name part' do
    visit collection_path

    select 'Name part', from: 'Sort by'
    click_button 'Apply'

    expect(page).to have_select('sort_by', selected: 'Name part')
  end

  context 'Editing' do
    let(:de_documentation_url) { Faker::Internet.url(host: 'example.com', path: '?lang=de') }
    let(:en_documentation_url) { Faker::Internet.url(host: 'example.com', path: '?lang=en') }

    scenario 'Editing MetaKey (Text) via Edit button' do
      visit meta_key_path(meta_key)

      click_link 'Edit'

      expect(current_path).to eq edit_meta_key_path(meta_key)
      expect(page).not_to have_content 'Allowed Subtypes'
      expect(page).not_to have_content 'Keywords alphabetical order'
      expect(page).not_to have_content 'Extensible?'
      expect(page).to have_content 'Text type'

      fill_in 'meta_key[labels][de]', with: 'new label DE'
      fill_in 'meta_key[labels][en]', with: 'new label EN'
      fill_in 'meta_key[descriptions][de]', with: 'new desc DE'
      fill_in 'meta_key[descriptions][en]', with: 'new desc EN'
      fill_in 'meta_key[hints][de]', with: 'new hint DE'
      fill_in 'meta_key[hints][en]', with: 'new hint EN'
      expect(page).to \
        have_select('meta_key[text_type]', selected: [meta_key.text_type])
      select 'block', from: 'meta_key[text_type]'

      click_button 'Save'
      expect(current_path).to eq meta_key_path(meta_key)
      expect(page).to have_css('.alert-success')

      visit edit_meta_key_path(meta_key)

      expect(page).to have_field 'meta_key[labels][de]', with: 'new label DE'
      expect(page).to have_field 'meta_key[labels][en]', with: 'new label EN'
      expect(page).to have_field 'meta_key[descriptions][de]', with: 'new desc DE'
      expect(page).to have_field 'meta_key[descriptions][en]', with: 'new desc EN'
      expect(page).to have_field 'meta_key[hints][de]', with: 'new hint DE'
      expect(page).to have_field 'meta_key[hints][en]', with: 'new hint EN'
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

    scenario 'Editing documentation URL' do
      visit meta_key_path(meta_key)
      click_link 'Edit'

      expect(meta_key.documentation_urls).to eq({})
      expect(page).to have_current_path(edit_meta_key_path(meta_key))

      fill_in 'Documentation URL [de]', with: de_documentation_url
      fill_in 'Documentation URL [en]', with: en_documentation_url
      click_button 'Save'

      expect(meta_key.reload.documentation_urls).to eq('de' => de_documentation_url,
                                                       'en' => en_documentation_url)
      expect(page).to have_css('.alert-success')
    end
  end

  context 'Creating' do
    scenario 'meta key with MetaDatum::People type' do
      visit collection_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[labels][de]', with: Faker::Lorem.word
      fill_in 'meta_key[descriptions][de]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hints][de]', with: Faker::Lorem.sentence
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
      visit collection_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[labels][de]', with: Faker::Lorem.word
      fill_in 'meta_key[descriptions][de]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hints][de]', with: Faker::Lorem.sentence
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
      visit collection_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[labels][de]', with: Faker::Lorem.word
      fill_in 'meta_key[descriptions][de]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hints][de]', with: Faker::Lorem.sentence
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
      visit collection_path

      click_link 'Create Meta Key'

      fill_in 'meta_key[id]', with: 'archhist:foo'
      fill_in 'meta_key[labels][de]', with: Faker::Lorem.word
      fill_in 'meta_key[descriptions][de]', with: Faker::Lorem.sentence
      fill_in 'meta_key[hints][de]', with: Faker::Lorem.sentence
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
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tr[data-id="archhist:ca_konzept"]') do
      find('.move-down').click
    end
    expect_order %w(archhist:ca_thema
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tr[data-id="archhist:ca_thema"]') do
      find('.move-down').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_thema
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tr[data-id="archhist:ca_zweck"]') do
      find('.move-up').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_thema
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tbody tr[data-id="archhist:ca_kontext"]') do
      find('.move-up').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tbody tr[data-id="archhist:ca_zweck"]') do
      find('.move-to-top').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_ausgangsmaterial
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tbody tr[data-id="archhist:ca_ausgangsmaterial"]') do
      find('.move-to-top').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_ausgangsmaterial
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_informationstechnologie
                    archhist:ca_daten
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept)

    within find('table tbody tr[data-id="archhist:ca_daten"]') do
      find('.move-to-bottom').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_ausgangsmaterial
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_informationstechnologie
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept
                    archhist:ca_daten)

    within find('table tbody tr[data-id="archhist:ca_daten"]') do
      find('.move-to-bottom').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_ausgangsmaterial
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_informationstechnologie
                    archhist:ca_sinnstiftung
                    archhist:ca_konzept
                    archhist:ca_daten)
  end

  scenario "Show 'Is extensible list' row for MetaDatum::Keywords" do
    visit meta_key_path(meta_key_keywords)

    expect(page).to have_content 'Is extensible list'
  end

  scenario "Don't show 'Is extensible list' for non MetaDatum::Keywords" do
    visit meta_key_path(meta_key)

    expect(page).not_to have_content 'Is extensible list'
  end

  scenario "Show 'Allowed Subtypes' for MetaDatum::People" do
    meta_key = create(:meta_key_people)

    visit meta_key_path(meta_key)

    expect(page).to have_content 'Allowed Subtypes'
  end

  scenario "Don't show 'Allowed Subtypes' for non MetaDatum::People" do
    visit meta_key_path(meta_key)

    expect(page).not_to have_content 'Allowed Subtypes'
  end

  scenario 'view/index: show contexts which meta key is used in' do
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'foo'))
    create(:context_key, meta_key: meta_key, context: create(:context, id: 'bar'))

    visit meta_keys_path(search_term: meta_key.id)

    expect(page).to have_content ': bar, foo'
    expect(page).to have_link 'bar', href: context_path('bar')
    expect(page).to have_link 'foo', href: context_path('foo')
  end

  scenario 'view/show: show contexts which meta key is used in' do
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
    visit vocabulary_path(vocabulary)

    expect(page).to have_content 'Enabled for'

    within '#meta_keys_list' do
      within "[data-id='#{meta_key_1.id}']" do
        expect(page).to have_content 'Entries, Sets'
      end

      within "[data-id='#{meta_key_2.id}']" do
        expect(page).to have_content 'Sets'
        expect(page).not_to have_content 'Entries, '
      end

      within "[data-id='#{meta_key_3.id}']" do
        expect(page).to have_content 'Entries'
      end
    end
  end

  include_examples 'display admin comments on overview page'

  describe 'Deleting' do
    context 'when meta key belongs to madek_core Vocabulary' do
      let(:meta_key) do
        MetaKey.find_by(id: 'madek_core:title') || create(:meta_key_core_title)
      end

      context 'index page' do
        scenario 'it cannot be edited' do
          visit collection_path

          select 'madek_core', from: 'vocabulary_id'
          click_button 'Apply'

          within "[data-id='#{meta_key.id}']" do
            expect(page).not_to have_link 'Edit'
          end
        end

        scenario 'it cannot be deleted' do
          visit collection_path

          select 'madek_core', from: 'vocabulary_id'
          click_button 'Apply'

          within "[data-id='#{meta_key.id}']" do
            expect(page).not_to have_link 'Delete'
          end
        end
      end

      context 'show page' do
        scenario 'it cannot be edited' do
          visit meta_key_path(meta_key)

          expect(page).not_to have_link 'Edit'
        end

        scenario 'it cannot be deleted' do
          visit meta_key_path(meta_key)

          expect(page).not_to have_link 'Delete'
        end
      end

      context 'vocabulary edit page' do
        scenario 'it cannot be reordered' do
          visit edit_vocabulary_path(meta_key.vocabulary)

          within '#meta_keys_list' do
            expect(page).not_to have_css 'a.move-to-top'
            expect(page).not_to have_css 'a.move-up'
            expect(page).not_to have_css 'a.move-down'
            expect(page).not_to have_css 'a.move-to-bottom'
          end
        end
      end
    end

    context 'when meta key has related meta data', browser: :firefox do
      given(:meta_key) { create(:meta_key_text) }
      given!(:meta_data) { create_list(:meta_datum_text, 3, meta_key_id: meta_key.id) }

      scenario 'meta key cannot be deleted' do
        visit meta_key_path(meta_key)

        accept_alert do
          click_link 'Delete', href: meta_key_path(meta_key)
        end

        expect(page).to have_content('An error occured code: 500')
        expect(page).to have_content('PG::ForeignKeyViolation: ERROR: '\
                                     'update or delete on table "meta_keys" '\
                                     'violates foreign key constraint')

        click_link 'Go back'

        expect(current_path).to eq(meta_key_path(meta_key))
        expect(meta_key.meta_data.reload).to eq(meta_data)
      end
    end

    context 'when meta key has no related meta data', browser: :firefox do
      given(:meta_key) { create(:meta_key_text, id: 'test:foo') }

      scenario 'meta key can be deleted' do
        visit meta_key_path(meta_key)

        accept_alert do
          click_link 'Delete', href: meta_key_path(meta_key)
        end

        expect(page).to have_css('.alert-success')
        expect(current_path).to eq(meta_keys_path)

        visit meta_key_path(meta_key)

        expect(page).to have_content('An error occured code: 404')
        expect(page).to have_content("Couldn't find MetaKey with 'id'=test:foo")
      end
    end
  end

  def expect_order(order)
    expect(
      all('table tr[data-id]').map { |tr| tr['data-id'] }
    ).to eq(order)
  end

  def selected_value_from_boolean(value)
    value == true ? 'Yes' : 'No'
  end
end
