module Api
  module Cms
    module V1
      class BaseController < CamaleonCms::CamaleonController
        before_action :set_default_format
        skip_before_action :verify_authenticity_token
        include CamaleonCms::FrontendConcern
        include CamaleonCms::Frontend::ApplicationHelper

        private

        def set_default_format
          request.format = :json
        end

        def render_error(message, status = :unprocessable_entity)
          render json: { error: message }, status: status
        end
      end
    end
  end
end
