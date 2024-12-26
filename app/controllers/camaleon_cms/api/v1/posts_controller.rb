module CamaleonCms
  module Api
    module V1
      class PostsController < BaseController
        # def index
        #   @posts = current_site.posts.published
        #   render json: @posts.map { |post| post.decorate.as_json }
        # end
  
        def show
          @post = current_site.the_posts.find_by(id: params[:id])
          if params[:draft_id].present?
            draft_render
          else
            render_post(@post, true)
          end
        end

        private

        def draft_render
          post_draft = current_site.posts.drafts.find_by(id: params[:draft_id])
          return render json: { error: 'Draft not found' }, status: :not_found unless post_draft
        
          @object = post_draft
        
          # Let a hook override the ability for certain roles to see drafts
          args = { permitted: false }
          hooks_run('on_render_draft_permitted', args)
        
          if args[:permitted] || can?(:update, post_draft)
            render_post(post_draft, false, nil, true)
          else
            render json: { error: 'Not authorized to view this draft' }, status: :forbidden
          end
        end

        def render_post(post_or_slug_or_id, from_url = false, status = nil, force_visit = false)
          return render json: { error: 'Post not found' }, status: :not_found unless @post.present?
          # return render json: { error: 'Unauthorized' }, status: :forbidden unless force_visit || @post.can_visit?
        
          @post = @post.decorate
          @object = @post
          @cama_visited_post = @post
          @post_type = @post.the_post_type
          @comments = @post.the_comments
          @categories = @post.the_categories
          @post_tags = @post.post_tags
        
          # Increment post visits
          # @post.increment_visits!
        
          # Build the JSON response
          response_data = {
            data: {
              id: @post.id,
              type: 'post',
              attributes: {
                title: @post.title,
                content: @post.content,
                slug: @post.slug,
                created_at: @post.created_at,
                updated_at: @post.updated_at
                # visit_count: @post.visit_count
              },
              relationships: {
                post_type: {
                  data: {
                    id: @post_type.id,
                    type: 'post_type'
                  }
                },
                categories: @categories.map do |category|
                  { id: category.id, type: 'category', name: category.name }
                end,
                post_tags: @post_tags.map do |post_tag|
                  { id: post_tag.id, type: 'post_tag', name: post_tag.name }
                end,
                comments: @comments.map do |comment|
                  { id: comment.id, type: 'comment', content: comment.content }
                end
              }
            }
          }
        
          # Include hooks if `from_url` is true
          hooks_run('on_render_post', response_data) if from_url
        
          render json: response_data, status: status || :ok
        end        
      end  
    end
  end
end
