. $(cd "$(dirname "$0")"; pwd)/setup.sh

# create lazar m w/ bbrc
task=`curl -X POST \
  --data-urlencode "dataset_uri=$ds" \
  --data-urlencode "feature_generation_uri=$lh:8081/algorithm/fminer/bbrc" \
  $lh:8081/algorithm/lazar`
lazar_m_bbrc=`get_result "$task"`
echo "lazar_m_bbrc: $lazar_m_bbrc"
