# 项目自动、打包

#赋予权限
#chmod 777 auto_ipa.sh 

#项目的根目录路径
PROJECT_PATH="$( cd "$( dirname "$0"  )" && pwd  )";

#选择项目 xcodeproj or xcworkspace 这里是二选一 
PROJECT_TYPE="xcworkspace"

# 项目target名字
TARGET_NAME=""


function getFileName(){

  for file in $(ls $PROJECT_PATH)
  do
    local lastFileName=${file##*.}
    if [[ $lastFileName =~ $PROJECT_TYPE ]]
    then
      TARGET_NAME=$(basename ${file} .$PROJECT_TYPE)
      echo $TARGET_NAME
    fi
  done
}
getFileName
echo ${#TARGET_NAME}

#判断是否获取到当前目录含有 xcode的项目文件
if [[ "${#TARGET_NAME}" -eq 0  ]]; then
	echo "没有获取到项目名称"
	exit;
fi



# 打包环境 Release / Debug
CONFIGURATION=Release

#工程文件路径

APP_PATH="${PROJECT_PATH}/${TARGET_NAME}.$PROJECT_TYPE"

# Xcode clean
xcodebuild clean -workspace "${APP_PATH}" -configuration "${CONFIGURATION}" -scheme "${TARGET_NAME}"

# 打包目录
DESKTOP_PATH="~/Desktop"

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

