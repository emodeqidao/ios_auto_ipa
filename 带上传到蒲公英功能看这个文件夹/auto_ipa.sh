# 项目自动、打包

# 赋予权限
# chmod 777 auto_ipa.sh 

# ps:脚本需要放在项目根目录, 同时需要 ExportOptions.plist 也放在项目根目录
# 1、如果只需要导出ipa则只需要设置 PROJECT_TYPE 的值, 其它值不需要填写
# 2、如果TARGET_NAME 和 Display_Name 不一样则需要手动设置Display_Name（Display_Name 和项目里面设置的保持一样）, 如果是一样则忽略 Display_Name
# 3、如果你不需要提交到蒲公英 就将 UPLOADPGYER=flase 和 pgyerApiKey=""
# 4、如果需要添加蒲公英更新说明则在 脚本后面 添加  举个栗子： ./auth_ipa.sh 我是版本更新内容
# 5、导出的ipa 在你的桌面

# 选择项目 xcodeproj or xcworkspace 这里是二选一 
PROJECT_TYPE="xcworkspace"
# 是否需要上传到蒲公英
UPLOADPGYER=true
# 蒲公英的key
PgyerApiKey=123456
#Display_NAME
DISPLAY_NAME=""


# --------------我是分割线-------------------
# --------------我是分割线-------------------

# 项目的根目录路径
PROJECT_PATH="$( cd "$( dirname "$0"  )" && pwd  )";

# 项目target名字
TARGET_NAME=""


function getFileName(){

  for file in $(ls $PROJECT_PATH)
  do
    local lastFileName=${file##*.}
    if [[ $lastFileName =~ $PROJECT_TYPE ]]
    then
      TARGET_NAME=$(basename ${file} .$PROJECT_TYPE)
    fi
  done
}
getFileName

# 判断是否获取到当前目录含有 xcode的项目文件
if [[ "${#TARGET_NAME}" -eq 0  ]]; then
	echo "没有获取到项目名称"
	exit;
fi



# 打包环境 Release / Debug
CONFIGURATION=Release

# 工程文件路径

APP_PATH="${PROJECT_PATH}/${TARGET_NAME}.$PROJECT_TYPE"

# Xcode clean
xcodebuild clean -workspace "${APP_PATH}" -configuration "${CONFIGURATION}" -scheme "${TARGET_NAME}"

# 打包目录
HOME_PATH=$(echo ${HOME})
DESKTOP_PATH="${HOME_PATH}/Desktop"

# 时间戳
CURRENT_TIME=$(date "+%Y-%m-%d %H-%M-%S")

# 归档路径
ARCHIVE_PATH="${DESKTOP_PATH}/${TARGET_NAME} ${CURRENT_TIME}/${TARGET_NAME}.xcarchive"

# 导出路径
EXPORT_PATH="${DESKTOP_PATH}/${TARGET_NAME} ${CURRENT_TIME}"

# plist路径
PLIST_PATH="${PROJECT_PATH}/ExportOptions.plist"

# archive 这边使用的工作区间 也可以使用project
xcodebuild archive -workspace "${APP_PATH}" -scheme "${TARGET_NAME}" -configuration "${CONFIGURATION}" -archivePath "${ARCHIVE_PATH}" 

# 导出ipa
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${EXPORT_PATH}" -exportOptionsPlist "${PLIST_PATH}"


# 上传到蒲公英
if [ $UPLOADPGYER = true ]; then
 # 获取第一个参数
  varBuildUpdateDescription=$1
    
  
  #如果有设置DISPLAY_NAME怎取DISPLAY_NAME ，否则默认取TARGET_NAME
  IPAPATH=""
  if [ -n "$DISPLAY_NAME" ] 
    then
    IPAPATH="${EXPORT_PATH}/${DISPLAY_NAME}.ipa"
  else
    IPAPATH="${EXPORT_PATH}/${TARGET_NAME}.ipa"
  fi
  echo $IPAPATH
    
  # 上传蒲公英  
  echo "~~~~~~~~~~~~~~~~上传ipa到蒲公英~~~~~~~~~~~~~~~~~~~"\
  RESULT=$(curl -F "file=@${IPAPATH}" -F "_api_key=${PgyerApiKey}" -F "buildUpdateDescription=${varBuildUpdateDescription}" https://www.pgyer.com/apiv2/app/upload)
  echo $RESULT

 
  if [ $? = 0 ]
    then
  echo "\n"
    echo "~~~~~~~~~~~~~~~~上传蒲公英成功~~~~~~~~~~~~~~~~~~~"
  else
    echo "\n"
  echo "~~~~~~~~~~~~~~~~上传蒲公英失败~~~~~~~~~~~~~~~~~~~"
  fi

fi


