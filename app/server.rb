require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require './lib/link' #this needs to be done after datamapper is initialised
require './lib/tag'
require './lib/user'
require 'rest_client'
require_relative 'data_mapper_setup'
# require_relative 'helpers/application'

#However, the database tables don't exist yet. Let's tell datamapper to create them
DataMapper.auto_upgrade!

class Bookmarks < Sinatra::Base

	API_KEY = ENV['MAILGUN_API_KEY']
	API_URL = "https://api:#{API_KEY}@api.mailgun.net/v2/app29425848.mailgun.org"

	enable :sessions
	set :session_secret, 'super secret'
	use Rack::Flash
	use Rack::MethodOverride

	get '/' do	
		@links = Link.all
		erb :index
	end

	post '/links' do
		url   = params[:url]
		title = params[:title]
		tags = params["tags"].split(" ").map do |tag|
			#this will either find this tag or create
			#it if it doesn't exist already
			Tag.first_or_create(:text => tag)
		end
		Link.create(:title => title, 
					:url   => url,
					:tags   => tags)
		redirect to '/'
	end

	get '/tags/:text' do
		tag= Tag.first(:text => params[:text])
		@links = tag ? tag.links : []
		erb :index
	end

	get '/users/new' do
		@user = User.new
		erb :"users/new"
	end

	post '/users' do
	  @user = User.new(:email => params[:email], 
                     :password => params[:password],
                     :password_confirmation => params[:password_confirmation])  
		if @user.save
		  session[:user_id] = @user.id
		  redirect to('/')
		else
			flash.now[:errors] = @user.errors.full_messages
			erb :"users/new"
		end
	end

	get 'users/reset_password/:token' do
		user = User.first(:email => email)
		user.password_token = (1..64).map{('A'..'Z').to_a.sample}.join
		user.password_token_timestamp = Time.now
		user.save
	end

	get '/sessions/new' do
		erb :"sessions/new"
	end

	post '/sessions' do
		email, password = params[:email], params[:password]
		user = User.authenticate(email, password)
		if user
			session[:user_id] = user.id
			redirect to('/')
		else
			flash[:errors] = ["The email or password is incorrect"]
			erb :"sessions/new"
		end
	end

	delete '/sessions' do
		session[:user_id] = nil
		flash[:notice] = "Good bye!"
		redirect to('/')
	end



	helpers do
	  def current_user    
	    @current_user ||= User.get(session[:user_id]) if session[:user_id]
	  end

	  def send_message
			RestClient.post API_URL+"/messages",
	    :from => "ev@example.com",
	    :to => "ev@mailgun.net",
	    :subject => "This is subject",
	    :text => "Text body",
	    :html => "<b>HTML</b> version of the body!"
		end
	end

end