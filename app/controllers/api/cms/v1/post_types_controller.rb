module Api
  module Cms
    module V1
      class PostTypesController < BaseController
        include Rails.application.routes.url_helpers

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
        
          # Apply free-text search if the `query` parameter is present
          search_query = params[:query].to_s.strip
          posts = @post_type.the_posts
          categories = @post_type.categories.no_empty
          post_tags = @post_type.post_tags
        
          if search_query.present?
            # Search in posts, categories, and post tags
            post_query = posts.where("title ILIKE :query OR content ILIKE :query", query: "%#{search_query}%")
            categories = categories.where("name ILIKE :query", query: "%#{search_query}%")
            post_tags = post_tags.where("name ILIKE :query", query: "%#{search_query}%")

            # Combine all post IDs and fetch unique posts
            all_post_ids = (post_query.pluck(:id) + categories.flat_map(&:posts).map(&:id) + post_tags.flat_map(&:posts).map(&:id)).uniq
            posts = posts.where(id: all_post_ids)
          end

          posts = posts.paginate(page: params[:page], per_page: current_site.front_per_page).eager_load(:metas)
          categories = categories.eager_load(:metas).decorate
          post_tags = post_tags.eager_load(:metas)
        
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
                  data: posts.map do |post|
                    post.as_json.merge(
                      image: URI.join(request.base_url, post.get_meta('thumb')).to_s,
                      categories: post.categories.map { |category| { id: category.id, name: category.name, slug: category.slug } }
                    )
                  end
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
        
          render json: response_data, status: :ok
        end        
      end  
    end
  end
end
