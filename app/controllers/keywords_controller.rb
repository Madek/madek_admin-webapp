class KeywordsController < ApplicationController
  def index
    @vocabularies = Vocabulary.sorted
    if filter_value(:vocabulary_id).present?
      @vocabulary = Vocabulary.find(filter_value(:vocabulary_id))
      @keywords = Keyword.of_vocabulary(@vocabulary.id)
    else
      @keywords = Keyword.all
    end
    @keywords = @keywords.order(:meta_key_id, :term).page(params[:page]).per(16)
    filter
    @usage_counts = Keyword.usage_count_for(@keywords)
    @current_meta_key = nil
  end

  def edit
    @keyword = Keyword.find(params[:id])
    @vocabulary = @keyword.meta_key.vocabulary
  end

  def update
    @keyword = Keyword.find(params[:id])
    @keyword.update!(keyword_params)
    @vocabulary = @keyword.meta_key.vocabulary

    respond_with @keyword, location: (lambda do
      keywords_path(filter: { vocabulary_id: @vocabulary.id })
    end)
  end

  def new
    @vocabulary = Vocabulary.find(params[:vocabulary_id])
    @keyword = Keyword.new
  end

  def create
    @keyword = Keyword.new(keyword_params)
    @keyword.creator_id = current_user.id
    @keyword.save!
    @vocabulary = @keyword.meta_key.vocabulary

    respond_with @keyword, location: (lambda do
      params[:redirect_to] ||
        keywords_path(filter: { vocabulary_id: @vocabulary.id })
    end)
  end

  def destroy
    @keyword = Keyword.find(params[:id])
    @vocabulary = @keyword.meta_key.vocabulary
    if @keyword.not_used?
      @keyword.destroy!
    else
      raise ActiveRecord::ActiveRecordError, 'The keyword is used' \
                                             'and cannot be deleted.'
    end

    respond_with @keyword, location: (lambda do
      params[:redirect_to] ||
        keywords_path(filter: { vocabulary_id: @vocabulary.id })
    end)
  end

  define_move_actions_for(Keyword) { |keyword| meta_key_path(keyword.meta_key) }

  def usage
    @keyword = Keyword.find(params[:id])
    @usage_count = Keyword
                    .usage_count_for(@keyword)
                    .fetch(@keyword.id, 0)
    @media_entries =
      MediaEntry
        .unscoped
        .where(id: @keyword.meta_data.pluck(:media_entry_id))
        .page(params[:page]).per(16)
  end

  def form_merge_to
    @keyword = Keyword.find(params[:id])
  end

  def merge_to
    @originator = Keyword.find(params[:id])
    @receiver = Keyword.find(params[:id_receiver].strip)

    if @originator.id == @receiver.id
      flash[:error] = 'The keyword cannot be merged to itself!'
      redirect_to form_merge_to_keyword_path(@originator) and return
    end

    @originator.merge_to(@receiver)

    flash[:success] = 'The keyword has been merged.'

    respond_with @receiver, location: (lambda do
      params[:redirect_to] || keyword_path(search_term: @receiver.term)
    end)
  end

  private

  def keyword_params
    params.require(:keyword).permit(:term, :meta_key_id)
  end

  def filter
    term = params[:search_term]

    if term.present?
      term.strip!
      @keywords =
        if UUIDTools::UUID_REGEXP =~ term
          @keywords.where('keywords.id = ?', term)
        else
          @keywords.where(
            'keywords.meta_key_id = ? OR keywords.term ILIKE ?', term, "%#{term}%"
          )
        end
    end
  end
end
