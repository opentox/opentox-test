require_relative "setup.rb"

TEST_URI  = "http://only_a_test/test/" + rand(1000000).to_s

class TestOpenToxAuthorizationBasic < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!
 
  def test_01_server
    @aaserver = $aa[:uri]
    assert_equal(@aaserver, OpenTox::Authorization.server)
  end
 
  def test_02_get_token
    refute_nil @@subjectid
  end
  
  def test_03_is_valid_token
    tok = login
    refute_nil tok
    assert OpenTox::Authorization.is_token_valid(tok)
    logout(tok)
  end
  
  def test_04_logout
    tok = login 
    assert logout(tok)
    assert_equal false, OpenTox::Authorization.is_token_valid(tok)
  end
  
  def test_05_list_policies
    assert_kind_of Array, OpenTox::Authorization.list_policies(@@subjectid)
  end

  def test_06_bad_login
    assert_raises OpenTox::ResourceNotFoundError do
      subjectid = OpenTox::Authorization.authenticate("blahhshshshsshsh", "blubbbbb")
    end
  end
=begin
  def test_07_unauthorized
    assert_raises OpenTox::UnauthorizedError do
      result = OpenTox::Authorization.authorize("http://somthingnotexitstin/bla/8675940", "PUT", @@subjectid).to_s
    end
  end
=end
end

class TestOpenToxAuthorizationLDAP < MiniTest::Test

  def test_01_list_user_groups
    assert_kind_of Array, OpenTox::Authorization.list_user_groups($aa[:user], @@subjectid)
  end
  
  def test_02_get_user
    assert_equal $aa[:user], OpenTox::Authorization.get_user(@@subjectid)
  end

end

class TestOpenToxAuthorizationLDAP < MiniTest::Test

  def test_01_create_check_delete_default_policies
    res = OpenTox::Authorization.send_policy(TEST_URI, @@subjectid)
    assert res
    assert OpenTox::Authorization.uri_has_policy(TEST_URI, @@subjectid)
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI, @@subjectid)
    assert_kind_of Array, policies
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy, @@subjectid)
    end
    assert_equal false, OpenTox::Authorization.uri_has_policy(TEST_URI, @@subjectid)
  end

  def test_02_check_policy_rules
    tok_anonymous = OpenTox::Authorization.authenticate("anonymous","anonymous")
    refute_nil tok_anonymous
    res = OpenTox::Authorization.send_policy(TEST_URI, @@subjectid)
    assert res
    assert OpenTox::Authorization.uri_has_policy(TEST_URI, @@subjectid)
    owner_rights = {"GET" => true, "POST" => true, "PUT" => true, "DELETE" => true}
    groupmember_rights = {"GET" => true, "POST" => false, "PUT" => false, "DELETE" => false}
    owner_rights.each do |request, right|
      assert_equal right, OpenTox::Authorization.authorize(TEST_URI, request, @@subjectid), "#{$aa[:user]} requests #{request} to #{TEST_URI}"
    end
    groupmember_rights.each do |request, r|
      assert_equal r, OpenTox::Authorization.authorize(TEST_URI, request, tok_anonymous), "anonymous requests #{request} to #{TEST_URI}"
    end
    
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI, @@subjectid)
    assert_kind_of Array, policies
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy, @@subjectid)
    end
    logout(tok_anonymous)
  end

  def test_03_check_different_uris
    res = OpenTox::Authorization.send_policy(TEST_URI, @@subjectid)
    assert OpenTox::Authorization.uri_has_policy(TEST_URI, @@subjectid)
    assert OpenTox::Authorization.authorize(TEST_URI, "GET", @@subjectid), "GET request"
    policies = OpenTox::Authorization.list_uri_policies(TEST_URI, @@subjectid)
    policies.each do |policy|
      assert OpenTox::Authorization.delete_policy(policy, @@subjectid)
    end
 
  end  
end


def logout (token)
   OpenTox::Authorization.logout(token)
end

def login
  OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
end 
