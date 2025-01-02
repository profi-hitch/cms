module Api
  module Cms
    module V1
      class CommentsController < BaseController
        def create
          @post = current_site.posts.find_by_id(params[:post_id])
          if @post.present? && @post.can_commented?
            comment_data = {
              content: params[:content],
              author: params[:author],
              author_email: params[:author_email],
              approved: current_site.front_comment_status
            }
            @comment = @post.comments.new(comment_data)
            if @comment.save
              render json: { message: "Comment added successfully" }, status: :created
            else
              render_error(@comment.errors.full_messages.join(", "))
            end
          else
            render_error("Cannot add comment to this post", :unprocessable_entity)
          end
        end
      end
    end
  end
end
