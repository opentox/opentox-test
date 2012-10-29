# File: helper.rb
# Purpose: Provide routines for tests
# Author: Andreas Maunz <andreas@maunz.de>

require 'uri'

class String
  def uri?
    uri = URI.parse(self)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end

def mkvar str
  a,v = str.chomp.split(": ")
  ENV[a] = v
end

