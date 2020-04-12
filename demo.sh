function getfiles(){
  for file in `ls $1`
  do
    if [ -d $1"/"$file ]
    then
      echo $1"/"$file
      getfiles $1"/"$file
    else
      # 这里是对文件的操作，可以是移动，删除，复制，
      # 也可以在对文件进行判断，支队指定类型的文件进行操作
      echo $file
      find $file;
    fi
  done
}


function find(){
  # key='.xcworkspace'
  key="pli"
  if [[ $1 =~ $key ]]
  then
    echo "包含"
  else
     echo "不包含"
  fi
}
 
getfiles $1
