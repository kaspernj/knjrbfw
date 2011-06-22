class Knj::Translations
	attr_accessor :args, :db, :ob, :cache
	
	def initialize(args)
		@args = args
		@cache = {}
		
		raise "No DB given." if !@args[:db]
		@db = @args[:db]
		
		@ob = Knj::Objects.new(
			:db => @args[:db],
			:extra_args => [self],
			:class_path => File.dirname(__FILE__),
			:module => Knj::Translations,
			:require => false,
			:datarow => true
		)
	end
	
	def get(obj, key, args = {})
		return "" if !obj
		
		if args[:locale]
			locale = args[:locale]
		else
			locale = @args[:locale]
		end
		
		classn = obj.class.name
		objid = obj.id.to_s
		
		if @cache[classn] and @cache[classn][objid] and @cache[classn][objid][key] and @cache[classn][objid][key][locale]
			return @cache[classn][objid][key][locale][:value]
		end
		
		trans = @ob.list(:Translation, {
			"object_class" => classn,
			"object_id" => objid,
			"key" => key,
			"locale" => locale
		})
		return "" if trans.empty?
		
		trans.each do |tran|
			if !@cache.has_key?(classn)
				@cache[classn] = {
					objid => {
						key => {
							locale => tran
						}
					}
				}
			elsif !@cache[classn][objid]
				@cache[classn][objid] = {
					key => {
						locale => tran
					}
				}
			elsif !@cache[classn][objid][key]
				@cache[classn][objid][key] = {
					locale => tran
				}
			elsif !@cache[classn][objid][key][locale]
				@cache[classn][objid][key][locale] = tran
			end
		end
		
		return trans[0][:value]
	end
	
	def set(obj, values, args = {})
		if args[:locale]
			locale = args[:locale]
		else
			locale = @args[:locale]
		end
		
		values.each do |key, val|
			trans = @ob.get_by(:Translation, {
				"object_id" => obj.id,
				"object_class" => obj.class.name,
				"key" => key,
				"locale" => locale
			})
			
			if trans
				trans.update(:value => val)
			else
				@ob.add(:Translation, {
					:object => obj,
					:key => key,
					:locale => locale,
					:value => val
				})
			end
		end
	end
	
	def delete(obj)
		classn = obj.class.name
		objid = obj.id.to_s
		
		trans = @ob.list(:Translation, {
			"object_id" => obj.id,
			"object_class" => obj.class.name
		})
		trans.each do |tran|
			@ob.delete(tran)
		end
		
		@cache[classn].delete(objid) if @cache.has_key?(classn) and @cache.has_key?(objid)
	end
end

class Knj::Translations::Translation < Knj::Datarow
	def self.add(d)
		if d.data[:object]
			d.data[:object_class] = d.data[:object].class.name
			d.data[:object_id] = d.data[:object].id
			d.data.delete(:object)
		end
	end
	
	def self.list(d)
		sql = "SELECT * FROM #{d.db.conn.escape_col}#{d.db.esc_col(table)}#{d.db.conn.escape_col} WHERE 1=1"
		ret = list_helper(d)
		
		d.args.each do |key, val|
			raise "No such key: #{key}."
		end
		
		sql += ret[:sql_where]
		sql += ret[:sql_order]
		sql += ret[:sql_limit]
		
		return d.ob.list_bysql(:Translation, sql)
	end
end