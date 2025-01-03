module Api
  module Cms
    module V1
      class PostsController < BaseController
        # def index
        #   @posts = current_site.posts.published
        #   render json: @posts.map { |post| post.decorate.as_json }
        # end
  
        def show
          @post = current_site.the_posts.find_by(slug: params[:slug])
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
        
          @post = @post.decorate
          @object = @post
          @cama_visited_post = @post
          @post_type = @post.the_post_type
          @comments = @post.the_comments
          @categories = @post.the_categories
          @post_tags = @post.post_tags
        
          # Fetch the SEO metadata
          seo_meta = @post.get_meta('_default') || {}
          seo_data = seo_meta.is_a?(String) ? JSON.parse(seo_meta) : seo_meta
        
          # Build the JSON response
          response_data = {
            data: {
              id: @post.id,
              type: 'post',
              attributes: {
                title: @post.title,
                content: @post.content,
                content_filtered: @post.content_filtered,
                summary: @post.get_meta('summary'),
                slug: @post.slug,
                image: @post.get_meta('thumb'),
                created_at: @post.created_at,
                updated_at: @post.updated_at,
                seo_title: seo_data['seo_title'],
                keywords: seo_data['keywords'],
                seo_description: seo_data['seo_description'],
                seo_author: seo_data['seo_author'],
                seo_image: seo_data['seo_image'],
                seo_canonical: seo_data['seo_canonical']
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
