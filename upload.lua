-- 关闭非正常请求
--local ngx_var = ngx.var
local request_method = ngx.var.request_method
--local header = ngx_var.content_type

--ngx.log(ngx.ALERT,"header1: ",header)
--if not header then
--    return nil
--end
--
--if type(header) == "table" then
--    header = header[1]
--end
--ngx.log(ngx.ALERT,"header2: ",header)
if "GET" == request_method then
	ngx.exit(444)
end
if "OPTIONS" == request_method then
	return nil
end
-- 加载基础库(第三方)
local json = require "cjson"
local upload = require "resty.upload"
local uuid = require("resty.uuid")

local env = io.open("/data/wwwroot/.env",r)
local config = json.decode(env:read("*all"))
env:close()

local chunk_size = 4096  --如果不设置默认是4096.
local form = upload:new(chunk_size)
local file
local filename
local filelen=0
local retable = {}
local code=0

local file_url = config["UPLOAD_URL"]
-- 配置文件上传目录,lua 执行用户一定要有写权限, 固定目录:/year/month/day
local osfilepath = config["UPLOAD_PATH"] .. uri_data

local uri_data = os.date("%Y/%m/%d/")
form:set_timeout(100000)
--文件后缀名过虑，只允许指定文件后缀名文件上传
local suffix_filter = {
	jpg = 1,
	jpeg = 1,
	png = 1,
	gif = 1
}


-- 生成类随机md5文件名,利用系统自带的毫秒级时间戳md5值作文件名
-- local file_name_md5 = ngx.md5(ngx.now())
local file_name_uuid = uuid.generate()


--form:set_timeout(0) -- 1 sec



-- 检测存储目录是否存在
local f,err = io.open(osfilepath)
if not f then
	local ok,err = os.execute("mkdir -p \"" .. osfilepath .. "\"")
	if not ok then
		retable["code"] = 8999
		retable["msg"] = "Fail mkdir"
		ngx.say(json.encode(retable))
		return
	end
end

-- 返回md5文件名+后缀
function get_file_suffix(res)
    local suffix = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
    if suffix then
	    local st,err = suffix[2]:match(".+%.(%w+)$")
	    if st then
		    local s = string.lower(st)
		    if suffix_filter[s] then
			    return file_name_uuid .. "." .. s
		    else
			    retable["code"] = 9000
			    retable["msg"] = "File is unlawful!"
			    ngx.say(json.encode(retable))
			    ngx.exit(403)
		    end
	    end
    end
end

local i=0
while true do
    local typ, res, err = form:read()
    if not typ then
	retable["code"] = 9001
        retable["msg"] = "Failed to read file."
        ngx.say(json.encode(retable))
        --ngx.say("failed to read: ", err)
        return
    end
    if typ == "header" then
        if res[1] ~= "Content-Type" then
            filename = get_file_suffix(res[2])
            if filename then
                i=i+1
                filepath = osfilepath  .. filename
                file = io.open(filepath,"wb")

                if not file then
		    retable["code"] = 9002
        	    retable["msg"] = "Failed to open file."
        	    ngx.say(json.encode(retable))
                    return
                end
            else
            end
        end
    elseif typ == "body" then
        if file then
            filelen = filelen + tonumber(string.len(res))
            file:write(res)
        else
        end
    elseif typ == "part_end" then
        if file then
            file:close()
            file = nil
	    local d ={}
	    d["url"] = file_url .. uri_data .. filename
	    retable["code"] = 0
            --retable["data"] = file_url .. uri_data .. filename
            retable["data"] = d
	    retable["msg"] = "Upload Success!"
	    local a = json.encode(retable)
	    ngx.say(a)
        end
    elseif typ == "eof" then
        break
    else
    end
end
if i==0 then
    retable["code"] = 9003
    retable["data"] = "please upload at least one file!"
    ngx.say(json.encode(retable))
    return
end
