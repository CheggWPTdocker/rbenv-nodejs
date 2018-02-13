#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' if development?

configure {
  set :server, :puma
}

class Myapp < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  # app code goes here
  get '/' do
    "<p><strong>Hello</strong> World</p><p>This is <i>dynamic</i> content served via puma: #{rand(36**6).to_s(36)}"
  end

  run! if app_file == $0
end
