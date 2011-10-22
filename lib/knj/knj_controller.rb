#This files makes the framework able to receive calls from the Rhodes framework from RhoMobile.
class KnjController < Rho::RhoController
	#GET /Server
	def index
		render
	end
	
	def html_links
		System.open_url(@params["url"])
	end
end