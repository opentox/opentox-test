dir=`dirname -z "$0"`
. $dir/setup.sh

# make benzene prediction w/ lazar m w/ pc
task=`curl -X POST \
--data-urlencode "compound_uri=$COMPOUND/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H" \
$lazar_m_pc`
lazar_p_pc=`get_result "$task"`
echo "lazar_p_pc: $lazar_p_pc" 
