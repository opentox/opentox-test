require_relative "toxbank-setup.rb"

class ExcelUploadTest < MiniTest::Test

  def setup
    @tmpdir = File.join(File.dirname(__FILE__),"tmp")
    FileUtils.mkdir_p @tmpdir
    FileUtils.rm_r Dir[File.join @tmpdir, '*']
  end

  def test_01_invalid_xls_upload 
    # upload
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid]
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid/isa_TB_ACCUTOX.xls"
    response = `curl -Lk -X POST -i -F file="@#{file};type=application/vnd.ms-excel" -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}`.chomp
    assert_match /202/, response
    uri = response.split("\n")[-1]
    t = OpenTox::Task.new(uri)
    t.wait
    assert_match t.hasStatus, "Error"
  end
  
  def test_02_valid_xls_upload
    # upload
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid/isa_TB_BII.xls"
    response = `curl -Lk -X POST -i -F file="@#{file};type=application/vnd.ms-excel" -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}`.chomp
    assert_match /202/, response
    uri = response.split("\n")[-1]
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid]
    t = OpenTox::Task.new(uri)
    t.wait
    puts t.uri
    assert_equal true, t.completed?
    uri = t.resultURI
    
    # get zip file
    zip = File.join @tmpdir,"tmp.zip"
    `curl -Lk -H "Accept:application/zip" -H "subjectid:#{$pi[:subjectid]}" #{uri} > #{zip}`
    `unzip -o #{zip} -d #{@tmpdir}`
    [
      "i_Investigation.txt",
      "s_BII-S-1.txt",
      "s_BII-S-2.txt",
      "a_metabolome.txt",
      "a_microarray.txt",
      "a_proteome.txt",
      "a_transcriptome.txt",
    ].each{|f| assert_equal true, File.exists?(File.join(@tmpdir,f)) }

    # get isatab files
    `curl -Lk -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{uri}`.split("\n").each do |u|
      if u.match(/txt$/)
        response = `curl -Lk -i -H Accept:text/tab-separated-values -H "subjectid:#{$pi[:subjectid]}" #{u}`
        assert_match /200/, response
      end
    end

    # delete
    response = `curl -Lk -i -X DELETE -H "subjectid:#{$pi[:subjectid]}" #{uri}`
    assert_match /200/, response
    response = `curl -Lk -i -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{uri}`
    assert_match /401/, response
    response = `curl -I -Lk -i -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{uri}`
    assert_match /404/, response
  end
  
end
