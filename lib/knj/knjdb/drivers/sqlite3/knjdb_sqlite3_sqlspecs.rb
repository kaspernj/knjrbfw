class KnjDB_sqlite3::Sqlspecs < Knj::Db::Sqlspecs
  def strftime(val, col_str)
    return "STRFTIME('#{val}', SUBSTR(#{col_str}, 0, 20))"
  end
end