echo "传递参数";
echo "当前脚本路径：$0";

PROJECT_PATH="$( cd "$( dirname "$0"  )" && pwd  )";


# 项目target名字
TARGET_NAME=$1

# 打包环境
CONFIGURATION=Release

#工程文件路径
# APP_PATH="${PROJECT_PATH}.xcodeproj"  #普通工程
APP_PATH="${PROJECT_PATH}/${TARGET_NAME}.xcworkspace"   #带pod工作区

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

# # 导出ipa
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${EXPORT_PATH}" -exportOptionsPlist "${PLIST_PATH}"

