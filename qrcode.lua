local json = require("cjson")
local uuid = require("resty.uuid")
local qr = require("qrencode")
local args = ngx.req.get_uri_args()

local uri_date = os.date("%Y/%m/%d/")
local osfilepath = "/tmp/files/qrcode/" .. uri_date
local file_name = uuid.generate() .. ".png"
local file_url = "http://localhost/files/qrcode/" .. uri_date .. file_name
local file_real_path = osfilepath .. file_name
-- apikeys
local apiKeys = {
	-- lcb api 1;
	9iRE0L3294l9DBREQveNBIc = 1,
        -- lcb api 2;
    j62h69HrFi1ar6iEc3QI3aM = 1
    }
-- 检测存储目录是否存在
local f,err = io.open(osfilepath)
if not f then
        local ok,err = os.execute("mkdir -p \"" .. osfilepath .. "\"")
        if not ok then
                local t = {}
                t["code"] = 8999
                t["msg"] = "Fail mkdir"
                ngx.say(json.encode(t))
                return
        end
end

ngx.req.read_body()
local postArgs = ngx.req.get_post_args()
local qrdata = postArgs["qrdata"]
local apikey = postArgs["apikey"]

if qrdata == nil or qrdata == "" or apikey == nil or apikey == "" or apiKeys[apikey] == nil then
    local t = {}
    t["code"] = 403
    t["msg"] = "param lost"
    ngx.say(json.encode(t))
    return
end

local q_code_file = qr {
        text=qrdata,
        level="L",
        kanji=false,
        size=16,
        margin=2,
        symversion=0,
        dpi=78,
        casesensitive=true,
     }

local file = io.open(file_real_path, "wb")
file:write(q_code_file)
file:close()

local t = {}
t["code"] = 0
t["url"] = file_url
ngx.say(json.encode(t))
return
