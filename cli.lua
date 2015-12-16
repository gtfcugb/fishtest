local cjson = require "cjson.safe"
local socket = require "socket"

chat = {}

G_port = ""
G_host = ""

G_time         = {}
G_time.connect = 1
G_time.login   = 2
G_time.join    = 3
G_time.leave   = 10
G_time.quit    = 12
G_time.chat    = 3
G_time.bat     = 15
G_time.mkdir   = 1800
G_time.path    = 86400

G_t ={}
for i=1,10 do
	G_t[i] = os.time()
end

G_num = {}
G_num.connect  = 800
G_num.room     = 10000
G_num.perconnect = G_num.connect/40
G_num.login    = G_num.connect/40
G_num.join     = G_num.connect/40
G_num.leave    = G_num.connect/80
G_num.quit     = G_num.connect/80
G_num.socket   = 0

G_allsock 	   = {}
G_connectsock  = {}
G_loginsock	   = {}
G_joinsock 	   = {}
G_jointime     = {}
G_union        = {}
G_uid 		   = {}

math.randomseed(os.time())

function chat.message()
	j = math.random(100,1000)
	local mymessage =""
	for i=1,j do
		local mes = string.char(math.random(97,122))
		mymessage = mymessage..mes
	end
	return mymessage
end
function chat.log(logmessage)
	local message = {G_port,G_union[conn].nick,G_union[conn].uid,G_union[conn].index,G_union[conn].re,G_union[conn].recv,G_union[conn].recvnum}
	sn = G_uid.b
	log = "log"..sn
	path = "/home/gutf/log/"..log
	out = io.open(path,"a")
	for num,mylog in ipairs(logmessage) do
		if mylog ~= nil then
			out:write(mylog.."\n\n")
		end
	end
	for num,mylog in ipairs(message) do
		if mylog ~= nil then
			out:write(mylog.."\n\n")
		end
	end
	out:close(out)
end
function recvlogin(conn,value)
	if  value.error_code == 0 then
		G_uid[value.uid]    = nil
		G_connectsock[conn] = nil
		G_loginsock[conn]   = true
		G_union[conn].nick  = value.nick
		G_union[conn].index = value.indexId
	else
		G_uid[G_union[conn].uid] = G_union[conn].uid
		G_union[conn].uid        = nil
		G_connectsock[conn]      = true
	end
end

function recvjoin(conn,value)
	if value.error_code == 0 then
		G_loginsock[conn]     = nil
		G_joinsock[conn]      = true
		G_union[conn].roomid  = value.roomId
		G_jointime[conn]      = {}
		G_jointime[conn].time = os.time()
	else
		G_loginsock[conn]     = true
	end
end

function recvleave(conn,value)
	if  value.error_code == 0 then
		G_loginsock[conn] = true
		G_union[conn].rid = nil
		G_joinsock[conn]  = nil
		G_jointime[conn]  = nil
		G_union[conn].roomid = nil
		G_union[conn].rid = nil
	else
		G_union[conn].roomid = G_union[conn].rid
		G_union[conn].rid    = nil
		G_joinsock[conn]     = true
		G_jointime[conn]     = {}
		G_jointime[conn].time= os.time()  
	end
end

function recvclose(conn)
	if G_union[conn].uid ~= nil then
		G_uid[G_union[conn].uid] = G_union[conn].uid
	end
	for i =1, G_num.connect do
		if G_allsock[i] == conn then
			G_allsock[i] = nil
		end
	end
	G_union[conn]       = nil
	G_connectsock[conn] = nil
	G_loginsock[conn]   = nil
	G_joinsock[conn]    = nil
	G_jointime[conn]    = nil
	conn:close()
	G_num.socket = G_num.socket -1
end

function recvdo(conn,rec)
--print(rec.."\n")
	local x,y,z,w =string.match(rec,"^%*-(%a-)%*+(%a+)%*+(%d+).-%\n(.-)$")
	if w ~= nil then
		local lua_value,erro = cjson.decode(w)
		if erro ~= nil then
			local log = {os.date().."recv cjson wrong",erro,rec}
			chat.log(log)
		else	
			if y == "login" then
				recvlogin(conn,lua_value)
			elseif y == "join" then
				recvjoin(conn,lua_value)
			elseif y == "joinN" then
			elseif y == "chat" then
			elseif y == "chatN" then
			elseif y == "leave" then
				recvleave(conn,lua_value)
			elseif y == "leaveN" then
			else
				local log = {os.date().."recv head wrong",rec}
				chat.log(log)
			end
		end
	else
		local log = {os.date().."recv cjson is nil",rec}
		chat.log(log)
	end
