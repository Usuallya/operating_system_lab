
user/_primes:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <lpipe_first_data>:
 * @param lpipe 左邻居的管道符
 * @param pfirst 用于存储第一个数据的地址
 * @return 如果没有数据返回-1,有数据返回0
 */
int lpipe_first_data(int lpipe[2], int *dst)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
   a:	84ae                	mv	s1,a1
  if (read(lpipe[RD], dst, sizeof(int)) == sizeof(int)) {
   c:	4611                	li	a2,4
   e:	4108                	lw	a0,0(a0)
  10:	00000097          	auipc	ra,0x0
  14:	42c080e7          	jalr	1068(ra) # 43c <read>
  18:	4791                	li	a5,4
  1a:	02f51163          	bne	a0,a5,3c <lpipe_first_data+0x3c>
    printf("prime %d\n", *dst);
  1e:	408c                	lw	a1,0(s1)
  20:	00001517          	auipc	a0,0x1
  24:	92050513          	addi	a0,a0,-1760 # 940 <malloc+0xe6>
  28:	00000097          	auipc	ra,0x0
  2c:	774080e7          	jalr	1908(ra) # 79c <printf>
    return 0;
  30:	4501                	li	a0,0
  }
  return -1;
}
  32:	60e2                	ld	ra,24(sp)
  34:	6442                	ld	s0,16(sp)
  36:	64a2                	ld	s1,8(sp)
  38:	6105                	addi	sp,sp,32
  3a:	8082                	ret
  return -1;
  3c:	557d                	li	a0,-1
  3e:	bfd5                	j	32 <lpipe_first_data+0x32>

0000000000000040 <transmit_data>:
 * @param lpipe 左邻居的管道符
 * @param rpipe 右邻居的管道符
 * @param first 左邻居的第一个数据
 */
void transmit_data(int lpipe[2], int rpipe[2], int first)
{
  40:	7139                	addi	sp,sp,-64
  42:	fc06                	sd	ra,56(sp)
  44:	f822                	sd	s0,48(sp)
  46:	f426                	sd	s1,40(sp)
  48:	f04a                	sd	s2,32(sp)
  4a:	ec4e                	sd	s3,24(sp)
  4c:	0080                	addi	s0,sp,64
  4e:	84aa                	mv	s1,a0
  50:	89ae                	mv	s3,a1
  52:	8932                	mv	s2,a2
  int data;
  // 从左管道读取数据
  while (read(lpipe[RD], &data, sizeof(int)) == sizeof(int)) {
  54:	4611                	li	a2,4
  56:	fcc40593          	addi	a1,s0,-52
  5a:	4088                	lw	a0,0(s1)
  5c:	00000097          	auipc	ra,0x0
  60:	3e0080e7          	jalr	992(ra) # 43c <read>
  64:	4791                	li	a5,4
  66:	02f51163          	bne	a0,a5,88 <transmit_data+0x48>
    // 将无法整除的数据传递入右管道
    if (data % first)
  6a:	fcc42783          	lw	a5,-52(s0)
  6e:	0327e7bb          	remw	a5,a5,s2
  72:	d3ed                	beqz	a5,54 <transmit_data+0x14>
      write(rpipe[WR], &data, sizeof(int));
  74:	4611                	li	a2,4
  76:	fcc40593          	addi	a1,s0,-52
  7a:	0049a503          	lw	a0,4(s3)
  7e:	00000097          	auipc	ra,0x0
  82:	3c6080e7          	jalr	966(ra) # 444 <write>
  86:	b7f9                	j	54 <transmit_data+0x14>
  }
  close(lpipe[RD]);
  88:	4088                	lw	a0,0(s1)
  8a:	00000097          	auipc	ra,0x0
  8e:	3c2080e7          	jalr	962(ra) # 44c <close>
  close(rpipe[WR]);
  92:	0049a503          	lw	a0,4(s3)
  96:	00000097          	auipc	ra,0x0
  9a:	3b6080e7          	jalr	950(ra) # 44c <close>
}
  9e:	70e2                	ld	ra,56(sp)
  a0:	7442                	ld	s0,48(sp)
  a2:	74a2                	ld	s1,40(sp)
  a4:	7902                	ld	s2,32(sp)
  a6:	69e2                	ld	s3,24(sp)
  a8:	6121                	addi	sp,sp,64
  aa:	8082                	ret

00000000000000ac <primes>:
/**
 * @brief 寻找素数
 * @param lpipe 左邻居管道
 */
void primes(int lpipe[2])
{
  ac:	7179                	addi	sp,sp,-48
  ae:	f406                	sd	ra,40(sp)
  b0:	f022                	sd	s0,32(sp)
  b2:	ec26                	sd	s1,24(sp)
  b4:	1800                	addi	s0,sp,48
  b6:	84aa                	mv	s1,a0
  close(lpipe[WR]);
  b8:	4148                	lw	a0,4(a0)
  ba:	00000097          	auipc	ra,0x0
  be:	392080e7          	jalr	914(ra) # 44c <close>
  int first;
  if (lpipe_first_data(lpipe, &first) == 0) {
  c2:	fdc40593          	addi	a1,s0,-36
  c6:	8526                	mv	a0,s1
  c8:	00000097          	auipc	ra,0x0
  cc:	f38080e7          	jalr	-200(ra) # 0 <lpipe_first_data>
  d0:	c511                	beqz	a0,dc <primes+0x30>
    } else {
      close(p[RD]);
      wait(0);
    }
  }
  exit(0);
  d2:	4501                	li	a0,0
  d4:	00000097          	auipc	ra,0x0
  d8:	350080e7          	jalr	848(ra) # 424 <exit>
    pipe(p); // 当前的管道
  dc:	fd040513          	addi	a0,s0,-48
  e0:	00000097          	auipc	ra,0x0
  e4:	354080e7          	jalr	852(ra) # 434 <pipe>
    transmit_data(lpipe, p, first);
  e8:	fdc42603          	lw	a2,-36(s0)
  ec:	fd040593          	addi	a1,s0,-48
  f0:	8526                	mv	a0,s1
  f2:	00000097          	auipc	ra,0x0
  f6:	f4e080e7          	jalr	-178(ra) # 40 <transmit_data>
    if (fork() == 0) {
  fa:	00000097          	auipc	ra,0x0
  fe:	322080e7          	jalr	802(ra) # 41c <fork>
 102:	e519                	bnez	a0,110 <primes+0x64>
      primes(p);    // 递归的思想，但这将在一个新的进程中调用
 104:	fd040513          	addi	a0,s0,-48
 108:	00000097          	auipc	ra,0x0
 10c:	fa4080e7          	jalr	-92(ra) # ac <primes>
      close(p[RD]);
 110:	fd042503          	lw	a0,-48(s0)
 114:	00000097          	auipc	ra,0x0
 118:	338080e7          	jalr	824(ra) # 44c <close>
      wait(0);
 11c:	4501                	li	a0,0
 11e:	00000097          	auipc	ra,0x0
 122:	30e080e7          	jalr	782(ra) # 42c <wait>
 126:	b775                	j	d2 <primes+0x26>

0000000000000128 <main>:
}

