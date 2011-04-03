module Knj::Errors
	class Notice < StandardError; end
	class NotFound < StandardError; end
	class InvalidData < StandardError; end
	class Retry < StandardError; end
end