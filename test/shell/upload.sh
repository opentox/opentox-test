. $(cd "$(dirname "$0")"; pwd)/setup.sh

# load ds
cd
task=`curl -X POST \
-F "file=@opentox-ruby/opentox-test/test/data/hamster_carcinogenicity.csv;type=text/csv" \
$DATASET`
ds=`get_result "$task"`
echo "ds: $ds" 
