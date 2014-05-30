require_relative "toxbank-setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")
require 'net/ftp'

begin
  puts "Service URI is: #{$investigation[:uri]} with FTP server: #{$ftp[:uri]}" 
  $ftp = Net::FTP.open($ftp[:uri], $pi[:name], $pi[:password]) 
rescue
  puts "Configuration Error: $ftp[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationFTP < MiniTest::Test

  i_suck_and_my_tests_are_order_dependent!
  
  $testdir = "nightlytempdir#{Time.now.strftime("%Y%m%d")}" # test directory on ftp server e.G.: nightlytempdir20140528

  # check user root dir
  def test_00_checkftpconnection
    $ftp.chdir("/")
    assert_equal $ftp.pwd, "/"
  end

  # create a testdirectory and upload a file 
  def test_01_create_folder_and_upload_file
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    
    begin
      $ftp.chdir($testdir)
    rescue Net::FTPPermError, NameError => boom
      $ftp.mkdir($testdir)
    end
    $ftp.chdir("/")
    $ftp.chdir($testdir)
    assert_equal $ftp.pwd, "/#{$testdir}"
    files = $ftp.list
    
    $ftp.putbinaryfile(file)
    f = $ftp.list(File.basename(file))
    assert_equal f[0].split[8], File.basename(file), "file #{File.basename(file)} do not exist on ftp server." 

    response = OpenTox::RestClientWrapper.get  $investigation[:uri]+"/ftpfiles", {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s

    files_to_check = ["subdir/JIC37_Ethanol_0.07_Internal_1_3.txt","JIC37_Ethanol_0.07_Internal_1_3.txt","subdir/isttest.txt","isttest.txt","#{$testdir}/#{File.basename(file)}"]
    files_to_check.each do |ftc|
      refute_nil response.match("(^|\n)#{ftc}(\n|$)"), "File: #{ftc} is not in ftpfiles"
    end

    $ftp.delete(File.basename(file))
    assert_raises Net::FTPTempError do
      f = $ftp.list(File.basename(file))
    end
    $ftp.chdir("/")      
    $ftp.rmdir($testdir)
    assert_raises Net::FTPPermError do
      $ftp.chdir($testdir)
    end
  end


  # close connection and check if it is closed
  def test_99_close
    $ftp.close
    assert $ftp.closed?, "connection not closed"
  end
end