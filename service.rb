require 'rubygems'
require 'environment'
require 'sinatra/base'
require "sinatra/reloader" unless ENV['RACK_ENV'].to_sym == :production

require 'ostruct'
require 'rack-flash'
require 'active_support/inflector'
require 'haml'

require 'json'

require 'omniauth'
require 'open_id/store/redis'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'
require 'helpers'
require 'omniauthdata'

class Service < Sinatra::Base
  configure do |c|
    helpers Sinatra::MyHelper

    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5

    use OmniAuth::Builder do
        provider :facebook, FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, { :scope => 'email, publish_stream' }
        provider :twitter, TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET
        provider :open_id, OpenID::Store::Redis.new($redis)
        provider :google_apps, OpenID::Store::Redis.new($redis)
        provider :github, GITHUB_CLIENT_ID, GITHUB_SECRET
    end

    enable :sessions
    use Rack::Flash
    layout :layout
  end
 
  configure :development do |c|
    register Sinatra::Reloader
    c.also_reload "lib/*.rb"
  end
  
  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:provider] = auth['provider']
    session[:uid] = auth['uid']
    session[:name] = auth['user_info']['name']
    session[:nickname] = auth['user_info']['nickname']
    redirect request.env['omniauth.origin'] || '/'
  end
  get '/auth/failure' do
    clear_session
    flash[:error] = 'In order to use the advanced featues of the site you must allow us access to your Accounts data'
    redirect '/'
  end

  get '/signout' do
    clear_session
    flash[:notice] = "Signed out!"
    redirect '/'
  end

  get '/' do
    cache_page
    page = params[:page].to_i
    if params[:sort] == 'by_rank'
      schedules = Schedule.all_by_rank
      by_rank = true
    else
       schedules = Schedule.all
      by_rank = false
    end
    haml :list,  :locals => { :schedules => schedules, :by_rank => by_rank}
  end

  get '/new' do
    cache_page
    haml :edit, :locals => { :schedule => Schedule.new, :url => '/' }
  end

  post '/' do
    created_at = Time.now
    schedule = Schedule.create :body => params[:body], :tags => params[:tags], :created_at => created_at, :slug => Schedule.make_slug(params[:body], created_at)
    flash[:notice] = 'Schedule successfull created'
    redirect schedule.url
  end

  get '/:slug' do
    cache_page
    schedule = Schedule.find_by_slug(params[:slug])
    items = Parser.parseSchedule(schedule.body, true)
    halt [ 404, "Page not found" ] unless schedule
    haml :schedule, :locals => { :schedule => schedule, :items => items }
  end

  get '/tags/:tag' do
    cache_page
    tag = params[:tag].downcase.strip
    schedules = Schedule.find_tagged(tag)
    haml :list_tagged, :locals => { :schedules => schedules, :tag => tag}
  end

  post '/:slug/uprank' do
    Schedule.uprank(params[:slug]).to_s
  end

  get '/:slug/edit' do
    schedule = Schedule.find_by_slug(params[:slug])
    halt [ 404, "Page not found" ] unless schedule
    haml :edit, :locals => { :schedule => schedule, :url => schedule.url }
  end

  post '/:slug' do
    schedule = Schedule.find_by_slug(params[:slug])
    halt [ 404, "Page not found" ] unless schedule
    schedule.update(params[:body],params[:tags])
    flash[:notice] = "Schedule successfull updated"
    redirect schedule.url
  end

  # start the server if ruby file executed directly
  app_file = "service.rb"
  run! if app_file == $0
end
