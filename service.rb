require 'rubygems'
require 'environment'
require 'sinatra/base'
require "sinatra/reloader" unless ENV['RACK_ENV'].to_sym == :production

require 'ostruct'
require 'rack-flash'
require 'net/http'
require 'rack/recaptcha'
require 'pony'

require 'active_support/inflector'
require 'haml'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'all'
require 'helpers'

class Service < Sinatra::Base
  configure do |c|
    helpers Sinatra::MyHelper

    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5

    use Rack::Recaptcha, :public_key => ENV['ReCaptchaPublicKey'], :private_key => ENV['ReCaptchaPrivateKey']#, :paths => '/send_schedule'
    helpers Rack::Recaptcha::Helpers
  Pony.options ={:to => ENV['MAIL_TO'], :from=>ENV['MAIL_FORM'], :via => :smtp, :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => ENV['MAIL_USER'],
      :password             => ENV['MAIL_PASSWORD'],
      :authentication       => :plain,
      :domain               => "localhost.localdomain"
    }}
    enable :sessions
    use Rack::Flash
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
    created_at = Time.now
    schedule = Schedule.create :body => params[:body], :tags => params[:tags], :created_at => created_at, :slug => Schedule.make_slug(params[:body], created_at)
    flash[:notice] = 'Schedule successfull created'
    redirect schedule.url
  end

  get '/send_schedule' do
    haml :send_schedule, :locals => { :schedule => Schedule.new, :mail => ''}
  end

  post '/send_schedule' do
    created_at = Time.now
    schedule = Schedule.build :body => params[:body], :tags => params[:tags], :created_at => created_at, :slug => Schedule.make_slug(params[:body], created_at)
    if recaptcha_valid?
      flash[:error] = reCaptcha invalid!
      haml :send_schedule, :locals => { :schedule => schedule, :mail => params[:mail]}
    else
      Pony.mail(:subject => schedule.tags, :body => "#{params[:mail]}\n#{schedule.body}")
      flash[:notice] = 'email sent'
      redirect '/'
    end
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
