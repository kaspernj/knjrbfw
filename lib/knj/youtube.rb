class Knj::YouTube
  def self.all_videos(data, params = {}, opts = {})
    params[:per_page] = 50
    
    ret_arr = []
    go_through_pages = true
    page = 1
    while go_through_pages
      #print "Getting page #{page.to_s}\n"
      
      newparams = Marshal.load(Marshal.dump(params))
      newparams[:page] = page
      videos = data["youtube"].videos_by(newparams)
      
      videos.videos.each do |video|
        if data["check_stop"] and data["check_stop"].respond_to?("check_stop_parsing")
          if data["check_stop"].check_stop_parsing(video)
            go_through_pages = false
            break
          end
        end
        
        ret_arr << video
      end
      
      status = videos.next_page
      break if !status
      
      page += 1
      break if data["pages"] and page > data["pages"].to_i
    end
    
    return ret_arr
  end
end