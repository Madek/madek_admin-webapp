class RolesController < ApplicationController
  before_action :load_meta_keys, only: [:index, :new, :edit]

  def index
    @roles = Role
               .search(params[:filter])
               .sorted
               .page(params[:page])
               .per(16)
  end

  def new
    @role = Role.new
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

  def load_meta_keys
    @meta_keys = MetaKey.with_type('MetaDatum::Roles')
  end

  def role_params
    params.require(:role).permit!
  end
end
