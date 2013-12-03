require_relative "toxbank-setup.rb"

# Test API extension SPARQL templates 
class TBSPARQLTest < Minitest::Unit::TestCase

  # login as pi and create a test investigation
  def setup
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid] # set pi as the logged in user
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
  end  

  # initial tests to be changed
  def test_nonexisting_template
    assert_raises OpenTox::ResourceNotFoundError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/not_existing_template", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end

  def test_existing_template
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/investigation_details", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  def test_camelcase_template
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/InvestigationDetails", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  def test_factors_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/factors_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    factorvalues = result["results"]["bindings"].map {|n|  "#{n["factorname"]["value"]}:::#{n["value"]["value"]}"}
    assert factorvalues.include?("limiting nutrient:::phosphorus")
    assert factorvalues.include?("limiting nutrient:::glucose")
    assert factorvalues.include?("limiting nutrient:::carbon")
    assert factorvalues.include?("limiting nutrient:::sulfur")
    assert factorvalues.include?("limiting nutrient:::nitrogen")
    assert factorvalues.include?("limiting nutrient:::ethanol")
    assert factorvalues.include?("rate:::0.1")
    assert factorvalues.include?("rate:::0.2")
    assert factorvalues.include?("rate:::0.07")
  end

  def test_characteristics_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/characteristics_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    propnamevalues = result["results"]["bindings"].map {|n|  "#{n["propname"]["value"]}:::#{n["value"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert propnamevalues.include?("organism:::Saccharomyces cerevisiae (Baker's yeast):::http://purl.obolibrary.org/obo/NEWT_4932")
    assert propnamevalues.include?("Label:::biotin:::http://purl.obolibrary.org/chebi/15956")
    assert propnamevalues.include?("organism:::Saccharomyces cerevisiae (Baker's yeast):::http://purl.obolibrary.org/obo/NEWT_4932")
  end


  def test_investigation_endpoint_technology
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/investigation_endpoint_technology", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    endpointtechnologies = result["results"]["bindings"].map {|n|  "#{n["endpoint"]["value"]}:::#{n["technology"]["value"]}"}
    assert_equal endpointtechnologies.size, 4
  end

  def test_investigation_and_characteristics
  end

  def test_investigations_and_protocols
  end

  def test_investigations_and_factors
  end

  def test_protocols_by_factors
  end

  def test_invetsigation_by_factors
  end

  def test_investigation_by_factorend
  end

  def test_investigation_by_characteristic_valueend
  end

  def test_investigation_by_characteristic_name
  end

  def test_investigation_by_characteristic
  end


  # delete investigation/{id}
  # @note expect code 200
  def teardown
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
  end

end