require_relative "setup.rb"
require 'capybara'
require 'capybara-webkit'

ENV['DISPLAY'] ="localhost:1.0"

Capybara.register_driver :webkit do |app|
  Capybara::Webkit::Driver.new(app).tap{|d| d.browser.ignore_ssl_errors}
end
Capybara.default_driver = :webkit
Capybara.default_wait_time = 20
Capybara.javascript_driver = :webkit
Capybara.run_server = false
Capybara.app_host =$lazar_gui[:uri] 

begin
  puts "Service URI is: #{$lazar_gui[:uri]}"
rescue
  puts "Configuration Error: $aop[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class LazarWebTest < MiniTest::Test
  
  def self.test_order
    :sorted
  end
  
  include Capybara::DSL

  def test_00_xsetup
    `Xvfb :1 -screen 0 1024x768x16 2>/dev/null &`
    sleep 2
  end

  def test_01_visit
    visit('/predict')
    assert page.has_content?('Lazar Toxicity Predictions')
    assert page.has_content?('DSSTox Carcinogenic Potency DBS ActivityOutcome Hamster (CPDBAS)')
  end
  def test_02_insert_wrong_smiles
    visit('/')
    page.fill_in 'identifier', :with => "blahblah"
    check('selection[Hamster]')
    first(:button, '>>').click
    assert page.has_content?('Attention')
  end

  def test_03_check_all_links_exists
    visit('/')
    links = ["Details", "SMILES", "toxicology gmbh 2004 - #{Time.now.year.to_s}"]
    links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
  end

  def test_04_predict
    visit('/')
    page.fill_in('identifier', :with => "NNc1ccccc1")
    check('selection[Hamster]')
    first(:button, '>>').click
    assert page.has_content?('DSSTox Carcinogenic Potency DBS ActivityOutcome Hamster (CPDBAS)'), "true"
    assert page.has_content?('Type: classification'), "true"
    assert page.has_content?('Result: inactive'), "true"
    assert page.has_content?('Confidence: 0.35'), "true"
    assert page.has_content?('Neighbors'), "true"
    assert page.has_link?('Significant fragments'), "true"
    assert page.has_link?('v'), "true"
    # open 'significant fragments' view
    find_link('linkPredictionSf').click
    sleep 5
    within_frame('details_overview') do
      assert page.has_content?('Predominantly in compounds with activity "inactive"'), "true"
      assert page.has_content?('Predominantly in compounds with activity "active"'), "true"
      assert page.has_content?('p value'), "true"
      # inactive
      assert page.has_content?('[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]-[#7&A]'), "true"
      assert page.has_content?('0.98674'), "true"
      assert page.has_content?('[#6&a]:[#6&a](-[#7&A])(:[#6&a]:[#6&a]:[#6&a])'), "true"
      assert page.has_content?('0.97699'), "true"
      assert page.has_content?('[#6&a]:[#6&a](-[#7&A])(:[#6&a]:[#6&a])'), "true"
      assert page.has_content?('0.97699'), "true"
      assert page.has_content?('[#6&a]:[#6&a](-[#7&A])(:[#6&a])'), "true"
      assert page.has_content?('0.97699'), "true"
      assert page.has_content?('[#6&a]:[#6&a]'), "true"
      assert page.has_content?('0.99605'), "true"
      assert page.has_content?('[#6&a]:[#6&a]:[#6&a]:[#6&a]'), "true"
      assert page.has_content?('0.99791'), "true"
      assert page.has_content?('[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]'), "true"
      assert page.has_content?('0.99985'), "true"
      # active
      assert page.has_content?('[#7&A]-[#7&A]'), "true"
      assert page.has_content?('0.99993'), "true"
      # close 'significant fragments' view
      find_button('closebutton').click
    end
    find_link('link0').click
    sleep 2
    assert page.has_content?('Compound'), "true"
    assert page.has_content?('Measured Activity'), "true"
    assert page.has_content?('Similarity'), "true"
    assert page.has_content?('Supporting information'), "true"
    first(:link, 'linkCompound').click
    sleep 5
    within_frame('details_overview') do
      assert page.has_content?('SMILES:'), "true"
      assert page.has_content?('c1ccc(cc1)NN'), "true"
      assert page.has_content?('InChI:'), "true"
      assert page.has_content?('1S/C6H8N2/c7-8-6-4-2-1-3-5-6/h1-5,8H,7H2'), "true"
      assert page.has_content?('Names:'), "true"
      assert page.has_content?('Phenylhydrazine'), "true"
      assert page.has_link?('PubChem read across'), "true"
    end
  end
  def test_99_kill
    `pidof Xvfb|xargs kill`
  end

end
