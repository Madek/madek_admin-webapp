require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin App Settings' do
  let(:context) { create :context }
  let(:invalid_context) { build :context, id: 'foo' }
  let(:contexts) { [create(:context), create(:context)] }
  let(:default_catalog_context_key) do
    ContextKey.find_by(
      context_id: 'core',
      meta_key_id: 'madek_core:keywords'
    )
  end
  let(:new_context_key) do
    create(:context_key,
           meta_key: create(:meta_key_keywords,
                            id: "test:#{Faker::Lorem.characters(8)}"))
  end
  let(:catalog_context_keys) do
    [
      ContextKey.find_by(
        context_id: 'upload',
        meta_key_id: 'madek_core:keywords'
      ).id,
      new_context_key.id,
      'madek_core:invalid_uuid'
    ]
  end
  let(:collection) { Collection.first }
  let(:random_uuid) { SecureRandom.uuid }

  scenario 'Updating Site Title' do
    new_title = Faker::Name.title

    visit app_settings_path

    within '#site_titles' do
      click_link 'Edit'
    end

    fill_in '[de]', with: new_title + 'DE'
    fill_in '[en]', with: new_title + 'EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#site_titles' do
      expect(page).to have_content "de → #{new_title}DE en → #{new_title}EN"
    end
  end

  scenario 'Updating Brand Text' do
    new_text = Faker::Book.title

    visit app_settings_path

    within '#brand_texts' do
      click_link 'Edit'
    end

    fill_in '[de]', with: new_text + 'DE'
    fill_in '[en]', with: new_text + 'EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#brand_texts' do
      expect(page).to have_content "de → #{new_text}DE en → #{new_text}EN"
    end
  end

  scenario 'Updating Provenance Notive' do
    new_text = Faker::University.name

    visit app_settings_path

    within '#provenance_notices' do
      click_link 'Edit'
    end

    fill_in '[de]', with: new_text + 'DE'
    fill_in '[en]', with: new_text + 'EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#provenance_notices' do
      expect(page).to have_content "de → #{new_text}DE en → #{new_text}EN"
    end
  end

  scenario 'Updating Welcome Title' do
    new_title = Faker::Book.title

    visit app_settings_path

    within '#welcome_titles' do
      click_link 'Edit'
    end

    fill_in '[de]', with: new_title + 'DE'
    fill_in '[en]', with: new_title + 'EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#welcome_titles' do
      expect(page).to have_content "de → #{new_title}DE en → #{new_title}EN"
    end
  end

  scenario 'Updating Welcome Texts', browser: :firefox do
    new_text = Faker::Lorem.paragraph

    visit app_settings_path

    within '#welcome_texts' do
      click_link 'Edit'
    end

    fill_in '[de]', with: new_text + 'DE'
    fill_in '[en]', with: new_text + 'EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#welcome_texts' do
      expect(page).to have_content "de ↘ #{new_text}DE en ↘ #{new_text}EN"
    end
  end

  scenario 'Updating Media Entry Default License Usage Text' do
    new_text = Faker::Lorem.sentence
    visit app_settings_path

    within '#media_entry_default_license_usage_text' do
      click_link 'Edit'
    end

    fill_in 'app_setting[media_entry_default_license_usage_text]', with: new_text
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#media_entry_default_license_usage_text' do
      expect(page).to have_content new_text
    end
  end

  describe 'Updating Summary Context for Entry View' do
    scenario 'with existing context' do
      visit app_settings_path

      within '#context_for_entry_summary' do
        click_link 'Edit'
      end
      fill_in 'app_setting[context_for_entry_summary]', with: context.id
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#context_for_entry_summary' do
        expect(page).to have_link context.label, href: context_path(context)
      end
    end

    scenario 'with invalid context' do
      visit app_settings_path

      within '#context_for_entry_summary' do
        click_link 'Edit'
      end
      fill_in 'app_setting[context_for_entry_summary]', with: invalid_context.id
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#context_for_entry_summary' do
        expect(page).to have_content "#{invalid_context} (invalid!)"
      end
    end
  end

  describe 'Updating Summary Context for Collection View' do
    scenario 'with existing context' do
      visit app_settings_path

      within '#context_for_collection_summary' do
        click_link 'Edit'
      end
      fill_in 'app_setting[context_for_collection_summary]', with: context.id
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#context_for_collection_summary' do
        expect(page).to have_link context.label, href: context_path(context)
      end
    end

    scenario 'with invalid context' do
      visit app_settings_path

      within '#context_for_collection_summary' do
        click_link 'Edit'
      end
      fill_in(
        'app_setting[context_for_collection_summary]',
        with: invalid_context.id
      )
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#context_for_collection_summary' do
        expect(page).to have_content "#{invalid_context} (invalid!)"
      end
    end
  end

  scenario 'Updating Extra Contexts for Entry View' do
    visit app_settings_path

    within '#contexts_for_entry_extra' do
      expect(page).to have_content 'Werk, Medium, Credits, ZHdK'
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_entry_extra]',
      with: 'media_content, media_object, copyright, zhdk_bereich'
    )
    fill_in 'app_setting[contexts_for_entry_extra]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_entry_extra' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Extra Contexts for Collection View' do
    visit app_settings_path

    within '#contexts_for_collection_extra' do
      expect(page).to have_content ''
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_collection_extra]',
      with: ''
    )
    fill_in 'app_setting[contexts_for_collection_extra]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_collection_extra' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Contexts for Entry Edit' do
    visit app_settings_path

    within '#contexts_for_entry_edit' do
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_entry_edit]',
      with: 'core, media_content, media_object, copyright, zhdk_bereich'
    )
    fill_in 'app_setting[contexts_for_entry_edit]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_entry_edit' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Contexts for Collection Edit' do
    visit app_settings_path

    within '#contexts_for_collection_edit' do
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_collection_edit]',
      with: 'core, media_content, media_object, copyright, zhdk_bereich'
    )
    fill_in 'app_setting[contexts_for_collection_edit]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_collection_edit' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Contexts for "List" View' do
    visit app_settings_path

    within '#contexts_for_list_details' do
      click_link 'Edit'
    end
    fill_in 'app_setting[contexts_for_list_details]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_list_details' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Contexts for Validation' do
    visit app_settings_path

    within '#contexts_for_entry_validation' do
      expect(page).to have_content 'Upload'
      click_link 'Edit'
    end
    fill_in 'app_setting[contexts_for_entry_validation]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_entry_validation' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  describe 'Updating Contexts for Dynamic Filters' do
    scenario 'with valid data' do
      visit app_settings_path

      within '#contexts_for_dynamic_filters' do
        expect(page).to have_content 'Core, Werk, Medium, Credits, ZHdK'
        click_link 'Edit'
      end
      expect(page).to have_field(
        'app_setting[contexts_for_dynamic_filters]',
        with: 'core, media_content, media_object, copyright, zhdk_bereich'
      )
      fill_in(
        'app_setting[contexts_for_dynamic_filters]',
        with: contexts.join(', ')
      )
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#contexts_for_dynamic_filters' do
        expect(page).to have_content contexts.map(&:label).join(', ').to_s
        contexts.each do |c|
          expect(page).to have_link c.label, href: context_path(c)
        end
      end
    end

    scenario 'with not existing context' do
      visit app_settings_path

      within '#contexts_for_dynamic_filters' do
        expect(page).to have_content 'Core, Werk, Medium, Credits, ZHdK'
        click_link 'Edit'
      end
      fill_in(
        'app_setting[contexts_for_dynamic_filters]',
        with: "core, media_content, media_object, \
               copyright, zhdk_bereich, foo"
      )
      click_button 'Save'

      expect(page).to have_css '.alert-success'
      within '#contexts_for_dynamic_filters' do
        expect(page).to have_content "Core, Werk, Medium, Credits, \
                                      ZHdK, foo (invalid!)"
      end
    end
  end

  scenario "Updating 'Explore Page' settings", browser: :firefox do
    visit app_settings_path

    within '#explore-page-section' do
      click_link 'Edit'
    end

    expect(page).to have_field(
      'Catalog Context Keys',
      with: default_catalog_context_key.id
    )

    fill_in 'Catalog Title [de]', with: 'CatalogTitleDE'
    fill_in 'Catalog Title [en]', with: 'CatalogTitleEN'
    fill_in 'Catalog Subtitle [de]', with: 'CatalogSubtitleDE'
    fill_in 'Catalog Subtitle [en]', with: 'CatalogSubtitleEN'
    fill_in 'Catalog Context Keys', with: catalog_context_keys.join(', ')
    fill_in 'Featured Set Title [de]', with: 'FeaturedSetTitleDE'
    fill_in 'Featured Set Title [en]', with: 'FeaturedSetTitleEN'
    fill_in 'Featured Set Subtitle [de]', with: 'FeaturedSetSubtitleDE'
    fill_in 'Featured Set Subtitle [en]', with: 'FeaturedSetSubtitleEN'
    fill_in 'Featured Set', with: collection.id

    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#explore-page-section' do
      expect(page).to have_content 'Catalog: Name de → CatalogTitleDE ' \
                                   'en → CatalogTitleEN'
      expect(page).to have_content 'Catalog: Subtitle de → CatalogSubtitleDE ' \
                                   'en → CatalogSubtitleEN'
      expect(page).to have_content 'Featured Content: Title ' \
                                   'de → FeaturedSetTitleDE ' \
                                   'en → FeaturedSetTitleEN'
      expect(page).to have_content 'Featured Content: Subtitle ' \
                                   'de → FeaturedSetSubtitleDE ' \
                                   'en → FeaturedSetSubtitleEN'
      expect(find('#featured_set_id')).to have_content collection.id

      within 'tr#catalog_context_keys' do
        catalog_context_keys.each do |ck_id|
          context_key = ContextKey.find_by(id: ck_id)
          if context_key
            expect(page).to have_link(
              "#{context_key.meta_key_id} (#{context_key.context.label})",
              href: meta_key_path(context_key.meta_key_id)
            )
          else
            expect(page).to have_content "#{ck_id} (invalid!)"
          end
        end
      end
    end
  end

  scenario "Updating 'Explore Page' Featured Set with invalid ID" do
    visit app_settings_path

    within '#explore-page-section' do
      click_link 'Edit'
    end

    fill_in 'Featured Set', with: random_uuid
    click_button 'Save'

    expect(page).to have_css '.alert-danger'
    expect(page).to have_content "The set with a given ID:
                                  #{random_uuid} doesn't exist!"
  end

  scenario 'Updating Support URL' do
    new_url = Faker::Internet.url('wiki.zhdk.ch')

    visit app_settings_path

    within '#support_urls' do
      expect(page).not_to have_content(new_url)
      click_link 'Edit'
    end

    fill_in '[de]', with: new_url + '?lang=de'
    fill_in '[en]', with: new_url + '?lang=en'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#support_urls' do
      expect(page).to have_content "de → #{new_url}?lang=de " \
                                   "en → #{new_url}?lang=en"
    end
  end

  scenario 'Updating Ignored keyword keys for browsing' do
    valid_meta_key   = create :meta_key_keywords
    invalid_meta_key = create :meta_key_title

    visit app_settings_path

    within '#ignored_keyword_keys_for_browsing' do
      click_link 'Edit'
    end

    fill_in 'app_setting[ignored_keyword_keys_for_browsing]', with: \
      "#{valid_meta_key.id}, #{invalid_meta_key.id}"
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#ignored_keyword_keys_for_browsing' do
      expect(page).to have_content(
        "#{valid_meta_key.id}, #{invalid_meta_key.id} (invalid!)"
      )
    end

    within '#ignored_keyword_keys_for_browsing' do
      click_link 'Edit'
    end

    expect(page).to have_field(
      'app_setting[ignored_keyword_keys_for_browsing]',
      with: "#{valid_meta_key.id}, #{invalid_meta_key.id}"
    )
  end
end
