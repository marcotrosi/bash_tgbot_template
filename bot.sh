#!/bin/bash

# config <<<
BotName=bot.sh
SleepTime=2
# >>>

# variables <<<
CfgPath="${HOME}/.config/${BotName}"
# CfgPath="${HOME}/.${BotName}"
TokenFile="${CfgPath}/token"
ChatIDFile="${CfgPath}/chatid"
Token="$(cat "${TokenFile}")"
ChatID="$(cat "${ChatIDFile}")"
Api="https://api.telegram.org/bot${Token}"
LastUpdateID="0"
# >>>

# functions <<<
# getResultLength <<<
function getResultLength()
{
   echo "${1}" | dasel select -p json --length 'result'
   return $?
}
# >>>

# getUpdates <<<
function getUpdates()
{
   CurlCall="${Api}/getUpdates"
   if [ "${LastUpdateID}" != "0" ]
   then
      CurlCall="${CurlCall}?offset=${LastUpdateID}"
   fi
   Response="$(curl -s "${CurlCall}")"
   if [ $? -eq 0 ]
   then
      if [ "$(echo ${Response} | dasel select -p json 'ok')" = "true" ]
      then
         echo "${Response}"
         return 0
      fi
   fi
   echo "pc error: could not get updates"
   return 1 
}
# >>>
# >>>

# main loop <<<

# the workflow in the loop is as follows ...
# - get all new messages, and store update ID
# - check if the number of new messages is different from 0
#    - if 0 new messages, sleep
#    - if >=1 new messages, process them one by one

# the processing is up to you, as demo only an echo is implemented, means the bot responds with what you sent

while true
do
   Messages=$(getUpdates)
   if [ $? -ne 0 ] ; then continue ; fi
   NumOfMessages=$(getResultLength "${Messages}")
   if [ $? -ne 0 ] ; then continue ; fi
   if [ "${NumOfMessages}" -eq 0 ]
   then
      # echo "no new messages"
      sleep "${SleepTime}"
      continue
   fi

   # iterate all new messages
   for (( m=0; m<"${NumOfMessages}"; m++ ))
   do
      Message=$(echo "${Messages}" | dasel select -p json "result.[${m}]")
      LastUpdateID=$(echo "${Message}" | dasel select -p json "update_id")
      MsgUserID=$(echo "${Message}" | dasel select -p json "message.from.id")
      if [ "${MsgUserID}" = "${ChatID}" ]
      then
         # put response code here
         # for testing purpose the bot responds with the same text message as sent by the user
         Text=$(echo "${Message}" | dasel select -p json "message.text")
         Data='{"chat_id": "'${ChatID}'", "text": '${Text}'}'
         curl -s -X POST -H 'Content-Type: application/json' -d "${Data}" "${Api}/sendMessage" > /dev/null
      fi
   done

   LastUpdateID=$((LastUpdateID+1))
done
# >>>

# vim: fdm=marker fmr=<<<,>>>
