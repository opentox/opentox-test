require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
require File.join(ENV["HOME"],"toxbank-investigation","tb_policy.rb")

class TBAccountBasicTest < Test::Unit::TestCase
  @@accounts = {"mrautenberg" => "http://toxbanktest1.opentox.org:8080/toxbank/user/U124", "guest" => "http://toxbanktest1.opentox.org:8080/toxbank/user/U2", "member" => "http://toxbanktest1.opentox.org:8080/toxbank/organisation/G176"}
  @@fake_uri = "http://only_a_test/test/" + rand(1000000).to_s
  def test_00_pi_exists
    assert_equal String, $pi[:name].class, "Add PI to your test.rb"
    assert_equal String, $pi[:password].class
  end

  def test_01_pi_login
    $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
    assert_equal true, OpenTox::Authorization.is_token_valid($pi[:subjectid]), "PI is not logged in"
  end

  def test_02_get_tb_service_rdf
    piaccount = OpenTox::TBAccount.new($pi[:uri], $pi[:subjectid])
    assert piaccount.instance_of? OpenTox::TBAccount
    assert_equal $pi[:uri], piaccount.uri
    assert_equal $pi[:name], piaccount.account
  end

  def test_03_get_account_via_uri
    @@accounts.each do |name, uri|
      account = OpenTox::TBAccount.new(uri, $pi[:subjectid])
      assert_equal name, account.account
    end
  end

  def test_04_get_account_via_username
    @@accounts.each do |name, uri|
      if uri.match(RDF::TBU.to_s)
        accounturi = OpenTox::RestClientWrapper.get("http://toxbanktest1.opentox.org:8080/toxbank/user?username=#{name}", nil, {:Accept => "text/uri-list", :subjectid => $pi[:subjectid]}).sub("\n","")
        account = OpenTox::TBAccount.new(accounturi, $pi[:subjectid])
        assert_equal name, account.account
        assert_equal accounturi, account.uri
      end
    end
  end

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

  def test_10_create_guest_policy
    guest = OpenTox::TBAccount.new("http://toxbanktest1.opentox.org:8080/toxbank/user/U2", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri)
    #puts @@fake_uri
    assert_equal true, OpenTox::Authorization.uri_has_policy(@@fake_uri, @@subjectid)
    #pols = OpenTox::Authorization.list_uri_policies(@@fake_uri, @@subjectid)
    #puts OpenTox::Authorization.list_policy(pols[0], @@subjectid)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "POST", @@subjectid)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "PUT", @@subjectid)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri,"GET", @@subjectid)
    test_98_delete_policies
  end

  def test_11_create_membergroup_policy
    guest = OpenTox::TBAccount.new("http://toxbanktest1.opentox.org:8080/toxbank/organisation/G176", $pi[:subjectid]) #PI creates policies
    guest.send_policy(@@fake_uri)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "POST", @@subjectid)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "PUT", @@subjectid)
    assert_equal nil, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", @@subjectid)
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri,"GET", @@subjectid)
    test_98_delete_policies
  end

  def test_12_create_pi_policy
    piaccount = OpenTox::TBAccount.new($pi[:uri], $pi[:subjectid])
    piaccount.send_policy(@@fake_uri, "all")
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@fake_uri, "GET", $pi[:subjectid])
  end

  def test_98_delete_policies
    policies = OpenTox::Authorization.list_uri_policies(@@fake_uri, $pi[:subjectid])
    policies.each do |policy|
      res = OpenTox::Authorization.delete_policy(policy, $pi[:subjectid])
      assert res
    end
  end
end