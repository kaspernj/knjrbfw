class Knj::Translations
	attr_accessor :args, :db, :ob
	
	def initialize(args)
		@args = args
		
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
		
		@cache = {}
	end
	
	def get(obj, key, args = {})
		return "" if !obj
		
		if args[:locale]
			locale = args[:locale]
		else
			locale = @args[:locale]
		end
		
		classn = obj.class.name
		objid = obj.id
		
		if @cache[classn] and @cache[classn][objid] and @cache[classn][objid][key] and @cache[classn][objid][key][locale]
			return @cache[classn][objid][key][locale][:value]
		end
		
		trans = @ob.list(:Translation, {
			"object_class" => classn,
			"object_id" => objid,
			"key" => key,
			"locale" => locale
		})
		trans.each do |tran|
			if !@cache[classn]
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
				@cache[classn][objid][key][locale] =  tran
			end
		end
		
		return "" if trans.empty?
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
				"object" => obj,
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
		objid = obj.id
		
		trans = @ob.list(:Translation, {
			"object" => obj
		})
		trans.each do |tran|
			@ob.delete(tran)
		end
		
		@cache[classn].delete(objid)
	end
end

class Knj::Translations::Translation < Knj::Datarow
	def self.add(data, translations)
		if data[:object]
			data[:object_class] = data[:object].class.name
			data[:object_id] = data[:object].id
			data.delete(:object)
		end
	end
	
	def self.list(d)
		sql = "SELECT * FROM #{table} WHERE 1=1"
		
		ret = list_helper(d)
		
		args.each do |key, val|
			case key
				when "object"
					sql += " AND object_class = '#{val.class.name.sql}' AND object_id = '#{val.id.sql}'"
				else
					raise "No such key: #{key}."
			end
		end
		
		sql += ret[:sql_where]
		sql += ret[:sql_order]
		sql += ret[:sql_limit]
		
		return translations.ob.list_bysql(:Translation, sql)
	end
end