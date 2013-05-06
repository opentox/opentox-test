require 'test/unit'
require 'capybara/dsl'
require 'capybara-webkit'
require 'capybara_minitest_spec'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 20
Capybara.javascript_driver = :webkit
Capybara.run_server = false

class LazarWebTest < MiniTest::Unit::TestCase
  i_suck_and_my_tests_are_order_dependent!
  
  include Capybara::DSL

  @@uri = "http://istva:8080/toxcreate"

=begin  
  def test_00_start
    `Xvfb :1 -screen 0 1024x768x16 -nolisten inet6 &`
    sleep 2
  end
=end
  def test_01_a_visit
    visit(@@uri)
    assert page.has_content?('Lazar Toxicity Predictions')
  end

# temporarily disabled html/css validation
=begin
  def test_01_b_validate_html
    visit(@@uri)
    html = page.source
    puts "\n#{page.source}\n"
    visit('http://validator.w3.org/#validate-by-input')
    within_fieldset('validate-by-input') do
      fill_in 'fragment', :with => html
    end
    first(:button, 'Check').click
    assert page.has_content?('This document was successfully checked as XHTML 1.0 Transitional!'), "true"
  end

  def test_01_c_validate_css
    # style.css
    visit(@@uri + '/stylesheets/style.css')
    html = page.source
    visit('http://jigsaw.w3.org/css-validator/validator.html.en#validate_by_input')
    within_fieldset('validate-by-input') do
      fill_in 'text', :with => html
    end
    first(:button, 'Check').click
    assert page.has_content?('Congratulations! No Error Found.'), "true"
    # progressbar.css
    visit(@@uri + '/progressbar/progressbar.css')
    html = page.source
    visit('http://jigsaw.w3.org/css-validator/validator.html.en#validate_by_input')
    within_fieldset('validate-by-input') do
      fill_in 'text', :with => html
    end
    first(:button, 'Check').click
    assert page.has_content?('Congratulations! No Error Found.'), "true"
  end
