class MainController < BaseController
  def index
    sha_service = Sha.new( DataBase::Base.new(REDIS) )
    sha_service.get_process(params['amount'])

    render json: { data: sha_service.response, status: 200, body_request: request.body.read }
  end

  def create
    sha_service = Sha.new( DataBase::Base.new(REDIS) )
    sha_service.set_process(params['data'])
    
    render json: { data: sha_service.response, status: 200, body_request: request.body.read }
  end
end