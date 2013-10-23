require_relative "setup.rb"
#require 'capybara/dsl'
#require 'capybara-webkit'

#Capybara.default_driver = :webkit
#Capybara.default_wait_time = 20
#Capybara.javascript_driver = :webkit
#Capybara.run_server = false
#Capybara.app_host = 'https://services.in-silico.ch/predict'

class LazarWebTest < MiniTest::Test
  #i_suck_and_my_tests_are_order_dependent!

  def test_online
    response = `curl -ki http://services.in-silico.ch`
    assert_match /301/, response
    response = `curl -ki https://services.in-silico.ch`
    assert_match /302/, response
    assert_match /predict/, response
  end

=begin  
  include Capybara::DSL

  def test_00_xsetup
    `Xvfb :1 -screen 0 1024x768x16 2>/dev/null &`
    sleep 2
  end

  def test_01_visit
    visit('/')
    assert page.has_content?('Lazar Toxicity Predictions')
  end

  def test_01_b_validate_html
    visit('/')
    html = page.source
    visit('http://validator.w3.org/#validate_by_input')
    within_fieldset('validate-by-input') do
      fill_in('fragment', :with => html)
    end
    click_button('Check')
    assert page.has_content?('This document was successfully checked as HTML5'), "true"
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

  def test_02_insert_wrong_smiles
    visit('/')
    page.fill_in 'identifier', :with => "blahblah"
    check('selection[Hamster]')
    first(:button, '>>').click
    assert page.has_content?('Attention')
  end

  def test_03_check_all_links_exists
    visit('/')
    links = ['Details', 'SMILES', 'in-silico toxicology gmbh']
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
    # open sf view
    find_link('linkPredictionSf').click
    sleep 5
    within_frame('iframe_overview') do
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
      # close sf view
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
    within_frame('iframe_overview') do
      assert page.has_content?('SMILES:'), "true"
      assert page.has_content?('c1ccc(cc1)NN'), "true"
      assert page.has_content?('InChI:'), "true"
      assert page.has_content?('1S/C6H8N2/c7-8-6-4-2-1-3-5-6/h1-5,8H,7H2'), "true"
      assert page.has_content?('Names:'), "true"
      assert page.has_content?('Phenylhydrazine'), "true"
      assert page.has_link?('PubChem read across'), "true"
      find_button('closebutton').click
    end
  end

  def test_05_multithread_visit_and_predict
    threads = []
    2.times do |t|
      threads << Thread.new(t) do |up|
        session = Capybara::Session.new(:selenium)
        puts "Start Time >> " << (Time.now).to_s
        session.visit('/')
        session.fill_in 'identifier', :with => 'NNc1ccccc1'
        session.check('selection[LC50-mmol]')
        session.check('selection[Hamster]')
        session.check('selection[Mutagenicity]')
        session.first(:button, '>>').click
        # check for Prediction page
        assert session.has_content?('Prediction Results'), "true"
        assert session.has_no_content?('502'), "true"
        puts "Predict Time >> " << (Time.now).to_s
      end
    end
    threads.each {|aThread| aThread.join}
  end

  def test_99_kill
    `pidof Xvfb|xargs kill`
  end
=end
end
