. $(cd "$(dirname "$0")"; pwd)/setup.sh

# make benzene prediction w/ lazar m w/ bbrc
task=`curl -X POST \
  --data-urlencode "compound_uri=$lh:8082/compound/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H" \
  $lazar_m_bbrc`
lazar_p_bbrc=`get_result "$task"`
echo "lazar_p_bbrc: $lazar_p_bbrc" 
