class BaseController < Controller::Base

  START_HASH = '0'
  PORT       = '80'
  IP         = '185.86.77.116'
  ID         = IP
  NAME       = 'woodcrust'

  def chain_service
    @chain_service ||= Chain::Process.new( base: DataBase::Base.new(REDIS), start_hash: START_HASH, port: PORT, ip: IP, id: ID, name: NAME )
  end
end