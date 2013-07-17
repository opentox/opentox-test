require_relative "setup.rb"
unless $aa[:uri].to_s == ""
  $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
  $secondpi[:subjectid] = OpenTox::Authorization.authenticate($secondpi[:name], $secondpi[:password])
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid $pi[:subjectid]
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid $secondpi[:subjectid]
end
