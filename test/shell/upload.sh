. shell/setup.sh

# load ds
cd
task=`curl -X POST \
-F "file=@opentox-ruby/opentox-test/test/data/hamster_carcinogenicity.csv;type=text/csv" \
$lh:8083/dataset`
ds=`get_result "$task"`
echo "ds: $ds" 
