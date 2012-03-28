require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

#TODO: check 4store entries/errors

class UploadTest < Test::Unit::TestCase

  def setup
    @tmpdir = File.join(File.dirname(__FILE__),"tmp")
    FileUtils.mkdir_p @tmpdir
    FileUtils.rm_r Dir[File.join @tmpdir, '*']
  end

  def test_01_get_all
    response = `curl -k -H "subjectid:#{@@subjectid}" -i #{$toxbank_investigation[:uri]}`
    assert_match /200/, response
  end

  def test_02_get_inexisting
    response = `curl -k -H "Accept:text/uri-list" -i -H "subjectid:#{@@subjectid}" #{$toxbank_investigation[:uri]}/foo`.chomp
    assert_match /404/, response
  end

  def test_03_valid_zip_upload
    # upload
    #["isa-tab-renamed.zip"].each do |f|
    ["BII-I-1.zip","isa-tab-renamed.zip"].each do |f|
      file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", f
      response = `curl -k -X POST -i -F file="@#{file};type=application/zip" -H "subjectid:#{@@subjectid}" #{$toxbank_investigation[:uri]}`.chomp
      assert_match /202/, response
      uri = response.split("\n")[-1]
      t = OpenTox::Task.new(uri)
      puts uri
      assert t.running?
      assert_match t.hasStatus, "Running"
      t.wait
      assert t.completed?
      assert_match t.hasStatus, "Completed"
      uri = t.resultURI
      #`curl -k "#{uri}/metadata"`
      metadata = `curl -k "subjectid:#{@@subjectid}" #{uri}/metadata`
      assert_match /#{uri}/, metadata
      zip = File.join @tmpdir,"tmp.zip"
      #puts "curl -k -H 'Accept:application/zip' -H 'subjectid:#{@@subjectid}' #{uri} > #{zip}"
      `curl -k -H "Accept:application/zip" -H "subjectid:#{@@subjectid}" #{uri} > #{zip}`
      `unzip -o #{zip} -d #{@tmpdir}`
      files = `unzip -l #{File.join File.dirname(__FILE__),"data/toxbank-investigation/valid",f}|grep txt|cut -c 31- | sed 's#^.*/##'`.split("\n")
      files.each{|f| assert_equal true, File.exists?(File.join(File.expand_path(@tmpdir),f)) }

      # get isatab files
      `curl -k -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`.split("\n").each do |u|
        unless u.match(/[n3|zip]$/)
          response = `curl -k -i -H "Accept:text/tab-separated-values" -H "subjectid:#{@@subjectid}" #{u}`
          assert_match /HTTP\/1.1 200 OK/, response.to_s.encode!('UTF-8', 'UTF-8', :invalid => :replace) 
        end
      end

      # delete
      response = `curl -k -i -X DELETE -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /200/, response
      response = `curl -k -i -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /404/, response
    end
  end

  def test_04_invalid_zip_upload
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid/isa_TB_ACCUTOX.zip"
    response = `curl -k -X POST -i -F file="@#{file};type=application/zip" -H "subjectid:#{@@subjectid}" #{$toxbank_investigation[:uri]}`.chomp
    assert_match /202/, response
    uri = response.split("\n")[-1]
    t = OpenTox::Task.new(uri)
    t.wait
    assert_match t.hasStatus, "Error"
    # TODO: test errorReport, rdf output of tasks has to be fixed for that purpose
  end

=begin
  def test_rest_client_wrapper
    ["BII-I-1.zip","isa-tab-renamed.zip"].each do |f|
      file = File.join File.dirname(__FILE__), "toxbank-investigation","data/toxbank-investigation/valid", f
      investigation_uri = OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {:file => File.read(file),:name => file}, {:content_type => "application/zip", :subjectid => @@subjectid}
      puts investigation_uri
      zip = File.join @tmpdir,"tmp.zip"
      #puts "curl -k -H 'Accept:application/zip' -H 'subjectid:#{@@subjectid}' #{uri} > #{zip}"
      `curl -k -H "Accept:application/zip" -H "subjectid:#{@@subjectid}" #{uri} > #{zip}`
      `unzip -o #{zip} -d #{@tmpdir}`
      files = `unzip -l toxbank-investigation/data/toxbank-investigation/valid/#{f}|grep txt|cut -c 31- | sed 's#^.*/##'`.split("\n")
      files.each{|f| assert_equal true, File.exists?(File.join(File.expand_path(@tmpdir),f)) }

      # get isatab files
      `curl -k -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`.split("\n").each do |u|
        unless u.match(/n3$/)
          response = `curl -k -i -H Accept:text/tab-separated-values -H "subjectid:#{@@subjectid}" #{u}`
          assert_match /HTTP\/1.1 200 OK/, response.to_s.encode!('UTF-8', 'UTF-8', :invalid => :replace) 
        end
      end

      # delete
      response = `curl -k -i -X DELETE -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /200/, response
      response = `curl -k -i -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /404/, response
    end
  end
=end

=begin
  def test_ruby_api
    ["BII-I-1.zip","isa-tab-renamed.zip"].each do |f|
      file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", f
      investigation = OpenTox::Investigation.create $toxbank_investigation[:uri], :file => file, :headers => {:content_type => "application/zip", :subjectid => @@subjectid}
      zip = File.join @tmpdir,"tmp.zip"
      #puts "curl -k -H 'Accept:application/zip' -H 'subjectid:#{@@subjectid}' #{uri} > #{zip}"
      `curl -k -H "Accept:application/zip" -H "subjectid:#{@@subjectid}" #{uri} > #{zip}`
      `unzip -o #{zip} -d #{@tmpdir}`
      files = `unzip -l data/toxbank-investigation/valid/#{f}|grep txt|cut -c 31- | sed 's#^.*/##'`.split("\n")
      files.each{|f| assert_equal true, File.exists?(File.join(File.expand_path(@tmpdir),f)) }

      # get isatab files
      `curl -k -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`.split("\n").each do |u|
        unless u.match(/n3$/)
          response = `curl -k -i -H Accept:text/tab-separated-values -H "subjectid:#{@@subjectid}" #{u}`
          assert_match /HTTP\/1.1 200 OK/, response.to_s.encode!('UTF-8', 'UTF-8', :invalid => :replace) 
        end
      end

      # delete
      response = `curl -k -i -X DELETE -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /200/, response
      response = `curl -k -i -H "Accept:text/uri-list" -H "subjectid:#{@@subjectid}" #{uri}`
      assert_match /404/, response
    end
  end
=end

end
