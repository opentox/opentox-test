require_relative "setup.rb"
test_path = File.expand_path(File.dirname(__FILE__))
require File.join(test_path,"validation_util.rb")

begin
  puts "Service URI is: #{$validation[:uri]}"
rescue
  puts "Configuration Error: $validation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

DELETE = true
TEST_LISTS = false

DATA = []
#DATA << { :type => :crossvalidation,
#      :data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?max=100",
#      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/26221",
#      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?max=100" } 
#  DATA << { :type => :training_test_validation,
#      :train_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=0&pagesize=150",
#      :test_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=3&pagesize=50",
#      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/26221",
#      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=0&pagesize=150" } 
#  DATA << { :type => :training_test_validation,
#      :train_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=0&pagesize=300",
#      :test_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=30&pagesize=10",
#      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/533748",
#      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=0&pagesize=300" }

FILES = {
  File.new(File.join(test_path,"data","hamster_carcinogenicity.csv")) => :split_validation,
  File.new(File.join(test_path,"data","EPAFHM.medi.csv")) => :split_validation,
}
  
unless defined?($short_tests)
  FILES.merge!({
    File.new(File.join(test_path,"data","hamster_carcinogenicity.csv")) => :crossvalidation,  
    File.new("data/EPAFHM.medi.csv") => :crossvalidation,
   # File.new("data/hamster_carcinogenicity.csv") => :bootstrap_validation
    })
end

FEAT_GEN = {}
FILES.each do |f,t|
  if f.path=~/hamster/
    FEAT_GEN[f] = [ File.join($algorithm[:uri],"fminer/bbrc") ] #FEAT_GEN[f] << File.join($algorithm[:uri],"fminer/last")
  elsif f.path=~/EPAFHM/
    FEAT_GEN[f] = [ File.join($algorithm[:uri],"descriptor","physchem") ]
  else
    raise "please define feature generation uri for dataset: #{f.path}"
  end
end

class ValidationTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  def global_setup
    # subjectid is set in setup.rb
    puts "login and upload datasets"
    OpenTox::RestClientWrapper.subjectid ? puts("logged in: "+OpenTox::RestClientWrapper.subjectid.to_s) : puts("AA disabled")
    FILES.each do |file,type|
      data = { :type => type,
          :data => ValidationTestUtil.upload_dataset(file),
          :feat => ValidationTestUtil.prediction_feature_for_file(file),
          :split_ratio => (file.path=~/EPAFHM/ ? 0.95 : 0.9),#only used for split_validation
          :info => file.path, :delete => true} 
      FEAT_GEN[file].each do |feat_gen|
        data[:alg_params] = "feature_generation_uri="+feat_gen
        data[:alg_params] << ";backbone=false;min_chisq_significance=0.0" if feat_gen=~/fminer/ and data[:info] =~ /mini/
        if feat_gen=~/physchem/
          # validation with physchem descriptors is performed twice, once with feature_generation_uri, once with feature_dataset_uri
          desc = [ "Openbabel.atoms", "Openbabel.bonds", "Openbabel.dbonds", "Openbabel.HBA1", "Openbabel.HBA2", "Openbabel.HBD", "Openbabel.MP", "Openbabel.MR", "Openbabel.MW", "Openbabel.nF", "Openbabel.sbonds", "Openbabel.tbonds", "Openbabel.TPSA"]
          data[:alg_params] << ";descriptors="+desc.join(",")
          DATA << data
          feature_dataset_uri = OpenTox::Algorithm::Generic.new(feat_gen).run({:dataset_uri => data[:data], :descriptors => desc})
          data[:alg_params] = "feature_dataset_uri="+feature_dataset_uri
          DATA << data
        else
          DATA << data
        end
      end
    end
  end
  
  def global_teardown
    puts "delete and logout"
    if defined?(DELETE) and DELETE
      [:data, :train_data, :test_data].each do |d|
        DATA.each do |data| 
          OpenTox::Dataset.new(data[d]).delete if data[d] and data[:delete]
        end
      end
      @@vs.each{|v| v.delete} if defined?@@vs
      @@cvs.each{|cv| cv.delete} if defined?@@cvs
      @@reports.each{|report| report.delete} if defined?@@reports
    end
  end  

  def test_validation_list
    return unless TEST_LISTS
    puts "test_validation_list"
    list = OpenTox::Validation.list
    assert list.is_a?(Array)
    list.each do |l|
      assert l.uri?
    end
  end

  def test_bootstrapping

    @@vs = [] unless defined?@@vs
    DATA.each do |data|
      if data[:type]==:bootstrap_validation
        puts "bootstrapping "+data[:info].to_s
        p = { 
          :dataset_uri => data[:data],
          :algorithm_uri => File.join($algorithm[:uri],"lazar"),
          :algorithm_params => data[:alg_params],
          :prediction_feature => data[:feat],
          :random_seed => 2}
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for boostrap validation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        v = OpenTox::Validation.create_bootstrapping_validation(p, t)
        assert v.uri.uri?
        if $aa[:uri]
          assert_unauthorized do
            OpenTox::Validation.find(v.uri)
          end
        end
        v = OpenTox::Validation.find(v.uri)
        assert_valid_date v
        assert v.uri.uri?
        assert_prob_correct(v)
        model = v.metadata[RDF::OT.model.to_s]
        assert model.uri?
        v_list = OpenTox::Validation.list( {:model => model} )
        assert v_list.size==1 and v_list.include?(v.uri)
        puts v.uri unless defined?(DELETE) and DELETE
        @@vs << v
      end
    end    
    
  end
  
  def test_training_test_split
    
    @@vs = [] unless defined?@@vs
    DATA.each do |data|
      if data[:type]==:split_validation
        puts "test_training_test_split "+data[:info].to_s
        p = { 
          :dataset_uri => data[:data],
          :algorithm_uri => File.join($algorithm[:uri],"lazar"),
          :algorithm_params => data[:alg_params],
          :prediction_feature => data[:feat],
          :split_ratio => data[:split_ratio],
          :random_seed => 2}
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for training-test-split validation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        v = OpenTox::Validation.create_training_test_split(p, t)
        assert v.uri.uri?
        if $aa[:uri]
          assert_unauthorized do
            OpenTox::Validation.find(v.uri)
          end
        end
        v = OpenTox::Validation.find(v.uri)
        #v_uri = "http://localhost:8087/validation/90"
        #v = OpenTox::Validation.find(v_uri)
        
        assert_valid_date v
        assert v.uri.uri?
        assert_prob_correct(v)
        
        train_compounds = OpenTox::Dataset.find(v.metadata[RDF::OT.trainingDataset.to_s]).compounds
        test_compounds = OpenTox::Dataset.find(v.metadata[RDF::OT.testDataset.to_s]).compounds
        orig_compounds = OpenTox::Dataset.find(data[:data]).compounds
        assert_equal((orig_compounds.size*data[:split_ratio]).round,train_compounds.size)
        assert_equal(orig_compounds.size,(train_compounds+test_compounds).size)
        assert_equal(orig_compounds.uniq.size,(train_compounds+test_compounds).uniq.size)
        
        model = v.metadata[RDF::OT.model.to_s]
        assert model.uri?
        v_list = OpenTox::Validation.list( {:model => model} )
        assert v_list.size==1 and v_list.include?(v.uri)
        puts v.uri unless defined?(DELETE) and DELETE
        @@vs << v
      end
    end
  end
  
  
  def test_training_test_validation
    
    @@vs = [] unless defined?@@vs
    DATA.each do |data|
      if data[:type]==:training_test_validation
        puts "test_training_test_validation "+data[:info].to_s
        p = { 
          :training_dataset_uri => data[:train_data],
          :test_dataset_uri => data[:test_data],
          :algorithm_uri => File.join($algorithm[:uri],"lazar"),
          :algorithm_params => data[:alg_params],
          :prediction_feature => data[:feat]}
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for training-test-set validation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        v = OpenTox::Validation.create_training_test_validation(p, t)
        assert v.uri.uri?
        if $aa[:uri]
          assert_unauthorized do
            OpenTox::Validation.find(v.uri)
          end
        end
        v = OpenTox::Validation.find(v.uri)
        assert_valid_date v
        assert v.uri.uri?
        assert_prob_correct(v)
        model = v.metadata[RDF::OT.model.to_s]
        assert model.uri?
        v_list = OpenTox::Validation.list( {:model => model} )
        assert v_list.size==1 and v_list.include?(v.uri)
        puts v.uri unless defined?(DELETE) and DELETE
        @@vs << v
      end
    end
  end

  def test_filter_predictions
    (@@vs + @@cv).each do |v|

      v = v.statistics if v.is_a?(OpenTox::Crossvalidation)
      puts v.metadata.to_yaml
      assert v.metadata[RDF::OT.numInstances.to_s].to_i>3
 
      # get top 3 predictions
      filtered = v.filter(nil, nil, 3)
      puts filtered.to_yaml
      assert filtered[RDF::OT.numInstances.to_s].to_i==3,"#{filtered[RDF::OT.numInstances.to_s]} != 3"
      assert filtered[RDF::OT.numUnpredicted.to_s].to_i==0

      # get predictions with min confidence 0.5 but at least 5 predictions
      filtered = v.filter(0.5, 5)
      puts filtered.to_yaml
      assert filtered[RDF::OT.numInstances.to_s].to_i>=5
      
    end
  end
  

  
  def test_validation_report
    @@reports = [] unless defined?@@reports
    @@vs.each do |v|
      puts "test_validation_report"
      assert defined?v,"no validation defined"
      assert_kind_of OpenTox::Validation,v
      if $aa[:uri]
        assert_unauthorized do
          OpenTox::ValidationReport.create(v.uri)
        end
      end
      report = OpenTox::ValidationReport.find_for_validation(v.uri)
      assert_nil report,"report already exists for validation\nreport: "+(report ? report.uri.to_s : "")+"\nvalidation: "+v.uri.to_s
      params = {:min_confidence => 0.05}
      report = OpenTox::ValidationReport.create(v.uri,params)
      assert report.uri.uri?
      if $aa[:uri]
        assert_unauthorized do
          OpenTox::ValidationReport.find(report.uri)
        end
      end
      report = OpenTox::ValidationReport.find(report.uri)
      assert_valid_date report
      assert report.uri.uri?
      report2 = OpenTox::ValidationReport.find_for_validation(v.uri)
      assert_equal report.uri,report2.uri
      report3_uri = v.find_or_create_report
      assert_equal report.uri,report3_uri
      puts report2.uri unless defined?(DELETE) and DELETE
      @@reports << report2
    end  
  end

  def test_crossvalidation_list
    return unless TEST_LISTS
    puts "test_crossvalidation_list"
    list = OpenTox::Crossvalidation.list
    assert list.is_a?(Array)
    list.each do |l|
      assert l.uri?
    end
  end

  def test_crossvalidation
    
    #assert_rest_call_error OpenTox::NotFoundError do 
    #  OpenTox::Crossvalidation.find(File.join(CONFIG[:services]["opentox-validation"],"crossvalidation/noexistingid"))
    #end
    @@cvs = []
    @@cv_datasets = []
    @@cv_identifiers = []
    DATA.each do |data|
      if data[:type]==:crossvalidation
        puts "test_crossvalidation "+data[:info].to_s+" "+data[:alg_params]
        p = { 
          :dataset_uri => data[:data],
          :algorithm_uri => File.join($algorithm[:uri],"lazar"),
          :algorithm_params => data[:alg_params],
          :prediction_feature => data[:feat],
          :num_folds => 10 }
          #:num_folds => 2 }
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for crossvalidation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        cv = OpenTox::Crossvalidation.create(p, t)
        assert cv.uri.uri?
        if $aa[:uri]
          assert_unauthorized do
            OpenTox::Crossvalidation.find(cv.uri)
          end
        end
        cv = OpenTox::Crossvalidation.find(cv.uri)
        assert_valid_date cv
        assert cv.uri.uri?
        stats_val = cv.statistics
        assert_kind_of OpenTox::Validation,stats_val
        assert_prob_correct(stats_val)
        
        algorithm = cv.metadata[RDF::OT.algorithm.to_s]
        assert algorithm.uri?
        cv_list = OpenTox::Crossvalidation.list( {:algorithm => algorithm} )
        assert cv_list.include?(cv.uri)
        cv_list.each do |cv_uri|
          #begin catch not authorized somehow
            alg = OpenTox::Crossvalidation.find(cv_uri).metadata[RDF::OT.algorithm.to_s]
            assert alg==algorithm,"wrong algorithm for filtered crossvalidation, should be: '"+algorithm.to_s+"', is: '"+alg.to_s+"'"
          #rescue 
          #end
        end
        puts cv.uri unless defined?(DELETE) and DELETE
        
        @@cvs << cv
        @@cv_datasets << data
        @@cv_identifiers << data[:alg_params]
      end
    end
  end
    
  def test_crossvalidation_report
    #@@cv = OpenTox::Crossvalidation.find("http://local-ot/validation/crossvalidation/48", SUBJECTID)
    
    @@reports = [] unless defined?@@reports
    @@cvs.each do |cv|
      puts "test_crossvalidation_report"
      assert defined?cv,"no crossvalidation defined"
      assert_kind_of OpenTox::Crossvalidation,cv
      #assert_rest_call_error OpenTox::NotFoundError do 
      #  OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri)
      #end
      if $aa[:uri]
        assert_unauthorized do
          OpenTox::CrossvalidationReport.create(cv.uri)
        end
      end
      assert OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri)==nil
      report = OpenTox::CrossvalidationReport.create(cv.uri)
      assert report.uri.uri?
      if $aa[:uri]
        assert_unauthorized do
          OpenTox::CrossvalidationReport.find(report.uri)
        end
      end
      report = OpenTox::CrossvalidationReport.find(report.uri)
      assert_valid_date report
      assert report.uri.uri?
      report2 = OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri)
      assert_equal report.uri,report2.uri
      report3_uri = cv.find_or_create_report
      assert_equal report.uri,report3_uri
      puts report2.uri unless defined?(DELETE) and DELETE
      @@reports << report2
    end  
  end
  
  def test_crossvalidation_compare_report
    @@reports = [] unless defined?@@reports
    @@cvs.size.times do |i|
      @@cvs.size.times do |j|
        if j>i and @@cv_datasets[i]==@@cv_datasets[j]
          puts "test_crossvalidation_compare_report"
          assert_kind_of OpenTox::Crossvalidation,@@cvs[i]
          assert_kind_of OpenTox::Crossvalidation,@@cvs[j]
          hash = { @@cv_identifiers[i] => [@@cvs[i].uri],
                   @@cv_identifiers[j] => [@@cvs[j].uri] }
          if $aa[:uri]
            assert_unauthorized do
              OpenTox::AlgorithmComparisonReport.create hash,{}
            end
          end
          assert OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[i].uri)==nil
          assert OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[j].uri)==nil
          
          params = {:ttest_significance => 0.95, :ttest_attributes => "real_runtime,percent_unpredicted", :max_num_predictions => 5}
          report = OpenTox::AlgorithmComparisonReport.create hash,params
          assert report.uri.uri?
          if $aa[:uri]
            assert_unauthorized do
              OpenTox::AlgorithmComparisonReport.find(report.uri)
            end
          end
          report = OpenTox::AlgorithmComparisonReport.find(report.uri)
          assert_valid_date report
          assert report.uri.uri?
          report2 = OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[i].uri)
          assert_equal report.uri,report2.uri
          report3 = OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[j].uri)
          assert_equal report.uri,report3.uri
          puts report2.uri unless defined?(DELETE) and DELETE
          @@reports << report2 
        end
      end
    end
  end

  # checks if opentox_object has date defined in metadata, and time is less than max_time seconds ago
  def assert_valid_date( opentox_object, max_time=600 )
    
    internal_server_error "no opentox object" unless opentox_object.class.to_s.split("::").first=="OpenTox"
    assert opentox_object.metadata.is_a?(Hash)
    puts opentox_object.class
    puts RDF::DC.date.to_s
    puts opentox_object.metadata.inspect
    assert opentox_object.metadata[RDF::DC.date.to_s],"date not set for "+opentox_object.uri.to_s+", is metadata loaded? (use find) :\n"+opentox_object.metadata.to_yaml
    time = Time.parse(opentox_object.metadata[RDF::DC.date.to_s])
    assert time!=nil
