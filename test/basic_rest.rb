require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class BasicTest < Test::Unit::TestCase

  # check response from service
  def test_01_get_investigations_200
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, :subjectid => @@subjectid
    assert_equal 200, response.code
  end

  # check if default response header is text/uri-list
  def test_02_get_investigations_type
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, { :accept => 'text/uri-list', :subjectid => @@subjectid }
    assert_equal "text/uri-list", response.headers[:content_type]
  end

  # check sparql query call to all investigations
  def test_03_get_investigations_query
    response = nil
    Net::HTTP.get_response(URI(File.join($toxbank_investigation[:uri], "?query=bla&subjectid=#{CGI.escape(@@subjectid)}"))) {|http|
      response = http
    }
    assert_equal 200, response.code.to_i
  end

end

class BasicTestCRUDInvestigation < Test::Unit::TestCase

  # check post to investigation service with wrong content type
  def test_01_post_investigation_400
    uri = File.join($toxbank_investigation[:uri], 'investigation')
    assert_raise OpenTox::NotFoundError do
      OpenTox::RestClientWrapper.post uri, {}, { :accept => 'text/dummy', :subjectid => @@subjectid }
    end
  end

  # create an investigation by uploading a zip file
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1.zip"

    task_uri = `curl -k -X POST #{$toxbank_investigation[:uri]} -H "Content-Type: multipart/form-data" -F "file=@#{file};type=application/zip" -H "subjectid:#{@@subjectid}"`

    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    @@uri = URI(uri)
    assert @@uri.host == URI($toxbank_investigation[:uri]).host
  end

  # get investigation/{id} as text/uri-list
  def test_03_get_investigation_uri_list
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => @@subjectid}
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # get investigation/{id} as application/zip
  def test_04_get_investigation_zip
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/zip", :subjectid => @@subjectid}
    assert_equal "application/zip", result.headers[:content_type]
  end

  # get investigation/{id} as text/tab-separated-values
  def test_05_get_investigation_tab
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/tab-separated-values", :subjectid => @@subjectid}
    assert_equal "text/tab-separated-values;charset=utf-8", result.headers[:content_type]
  end

  # get investigation/{id} as application/sparql-results+json
  def test_06_get_investigation_sparql
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  # check if uri is in uri-list
  def test_98_get_investigation
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, :subjectid => @@subjectid
    assert response.index(@@uri.to_s) != nil, "URI: #{@@uri} is not in uri-list"
  end

  # delete investigation/{id}
  def test_99_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, :subjectid => @@subjectid
    assert_raise OpenTox::NotFoundError do
      OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => @@subjectid}
    end
  end

end


