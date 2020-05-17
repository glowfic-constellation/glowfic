class Reply::Previwer < Reply::Service
  def perform
    @reply.assign_attributes(permitted_params)
  end
end
