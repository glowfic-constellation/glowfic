class Api::V1::BoardSectionsController < Api::ApiController
  before_filter :login_required

  resource_description do
    name 'Subcontinuities'
    description 'Viewing and editing subcontinuities'
  end

  api! 'Update the order of subcontinuities (or, confusingly, posts). This may be moved or renamed and should not be trusted.'
  error 401, "You must be logged in"
  param :changes, Hash do
    param :section_id, Hash do
      param :type, ['BoardSection', 'Post']
      param :order, :number
    end
  end
  example "'errors': [{'message': 'You must be logged in to view that page.'}]"
  example "{}"
  def reorder
    valid_types = ['Post', 'BoardSection']

    BoardSection.transaction do
      params[:changes].each do |section_id, change_info|
        section_type = change_info[:type]
        next unless valid_types.include?(section_type)

        section = section_type.constantize.find_by_id(section_id)
        next unless section && section.board.editable_by?(current_user)

        section_order = change_info[:order]
        section.update_attributes(section_order: section_order)
      end
    end

    render json: {}
  end
end
