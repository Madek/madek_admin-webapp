class GroupsController < ApplicationController
  before_action :ensure_presence_of_system_groups, only: [:index, :show, :edit]

  def index
    @groups = sort_and_filter(params)

    remember_vocabulary_url_params
  rescue ArgumentError => e
    @groups = Group.all.page(params[:page])
    flash[:error] = e.to_s
  end

  def new
    @group = Group.new params[:group]
  end

  define_update_action_for(Group, true)

  def create
    @group = Group.create!(group_params)

    respond_with @group, location: -> { group_path(@group) }
  end

  def show
    @group = Group.find params[:id]
    @users = @group.users

    if params.fetch(:user, {}).fetch(:search_term, nil).present?
      @users = @users.filter_by(params[:user][:search_term])
    end

    @users = @users.page(params[:page])
  end

  def edit
    @group = Group.find params[:id]
  end

  def destroy
    @group = Group.find(params[:id])
    authorize @group

    if @group.users.empty?
      @group.destroy!
      respond_with @group, location: -> { groups_path }
    else
      redirect_to params[:redirect_path], flash: {
        error: 'The group contains users and cannot be destroyed.'
      }
    end
  end

  def form_add_user
    group = Group.find(params[:id])

    redirect_to users_path(add_to_group_id: group.id)
  end

  def add_user
    @group = Group.find(params[:id])
    authorize @group
    @user = User.find(params[:user_id])
    if @group.users.include?(@user)
      flash = { error: "The user <strong>#{@user.login}</strong> " \
                       'already belongs to this group.'.html_safe }
    else
      @group.users << @user
      flash = { success: "The user <strong>#{@user.login}</strong> " \
                         'has been added.'.html_safe }
    end

    redirect_to group_path(@group), flash: flash
  end

  def form_merge_to
    @group = Group.departments.find(params[:id])
    authorize @group
  end

  def merge_to
    originator = Group.departments.find(params[:id])
    authorize originator
    receiver = Group.departments.find(params[:id_receiver].strip)

    originator.merge_to(receiver)

    redirect_to group_path(receiver), flash: { success: 'The group '\
                                                             'has been merged.' }
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end
  alias_method :update_group_params, :group_params

  def sort_and_filter(params)
    groups = Group.page(params[:page]).per(25)
    groups = groups.by_type(params[:type]) \
      if params[:type].present?
    search_terms = params[:search_terms].strip \
      if params[:search_terms].present?
    groups = groups.filter_by(search_terms, params[:sort_by]) \
      if params[:sort_by].present?
    groups
  end

  def ensure_presence_of_system_groups
    # NOTE: this list could be moved to Madek::Constants
    sysgroups = [
      {
        id: Madek::Constants::SIGNED_IN_USERS_GROUP_ID,
        name: 'Signed-in Users',
        type: 'AuthenticationGroup'
      },
      {
        id: Madek::Constants::BETA_TESTERS_QUICK_EDIT_GROUP_ID,
        name: 'Beta-Tester "Metadaten-Stapelverarbeitung"',
        institutional_id: 'beta_test_quick_edit',
        type: 'InstitutionalGroup'
      }
    ]
    sysgroups.each do |attrs|
      next if Group.find_by(id: attrs[:id].to_s, type: attrs[:type])
      Group.create!(
        id: attrs[:id].to_s, type: attrs[:type],
        name: attrs[:name], institutional_id: attrs[:institutional_id])
    end
  end
end
