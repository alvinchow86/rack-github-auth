#!/usr/bin/env ruby
require 'rack'

require 'omniauth'
require 'omniauth-github'
require 'octokit'

require 'sinatra/base'


class GitHubAuthApp < Sinatra::Base

  GITHUB_CLIENT_ID =  ENV['GITHUB_CLIENT_ID']
  GITHUB_SECRET = ENV['GITHUB_SECRET']
  AUTHORIZED_USERS = ENV['AUTHORIZED_USERS']
  AUTHORIZED_ORG = ENV['AUTHORIZED_ORG']
  SECRET_KEY = ENV['SECRET_KEY']

  authorized_users = AUTHORIZED_USERS ? AUTHORIZED_USERS.split(',') : []

  # Ideally figure out a way for the calling app to set this..
  use Rack::Session::Cookie,
                           :expire_after => 86400, # In seconds
                           :secret => SECRET_KEY

  use OmniAuth::Builder do
    provider :github, GITHUB_CLIENT_ID, GITHUB_SECRET, scope: "user:email,read:org"
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
    auth_hash =request.env['omniauth.auth']

    user_info = auth_hash['info']
    credentials = auth_hash['credentials']

    # Construct Github API client, for checking organization
    client = Octokit::Client.new(:access_token => credentials['token'])

    username = user_info['nickname']
    email = user_info['email']

    authorized = false
    if authorized_users.include? username
      authorized = true;
    elsif AUTHORIZED_ORG && client.org_member?(AUTHORIZED_ORG, client.user.login)
      authorized = true
    end

    if authorized
      user = {
        "username" => username,
        "email" => email
      }

      # Store gollum author
      # TODO figure out how to make this a configurable callback function
      session['gollum.author'] = {
        :name => username,
        :email => email
      }

      login_user(user)
      redirect to('/')
    end
    return 200
  end

end
