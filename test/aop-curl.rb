require_relative "./setup.rb"

begin
  puts "Service URI is: #{$aop[:uri]}"
rescue
  puts "Configuration Error: $aop[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end


class JsonTest < MiniTest::Test
  
  # check response from service with header application/json
  # @note expect code 200
  def test_01_response
    response = `curl -i -H accept:application/json #{$aop[:uri]}`
    assert_match /200/, response
  end

  # check response for json data with header application/json
  # @note expect code 200
  def test_02
    response = `curl -i -H accept:application/json #{$aop[:uri]}/cid/1234/assays/active/1234-assays-active.json`
    assert_match /200/, response
  end

  # check json data for content
  def test_03
    response = `curl -H accept:application/json #{$aop[:uri]}/cid/1234/prediction/assays/active/1234-assays-active.json`.chomp
    result = JSON[response]
    #puts result
    aid = result.collect{|x| x['AID']}
    assert_includes aid.to_s, "651645"
    p_active = result.collect{|x| x['p_active']}
    assert_includes p_active.to_s, "0.9701425001453319"
    p_inactive = result.collect{|x| x['p_inactive']}
    assert_includes p_inactive.to_s, "0.029857499854668124"
    assay_name = result.collect{|x| x['Assay Name']}
    assert_includes assay_name.to_s, "Cell Proliferation Assay against the TMD8 Cell Line"
  end

end

class CsvTest < MiniTest::Test

  # check response for csv data with header text/csv
  # @note expect code 200
  def test_01
    response = `curl -i -H accept:text/csv #{$aop[:uri]}/cid/1234/assays/active/1234-assays-active.csv`
    assert_match /200/, response
  end
  
  # check csv data for content
  def test_02
    response = `curl -H accept:text/csv #{$aop[:uri]}/cid/1234/prediction/assays/active/1234-assays-active.csv`.chomp
    result = CSV.parse(response, {:col_sep => ";"})
    assert_equal result[0].size, 4
  end

end

