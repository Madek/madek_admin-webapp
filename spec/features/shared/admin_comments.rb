shared_examples 'display admin comments on overview page' do
  scenario 'Displaying admin comments on overview page' do
    visit collection_path

    all('table tr.admin-comment').each do |row|
      expect(row).to have_content 'Admin comment: '
    end
  end
end
