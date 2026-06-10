class KeywordsController < ApplicationController
  def index
    @keywords = current_organization.keywords.order(:word).includes(:tag)
    @keyword = current_organization.keywords.new
  end

  def create
    @keyword = current_organization.keywords.new(keyword_params)
    if @keyword.save
      redirect_to keywords_path, notice: "Keyword added."
    else
      redirect_to keywords_path, alert: @keyword.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_organization.keywords.find(params[:id]).destroy
    redirect_to keywords_path, notice: "Keyword removed."
  end

  private

  def keyword_params
    permitted = params.require(:keyword).permit(:word, :reply_body, :tag_name)
    tag_name = permitted.delete(:tag_name)
    permitted[:tag] = current_organization.tags.find_or_create_by!(name: tag_name.strip) if tag_name.present?
    permitted
  end
end
