dir=`dirname -z "$0"`
. $dir/setup.sh

# load ds
task=`curl -X POST \
-F "file=@$dir/../data/hamster_carcinogenicity.csv;type=text/csv" \
$DATASET`
ds=`get_result "$task"`
echo "ds: $ds" 
