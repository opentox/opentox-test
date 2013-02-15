dir=`dirname -z "$0"`
. $dir/setup.sh

task=`curl \
--data-urlencode "pc_type=geometrical"  \
-X POST $ds/pc`
echo $task
pc_fds=`get_result "$task"`
echo "pc_fds: $pc_fds"
