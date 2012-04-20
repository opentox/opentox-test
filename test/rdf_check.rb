require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class UploadTest < Test::Unit::TestCase

  def setup
  end
  
  def teardown
  end
 
  def test_01_query_sparqle_rdf_BII_I_1
    id = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    #test_all
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/`.chomp
    assert_match /[https\:\/\/toxbanktest2, https\:\/\/toxbank\-dev]/, response
    #test_id_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[title, Manchester, givenname, Castrillo]/, response
    #test_metadata_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/metadata`.chomp
    assert_match /[I2225, BII\-I\-1, S2223, S2224, Growth, Background]/, response
    #test_resource_Investigation
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/I2225`.chomp
    assert_match /[BII\-I\-1, title, Growth, abstract, Background]/, response
    #test_resource_Study
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/S2223`.chomp
    assert_match /[hasProtocol, P\_2202, description, Comprehensive, title, rapamycin, Rapamycin, Affymetrix]/, response
    #test_resource_Assay
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/A1269`.chomp
    assert_match /Assay/, response
    #test_resource_Protocol
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/P_2202`.chomp
    assert_match /[mRNA, extraction]/, response
    #test_resource_ISA
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0/ISA_3981`.chomp
    assert_match /[givenname, Castrillo, family\_name, Juan]/, response
  end  

end
