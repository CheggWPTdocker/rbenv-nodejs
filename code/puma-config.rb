root = "#{Dir.getwd}"

bind "unix://#{root}/puma/socket"
pidfile "#{root}/puma/pid"
state_path "#{root}/puma/state"
rackup "#{root}/config.ru"

threads 1,16
workers 4

activate_control_app
