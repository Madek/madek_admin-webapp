module CsvImport
  require 'csv'
  extend ActiveSupport::Concern

  included do

    def csv_import_index; end

    def csv_import_roles; end

    def csv_import_roles_update
      expected_headers = %w(meta_key_id label_de label_en)
      csv_import(expected_headers, method(:data_mapper_roles))
      respond_with nil, location: roles_path
    end
  end

  private

  def csv_import(expected_headers, data_mapper)
    db_data = nil
    err = nil
    text_input = params.require(:csv_input)
    csv_data = get_csv_data(text_input, expected_headers)

    ActiveRecord::Base.transaction do
      begin
        db_data = data_mapper.call(csv_data.map { |row| Pojo.new(row) })
      rescue => e
        err = e
        raise ActiveRecord::Rollback
      end
    end
    raise err if err
    flash[:success] = "Imported #{db_data.try(:length).presence || 0} rows."
  end

  def get_csv_data(text_input, expected_headers)
    given_headers = CSV.parse(text_input, headers: false).first

    if expected_headers.sort != given_headers.sort
      fail 'Invalid Headers!'
    end

    CSV.parse(text_input, headers: given_headers).drop(1)
  end

  def data_mapper_roles(rows)
    begin
      rows.map do |row|
        role = Role.new(meta_key_id: row.meta_key_id,
                        labels: {
                          de: row.label_de,
                          en: row.label_en
                        })
        role.creator = current_user
        role.save!
        role
      end
    rescue => e
      throw e
    end
  end

end
