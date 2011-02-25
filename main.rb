require 'rubygems'
require 'sinatra'
require 'ostruct'
require 'rack-flash'
require 'sinatra/redirect_with_flash'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "*.rb"
  c.also_reload "/lib/*.rb"
end

configure do
  App = OpenStruct.new(
        :db_base_key => 'swim'
        )  
end

use Rack::Flash
enable :sessions
layout :layout

get '/' do
  schedules = Schedule.all
  erb :list,  :locals => { :schedules => schedules}
end

get '/s/new' do
  erb :form, :locals => { :schedule => Schedule.new, :url => '/s' }
end

post '/s' do
  schedule = Schedule.create :body => params[:body], :tags => params[:tags], :slug => Schedule.make_slug(params[:body])
  redirect schedule.url, :notice => "Schedule successfull created"
end

get '/s/:slug/' do
	schedule = Schedule.find_by_slug(params[:slug])
	halt [ 404, "Page not found" ] unless schedule
	erb :schedule, :locals => { :schedule => schedule }
end

get '/s/tags/:tag' do
	tag = params[:tag].downcase.strip
	schedules = Schedule.find_tagged(tag)
	erb :tagged, :locals => { :schedules => schedules, :tag => tag }
end
