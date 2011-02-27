require 'rubygems'
require 'sinatra'
require 'ostruct'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require 'active_support/inflector'


$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'

require 'helpers'

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "*.rb"
  c.also_reload "lib/*.rb"
end

configure do
  App = OpenStruct.new(
        :db_base_key => 'swim'
        )
end

set :haml, :format => :html5

use Rack::Flash
enable :sessions

layout :layout


get '/' do
  cache_page
  schedules = Schedule.all
  haml :list,  :locals => { :schedules => schedules}
end

get '/:by_rank' do
  cache_page
  if params[:by_rank] == true
    schedules = Schedule.all_by_rank
  else
    schedules = Schedule.all
  end
  haml :list,  :locals => { :schedules => schedules}
end

get '/s/new' do
  cache_page
  haml :edit, :locals => { :schedule => Schedule.new, :url => '/s' }
end

post '/s' do
  schedule = Schedule.create :body => params[:body], :tags => params[:tags], :slug => Schedule.make_slug(params[:body])
  redirect schedule.url, :notice => "Schedule successfull created"
end

get '/s/:slug/' do
  cache_page
	schedule = Schedule.find_by_slug(params[:slug])
	items = Parser.parseSchedule(schedule.body, true)
	halt [ 404, "Page not found" ] unless schedule
	haml :schedule, :locals => { :schedule => schedule, :items => items }
end

get '/s/tags/:tag' do
  cache_page
	tag = params[:tag].downcase.strip
	schedules = Schedule.find_tagged(tag)
	haml :tagged, :locals => { :schedules => schedules, :tag => tag}
end
