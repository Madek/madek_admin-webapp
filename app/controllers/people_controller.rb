class PeopleController < ApplicationController
  include ApplicationHelper
  include ::Filters
  include PreviousResource

  def index
    @people = Person.page(page_params).per(16)
    filter_with(
      { search_term: :search_by_term },
      :subtype
    )
    @people = @people.with_user if params[:with_user] == '1'
    if (merge_originator_id = params[:merge_originator_id]).presence
      @merge_originator = Person.find(merge_originator_id)
      @people = @people.where.not(id: @merge_originator.id)
    end
  end

  def show
    @person = Person.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    try_redirect_to_subsequent_resource
  end

  def edit
    @person = Person.find(params[:id])
    @identification_info_is_shown = AppSetting.first.person_info_fields.include?('identification_info')
  end

  def new
    @person = Person.new
  end

  def update
    find_person
    @person.update!(person_params)

    redirect_to person_path(@person), flash: {
      success: 'The person has been updated.'
    }
  rescue => e
    redirect_to edit_person_path(@person), flash: { error: e.to_s }
  end

  def create
    @person = Person.new(person_params)
    @person.save!

    redirect_to people_path, flash: {
      success: 'The person has been created.'
    }
  rescue => e
    flash.now[:error] = e.to_s
    render :new
  end

  def destroy
    find_person
    @person.destroy!

    redirect_to people_path, flash: {
      success: 'The person has been deleted.'
    }
  rescue => e
    redirect_to person_path(@person), flash: { error: e.to_s }
  end

  def merge_to
    find_person
    originator = Person.find(params[:originator_id])
    originator.merge_to(@person, current_user)
    flash[:success] = 'The person has been merged.'
  rescue => e
    flash[:error] = e.to_s
  ensure
    redirect_to people_path
  end

  private

  def find_person
    @person = Person.find(params[:id])
  end

  def person_params
    pp = params.require(:person).permit!
    pp.to_h.map { |k, v| [k, v.presence] }.to_h
      .merge(external_uris: parse_external_uris(pp[:external_uris]))
  end

end
