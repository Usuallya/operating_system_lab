#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

int main(int argc,char* argv[]){
    
    if(argc < 2){
        fprintf(2,"error:xargs must have 1 parameter at least!\n");
    }

    int pid = fork();
    if(pid < 0){
        fprintf(2,"error to fork");
        exit(1);
    }else if(pid == 0){
        //子进程
        char* newArgv[argc-1];
        for(int i = 1;i<argc;i++){
            newArgv[i-1] = argv[i];
        }
        exec(argv[1],newArgv);
        // printf("child processor:%d",getpid());
        //这里为什么加了exit就不会执行exec的内容，直接返回了？
        // exit(0);
    }else{
        wait((int *)0);
        // printf("child processor:%d has succeed",wait((int *)0));
    }
    exit(0);
}

