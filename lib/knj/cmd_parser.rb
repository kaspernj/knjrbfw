#This class can help you parse results from command-line commands.
class Knj::Cmd_parser
  #Parses the results of "ls -l".
  #===Examples
  # str = %x[ls -l]
  # Knj::Cmd_parser.lsl(str) #=> <Array> holding a lot of info about the various listed files.
  def self.lsl(str, args = {})
    ret = []
    
    str.lines.each do |line|
      next if line.match(/^total ([\d\.,]+)(M|k|G|)$/)
      match = line.match(/^(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\s+(\d+)\s+(.+)\s+([^\W].+?)\s+([\d\.,]+)(M|k|G|K|)\s+((\d+)-(\d+)-(\d+)|(([A-z]{3})\s+(\d+)))\s+((\d+):(\d+)|(\d{4}))\s+(.+)$/)
      raise "Could not match: '#{line}'." if !match
      
      year = nil
      
      if match[17].to_i > 0
        year = match[17].to_i
      elsif match[26].to_i > 0
        year = match[26].to_i
      end
      
      hour = match[24].to_i
      min = match[25].to_i
      
      if match[17] and match[18] and match[19]
        month = match[18].to_i
        date = match[19].to_i
      elsif match[20] and match[21] and match[22]
        month = Datet.month_str_to_no(match[21])
        date = match[22].to_i
      end
      
      if !year
        if month > Time.now.month
          year = Time.now.year - 1
        else
          year = Time.now.year
        end
      end
      
      time = Time.local(year, month, date, hour, min)
      bytes = match[14].gsub(",", ".").to_f
      
      size_match = match[15]
      if size_match == ""
        #bytes - dont touch
      elsif size_match.downcase == "k"
        bytes = bytes * 1024
      elsif size_match == "M"
        bytes = bytes * 1024 * 1024
      elsif size_match == "G"
        bytes = bytes * 1024 * 1024 * 1024
      else
        raise "Unknown size match: '#{size_match}'."
      end
      
      ret << {
        :mod => {
          :usr => {
            :read => match[2],
            :write => match[3],
            :exec => match[4]
          },
          :grp => {
            :read => match[5],
            :write => match[6],
            :exec => match[7]
          },
          :all => {
            :read => match[8],
            :write => match[9],
            :exec => match[10]
          }
        },
        :usr => match[12],
        :grp => match[13],
        :size => bytes.to_i,
        :time => time,
        :file => match[27]
      }
    end
    
    return ret
  end
end