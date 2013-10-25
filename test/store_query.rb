require_relative "setup.rb"

class UploadTest < MiniTest::Test
  
  i_suck_and_my_tests_are_order_dependent!
  def test_01_basic_response
    response = `curl -i -k --user #{$four_store[:user]}:#{$four_store[:password]} '#{$four_store[:uri]}/status/'`.chomp
    assert_match /200/, response
    response = `curl -i -k -u guest:guest '#{$four_store[:uri]}/status/'`.chomp
    assert_match /401/, response unless $four_store[:uri].match(/localhost/)
  end
  
  def test_02_add_data
    # upload invalid data
    response = `curl -0 -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -T '#{File.join File.dirname(__FILE__),"data/toxbank-investigation/invalid/BII-invalid.n3"}' '#{$four_store[:uri]}/data/?graph=https://this.is-atesturi.net/BII-I-1.n3'`.chomp
    assert_match /400/, response
    # upload valid data
    response = `curl -0 -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -T '#{File.join File.dirname(__FILE__),"data/toxbank-investigation/valid/BII-I-1-test.nt"}' '#{$four_store[:uri]}/data/?graph=https://this.is-atesturi.net/BII-I-1-test.nt'`.chomp
    assert_match /201/, response
  end
  
  def test_03_query_all
    response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} '#{$four_store[:uri]}/sparql/'`.chomp
    assert_match /500/, response
    response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -H 'Accept:application/sparql-results+xml' -d "query=CONSTRUCT { ?s ?p ?o } WHERE {?s ?p ?o} LIMIT 10" '#{$four_store[:uri]}/sparql/'`.chomp
    assert_match /200/, response
    assert_match /rdf\:RDF/, response
    assert_match /rdf\:Description/, response
  end
  
  def test_04_query_sparqle
    response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} '#{$four_store[:uri]}/sparql/'`.chomp
    assert_match /500/, response
    response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -H 'Accept:application/sparql-results+xml' -d "query=CONSTRUCT { ?s ?p ?o } FROM <https://this.is-atesturi.net/BII-I-1-test.nt> WHERE {?s ?p ?o} LIMIT 10" '#{$four_store[:uri]}/sparql/'`.chomp
    assert_match /200/, response
    assert_match /rdf\:RDF/, response
    assert_match /rdf\:Description/, response
    assert_match /investigation/, response
  end
  
  def test_05_delete_data
    response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -X DELETE '#{$four_store[:uri]}/data/?graph=https://this.is-atesturi.net/BII-I-1-test.nt'`.chomp
    assert_match /200/, response
  end

  def test_06_simultaneous_uploads 
    threads = []
    50.times do |t|
      threads << Thread.new(t) do |up|
        #puts "Start Time >> " << (Time.now).to_s
        response = `curl -0 -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -T '#{File.join File.dirname(__FILE__),"data/toxbank-investigation/valid/BII-I-1-test.nt"}' '#{$four_store[:uri]}/data/?graph=https://this.is-atesturi.net/test#{t}.nt'`.chomp
        assert_match /201/, response
      end
    end
    threads.each {|aThread| aThread.join}
  end
  
  def test_07_query_simultaneous
    threads = []
    50.times do |t|
      threads << Thread.new(t) do |up|
        #puts "Start Time >> " << (Time.now).to_s
        response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -H 'accept:application/rdf+xml' -d 'query=CONSTRUCT { ?s ?p ?o. } WHERE {?s ?p ?o.} LIMIT 10' '#{$four_store[:uri]}/sparql/'`.chomp 
        # puts response
        assert_match /200/, response
      end
    end
    threads.each {|aThread| aThread.join}
  end
  
  def test_08_delete_simultaneous 
    threads = []
    50.times do |t|
      threads << Thread.new(t) do |up|
        #puts "Start Time >> " << (Time.now).to_s
        response = `curl -i -k -u #{$four_store[:user]}:#{$four_store[:password]} -X DELETE '#{$four_store[:uri]}/data/?graph=https://this.is-atesturi.net/test#{t}.nt'`.chomp
        assert_match /200/, response
      end
    end
    threads.each {|aThread| aThread.join}
  end

end

