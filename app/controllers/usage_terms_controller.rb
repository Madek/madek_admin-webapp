class UsageTermsController < ApplicationController
  def index
    @usage_terms = UsageTerms.order(created_at: :desc)
  end

  def show
    @usage_terms = UsageTerms.find(params[:id])
  end

  def new
    @usage_terms = UsageTerms.new
  end

  def create
    usage_terms = UsageTerms.create!(usage_term_params)

    respond_with usage_terms, location: (lambda do
      usage_terms_path
    end)
  end

  def destroy
    usage_terms = UsageTerms.find(params[:id])
    usage_terms.destroy!

    respond_with usage_terms, location: (lambda do
      usage_terms_path
    end)
  end

  private

  def usage_term_params
    params.require(:usage_terms).permit!
  end
end
