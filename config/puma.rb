# JUST FOR EXAMPLE

workers 1
threads 1, 1

app_dir    = '/Users/nerzh/mydata/projects/web_sha256'
shared_dir = "#{app_dir}/shared"

simple_env = ENV['SIMPLE_ENV'] || "development"
environment simple_env

bind "unix://#{shared_dir}/puma.sock"

pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"

on_worker_boot do
end

if simple_env == 'production'
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
  daemonize
  preload_app!
else
  stdout_redirect false
  worker_timeout 3600
  worker_boot_timeout 3600
end