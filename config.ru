require 'gollum/app'
require './github_auth'


module Precious
  class App < Sinatra::Base
    # use GitHubAuthApp
  end
end

gollum_path = File.expand_path(File.dirname(__FILE__)) # CHANGE THIS TO POINT TO YOUR OWN WIKI REPO
wiki_options = {
    :universal_toc => false,
    :allow_uploads => true,
    :live_preview => true,
    :css => true
  }
Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:default_markup, :markdown) # set your favorite markup language
Precious::App.set(:wiki_options, wiki_options)

run Precious::App
