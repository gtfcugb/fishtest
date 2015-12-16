#include<unistd.h>
#include<signal.h>
#include<fcntl.h>
#include<sys/param.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<stdio.h>
#include<stdlib.h>

#include<lua.h>
#include<lualib.h>
#include<lauxlib.h>

#define MAXFD 64

void dofile(char *config)
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    if (luaL_loadfile(L,"/home/gutf/chattest/cli.lua")||lua_pcall(L,0,0,0))
        return;
    lua_getglobal(L,"run");
    lua_pushstring(L,config);
    lua_pcall(L,1,0,0);
    int fp;
    fp = open("/home/gutf/erro",O_CREAT|O_RDWR|O_APPEND);
    write(fp,"\n",3);
    write(fp,lua_tostring(L,-1),256);
    close(fp);
    lua_close(L);

}
int
daemon_init(char *config)
{
    int i;
    pid_t pid;


    signal(SIGTTOU,SIG_IGN);
    signal(SIGTTIN,SIG_IGN);
    signal(SIGTSTP,SIG_IGN);
    signal(SIGHUP,SIG_IGN);

    if ((pid = fork()) < 0 )
        exit(1);
    else if (pid)
       exit(0);
    
    setsid();

    if ((pid = fork()) < 0)
        exit (1);
    else if (pid)
        exit(0);


    for(i=0;i<MAXFD;i++)
        close(i);

    open("/dev/null",O_RDONLY);
    open("/dev/null",O_RDWR);
    open("/dev/null",O_RDWR);

    chdir("/tmp");

    umask(0);

    signal(SIGCHLD,SIG_IGN);

    dofile(config);
    return (0);
}
int
main(int argc,char **argv)
{
    daemon_init(argv[1]);
}

