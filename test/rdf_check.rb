require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class UploadTest < Test::Unit::TestCase

  def setup
  end
  
  def teardown
  end
 
  def test_01_query_sparqle_rdf
    id = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    #test_all
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/`.chomp
    assert_match /DoseResponse-Trial/, response
    assert_match /Investigation/, response
    assert_match /BII-I-1/, response
    #test_id_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /TB-DoseResponseTrial-acetaminophen/, response
    #test_metadata_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/metadata`.chomp
    assert_match /DoseResponse-Trial/, response
    #test_resource_ISA_Investigation
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/ISA_1879`.chomp
    assert_match /[Person, User, Contact]/, response
    #test_resource_Study
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/S1887`.chomp
    assert_match /A451/, response
    #test_resource_Assay
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/A451`.chomp
    assert_match /Assay/, response
  end  

end
