. $(cd "$(dirname "$0")"; pwd)/setup.sh

task=`curl \
--data-urlencode "pc_type=geometrical"  \
-X POST $ds/pc`
pc_fds=`get_result "$task"`
echo "pc_fds: $pc_fds"
