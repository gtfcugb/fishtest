my = io.open("shellrun","w")
for i=76,150 do
        table = {}
	run = "./run /home/gutf/chattest/backup/config"..i
        my:write(run.."\n")
        my:write("sleep 2\n")
end
my:close()
