require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class UploadTest < Test::Unit::TestCase

  def setup
  end
  
  def teardown
  end
 
  def test_01_check_rdf_with_ToxBank_specific_fields_on_BII_I_1
    id = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Investigation Identifier, BII\-I\-1]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Investigation Title, Growth control of the eukaryote cell\: a systems biology study in yeast]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Investigation Description, Background Cell growth underlies many key cellular and developmental processes]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Owning Organisation URI, TBO\:G176]/, response
    #test_id_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Consortium URI, TBC:G2]/, response
    #test_resource_ISA
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/0`.chomp
    assert_match /[Investigation keywords, TBK\:Blotting, Southwestern;TBK\:Molecular Imaging;DOID\:primary carcinoma of the liver cells]/, response
  end
  
  def test_02_check_rdf_with_ToxBank_specific_fields_on_E_MTAB
    id = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Investigation Identifier, E\-MTAB\-798]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Investigation Title, Open TG\-GATEs \(in vitro, human\)]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Investigation Description, The Toxicogenomics Project was a 5\-year collaborative project]/, response
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Owning Organisation URI, TBO\:G176]/, response
    #test_id_query_sparqle
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Consortium URI, TBC:G2]/, response
    #test_resource_ISA
    response = `curl -i -k -H subjectid:#{id} -H accept:application/rdf+xml https://toxbank-dev.in-silico.ch/2`.chomp
    assert_match /[Investigation keywords, TBK\:Fluxomics]/, response
  end
  
end
