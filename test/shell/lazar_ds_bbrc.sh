dir=`dirname -z "$0"`
. $dir/setup.sh

# make a dataset prediction
task=`curl -X POST \
-F "file=@$dir/../data/EPAFHM.mini.csv;type=text/csv" \
$DATASET`
mini=`get_result $task`
task=`curl -X POST \
--data-urlencode "dataset_uri=$mini" \
$lazar_m_bbrc`
lazar_ds_bbrc=`get_result "$task"`
echo "lazar_ds_bbrc: $lazar_ds_bbrc"
