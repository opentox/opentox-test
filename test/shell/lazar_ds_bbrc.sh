. $(cd "$(dirname "$0")"; pwd)/setup.sh

# make a dataset prediction
cd
task=`curl -X POST \
-F "file=@opentox-ruby/opentox-test/test/data/EPAFHM.mini.csv;type=text/csv" \
$lh:8083/dataset`
mini=`get_result $task`
task=`curl -X POST \
--data-urlencode "dataset_uri=$mini" \
$lazar_m_bbrc`
lazar_ds_bbrc=`get_result "$task"`
echo "lazar_ds_bbrc: $lazar_ds_bbrc"