int main(int argc, char const *argv[])
{
 128:	7179                	addi	sp,sp,-48
 12a:	f406                	sd	ra,40(sp)
 12c:	f022                	sd	s0,32(sp)
 12e:	ec26                	sd	s1,24(sp)
 130:	1800                	addi	s0,sp,48
  int p[2];
  pipe(p);
 132:	fd840513          	addi	a0,s0,-40
 136:	00000097          	auipc	ra,0x0
 13a:	2fe080e7          	jalr	766(ra) # 434 <pipe>

  for (int i = 2; i <= 35; ++i) //写入初始数据
 13e:	4789                	li	a5,2
 140:	fcf42a23          	sw	a5,-44(s0)
 144:	02300493          	li	s1,35
    write(p[WR], &i, INT_LEN);
 148:	4611                	li	a2,4
 14a:	fd440593          	addi	a1,s0,-44
 14e:	fdc42503          	lw	a0,-36(s0)
 152:	00000097          	auipc	ra,0x0
 156:	2f2080e7          	jalr	754(ra) # 444 <write>
  for (int i = 2; i <= 35; ++i) //写入初始数据
 15a:	fd442783          	lw	a5,-44(s0)
 15e:	2785                	addiw	a5,a5,1
 160:	0007871b          	sext.w	a4,a5
 164:	fcf42a23          	sw	a5,-44(s0)
 168:	fee4d0e3          	bge	s1,a4,148 <main+0x20>

  if (fork() == 0) {
 16c:	00000097          	auipc	ra,0x0
 170:	2b0080e7          	jalr	688(ra) # 41c <fork>
 174:	e519                	bnez	a0,182 <main+0x5a>
    primes(p);
 176:	fd840513          	addi	a0,s0,-40
 17a:	00000097          	auipc	ra,0x0
 17e:	f32080e7          	jalr	-206(ra) # ac <primes>
  } else {
    close(p[WR]);
 182:	fdc42503          	lw	a0,-36(s0)
 186:	00000097          	auipc	ra,0x0
 18a:	2c6080e7          	jalr	710(ra) # 44c <close>
    close(p[RD]);
 18e:	fd842503          	lw	a0,-40(s0)
 192:	00000097          	auipc	ra,0x0
 196:	2ba080e7          	jalr	698(ra) # 44c <close>
    wait(0);
 19a:	4501                	li	a0,0
 19c:	00000097          	auipc	ra,0x0
 1a0:	290080e7          	jalr	656(ra) # 42c <wait>
  }

  exit(0);
 1a4:	4501                	li	a0,0
 1a6:	00000097          	auipc	ra,0x0
 1aa:	27e080e7          	jalr	638(ra) # 424 <exit>

00000000000001ae <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1ae:	1141                	addi	sp,sp,-16
 1b0:	e422                	sd	s0,8(sp)
 1b2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1b4:	87aa                	mv	a5,a0
 1b6:	0585                	addi	a1,a1,1
 1b8:	0785                	addi	a5,a5,1
 1ba:	fff5c703          	lbu	a4,-1(a1)
 1be:	fee78fa3          	sb	a4,-1(a5)
 1c2:	fb75                	bnez	a4,1b6 <strcpy+0x8>
    ;
  return os;
}
 1c4:	6422                	ld	s0,8(sp)
 1c6:	0141                	addi	sp,sp,16
 1c8:	8082                	ret

00000000000001ca <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1ca:	1141                	addi	sp,sp,-16
 1cc:	e422                	sd	s0,8(sp)
 1ce:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1d0:	00054783          	lbu	a5,0(a0)
 1d4:	cb91                	beqz	a5,1e8 <strcmp+0x1e>
 1d6:	0005c703          	lbu	a4,0(a1)
 1da:	00f71763          	bne	a4,a5,1e8 <strcmp+0x1e>
    p++, q++;
 1de:	0505                	addi	a0,a0,1
 1e0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1e2:	00054783          	lbu	a5,0(a0)
 1e6:	fbe5                	bnez	a5,1d6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1e8:	0005c503          	lbu	a0,0(a1)
}
 1ec:	40a7853b          	subw	a0,a5,a0
 1f0:	6422                	ld	s0,8(sp)
 1f2:	0141                	addi	sp,sp,16
 1f4:	8082                	ret

00000000000001f6 <strlen>:

