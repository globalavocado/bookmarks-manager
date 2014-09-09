require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require './lib/link' #this needs to be done after datamapper is initialised
require './lib/tag'
require './lib/user'
require_relative 'data_mapper_setup'
# require_relative 'helpers/application'

#However, the database tables don't exist yet. Let's tell datamapper to create them
DataMapper.auto_upgrade!

class Bookmarks < Sinatra::Base

	enable :sessions
	set :session_secret, 'super secret'
	use Rack::Flash

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
			flash[:errors] = @user.errors.full_messages
			erb :"users/new"
		end
	end

	helpers do
	  def current_user    
	    @current_user ||= User.get(session[:user_id]) if session[:user_id]
	  end
	end

end