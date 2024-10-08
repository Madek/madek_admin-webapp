class VocabulariesController < ApplicationController
  include LocalizedFieldParams

  def index
    @vocabularies = Vocabulary.with_meta_keys_count

    if (search_term = params[:search_term]).present?
      @vocabularies = @vocabularies.filter_by(search_term)
    end

    @vocabularies = @vocabularies.page(page_params).per(16)
  end

  def show
    @vocabulary = Vocabulary.find(params[:id])
    @meta_keys = load_meta_keys
  end

  def edit
    @vocabulary = Vocabulary.find(params[:id])
    @meta_keys = load_meta_keys
    @redirect_to = params[:redirect_to].presence || vocabularies_path
  end

  define_update_action_for(Vocabulary)

  def new
    @vocabulary = Vocabulary.new
  end

  def create
    @vocabulary = Vocabulary.new(new_vocabulary_params)
    @vocabulary.save!

    respond_with @vocabulary, location: (lambda do
      vocabularies_path
    end)
  end

  def destroy
    @vocabulary = Vocabulary.find(params[:id])
    @vocabulary.destroy!

    respond_with @vocabulary, location: (lambda do
      vocabularies_path
    end)
  end

  define_move_actions_for(Vocabulary) { vocabularies_path }

  private

  def new_vocabulary_params
    params.require(:vocabulary).permit!
  end

  def update_vocabulary_params
    params.require(:vocabulary).permit(:admin_comment,
                                       :enabled_for_public_view,
                                       :enabled_for_public_use,
                                       localized_field_params)
  end

  def load_meta_keys
    @vocabulary.meta_keys.with_keywords_count.page(page_params).per(16)
  end
end
