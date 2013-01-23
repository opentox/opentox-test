dir=`dirname -z "$0"`
. $dir/setup.sh

# create lazar m w/ bbrc
task=`curl -X POST \
--data-urlencode "dataset_uri=$ds" \
--data-urlencode "feature_dataset_uri=$pc_fds" \
--data-urlencode "feature_generation_uri=$ds/pc" \
$ALGORITHM/lazar`
lazar_m_pc=`get_result "$task"`
echo "lazar_m_pc: $lazar_m_pc"
