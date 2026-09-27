[INFORMATION]
source_code = https://github.com/simplex-chat/simplexmq
${INFORMATION}

[STORE_LOG]
enable = on
store_files = memory
expire_files_hours = ${EXPIRE_FILES_HOURS}
log_stats = off

[AUTH]
new_files = ${NEW_FILES}
${CREATE_PASSWORD_LINE}

[TRANSPORT]
host = ${ADDR}
port = 443
log_tls_errors = off

[FILES]
path = ${FILES_DIR}
storage_quota = ${QUOTA}

[INACTIVE_CLIENTS]
disconnect = off

${WEB_SECTION}
