# iOS项目自动打包、上传到蒲公英、发送消息到企业微信

# author: xixi

# 赋予权限
# chmod 777 upload.sh 

# ps:脚本需要放在项目根目录, 同时需要 ExportOptions.plist 也放在项目根目录
# 1、如果只需要导出ipa则只需要设置 PROJECT_TYPE 的值, 其它值不需要填写
# 2、如果TARGET_NAME 和 Display_Name 不一样则需要手动设置Display_Name, 如果是一样则忽略  Display_Name
# 3、如果你不需要提交到蒲公英 就将 UPLOADPGYER=flase 和 pgyerApiKey=""
# 4、如果需要添加蒲公英更新说明则在 脚本后面 添加  举个栗子： ./upload.sh 我是版本更新内容
# 5、导出的ipa 在你的桌面，上传完蒲公英会自动删除【如果不想删除，可以更变属性IS_Delete_IPA=false】

# 选择项目 xcodeproj or xcworkspace 这里是二选一 
PROJECT_TYPE="xcworkspace"

# 是否需要上传到蒲公英
UPLOADPGYER=true

# 蒲公英的key
PgyerApiKey=""

#Display_NAME
DISPLAY_NAME="AAAA"

# 打包环境 Release / Debug
CONFIGURATION=Release

# 项目target名字
TARGET_NAME="AAAA"

#企业微信机器人key
BOT_KEY=

#是否需要删除编译打包遗留下来的IPA
IS_Delete_IPA=true

# 是否显示日志 1=enable, 0=disable
LOG_ENABLE=1

# ---------------------------------------------------------------
# function 
# ---------------------------------------------------------------

  # check api_key exists
if [ -z "$PgyerApiKey" ]; then
    echo "PgyerApiKey is empty"
    echo "PgyerApiKey is empty"
    echo "PgyerApiKey is empty"
    exit 1
fi


log() {
    [ $LOG_ENABLE -eq 1 ]  && echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

logTitle() {
    log "-------------------------------- $* --------------------------------"
}

execCommand() {
    log "$@"
    result=$(eval $@)
}

sendMsg() {
  content="$@"
  logTitle $content
  sendPostURL="curl --location --request POST 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${BOT_KEY}' --header 'Content-Type: application/json;charset=utf-8' --data-raw '{\"msgtype\": \"text\",\"text\": {\"content\":\"${content}\"}}'"
  logTitle sendPostURL
  execCommand $sendPostURL
}

# --------------我是分割线-------------------
# --------------我是分割线-------------------
# --------------我是分割线-------------------
# --------------我是分割线-------------------

logTitle '开始打包'


# # 项目的根目录路径
PROJECT_PATH="$( cd "$( dirname "$0"  )" && pwd  )";

gitBranchName=$(echo `git branch --show-current`)
echo '当前打包分支：' $gitBranchName
gitBranchName="qa"

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


logTitle '打包完成'

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

  logTitle $IPAPATH
  # 上传蒲公英  
  logTitle "~~~~~~~~~~~~~~~~开始上传ipa到蒲公英~~~~~~~~~~~~~~~~~~~"

  execCommand "curl -s -F '_api_key=${PgyerApiKey}' -F 'buildUpdateDescription=${varBuildUpdateDescription}' -F 'buildType=ios' http://www.pgyer.com/apiv2/app/getCOSToken"

  [[ "${result}" =~ \"endpoint\":\"([\:\_\.\/\\A-Za-z0-9\-]+)\" ]] && endpoint=`echo ${BASH_REMATCH[1]} | sed 's!\\\/!/!g'`
  [[ "${result}" =~ \"key\":\"([\.a-z0-9]+)\" ]] && key=`echo ${BASH_REMATCH[1]}`
  [[ "${result}" =~ \"signature\":\"([\=\&\_\;A-Za-z0-9\-]+)\" ]] && signature=`echo ${BASH_REMATCH[1]}`
  [[ "${result}" =~ \"x-cos-security-token\":\"([\_A-Za-z0-9\-]+)\" ]] && x_cos_security_token=`echo ${BASH_REMATCH[1]}`

  if [ -z "$key" ] || [ -z "$signature" ] || [ -z "$x_cos_security_token" ] || [ -z "$endpoint" ]; then
    log "get upload token failed"
    exit 1
  fi

  logTitle "开始上传文件"

  execCommand "curl --connect-timeout 60 -m 60 -D - --form-string 'key=${key}' --form-string 'signature=${signature}' --form-string 'x-cos-security-token=${x_cos_security_token}' -F 'file=@${IPAPATH}' ${endpoint}"

  # 如果上传成功：返回 http 状态码为 204 No Content； 如果上传失败：返回相应错误信息说明
  logTitle "上传结果：" "$result"
  if [[ $result -ne 204 ]]; then
    logTitle "上传失败 Upload failed"
    exit 1
  fi

  logTitle "上传成功"



  # ---------------------------------------------------------------
  # 检查结果
  # ---------------------------------------------------------------

  logTitle "开始 检查结果"

  isSuccessGetBuildInfo=false

  for i in {1..60}; do
    logTitle "第${i}次查询"
    execCommand "curl -s http://www.pgyer.com/apiv2/app/buildInfo?_api_key=${PgyerApiKey}\&buildKey=${key}"
    logTitle $result

    [[ "${result}" =~ \"code\":([0-9]+) ]] && code=`echo ${BASH_REMATCH[1]}`
    if [ $code -eq 0 ]; then
      isSuccessGetBuildInfo=true
      logTitle $newResult

      [[ "$result" =~ \"buildQRCodeURL\":\"([\:\_\.\/\\A-Za-z0-9\-]+)\" ]] && buildQRCodeURL=`echo ${BASH_REMATCH[1]} | sed 's!\\\/!/!g'`
      [[ "$result" =~ \buildCreated\":\"(([0-9]{4}-[0-9]{2}-[0-9]{2}) [0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])\" ]] && buildCreated=`echo ${BASH_REMATCH[1]} | sed 's!\\\/!/!g'`

      logTitle $buildQRCodeURL
      logTitle $buildCreated
      logTitle $varBuildUpdateDescription
      content="上传时间: ${buildCreated} \n 二维码：${buildQRCodeURL} \n 更新内容：${varBuildUpdateDescription} \n 当前打包git分支：${gitBranchName}"

      echo $content
      logTitle '开始给企业微信发送消息'
     
      sendMsg $content 
      logTitle $result
      
        
      echo $result
      logTitle $result
      sendResult=$(echo $result)
      if [[ $sendResult =~ "ok" ]]; then
        logTitle "~~~~~~~~~~~~~~~~🎆🎆🎆🎆发送到企业微信成功~~~~~~~~~~~~~~~~~~~"

        if [ $IS_Delete_IPA = true ]; then
        logTitle "删除导出的文件夹 - 开始"
        logTitle "$EXPORT_PATH"
        rm -rf "$EXPORT_PATH"
        logTitle "删除导出的文件夹 - 结束"
        fi
      else 
        logTitle "~~~~~~~~~~~~~~~~⚠️⚠️⚠️⚠️发送到企业微信 失败失败 ~~~~~~~~~~~~~~~~~~~"
      fi

      break
    else
      sleep 1
    fi
  done

  if [ $isSuccessGetBuildInfo = false ]; then
    sendMsg "1分钟了，也没查到新上传的ipa相关发布信息 后续请查看 【括号里面这里填写你的蒲公英短链】  \n 描述内容是：${varBuildUpdateDescription}"
  fi

fi




