require 'rubygems'
require 'sinatra/base'
require 'sinatra/redirect_with_flash'
require "sinatra/reloader"

require 'ostruct'
require 'rack-flash'
require 'active_support/inflector'
require 'haml'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'
require 'helpers'

class Service < Sinatra::Base
  configure do |c|
    register Sinatra::RedirectWithFlash
    helpers Sinatra::MyHelper

    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5

    use Rack::Flash, :sweep => true
    enable :sessions    
    layout :layout
  end

  configure :development do |c|
    register Sinatra::Reloader
    c.also_reload "lib/*.rb"
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
    schedule = Schedule.create :body => params[:body], :tags => params[:tags], :created_at => Time.now, :slug => Schedule.make_slug(params[:body])
    redirect schedule.url#, :notice => "Schedule successfull created"
  end

  get '/:slug/' do
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

  post '/:slug/' do
    schedule = Schedule.find_by_slug(params[:slug])
    halt [ 404, "Page not found" ] unless schedule
    schedule.update(params[:body],params[:tags])
    redirect schedule.url#, :notice => "Schedule successfull updated"
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end