uint
strlen(const char *s)
{
 1f6:	1141                	addi	sp,sp,-16
 1f8:	e422                	sd	s0,8(sp)
 1fa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1fc:	00054783          	lbu	a5,0(a0)
 200:	cf91                	beqz	a5,21c <strlen+0x26>
 202:	0505                	addi	a0,a0,1
 204:	87aa                	mv	a5,a0
 206:	4685                	li	a3,1
 208:	9e89                	subw	a3,a3,a0
 20a:	00f6853b          	addw	a0,a3,a5
 20e:	0785                	addi	a5,a5,1
 210:	fff7c703          	lbu	a4,-1(a5)
 214:	fb7d                	bnez	a4,20a <strlen+0x14>
    ;
  return n;
}
 216:	6422                	ld	s0,8(sp)
 218:	0141                	addi	sp,sp,16
 21a:	8082                	ret
  for(n = 0; s[n]; n++)
 21c:	4501                	li	a0,0
 21e:	bfe5                	j	216 <strlen+0x20>

0000000000000220 <memset>:

void*
memset(void *dst, int c, uint n)
{
 220:	1141                	addi	sp,sp,-16
 222:	e422                	sd	s0,8(sp)
 224:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 226:	ce09                	beqz	a2,240 <memset+0x20>
 228:	87aa                	mv	a5,a0
 22a:	fff6071b          	addiw	a4,a2,-1
 22e:	1702                	slli	a4,a4,0x20
 230:	9301                	srli	a4,a4,0x20
 232:	0705                	addi	a4,a4,1
 234:	972a                	add	a4,a4,a0
    cdst[i] = c;
 236:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 23a:	0785                	addi	a5,a5,1
 23c:	fee79de3          	bne	a5,a4,236 <memset+0x16>
  }
  return dst;
}
 240:	6422                	ld	s0,8(sp)
 242:	0141                	addi	sp,sp,16
 244:	8082                	ret

0000000000000246 <strchr>:

