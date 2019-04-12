class PeopleController < ApplicationController
  include Concerns::Filters

  def index
    @people = Person.page(params[:page]).per(16)
    filter_with(
      { search_term: :search_by_term },
      :subtype
    )
    @people = @people.with_user if params[:with_user] == '1'
    if (merge_originator_id = params[:merge_originator_id]).presence
      @merge_originator = Person.find(merge_originator_id)
      @people = @people.where.not(id: @merge_originator.id)
    end
    @people = @people.admin_with_usage_count
  end

  def show
    @person = Person.find(params[:id])
  end

  def edit
    @person = Person.find(params[:id])
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
    pp.map { |k, v| [k, v.presence] }.to_h
    pp.merge(external_uris: parse_external_uris(pp.external_uris))
  end

  def parse_external_uris(text)
    text.split("\n").map do |line|
      begin
        uri = URI.parse(line.strip)
        # cleanup
        uri.user = nil
        uri.password = nil
        # ok
        uri.to_s
      rescue
        nil
      end
    end.compact
  end
end
