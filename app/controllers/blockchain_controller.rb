class BlockchainController < BaseController
  def get_blocks
    chain_service.get_blocks(params['num_blocks'].to_i)
    render json: chain_service.response
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def receive_update
    params = (params.nil? or params.empty?) ? JSON.parse(request.body.read) : params
    chain_service.receive_update(params)
    render json: { success: true, status: 'ok', message: chain_service.response.to_json }
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end
end