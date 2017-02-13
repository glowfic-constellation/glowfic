class Api::V1::PostsController < Api::ApiController
  resource_description do
    description 'Viewing and editing posts'
  end

  api! 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  example "'errors': [{'message': 'Post could not be found.'}]"
  example "'errors': [{'message': 'You do not have permission to perform this action.'}]"
  example "{
  'id': 1,
  'user': {
    'id': 1,
    'username': 'Marri1'
  },
  'board': {
    'id': 5,
    'name': 'Continuity'
  },
  'section': {
    'id': 6,
    'name': 'Subcontinuity',
    'order': 0
  },
  'subject': 'search',
  'description': 'example json',
  'content': 'Lorem ipsum...',
  'created_at': '2000-01-07T01:02:03Z',
  'edited_at': '2000-01-07T01:03:03Z',
  'tagged_at': '2000-01-08T01:02:03Z',
  'status': 0,
  'character': {
    'id': 3,
    'name': 'Character Example',
    'screenname': 'char-example'
  },
  'icon': {
    'id': 4,
    'url': 'http://www.example.com/image.png',
    'keyword': 'icon'
  }
}"
  def show
    unless post = Post.find_by_id(params[:id])
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless post.visible_to?(current_user)
    render json: post
  end
end
