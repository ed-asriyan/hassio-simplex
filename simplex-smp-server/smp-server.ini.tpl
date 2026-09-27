[INFORMATION]
source_code = https://github.com/simplex-chat/simplexmq
${INFORMATION}

[STORE_LOG]
enable: on
store_queues: memory
store_messages: memory
restore_messages: ${RESTORE_MESSAGES}
expire_messages_days: ${EXPIRE_MESSAGES_DAYS}
expire_messages_on_start: on
expire_ntfs_hours: ${EXPIRE_NTFS_HOURS}
log_stats = off

[AUTH]
new_queues: ${NEW_QUEUES}
${CREATE_PASSWORD_LINE}

[TRANSPORT]
host: ${ADDR}
port: 5223
log_tls_errors: off
websockets: off

[INACTIVE_CLIENTS]
disconnect: on
ttl: 21600
check_interval: 3600
