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

    within '#contexts_for_validation' do
      expect(page).to have_content 'Upload'
      click_link 'Edit'
    end
    fill_in 'app_setting[contexts_for_validation]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_validation' do
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

    fill_in 'Catalog Title', with: 'CatalogTitle'
    fill_in 'Catalog Subtitle', with: 'CatalogSubtitle'
    fill_in 'Catalog Context Keys', with: catalog_context_keys.join(', ')
    fill_in 'Featured Set Title', with: 'FeaturedSetTitle'
    fill_in 'Featured Set Subtitle', with: 'FeaturedSetSubtitle'
    fill_in 'Featured Set', with: collection.id

    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within '#explore-page-section' do
      expect(page).to have_content 'Catalog: Name CatalogTitle'
      expect(page).to have_content 'Catalog: Subtitle CatalogSubtitle'
      expect(page).to have_content 'Featured Content: Title FeaturedSetTitle'
      expect(page).to have_content 'Featured Content: Subtitle FeaturedSetSubtitle'
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

  scenario "Updating 'Explore Page' Teaser Set with invalid ID" do
    visit app_settings_path

    within '#explore-page-section' do
      click_link 'Edit'
    end

    fill_in 'Teaser Set', with: random_uuid
    click_button 'Save'

    expect(page).to have_css '.alert-danger'
    expect(page).to have_content "The set with a given ID:
                                  #{random_uuid} doesn't exist!"
  end
end
