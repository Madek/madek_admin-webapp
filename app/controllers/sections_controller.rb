class SectionsController < ApplicationController
  include LocalizedFieldParams

  def index
    @section_meta_key = MetaKey.find_by(id: AppSetting.first.section_meta_key_id)
    keywords = @section_meta_key.try(:keywords) || []
    misconfigured_keywords = Section.all
      .map { |x| x.keyword }
      .filter { |x| !keywords.include?(x) }
    @keywords = keywords.to_a.concat(misconfigured_keywords.to_a)
  end

  def edit
    @section = Section.find(params[:id])
  end

  def update
    @section = Section.find(params[:id])
    @section.update!(section_params)

    redirect_to action: "index"
  end

  def new
    @keyword = Keyword.find(params[:keyword_id])
    @section = Section.new keyword: @keyword, labels: {de: @keyword.term}
  end

  def create
    @keyword = Keyword.find(params[:keyword_id])
    @section = Section.new section_params.merge(keyword: @keyword)
    @section.save!()

    redirect_to action: "index"
  end
  
  def destroy
    @section = Section.find(params[:id])
    @section.destroy!

    redirect_to action: "index"
  end

  private

  def section_params
    kp = params.require(:section)
               .permit(:color, localized_field_params, :index_collection_id)
  end

end
