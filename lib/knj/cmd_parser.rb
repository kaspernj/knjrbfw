class Knj::Cmd_parser
  def self.lsl(str)
    ret = []
    
    str.lines.each do |line|
      next if line.match(/^total (\d+)$/)
      match = line.match(/^(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\s+(\d+)\s+(.+)\s+([^\W].+?)\s+(\d+)\s+(\d+)-(\d+)-(\d+)\s+(\d+):(\d+)\s+(.+)$/)
      raise "Could not match: '#{line}'." if !match
      
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
        :size => match[14].to_i,
        :time => Time.local(match[15].to_i, match[16].to_i, match[17].to_i, match[18].to_i, match[19].to_i),
        :file => match[20]
      }
    end
    
    return ret
  end
end