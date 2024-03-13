class AnalyticsController < ApplicationController
  def index
  end

  def load_embed_config
    @report_embed_config = Analytics::OAuth::GetEmbedConfig.new.call

    respond_to do |format|
      format.json {
        render json: @report_embed_config
      }
      format.html { redirect_to index_path }
    end
  end
end
