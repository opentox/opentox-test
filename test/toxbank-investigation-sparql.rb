require_relative "toxbank-setup.rb"

# Test API extension SPARQL templates 
class TBSPARQLTest < MiniTest::Test

  i_suck_and_my_tests_are_order_dependent!

  # login as pi and create a test investigation
  def test_00_create_investigation
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid] # set pi as the logged in user
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2_ftp.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
    OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :summarySearchable => "true"}, { :subjectid => $pi[:subjectid] }
  end  

  # initial tests to be changed
  def test_01_nonexisting_template
    assert_raises OpenTox::ResourceNotFoundError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/not_existing_template", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end

  def test_02_existing_template
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/investigation_details", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  def test_03_camelcase_template
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/InvestigationDetails", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  # Retrieves all factors (name, value, ontology URI of the value) given an investigation URI
  def test_04_factors_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/factors_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    headvars = result["head"]["vars"]
    assert headvars.include?("factorname")
    assert headvars.include?("value")
    assert headvars.include?("ontouri")
    assert headvars.include?("unitOnto")
    assert headvars.include?("unit")
    assert headvars.include?("unitID")
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

  def test_05_characteristics_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/characteristics_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    propnamevalues = result["results"]["bindings"].map {|n|  "#{n["propname"]["value"]}:::#{n["value"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert propnamevalues.include?("organism:::Saccharomyces cerevisiae (Baker's yeast):::http://purl.obolibrary.org/obo/NEWT_4932")
    assert propnamevalues.include?("Label:::biotin:::http://purl.obolibrary.org/chebi/15956")
    assert propnamevalues.include?("organism:::Saccharomyces cerevisiae (Baker's yeast):::http://purl.obolibrary.org/obo/NEWT_4932")
  end


  def test_06_investigation_endpoint_technology
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/investigation_endpoint_technology", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    endpointtechnologies = result["results"]["bindings"].map {|n|  "#{n["endpoint"]["value"]}:::#{n["technology"]["value"]}"}
    assert endpointtechnologies.include?("http://purl.org/obo/owl/OBI#0000424:::http://purl.org/obo/owl/OBI#0400148")
    assert endpointtechnologies.include?("http://purl.org/obo/owl/OBI#0000366:::http://purl.org/obo/owl/OBI#OBI_0000470")
    assert endpointtechnologies.include?("http://purl.org/obo/owl/OBI#OBI_0000615:::http://purl.org/obo/owl/OBI#OBI_0000470")
    assert endpointtechnologies.include?("http://purl.org/obo/owl/OBI#0000424:::http://purl.org/obo/owl/OBI#0400148")
    assert_equal endpointtechnologies.size, 4
  end

  def test_07_investigation_and_characteristics
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert inv_chars.include?("#{@@uri}:::Label:::#{@@uri}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{@@uri}:::organism:::#{@@uri}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert_equal 200, response.code
  end

  def test_08_investigations_and_protocols
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigations_and_protocols", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    inv_protocols = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["protocol"]["value"]}:::#{n["label"]["value"]}"}
    #puts inv_protocols
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P2:::biotin labeling")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P6:::EukGE-WS4")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P1:::metabolite extraction")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P5:::mRNA extraction")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P9:::biotin labeling")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P8:::mRNA extraction")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P4:::protein extraction")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P3:::EukGE-WS4")
    assert inv_protocols.include?("#{@@uri}:::#{@@uri}/P7:::ITRAQ labeling")
    assert_equal 200, response.code
  end

  def test_09_factorvalues_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/factorvalues_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts result
    ["biosample","sample", "factorname", "value", "ontouri", "unitOnto", "unit"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end
    
    biosample = result["results"]["bindings"].map{|n| "#{n["biosample"]["value"]}"}
    assert biosample.include?("#{@@uri}/source2659")

    sample = result["results"]["bindings"].map{|n| "#{n["sample"]}"}
    type = result["results"]["bindings"].map{|n| "#{n["sample"]["type"]}"}
    assert type.include?("uri")
    value = result["results"]["bindings"].map{|n| "#{n["sample"]["value"]}"}
    assert value.include?("#{@@uri}/sample2409")
    
    factorname = result["results"]["bindings"].map{|n| "#{n["factorname"]}"}
    type = result["results"]["bindings"].map{|n| "#{n["factorname"]["type"]}"}
    assert type.include?("literal")
    value = result["results"]["bindings"].map{|n| "#{n["factorname"]["value"]}"}
    assert value.include?("limiting nutrient")
  end

  def test_10_characteristics_by_sample
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/characteristics_by_sample/source2659", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts result
    ["propname", "value", "ontouri"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end

    propname = result["results"]["bindings"].map{|n| "#{n["propname"]["value"]}"}
    assert propname.include?("organism")

    value = result["results"]["bindings"].map{|n| "#{n["value"]["value"]}"}
    assert value.include?("Saccharomyces cerevisiae (Baker's yeast)")

    ontouri = result["results"]["bindings"].map{|n| "#{n["ontouri"]["value"]}"}
    assert ontouri.include?("http://purl.obolibrary.org/obo/NEWT_4932")
  end

  def test_13_investigation_by_characteristic_value
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_characteristic_value", {:value => "Saccharomyces cerevisiae (Baker's yeast)"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    char_value = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["ontoURI"]["value"]}"}
    assert char_value.include?("#{@@uri}:::organism:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert_equal 200, response.code
  end

  def test_14_investigation_by_characteristic_name
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_characteristic_name", {:value => "organism"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    char_name = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["value"]["value"]}:::#{n["ontoURI"]["value"]}"}
    assert char_name.include?("#{@@uri}:::Saccharomyces cerevisiae (Baker's yeast):::http://purl.obolibrary.org/obo/NEWT_4932")
    assert_equal 200, response.code
  end

  def test_15_investigation_by_characteristic
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_characteristic", {:value => "http://purl.obolibrary.org/obo/NEWT_4932"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    inv_char = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["value"]["value"]}"}
    assert inv_char.include?("#{@@uri}:::organism:::Saccharomyces cerevisiae (Baker's yeast)")
    assert_equal 200, response.code
  end
  
  # Retrieves investigation URI and factors (name, value, ontology URI of the value)
  def test_16_investigations_and_factors
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigations_and_factors", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts result
    ["investigation", "factorname", "value", "ontouri"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end

    investigation = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}"}
    assert investigation.include?("#{@@uri}")

    factorname = result["results"]["bindings"].map{|n| "#{n["factorname"]["value"]}"}
    assert factorname.include?("limiting nutrient")

    value = result["results"]["bindings"].map{|n| "#{n["value"]["value"]}"}
    assert value.include?("phosphorus")

    ontouri = result["results"]["bindings"].map{|n| "#{n["ontouri"]["value"]}"}
    #assert value.include?("http://purl.obolibrary.org/chebi/CHEBI:28748")
  end
  

  def test_30_empty_factorValues_search
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_factors", {:factorValues => ""}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end

  def test_31_empty_value_search
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_characteristic", {:value => ""}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end

  # delete investigation/{id}
  # @note expect code 200
  def test_90_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
  end

end

class TBSPARQLTestExtended < MiniTest::Test

  i_suck_and_my_tests_are_order_dependent!

  # login as pi and create a test investigation
  def test_00_create_investigation
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid] # set pi as the logged in user
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "GC-ToxBank-15_tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
    OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :summarySearchable => "true"}, { :subjectid => $pi[:subjectid] }
    subtask = OpenTox::RestClientWrapper.get "#{@@uri}/subtaskuri", {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    puts "SubTaskURI is: #{subtask}"
    if subtask != ""
      task = OpenTox::Task.new subtask.chomp
      task.wait
      puts task.hasStatus
    end
    #puts "sleep 120s"
    #sleep 120
  end  
  
  # Retrieves all factors (name, value, ontology URI of the value) given an investigation URI
  def test_04_factors_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/factors_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    ["factorname", "value", "ontouri", "unitOnto", "unit"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end
    
    factors = result["results"]["bindings"].map{|n| "#{n["factorname"]["value"]}:::#{n["value"]["value"]}:::#{n["ontouri"]["value"]}:::#{n["unitOnto"]["value"]}:::#{n["unit"]["value"]}:::#{n["unitID"]["value"]}"}
    #puts factors
    assert factors.include?("sample TimePoint:::8::::::::::::")
    assert factors.include?("dose:::0::::::http://purl.obolibrary.org/obo/UO_0000064:::micromolar:::UO:0000064")
    assert factors.include?("compound:::DOXORUBICIN:::http://purl.obolibrary.org/chebi/CHEBI:28748:::::::::")
  end

  def test_05_files_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/files_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts result
    ["assay", "assayFile", "endpoint", "endpointLabel", "platform", "technology", "techLabel", "file", "term", "downloaduri"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end
  end
  
  def test_06_files_and_assays_by_investigation
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/files_and_assays_by_investigation", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts result
    ["study", "assay", "assayFile", "endpoint", "endpointLabel", "technology", "techLabel", "platform", "file", "term"].each do |v|
      assert result["head"]["vars"].include?(v.to_s)
    end
  end
  

  # Retrieves protocol URI containing any of the factor value URI (e.g. two compound URIs)
  def test_10_protocols_by_factors
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/protocols_by_factors", {:factorValues => "['http://purl.obolibrary.org/chebi/CHEBI:28748']"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    protocol_factors = result["results"]["bindings"].map{|n| "#{n["protocol"]["value"]}:::#{n["label"]["value"]}:::#{n["factorname"]["value"]}:::#{n["value"]["value"]}"}
    #puts protocol_factors
    assert_equal 200, response.code
    #assert protocol_factors.include?("#{@@uri}/P4:::labeling:::compound:::DOXORUBICIN")
    #assert protocol_factors.include?("#{@@uri}/P3:::RNA extraction:::compound:::DOXORUBICIN")
    #assert protocol_factors.include?("#{@@uri}/P2:::normalization data transformation:::compound:::DOXORUBICIN")
    #assert protocol_factors.include?("#{@@uri}/P1:::data transformation:::compound:::DOXORUBICIN")
    #assert protocol_factors.include?("#{@@uri}/P5:::data collection:::compound:::DOXORUBICIN")
    #assert protocol_factors.include?("#{@@uri}/P6:::nucleic acid hybridization:::compound:::DOXORUBICIN")
  end

  # Retrieves investigation URI containing any of the factor value URI (e.g. two compound URIs)
  def test_11_investigation_by_factors
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_factors", {:factorValues => "['http://purl.obolibrary.org/chebi/CHEBI:28748']"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    #puts response
    result = JSON.parse(response)
    inv_factors = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["factorname"]["value"]}:::#{n["value"]["value"]}"}
    assert_equal 200, response.code
    assert inv_factors.include?("#{@@uri}:::compound:::DOXORUBICIN")
  end

  # Retrieves investigation URI given a factor value URI (e.g. compound URI)
  def test_12_investigation_by_factor
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_factor", {:value => "http://purl.obolibrary.org/chebi/CHEBI:28748"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    #puts response
    result = JSON.parse(response)
    inv_factor = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["factorname"]["value"]}:::#{n["value"]["value"]}"}
    assert_equal 200, response.code
    assert inv_factor.include?("#{@@uri}:::compound:::DOXORUBICIN")
  end

  def test_16_investigation_by_pvalue
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_pvalue", {:value => "0.65614"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts response
    result = JSON.parse(response)
    inv_pvalue = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["gene"]["value"]}"}
    assert_equal 200, response.code
    assert inv_pvalue.include?("#{@@uri}:::http://onto.toxbank.net/isa/Entrez/3075")
  end
  
  def test_17_investigation_by_qvalue
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_qvalue", {:value => "0.805517"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    #puts response
    result = JSON.parse(response)
    inv_qvalue = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["gene"]["value"]}"}
    assert_equal 200, response.code
    assert inv_qvalue.include?("#{@@uri}:::http://onto.toxbank.net/isa/Entrez/3075")
  end
  
  def test_18_investigation_by_foldchange
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_foldchange", {:value => "0.035"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts response
    inv_foldchange = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["gene"]["value"]}"}
    assert_equal 200, response.code
    assert inv_foldchange.include?("#{@@uri}:::http://onto.toxbank.net/isa/Entrez/3075")
  end
  
  def test_19_investigation_by_genes
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_genes", {:geneIdentifiers => "['entrez:3075']"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    result = JSON.parse(response)
    #puts response
    inv_genes = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["datatype"]["value"]}:::#{n["title"]["value"]}:::#{n["valuetype"]["value"]}:::#{n["value"]["value"]}"}
    assert_equal 200, response.code
    assert inv_genes.include?("#{@@uri}:::http://onto.toxbank.net/isa/bii/data_types/microarray_derived_data:::q-value[Low.8hr-Control.8hr]:::http://onto.toxbank.net/isa/qvalue:::0.911237")
  end

  def test_19_b_investigation_by_genes
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_genes", {:geneIdentifiers => "['entrez3075', 'uniprot:P10809']"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end
  
  def test_20_investigation_by_gene_and_value
    # check for FC, pValue, qValue
    ["FC", "pvalue", "qvalue"].each do |value_type|
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_gene_and_value", {:geneIdentifiers => "['entrez:3075', 'uniprot:P10809']", :value => "#{value_type}:0.7"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
      result = JSON.parse(response)
      #puts response
      ["investigation", "datatype", "title", "value"].each do |v|
        assert result["head"]["vars"].include?(v.to_s)
      end
      assert_equal 200, response.code
    end
  end
  
  def test_21_investigation_by_gene_and_value
    # check for valid request
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_gene_and_value", {:geneIdentifiers => "['entrez:3075', 'uniprot:P10809']", :value => "FC0.7"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_gene_and_value", {:geneIdentifiers => "['entrez:3075', 'uniprot:P10809']", :value => "DC=0.7"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_by_gene_and_value", {:geneIdentifiers => "['entrez3075']", :value => "DC:0.7"}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    end
  end

  # delete investigation/{id}
  # @note expect code 200
  def test_90_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
  end
end