end

function chat.recv()
	local recev,status = socket.select(G_allsock,nil,0)
	if recev~= nil and #recev>0 then
		for s,conn in ipairs(recev) do
			local recv,recv_statues = conn:receive("*l")
			if recv~= nil and #recv > 0 then
				recv = recv .."\n"
				bodylen = tonumber(string.match(recv,"%*+(%d+).-%\n"))
				G_union.le = bodylen
				if bodylen == nil then
					local log = {os.date().."recv bodylen is nil",recv}
					chat.log(log)
				else
					if bodylen > 0 then
						local rec,recv_statue = conn:receive(bodylen)
						if rec~= nil  then
							recv = recv ..rec
							G_union[conn].re   = G_union[conn].recv 
							G_union[conn].recv = recv
							G_union[conn].recvnum = G_union[conn].recvnum + 1
							recvdo(conn,recv)
						elseif recv_statue == "closed" then
							recvclose(conn)
						else
							local log = {os.date().."recv body wrong",recv,recv_statue}
							chat.log(log)
							recvclose(conn)
						end
					else
						G_union[conn].re   = G_union[conn].recv 
						G_union[conn].recv = recv
						G_union[conn].recvnum = G_union[conn].recvnum + 1
						recvdo(conn,recv)
					end
				end
			elseif recv_statues == "closed" then
				recvclose(conn)
			else
				local log = {os.date().."recv head wrong",recv,recv_statues}
				chat.log(log)
				recvclose(conn)
			end
		end
	end
end