=end
  def test_02_a_insert_wrong_smiles
    visit(@@uri)
    page.fill_in 'identifier', :with => "blahblah"
    check('model6')
    first(:button, 'Predict').click
    assert page.has_content?('OpenTox::RestCallError')
    visit(@@uri)
    page.fill_in 'identifier', :with => "N9N7N8"
    check('model6')
    first(:button, 'Predict').click
    assert page.has_content?('OpenTox::RestCallError')
  end
  
  def test_02_b_check_all_links_exists
    visit(@@uri)
    links = ['Prediction', '(help)', 'JME Editor', 'SMILES', 'in silico toxicology gmbh', 'Validation']
    links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
  end

  def test_03_MOU
    visit(@@uri)
    page.fill_in('identifier', :with => "NNc1ccccc1")
    check('model6')
    first(:button, 'Predict').click
    assert page.has_content?('MOU (pTD50)'), "true"
    assert page.has_content?('3.1809'), "true"
    assert page.has_content?('TD50'), "true"
    assert page.has_content?('71.4481'), "true"
    assert page.has_link?('Measured activity'), "true"
    first(:link, 'Measured activity').click
    assert page.has_content?('Experimental result(s) from the training dataset.'), "true"
  end

  def test_04_RAT
    visit(@@uri)
    page.fill_in('identifier', :with => "NNc1ccccc1")
    check('model9')
    first(:button, 'Predict').click
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody') do
      assert page.has_content?('RAT (pTD50)'), "true"
      assert page.has_content?('4.8504'), "true"
      assert page.has_content?('TD50'), "true"
      assert page.has_content?('1.5275 '), "true"
      assert page.has_link?('Confidence'), "true"
      assert page.has_content?('0.585'), "true"
      assert page.has_button?('Details'), "true"
      first(:button, 'Details').click
    end
    # check lazar help is shown
    within('html body div.content div.lazar-predictions dl#lazar_algorithm') do
      links = ['similar', 'Physico chemical descriptors', 'activity specific similarities']
      links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
    end
    # check prediction table links
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody') do
      links = ['Prediction', 'Confidence', 'Names and synonyms', 'Physico chemical descriptors', 'Measured activity', 'Similarity']
      links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
    end
    # check thead
    within(:xpath, '/html/body/div[3]/div[3]/table/thead') do
      content = ['pTD50', 'Supporting information']
      content.each{|c| puts c.to_s; assert page.has_content?(c), "true"}
      links = ['Prediction', 'Confidence']
      links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[2]') do
      content = ['4.85', 'TD50', '1.5275', '0.585']
      content.each{|c| puts c.to_s; assert page.has_content?(c), "true"}
      links = ['Names and synonyms', 'Physico chemical descriptors']
      links.each{|l| puts l.to_s; assert page.has_link?(l), "true"}
    end
    # check for neighbors 
    within(:xpath, '//*[@id="neighbors"]') do
      content = ['Neighbors', '(1-5/64)']
      content.each{|c| puts c.to_s; assert page.has_content?(c), "true"}
    end
    # click Descriptors
    find('html body div.content div.lazar-predictions table thead tr td ul li a#js_link12').click
    assert page.has_xpath?('//*[@id="fragments"]'), "true"
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr') do
      assert page.has_content?('Descriptors'), "true"
      assert page.has_content?('Values'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[2]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/ALogP'), "true"
      assert page.has_content?('-0.0593000017106533'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[3]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/ALogp2'), "true"
      assert page.has_content?('0.00351649010553956'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[4]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/AMR'), "true"
      assert page.has_content?('38.8675994873047'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[5]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/LipinskiFailures'), "true"
      assert page.has_content?('0.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[6]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/MLogP'), "true"
      assert page.has_content?('1.89999997615814'), "true"
    end
     within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[7]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/XLogP'), "true"
      assert page.has_content?('0.105999998748302'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[8]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nAromBond'), "true"
      assert page.has_content?('6.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[9]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nAtom'), "true"
      assert page.has_content?('16.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[10]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nAtomLAC'), "true"
      assert page.has_content?('0.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[11]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nAtomLC'), "true"
      assert page.has_content?('2.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[12]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nAtomP'), "true"
      assert page.has_content?('8.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[13]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nB'), "true"
      assert page.has_content?('8.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[14]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/nRotB'), "true"
      assert page.has_content?('1.0'), "true"
    end
    within(:xpath, '/html/body/div[3]/div[3]/table/thead/tr[4]/td/table/tbody/tr[15]') do
      assert page.has_content?('http://istva:8080/dataset/10/feature/naAromAtom'), "true"
      assert page.has_content?('6.0'), "true"
    end
  end

  def test_05_prediction_on_four_models_parallel
    visit(@@uri)
    page.fill_in('identifier', :with => "NNc1ccccc1")
    check('model6')
    check('model9')
    check('model10')
    check('model11')
    first(:button, 'Predict').click
    # check table headline
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr/th') do
      assert page.has_content?('NNc1ccccc1')
    end
    # check for image
    #within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr[2]/td') do
    assert page.has_xpath?('/html/body/div[3]/div[3]/table/tbody/tr[2]/td/img')
    #end
    # check for MOU (pTD50)
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr[2]/td[2]') do
      assert page.has_content?('MOU (pTD50):')
      assert page.has_content?('3.1809')
      assert page.has_content?('TD50: 71.4481')
      assert page.has_link?('Measured activity')
    end
    # check for LOAEL (log(mmol/kg bw/day))
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr[2]/td[3]') do
      assert page.has_content?('LOAEL (log(mmol/kg bw/day)):')
      assert page.has_content?('2.519')
      assert page.has_content?('mg/kg bw/day: 326.581')
      assert page.has_content?('0.634')
      assert page.has_link?('Confidence'), "true"
      assert page.has_button?('Details'), "true"
    end
    # check for RAT (pTD50)
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr[2]/td[4]') do
      assert page.has_content?('RAT (pTD50):')
      assert page.has_content?('4.8504')
      assert page.has_content?('TD50: 1.5275')
      assert page.has_content?('0.585')
      assert page.has_link?('Confidence'), "true"
      assert page.has_button?('Details'), "true"
    end
    # check for LOAEL (log(mg/kg bw/day))
    within(:xpath, '/html/body/div[3]/div[3]/table/tbody/tr[2]/td[5]') do
      assert page.has_content?('LOAEL (log(mg/kg bw/day)):')
      assert page.has_content?('2.2527')
      assert page.has_content?('mg/kg bw/day: 177.8279')
      assert page.has_content?('0.634')
      assert page.has_link?('Confidence'), "true"
      assert page.has_button?('Details'), "true"
    end
  end

  def test_06_multithread_visit_and_predict
    threads = []
    5.times do |t|
      threads << Thread.new(t) do |up|
        session = Capybara::Session.new(:webkit)
        puts "Start Time >> " << (Time.now).to_s
        session.visit(@@uri)
        #session.within(:xpath, '/html/body/div[3]/div[3]/form/fieldset') do
        session.fill_in 'identifier', :with => 'NNc1ccccc1'
        #end
        session.check('model6')
        session.check('model9')
        session.check('model10')
        session.check('model11')
        session.first(:button, 'Predict').click
        # check for Prediction page
        assert session.has_content?('NNc1ccccc1'), "true"
        assert session.has_no_content?('Error'), "true"
        puts "Predict Time >> " << (Time.now).to_s
      end
    end
    threads.each {|aThread| aThread.join}
  end

  def test_07_validation
    visit(@@uri)
    click_on 'Validation'
    models = ['//*[@id="model_11"]', '//*[@id="model_10"]', '//*[@id="model_9"]', '//*[@id="model_6"]']
    models.each{|m| assert page.has_xpath?(m), "true"}
    within(:xpath, models[0]) do
      assert page.has_content?('Completed'), "true"
      assert page.has_content?('Training compounds'), "true"
      assert page.has_content?('439'), "true"
      assert page.has_content?('Number of predictions'), "true"
      assert page.has_content?('562'), "true"
      assert page.has_link?('regression'), "true"
    end
    within(:xpath, models[1]) do
      assert page.has_content?('Completed'), "true"
      assert page.has_content?('Training compounds'), "true"
      assert page.has_content?('439'), "true"
      assert page.has_content?('Number of predictions'), "true"
      assert page.has_content?('561'), "true"
      assert page.has_link?('regression'), "true"
    end
    within(:xpath, models[2]) do
      assert page.has_content?('Completed'), "true"
      assert page.has_content?('Training compounds'), "true"
      assert page.has_content?('460'), "true"
      assert page.has_content?('Number of predictions'), "true"
      assert page.has_content?('42'), "true"
      assert page.has_link?('regression'), "true"
    end
    within(:xpath, models[3]) do
      assert page.has_content?('Completed'), "true"
      assert page.has_content?('Training compounds'), "true"
      assert page.has_content?('361'), "true"
      assert page.has_content?('Number of predictions'), "true"
      assert page.has_content?('29'), "true"
      assert page.has_link?('regression'), "true"
    end
  end
=begin
  def test_99_kill
    `pidof Xvfb|xargs kill`
  end
=end
end
