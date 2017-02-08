class Api::V1::PostsController < Api::ApiController
  resource_description do
    description 'Viewing and editing posts'
  end

  api :GET, '/posts/:id', 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  example "'errors': [{'message': 'Post could not be found.'}]"
  example "'errors': [{'message': 'You do not have permission to perform this action.'}]"
  example "'data': {
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
  'status': 0,
  'character': {
    'id': 3,
    'name': 'Character Example',
    'screenname': 'char-example'
  },
  'icon': null,
  'replies': [{
    'id': 1,
    'content': 'dolor sit amet',
    'character': null,
    'icon': null,
    'user': {
      'id': 2,
      'username': 'Marri2'
    }
  }, {
    'id': 2,
    'content': 'consectetur adipiscing elit',
    'character': null,
    'icon': {
      'id': 7,
      'url': 'http://www.example.com/image.png',
      'keyword': 'icon'
    },
    'user': {
      'id': 1,
      'username': 'Marri1'
    }
  }],
}"
  def show
    unless post = Post.find_by_id(params[:id])
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless post.visible_to?(current_user)

    render json: {data: post}
  end
end
