require_relative "setup.rb"

class UriListTest < MiniTest::Test

  def test_01_urilist_dublicates
    services = [$algorithm[:uri], $dataset[:uri], $feature[:uri], $model[:uri], $task[:uri]]
    services.each do |service|
      s_urilist = `curl -H accept:text/uri-list #{service}`.split("\n")
      assert_equal s_urilist.uniq.length, s_urilist.length, "Attention, dublicates found in #{service.split("/").last} uri-list!"
    end
  end

  def test_02_urilist_mime
    mime_types = ["application/rdf+xml", "text/turtle", "application/sparql-results+xml", "text/plain", "text/uri-list", "text/html"]
    mime_types.each do |mt|
      s_urilist = `curl -i -H accept:#{mt} #{$feature[:uri]}`
      assert_match /200 OK/, s_urilist.to_s
      refute_match /Content-Length: 0/, s_urilist.to_s, "Attention, content length empty!"
      refute_match /dataset/, s_urilist.to_s, "Attention, found dataset in feature uri-list!"
    end
  end

end