=begin    
    assert time<Time.new,"date of "+opentox_object.uri.to_s+" is in the future: "+time.to_s
    assert time>Time.new-(10*60),opentox_object.uri.to_s+" took longer than 10 minutes "+time.to_s
=end
  end
  
  def assert_prob_correct( validation )
    class_stats = validation.metadata[RDF::OT.classificationStatistics]
    if class_stats != nil
      class_value_stats = class_stats[RDF::OT.classValueStatistics]
      class_value_stats.each do |cs|
        #puts cs[RDF::OT.positivePredictiveValue]
        #puts validation.probabilities(0,cs[RDF::OT.classValue]).inspect
        assert cs[RDF::OT.positivePredictiveValue]==validation.probabilities(0,cs[RDF::OT.classValue])[:probs][cs[RDF::OT.classValue]]
      end
    end
  end  
  
  def assert_unauthorized
    unless $aa[:uri]
      puts "AA disabled: skipping test for not authorized"
      return
    else
      subjectid = OpenTox::RestClientWrapper.subjectid
      OpenTox::RestClientWrapper.subjectid = nil
      begin
        res = yield
        assert false,"no un-authorized error thrown, result is #{res}"
      rescue => ex
        assert ex.is_a?(OpenTox::UnauthorizedError),"not unauthorized error, instead: #{ex.class}"
      ensure
        OpenTox::RestClientWrapper.subjectid = subjectid
      end
    end
  end
  
  # hack to have a global_setup and global_teardown 
  def teardown
    if((@@expected_test_count-=1) == 0)
      global_teardown
    end
  end
  def setup
    unless defined?@@expected_test_count
      @@expected_test_count = (self.class.instance_methods.reject{|method| method[0..3] != 'test'}).length
      global_setup
    end
  end  

end