char*
strchr(const char *s, char c)
{
 246:	1141                	addi	sp,sp,-16
 248:	e422                	sd	s0,8(sp)
 24a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 24c:	00054783          	lbu	a5,0(a0)
 250:	cb99                	beqz	a5,266 <strchr+0x20>
    if(*s == c)
 252:	00f58763          	beq	a1,a5,260 <strchr+0x1a>
  for(; *s; s++)
 256:	0505                	addi	a0,a0,1
 258:	00054783          	lbu	a5,0(a0)
 25c:	fbfd                	bnez	a5,252 <strchr+0xc>
      return (char*)s;
  return 0;
 25e:	4501                	li	a0,0
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret
  return 0;
 266:	4501                	li	a0,0
 268:	bfe5                	j	260 <strchr+0x1a>

000000000000026a <gets>:

char*
gets(char *buf, int max)
{
 26a:	711d                	addi	sp,sp,-96
 26c:	ec86                	sd	ra,88(sp)
 26e:	e8a2                	sd	s0,80(sp)
 270:	e4a6                	sd	s1,72(sp)
 272:	e0ca                	sd	s2,64(sp)
 274:	fc4e                	sd	s3,56(sp)
 276:	f852                	sd	s4,48(sp)
 278:	f456                	sd	s5,40(sp)
 27a:	f05a                	sd	s6,32(sp)
 27c:	ec5e                	sd	s7,24(sp)
 27e:	1080                	addi	s0,sp,96
 280:	8baa                	mv	s7,a0
 282:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 284:	892a                	mv	s2,a0
 286:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 288:	4aa9                	li	s5,10
 28a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 28c:	89a6                	mv	s3,s1
 28e:	2485                	addiw	s1,s1,1
 290:	0344d863          	bge	s1,s4,2c0 <gets+0x56>
    cc = read(0, &c, 1);
 294:	4605                	li	a2,1
 296:	faf40593          	addi	a1,s0,-81
 29a:	4501                	li	a0,0
 29c:	00000097          	auipc	ra,0x0
 2a0:	1a0080e7          	jalr	416(ra) # 43c <read>
    if(cc < 1)
 2a4:	00a05e63          	blez	a0,2c0 <gets+0x56>
    buf[i++] = c;
 2a8:	faf44783          	lbu	a5,-81(s0)
 2ac:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2b0:	01578763          	beq	a5,s5,2be <gets+0x54>
 2b4:	0905                	addi	s2,s2,1
 2b6:	fd679be3          	bne	a5,s6,28c <gets+0x22>
  for(i=0; i+1 < max; ){
 2ba:	89a6                	mv	s3,s1
 2bc:	a011                	j	2c0 <gets+0x56>
 2be:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2c0:	99de                	add	s3,s3,s7
 2c2:	00098023          	sb	zero,0(s3)
  return buf;
}
 2c6:	855e                	mv	a0,s7
 2c8:	60e6                	ld	ra,88(sp)
 2ca:	6446                	ld	s0,80(sp)
 2cc:	64a6                	ld	s1,72(sp)
 2ce:	6906                	ld	s2,64(sp)
 2d0:	79e2                	ld	s3,56(sp)
 2d2:	7a42                	ld	s4,48(sp)
 2d4:	7aa2                	ld	s5,40(sp)
 2d6:	7b02                	ld	s6,32(sp)
 2d8:	6be2                	ld	s7,24(sp)
 2da:	6125                	addi	sp,sp,96
 2dc:	8082                	ret

00000000000002de <stat>:

int
stat(const char *n, struct stat *st)
{
 2de:	1101                	addi	sp,sp,-32
 2e0:	ec06                	sd	ra,24(sp)
 2e2:	e822                	sd	s0,16(sp)
 2e4:	e426                	sd	s1,8(sp)
 2e6:	e04a                	sd	s2,0(sp)
 2e8:	1000                	addi	s0,sp,32
 2ea:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2ec:	4581                	li	a1,0
 2ee:	00000097          	auipc	ra,0x0
 2f2:	176080e7          	jalr	374(ra) # 464 <open>
  if(fd < 0)
 2f6:	02054563          	bltz	a0,320 <stat+0x42>
 2fa:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2fc:	85ca                	mv	a1,s2
 2fe:	00000097          	auipc	ra,0x0
 302:	17e080e7          	jalr	382(ra) # 47c <fstat>
 306:	892a                	mv	s2,a0
  close(fd);
 308:	8526                	mv	a0,s1
 30a:	00000097          	auipc	ra,0x0
 30e:	142080e7          	jalr	322(ra) # 44c <close>
  return r;
}
 312:	854a                	mv	a0,s2
 314:	60e2                	ld	ra,24(sp)
 316:	6442                	ld	s0,16(sp)
 318:	64a2                	ld	s1,8(sp)
 31a:	6902                	ld	s2,0(sp)
 31c:	6105                	addi	sp,sp,32
 31e:	8082                	ret
    return -1;
 320:	597d                	li	s2,-1
 322:	bfc5                	j	312 <stat+0x34>

0000000000000324 <atoi>:

int
atoi(const char *s)
{
 324:	1141                	addi	sp,sp,-16
 326:	e422                	sd	s0,8(sp)
 328:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 32a:	00054603          	lbu	a2,0(a0)
 32e:	fd06079b          	addiw	a5,a2,-48
 332:	0ff7f793          	andi	a5,a5,255
 336:	4725                	li	a4,9
 338:	02f76963          	bltu	a4,a5,36a <atoi+0x46>
 33c:	86aa                	mv	a3,a0
  n = 0;
 33e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 340:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 342:	0685                	addi	a3,a3,1
 344:	0025179b          	slliw	a5,a0,0x2
 348:	9fa9                	addw	a5,a5,a0
 34a:	0017979b          	slliw	a5,a5,0x1
 34e:	9fb1                	addw	a5,a5,a2
 350:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 354:	0006c603          	lbu	a2,0(a3)
 358:	fd06071b          	addiw	a4,a2,-48
 35c:	0ff77713          	andi	a4,a4,255
 360:	fee5f1e3          	bgeu	a1,a4,342 <atoi+0x1e>
  return n;
}
 364:	6422                	ld	s0,8(sp)
 366:	0141                	addi	sp,sp,16
 368:	8082                	ret
  n = 0;
 36a:	4501                	li	a0,0
 36c:	bfe5                	j	364 <atoi+0x40>

000000000000036e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 36e:	1141                	addi	sp,sp,-16
 370:	e422                	sd	s0,8(sp)
 372:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 374:	02b57663          	bgeu	a0,a1,3a0 <memmove+0x32>
    while(n-- > 0)
 378:	02c05163          	blez	a2,39a <memmove+0x2c>
 37c:	fff6079b          	addiw	a5,a2,-1
 380:	1782                	slli	a5,a5,0x20
 382:	9381                	srli	a5,a5,0x20
 384:	0785                	addi	a5,a5,1
 386:	97aa                	add	a5,a5,a0
  dst = vdst;
 388:	872a                	mv	a4,a0
      *dst++ = *src++;
 38a:	0585                	addi	a1,a1,1
 38c:	0705                	addi	a4,a4,1
 38e:	fff5c683          	lbu	a3,-1(a1)
 392:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 396:	fee79ae3          	bne	a5,a4,38a <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 39a:	6422                	ld	s0,8(sp)
 39c:	0141                	addi	sp,sp,16
 39e:	8082                	ret
    dst += n;
 3a0:	00c50733          	add	a4,a0,a2
    src += n;
 3a4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3a6:	fec05ae3          	blez	a2,39a <memmove+0x2c>
 3aa:	fff6079b          	addiw	a5,a2,-1
 3ae:	1782                	slli	a5,a5,0x20
 3b0:	9381                	srli	a5,a5,0x20
 3b2:	fff7c793          	not	a5,a5
 3b6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3b8:	15fd                	addi	a1,a1,-1
 3ba:	177d                	addi	a4,a4,-1
 3bc:	0005c683          	lbu	a3,0(a1)
 3c0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3c4:	fee79ae3          	bne	a5,a4,3b8 <memmove+0x4a>
 3c8:	bfc9                	j	39a <memmove+0x2c>

00000000000003ca <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3ca:	1141                	addi	sp,sp,-16
 3cc:	e422                	sd	s0,8(sp)
 3ce:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3d0:	ca05                	beqz	a2,400 <memcmp+0x36>
 3d2:	fff6069b          	addiw	a3,a2,-1
 3d6:	1682                	slli	a3,a3,0x20
 3d8:	9281                	srli	a3,a3,0x20
 3da:	0685                	addi	a3,a3,1
 3dc:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3de:	00054783          	lbu	a5,0(a0)
 3e2:	0005c703          	lbu	a4,0(a1)
 3e6:	00e79863          	bne	a5,a4,3f6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ea:	0505                	addi	a0,a0,1
    p2++;
 3ec:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3ee:	fed518e3          	bne	a0,a3,3de <memcmp+0x14>
  }
  return 0;
 3f2:	4501                	li	a0,0
 3f4:	a019                	j	3fa <memcmp+0x30>
      return *p1 - *p2;
 3f6:	40e7853b          	subw	a0,a5,a4
}
 3fa:	6422                	ld	s0,8(sp)
 3fc:	0141                	addi	sp,sp,16
 3fe:	8082                	ret
  return 0;
 400:	4501                	li	a0,0
 402:	bfe5                	j	3fa <memcmp+0x30>

0000000000000404 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 404:	1141                	addi	sp,sp,-16
 406:	e406                	sd	ra,8(sp)
 408:	e022                	sd	s0,0(sp)
 40a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 40c:	00000097          	auipc	ra,0x0
 410:	f62080e7          	jalr	-158(ra) # 36e <memmove>
}
 414:	60a2                	ld	ra,8(sp)
 416:	6402                	ld	s0,0(sp)
 418:	0141                	addi	sp,sp,16
 41a:	8082                	ret

