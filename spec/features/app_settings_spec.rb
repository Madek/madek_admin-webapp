require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin App Settings' do
  let(:context) { create :context }
  let(:contexts) { [create(:context), create(:context)] }

  scenario 'Updating Summary Context for Detail View' do
    visit app_settings_path

    within '#context_for_show_summary' do
      click_link 'Edit'
    end
    fill_in 'app_setting[context_for_show_summary]', with: context.id
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_link context.label, href: context_path(context)
  end

  scenario 'Updating Extra Contexts for Detail View' do
    visit app_settings_path

    within '#contexts_for_show_extra' do
      expect(page).to have_content 'Werk, Medium, Credits, ZHdK'
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_show_extra]',
      with: 'media_content, media_object, copyright, zhdk_bereich'
    )
    fill_in 'app_setting[contexts_for_show_extra]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_show_extra' do
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

  scenario 'Updating Contexts for Dynamic Filters' do
    visit app_settings_path

    within '#contexts_for_dynamic_filters' do
      expect(page).to have_content 'Core, Werk, Medium, Credits, ZHdK'
      click_link 'Edit'
    end
    expect(page).to have_field(
      'app_setting[contexts_for_dynamic_filters]',
      with: 'core, media_content, media_object, copyright, zhdk_bereich'
    )
    fill_in 'app_setting[contexts_for_dynamic_filters]', with: contexts.join(', ')
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    within '#contexts_for_dynamic_filters' do
      expect(page).to have_content contexts.map(&:label).join(', ').to_s
      contexts.each do |c|
        expect(page).to have_link c.label, href: context_path(c)
      end
    end
  end

  scenario 'Updating Contexts for Dynamic Filters with not existing context' do
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
