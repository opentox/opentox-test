require_relative "setup.rb"

TEST_URI  ||= "http://only_a_test/test/" + rand(1000000).to_s

class TestOpenToxAuthorizationBasic < MiniTest::Test

  def setup
     skip unless $aa[:uri] # no authorization tests without opensso server.
     login
  end

  def teardown
    logout
  end

  def test_01_server
    @aaserver = $aa[:uri]
    assert_equal(@aaserver, OpenTox::Authorization.server)
  end
 
  def test_02_get_token
    refute_nil OpenTox::RestClientWrapper.subjectid
  end
  
  def test_03_is_valid_token
    assert OpenTox::Authorization.is_token_valid(OpenTox::RestClientWrapper.subjectid), "Token is not valid for user: #{$aa[:user]}, password: #{$aa[:password]}"
  end
  
  def test_04_logout
    assert logout
    assert_equal false, OpenTox::Authorization.is_token_valid(OpenTox::RestClientWrapper.subjectid)
  end
  
  def test_05_list_policies
    assert_kind_of Array, OpenTox::Authorization.list_policies
  end

  def test_06_bad_login
    logout
    assert_raises OpenTox::BadRequestError do
      OpenTox::Authorization.authenticate("blahhshshshsshsh", "blubbbbb")
    end
  end

  def test_07_unauthorized
    assert_equal false, OpenTox::Authorization.authorize("http://somthingnotexitstin/bla/8675940", "PUT")
  end

end

class TestOpenToxAuthorizationLDAP < MiniTest::Test

  def setup
    skip unless $aa[:uri] # no authorization tests without opensso server.
    login
  end

  def teardown
    logout
  end

  def test_01_list_user_groups
    assert_kind_of Array, OpenTox::Authorization.list_user_groups($aa[:user])
  end
  
  def test_02_get_user
    assert_equal $aa[:user], OpenTox::Authorization.get_user
  end

end

class TestOpenToxAuthorizationPolicy < MiniTest::Test

  def setup
     skip unless $aa[:uri] # no authorization tests without opensso server.
     login
  end

  def teardown
    logout
  end

  def test_01_create_check_delete_default_policies
    login
    res = OpenTox::Authorization.send_policy(TEST_URI)
    assert res
    assert OpenTox::Authorization.uri_has_policy(TEST_URI)
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI)
    assert_kind_of Array, policies
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy)
    end
    assert_equal false, OpenTox::Authorization.uri_has_policy(TEST_URI)
    logout
  end

  def test_02_check_policy_rules
    logout
    assert OpenTox::Authorization.authenticate("anonymous","anonymous")
    res = OpenTox::Authorization.send_policy(TEST_URI)
    assert res
    assert OpenTox::Authorization.uri_has_policy(TEST_URI)
    owner_rights = {"GET" => true, "POST" => true, "PUT" => true, "DELETE" => true}
    groupmember_rights = {"GET" => true, "POST" => false, "PUT" => false, "DELETE" => false}
    owner_rights.each do |request, right|
      assert_equal right, OpenTox::Authorization.authorize(TEST_URI, request), "#{$aa[:user]} requests #{request} to #{TEST_URI}"
    end
    groupmember_rights.each do |request, r|
      assert_equal r, OpenTox::Authorization.authorize(TEST_URI, request), "anonymous requests #{request} to #{TEST_URI}"
    end
    
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI)
    assert_kind_of Array, policies
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy)
    end
  end

  def test_03_check_different_uris
    res = OpenTox::Authorization.send_policy(TEST_URI)
    assert OpenTox::Authorization.uri_has_policy(TEST_URI)
    assert OpenTox::Authorization.authorize(TEST_URI, "GET"), "GET request"
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI)
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy)
    end
  end  
end


def logout
   OpenTox::Authorization.logout(OpenTox::RestClientWrapper.subjectid)
end

def login
  OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
end 
