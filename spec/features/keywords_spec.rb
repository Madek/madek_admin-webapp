require 'spec_helper'
require 'spec_helper_feature'

feature 'Keywords' do
  let(:meta_key) do
    create(:meta_key_keywords,
           is_extensible_list: false,
           keywords_alphabetical_order: false)
  end
  let(:keyword_1) { create :keyword, term: 'Zett 1-2011', meta_key: meta_key }
  let(:keyword_2) { create :keyword, term: 'Zett 1-2012', meta_key: meta_key }
  let(:keyword_3) { create :keyword, term: 'Zett 1-2013', meta_key: meta_key }

  context 'when meta key contains some keywords' do
    context 'when keywords are not alphabetically ordered' do
      scenario 'added keyword is the last in the list' do
        keyword_3
        keyword_1
        keyword_2

        visit meta_key_path(meta_key)

        expect(page).to have_content 'Keywords alphabetical order false'
        expect(page).to have_content 'Keywords'

        fill_in 'keyword[term]', with: 'Zett 1-2010'
        click_button 'Add Keyword'

        expect(page).to have_css('.alert-success')

        expect(collect_keyword_terms).to eq [
          'Zett 1-2013',
          'Zett 1-2011',
          'Zett 1-2012',
          'Zett 1-2010'
        ]
      end
    end

    context 'when keywords are alphabetically ordered' do
      before do
        meta_key.update_column(:keywords_alphabetical_order, true)
        keyword_3
        keyword_1
        keyword_2
      end

      scenario 'added keyword is the first in the list' do
        visit meta_key_path(meta_key)

        expect(page).to have_content 'Keywords alphabetical order true'
        expect(page).to have_content 'Keywords'

        fill_in 'keyword[term]', with: 'Zett 1-2010'
        click_button 'Add Keyword'

        expect(page).to have_css('.alert-success')

        expect(collect_keyword_terms).to eq [
          'Zett 1-2010',
          'Zett 1-2011',
          'Zett 1-2012',
          'Zett 1-2013'
        ]
      end

      scenario 'they remain on the same position after alphabetical ordering ' \
               'is disabled again' do
        toggle_alphabetical_ordering(false)

        expect(collect_keyword_terms).to eq [
          'Zett 1-2011',
          'Zett 1-2012',
          'Zett 1-2013'
        ]
      end
    end
  end

  context 'when meta key does not contain any keywords' do
    context 'when keywords are not alphabetically ordered' do
      scenario 'added keywords are correctly ordered' do
        visit meta_key_path(meta_key)

        expect(page).to have_content 'Keywords alphabetical order false'
        expect(page).to have_content 'Keywords'

        fill_in 'keyword[term]', with: 'Zett 1-2010'
        click_button 'Add Keyword'
        fill_in 'keyword[term]', with: 'Zett 1-2009'
        click_button 'Add Keyword'

        expect(page).to have_css('.alert-success')

        expect(collect_keyword_terms).to eq [
          'Zett 1-2010',
          'Zett 1-2009'
        ]
      end
    end

    context 'when keywords are alphabetically ordered' do
      before { meta_key.update_column(:keywords_alphabetical_order, true) }

      scenario 'added keywords are correctly ordered' do
        visit meta_key_path(meta_key)

        expect(page).to have_content 'Keywords alphabetical order true'
        expect(page).to have_content 'Keywords'

        fill_in 'keyword[term]', with: 'Zett 1-2010'
        click_button 'Add Keyword'
        fill_in 'keyword[term]', with: 'Zett 1-2009'
        click_button 'Add Keyword'

        expect(page).to have_css('.alert-success')

        expect(collect_keyword_terms).to eq [
          'Zett 1-2009',
          'Zett 1-2010'
        ]
      end
    end
  end

  scenario 'Changing position in scope of a meta key' do
    keyword_1
    keyword_2
    keyword_3

    visit meta_key_path(meta_key)

    expect_order ['Zett 1-2011',
                  'Zett 1-2012',
                  'Zett 1-2013']

    within('#keywords tr:contains("Zett 1-2012")') do
      find('.move-down').click
    end
    expect_order ['Zett 1-2011',
                  'Zett 1-2013',
                  'Zett 1-2012']

    within('#keywords tr:contains("Zett 1-2012")') do
      find('.move-down').click
    end
    expect_order ['Zett 1-2011',
                  'Zett 1-2013',
                  'Zett 1-2012']

    within('#keywords tr:contains("Zett 1-2011")') do
      find('.move-up').click
    end
    expect_order ['Zett 1-2011',
                  'Zett 1-2013',
                  'Zett 1-2012']

    within('#keywords tr:contains("Zett 1-2013")') do
      find('.move-up').click
    end
    expect_order ['Zett 1-2013',
                  'Zett 1-2011',
                  'Zett 1-2012']

    within('#keywords tr:contains("Zett 1-2013")') do
      find('.move-to-top').click
    end
    expect_order ['Zett 1-2013',
                  'Zett 1-2011',
                  'Zett 1-2012']

    within('#keywords tr:contains("Zett 1-2012")') do
      find('.move-to-top').click
    end
    expect_order ['Zett 1-2012',
                  'Zett 1-2013',
                  'Zett 1-2011']

    within('#keywords tr:contains("Zett 1-2011")') do
      find('.move-to-bottom').click
    end
    expect_order ['Zett 1-2012',
                  'Zett 1-2013',
                  'Zett 1-2011']

    within('#keywords tr:contains("Zett 1-2012")') do
      find('.move-to-bottom').click
    end
    expect_order ['Zett 1-2013',
                  'Zett 1-2011',
                  'Zett 1-2012']
  end

  def collect_keyword_terms
    all('#keywords tbody tr td:nth-child(2)').map(&:text)
  end

  def expect_order(order, limit = 3)
    expect(
      all('#keywords tr[data-id] td:nth(2)').map(&:text)[0, limit]
    ).to eq(order)
  end

  def toggle_alphabetical_ordering(target_state)
    visit meta_key_path(meta_key)

    within '.panel' do
      click_link 'Edit'
    end
    choose(target_state ? 'Yes' : 'No')
    click_button 'Save'

    expect(page).to have_content "Keywords alphabetical order #{target_state}"
  end
end
