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
    puts t.uri
    assert_match t.hasStatus, "Error"
  end
  
  def test_02_valid_xls_upload
    # upload
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid/BII-I-1-tb2.xls"
    response = `curl -Lk -X POST -i -F file="@#{file};type=application/vnd.ms-excel" -H "subjectid:#{$pi[:subjectid]}" #{$investigation[:uri]}`.chomp
    assert_match /202/, response
    uri = response.split("\n")[-1]
    t = OpenTox::Task.new(uri)
    t.wait
    puts t.uri
    assert_match t.hasStatus, "Error"
  end
end
