FROM tarantool/tarantool:2.6.0

COPY KeyValue.lua /opt/tarantool
CMD ["tarantool", "/opt/tarantool/KeyValue.lua"]