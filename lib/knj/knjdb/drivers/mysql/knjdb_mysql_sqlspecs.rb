class KnjDB_mysql::Sqlspecs < Knj::Db::Sqlspecs
  def strftime(val, colstr)
    return "DATE_FORMAT(#{colstr}, '#{val}')"
  end
end