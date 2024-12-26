module CamaleonCms
  module Api
    module V1
      class SitemapController < BaseController
        def show
          r = { format: 'xml', custom: {} }
          hooks_run('on_render_sitemap', r)
          @sitemap_data = r[:custom]
          render json: { sitemap: @sitemap_data }
        end
      end  
    end
  end
end
