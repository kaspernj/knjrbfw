#This files makes the framework able to receive calls from the Rhodes framework from RhoMobile.
class KnjController < Rho::RhoController
  #GET /Server
  def index
    render
  end
  
  def html_links
    System.open_url(@params["url"])
  end
	
  def callback
    block = $rhodes.callbacks(@params["callback_id"])
    block.call(:params => @params)
  end
  
  def youtube_embed
		@iframe_height = System.get_property("screen_height").to_i - 40
		render :file => "Knj/rhodes/youtube_embed.erb"
  end
  
  def youtube_open
		render :file => "Knj/rhodes/youtube_open.erb"
  end
end