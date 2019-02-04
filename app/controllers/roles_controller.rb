require 'csv'

class RolesController < ApplicationController
  def index
    @roles = Role
               .filter_by(filter_value(:term, nil))
               .sorted
               .page(params[:page])
               .per(16)
    filter_by_vocabulary
    @vocabularies = Vocabulary.reorder(:id)
    @vocabulary = Vocabulary.find_by(id: filter_value(:vocabulary_id))
  end

  def new
    @role = Role.new
    @vocabulary = Vocabulary.find(params[:vocabulary_id])
    @meta_keys = @vocabulary
                   .meta_keys
                   .where(meta_datum_object_type: 'MetaDatum::Roles')
  end

  def create
    role = create_role!(role_params)
    respond_with role, location: roles_path
  end

  def edit
    @role = Role.find(params[:id])
    @vocabulary = @role.meta_key.vocabulary
    @meta_keys = @vocabulary
                   .meta_keys
                   .where(meta_datum_object_type: 'MetaDatum::Roles')
  end

  def import
  end

  def import_post
    err = nil
    table_data = params.require(:csv_input)
    roles = roles_from_csv(table_data)
    fail 'Empty list!' if roles.empty?

    ActiveRecord::Base.transaction do
      begin
        roles = roles.map { |role_params| create_role!(role_params) }
      rescue => e
        err = e
        raise ActiveRecord::Rollback
      end
    end
    raise err if err

    respond_with nil, location: roles_path
  end

  def update
    role = Role.find(params[:id])
    role.update!(role_params)
    respond_with role, location: roles_path
  end

  def destroy
    role = Role.find(params[:id])
    role.destroy!
    respond_with role, location: roles_path
  end

  private

  def filter_by_vocabulary
    @roles = @roles.of_vocabulary(params.fetch(:filter, {})[:vocabulary_id])
  end

  def role_params
    params.require(:role).permit!
  end

  def create_role!(role_params)
    role = Role.new(role_params)
    role.creator = current_user
    role.save!
    role
  end

  def roles_from_csv(table_data)
    expected_headers = %w(meta_key_id label_de label_en)
    given_headers = CSV.parse(table_data, headers: false).first

    if expected_headers.sort != given_headers.sort
      fail 'Invalid Headers!'
    end

    begin
      roles = CSV.parse(table_data, headers: given_headers).map do |row|
        {
          meta_key_id: row['meta_key_id'],
          labels: {
            de: row['label_de'],
            en: row['label_en']
          }
        }
      end.drop(1)
    rescue => e
      throw e
    end
    roles
  end
end
