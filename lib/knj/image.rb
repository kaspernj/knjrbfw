class Knj::Image
  #This function can make rounded transparent corners on an image with a given radius. Further more it can also draw borders around the entire image in a given color and take the border into account.
  def self.rounded_corners(args)
    raise "No or invalid ':img' given." if !args[:img]
    raise "No or invalid ':radius' given." if args[:radius].to_i <= 0
    
    pic = args[:img]
    
    r = args[:radius].to_i
    r_half = r / 2
    r2 = r * r
    d = r * 2
    
    center_x = r - 1
    center_y = 1
    
    coords = {}
    0.upto(r) do |x|
      y = center_y + Math.sqrt(r2 - ((x - center_x) * (x - center_x)))
      coords[x] = y.to_i
    end
    
    if args[:border]
      draw = Magick::Draw.new
      draw.stroke(args[:border_color])
      draw.stroke_width(1)
      
      0.upto(args[:border] - 1) do |x|
        draw.line(x, 0, x, pic.rows)
        draw.line(pic.columns-x-1, 0, pic.columns-x-1, pic.rows)
        
        draw.line(0, x, pic.columns, x)
        draw.line(0, pic.rows-x-1, pic.columns, pic.rows-x-1)
      end
      
      draw.draw(pic)
    end
    
    borders = [] if args[:border]
    
    1.upto(4) do |count|
      r.times do |x|
        border_from = nil
        border_to = nil
        border_mode = nil
        
        case count
          when 1
            x_from = x
            
            y_from = 0
            y_to = r - coords[x]
            
            if borders and x > 0 and x < r_half
              border_from = y_to
              border_to = r - coords[x - 1]
              border_to = 1 if border_to < 1
              
              #top left
              borders << {:x => x_from, :yf => border_from, :yt => border_to}
              borders << {:y => x_from, :xf => border_from, :xt => border_to}
              
              #top right
              borders << {:x => pic.columns - x - 1, :yf => border_from, :yt => border_to}
              borders << {:y => x_from, :xf => pic.columns - border_to, :xt => pic.columns - border_from}
              
              #bottom left
              borders << {:x => x_from, :yf => pic.rows - border_to, :yt => pic.rows - border_from}
              borders << {:y => pic.rows - x - 1, :xf => border_from, :xt => border_to}
              
              #bottom right
              borders << {:x => pic.columns - x - 1, :yf => pic.rows - border_to, :yt => pic.rows - border_from}
              borders << {:y => pic.rows - x - 1, :xf => pic.columns - border_to, :xt => pic.columns - border_from}
            end
          when 2
            x_from = pic.columns - r + x
            
            y_from = 0
            y_to = r - coords[r - x - 1]
          when 3
            x_from = x
            
            y_from = pic.rows - r + coords[x]
            y_to = pic.rows - y_from
          when 4
            x_from = pic.columns - r + x
            
            y_from = pic.rows - r + coords[r - x - 1]
            y_to = pic.rows - y_from
        end
        
        next if y_to <= 0
        
        #Make corners transparent.
        pixels = pic.get_pixels(x_from, y_from, 1, y_to)
        pixels.each do |pixel|
          pixel.opacity = Magick::TransparentOpacity
        end
        
        pic.store_pixels(x_from, y_from, 1, y_to, pixels)
      end
    end
    
    if borders
      borders.each do |border|
        if border.has_key?(:x)
          count_from = border[:yf]
          count_to = border[:yt]
        elsif border.has_key?(:y)
          count_from = border[:xf]
          count_to = border[:xt]
        end
        
        count_from.upto(count_to - 1) do |coord|
          pixel = Magick::Pixel.from_color(args[:border_color])
          
          if border.has_key?(:x)
            pic.pixel_color(border[:x], coord, pixel)
          elsif border.has_key?(:y)
            pic.pixel_color(coord, border[:y], pixel)
          end
        end
      end
    end
    
    pic.matte = true
  end
end