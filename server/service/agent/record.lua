local skynet = require "skynet"
local inspect = require "inspect"
local mongox = require "mongox"

local send_message, send_status = send_message, send_status
local M = {}

-- 所有的sql查询都应该做必要的缓存
register_msg_handler("getRecord", function(rpcid, msg)
  -- mongo 中 player_room_record 查找 room_db_id, 再到room_record中查找数据

  local time = skynet.time() - 24 * 60 * 60  --现在先查询一天的量，个数限制为10个
  local limit = 2

  local find_opt = {
    selector = {uin = msg.uin,  ts = {['$gt'] = time}, game_type = msg.gameType},
    sort = {ts = 1},
    limit = limit,
  }
  local set = mongox.find("player_room_record", find_opt)
 
  if not set or #set == 0 then
    send_message(rpcid, {records= {}})
    return    
  end

  local record_set = {}
  local item = {}
  local utils = require "utils"

  if msg.gameType then
    for _, s in ipairs(set) do
      item = mongox.findOne("room_record",  {_id = s.room_db_id})
      local name_map = {}
      for k, v in ipairs(item.room_result) do
        name_map[v.uin] = v.name
      end
      for k, v in ipairs(item.round_result) do
        local r = {}
        r.roomId = item.room_id
        r.roundId = k
        r.playerRecord = v.result
        r.date = v.ts
        r.gameType = item.game_type
        table.insert(record_set, r)
      end
    end
  end
  return send_message(rpcid, {records= record_set})
end)

return M
