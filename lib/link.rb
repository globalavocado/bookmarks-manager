# This class corresponds to a table in the database
# We can use it to manipulate the data

class Link

	# This makes the instances of this class Datamapper resources
	include DataMapper::Resource

	# This block describes what resources out model will have
	property :id, 		Serial #Serial means that it will be auto-incremented for every record
	property :title,	String
	property :url, 		String

end

