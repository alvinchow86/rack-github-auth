#!/usr/bin/env ruby
require 'rack'

require 'omniauth'
require 'omniauth-github'

require 'sinatra/base'


GITHUB_CLIENT_ID =  ENV['GITHUB_CLIENT_ID']
GITHUB_SECRET = ENV['GITHUB_SECRET']
AUTHORIZED_USERS = ENV['AUTHORIZED_USERS']
SECRET_KEY = ENV['SECRET_KEY']

authorized_users = AUTHORIZED_USERS ? AUTHORIZED_USERS.split(',') : []

class GitHubAuthApp < Sinatra::Base

  # Ideally figure out a way for the calling app to set this..
  use Rack::Session::Cookie,
                           :expire_after => 86400, # In seconds
                           :secret => SECRET_KEY

  use OmniAuth::Builder do
    provider :github, GITHUB_CLIENT_ID, GITHUB_SECRET, scope: "user:email"
  end

  AUTH_URL = '/auth/github'

  def initialize(app, params={})
    super(app)
  end

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

      # Store gollum author
      # TODO figure out how to make this a configurable callback function
      session['gollum.author'] = {
        :name => nickname,
        :email => email
      }

      login_user(user)
      redirect to('/')
    end
    return 200
  end

end