000000000000041c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 41c:	4885                	li	a7,1
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <exit>:
.global exit
exit:
 li a7, SYS_exit
 424:	4889                	li	a7,2
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <wait>:
.global wait
wait:
 li a7, SYS_wait
 42c:	488d                	li	a7,3
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 434:	4891                	li	a7,4
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <read>:
.global read
read:
 li a7, SYS_read
 43c:	4895                	li	a7,5
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <write>:
.global write
write:
 li a7, SYS_write
 444:	48c1                	li	a7,16
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <close>:
.global close
close:
 li a7, SYS_close
 44c:	48d5                	li	a7,21
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <kill>:
.global kill
kill:
 li a7, SYS_kill
 454:	4899                	li	a7,6
 ecall
 456:	00000073          	ecall
 ret
 45a:	8082                	ret

000000000000045c <exec>:
.global exec
exec:
 li a7, SYS_exec
 45c:	489d                	li	a7,7
 ecall
 45e:	00000073          	ecall
 ret
 462:	8082                	ret

0000000000000464 <open>:
.global open
open:
 li a7, SYS_open
 464:	48bd                	li	a7,15
 ecall
 466:	00000073          	ecall
 ret
 46a:	8082                	ret

000000000000046c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 46c:	48c5                	li	a7,17
 ecall
 46e:	00000073          	ecall
 ret
 472:	8082                	ret

0000000000000474 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 474:	48c9                	li	a7,18
 ecall
 476:	00000073          	ecall
 ret
 47a:	8082                	ret

000000000000047c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 47c:	48a1                	li	a7,8
 ecall
 47e:	00000073          	ecall
 ret
 482:	8082                	ret

0000000000000484 <link>:
.global link
link:
 li a7, SYS_link
 484:	48cd                	li	a7,19
 ecall
 486:	00000073          	ecall
 ret
 48a:	8082                	ret

000000000000048c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 48c:	48d1                	li	a7,20
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 494:	48a5                	li	a7,9
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <dup>:
.global dup
dup:
 li a7, SYS_dup
 49c:	48a9                	li	a7,10
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4a4:	48ad                	li	a7,11
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4ac:	48b1                	li	a7,12
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4b4:	48b5                	li	a7,13
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4bc:	48b9                	li	a7,14
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4c4:	1101                	addi	sp,sp,-32
 4c6:	ec06                	sd	ra,24(sp)
 4c8:	e822                	sd	s0,16(sp)
 4ca:	1000                	addi	s0,sp,32
 4cc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4d0:	4605                	li	a2,1
 4d2:	fef40593          	addi	a1,s0,-17
 4d6:	00000097          	auipc	ra,0x0
 4da:	f6e080e7          	jalr	-146(ra) # 444 <write>
}
 4de:	60e2                	ld	ra,24(sp)
 4e0:	6442                	ld	s0,16(sp)
 4e2:	6105                	addi	sp,sp,32
 4e4:	8082                	ret

00000000000004e6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4e6:	7139                	addi	sp,sp,-64
 4e8:	fc06                	sd	ra,56(sp)
 4ea:	f822                	sd	s0,48(sp)
 4ec:	f426                	sd	s1,40(sp)
 4ee:	f04a                	sd	s2,32(sp)
 4f0:	ec4e                	sd	s3,24(sp)
 4f2:	0080                	addi	s0,sp,64
 4f4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4f6:	c299                	beqz	a3,4fc <printint+0x16>
 4f8:	0805c863          	bltz	a1,588 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4fc:	2581                	sext.w	a1,a1
  neg = 0;
 4fe:	4881                	li	a7,0
 500:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 504:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 506:	2601                	sext.w	a2,a2
 508:	00000517          	auipc	a0,0x0
 50c:	45050513          	addi	a0,a0,1104 # 958 <digits>
 510:	883a                	mv	a6,a4
 512:	2705                	addiw	a4,a4,1
 514:	02c5f7bb          	remuw	a5,a1,a2
 518:	1782                	slli	a5,a5,0x20
 51a:	9381                	srli	a5,a5,0x20
 51c:	97aa                	add	a5,a5,a0
 51e:	0007c783          	lbu	a5,0(a5)
 522:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 526:	0005879b          	sext.w	a5,a1
 52a:	02c5d5bb          	divuw	a1,a1,a2
 52e:	0685                	addi	a3,a3,1
 530:	fec7f0e3          	bgeu	a5,a2,510 <printint+0x2a>
  if(neg)
 534:	00088b63          	beqz	a7,54a <printint+0x64>
    buf[i++] = '-';
 538:	fd040793          	addi	a5,s0,-48
 53c:	973e                	add	a4,a4,a5
 53e:	02d00793          	li	a5,45
 542:	fef70823          	sb	a5,-16(a4)
 546:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 54a:	02e05863          	blez	a4,57a <printint+0x94>
 54e:	fc040793          	addi	a5,s0,-64
 552:	00e78933          	add	s2,a5,a4
 556:	fff78993          	addi	s3,a5,-1
 55a:	99ba                	add	s3,s3,a4
 55c:	377d                	addiw	a4,a4,-1
 55e:	1702                	slli	a4,a4,0x20
 560:	9301                	srli	a4,a4,0x20
 562:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 566:	fff94583          	lbu	a1,-1(s2)
 56a:	8526                	mv	a0,s1
 56c:	00000097          	auipc	ra,0x0
 570:	f58080e7          	jalr	-168(ra) # 4c4 <putc>
  while(--i >= 0)
 574:	197d                	addi	s2,s2,-1
 576:	ff3918e3          	bne	s2,s3,566 <printint+0x80>
}
 57a:	70e2                	ld	ra,56(sp)
 57c:	7442                	ld	s0,48(sp)
 57e:	74a2                	ld	s1,40(sp)
 580:	7902                	ld	s2,32(sp)
 582:	69e2                	ld	s3,24(sp)
 584:	6121                	addi	sp,sp,64
 586:	8082                	ret
    x = -xx;
 588:	40b005bb          	negw	a1,a1
    neg = 1;
 58c:	4885                	li	a7,1
    x = -xx;
 58e:	bf8d                	j	500 <printint+0x1a>

