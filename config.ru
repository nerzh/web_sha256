require 'bundler'

# Because Bundler.require - dont work
Bundler.locked_gems.dependencies.keys.each do |gem_name|
  Gem.loaded_specs[gem_name].full_require_paths.each do |lib_path|
    Dir[lib_path + '/*.rb'].each { |full_path| require_relative full_path }
  end
end

module SimpleApp
  require File.join(File.dirname(__FILE__), 'config', 'main_application')
  require File.join(File.dirname(__FILE__), 'config', 'initialize')

  MainApp       = MainApplication.new
  InstanceRoute = BaseRoutes.new
  require File.join(File.dirname(__FILE__),'config', 'routes')
end

use Rack::Reloader
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'change_me',
                           :old_secret => 'also_change_me'
use Rack::Static, :urls => ['/images', '/css'], :root => 'public'

run SimpleApp::MainApp