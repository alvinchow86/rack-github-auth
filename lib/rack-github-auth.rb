#!/usr/bin/env ruby
# require 'rubygems'
require 'rack'

require 'omniauth'
require 'omniauth-github'

require 'sinatra/base'


GITHUB_CLIENT_ID =  ENV['GITHUB_CLIENT_ID']
GITHUB_SECRET = ENV['GITHUB_SECRET']
AUTHORIZED_USERS = ENV['AUTHORIZED_USERS']

authorized_users = AUTHORIZED_USERS ? AUTHORIZED_USERS.split(',') : []

class GitHubAuthApp < Sinatra::Base

  use Rack::Session::Pool, :expire_after => 86400

  use OmniAuth::Builder do
    provider :github, GITHUB_CLIENT_ID, GITHUB_SECRET, scope: "user:email"
  end

  AUTH_URL = '/auth/github'

  module Helpers
    def authorized?
      session.has_key? :user
    end

    def get_user
      session[:user]
    end

    def login_user(user)
      session[:user] = user
    end

    def logout_user
      session.delete :user
    end

  end

  helpers Helpers

  before do
    pass if request.path_info.start_with?(AUTH_URL)

    if !authorized?
      redirect to('/auth/github')
    end
  end

  get '/logout' do
    logout_user()
    return 200
  end

  get '/auth/github/callback' do
    user_info = request.env['omniauth.auth']['info']

    nickname = user_info['nickname']
    email = user_info['email']

    if AUTHORIZED_USERS.include? nickname
      user = {
        "nickname" => nickname,
        "email" => email
      }
      login_user(user)
      redirect to('/')
    end
    return 200
  end

end