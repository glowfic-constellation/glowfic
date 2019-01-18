class Generic::Saver < Generic::Service
  def initialize(model, user:, params:, allowed_params: [])
    super()
    @user = user
    @params = params
    @model = model
    @allowed = allowed_params if allowed_params.present?
  end

  def perform
    build
    save!
  end

  alias create! perform
  alias update! perform

  private

  def build
    @model.assign_attributes(permitted_params)
  end

  def save!
    @model.save!
  end

  def permitted_params
    @params.fetch(@model.class.name.underscore.to_sym, {}).permit(@allowed)
  end
end