0000000000000590 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 590:	7119                	addi	sp,sp,-128
 592:	fc86                	sd	ra,120(sp)
 594:	f8a2                	sd	s0,112(sp)
 596:	f4a6                	sd	s1,104(sp)
 598:	f0ca                	sd	s2,96(sp)
 59a:	ecce                	sd	s3,88(sp)
 59c:	e8d2                	sd	s4,80(sp)
 59e:	e4d6                	sd	s5,72(sp)
 5a0:	e0da                	sd	s6,64(sp)
 5a2:	fc5e                	sd	s7,56(sp)
 5a4:	f862                	sd	s8,48(sp)
 5a6:	f466                	sd	s9,40(sp)
 5a8:	f06a                	sd	s10,32(sp)
 5aa:	ec6e                	sd	s11,24(sp)
 5ac:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5ae:	0005c903          	lbu	s2,0(a1)
 5b2:	18090f63          	beqz	s2,750 <vprintf+0x1c0>
 5b6:	8aaa                	mv	s5,a0
 5b8:	8b32                	mv	s6,a2
 5ba:	00158493          	addi	s1,a1,1
  state = 0;
 5be:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5c0:	02500a13          	li	s4,37
      if(c == 'd'){
 5c4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5c8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5cc:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5d0:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d4:	00000b97          	auipc	s7,0x0
 5d8:	384b8b93          	addi	s7,s7,900 # 958 <digits>
 5dc:	a839                	j	5fa <vprintf+0x6a>
        putc(fd, c);
 5de:	85ca                	mv	a1,s2
 5e0:	8556                	mv	a0,s5
 5e2:	00000097          	auipc	ra,0x0
 5e6:	ee2080e7          	jalr	-286(ra) # 4c4 <putc>
 5ea:	a019                	j	5f0 <vprintf+0x60>
    } else if(state == '%'){
 5ec:	01498f63          	beq	s3,s4,60a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5f0:	0485                	addi	s1,s1,1
 5f2:	fff4c903          	lbu	s2,-1(s1)
 5f6:	14090d63          	beqz	s2,750 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5fa:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5fe:	fe0997e3          	bnez	s3,5ec <vprintf+0x5c>
      if(c == '%'){
 602:	fd479ee3          	bne	a5,s4,5de <vprintf+0x4e>
        state = '%';
 606:	89be                	mv	s3,a5
 608:	b7e5                	j	5f0 <vprintf+0x60>
      if(c == 'd'){
 60a:	05878063          	beq	a5,s8,64a <vprintf+0xba>
      } else if(c == 'l') {
 60e:	05978c63          	beq	a5,s9,666 <vprintf+0xd6>
      } else if(c == 'x') {
 612:	07a78863          	beq	a5,s10,682 <vprintf+0xf2>
      } else if(c == 'p') {
 616:	09b78463          	beq	a5,s11,69e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 61a:	07300713          	li	a4,115
 61e:	0ce78663          	beq	a5,a4,6ea <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 622:	06300713          	li	a4,99
 626:	0ee78e63          	beq	a5,a4,722 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 62a:	11478863          	beq	a5,s4,73a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 62e:	85d2                	mv	a1,s4
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e92080e7          	jalr	-366(ra) # 4c4 <putc>
        putc(fd, c);
 63a:	85ca                	mv	a1,s2
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	e86080e7          	jalr	-378(ra) # 4c4 <putc>
      }
      state = 0;
 646:	4981                	li	s3,0
 648:	b765                	j	5f0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 64a:	008b0913          	addi	s2,s6,8
 64e:	4685                	li	a3,1
 650:	4629                	li	a2,10
 652:	000b2583          	lw	a1,0(s6)
 656:	8556                	mv	a0,s5
 658:	00000097          	auipc	ra,0x0
 65c:	e8e080e7          	jalr	-370(ra) # 4e6 <printint>
 660:	8b4a                	mv	s6,s2
      state = 0;
 662:	4981                	li	s3,0
 664:	b771                	j	5f0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 666:	008b0913          	addi	s2,s6,8
 66a:	4681                	li	a3,0
 66c:	4629                	li	a2,10
 66e:	000b2583          	lw	a1,0(s6)
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	e72080e7          	jalr	-398(ra) # 4e6 <printint>
 67c:	8b4a                	mv	s6,s2
      state = 0;
 67e:	4981                	li	s3,0
 680:	bf85                	j	5f0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 682:	008b0913          	addi	s2,s6,8
 686:	4681                	li	a3,0
 688:	4641                	li	a2,16
 68a:	000b2583          	lw	a1,0(s6)
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	e56080e7          	jalr	-426(ra) # 4e6 <printint>
 698:	8b4a                	mv	s6,s2
      state = 0;
 69a:	4981                	li	s3,0
 69c:	bf91                	j	5f0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 69e:	008b0793          	addi	a5,s6,8
 6a2:	f8f43423          	sd	a5,-120(s0)
 6a6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6aa:	03000593          	li	a1,48
 6ae:	8556                	mv	a0,s5
 6b0:	00000097          	auipc	ra,0x0
 6b4:	e14080e7          	jalr	-492(ra) # 4c4 <putc>
  putc(fd, 'x');
 6b8:	85ea                	mv	a1,s10
 6ba:	8556                	mv	a0,s5
 6bc:	00000097          	auipc	ra,0x0
 6c0:	e08080e7          	jalr	-504(ra) # 4c4 <putc>
 6c4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6c6:	03c9d793          	srli	a5,s3,0x3c
 6ca:	97de                	add	a5,a5,s7
 6cc:	0007c583          	lbu	a1,0(a5)
 6d0:	8556                	mv	a0,s5
 6d2:	00000097          	auipc	ra,0x0
 6d6:	df2080e7          	jalr	-526(ra) # 4c4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6da:	0992                	slli	s3,s3,0x4
 6dc:	397d                	addiw	s2,s2,-1
 6de:	fe0914e3          	bnez	s2,6c6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6e2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6e6:	4981                	li	s3,0
 6e8:	b721                	j	5f0 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ea:	008b0993          	addi	s3,s6,8
 6ee:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6f2:	02090163          	beqz	s2,714 <vprintf+0x184>
        while(*s != 0){
 6f6:	00094583          	lbu	a1,0(s2)
 6fa:	c9a1                	beqz	a1,74a <vprintf+0x1ba>
          putc(fd, *s);
 6fc:	8556                	mv	a0,s5
 6fe:	00000097          	auipc	ra,0x0
 702:	dc6080e7          	jalr	-570(ra) # 4c4 <putc>
          s++;
 706:	0905                	addi	s2,s2,1
        while(*s != 0){
 708:	00094583          	lbu	a1,0(s2)
 70c:	f9e5                	bnez	a1,6fc <vprintf+0x16c>
        s = va_arg(ap, char*);
 70e:	8b4e                	mv	s6,s3
      state = 0;
 710:	4981                	li	s3,0
 712:	bdf9                	j	5f0 <vprintf+0x60>
          s = "(null)";
 714:	00000917          	auipc	s2,0x0
 718:	23c90913          	addi	s2,s2,572 # 950 <malloc+0xf6>
        while(*s != 0){
 71c:	02800593          	li	a1,40
 720:	bff1                	j	6fc <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 722:	008b0913          	addi	s2,s6,8
 726:	000b4583          	lbu	a1,0(s6)
 72a:	8556                	mv	a0,s5
 72c:	00000097          	auipc	ra,0x0
 730:	d98080e7          	jalr	-616(ra) # 4c4 <putc>
 734:	8b4a                	mv	s6,s2
      state = 0;
 736:	4981                	li	s3,0
 738:	bd65                	j	5f0 <vprintf+0x60>
        putc(fd, c);
 73a:	85d2                	mv	a1,s4
 73c:	8556                	mv	a0,s5
 73e:	00000097          	auipc	ra,0x0
 742:	d86080e7          	jalr	-634(ra) # 4c4 <putc>
      state = 0;
 746:	4981                	li	s3,0
 748:	b565                	j	5f0 <vprintf+0x60>
        s = va_arg(ap, char*);
 74a:	8b4e                	mv	s6,s3
      state = 0;
 74c:	4981                	li	s3,0
 74e:	b54d                	j	5f0 <vprintf+0x60>
    }
  }
}
 750:	70e6                	ld	ra,120(sp)
 752:	7446                	ld	s0,112(sp)
 754:	74a6                	ld	s1,104(sp)
 756:	7906                	ld	s2,96(sp)
 758:	69e6                	ld	s3,88(sp)
 75a:	6a46                	ld	s4,80(sp)
 75c:	6aa6                	ld	s5,72(sp)
 75e:	6b06                	ld	s6,64(sp)
 760:	7be2                	ld	s7,56(sp)
 762:	7c42                	ld	s8,48(sp)
 764:	7ca2                	ld	s9,40(sp)
 766:	7d02                	ld	s10,32(sp)
 768:	6de2                	ld	s11,24(sp)
 76a:	6109                	addi	sp,sp,128
 76c:	8082                	ret

000000000000076e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 76e:	715d                	addi	sp,sp,-80
 770:	ec06                	sd	ra,24(sp)
 772:	e822                	sd	s0,16(sp)
 774:	1000                	addi	s0,sp,32
 776:	e010                	sd	a2,0(s0)
 778:	e414                	sd	a3,8(s0)
 77a:	e818                	sd	a4,16(s0)
 77c:	ec1c                	sd	a5,24(s0)
 77e:	03043023          	sd	a6,32(s0)
 782:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 786:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 78a:	8622                	mv	a2,s0
 78c:	00000097          	auipc	ra,0x0
 790:	e04080e7          	jalr	-508(ra) # 590 <vprintf>
}
 794:	60e2                	ld	ra,24(sp)
 796:	6442                	ld	s0,16(sp)
 798:	6161                	addi	sp,sp,80
 79a:	8082                	ret

000000000000079c <printf>:

void
printf(const char *fmt, ...)
{
 79c:	711d                	addi	sp,sp,-96
 79e:	ec06                	sd	ra,24(sp)
 7a0:	e822                	sd	s0,16(sp)
 7a2:	1000                	addi	s0,sp,32
 7a4:	e40c                	sd	a1,8(s0)
 7a6:	e810                	sd	a2,16(s0)
 7a8:	ec14                	sd	a3,24(s0)
 7aa:	f018                	sd	a4,32(s0)
 7ac:	f41c                	sd	a5,40(s0)
 7ae:	03043823          	sd	a6,48(s0)
 7b2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7b6:	00840613          	addi	a2,s0,8
 7ba:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7be:	85aa                	mv	a1,a0
 7c0:	4505                	li	a0,1
 7c2:	00000097          	auipc	ra,0x0
 7c6:	dce080e7          	jalr	-562(ra) # 590 <vprintf>
}
 7ca:	60e2                	ld	ra,24(sp)
 7cc:	6442                	ld	s0,16(sp)
 7ce:	6125                	addi	sp,sp,96
 7d0:	8082                	ret

00000000000007d2 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7d2:	1141                	addi	sp,sp,-16
 7d4:	e422                	sd	s0,8(sp)
 7d6:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7d8:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7dc:	00000797          	auipc	a5,0x0
 7e0:	1947b783          	ld	a5,404(a5) # 970 <freep>
 7e4:	a805                	j	814 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7e6:	4618                	lw	a4,8(a2)
 7e8:	9db9                	addw	a1,a1,a4
 7ea:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7ee:	6398                	ld	a4,0(a5)
 7f0:	6318                	ld	a4,0(a4)
 7f2:	fee53823          	sd	a4,-16(a0)
 7f6:	a091                	j	83a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7f8:	ff852703          	lw	a4,-8(a0)
 7fc:	9e39                	addw	a2,a2,a4
 7fe:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 800:	ff053703          	ld	a4,-16(a0)
 804:	e398                	sd	a4,0(a5)
 806:	a099                	j	84c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 808:	6398                	ld	a4,0(a5)
 80a:	00e7e463          	bltu	a5,a4,812 <free+0x40>
 80e:	00e6ea63          	bltu	a3,a4,822 <free+0x50>
{
 812:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 814:	fed7fae3          	bgeu	a5,a3,808 <free+0x36>
 818:	6398                	ld	a4,0(a5)
 81a:	00e6e463          	bltu	a3,a4,822 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 81e:	fee7eae3          	bltu	a5,a4,812 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 822:	ff852583          	lw	a1,-8(a0)
 826:	6390                	ld	a2,0(a5)
 828:	02059713          	slli	a4,a1,0x20
 82c:	9301                	srli	a4,a4,0x20
 82e:	0712                	slli	a4,a4,0x4
 830:	9736                	add	a4,a4,a3
 832:	fae60ae3          	beq	a2,a4,7e6 <free+0x14>
    bp->s.ptr = p->s.ptr;
 836:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 83a:	4790                	lw	a2,8(a5)
 83c:	02061713          	slli	a4,a2,0x20
 840:	9301                	srli	a4,a4,0x20
 842:	0712                	slli	a4,a4,0x4
 844:	973e                	add	a4,a4,a5
 846:	fae689e3          	beq	a3,a4,7f8 <free+0x26>
  } else
    p->s.ptr = bp;
 84a:	e394                	sd	a3,0(a5)
  freep = p;
 84c:	00000717          	auipc	a4,0x0
 850:	12f73223          	sd	a5,292(a4) # 970 <freep>
}
 854:	6422                	ld	s0,8(sp)
 856:	0141                	addi	sp,sp,16
 858:	8082                	ret

