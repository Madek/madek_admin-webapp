require 'spec_helper'

describe PeopleController do
  let!(:admin_user) { create :admin_user }
  let(:session) { { user_id: admin_user.id } }

  describe '#index' do
    it 'responds with HTTP 200 status code' do
      get :index, nil, session

      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'loads the first page of people into @people' do
      get :index, nil, session

      expect(response).to be_success
      expect(assigns(:people)).to eq Person.first(16)
    end

    describe 'filtering people' do
      context 'by first name' do
        it "returns users containing 'xxx' in first name" do
          person_1 = create :person, first_name: 'test1xxx'
          person_2 = create :person, first_name: 'test2xxx'
          person_3 = create :person, first_name: 'test3xxx'

          get :index, { filter: { search_term: 'xxx' } }, session

          expect(response).to be_success
          expect(assigns(:people)).to match_array [person_1, person_2, person_3]
        end
      end

      context 'with user' do
        it 'returns only people with user' do
          get :index, { with_user: 1 }, session

          expect(response).to be_success
          expect(assigns(:people)).to match_array Person.with_user
        end
      end

      context 'by subtype' do
        let!(:person) { create :person, first_name: 'Foo' }
        let!(:people_group) { create :people_group, first_name: 'Foo' }
        let!(:people_instgroup) { create :people_instgroup, first_name: 'Foo' }

        it 'returns only people with "Person" subtype' do
          get :index, filter_params('Person'), session

          expect(response).to be_success
          expect(assigns[:people]).to include person
          expect(assigns[:people]).not_to include people_group
          expect(assigns[:people]).not_to include people_instgroup
        end

        it 'returns only people with "PeopleGroup" subtype' do
          get :index, filter_params('PeopleGroup'), session

          expect(response).to be_success
          expect(assigns[:people]).to include people_group
          expect(assigns[:people]).not_to include person
          expect(assigns[:people]).not_to include people_instgroup
        end

        it 'returns only people with "PeopleInstitutionalGroup" subtype' do
          get :index, filter_params('PeopleInstitutionalGroup'), session

          expect(response).to be_success
          expect(assigns[:people]).to include people_instgroup
          expect(assigns[:people]).not_to include person
          expect(assigns[:people]).not_to include people_group
        end

        def filter_params(subtype)
          { filter: { search_term: 'Foo', subtype: subtype } }
        end
      end
    end

    describe 'merging' do
      let(:originator) { create :person }
      let(:receiver)   { create :person }

      it 'assigns @merge_originator if given' do
        get :index, { merge_originator_id: originator.id }, session

        expect(assigns[:merge_originator]).to eq originator
      end
    end
  end

  describe '#show' do
    before do
      @person = create :person
    end

    it 'responds with HTTP 200 status code' do
      get :show, { id: @person.id }, session

      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get :show, { id: @person.id }, session

      expect(response).to render_template(:show)
    end

    it 'loads the proper person into @person' do
      get :show, { id: @person.id }, session

      expect(assigns[:person]).to eq @person
    end
  end

  describe '#edit' do
    before do
      @person = create :person
    end

    it 'responds with HTTP 200 status code' do
      get :edit, { id: @person.id }, session

      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'render the edit template and assigns the person to @person' do
      get :edit, { id: @person.id }, session

      expect(response).to render_template(:edit)
      expect(assigns[:person]).to eq @person
    end
  end

  describe '#update' do
    before do
      @person = create :person
    end

    it 'redirects to admin person show page' do
      patch(
        :update,
        { id: @person.id, person: { first_name: 'test' } },
        session
      )

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(person_path(@person))
    end

    it 'updates the person' do
      patch(
        :update,
        { id: @person.id, person: { first_name: 'test' } },
        session
      )

      expect(flash[:success]).to eq 'The person has been updated.'
      expect(@person.reload.first_name).to eq 'test'
    end

    it 'displays error message when something went wrong' do
      patch :update, { id: @person.id }, session

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(edit_person_path(@person))
      expect(flash[:error]).not_to be_nil
    end
  end

  describe '#create' do
    it 'redirects to admin people path after successfuly created person' do
      post :create, { person: attributes_for(:person) }, session

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(people_path)
      expect(flash[:success]).to eq(
        'The person has been created.')
    end

    it 'creates a person' do
      expect do
        post :create, { person: attributes_for(:person) }, session
      end.to change { Person.count }.by(1)
    end

    context 'when validation failed' do
      it "renders 'new' template" do
        post :create, nil, session

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(flash[:error]).to be_present
      end

      it 'assigns @person with previously given values' do
        attributes = { first_name: 'example_name' }
        post :create, { person: attributes }, session

        expect(assigns[:person].first_name).to eq 'example_name'
      end
    end
  end

  describe '#destroy' do
    let!(:person) { create :person }

    it 'redirects to admin people path after succesful destroy' do
      delete :destroy, { id: person.id }, session

      expect(response).to redirect_to(people_path)
      expect(flash[:success]).to eq 'The person has been deleted.'
    end

    it 'destroys the person' do
      expect do
        delete :destroy, { id: person.id }, session
      end.to change { Person.count }.by(-1)
    end
  end

  describe '#merge_to' do
    let(:originator) { create :person }
    let(:receiver)   { create :person }

    it 'redirects to /people with success message' do
      post :merge_to, { id: receiver.id, originator_id: originator.id }, session

      expect(response).to redirect_to people_path
      expect(flash[:success]).not_to be_empty
    end

    context 'when an error occures' do
      it 'redirects to /people with error message' do
        allow_any_instance_of(Person).to receive(:merge_to)
                                           .and_raise(ActiveRecord::RecordNotFound)

        post :merge_to, { id: receiver.id, originator_id: originator.id }, session

        expect(response).to redirect_to people_path
        expect(flash[:error]).not_to be_empty
      end
    end
  end
end
