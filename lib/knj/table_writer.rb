class Knj::Table_writer
  def initialize(args = {})
    @args = args
    
    if !@args["filepath"]
      raise "No filepath was given."
    end
    
    if @args["format"] == "csv"
      @fp = File.open(@args["filepath"], "w")
    elsif @args["format"] == "excel"
      raise "Excel not supported."
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def write_row(arr)
    if @args["format"] == "csv"
      arr.each_index do |key|
        val = arr[key]
        
        if val.is_a?(Hash) and val["type"] == "decimal"
          arr[key] = Knj::Php.number_format(val["value"], @args["amount_decimals"], @args["amount_dsep"], @args["amount_tsep"])
        elsif val.is_a?(Hash) and val["type"] == "date"
          arr[key] = Knj::Php.date(@args["date_format"], val["value"])
        end
      end
      
      line_str = Knj::Csv.arr_to_csv(arr, @args["expl"], @args["surr"])
      
      #line_str = line_str.encode("iso8859-1") if @args["encoding"] == "iso8859-1"
      
      @fp.write(line_str)
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def close
    if @args["format"] == "csv"
      @fp.close
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def ext
    if @args["format"] == "csv"
      return "csv"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def ftype
    if @args["format"] == "csv"
      return "text/csv"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
end