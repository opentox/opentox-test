# util 
function get_result {
  task=$1
  while [ 1 ]; do
    result=`curl -H "accept:text/uri-list" $task 2>/dev/null`
    [ $result == $task ] && sleep 1 || break
  done
  echo $result
}
