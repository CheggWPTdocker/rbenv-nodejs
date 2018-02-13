#!/bin/sh

eval "$(rbenv init -)"
exec nginx -g "daemon off;" &
exec bundle exec puma --config /app/puma-config.rb