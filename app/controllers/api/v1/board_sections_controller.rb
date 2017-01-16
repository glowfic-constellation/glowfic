class Api::V1::BoardSectionsController < Api::ApiController
  before_filter :login_required

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