000000000000085a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 85a:	7139                	addi	sp,sp,-64
 85c:	fc06                	sd	ra,56(sp)
 85e:	f822                	sd	s0,48(sp)
 860:	f426                	sd	s1,40(sp)
 862:	f04a                	sd	s2,32(sp)
 864:	ec4e                	sd	s3,24(sp)
 866:	e852                	sd	s4,16(sp)
 868:	e456                	sd	s5,8(sp)
 86a:	e05a                	sd	s6,0(sp)
 86c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 86e:	02051493          	slli	s1,a0,0x20
 872:	9081                	srli	s1,s1,0x20
 874:	04bd                	addi	s1,s1,15
 876:	8091                	srli	s1,s1,0x4
 878:	0014899b          	addiw	s3,s1,1
 87c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 87e:	00000517          	auipc	a0,0x0
 882:	0f253503          	ld	a0,242(a0) # 970 <freep>
 886:	c515                	beqz	a0,8b2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 888:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 88a:	4798                	lw	a4,8(a5)
 88c:	02977f63          	bgeu	a4,s1,8ca <malloc+0x70>
 890:	8a4e                	mv	s4,s3
 892:	0009871b          	sext.w	a4,s3
 896:	6685                	lui	a3,0x1
 898:	00d77363          	bgeu	a4,a3,89e <malloc+0x44>
 89c:	6a05                	lui	s4,0x1
 89e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8a2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8a6:	00000917          	auipc	s2,0x0
 8aa:	0ca90913          	addi	s2,s2,202 # 970 <freep>
  if(p == (char*)-1)
 8ae:	5afd                	li	s5,-1
 8b0:	a88d                	j	922 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8b2:	00000797          	auipc	a5,0x0
 8b6:	0c678793          	addi	a5,a5,198 # 978 <base>
 8ba:	00000717          	auipc	a4,0x0
 8be:	0af73b23          	sd	a5,182(a4) # 970 <freep>
 8c2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8c4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8c8:	b7e1                	j	890 <malloc+0x36>
      if(p->s.size == nunits)
 8ca:	02e48b63          	beq	s1,a4,900 <malloc+0xa6>
        p->s.size -= nunits;
 8ce:	4137073b          	subw	a4,a4,s3
 8d2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8d4:	1702                	slli	a4,a4,0x20
 8d6:	9301                	srli	a4,a4,0x20
 8d8:	0712                	slli	a4,a4,0x4
 8da:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8dc:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8e0:	00000717          	auipc	a4,0x0
 8e4:	08a73823          	sd	a0,144(a4) # 970 <freep>
      return (void*)(p + 1);
 8e8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8ec:	70e2                	ld	ra,56(sp)
 8ee:	7442                	ld	s0,48(sp)
 8f0:	74a2                	ld	s1,40(sp)
 8f2:	7902                	ld	s2,32(sp)
 8f4:	69e2                	ld	s3,24(sp)
 8f6:	6a42                	ld	s4,16(sp)
 8f8:	6aa2                	ld	s5,8(sp)
 8fa:	6b02                	ld	s6,0(sp)
 8fc:	6121                	addi	sp,sp,64
 8fe:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 900:	6398                	ld	a4,0(a5)
 902:	e118                	sd	a4,0(a0)
 904:	bff1                	j	8e0 <malloc+0x86>
  hp->s.size = nu;
 906:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 90a:	0541                	addi	a0,a0,16
 90c:	00000097          	auipc	ra,0x0
 910:	ec6080e7          	jalr	-314(ra) # 7d2 <free>
  return freep;
 914:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 918:	d971                	beqz	a0,8ec <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 91a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 91c:	4798                	lw	a4,8(a5)
 91e:	fa9776e3          	bgeu	a4,s1,8ca <malloc+0x70>
    if(p == freep)
 922:	00093703          	ld	a4,0(s2)
 926:	853e                	mv	a0,a5
 928:	fef719e3          	bne	a4,a5,91a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 92c:	8552                	mv	a0,s4
 92e:	00000097          	auipc	ra,0x0
 932:	b7e080e7          	jalr	-1154(ra) # 4ac <sbrk>
  if(p == (char*)-1)
 936:	fd5518e3          	bne	a0,s5,906 <malloc+0xac>
        return 0;
 93a:	4501                	li	a0,0
 93c:	bf45                	j	8ec <malloc+0x92>
