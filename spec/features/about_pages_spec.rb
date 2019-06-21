require 'spec_helper'
require 'spec_helper_feature'

EXAMPLE_CONTENT_RAW = <<MARKDOWN.strip_heredoc.strip
  # About this Archive

  ## Notice

  We use [Cookies](https://en.wikipedia.org/wiki/Cookie). They are quite tasty, *yum*!
MARKDOWN

feature 'Admin App Settings' do

  scenario "Updating 'About Page' settings", browser: :firefox do
    configure_about_page_content(nil)

    visit app_settings_path

    within('#about_pages') do
      expect(page.all('td').map(&:text)).to eq \
        [
          'About Page HTML/Markdown Content for "About Page" (/about)',
          'de → Not configured en → Not configured',
          'Edit'
        ]

      click_link 'Edit'
    end

    fill_in('app_setting_about_pages_de', with: 'DE' + EXAMPLE_CONTENT_RAW)
    fill_in('app_setting_about_pages_en', with: 'EN' + EXAMPLE_CONTENT_RAW)
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    within('#about_pages') do
      expect(page.all('td').map(&:text)).to eq \
        [
          'About Page HTML/Markdown Content for "About Page" (/about)',
          'de → DE# About this Archive ## Notice … ' \
          'en → EN# About this Archive ## Notice …',
          'Edit'
        ]

    end

  end

end

private

def configure_about_page_content(content)
  AppSetting.first.update_attributes!(about_pages: { de: content })
end
