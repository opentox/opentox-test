. $(cd "$(dirname "$0")"; pwd)/setup.sh

# make benzene prediction w/ lazar m w/ pc
task=`curl -X POST \
--data-urlencode "compound_uri=$lh:8082/compound/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H" \
$lazar_m_pc`
lazar_p_pc=`get_result "$task"`
echo "lazar_p_pc: $lazar_p_pc" 
