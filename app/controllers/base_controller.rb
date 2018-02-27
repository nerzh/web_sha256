class BaseController < Controller::Base

  START_HASH = '0'
  PORT       = '3000'
  IP         = '192.168.44.94'
  ID         = 94
  NAME       = 'woodcrust'

  def chain_service
    @chain_service ||= Chain::Process.new( base: DataBase::Base.new(REDIS), start_hash: START_HASH, port: PORT, ip: IP, id: ID, name: NAME )
  end
end