require 'sinatra'
require 'data_mapper'

env = ENV["RACK_ENV"] || "development"
# we're telling datamapper to user a postgres database on localhost. The name will be "bookmark_manager_test" or "bookmark_manager_development" depending on the environment
DataMapper.setup(:default, "postgres://localhost/bookmark_manager_#{env}")

require './lib/link' #this needs to be done after datamapper is initialised
require './lib/tag'

#After declaring your models, you should finalise them
DataMapper.finalize

#However, the database tables don't exist yet. Let's tell datamapper to create them
DataMapper.auto_upgrade!


class Bookmarks < Sinatra::Base

	set :views, Proc.new { File.join(root, "..", "views") }

	get '/' do
		@links = Link.all
		erb :index
	end

	post '/links' do
		# raise params.inspect
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

end