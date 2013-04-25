class String 
  def uri?
    uri = URI.parse(self)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end

class ValidationTestUtil    
  
  @@dataset_uris = {}
  @@prediction_features = {}

  def self.upload_dataset(file, subjectid=nil, dataset_service=$dataset[:uri])
    internal_server_error "File not found: "+file.path.to_s unless File.exist?(file.path)
    if @@dataset_uris[file.path.to_s]==nil
      puts "uploading file: "+file.path.to_s
      if (file.path =~ /csv$/)
        d = OpenTox::Dataset.new nil, subjectid
        d.upload file.path
        internal_server_error "num features not 1 (="+d.features.size.to_s+"), what to predict??" if d.features.size != 1
        @@prediction_features[file.path.to_s] = d.features[0].uri
        @@dataset_uris[file.path.to_s] = d.uri
      else
        internal_server_error "unknown file type: "+file.path.to_s
      end
      puts "uploaded dataset: "+d.uri
    else
      puts "file already uploaded: "+@@dataset_uris[file.path.to_s]
    end
    return @@dataset_uris[file.path.to_s]
  end
  
  def self.prediction_feature_for_file(file)
    @@prediction_features[file.path.to_s]
  end

end
