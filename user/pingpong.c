#include "kernel/types.h"
#include "user/user.h"

int main(int argc,char const *argv[]){
    //首先调用Pipe创建两个管道
    //p1是父写子读的管道
    int p1[2];
    //p2是子写父读的管道
    int p2[2];
    pipe(p1);
    pipe(p2);
    char buffer[1];
    int childPid = fork();
    if(childPid < 0){
        fprintf(2,"error to fork processor");
        close(p1[0]);
        close(p1[1]);
        close(p2[0]);
        close(p2[1]);
    }else if(childPid > 0){
        //父进程
        close(p1[0]);
        write(p1[1],"a",1);
        close(p1[1]);
        //关闭管道2的写端
        close(p2[1]);
        if(read(p2[0],buffer,1) > 0){
            fprintf(1,"%d:received pong\n",getpid());
        }
        close(p2[0]);
    }else{
        //子进程，首先关闭管道1的写端，并从读端读取
        close(p1[1]);
        if(read(p1[0],buffer,1) > 0){
            fprintf(1,"%d:received ping\n",getpid());
        }
        //关闭读端
        close(p1[0]);

        //关闭管道2的读端
        close(p2[0]);
        //在管道2的写端写入
        write(p2[1],"a",1);
        close(p2[1]);
    }
    exit(0);
}