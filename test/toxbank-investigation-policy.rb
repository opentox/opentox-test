require_relative "setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),"..","..","toxbank-investigation","tbaccount.rb")

class TBAccountBasicTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  @@accounts = {"mrautenberg" => "#{RDF::TBU.U124}", "guest" => "#{RDF::TBU.U2}", "member" => "#{RDF::TBO.G176}"}
  @@fake_uri = "http://only_a_test/test/" + rand(1000000).to_s

  # check if PI test user is in test configuration
  def test_00a_pi_exists
    assert_equal String, $pi[:name].class, "Add PI to your test.rb"
    assert_equal String, $pi[:password].class
  end

  # check if second PI test user is in test configuration
  def test_00b_secondpi_exists
    assert_equal String, $secondpi[:name].class, "Add second PI ($secondpi) to your test.rb"
    assert_equal String, $secondpi[:password].class
  end

  # login PI user. get a valid subjectid
  # @note expect valid token from OpenSSO
  def test_01_pi_login
    $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
    assert_equal true, OpenTox::Authorization.is_token_valid($pi[:subjectid]), "PI is not logged in"
  end

  # check userservice data of PI user
  def test_02_get_tb_service_rdf
    piaccount = OpenTox::TBAccount.new($pi[:uri], $pi[:subjectid])
    assert piaccount.instance_of? OpenTox::TBAccount
    assert_equal $pi[:uri], piaccount.uri
    assert_equal $pi[:name], piaccount.account
  end

  # read several accounts from userservice and compare account.account with testdata names
  def test_03_get_account_via_uri
    @@accounts.each do |name, uri|
      account = OpenTox::TBAccount.new(uri, $pi[:subjectid])
      assert_equal name, account.account
    end
  end

  # find an account by username
  def test_04b_get_account_via_username
    @@accounts.each do |name, uri|
      if uri.match(RDF::TBU.to_s)
        accounturi = OpenTox::TBAccount.search_user name, $pi[:subjectid]
        account = OpenTox::TBAccount.new(accounturi, $pi[:subjectid])
        assert_equal name, account.account
        assert_equal accounturi, account.uri
        assert_equal "TBU:#{accounturi.split('/')[-1]}", account.ns_uri
      end
    end
  end

  # check LDAP DN types of accounts
  def test_05_ldap_dn_type
    @@accounts.each do |name, uri|
      account = OpenTox::TBAccount.new(uri, $pi[:subjectid])
      if account.ldap_type == "LDAPUsers"
        assert_equal "uid=#{name},ou=people,dc=opentox,dc=org", account.ldap_dn
      else
        assert_equal "cn=#{name},ou=groups,dc=opentox,dc=org", account.ldap_dn
      end
    end
  end

  # create a policy for guest user and check authorizations
  # GET=true, POST=false, PUT=false, DELETE=false
  def test_10_create_guest_policy
    guest = OpenTox::TBAccount.new("#{RDF::TBU.U2}", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri)
    assert_equal true, OpenTox::Authorization.uri_has_policy(@@fake_uri, @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "POST", @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "PUT", @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri,"GET", @@subjectid)
    test_98_delete_policies
  end

  # create a policy for member group and check authorizations
  # GET=true, POST=false, PUT=false, DELETE=false
  def test_11_create_membergroup_policy
    guest = OpenTox::TBAccount.new("#{RDF::TBO.G176}", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "POST", @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "PUT", @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri,"GET", @@subjectid)
    test_98_delete_policies
  end

  # create a policy for PI user and check authorizations
  # GET=true, POST=true, PUT=true, DELETE=true
  def test_12a_create_pi_policy # create pi policy via account uri 
    piaccount = OpenTox::TBAccount.new($pi[:uri], $pi[:subjectid])
    piaccount.send_policy(@@fake_uri, "all")
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "GET", $pi[:subjectid])
    test_98_delete_policies
  end

  def test_12b_create_pi_policy # create pi policy via subjectid only
    ret = OpenTox::Authorization.create_pi_policy(@@fake_uri, $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "GET", $pi[:subjectid])
    # delete the policies in 12c!
  end

  def test_12c_pi_policy_subject_name
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    assert_equal policies.size, 1
    xml = OpenTox::Authorization.list_policy(policies[0], $pi[:subjectid])
    policy = OpenTox::Policies.new
    policy.load_xml(xml)
    assert_equal $pi[:name], policy.policies[policy.names[0]].subject.name, "subject name is not user name"
    test_98_delete_policies
  end

  def test_13a_create_guest_rw_policy
    guest = OpenTox::TBAccount.new("#{RDF::TBU.U2}", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri, "readwrite")
    assert_equal true, OpenTox::Authorization.uri_has_policy(@@fake_uri, @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "POST", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "PUT", @@subjectid)
    assert_equal false, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri,"GET", @@subjectid)
    # delete policies in 13b!
  end

  def test_13b_guest_policy_subject_name
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    assert_equal policies.size, 1
    xml = OpenTox::Authorization.list_policy(policies[0], $pi[:subjectid])
    policy = OpenTox::Policies.new
    policy.load_xml(xml)
    assert_equal "guest", policy.policies[policy.names[0]].subject.name, "subject name is not user name"
    test_98_delete_policies
  end

  # create 3 policies and delete all policies except pi-policy with policies_reset method
  def test_14_check_reset_policies
    guest = OpenTox::TBAccount.new("#{RDF::TBU.U2}", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri)
    member = OpenTox::TBAccount.new("#{RDF::TBO.G176}", $pi[:subjectid]) #PI creates policies
    member.send_policy(@@fake_uri)
    piaccount = OpenTox::TBAccount.new($pi[:uri], $pi[:subjectid])
    piaccount.send_policy(@@fake_uri, "all")
    assert_equal 3, OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid]).size
    result = OpenTox::Authorization.reset_policies(@@fake_uri,"users", $pi[:subjectid])
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    assert_equal 2, policies.size
    result = OpenTox::Authorization.reset_policies(@@fake_uri,"groups", $pi[:subjectid])
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    assert_equal 1, policies.size
    assert policies[0] =~ /^tbi-#{piaccount.account}-users-*/
    test_98_delete_policies
  end

  # delete all policies aftre the test
  def test_98_delete_policies
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    policies.each do |policy|
      res = OpenTox::Authorization.delete_policy(policy, $pi[:subjectid])
      assert res
    end
  end
end
