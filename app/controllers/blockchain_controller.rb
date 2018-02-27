class BlockchainController < BaseController
  def get_blocks
    chain_service.get_blocks(params['num_blocks'].to_i)
    render json: chain_service.response
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def receive_update
    chain_service.receive_update(JSON.parse(request.body.read))
    render json: chain_service.response
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def t
    p 'CONTROLLER T'
    p params
    # p request.body.read
    p JSON.parse(params.to_json)
    # chain_service.receive_update(JSON.parse(request.body.read))
    render json: {}
  # rescue => ex
    # render json: { success: false, status: 'error', message: ex.message }
  end
end