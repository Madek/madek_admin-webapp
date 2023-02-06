require 'csv'

class RolesController < ApplicationController
  def index
    @roles = Role
               .filter_by(filter_value(:term, nil))
               .sorted
               .page(page_params)
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
    role = Role.new(role_params)
    role.creator = current_user
    role.save!
    respond_with role, location: roles_path
  end

  def edit
    @role = Role.find(params[:id])
    @vocabulary = @role.meta_key.vocabulary
    @meta_keys = @vocabulary
                   .meta_keys
                   .where(meta_datum_object_type: 'MetaDatum::Roles')
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

end
