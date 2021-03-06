require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require './lib/link' #this needs to be done after datamapper is initialised
require './lib/tag'
require './lib/user'
require 'rest_client'
require 'mailgun'

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
                     :password_confirmation => params[:password_confirmation],
                     :password_token => nil,
                     :password_token_timestamp => nil)  
		if @user.save
		  session[:user_id] = @user.id
		  redirect to('/')
		else
			flash.now[:errors] = @user.errors.full_messages
			erb :"users/new"
		end
	end

	get '/users/password_reset_request' do
		erb :"users/password_reset_request"
	end

	post '/users/password_reset_request' do
		user = User.first(:email => params[:email])
		user.password_token = (1..9).map{('A'..'F').to_a.sample}.join
		user.password_token_timestamp = Time.now
		user.save
		send_message(params[:email], user.password_token)
		flash[:notice] = "Please check your email to complete your password reset!"
		redirect to('sessions/new')
	end

	get '/users/reset_password/:token' do
		erb :"users/password_reset_confirmation"
	end

	post '/users/reset_password' do
		user = User.first(:password_token => params[:token])
		user.password=(params[:password])
		flash[:notice] = "Your password has been reset, please sign in!"
		redirect to('sessions/new')
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

	  def send_message(user_email, password_token)
			RestClient.post API_URL+"/messages",
	    :from => "my@mail.com",
	    :to => user_email,
	    :subject => "Password Recovery",
	    :text => "Please click the following link, to recover your password: http://secret-brushlands-2777.herokuapp.com/users/reset_password/#{password_token}!"
		end
	end

end