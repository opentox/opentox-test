require_relative "setup.rb"

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

#TODO: check 4store entries/errors

class UploadTest < MiniTest::Test

  def setup
    @tmpdir = File.join(File.dirname(__FILE__),"tmp")
    FileUtils.mkdir_p @tmpdir
    FileUtils.rm_r Dir[File.join @tmpdir, '*']
  end

  def test_01_get_all
    response = `curl -Lk -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" -i #{$investigation[:uri]}`
    assert_match /200/, response
  end

  def test_02_get_inexisting
    response = `curl -Lk -H "Accept:text/uri-list" -i -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}/foo`.chomp
    assert_match /401|404/, response
    response = `curl -Lk -H "Accept:application/rdf+xml" -i -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}/999999/metadata`.chomp
    assert_match /401|404/, response
  end

  def test_03_valid_zip_upload
    # upload
    ["BII-I-1-tb2.zip","E-MTAB-798_philippe-tb2.zip"].each do |f|
      file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", f
      response = `curl -Lk -X POST -i -F file="@#{file};type=application/zip" -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}`.chomp
      assert_match /202/, response
      taskuri = response.split("\n")[-1]
      t = OpenTox::Task.new taskuri
      t.wait
      assert_equal true, t.completed?
      assert_match t.hasStatus, "Completed"
      uri = t.resultURI
      metadata = `curl -Lk -H accept:application/rdf+xml -H "subjectid:#{$pi[:subjectid]}" #{uri}/metadata`
      assert_match /#{uri}/, metadata
      zip = File.join @tmpdir,"tmp.zip"
      `curl -Lk -H "Accept:application/zip" -H "subjectid:#{$pi[:subjectid]}" #{uri} > #{zip}`
      `unzip -o #{zip} -d #{@tmpdir}`
      files = `unzip -l #{File.join File.dirname(__FILE__),"data/toxbank-investigation/valid",f}|grep txt|cut -c 31- | sed 's#^.*/##'`.split("\n")
      files.each{|f| assert_equal true, File.exists?(File.join(File.expand_path(@tmpdir),f)) }
      # get isatab files
      urilist = `curl -Lk -H "subjectid:#{$pi[:subjectid]}" -H "Accept:text/uri-list" #{uri}`.split("\n")
      urilist.each do |u|
        unless u.match(/[n3|zip]$/)
          response = `curl -Lk -i -H "Accept:text/tab-separated-values" -H "subjectid:#{$pi[:subjectid]}" #{u}`
          assert_match /HTTP\/1.1 200 OK/, response.to_s.encode!('UTF-8', 'UTF-8', :invalid => :replace) 
        end
      end
      # delete
      response = `curl -Lk -i -X DELETE -H "subjectid:#{$pi[:subjectid]}" #{uri}`
      assert_match /200/, response
      response = `curl -Lk -i -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{uri}`
      assert_match /401|404/, response
      response = `curl -I -Lk -i -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{uri}`
      assert_match /404|404/, response
    end
  end
  def test_04_invalid_zip_upload
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid/isa_TB_ACCUTOX.zip"
    response = `curl -Lk -X POST -i -F file="@#{file};type=application/zip" -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}`.chomp
    assert_match /202/, response
    uri = response.split("\n")[-1]
    t = OpenTox::Task.new(uri,$pi[:subjectid])
    t.wait
    assert_match t.hasStatus, "Error"
    # TODO: test errorReport, rdf output of tasks has to be fixed for that purpose
  end

end
