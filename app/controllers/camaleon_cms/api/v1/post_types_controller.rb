module CamaleonCms
  module Api
    module V1
      class PostTypesController < BaseController
        def index
          @post_types = current_site.post_types
          render json: @post_types.map { |post_type| post_type.decorate.as_json }
        end

        def show
          begin
            @post_type = current_site.post_types.find(params[:id]).decorate
          rescue StandardError
            return render json: { errors: [{ title: 'Post Type Not Found', detail: 'The specified post type could not be found.' }] }, status: :not_found
          end
          # Prepare the data for posts, categories, and tags
          posts = @post_type.the_posts.paginate(page: params[:page], per_page: current_site.front_per_page).eager_load(:metas)
          categories = @post_type.categories.no_empty.eager_load(:metas).decorate
          post_tags = @post_type.post_tags.eager_load(:metas)
        
          # Create a JSON response structure based on the JSON API specification
          response_data = {
            data: {
              id: @post_type.id,
              type: 'post_type',
              attributes: {
                slug: @post_type.slug,
                name: @post_type.name,
                description: @post_type.description,
                created_at: @post_type.created_at,
                updated_at: @post_type.updated_at
              },
              relationships: {
                posts: {
                  data: posts.as_json
                },
                categories: {
                  data: categories.as_json
                },
                post_tags: {
                  data: post_tags.as_json
                }
              }
            },
            meta: {
              total_posts: posts.total_entries,
              total_pages: posts.total_pages,
              current_page: posts.current_page,
              per_page: current_site.front_per_page
            }
          }
        
          # Render the response as JSON
          render json: response_data, status: :ok
        end
      end  
    end
  end
end
