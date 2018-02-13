#!/bin/sh

exec nginx -g "daemon off;" &
exec bundle exec puma --config /app/puma-config.rb
