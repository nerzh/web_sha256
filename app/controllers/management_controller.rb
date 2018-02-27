class ManagementController < BaseController
  def add_transaction
    chain_service.add_transaction(params)

    render json: { success: true, status: 'success', message: chain_service.response }
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def add_link
    chain_service.add_link(params)
    render json: { success: true, status: 'success', message: chain_service.response }
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def status
    chain_service.get_status
    
    render json: chain_service.response
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end

  def sync
    chain_service.sync
    
    render json: { success: true, status: 'success', message: chain_service.response }
  rescue => ex
    render json: { success: false, status: 'error', message: ex.message }
  end
end