function chat.send(conn,str)
--print(str.."\n")
	while str ~= nil and #str ~= 0  do
		local sdnum , sendstatues = conn:send(str)
		if sdnum == nil then
			if G_union[conn].uid ~= nil then
				G_uid[G_union[conn].uid] = G_union[conn].uid
			end
			for i =1,G_num.connect do
				if G_allsock[i] == conn then
					G_allsock[i] = nil
				end
			end
			G_union[conn]       = nil
			G_connectsock[conn] = nil
			G_loginsock[conn]   = nil
			G_joinsock[conn]    = nil
			G_jointime[conn]    = nil
			conn:close()
			G_num.socket = G_num.socket -1
			return "closed" 
		elseif sdnum == #str then
			break
		else
			sdnum = sdnum +1
			str = string.sub(str,sdnum,#str)
		end
	end
end

function chat.myconnect()
	if G_num.socket < G_num.connect then
		local sock=socket.connect(G_host,G_port)
		if sock ~= nil then
			G_num.socket = G_num.socket +1
			return sock
		else
			return nil
		end
	else
		return nil
	end
end
function chat.connect()
	if os.time() - G_t[1] > G_time.connect then
		for j =1 ,G_num.perconnect do
			local sock = chat.myconnect()
			if sock ~= nil then
				for i =1,G_num.connect do
					if G_allsock[i] == nil then
						G_allsock[i] = sock
						G_connectsock[sock] = true
						G_union[sock] = {}
						G_union[sock].recvnum = 0
						break
					end
				end
			end
		end
		G_t[1] = os.time()
	end
end

function chat.mylogin(conn,uid)
	local table = {}
	table.nick  = "felix" ..uid
	table.uid   =  uid
	local lua_text = cjson.encode(table)
	local len = string.len(lua_text)
	local num = math.random(1,1024)
	local str = "account*login*"..num.."*" ..len .."\n" ..lua_text
	local stues = chat.send(conn,str)
	return stues
end
function chat.login()
	if os.time() - G_t[2] > G_time.login then
		local times = 0
		for v,s in pairs(G_connectsock) do
			if times == G_num.login then
				break
			elseif s == true then
				for i= G_uid.b,G_uid.t do
					if G_uid[i] == i then
						uid = G_uid[i]
						local stues = chat.mylogin(v,uid)
						if stues ~= "closed" then
							G_uid[i] = "login"
							G_connectsock[v] = "login"
							G_union[v].uid = uid
						end
						times = times +1
						break
					end
				end
			end
		end
		G_t[2] = os.time()
	end
end

function chat.myjoin(conn,roomid)
	local table = {}
	table.roomId = tonumber(roomid)
	local lua_text = cjson.encode(table)
	local len = string.len(lua_text)
	local str = "room*join*"
	str = str .. table.roomId .. "*" .. len .."\n" .. lua_text
	local stues =chat.send(conn,str)
	return stues
end
function chat.join()
	if os.time() - G_t[3] > G_time.join then
		local times = 0
		for v,s in pairs(G_loginsock) do
			if times == G_num.join then
				break
			elseif s == true then
					local roomid = math.random(1,G_num.room)
					local stues = chat.myjoin(v,roomid)
					if stues ~= "closed" then
						G_loginsock[v]     = "join"
					end
					times = times +1
			end
		end
		G_t[3] = os.time()
	end
end

function chat.myleave(conn,roomid)
	local table = {}
	table.roomId = roomid
	local lua_text = cjson.encode(table)
	local len = string.len(lua_text)
	local str = "room*leave*"
	str = str .. table.roomId .. "*" .. len .."\n" .. lua_text
	local stues = chat.send(conn,str)
	return stues
end
function chat.leave()
	if os.time() - G_t[4] > G_time.leave then
			for i = 1, G_num.leave do
				if #G_allsock > 0 then
					while true do
			 			num = math.random(1,#G_allsock)
						if G_allsock[num] ~=nil then
							break
						end
					end
					if G_allsock[num] ~= nil then
						if G_joinsock[G_allsock[num]] ~=nil then
							if G_union[G_allsock[num]].roomid ~= nil and G_joinsock[G_allsock[num]] ~= "leave" then
								local stues =chat.myleave(G_allsock[num],G_union[G_allsock[num]].roomid)
								if stues ~= "closed" then
									G_joinsock[G_allsock[num]] = "leave"
									G_union[G_allsock[num]].rid = G_union[G_allsock[num]].roomid
									G_union[G_allsock[num]].roomid   = "leave"
								end
							end
						end
					end
				else
					break
				end
			end
		G_t[4] = os.time()
	end
end

function chat.myquit(conn)
	if G_union[conn].uid ~= nil then
		G_uid[G_union[conn].uid] = G_union[conn].uid
	end
	for i =1,G_num.connect do
		if G_allsock[i] == conn then
			G_allsock[i] = nil
		end
	end
	G_union[conn]       = nil
	G_connectsock[conn] = nil
	G_loginsock[conn]   = nil
	G_joinsock[conn]    = nil
	G_jointime[conn]    = nil
	conn:close()
	G_num.socket = G_num.socket -1
end
function chat.quit()
	if os.time() - G_t[5] > G_time.quit then
			for i = 1,G_num.quit do
				if #G_allsock >  0 then
					while true do
			 			num = math.random(1,#G_allsock)
						if G_allsock[num] ~=nil then
							break
						end
					end
					chat.myquit(G_allsock[num])
				else
					break
				end
			end
		G_t[5] = os.time()
	end
end

function chat.mychat(conn,roomid)
	local table = {}
	table.msg = chat.message()
	table.roomId = roomid
	local lua_text = cjson.encode(table)
	local len =  string.len(lua_text)
	local str = "room*chat*"
	str = str .. roomid .."*" .. len .. "\n" .. lua_text
	chat.send(conn,str)
end
function chat.chat()
	if os.time() - G_t[6] > G_time.chat then
		for v,s in pairs(G_joinsock) do
			if s== true then
				if os.time() - G_jointime[v].time > math.random(15,30) then
					G_jointime[v].time = os.time()
if G_union[v].roomid == nil then
else
						chat.mychat(v,G_union[v].roomid)
					end
				end
			end
		end
		G_t[6] = os.time()
	end
end

function chat.bat()
	if os.time() - G_t[7] > G_time.bat then
		for v,s in pairs(G_allsock) do
			if s ~= nil then
				local sys = "system*beat*0*0\n"
				chat.send(s,sys)
			end
		end
		G_t[7] = os.time()
	end
end

function init(config)
	local myin = io.open(config,"r")
	local value = cjson.decode(myin:read("*all"))
	G_uid.b = tonumber(value.uidbottom)
	G_uid.t = tonumber(value.uidtop)
	for i = G_uid.b,G_uid.t do
		G_uid[i] = i
	end
	G_host = tostring(value.host)
	--G_port= tonumber(value.port)
	G_port=6000
end

function run(config)
--	config = tostring(io.read())
	init(config)
	while true do
		chat.connect() chat.recv() chat.chat() chat.bat()
		chat.login() chat.recv() chat.chat() chat.bat()
		chat.join() chat.recv() chat.chat() chat.bat()
		chat.leave() chat.recv() chat.chat() chat.bat()
		chat.quit() chat.recv() chat.chat() chat.bat()
		socket.select(nil,nil,0.1)
	end
end
--run(config)
