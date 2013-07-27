require_relative "setup.rb"
unless $aa[:uri].to_s == ""
  OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
  $pi[:subjectid] = OpenTox::RestClientWrapper.subjectid
  OpenTox::Authorization.authenticate($secondpi[:name], $secondpi[:password]) 
  $secondpi[:subjectid] = OpenTox::RestClientWrapper.subjectid
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid $pi[:subjectid]
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid $secondpi[:subjectid]
  OpenTox::Authorization.authenticate($aa[:user], $aa[:password])
end
