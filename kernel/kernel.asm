
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	cf478793          	addi	a5,a5,-780 # 80005d50 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3ce080e7          	jalr	974(ra) # 800024f4 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	85a080e7          	jalr	-1958(ra) # 80001a28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	05e080e7          	jalr	94(ra) # 8000223c <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	284080e7          	jalr	644(ra) # 8000249e <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	24e080e7          	jalr	590(ra) # 8000254a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f72080e7          	jalr	-142(ra) # 800023c2 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b0c080e7          	jalr	-1268(ra) # 800023c2 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8ec080e7          	jalr	-1812(ra) # 8000223c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <freememcount>:

int freememcount(void){
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  int count = 0;
  acquire(&kmem.lock);
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  struct run *p = kmem.freelist;
    80000b9c:	6c9c                	ld	a5,24(s1)
  while(p){
    80000b9e:	c785                	beqz	a5,80000bc6 <freememcount+0x46>
  int count = 0;
    80000ba0:	4481                	li	s1,0
    count++;
    80000ba2:	2485                	addiw	s1,s1,1
    p = p->next;
    80000ba4:	639c                	ld	a5,0(a5)
  while(p){
    80000ba6:	fff5                	bnez	a5,80000ba2 <freememcount+0x22>
  }
  release(&kmem.lock);
    80000ba8:	00011517          	auipc	a0,0x11
    80000bac:	d8850513          	addi	a0,a0,-632 # 80011930 <kmem>
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	15e080e7          	jalr	350(ra) # 80000d0e <release>
  return count*PGSIZE;
}
    80000bb8:	00c4951b          	slliw	a0,s1,0xc
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  int count = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7c5                	j	80000ba8 <freememcount+0x28>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e18080e7          	jalr	-488(ra) # 80001a0c <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de6080e7          	jalr	-538(ra) # 80001a0c <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dda080e7          	jalr	-550(ra) # 80001a0c <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc2080e7          	jalr	-574(ra) # 80001a0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d56080e7          	jalr	-682(ra) # 80001a0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	aec080e7          	jalr	-1300(ra) # 800019fc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	ad0080e7          	jalr	-1328(ra) # 800019fc <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	808080e7          	jalr	-2040(ra) # 80002756 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	e3a080e7          	jalr	-454(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	002080e7          	jalr	2(ra) # 80001f60 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	80a080e7          	jalr	-2038(ra) # 80000778 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	614080e7          	jalr	1556(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	11a50513          	addi	a0,a0,282 # 800080a0 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	604080e7          	jalr	1540(ra) # 80000592 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13250513          	addi	a0,a0,306 # 800080c8 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b3e080e7          	jalr	-1218(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	96e080e7          	jalr	-1682(ra) # 8000192c <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	768080e7          	jalr	1896(ra) # 8000272e <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	788080e7          	jalr	1928(ra) # 80002756 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	da4080e7          	jalr	-604(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	db2080e7          	jalr	-590(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	f54080e7          	jalr	-172(ra) # 80002f3a <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	5e4080e7          	jalr	1508(ra) # 800035d2 <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	57e080e7          	jalr	1406(ra) # 80004574 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	e9a080e7          	jalr	-358(ra) # 80005e98 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	cec080e7          	jalr	-788(ra) # 80001cf2 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srli	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	slli	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	06850513          	addi	a0,a0,104 # 800080d0 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	aa4080e7          	jalr	-1372(ra) # 80000b20 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cca080e7          	jalr	-822(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srli	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	andi	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	addi	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	00a7d513          	srli	a0,a5,0xa
    80001122:	0532                	slli	a0,a0,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	addi	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	addi	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	slli	a0,a0,0x34
    80001138:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	andi	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srli	a0,a0,0xa
    8000115a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	addi	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f6050513          	addi	a0,a0,-160 # 800080d8 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	addi	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	addi	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	167d                	addi	a2,a2,-1
    800011aa:	00b609b3          	add	s3,a2,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	addi	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	addi	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	addi	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	302080e7          	jalr	770(ra) # 80000548 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	addi	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	8c8080e7          	jalr	-1848(ra) # 80000b20 <kalloc>
    80001260:	00008797          	auipc	a5,0x8
    80001264:	daa7b823          	sd	a0,-592(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	aea080e7          	jalr	-1302(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	addi	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	addi	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	slli	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	slli	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	addi	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	addi	a0,a0,-1
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	addi	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	slli	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	slli	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e863          	bltu	a1,s3,800013bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	addi	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	d8a50513          	addi	a0,a0,-630 # 800080f0 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	d9250513          	addi	a0,a0,-622 # 80008108 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	d9250513          	addi	a0,a0,-622 # 80008118 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	d9a50513          	addi	a0,a0,-614 # 80008130 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	67a080e7          	jalr	1658(ra) # 80000a24 <kfree>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	f9397ce3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	c80080e7          	jalr	-896(ra) # 80001042 <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d54d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dbcd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fb778ee3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x92>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	732080e7          	jalr	1842(ra) # 80000b20 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	958080e7          	jalr	-1704(ra) # 80000d56 <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6f2080e7          	jalr	1778(ra) # 80000b20 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	91a080e7          	jalr	-1766(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95a080e7          	jalr	-1702(ra) # 80000db6 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cd450513          	addi	a0,a0,-812 # 80008148 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	767d                	lui	a2,0xfffff
    800014a0:	8f71                	and	a4,a4,a2
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff1                	and	a5,a5,a2
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6985                	lui	s3,0x1
    800014e8:	19fd                	addi	s3,s3,-1
    800014ea:	95ce                	add	a1,a1,s3
    800014ec:	79fd                	lui	s3,0xfffff
    800014ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	628080e7          	jalr	1576(ra) # 80000b20 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	84e080e7          	jalr	-1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4d0080e7          	jalr	1232(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a821                	j	800015a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001594:	0532                	slli	a0,a0,0xc
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	fe0080e7          	jalr	-32(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    8000159e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a2:	04a1                	addi	s1,s1,8
    800015a4:	03248163          	beq	s1,s2,800015c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015aa:	00f57793          	andi	a5,a0,15
    800015ae:	ff3782e3          	beq	a5,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b2:	8905                	andi	a0,a0,1
    800015b4:	d57d                	beqz	a0,800015a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bb250513          	addi	a0,a0,-1102 # 80008168 <digits+0x128>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c6:	8552                	mv	a0,s4
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	45c080e7          	jalr	1116(ra) # 80000a24 <kfree>
}
    800015d0:	70a2                	ld	ra,40(sp)
    800015d2:	7402                	ld	s0,32(sp)
    800015d4:	64e2                	ld	s1,24(sp)
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	69a2                	ld	s3,8(sp)
    800015da:	6a02                	ld	s4,0(sp)
    800015dc:	6145                	addi	sp,sp,48
    800015de:	8082                	ret

00000000800015e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e0:	1101                	addi	sp,sp,-32
    800015e2:	ec06                	sd	ra,24(sp)
    800015e4:	e822                	sd	s0,16(sp)
    800015e6:	e426                	sd	s1,8(sp)
    800015e8:	1000                	addi	s0,sp,32
    800015ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ec:	e999                	bnez	a1,80001602 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f86080e7          	jalr	-122(ra) # 80001576 <freewalk>
}
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6105                	addi	sp,sp,32
    80001600:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001602:	6605                	lui	a2,0x1
    80001604:	167d                	addi	a2,a2,-1
    80001606:	962e                	add	a2,a2,a1
    80001608:	4685                	li	a3,1
    8000160a:	8231                	srli	a2,a2,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d12080e7          	jalr	-750(ra) # 80001320 <uvmunmap>
    80001616:	bfe1                	j	800015ee <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a04080e7          	jalr	-1532(ra) # 80001042 <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4c4080e7          	jalr	1220(ra) # 80000b20 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	74a080e7          	jalr	1866(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b0a080e7          	jalr	-1270(ra) # 80001188 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	370080e7          	jalr	880(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c5a080e7          	jalr	-934(ra) # 80001320 <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94e080e7          	jalr	-1714(ra) # 80001042 <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e34080e7          	jalr	-460(ra) # 80000548 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	666080e7          	jalr	1638(ra) # 80000db6 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97a080e7          	jalr	-1670(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	c6bd                	beqz	a3,80001816 <copyin+0x6e>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a015                	j	800017f2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	9562                	add	a0,a0,s8
    800017d2:	0004861b          	sext.w	a2,s1
    800017d6:	412505b3          	sub	a1,a0,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	5da080e7          	jalr	1498(ra) # 80000db6 <memmove>

    len -= n;
    800017e4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ee:	02098263          	beqz	s3,80001812 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85ca                	mv	a1,s2
    800017f8:	855a                	mv	a0,s6
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	8ee080e7          	jalr	-1810(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001802:	cd01                	beqz	a0,8000181a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001804:	418904b3          	sub	s1,s2,s8
    80001808:	94d6                	add	s1,s1,s5
    if(n > len)
    8000180a:	fc99f3e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    8000180e:	84ce                	mv	s1,s3
    80001810:	b7c1                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001812:	4501                	li	a0,0
    80001814:	a021                	j	8000181c <copyin+0x74>
    80001816:	4501                	li	a0,0
}
    80001818:	8082                	ret
      return -1;
    8000181a:	557d                	li	a0,-1
}
    8000181c:	60a6                	ld	ra,72(sp)
    8000181e:	6406                	ld	s0,64(sp)
    80001820:	74e2                	ld	s1,56(sp)
    80001822:	7942                	ld	s2,48(sp)
    80001824:	79a2                	ld	s3,40(sp)
    80001826:	7a02                	ld	s4,32(sp)
    80001828:	6ae2                	ld	s5,24(sp)
    8000182a:	6b42                	ld	s6,16(sp)
    8000182c:	6ba2                	ld	s7,8(sp)
    8000182e:	6c02                	ld	s8,0(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret

0000000080001834 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001834:	c6c5                	beqz	a3,800018dc <copyinstr+0xa8>
{
    80001836:	715d                	addi	sp,sp,-80
    80001838:	e486                	sd	ra,72(sp)
    8000183a:	e0a2                	sd	s0,64(sp)
    8000183c:	fc26                	sd	s1,56(sp)
    8000183e:	f84a                	sd	s2,48(sp)
    80001840:	f44e                	sd	s3,40(sp)
    80001842:	f052                	sd	s4,32(sp)
    80001844:	ec56                	sd	s5,24(sp)
    80001846:	e85a                	sd	s6,16(sp)
    80001848:	e45e                	sd	s7,8(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8a2a                	mv	s4,a0
    8000184e:	8b2e                	mv	s6,a1
    80001850:	8bb2                	mv	s7,a2
    80001852:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6985                	lui	s3,0x1
    80001858:	a035                	j	80001884 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001860:	0017b793          	seqz	a5,a5
    80001864:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	85c080e7          	jalr	-1956(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001896:	41790833          	sub	a6,s2,s7
    8000189a:	984e                	add	a6,a6,s3
    if(n > max)
    8000189c:	0104f363          	bgeu	s1,a6,800018a2 <copyinstr+0x6e>
    800018a0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	fc080be3          	beqz	a6,8000187e <copyinstr+0x4a>
    800018ac:	985a                	add	a6,a6,s6
    800018ae:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b0:	41650633          	sub	a2,a0,s6
    800018b4:	14fd                	addi	s1,s1,-1
    800018b6:	9b26                	add	s6,s6,s1
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c0:	df49                	beqz	a4,8000185a <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	ff0796e3          	bne	a5,a6,800018b8 <copyinstr+0x84>
      dst++;
    800018d0:	8b42                	mv	s6,a6
    800018d2:	b775                	j	8000187e <copyinstr+0x4a>
    800018d4:	4781                	li	a5,0
    800018d6:	b769                	j	80001860 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x34>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	0017b793          	seqz	a5,a5
    800018e2:	40f00533          	neg	a0,a5
}
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	2ec080e7          	jalr	748(ra) # 80000be0 <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8ba50513          	addi	a0,a0,-1862 # 800081c8 <digits+0x188>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <procinit>:
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	88e58593          	addi	a1,a1,-1906 # 800081d0 <digits+0x190>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	00650513          	addi	a0,a0,6 # 80011950 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	278080e7          	jalr	632(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010917          	auipc	s2,0x10
    8000195e:	40e90913          	addi	s2,s2,1038 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b97          	auipc	s7,0x7
    80001966:	876b8b93          	addi	s7,s7,-1930 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196a:	8b4a                	mv	s6,s2
    8000196c:	00006a97          	auipc	s5,0x6
    80001970:	694a8a93          	addi	s5,s5,1684 # 80008000 <etext>
    80001974:	040009b7          	lui	s3,0x4000
    80001978:	19fd                	addi	s3,s3,-1
    8000197a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016a17          	auipc	s4,0x16
    80001980:	feca0a13          	addi	s4,s4,-20 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85de                	mv	a1,s7
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	242080e7          	jalr	578(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80001998:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199a:	c929                	beqz	a0,800019ec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199c:	416904b3          	sub	s1,s2,s6
    800019a0:	8491                	srai	s1,s1,0x4
    800019a2:	000ab783          	ld	a5,0(s5)
    800019a6:	02f484b3          	mul	s1,s1,a5
    800019aa:	2485                	addiw	s1,s1,1
    800019ac:	00d4949b          	slliw	s1,s1,0xd
    800019b0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4699                	li	a3,6
    800019b6:	6605                	lui	a2,0x1
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	85c080e7          	jalr	-1956(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	17090913          	addi	s2,s2,368
    800019ca:	fb491de3          	bne	s2,s4,80001984 <procinit+0x58>
  kvminithart();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	650080e7          	jalr	1616(ra) # 8000101e <kvminithart>
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6161                	addi	sp,sp,80
    800019ea:	8082                	ret
        panic("kalloc");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7f450513          	addi	a0,a0,2036 # 800081e0 <digits+0x1a0>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>

00000000800019fc <cpuid>:
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a02:	8512                	mv	a0,tp
}
    80001a04:	2501                	sext.w	a0,a0
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <mycpu>:
mycpu(void) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
}
    80001a18:	00010517          	auipc	a0,0x10
    80001a1c:	f5050513          	addi	a0,a0,-176 # 80011968 <cpus>
    80001a20:	953e                	add	a0,a0,a5
    80001a22:	6422                	ld	s0,8(sp)
    80001a24:	0141                	addi	sp,sp,16
    80001a26:	8082                	ret

0000000080001a28 <myproc>:
myproc(void) {
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
  push_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1dc080e7          	jalr	476(ra) # 80000c0e <push_off>
    80001a3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3c:	2781                	sext.w	a5,a5
    80001a3e:	079e                	slli	a5,a5,0x7
    80001a40:	00010717          	auipc	a4,0x10
    80001a44:	f1070713          	addi	a4,a4,-240 # 80011950 <pid_lock>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	262080e7          	jalr	610(ra) # 80000cae <pop_off>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6105                	addi	sp,sp,32
    80001a5e:	8082                	ret

0000000080001a60 <forkret>:
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e406                	sd	ra,8(sp)
    80001a64:	e022                	sd	s0,0(sp)
    80001a66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	fc0080e7          	jalr	-64(ra) # 80001a28 <myproc>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	29e080e7          	jalr	670(ra) # 80000d0e <release>
  if (first) {
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	0087a783          	lw	a5,8(a5) # 80008a80 <first.1671>
    80001a80:	eb89                	bnez	a5,80001a92 <forkret+0x32>
  usertrapret();
    80001a82:	00001097          	auipc	ra,0x1
    80001a86:	cec080e7          	jalr	-788(ra) # 8000276e <usertrapret>
}
    80001a8a:	60a2                	ld	ra,8(sp)
    80001a8c:	6402                	ld	s0,0(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret
    first = 0;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	fe07a723          	sw	zero,-18(a5) # 80008a80 <first.1671>
    fsinit(ROOTDEV);
    80001a9a:	4505                	li	a0,1
    80001a9c:	00002097          	auipc	ra,0x2
    80001aa0:	ab6080e7          	jalr	-1354(ra) # 80003552 <fsinit>
    80001aa4:	bff9                	j	80001a82 <forkret+0x22>

0000000080001aa6 <allocpid>:
allocpid() {
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab2:	00010917          	auipc	s2,0x10
    80001ab6:	e9e90913          	addi	s2,s2,-354 # 80011950 <pid_lock>
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac4:	00007797          	auipc	a5,0x7
    80001ac8:	fc078793          	addi	a5,a5,-64 # 80008a84 <nextpid>
    80001acc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ace:	0014871b          	addiw	a4,s1,1
    80001ad2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	238080e7          	jalr	568(ra) # 80000d0e <release>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret

0000000080001aec <proc_pagetable>:
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	e04a                	sd	s2,0(sp)
    80001af6:	1000                	addi	s0,sp,32
    80001af8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	8ea080e7          	jalr	-1814(ra) # 800013e4 <uvmcreate>
    80001b02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b04:	c121                	beqz	a0,80001b44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b06:	4729                	li	a4,10
    80001b08:	00005697          	auipc	a3,0x5
    80001b0c:	4f868693          	addi	a3,a3,1272 # 80007000 <_trampoline>
    80001b10:	6605                	lui	a2,0x1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	66e080e7          	jalr	1646(ra) # 80001188 <mappages>
    80001b22:	02054863          	bltz	a0,80001b52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b26:	4719                	li	a4,6
    80001b28:	05893683          	ld	a3,88(s2)
    80001b2c:	6605                	lui	a2,0x1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	650080e7          	jalr	1616(ra) # 80001188 <mappages>
    80001b40:	02054163          	bltz	a0,80001b62 <proc_pagetable+0x76>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	addi	sp,sp,32
    80001b50:	8082                	ret
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a8a080e7          	jalr	-1398(ra) # 800015e0 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	b7d5                	j	80001b44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	7b0080e7          	jalr	1968(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b78:	4581                	li	a1,0
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a64080e7          	jalr	-1436(ra) # 800015e0 <uvmfree>
    return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	bf7d                	j	80001b44 <proc_pagetable+0x58>

0000000080001b88 <proc_freepagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	84aa                	mv	s1,a0
    80001b96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b98:	4681                	li	a3,0
    80001b9a:	4605                	li	a2,1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	77c080e7          	jalr	1916(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	020005b7          	lui	a1,0x2000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b6                	slli	a1,a1,0xd
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	766080e7          	jalr	1894(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc2:	85ca                	mv	a1,s2
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a1a080e7          	jalr	-1510(ra) # 800015e0 <uvmfree>
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <freeproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be6:	6d28                	ld	a0,88(a0)
    80001be8:	c509                	beqz	a0,80001bf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	e3a080e7          	jalr	-454(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf6:	68a8                	ld	a0,80(s1)
    80001bf8:	c511                	beqz	a0,80001c04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfa:	64ac                	ld	a1,72(s1)
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	f8c080e7          	jalr	-116(ra) # 80001b88 <proc_freepagetable>
  p->pagetable = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c24:	0004ac23          	sw	zero,24(s1)
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <allocproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3e:	00010497          	auipc	s1,0x10
    80001c42:	12a48493          	addi	s1,s1,298 # 80011d68 <proc>
    80001c46:	00016917          	auipc	s2,0x16
    80001c4a:	d2290913          	addi	s2,s2,-734 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	00a080e7          	jalr	10(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c58:	4c9c                	lw	a5,24(s1)
    80001c5a:	cf81                	beqz	a5,80001c72 <allocproc+0x40>
      release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	0b0080e7          	jalr	176(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	17048493          	addi	s1,s1,368
    80001c6a:	ff2492e3          	bne	s1,s2,80001c4e <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a0b9                	j	80001cbe <allocproc+0x8c>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e34080e7          	jalr	-460(ra) # 80001aa6 <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	ea4080e7          	jalr	-348(ra) # 80000b20 <kalloc>
    80001c84:	892a                	mv	s2,a0
    80001c86:	eca8                	sd	a0,88(s1)
    80001c88:	c131                	beqz	a0,80001ccc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e60080e7          	jalr	-416(ra) # 80001aec <proc_pagetable>
    80001c94:	892a                	mv	s2,a0
    80001c96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c98:	c129                	beqz	a0,80001cda <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c9a:	07000613          	li	a2,112
    80001c9e:	4581                	li	a1,0
    80001ca0:	06048513          	addi	a0,s1,96
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0b2080e7          	jalr	178(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cac:	00000797          	auipc	a5,0x0
    80001cb0:	db478793          	addi	a5,a5,-588 # 80001a60 <forkret>
    80001cb4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb6:	60bc                	ld	a5,64(s1)
    80001cb8:	6705                	lui	a4,0x1
    80001cba:	97ba                	add	a5,a5,a4
    80001cbc:	f4bc                	sd	a5,104(s1)
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	040080e7          	jalr	64(ra) # 80000d0e <release>
    return 0;
    80001cd6:	84ca                	mv	s1,s2
    80001cd8:	b7dd                	j	80001cbe <allocproc+0x8c>
    freeproc(p);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	efe080e7          	jalr	-258(ra) # 80001bda <freeproc>
    release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	028080e7          	jalr	40(ra) # 80000d0e <release>
    return 0;
    80001cee:	84ca                	mv	s1,s2
    80001cf0:	b7f9                	j	80001cbe <allocproc+0x8c>

0000000080001cf2 <userinit>:
{
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	f36080e7          	jalr	-202(ra) # 80001c32 <allocproc>
    80001d04:	84aa                	mv	s1,a0
  initproc = p;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	30a7b923          	sd	a0,786(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0e:	03400613          	li	a2,52
    80001d12:	00007597          	auipc	a1,0x7
    80001d16:	d7e58593          	addi	a1,a1,-642 # 80008a90 <initcode>
    80001d1a:	6928                	ld	a0,80(a0)
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	6f6080e7          	jalr	1782(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d24:	6785                	lui	a5,0x1
    80001d26:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d28:	6cb8                	ld	a4,88(s1)
    80001d2a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2e:	6cb8                	ld	a4,88(s1)
    80001d30:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d32:	4641                	li	a2,16
    80001d34:	00006597          	auipc	a1,0x6
    80001d38:	4b458593          	addi	a1,a1,1204 # 800081e8 <digits+0x1a8>
    80001d3c:	15848513          	addi	a0,s1,344
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	16c080e7          	jalr	364(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d48:	00006517          	auipc	a0,0x6
    80001d4c:	4b050513          	addi	a0,a0,1200 # 800081f8 <digits+0x1b8>
    80001d50:	00002097          	auipc	ra,0x2
    80001d54:	22a080e7          	jalr	554(ra) # 80003f7a <namei>
    80001d58:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5c:	4789                	li	a5,2
    80001d5e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	fac080e7          	jalr	-84(ra) # 80000d0e <release>
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <growproc>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	e04a                	sd	s2,0(sp)
    80001d7e:	1000                	addi	s0,sp,32
    80001d80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	ca6080e7          	jalr	-858(ra) # 80001a28 <myproc>
    80001d8a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d8c:	652c                	ld	a1,72(a0)
    80001d8e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d92:	00904f63          	bgtz	s1,80001db0 <growproc+0x3c>
  } else if(n < 0){
    80001d96:	0204cc63          	bltz	s1,80001dce <growproc+0x5a>
  p->sz = sz;
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da2:	4501                	li	a0,0
}
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6902                	ld	s2,0(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db0:	9e25                	addw	a2,a2,s1
    80001db2:	1602                	slli	a2,a2,0x20
    80001db4:	9201                	srli	a2,a2,0x20
    80001db6:	1582                	slli	a1,a1,0x20
    80001db8:	9181                	srli	a1,a1,0x20
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	710080e7          	jalr	1808(ra) # 800014cc <uvmalloc>
    80001dc4:	0005061b          	sext.w	a2,a0
    80001dc8:	fa69                	bnez	a2,80001d9a <growproc+0x26>
      return -1;
    80001dca:	557d                	li	a0,-1
    80001dcc:	bfe1                	j	80001da4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dce:	9e25                	addw	a2,a2,s1
    80001dd0:	1602                	slli	a2,a2,0x20
    80001dd2:	9201                	srli	a2,a2,0x20
    80001dd4:	1582                	slli	a1,a1,0x20
    80001dd6:	9181                	srli	a1,a1,0x20
    80001dd8:	6928                	ld	a0,80(a0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	6aa080e7          	jalr	1706(ra) # 80001484 <uvmdealloc>
    80001de2:	0005061b          	sext.w	a2,a0
    80001de6:	bf55                	j	80001d9a <growproc+0x26>

0000000080001de8 <fork>:
{
    80001de8:	7179                	addi	sp,sp,-48
    80001dea:	f406                	sd	ra,40(sp)
    80001dec:	f022                	sd	s0,32(sp)
    80001dee:	ec26                	sd	s1,24(sp)
    80001df0:	e84a                	sd	s2,16(sp)
    80001df2:	e44e                	sd	s3,8(sp)
    80001df4:	e052                	sd	s4,0(sp)
    80001df6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	c30080e7          	jalr	-976(ra) # 80001a28 <myproc>
    80001e00:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	e30080e7          	jalr	-464(ra) # 80001c32 <allocproc>
    80001e0a:	c575                	beqz	a0,80001ef6 <fork+0x10e>
    80001e0c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0e:	04893603          	ld	a2,72(s2)
    80001e12:	692c                	ld	a1,80(a0)
    80001e14:	05093503          	ld	a0,80(s2)
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	800080e7          	jalr	-2048(ra) # 80001618 <uvmcopy>
    80001e20:	04054863          	bltz	a0,80001e70 <fork+0x88>
  np->sz = p->sz;
    80001e24:	04893783          	ld	a5,72(s2)
    80001e28:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e2c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e30:	05893683          	ld	a3,88(s2)
    80001e34:	87b6                	mv	a5,a3
    80001e36:	0589b703          	ld	a4,88(s3)
    80001e3a:	12068693          	addi	a3,a3,288
    80001e3e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e42:	6788                	ld	a0,8(a5)
    80001e44:	6b8c                	ld	a1,16(a5)
    80001e46:	6f90                	ld	a2,24(a5)
    80001e48:	01073023          	sd	a6,0(a4)
    80001e4c:	e708                	sd	a0,8(a4)
    80001e4e:	eb0c                	sd	a1,16(a4)
    80001e50:	ef10                	sd	a2,24(a4)
    80001e52:	02078793          	addi	a5,a5,32
    80001e56:	02070713          	addi	a4,a4,32
    80001e5a:	fed792e3          	bne	a5,a3,80001e3e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e5e:	0589b783          	ld	a5,88(s3)
    80001e62:	0607b823          	sd	zero,112(a5)
    80001e66:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e6a:	15000a13          	li	s4,336
    80001e6e:	a03d                	j	80001e9c <fork+0xb4>
    freeproc(np);
    80001e70:	854e                	mv	a0,s3
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	d68080e7          	jalr	-664(ra) # 80001bda <freeproc>
    release(&np->lock);
    80001e7a:	854e                	mv	a0,s3
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e92080e7          	jalr	-366(ra) # 80000d0e <release>
    return -1;
    80001e84:	54fd                	li	s1,-1
    80001e86:	a8b9                	j	80001ee4 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e88:	00002097          	auipc	ra,0x2
    80001e8c:	77e080e7          	jalr	1918(ra) # 80004606 <filedup>
    80001e90:	009987b3          	add	a5,s3,s1
    80001e94:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e96:	04a1                	addi	s1,s1,8
    80001e98:	01448763          	beq	s1,s4,80001ea6 <fork+0xbe>
    if(p->ofile[i])
    80001e9c:	009907b3          	add	a5,s2,s1
    80001ea0:	6388                	ld	a0,0(a5)
    80001ea2:	f17d                	bnez	a0,80001e88 <fork+0xa0>
    80001ea4:	bfcd                	j	80001e96 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ea6:	15093503          	ld	a0,336(s2)
    80001eaa:	00002097          	auipc	ra,0x2
    80001eae:	8e2080e7          	jalr	-1822(ra) # 8000378c <idup>
    80001eb2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb6:	4641                	li	a2,16
    80001eb8:	15890593          	addi	a1,s2,344
    80001ebc:	15898513          	addi	a0,s3,344
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	fec080e7          	jalr	-20(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001ec8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ecc:	4789                	li	a5,2
    80001ece:	00f9ac23          	sw	a5,24(s3)
  np->tracenum = p->tracenum;
    80001ed2:	16892783          	lw	a5,360(s2)
    80001ed6:	16f9a423          	sw	a5,360(s3)
  release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	e32080e7          	jalr	-462(ra) # 80000d0e <release>
}
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	70a2                	ld	ra,40(sp)
    80001ee8:	7402                	ld	s0,32(sp)
    80001eea:	64e2                	ld	s1,24(sp)
    80001eec:	6942                	ld	s2,16(sp)
    80001eee:	69a2                	ld	s3,8(sp)
    80001ef0:	6a02                	ld	s4,0(sp)
    80001ef2:	6145                	addi	sp,sp,48
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	54fd                	li	s1,-1
    80001ef8:	b7f5                	j	80001ee4 <fork+0xfc>

0000000080001efa <reparent>:
{
    80001efa:	7179                	addi	sp,sp,-48
    80001efc:	f406                	sd	ra,40(sp)
    80001efe:	f022                	sd	s0,32(sp)
    80001f00:	ec26                	sd	s1,24(sp)
    80001f02:	e84a                	sd	s2,16(sp)
    80001f04:	e44e                	sd	s3,8(sp)
    80001f06:	e052                	sd	s4,0(sp)
    80001f08:	1800                	addi	s0,sp,48
    80001f0a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f0c:	00010497          	auipc	s1,0x10
    80001f10:	e5c48493          	addi	s1,s1,-420 # 80011d68 <proc>
      pp->parent = initproc;
    80001f14:	00007a17          	auipc	s4,0x7
    80001f18:	104a0a13          	addi	s4,s4,260 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f1c:	00016997          	auipc	s3,0x16
    80001f20:	a4c98993          	addi	s3,s3,-1460 # 80017968 <tickslock>
    80001f24:	a029                	j	80001f2e <reparent+0x34>
    80001f26:	17048493          	addi	s1,s1,368
    80001f2a:	03348363          	beq	s1,s3,80001f50 <reparent+0x56>
    if(pp->parent == p){
    80001f2e:	709c                	ld	a5,32(s1)
    80001f30:	ff279be3          	bne	a5,s2,80001f26 <reparent+0x2c>
      acquire(&pp->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d24080e7          	jalr	-732(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f3e:	000a3783          	ld	a5,0(s4)
    80001f42:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	dc8080e7          	jalr	-568(ra) # 80000d0e <release>
    80001f4e:	bfe1                	j	80001f26 <reparent+0x2c>
}
    80001f50:	70a2                	ld	ra,40(sp)
    80001f52:	7402                	ld	s0,32(sp)
    80001f54:	64e2                	ld	s1,24(sp)
    80001f56:	6942                	ld	s2,16(sp)
    80001f58:	69a2                	ld	s3,8(sp)
    80001f5a:	6a02                	ld	s4,0(sp)
    80001f5c:	6145                	addi	sp,sp,48
    80001f5e:	8082                	ret

0000000080001f60 <scheduler>:
{
    80001f60:	715d                	addi	sp,sp,-80
    80001f62:	e486                	sd	ra,72(sp)
    80001f64:	e0a2                	sd	s0,64(sp)
    80001f66:	fc26                	sd	s1,56(sp)
    80001f68:	f84a                	sd	s2,48(sp)
    80001f6a:	f44e                	sd	s3,40(sp)
    80001f6c:	f052                	sd	s4,32(sp)
    80001f6e:	ec56                	sd	s5,24(sp)
    80001f70:	e85a                	sd	s6,16(sp)
    80001f72:	e45e                	sd	s7,8(sp)
    80001f74:	e062                	sd	s8,0(sp)
    80001f76:	0880                	addi	s0,sp,80
    80001f78:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f7c:	00779b13          	slli	s6,a5,0x7
    80001f80:	00010717          	auipc	a4,0x10
    80001f84:	9d070713          	addi	a4,a4,-1584 # 80011950 <pid_lock>
    80001f88:	975a                	add	a4,a4,s6
    80001f8a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f8e:	00010717          	auipc	a4,0x10
    80001f92:	9e270713          	addi	a4,a4,-1566 # 80011970 <cpus+0x8>
    80001f96:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f98:	4c0d                	li	s8,3
        c->proc = p;
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	00010a17          	auipc	s4,0x10
    80001fa0:	9b4a0a13          	addi	s4,s4,-1612 # 80011950 <pid_lock>
    80001fa4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	00016997          	auipc	s3,0x16
    80001faa:	9c298993          	addi	s3,s3,-1598 # 80017968 <tickslock>
        found = 1;
    80001fae:	4b85                	li	s7,1
    80001fb0:	a899                	j	80002006 <scheduler+0xa6>
        p->state = RUNNING;
    80001fb2:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fb6:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fba:	06048593          	addi	a1,s1,96
    80001fbe:	855a                	mv	a0,s6
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	704080e7          	jalr	1796(ra) # 800026c4 <swtch>
        c->proc = 0;
    80001fc8:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fcc:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	d3e080e7          	jalr	-706(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd8:	17048493          	addi	s1,s1,368
    80001fdc:	01348b63          	beq	s1,s3,80001ff2 <scheduler+0x92>
      acquire(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	c78080e7          	jalr	-904(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fea:	4c9c                	lw	a5,24(s1)
    80001fec:	ff2791e3          	bne	a5,s2,80001fce <scheduler+0x6e>
    80001ff0:	b7c9                	j	80001fb2 <scheduler+0x52>
    if(found == 0) {
    80001ff2:	000a9a63          	bnez	s5,80002006 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ffe:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002002:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002006:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002012:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002014:	00010497          	auipc	s1,0x10
    80002018:	d5448493          	addi	s1,s1,-684 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000201c:	4909                	li	s2,2
    8000201e:	b7c9                	j	80001fe0 <scheduler+0x80>

0000000080002020 <sched>:
{
    80002020:	7179                	addi	sp,sp,-48
    80002022:	f406                	sd	ra,40(sp)
    80002024:	f022                	sd	s0,32(sp)
    80002026:	ec26                	sd	s1,24(sp)
    80002028:	e84a                	sd	s2,16(sp)
    8000202a:	e44e                	sd	s3,8(sp)
    8000202c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	9fa080e7          	jalr	-1542(ra) # 80001a28 <myproc>
    80002036:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	ba8080e7          	jalr	-1112(ra) # 80000be0 <holding>
    80002040:	c93d                	beqz	a0,800020b6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002042:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002044:	2781                	sext.w	a5,a5
    80002046:	079e                	slli	a5,a5,0x7
    80002048:	00010717          	auipc	a4,0x10
    8000204c:	90870713          	addi	a4,a4,-1784 # 80011950 <pid_lock>
    80002050:	97ba                	add	a5,a5,a4
    80002052:	0907a703          	lw	a4,144(a5)
    80002056:	4785                	li	a5,1
    80002058:	06f71763          	bne	a4,a5,800020c6 <sched+0xa6>
  if(p->state == RUNNING)
    8000205c:	4c98                	lw	a4,24(s1)
    8000205e:	478d                	li	a5,3
    80002060:	06f70b63          	beq	a4,a5,800020d6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002064:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002068:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000206a:	efb5                	bnez	a5,800020e6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000206c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000206e:	00010917          	auipc	s2,0x10
    80002072:	8e290913          	addi	s2,s2,-1822 # 80011950 <pid_lock>
    80002076:	2781                	sext.w	a5,a5
    80002078:	079e                	slli	a5,a5,0x7
    8000207a:	97ca                	add	a5,a5,s2
    8000207c:	0947a983          	lw	s3,148(a5)
    80002080:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	00010597          	auipc	a1,0x10
    8000208a:	8ea58593          	addi	a1,a1,-1814 # 80011970 <cpus+0x8>
    8000208e:	95be                	add	a1,a1,a5
    80002090:	06048513          	addi	a0,s1,96
    80002094:	00000097          	auipc	ra,0x0
    80002098:	630080e7          	jalr	1584(ra) # 800026c4 <swtch>
    8000209c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000209e:	2781                	sext.w	a5,a5
    800020a0:	079e                	slli	a5,a5,0x7
    800020a2:	97ca                	add	a5,a5,s2
    800020a4:	0937aa23          	sw	s3,148(a5)
}
    800020a8:	70a2                	ld	ra,40(sp)
    800020aa:	7402                	ld	s0,32(sp)
    800020ac:	64e2                	ld	s1,24(sp)
    800020ae:	6942                	ld	s2,16(sp)
    800020b0:	69a2                	ld	s3,8(sp)
    800020b2:	6145                	addi	sp,sp,48
    800020b4:	8082                	ret
    panic("sched p->lock");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	14a50513          	addi	a0,a0,330 # 80008200 <digits+0x1c0>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	48a080e7          	jalr	1162(ra) # 80000548 <panic>
    panic("sched locks");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	14a50513          	addi	a0,a0,330 # 80008210 <digits+0x1d0>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	47a080e7          	jalr	1146(ra) # 80000548 <panic>
    panic("sched running");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	14a50513          	addi	a0,a0,330 # 80008220 <digits+0x1e0>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	46a080e7          	jalr	1130(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	14a50513          	addi	a0,a0,330 # 80008230 <digits+0x1f0>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	45a080e7          	jalr	1114(ra) # 80000548 <panic>

00000000800020f6 <exit>:
{
    800020f6:	7179                	addi	sp,sp,-48
    800020f8:	f406                	sd	ra,40(sp)
    800020fa:	f022                	sd	s0,32(sp)
    800020fc:	ec26                	sd	s1,24(sp)
    800020fe:	e84a                	sd	s2,16(sp)
    80002100:	e44e                	sd	s3,8(sp)
    80002102:	e052                	sd	s4,0(sp)
    80002104:	1800                	addi	s0,sp,48
    80002106:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	920080e7          	jalr	-1760(ra) # 80001a28 <myproc>
    80002110:	89aa                	mv	s3,a0
  if(p == initproc)
    80002112:	00007797          	auipc	a5,0x7
    80002116:	f067b783          	ld	a5,-250(a5) # 80009018 <initproc>
    8000211a:	0d050493          	addi	s1,a0,208
    8000211e:	15050913          	addi	s2,a0,336
    80002122:	02a79363          	bne	a5,a0,80002148 <exit+0x52>
    panic("init exiting");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	12250513          	addi	a0,a0,290 # 80008248 <digits+0x208>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	41a080e7          	jalr	1050(ra) # 80000548 <panic>
      fileclose(f);
    80002136:	00002097          	auipc	ra,0x2
    8000213a:	522080e7          	jalr	1314(ra) # 80004658 <fileclose>
      p->ofile[fd] = 0;
    8000213e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002142:	04a1                	addi	s1,s1,8
    80002144:	01248563          	beq	s1,s2,8000214e <exit+0x58>
    if(p->ofile[fd]){
    80002148:	6088                	ld	a0,0(s1)
    8000214a:	f575                	bnez	a0,80002136 <exit+0x40>
    8000214c:	bfdd                	j	80002142 <exit+0x4c>
  begin_op();
    8000214e:	00002097          	auipc	ra,0x2
    80002152:	038080e7          	jalr	56(ra) # 80004186 <begin_op>
  iput(p->cwd);
    80002156:	1509b503          	ld	a0,336(s3)
    8000215a:	00002097          	auipc	ra,0x2
    8000215e:	82a080e7          	jalr	-2006(ra) # 80003984 <iput>
  end_op();
    80002162:	00002097          	auipc	ra,0x2
    80002166:	0a4080e7          	jalr	164(ra) # 80004206 <end_op>
  p->cwd = 0;
    8000216a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000216e:	00007497          	auipc	s1,0x7
    80002172:	eaa48493          	addi	s1,s1,-342 # 80009018 <initproc>
    80002176:	6088                	ld	a0,0(s1)
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	ae2080e7          	jalr	-1310(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002180:	6088                	ld	a0,0(s1)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	766080e7          	jalr	1894(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    8000218a:	6088                	ld	a0,0(s1)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b82080e7          	jalr	-1150(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002194:	854e                	mv	a0,s3
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	ac4080e7          	jalr	-1340(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    8000219e:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a2:	854e                	mv	a0,s3
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	b6a080e7          	jalr	-1174(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aac080e7          	jalr	-1364(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021b6:	854e                	mv	a0,s3
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	aa2080e7          	jalr	-1374(ra) # 80000c5a <acquire>
  reparent(p);
    800021c0:	854e                	mv	a0,s3
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	d38080e7          	jalr	-712(ra) # 80001efa <reparent>
  wakeup1(original_parent);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	71c080e7          	jalr	1820(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800021d4:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021d8:	4791                	li	a5,4
    800021da:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	b2e080e7          	jalr	-1234(ra) # 80000d0e <release>
  sched();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e38080e7          	jalr	-456(ra) # 80002020 <sched>
  panic("zombie exit");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	06850513          	addi	a0,a0,104 # 80008258 <digits+0x218>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	350080e7          	jalr	848(ra) # 80000548 <panic>

0000000080002200 <yield>:
{
    80002200:	1101                	addi	sp,sp,-32
    80002202:	ec06                	sd	ra,24(sp)
    80002204:	e822                	sd	s0,16(sp)
    80002206:	e426                	sd	s1,8(sp)
    80002208:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	81e080e7          	jalr	-2018(ra) # 80001a28 <myproc>
    80002212:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a46080e7          	jalr	-1466(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    8000221c:	4789                	li	a5,2
    8000221e:	cc9c                	sw	a5,24(s1)
  sched();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e00080e7          	jalr	-512(ra) # 80002020 <sched>
  release(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	ae4080e7          	jalr	-1308(ra) # 80000d0e <release>
}
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <sleep>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	89aa                	mv	s3,a0
    8000224c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	7da080e7          	jalr	2010(ra) # 80001a28 <myproc>
    80002256:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002258:	05250663          	beq	a0,s2,800022a4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	9fe080e7          	jalr	-1538(ra) # 80000c5a <acquire>
    release(lk);
    80002264:	854a                	mv	a0,s2
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	aa8080e7          	jalr	-1368(ra) # 80000d0e <release>
  p->chan = chan;
    8000226e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002272:	4785                	li	a5,1
    80002274:	cc9c                	sw	a5,24(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	daa080e7          	jalr	-598(ra) # 80002020 <sched>
  p->chan = 0;
    8000227e:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a8a080e7          	jalr	-1398(ra) # 80000d0e <release>
    acquire(lk);
    8000228c:	854a                	mv	a0,s2
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	9cc080e7          	jalr	-1588(ra) # 80000c5a <acquire>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6145                	addi	sp,sp,48
    800022a2:	8082                	ret
  p->chan = chan;
    800022a4:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022a8:	4785                	li	a5,1
    800022aa:	cd1c                	sw	a5,24(a0)
  sched();
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	d74080e7          	jalr	-652(ra) # 80002020 <sched>
  p->chan = 0;
    800022b4:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022b8:	bff9                	j	80002296 <sleep+0x5a>

00000000800022ba <wait>:
{
    800022ba:	715d                	addi	sp,sp,-80
    800022bc:	e486                	sd	ra,72(sp)
    800022be:	e0a2                	sd	s0,64(sp)
    800022c0:	fc26                	sd	s1,56(sp)
    800022c2:	f84a                	sd	s2,48(sp)
    800022c4:	f44e                	sd	s3,40(sp)
    800022c6:	f052                	sd	s4,32(sp)
    800022c8:	ec56                	sd	s5,24(sp)
    800022ca:	e85a                	sd	s6,16(sp)
    800022cc:	e45e                	sd	s7,8(sp)
    800022ce:	e062                	sd	s8,0(sp)
    800022d0:	0880                	addi	s0,sp,80
    800022d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	754080e7          	jalr	1876(ra) # 80001a28 <myproc>
    800022dc:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022de:	8c2a                	mv	s8,a0
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	97a080e7          	jalr	-1670(ra) # 80000c5a <acquire>
    havekids = 0;
    800022e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ea:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022ec:	00015997          	auipc	s3,0x15
    800022f0:	67c98993          	addi	s3,s3,1660 # 80017968 <tickslock>
        havekids = 1;
    800022f4:	4a85                	li	s5,1
    havekids = 0;
    800022f6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f8:	00010497          	auipc	s1,0x10
    800022fc:	a7048493          	addi	s1,s1,-1424 # 80011d68 <proc>
    80002300:	a08d                	j	80002362 <wait+0xa8>
          pid = np->pid;
    80002302:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002306:	000b0e63          	beqz	s6,80002322 <wait+0x68>
    8000230a:	4691                	li	a3,4
    8000230c:	03448613          	addi	a2,s1,52
    80002310:	85da                	mv	a1,s6
    80002312:	05093503          	ld	a0,80(s2)
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	406080e7          	jalr	1030(ra) # 8000171c <copyout>
    8000231e:	02054263          	bltz	a0,80002342 <wait+0x88>
          freeproc(np);
    80002322:	8526                	mv	a0,s1
    80002324:	00000097          	auipc	ra,0x0
    80002328:	8b6080e7          	jalr	-1866(ra) # 80001bda <freeproc>
          release(&np->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	9e0080e7          	jalr	-1568(ra) # 80000d0e <release>
          release(&p->lock);
    80002336:	854a                	mv	a0,s2
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	9d6080e7          	jalr	-1578(ra) # 80000d0e <release>
          return pid;
    80002340:	a8a9                	j	8000239a <wait+0xe0>
            release(&np->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	9ca080e7          	jalr	-1590(ra) # 80000d0e <release>
            release(&p->lock);
    8000234c:	854a                	mv	a0,s2
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	9c0080e7          	jalr	-1600(ra) # 80000d0e <release>
            return -1;
    80002356:	59fd                	li	s3,-1
    80002358:	a089                	j	8000239a <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235a:	17048493          	addi	s1,s1,368
    8000235e:	03348463          	beq	s1,s3,80002386 <wait+0xcc>
      if(np->parent == p){
    80002362:	709c                	ld	a5,32(s1)
    80002364:	ff279be3          	bne	a5,s2,8000235a <wait+0xa0>
        acquire(&np->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	8f0080e7          	jalr	-1808(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002372:	4c9c                	lw	a5,24(s1)
    80002374:	f94787e3          	beq	a5,s4,80002302 <wait+0x48>
        release(&np->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	994080e7          	jalr	-1644(ra) # 80000d0e <release>
        havekids = 1;
    80002382:	8756                	mv	a4,s5
    80002384:	bfd9                	j	8000235a <wait+0xa0>
    if(!havekids || p->killed){
    80002386:	c701                	beqz	a4,8000238e <wait+0xd4>
    80002388:	03092783          	lw	a5,48(s2)
    8000238c:	c785                	beqz	a5,800023b4 <wait+0xfa>
      release(&p->lock);
    8000238e:	854a                	mv	a0,s2
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	97e080e7          	jalr	-1666(ra) # 80000d0e <release>
      return -1;
    80002398:	59fd                	li	s3,-1
}
    8000239a:	854e                	mv	a0,s3
    8000239c:	60a6                	ld	ra,72(sp)
    8000239e:	6406                	ld	s0,64(sp)
    800023a0:	74e2                	ld	s1,56(sp)
    800023a2:	7942                	ld	s2,48(sp)
    800023a4:	79a2                	ld	s3,40(sp)
    800023a6:	7a02                	ld	s4,32(sp)
    800023a8:	6ae2                	ld	s5,24(sp)
    800023aa:	6b42                	ld	s6,16(sp)
    800023ac:	6ba2                	ld	s7,8(sp)
    800023ae:	6c02                	ld	s8,0(sp)
    800023b0:	6161                	addi	sp,sp,80
    800023b2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b4:	85e2                	mv	a1,s8
    800023b6:	854a                	mv	a0,s2
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	e84080e7          	jalr	-380(ra) # 8000223c <sleep>
    havekids = 0;
    800023c0:	bf1d                	j	800022f6 <wait+0x3c>

00000000800023c2 <wakeup>:
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	0080                	addi	s0,sp,64
    800023d4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d6:	00010497          	auipc	s1,0x10
    800023da:	99248493          	addi	s1,s1,-1646 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e2:	00015917          	auipc	s2,0x15
    800023e6:	58690913          	addi	s2,s2,1414 # 80017968 <tickslock>
    800023ea:	a821                	j	80002402 <wakeup+0x40>
      p->state = RUNNABLE;
    800023ec:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	91c080e7          	jalr	-1764(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	17048493          	addi	s1,s1,368
    800023fe:	01248e63          	beq	s1,s2,8000241a <wakeup+0x58>
    acquire(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	856080e7          	jalr	-1962(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000240c:	4c9c                	lw	a5,24(s1)
    8000240e:	ff3791e3          	bne	a5,s3,800023f0 <wakeup+0x2e>
    80002412:	749c                	ld	a5,40(s1)
    80002414:	fd479ee3          	bne	a5,s4,800023f0 <wakeup+0x2e>
    80002418:	bfd1                	j	800023ec <wakeup+0x2a>
}
    8000241a:	70e2                	ld	ra,56(sp)
    8000241c:	7442                	ld	s0,48(sp)
    8000241e:	74a2                	ld	s1,40(sp)
    80002420:	7902                	ld	s2,32(sp)
    80002422:	69e2                	ld	s3,24(sp)
    80002424:	6a42                	ld	s4,16(sp)
    80002426:	6aa2                	ld	s5,8(sp)
    80002428:	6121                	addi	sp,sp,64
    8000242a:	8082                	ret

000000008000242c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000243c:	00010497          	auipc	s1,0x10
    80002440:	92c48493          	addi	s1,s1,-1748 # 80011d68 <proc>
    80002444:	00015997          	auipc	s3,0x15
    80002448:	52498993          	addi	s3,s3,1316 # 80017968 <tickslock>
    acquire(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	80c080e7          	jalr	-2036(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002456:	5c9c                	lw	a5,56(s1)
    80002458:	01278d63          	beq	a5,s2,80002472 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	8b0080e7          	jalr	-1872(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002466:	17048493          	addi	s1,s1,368
    8000246a:	ff3491e3          	bne	s1,s3,8000244c <kill+0x20>
  }
  return -1;
    8000246e:	557d                	li	a0,-1
    80002470:	a829                	j	8000248a <kill+0x5e>
      p->killed = 1;
    80002472:	4785                	li	a5,1
    80002474:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002476:	4c98                	lw	a4,24(s1)
    80002478:	4785                	li	a5,1
    8000247a:	00f70f63          	beq	a4,a5,80002498 <kill+0x6c>
      release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	88e080e7          	jalr	-1906(ra) # 80000d0e <release>
      return 0;
    80002488:	4501                	li	a0,0
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
        p->state = RUNNABLE;
    80002498:	4789                	li	a5,2
    8000249a:	cc9c                	sw	a5,24(s1)
    8000249c:	b7cd                	j	8000247e <kill+0x52>

000000008000249e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000249e:	7179                	addi	sp,sp,-48
    800024a0:	f406                	sd	ra,40(sp)
    800024a2:	f022                	sd	s0,32(sp)
    800024a4:	ec26                	sd	s1,24(sp)
    800024a6:	e84a                	sd	s2,16(sp)
    800024a8:	e44e                	sd	s3,8(sp)
    800024aa:	e052                	sd	s4,0(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	84aa                	mv	s1,a0
    800024b0:	892e                	mv	s2,a1
    800024b2:	89b2                	mv	s3,a2
    800024b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	572080e7          	jalr	1394(ra) # 80001a28 <myproc>
  if(user_dst){
    800024be:	c08d                	beqz	s1,800024e0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c0:	86d2                	mv	a3,s4
    800024c2:	864e                	mv	a2,s3
    800024c4:	85ca                	mv	a1,s2
    800024c6:	6928                	ld	a0,80(a0)
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	254080e7          	jalr	596(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6a02                	ld	s4,0(sp)
    800024dc:	6145                	addi	sp,sp,48
    800024de:	8082                	ret
    memmove((char *)dst, src, len);
    800024e0:	000a061b          	sext.w	a2,s4
    800024e4:	85ce                	mv	a1,s3
    800024e6:	854a                	mv	a0,s2
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	8ce080e7          	jalr	-1842(ra) # 80000db6 <memmove>
    return 0;
    800024f0:	8526                	mv	a0,s1
    800024f2:	bff9                	j	800024d0 <either_copyout+0x32>

00000000800024f4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	892a                	mv	s2,a0
    80002506:	84ae                	mv	s1,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	51c080e7          	jalr	1308(ra) # 80001a28 <myproc>
  if(user_src){
    80002514:	c08d                	beqz	s1,80002536 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	28a080e7          	jalr	650(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove(dst, (char*)src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	878080e7          	jalr	-1928(ra) # 80000db6 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyin+0x32>

000000008000254a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000254a:	715d                	addi	sp,sp,-80
    8000254c:	e486                	sd	ra,72(sp)
    8000254e:	e0a2                	sd	s0,64(sp)
    80002550:	fc26                	sd	s1,56(sp)
    80002552:	f84a                	sd	s2,48(sp)
    80002554:	f44e                	sd	s3,40(sp)
    80002556:	f052                	sd	s4,32(sp)
    80002558:	ec56                	sd	s5,24(sp)
    8000255a:	e85a                	sd	s6,16(sp)
    8000255c:	e45e                	sd	s7,8(sp)
    8000255e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002560:	00006517          	auipc	a0,0x6
    80002564:	b6850513          	addi	a0,a0,-1176 # 800080c8 <digits+0x88>
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	02a080e7          	jalr	42(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002570:	00010497          	auipc	s1,0x10
    80002574:	95048493          	addi	s1,s1,-1712 # 80011ec0 <proc+0x158>
    80002578:	00015917          	auipc	s2,0x15
    8000257c:	54890913          	addi	s2,s2,1352 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002580:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002582:	00006997          	auipc	s3,0x6
    80002586:	ce698993          	addi	s3,s3,-794 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000258a:	00006a97          	auipc	s5,0x6
    8000258e:	ce6a8a93          	addi	s5,s5,-794 # 80008270 <digits+0x230>
    printf("\n");
    80002592:	00006a17          	auipc	s4,0x6
    80002596:	b36a0a13          	addi	s4,s4,-1226 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259a:	00006b97          	auipc	s7,0x6
    8000259e:	d0eb8b93          	addi	s7,s7,-754 # 800082a8 <states.1711>
    800025a2:	a00d                	j	800025c4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a4:	ee06a583          	lw	a1,-288(a3)
    800025a8:	8556                	mv	a0,s5
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	fe8080e7          	jalr	-24(ra) # 80000592 <printf>
    printf("\n");
    800025b2:	8552                	mv	a0,s4
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fde080e7          	jalr	-34(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	17048493          	addi	s1,s1,368
    800025c0:	03248163          	beq	s1,s2,800025e2 <procdump+0x98>
    if(p->state == UNUSED)
    800025c4:	86a6                	mv	a3,s1
    800025c6:	ec04a783          	lw	a5,-320(s1)
    800025ca:	dbed                	beqz	a5,800025bc <procdump+0x72>
      state = "???";
    800025cc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ce:	fcfb6be3          	bltu	s6,a5,800025a4 <procdump+0x5a>
    800025d2:	1782                	slli	a5,a5,0x20
    800025d4:	9381                	srli	a5,a5,0x20
    800025d6:	078e                	slli	a5,a5,0x3
    800025d8:	97de                	add	a5,a5,s7
    800025da:	6390                	ld	a2,0(a5)
    800025dc:	f661                	bnez	a2,800025a4 <procdump+0x5a>
      state = "???";
    800025de:	864e                	mv	a2,s3
    800025e0:	b7d1                	j	800025a4 <procdump+0x5a>
  }
}
    800025e2:	60a6                	ld	ra,72(sp)
    800025e4:	6406                	ld	s0,64(sp)
    800025e6:	74e2                	ld	s1,56(sp)
    800025e8:	7942                	ld	s2,48(sp)
    800025ea:	79a2                	ld	s3,40(sp)
    800025ec:	7a02                	ld	s4,32(sp)
    800025ee:	6ae2                	ld	s5,24(sp)
    800025f0:	6b42                	ld	s6,16(sp)
    800025f2:	6ba2                	ld	s7,8(sp)
    800025f4:	6161                	addi	sp,sp,80
    800025f6:	8082                	ret

00000000800025f8 <trace>:

int trace(int num){
    800025f8:	1101                	addi	sp,sp,-32
    800025fa:	ec06                	sd	ra,24(sp)
    800025fc:	e822                	sd	s0,16(sp)
    800025fe:	e426                	sd	s1,8(sp)
    80002600:	1000                	addi	s0,sp,32
    80002602:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	424080e7          	jalr	1060(ra) # 80001a28 <myproc>
    p->tracenum = num;
    8000260c:	16952423          	sw	s1,360(a0)
    return p->tracenum;
}
    80002610:	8526                	mv	a0,s1
    80002612:	60e2                	ld	ra,24(sp)
    80002614:	6442                	ld	s0,16(sp)
    80002616:	64a2                	ld	s1,8(sp)
    80002618:	6105                	addi	sp,sp,32
    8000261a:	8082                	ret

000000008000261c <proccount>:

int proccount(){
    8000261c:	7179                	addi	sp,sp,-48
    8000261e:	f406                	sd	ra,40(sp)
    80002620:	f022                	sd	s0,32(sp)
    80002622:	ec26                	sd	s1,24(sp)
    80002624:	e84a                	sd	s2,16(sp)
    80002626:	e44e                	sd	s3,8(sp)
    80002628:	1800                	addi	s0,sp,48
    struct proc *p;
    int count = 0;
    8000262a:	4901                	li	s2,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000262c:	0000f497          	auipc	s1,0xf
    80002630:	73c48493          	addi	s1,s1,1852 # 80011d68 <proc>
    80002634:	00015997          	auipc	s3,0x15
    80002638:	33498993          	addi	s3,s3,820 # 80017968 <tickslock>
    8000263c:	a811                	j	80002650 <proccount+0x34>
      acquire(&p->lock);
      if(p->state != UNUSED) {
        count++;
      }
      release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	6ce080e7          	jalr	1742(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002648:	17048493          	addi	s1,s1,368
    8000264c:	01348b63          	beq	s1,s3,80002662 <proccount+0x46>
      acquire(&p->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	608080e7          	jalr	1544(ra) # 80000c5a <acquire>
      if(p->state != UNUSED) {
    8000265a:	4c9c                	lw	a5,24(s1)
    8000265c:	d3ed                	beqz	a5,8000263e <proccount+0x22>
        count++;
    8000265e:	2905                	addiw	s2,s2,1
    80002660:	bff9                	j	8000263e <proccount+0x22>
  }
  return count;
}
    80002662:	854a                	mv	a0,s2
    80002664:	70a2                	ld	ra,40(sp)
    80002666:	7402                	ld	s0,32(sp)
    80002668:	64e2                	ld	s1,24(sp)
    8000266a:	6942                	ld	s2,16(sp)
    8000266c:	69a2                	ld	s3,8(sp)
    8000266e:	6145                	addi	sp,sp,48
    80002670:	8082                	ret

0000000080002672 <sysinfo>:

int sysinfo(uint64 p){
  if(p == 0){
    80002672:	c539                	beqz	a0,800026c0 <sysinfo+0x4e>
int sysinfo(uint64 p){
    80002674:	7179                	addi	sp,sp,-48
    80002676:	f406                	sd	ra,40(sp)
    80002678:	f022                	sd	s0,32(sp)
    8000267a:	ec26                	sd	s1,24(sp)
    8000267c:	1800                	addi	s0,sp,48
    8000267e:	84aa                	mv	s1,a0
    return -1;
  }

  struct sysinfo info;

  info.nproc = proccount();
    80002680:	00000097          	auipc	ra,0x0
    80002684:	f9c080e7          	jalr	-100(ra) # 8000261c <proccount>
    80002688:	fca43c23          	sd	a0,-40(s0)
  info.freemem = freememcount();
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	4f4080e7          	jalr	1268(ra) # 80000b80 <freememcount>
    80002694:	fca43823          	sd	a0,-48(s0)

  struct proc *proc = myproc();
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	390080e7          	jalr	912(ra) # 80001a28 <myproc>
  if(copyout(proc->pagetable,p,(char *)&info,sizeof(info)) < 0){
    800026a0:	46c1                	li	a3,16
    800026a2:	fd040613          	addi	a2,s0,-48
    800026a6:	85a6                	mv	a1,s1
    800026a8:	6928                	ld	a0,80(a0)
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	072080e7          	jalr	114(ra) # 8000171c <copyout>
    800026b2:	41f5551b          	sraiw	a0,a0,0x1f
    return -1;
  }
  return 0;
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6145                	addi	sp,sp,48
    800026be:	8082                	ret
    return -1;
    800026c0:	557d                	li	a0,-1
}
    800026c2:	8082                	ret

00000000800026c4 <swtch>:
    800026c4:	00153023          	sd	ra,0(a0)
    800026c8:	00253423          	sd	sp,8(a0)
    800026cc:	e900                	sd	s0,16(a0)
    800026ce:	ed04                	sd	s1,24(a0)
    800026d0:	03253023          	sd	s2,32(a0)
    800026d4:	03353423          	sd	s3,40(a0)
    800026d8:	03453823          	sd	s4,48(a0)
    800026dc:	03553c23          	sd	s5,56(a0)
    800026e0:	05653023          	sd	s6,64(a0)
    800026e4:	05753423          	sd	s7,72(a0)
    800026e8:	05853823          	sd	s8,80(a0)
    800026ec:	05953c23          	sd	s9,88(a0)
    800026f0:	07a53023          	sd	s10,96(a0)
    800026f4:	07b53423          	sd	s11,104(a0)
    800026f8:	0005b083          	ld	ra,0(a1)
    800026fc:	0085b103          	ld	sp,8(a1)
    80002700:	6980                	ld	s0,16(a1)
    80002702:	6d84                	ld	s1,24(a1)
    80002704:	0205b903          	ld	s2,32(a1)
    80002708:	0285b983          	ld	s3,40(a1)
    8000270c:	0305ba03          	ld	s4,48(a1)
    80002710:	0385ba83          	ld	s5,56(a1)
    80002714:	0405bb03          	ld	s6,64(a1)
    80002718:	0485bb83          	ld	s7,72(a1)
    8000271c:	0505bc03          	ld	s8,80(a1)
    80002720:	0585bc83          	ld	s9,88(a1)
    80002724:	0605bd03          	ld	s10,96(a1)
    80002728:	0685bd83          	ld	s11,104(a1)
    8000272c:	8082                	ret

000000008000272e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000272e:	1141                	addi	sp,sp,-16
    80002730:	e406                	sd	ra,8(sp)
    80002732:	e022                	sd	s0,0(sp)
    80002734:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002736:	00006597          	auipc	a1,0x6
    8000273a:	b9a58593          	addi	a1,a1,-1126 # 800082d0 <states.1711+0x28>
    8000273e:	00015517          	auipc	a0,0x15
    80002742:	22a50513          	addi	a0,a0,554 # 80017968 <tickslock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	484080e7          	jalr	1156(ra) # 80000bca <initlock>
}
    8000274e:	60a2                	ld	ra,8(sp)
    80002750:	6402                	ld	s0,0(sp)
    80002752:	0141                	addi	sp,sp,16
    80002754:	8082                	ret

0000000080002756 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002756:	1141                	addi	sp,sp,-16
    80002758:	e422                	sd	s0,8(sp)
    8000275a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275c:	00003797          	auipc	a5,0x3
    80002760:	56478793          	addi	a5,a5,1380 # 80005cc0 <kernelvec>
    80002764:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002768:	6422                	ld	s0,8(sp)
    8000276a:	0141                	addi	sp,sp,16
    8000276c:	8082                	ret

000000008000276e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000276e:	1141                	addi	sp,sp,-16
    80002770:	e406                	sd	ra,8(sp)
    80002772:	e022                	sd	s0,0(sp)
    80002774:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	2b2080e7          	jalr	690(ra) # 80001a28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002782:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002784:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002788:	00005617          	auipc	a2,0x5
    8000278c:	87860613          	addi	a2,a2,-1928 # 80007000 <_trampoline>
    80002790:	00005697          	auipc	a3,0x5
    80002794:	87068693          	addi	a3,a3,-1936 # 80007000 <_trampoline>
    80002798:	8e91                	sub	a3,a3,a2
    8000279a:	040007b7          	lui	a5,0x4000
    8000279e:	17fd                	addi	a5,a5,-1
    800027a0:	07b2                	slli	a5,a5,0xc
    800027a2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027aa:	180026f3          	csrr	a3,satp
    800027ae:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027b0:	6d38                	ld	a4,88(a0)
    800027b2:	6134                	ld	a3,64(a0)
    800027b4:	6585                	lui	a1,0x1
    800027b6:	96ae                	add	a3,a3,a1
    800027b8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ba:	6d38                	ld	a4,88(a0)
    800027bc:	00000697          	auipc	a3,0x0
    800027c0:	13868693          	addi	a3,a3,312 # 800028f4 <usertrap>
    800027c4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c8:	8692                	mv	a3,tp
    800027ca:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027d0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027de:	6f18                	ld	a4,24(a4)
    800027e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e4:	692c                	ld	a1,80(a0)
    800027e6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027e8:	00005717          	auipc	a4,0x5
    800027ec:	8a870713          	addi	a4,a4,-1880 # 80007090 <userret>
    800027f0:	8f11                	sub	a4,a4,a2
    800027f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027f4:	577d                	li	a4,-1
    800027f6:	177e                	slli	a4,a4,0x3f
    800027f8:	8dd9                	or	a1,a1,a4
    800027fa:	02000537          	lui	a0,0x2000
    800027fe:	157d                	addi	a0,a0,-1
    80002800:	0536                	slli	a0,a0,0xd
    80002802:	9782                	jalr	a5
}
    80002804:	60a2                	ld	ra,8(sp)
    80002806:	6402                	ld	s0,0(sp)
    80002808:	0141                	addi	sp,sp,16
    8000280a:	8082                	ret

000000008000280c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000280c:	1101                	addi	sp,sp,-32
    8000280e:	ec06                	sd	ra,24(sp)
    80002810:	e822                	sd	s0,16(sp)
    80002812:	e426                	sd	s1,8(sp)
    80002814:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002816:	00015497          	auipc	s1,0x15
    8000281a:	15248493          	addi	s1,s1,338 # 80017968 <tickslock>
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	43a080e7          	jalr	1082(ra) # 80000c5a <acquire>
  ticks++;
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	7f850513          	addi	a0,a0,2040 # 80009020 <ticks>
    80002830:	411c                	lw	a5,0(a0)
    80002832:	2785                	addiw	a5,a5,1
    80002834:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	b8c080e7          	jalr	-1140(ra) # 800023c2 <wakeup>
  release(&tickslock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	4ce080e7          	jalr	1230(ra) # 80000d0e <release>
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6105                	addi	sp,sp,32
    80002850:	8082                	ret

0000000080002852 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002860:	00074d63          	bltz	a4,8000287a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002864:	57fd                	li	a5,-1
    80002866:	17fe                	slli	a5,a5,0x3f
    80002868:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000286a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000286c:	06f70363          	beq	a4,a5,800028d2 <devintr+0x80>
  }
}
    80002870:	60e2                	ld	ra,24(sp)
    80002872:	6442                	ld	s0,16(sp)
    80002874:	64a2                	ld	s1,8(sp)
    80002876:	6105                	addi	sp,sp,32
    80002878:	8082                	ret
     (scause & 0xff) == 9){
    8000287a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000287e:	46a5                	li	a3,9
    80002880:	fed792e3          	bne	a5,a3,80002864 <devintr+0x12>
    int irq = plic_claim();
    80002884:	00003097          	auipc	ra,0x3
    80002888:	544080e7          	jalr	1348(ra) # 80005dc8 <plic_claim>
    8000288c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000288e:	47a9                	li	a5,10
    80002890:	02f50763          	beq	a0,a5,800028be <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002894:	4785                	li	a5,1
    80002896:	02f50963          	beq	a0,a5,800028c8 <devintr+0x76>
    return 1;
    8000289a:	4505                	li	a0,1
    } else if(irq){
    8000289c:	d8f1                	beqz	s1,80002870 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000289e:	85a6                	mv	a1,s1
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	a3850513          	addi	a0,a0,-1480 # 800082d8 <states.1711+0x30>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	cea080e7          	jalr	-790(ra) # 80000592 <printf>
      plic_complete(irq);
    800028b0:	8526                	mv	a0,s1
    800028b2:	00003097          	auipc	ra,0x3
    800028b6:	53a080e7          	jalr	1338(ra) # 80005dec <plic_complete>
    return 1;
    800028ba:	4505                	li	a0,1
    800028bc:	bf55                	j	80002870 <devintr+0x1e>
      uartintr();
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	116080e7          	jalr	278(ra) # 800009d4 <uartintr>
    800028c6:	b7ed                	j	800028b0 <devintr+0x5e>
      virtio_disk_intr();
    800028c8:	00004097          	auipc	ra,0x4
    800028cc:	9be080e7          	jalr	-1602(ra) # 80006286 <virtio_disk_intr>
    800028d0:	b7c5                	j	800028b0 <devintr+0x5e>
    if(cpuid() == 0){
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	12a080e7          	jalr	298(ra) # 800019fc <cpuid>
    800028da:	c901                	beqz	a0,800028ea <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028dc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028e2:	14479073          	csrw	sip,a5
    return 2;
    800028e6:	4509                	li	a0,2
    800028e8:	b761                	j	80002870 <devintr+0x1e>
      clockintr();
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	f22080e7          	jalr	-222(ra) # 8000280c <clockintr>
    800028f2:	b7ed                	j	800028dc <devintr+0x8a>

00000000800028f4 <usertrap>:
{
    800028f4:	1101                	addi	sp,sp,-32
    800028f6:	ec06                	sd	ra,24(sp)
    800028f8:	e822                	sd	s0,16(sp)
    800028fa:	e426                	sd	s1,8(sp)
    800028fc:	e04a                	sd	s2,0(sp)
    800028fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002900:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002904:	1007f793          	andi	a5,a5,256
    80002908:	e3ad                	bnez	a5,8000296a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290a:	00003797          	auipc	a5,0x3
    8000290e:	3b678793          	addi	a5,a5,950 # 80005cc0 <kernelvec>
    80002912:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	112080e7          	jalr	274(ra) # 80001a28 <myproc>
    8000291e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002920:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002922:	14102773          	csrr	a4,sepc
    80002926:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000292c:	47a1                	li	a5,8
    8000292e:	04f71c63          	bne	a4,a5,80002986 <usertrap+0x92>
    if(p->killed)
    80002932:	591c                	lw	a5,48(a0)
    80002934:	e3b9                	bnez	a5,8000297a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002936:	6cb8                	ld	a4,88(s1)
    80002938:	6f1c                	ld	a5,24(a4)
    8000293a:	0791                	addi	a5,a5,4
    8000293c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002942:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10079073          	csrw	sstatus,a5
    syscall();
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	2e0080e7          	jalr	736(ra) # 80002c2a <syscall>
  if(p->killed)
    80002952:	589c                	lw	a5,48(s1)
    80002954:	ebc1                	bnez	a5,800029e4 <usertrap+0xf0>
  usertrapret();
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	e18080e7          	jalr	-488(ra) # 8000276e <usertrapret>
}
    8000295e:	60e2                	ld	ra,24(sp)
    80002960:	6442                	ld	s0,16(sp)
    80002962:	64a2                	ld	s1,8(sp)
    80002964:	6902                	ld	s2,0(sp)
    80002966:	6105                	addi	sp,sp,32
    80002968:	8082                	ret
    panic("usertrap: not from user mode");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	98e50513          	addi	a0,a0,-1650 # 800082f8 <states.1711+0x50>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bd6080e7          	jalr	-1066(ra) # 80000548 <panic>
      exit(-1);
    8000297a:	557d                	li	a0,-1
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	77a080e7          	jalr	1914(ra) # 800020f6 <exit>
    80002984:	bf4d                	j	80002936 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	ecc080e7          	jalr	-308(ra) # 80002852 <devintr>
    8000298e:	892a                	mv	s2,a0
    80002990:	c501                	beqz	a0,80002998 <usertrap+0xa4>
  if(p->killed)
    80002992:	589c                	lw	a5,48(s1)
    80002994:	c3a1                	beqz	a5,800029d4 <usertrap+0xe0>
    80002996:	a815                	j	800029ca <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000299c:	5c90                	lw	a2,56(s1)
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	97a50513          	addi	a0,a0,-1670 # 80008318 <states.1711+0x70>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	bec080e7          	jalr	-1044(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	99250513          	addi	a0,a0,-1646 # 80008348 <states.1711+0xa0>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	bd4080e7          	jalr	-1068(ra) # 80000592 <printf>
    p->killed = 1;
    800029c6:	4785                	li	a5,1
    800029c8:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029ca:	557d                	li	a0,-1
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	72a080e7          	jalr	1834(ra) # 800020f6 <exit>
  if(which_dev == 2)
    800029d4:	4789                	li	a5,2
    800029d6:	f8f910e3          	bne	s2,a5,80002956 <usertrap+0x62>
    yield();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	826080e7          	jalr	-2010(ra) # 80002200 <yield>
    800029e2:	bf95                	j	80002956 <usertrap+0x62>
  int which_dev = 0;
    800029e4:	4901                	li	s2,0
    800029e6:	b7d5                	j	800029ca <usertrap+0xd6>

00000000800029e8 <kerneltrap>:
{
    800029e8:	7179                	addi	sp,sp,-48
    800029ea:	f406                	sd	ra,40(sp)
    800029ec:	f022                	sd	s0,32(sp)
    800029ee:	ec26                	sd	s1,24(sp)
    800029f0:	e84a                	sd	s2,16(sp)
    800029f2:	e44e                	sd	s3,8(sp)
    800029f4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a02:	1004f793          	andi	a5,s1,256
    80002a06:	cb85                	beqz	a5,80002a36 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0e:	ef85                	bnez	a5,80002a46 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	e42080e7          	jalr	-446(ra) # 80002852 <devintr>
    80002a18:	cd1d                	beqz	a0,80002a56 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	4789                	li	a5,2
    80002a1c:	06f50a63          	beq	a0,a5,80002a90 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a20:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10049073          	csrw	sstatus,s1
}
    80002a28:	70a2                	ld	ra,40(sp)
    80002a2a:	7402                	ld	s0,32(sp)
    80002a2c:	64e2                	ld	s1,24(sp)
    80002a2e:	6942                	ld	s2,16(sp)
    80002a30:	69a2                	ld	s3,8(sp)
    80002a32:	6145                	addi	sp,sp,48
    80002a34:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	93250513          	addi	a0,a0,-1742 # 80008368 <states.1711+0xc0>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b0a080e7          	jalr	-1270(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	94a50513          	addi	a0,a0,-1718 # 80008390 <states.1711+0xe8>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	afa080e7          	jalr	-1286(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a56:	85ce                	mv	a1,s3
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	95850513          	addi	a0,a0,-1704 # 800083b0 <states.1711+0x108>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b32080e7          	jalr	-1230(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	95050513          	addi	a0,a0,-1712 # 800083c0 <states.1711+0x118>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b1a080e7          	jalr	-1254(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	95850513          	addi	a0,a0,-1704 # 800083d8 <states.1711+0x130>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	ac0080e7          	jalr	-1344(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	f98080e7          	jalr	-104(ra) # 80001a28 <myproc>
    80002a98:	d541                	beqz	a0,80002a20 <kerneltrap+0x38>
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	f8e080e7          	jalr	-114(ra) # 80001a28 <myproc>
    80002aa2:	4d18                	lw	a4,24(a0)
    80002aa4:	478d                	li	a5,3
    80002aa6:	f6f71de3          	bne	a4,a5,80002a20 <kerneltrap+0x38>
    yield();
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	756080e7          	jalr	1878(ra) # 80002200 <yield>
    80002ab2:	b7bd                	j	80002a20 <kerneltrap+0x38>

0000000080002ab4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	1000                	addi	s0,sp,32
    80002abe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	f68080e7          	jalr	-152(ra) # 80001a28 <myproc>
  switch (n) {
    80002ac8:	4795                	li	a5,5
    80002aca:	0497e163          	bltu	a5,s1,80002b0c <argraw+0x58>
    80002ace:	048a                	slli	s1,s1,0x2
    80002ad0:	00006717          	auipc	a4,0x6
    80002ad4:	ab070713          	addi	a4,a4,-1360 # 80008580 <states.1711+0x2d8>
    80002ad8:	94ba                	add	s1,s1,a4
    80002ada:	409c                	lw	a5,0(s1)
    80002adc:	97ba                	add	a5,a5,a4
    80002ade:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae0:	6d3c                	ld	a5,88(a0)
    80002ae2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return p->trapframe->a1;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	7fa8                	ld	a0,120(a5)
    80002af2:	bfcd                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a2;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	63c8                	ld	a0,128(a5)
    80002af8:	b7f5                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a3;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	67c8                	ld	a0,136(a5)
    80002afe:	b7dd                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a4;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6bc8                	ld	a0,144(a5)
    80002b04:	b7c5                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a5;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	6fc8                	ld	a0,152(a5)
    80002b0a:	bfe9                	j	80002ae4 <argraw+0x30>
  panic("argraw");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	8dc50513          	addi	a0,a0,-1828 # 800083e8 <states.1711+0x140>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a34080e7          	jalr	-1484(ra) # 80000548 <panic>

0000000080002b1c <fetchaddr>:
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84aa                	mv	s1,a0
    80002b2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	efc080e7          	jalr	-260(ra) # 80001a28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b34:	653c                	ld	a5,72(a0)
    80002b36:	02f4f863          	bgeu	s1,a5,80002b66 <fetchaddr+0x4a>
    80002b3a:	00848713          	addi	a4,s1,8
    80002b3e:	02e7e663          	bltu	a5,a4,80002b6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b42:	46a1                	li	a3,8
    80002b44:	8626                	mv	a2,s1
    80002b46:	85ca                	mv	a1,s2
    80002b48:	6928                	ld	a0,80(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	c5e080e7          	jalr	-930(ra) # 800017a8 <copyin>
    80002b52:	00a03533          	snez	a0,a0
    80002b56:	40a00533          	neg	a0,a0
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6902                	ld	s2,0(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret
    return -1;
    80002b66:	557d                	li	a0,-1
    80002b68:	bfcd                	j	80002b5a <fetchaddr+0x3e>
    80002b6a:	557d                	li	a0,-1
    80002b6c:	b7fd                	j	80002b5a <fetchaddr+0x3e>

0000000080002b6e <fetchstr>:
{
    80002b6e:	7179                	addi	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	1800                	addi	s0,sp,48
    80002b7c:	892a                	mv	s2,a0
    80002b7e:	84ae                	mv	s1,a1
    80002b80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	ea6080e7          	jalr	-346(ra) # 80001a28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b8a:	86ce                	mv	a3,s3
    80002b8c:	864a                	mv	a2,s2
    80002b8e:	85a6                	mv	a1,s1
    80002b90:	6928                	ld	a0,80(a0)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	ca2080e7          	jalr	-862(ra) # 80001834 <copyinstr>
  if(err < 0)
    80002b9a:	00054763          	bltz	a0,80002ba8 <fetchstr+0x3a>
  return strlen(buf);
    80002b9e:	8526                	mv	a0,s1
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	33e080e7          	jalr	830(ra) # 80000ede <strlen>
}
    80002ba8:	70a2                	ld	ra,40(sp)
    80002baa:	7402                	ld	s0,32(sp)
    80002bac:	64e2                	ld	s1,24(sp)
    80002bae:	6942                	ld	s2,16(sp)
    80002bb0:	69a2                	ld	s3,8(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret

0000000080002bb6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	ef2080e7          	jalr	-270(ra) # 80002ab4 <argraw>
    80002bca:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bcc:	4501                	li	a0,0
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	addi	sp,sp,32
    80002bd6:	8082                	ret

0000000080002bd8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	1000                	addi	s0,sp,32
    80002be2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	ed0080e7          	jalr	-304(ra) # 80002ab4 <argraw>
    80002bec:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bee:	4501                	li	a0,0
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	addi	s0,sp,32
    80002c06:	84ae                	mv	s1,a1
    80002c08:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	eaa080e7          	jalr	-342(ra) # 80002ab4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c12:	864a                	mv	a2,s2
    80002c14:	85a6                	mv	a1,s1
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	f58080e7          	jalr	-168(ra) # 80002b6e <fetchstr>
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6902                	ld	s2,0(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <syscall>:
    "sys_trace"
};

void
syscall(void)
{
    80002c2a:	7179                	addi	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	e84a                	sd	s2,16(sp)
    80002c34:	e44e                	sd	s3,8(sp)
    80002c36:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	df0080e7          	jalr	-528(ra) # 80001a28 <myproc>
    80002c40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c42:	05853903          	ld	s2,88(a0)
    80002c46:	0a893783          	ld	a5,168(s2)
    80002c4a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4e:	37fd                	addiw	a5,a5,-1
    80002c50:	4759                	li	a4,22
    80002c52:	04f76b63          	bltu	a4,a5,80002ca8 <syscall+0x7e>
    80002c56:	00399713          	slli	a4,s3,0x3
    80002c5a:	00006797          	auipc	a5,0x6
    80002c5e:	93e78793          	addi	a5,a5,-1730 # 80008598 <syscalls>
    80002c62:	97ba                	add	a5,a5,a4
    80002c64:	639c                	ld	a5,0(a5)
    80002c66:	c3a9                	beqz	a5,80002ca8 <syscall+0x7e>
    p->trapframe->a0 = syscalls[num]();
    80002c68:	9782                	jalr	a5
    80002c6a:	06a93823          	sd	a0,112(s2)
    if((p->tracenum & (1 << num)) > 0){
    80002c6e:	4785                	li	a5,1
    80002c70:	0137973b          	sllw	a4,a5,s3
    80002c74:	1684a783          	lw	a5,360(s1)
    80002c78:	8ff9                	and	a5,a5,a4
    80002c7a:	2781                	sext.w	a5,a5
    80002c7c:	04f05563          	blez	a5,80002cc6 <syscall+0x9c>
      printf("%d: syscall %s -> %d \n",p->pid,syscall_name[num],p->trapframe->a0);
    80002c80:	6cb8                	ld	a4,88(s1)
    80002c82:	098e                	slli	s3,s3,0x3
    80002c84:	00006797          	auipc	a5,0x6
    80002c88:	91478793          	addi	a5,a5,-1772 # 80008598 <syscalls>
    80002c8c:	99be                	add	s3,s3,a5
    80002c8e:	7b34                	ld	a3,112(a4)
    80002c90:	0c09b603          	ld	a2,192(s3)
    80002c94:	5c8c                	lw	a1,56(s1)
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	75a50513          	addi	a0,a0,1882 # 800083f0 <states.1711+0x148>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8f4080e7          	jalr	-1804(ra) # 80000592 <printf>
    80002ca6:	a005                	j	80002cc6 <syscall+0x9c>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ca8:	86ce                	mv	a3,s3
    80002caa:	15848613          	addi	a2,s1,344
    80002cae:	5c8c                	lw	a1,56(s1)
    80002cb0:	00005517          	auipc	a0,0x5
    80002cb4:	75850513          	addi	a0,a0,1880 # 80008408 <states.1711+0x160>
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	8da080e7          	jalr	-1830(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cc0:	6cbc                	ld	a5,88(s1)
    80002cc2:	577d                	li	a4,-1
    80002cc4:	fbb8                	sd	a4,112(a5)
  }
}
    80002cc6:	70a2                	ld	ra,40(sp)
    80002cc8:	7402                	ld	s0,32(sp)
    80002cca:	64e2                	ld	s1,24(sp)
    80002ccc:	6942                	ld	s2,16(sp)
    80002cce:	69a2                	ld	s3,8(sp)
    80002cd0:	6145                	addi	sp,sp,48
    80002cd2:	8082                	ret

0000000080002cd4 <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cdc:	fec40593          	addi	a1,s0,-20
    80002ce0:	4501                	li	a0,0
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	ed4080e7          	jalr	-300(ra) # 80002bb6 <argint>
    return -1;
    80002cea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cec:	00054963          	bltz	a0,80002cfe <sys_exit+0x2a>
  exit(n);
    80002cf0:	fec42503          	lw	a0,-20(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	402080e7          	jalr	1026(ra) # 800020f6 <exit>
  return 0;  // not reached
    80002cfc:	4781                	li	a5,0
}
    80002cfe:	853e                	mv	a0,a5
    80002d00:	60e2                	ld	ra,24(sp)
    80002d02:	6442                	ld	s0,16(sp)
    80002d04:	6105                	addi	sp,sp,32
    80002d06:	8082                	ret

0000000080002d08 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d08:	1141                	addi	sp,sp,-16
    80002d0a:	e406                	sd	ra,8(sp)
    80002d0c:	e022                	sd	s0,0(sp)
    80002d0e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	d18080e7          	jalr	-744(ra) # 80001a28 <myproc>
}
    80002d18:	5d08                	lw	a0,56(a0)
    80002d1a:	60a2                	ld	ra,8(sp)
    80002d1c:	6402                	ld	s0,0(sp)
    80002d1e:	0141                	addi	sp,sp,16
    80002d20:	8082                	ret

0000000080002d22 <sys_fork>:

uint64
sys_fork(void)
{
    80002d22:	1141                	addi	sp,sp,-16
    80002d24:	e406                	sd	ra,8(sp)
    80002d26:	e022                	sd	s0,0(sp)
    80002d28:	0800                	addi	s0,sp,16
  return fork();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	0be080e7          	jalr	190(ra) # 80001de8 <fork>
}
    80002d32:	60a2                	ld	ra,8(sp)
    80002d34:	6402                	ld	s0,0(sp)
    80002d36:	0141                	addi	sp,sp,16
    80002d38:	8082                	ret

0000000080002d3a <sys_wait>:

uint64
sys_wait(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d42:	fe840593          	addi	a1,s0,-24
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	e90080e7          	jalr	-368(ra) # 80002bd8 <argaddr>
    80002d50:	87aa                	mv	a5,a0
    return -1;
    80002d52:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d54:	0007c863          	bltz	a5,80002d64 <sys_wait+0x2a>
  return wait(p);
    80002d58:	fe843503          	ld	a0,-24(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	55e080e7          	jalr	1374(ra) # 800022ba <wait>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d6c:	7179                	addi	sp,sp,-48
    80002d6e:	f406                	sd	ra,40(sp)
    80002d70:	f022                	sd	s0,32(sp)
    80002d72:	ec26                	sd	s1,24(sp)
    80002d74:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d76:	fdc40593          	addi	a1,s0,-36
    80002d7a:	4501                	li	a0,0
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	e3a080e7          	jalr	-454(ra) # 80002bb6 <argint>
    80002d84:	87aa                	mv	a5,a0
    return -1;
    80002d86:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d88:	0207c063          	bltz	a5,80002da8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	c9c080e7          	jalr	-868(ra) # 80001a28 <myproc>
    80002d94:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d96:	fdc42503          	lw	a0,-36(s0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	fda080e7          	jalr	-38(ra) # 80001d74 <growproc>
    80002da2:	00054863          	bltz	a0,80002db2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002da6:	8526                	mv	a0,s1
}
    80002da8:	70a2                	ld	ra,40(sp)
    80002daa:	7402                	ld	s0,32(sp)
    80002dac:	64e2                	ld	s1,24(sp)
    80002dae:	6145                	addi	sp,sp,48
    80002db0:	8082                	ret
    return -1;
    80002db2:	557d                	li	a0,-1
    80002db4:	bfd5                	j	80002da8 <sys_sbrk+0x3c>

0000000080002db6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002db6:	7139                	addi	sp,sp,-64
    80002db8:	fc06                	sd	ra,56(sp)
    80002dba:	f822                	sd	s0,48(sp)
    80002dbc:	f426                	sd	s1,40(sp)
    80002dbe:	f04a                	sd	s2,32(sp)
    80002dc0:	ec4e                	sd	s3,24(sp)
    80002dc2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dc4:	fcc40593          	addi	a1,s0,-52
    80002dc8:	4501                	li	a0,0
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	dec080e7          	jalr	-532(ra) # 80002bb6 <argint>
    return -1;
    80002dd2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dd4:	06054563          	bltz	a0,80002e3e <sys_sleep+0x88>
  acquire(&tickslock);
    80002dd8:	00015517          	auipc	a0,0x15
    80002ddc:	b9050513          	addi	a0,a0,-1136 # 80017968 <tickslock>
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	e7a080e7          	jalr	-390(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002de8:	00006917          	auipc	s2,0x6
    80002dec:	23892903          	lw	s2,568(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002df0:	fcc42783          	lw	a5,-52(s0)
    80002df4:	cf85                	beqz	a5,80002e2c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002df6:	00015997          	auipc	s3,0x15
    80002dfa:	b7298993          	addi	s3,s3,-1166 # 80017968 <tickslock>
    80002dfe:	00006497          	auipc	s1,0x6
    80002e02:	22248493          	addi	s1,s1,546 # 80009020 <ticks>
    if(myproc()->killed){
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	c22080e7          	jalr	-990(ra) # 80001a28 <myproc>
    80002e0e:	591c                	lw	a5,48(a0)
    80002e10:	ef9d                	bnez	a5,80002e4e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e12:	85ce                	mv	a1,s3
    80002e14:	8526                	mv	a0,s1
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	426080e7          	jalr	1062(ra) # 8000223c <sleep>
  while(ticks - ticks0 < n){
    80002e1e:	409c                	lw	a5,0(s1)
    80002e20:	412787bb          	subw	a5,a5,s2
    80002e24:	fcc42703          	lw	a4,-52(s0)
    80002e28:	fce7efe3          	bltu	a5,a4,80002e06 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e2c:	00015517          	auipc	a0,0x15
    80002e30:	b3c50513          	addi	a0,a0,-1220 # 80017968 <tickslock>
    80002e34:	ffffe097          	auipc	ra,0xffffe
    80002e38:	eda080e7          	jalr	-294(ra) # 80000d0e <release>
  return 0;
    80002e3c:	4781                	li	a5,0
}
    80002e3e:	853e                	mv	a0,a5
    80002e40:	70e2                	ld	ra,56(sp)
    80002e42:	7442                	ld	s0,48(sp)
    80002e44:	74a2                	ld	s1,40(sp)
    80002e46:	7902                	ld	s2,32(sp)
    80002e48:	69e2                	ld	s3,24(sp)
    80002e4a:	6121                	addi	sp,sp,64
    80002e4c:	8082                	ret
      release(&tickslock);
    80002e4e:	00015517          	auipc	a0,0x15
    80002e52:	b1a50513          	addi	a0,a0,-1254 # 80017968 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	eb8080e7          	jalr	-328(ra) # 80000d0e <release>
      return -1;
    80002e5e:	57fd                	li	a5,-1
    80002e60:	bff9                	j	80002e3e <sys_sleep+0x88>

0000000080002e62 <sys_kill>:

uint64
sys_kill(void)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e6a:	fec40593          	addi	a1,s0,-20
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	d46080e7          	jalr	-698(ra) # 80002bb6 <argint>
    80002e78:	87aa                	mv	a5,a0
    return -1;
    80002e7a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e7c:	0007c863          	bltz	a5,80002e8c <sys_kill+0x2a>
  return kill(pid);
    80002e80:	fec42503          	lw	a0,-20(s0)
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	5a8080e7          	jalr	1448(ra) # 8000242c <kill>
}
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e9e:	00015517          	auipc	a0,0x15
    80002ea2:	aca50513          	addi	a0,a0,-1334 # 80017968 <tickslock>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	db4080e7          	jalr	-588(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002eae:	00006497          	auipc	s1,0x6
    80002eb2:	1724a483          	lw	s1,370(s1) # 80009020 <ticks>
  release(&tickslock);
    80002eb6:	00015517          	auipc	a0,0x15
    80002eba:	ab250513          	addi	a0,a0,-1358 # 80017968 <tickslock>
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	e50080e7          	jalr	-432(ra) # 80000d0e <release>
  return xticks;
}
    80002ec6:	02049513          	slli	a0,s1,0x20
    80002eca:	9101                	srli	a0,a0,0x20
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <sys_trace>:

uint64
sys_trace(void){
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	1000                	addi	s0,sp,32
  int num;

  if(argint(0, &num) < 0)
    80002ede:	fec40593          	addi	a1,s0,-20
    80002ee2:	4501                	li	a0,0
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	cd2080e7          	jalr	-814(ra) # 80002bb6 <argint>
    80002eec:	87aa                	mv	a5,a0
    return -1;
    80002eee:	557d                	li	a0,-1
  if(argint(0, &num) < 0)
    80002ef0:	0007c863          	bltz	a5,80002f00 <sys_trace+0x2a>
  return trace(num);
    80002ef4:	fec42503          	lw	a0,-20(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	700080e7          	jalr	1792(ra) # 800025f8 <trace>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <sys_info>:

uint64 sys_info(){
    80002f08:	1101                	addi	sp,sp,-32
    80002f0a:	ec06                	sd	ra,24(sp)
    80002f0c:	e822                	sd	s0,16(sp)
    80002f0e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f10:	fe840593          	addi	a1,s0,-24
    80002f14:	4501                	li	a0,0
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	cc2080e7          	jalr	-830(ra) # 80002bd8 <argaddr>
    80002f1e:	87aa                	mv	a5,a0
    return -1;
    80002f20:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f22:	0007c863          	bltz	a5,80002f32 <sys_info+0x2a>
  return sysinfo(p);
    80002f26:	fe843503          	ld	a0,-24(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	748080e7          	jalr	1864(ra) # 80002672 <sysinfo>
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f3a:	7179                	addi	sp,sp,-48
    80002f3c:	f406                	sd	ra,40(sp)
    80002f3e:	f022                	sd	s0,32(sp)
    80002f40:	ec26                	sd	s1,24(sp)
    80002f42:	e84a                	sd	s2,16(sp)
    80002f44:	e44e                	sd	s3,8(sp)
    80002f46:	e052                	sd	s4,0(sp)
    80002f48:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f4a:	00005597          	auipc	a1,0x5
    80002f4e:	7fe58593          	addi	a1,a1,2046 # 80008748 <syscall_name+0xf0>
    80002f52:	00015517          	auipc	a0,0x15
    80002f56:	a2e50513          	addi	a0,a0,-1490 # 80017980 <bcache>
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	c70080e7          	jalr	-912(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f62:	0001d797          	auipc	a5,0x1d
    80002f66:	a1e78793          	addi	a5,a5,-1506 # 8001f980 <bcache+0x8000>
    80002f6a:	0001d717          	auipc	a4,0x1d
    80002f6e:	c7e70713          	addi	a4,a4,-898 # 8001fbe8 <bcache+0x8268>
    80002f72:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f76:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7a:	00015497          	auipc	s1,0x15
    80002f7e:	a1e48493          	addi	s1,s1,-1506 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002f82:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f84:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f86:	00005a17          	auipc	s4,0x5
    80002f8a:	7caa0a13          	addi	s4,s4,1994 # 80008750 <syscall_name+0xf8>
    b->next = bcache.head.next;
    80002f8e:	2b893783          	ld	a5,696(s2)
    80002f92:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f94:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f98:	85d2                	mv	a1,s4
    80002f9a:	01048513          	addi	a0,s1,16
    80002f9e:	00001097          	auipc	ra,0x1
    80002fa2:	4ac080e7          	jalr	1196(ra) # 8000444a <initsleeplock>
    bcache.head.next->prev = b;
    80002fa6:	2b893783          	ld	a5,696(s2)
    80002faa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fac:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb0:	45848493          	addi	s1,s1,1112
    80002fb4:	fd349de3          	bne	s1,s3,80002f8e <binit+0x54>
  }
}
    80002fb8:	70a2                	ld	ra,40(sp)
    80002fba:	7402                	ld	s0,32(sp)
    80002fbc:	64e2                	ld	s1,24(sp)
    80002fbe:	6942                	ld	s2,16(sp)
    80002fc0:	69a2                	ld	s3,8(sp)
    80002fc2:	6a02                	ld	s4,0(sp)
    80002fc4:	6145                	addi	sp,sp,48
    80002fc6:	8082                	ret

0000000080002fc8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fc8:	7179                	addi	sp,sp,-48
    80002fca:	f406                	sd	ra,40(sp)
    80002fcc:	f022                	sd	s0,32(sp)
    80002fce:	ec26                	sd	s1,24(sp)
    80002fd0:	e84a                	sd	s2,16(sp)
    80002fd2:	e44e                	sd	s3,8(sp)
    80002fd4:	1800                	addi	s0,sp,48
    80002fd6:	89aa                	mv	s3,a0
    80002fd8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fda:	00015517          	auipc	a0,0x15
    80002fde:	9a650513          	addi	a0,a0,-1626 # 80017980 <bcache>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	c78080e7          	jalr	-904(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fea:	0001d497          	auipc	s1,0x1d
    80002fee:	c4e4b483          	ld	s1,-946(s1) # 8001fc38 <bcache+0x82b8>
    80002ff2:	0001d797          	auipc	a5,0x1d
    80002ff6:	bf678793          	addi	a5,a5,-1034 # 8001fbe8 <bcache+0x8268>
    80002ffa:	02f48f63          	beq	s1,a5,80003038 <bread+0x70>
    80002ffe:	873e                	mv	a4,a5
    80003000:	a021                	j	80003008 <bread+0x40>
    80003002:	68a4                	ld	s1,80(s1)
    80003004:	02e48a63          	beq	s1,a4,80003038 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003008:	449c                	lw	a5,8(s1)
    8000300a:	ff379ce3          	bne	a5,s3,80003002 <bread+0x3a>
    8000300e:	44dc                	lw	a5,12(s1)
    80003010:	ff2799e3          	bne	a5,s2,80003002 <bread+0x3a>
      b->refcnt++;
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	2785                	addiw	a5,a5,1
    80003018:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301a:	00015517          	auipc	a0,0x15
    8000301e:	96650513          	addi	a0,a0,-1690 # 80017980 <bcache>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	cec080e7          	jalr	-788(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    8000302a:	01048513          	addi	a0,s1,16
    8000302e:	00001097          	auipc	ra,0x1
    80003032:	456080e7          	jalr	1110(ra) # 80004484 <acquiresleep>
      return b;
    80003036:	a8b9                	j	80003094 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003038:	0001d497          	auipc	s1,0x1d
    8000303c:	bf84b483          	ld	s1,-1032(s1) # 8001fc30 <bcache+0x82b0>
    80003040:	0001d797          	auipc	a5,0x1d
    80003044:	ba878793          	addi	a5,a5,-1112 # 8001fbe8 <bcache+0x8268>
    80003048:	00f48863          	beq	s1,a5,80003058 <bread+0x90>
    8000304c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000304e:	40bc                	lw	a5,64(s1)
    80003050:	cf81                	beqz	a5,80003068 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003052:	64a4                	ld	s1,72(s1)
    80003054:	fee49de3          	bne	s1,a4,8000304e <bread+0x86>
  panic("bget: no buffers");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	70050513          	addi	a0,a0,1792 # 80008758 <syscall_name+0x100>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4e8080e7          	jalr	1256(ra) # 80000548 <panic>
      b->dev = dev;
    80003068:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000306c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003070:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003074:	4785                	li	a5,1
    80003076:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003078:	00015517          	auipc	a0,0x15
    8000307c:	90850513          	addi	a0,a0,-1784 # 80017980 <bcache>
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	c8e080e7          	jalr	-882(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003088:	01048513          	addi	a0,s1,16
    8000308c:	00001097          	auipc	ra,0x1
    80003090:	3f8080e7          	jalr	1016(ra) # 80004484 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003094:	409c                	lw	a5,0(s1)
    80003096:	cb89                	beqz	a5,800030a8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003098:	8526                	mv	a0,s1
    8000309a:	70a2                	ld	ra,40(sp)
    8000309c:	7402                	ld	s0,32(sp)
    8000309e:	64e2                	ld	s1,24(sp)
    800030a0:	6942                	ld	s2,16(sp)
    800030a2:	69a2                	ld	s3,8(sp)
    800030a4:	6145                	addi	sp,sp,48
    800030a6:	8082                	ret
    virtio_disk_rw(b, 0);
    800030a8:	4581                	li	a1,0
    800030aa:	8526                	mv	a0,s1
    800030ac:	00003097          	auipc	ra,0x3
    800030b0:	f30080e7          	jalr	-208(ra) # 80005fdc <virtio_disk_rw>
    b->valid = 1;
    800030b4:	4785                	li	a5,1
    800030b6:	c09c                	sw	a5,0(s1)
  return b;
    800030b8:	b7c5                	j	80003098 <bread+0xd0>

00000000800030ba <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ba:	1101                	addi	sp,sp,-32
    800030bc:	ec06                	sd	ra,24(sp)
    800030be:	e822                	sd	s0,16(sp)
    800030c0:	e426                	sd	s1,8(sp)
    800030c2:	1000                	addi	s0,sp,32
    800030c4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030c6:	0541                	addi	a0,a0,16
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	456080e7          	jalr	1110(ra) # 8000451e <holdingsleep>
    800030d0:	cd01                	beqz	a0,800030e8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030d2:	4585                	li	a1,1
    800030d4:	8526                	mv	a0,s1
    800030d6:	00003097          	auipc	ra,0x3
    800030da:	f06080e7          	jalr	-250(ra) # 80005fdc <virtio_disk_rw>
}
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	64a2                	ld	s1,8(sp)
    800030e4:	6105                	addi	sp,sp,32
    800030e6:	8082                	ret
    panic("bwrite");
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	68850513          	addi	a0,a0,1672 # 80008770 <syscall_name+0x118>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	458080e7          	jalr	1112(ra) # 80000548 <panic>

00000000800030f8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030f8:	1101                	addi	sp,sp,-32
    800030fa:	ec06                	sd	ra,24(sp)
    800030fc:	e822                	sd	s0,16(sp)
    800030fe:	e426                	sd	s1,8(sp)
    80003100:	e04a                	sd	s2,0(sp)
    80003102:	1000                	addi	s0,sp,32
    80003104:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003106:	01050913          	addi	s2,a0,16
    8000310a:	854a                	mv	a0,s2
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	412080e7          	jalr	1042(ra) # 8000451e <holdingsleep>
    80003114:	c92d                	beqz	a0,80003186 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003116:	854a                	mv	a0,s2
    80003118:	00001097          	auipc	ra,0x1
    8000311c:	3c2080e7          	jalr	962(ra) # 800044da <releasesleep>

  acquire(&bcache.lock);
    80003120:	00015517          	auipc	a0,0x15
    80003124:	86050513          	addi	a0,a0,-1952 # 80017980 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b32080e7          	jalr	-1230(ra) # 80000c5a <acquire>
  b->refcnt--;
    80003130:	40bc                	lw	a5,64(s1)
    80003132:	37fd                	addiw	a5,a5,-1
    80003134:	0007871b          	sext.w	a4,a5
    80003138:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000313a:	eb05                	bnez	a4,8000316a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000313c:	68bc                	ld	a5,80(s1)
    8000313e:	64b8                	ld	a4,72(s1)
    80003140:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003142:	64bc                	ld	a5,72(s1)
    80003144:	68b8                	ld	a4,80(s1)
    80003146:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003148:	0001d797          	auipc	a5,0x1d
    8000314c:	83878793          	addi	a5,a5,-1992 # 8001f980 <bcache+0x8000>
    80003150:	2b87b703          	ld	a4,696(a5)
    80003154:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003156:	0001d717          	auipc	a4,0x1d
    8000315a:	a9270713          	addi	a4,a4,-1390 # 8001fbe8 <bcache+0x8268>
    8000315e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003160:	2b87b703          	ld	a4,696(a5)
    80003164:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003166:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000316a:	00015517          	auipc	a0,0x15
    8000316e:	81650513          	addi	a0,a0,-2026 # 80017980 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	b9c080e7          	jalr	-1124(ra) # 80000d0e <release>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6902                	ld	s2,0(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret
    panic("brelse");
    80003186:	00005517          	auipc	a0,0x5
    8000318a:	5f250513          	addi	a0,a0,1522 # 80008778 <syscall_name+0x120>
    8000318e:	ffffd097          	auipc	ra,0xffffd
    80003192:	3ba080e7          	jalr	954(ra) # 80000548 <panic>

0000000080003196 <bpin>:

void
bpin(struct buf *b) {
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	1000                	addi	s0,sp,32
    800031a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a2:	00014517          	auipc	a0,0x14
    800031a6:	7de50513          	addi	a0,a0,2014 # 80017980 <bcache>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	ab0080e7          	jalr	-1360(ra) # 80000c5a <acquire>
  b->refcnt++;
    800031b2:	40bc                	lw	a5,64(s1)
    800031b4:	2785                	addiw	a5,a5,1
    800031b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031b8:	00014517          	auipc	a0,0x14
    800031bc:	7c850513          	addi	a0,a0,1992 # 80017980 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	b4e080e7          	jalr	-1202(ra) # 80000d0e <release>
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6105                	addi	sp,sp,32
    800031d0:	8082                	ret

00000000800031d2 <bunpin>:

void
bunpin(struct buf *b) {
    800031d2:	1101                	addi	sp,sp,-32
    800031d4:	ec06                	sd	ra,24(sp)
    800031d6:	e822                	sd	s0,16(sp)
    800031d8:	e426                	sd	s1,8(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	7a250513          	addi	a0,a0,1954 # 80017980 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	a74080e7          	jalr	-1420(ra) # 80000c5a <acquire>
  b->refcnt--;
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	37fd                	addiw	a5,a5,-1
    800031f2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	78c50513          	addi	a0,a0,1932 # 80017980 <bcache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	b12080e7          	jalr	-1262(ra) # 80000d0e <release>
}
    80003204:	60e2                	ld	ra,24(sp)
    80003206:	6442                	ld	s0,16(sp)
    80003208:	64a2                	ld	s1,8(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret

000000008000320e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	e04a                	sd	s2,0(sp)
    80003218:	1000                	addi	s0,sp,32
    8000321a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000321c:	00d5d59b          	srliw	a1,a1,0xd
    80003220:	0001d797          	auipc	a5,0x1d
    80003224:	e3c7a783          	lw	a5,-452(a5) # 8002005c <sb+0x1c>
    80003228:	9dbd                	addw	a1,a1,a5
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	d9e080e7          	jalr	-610(ra) # 80002fc8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003232:	0074f713          	andi	a4,s1,7
    80003236:	4785                	li	a5,1
    80003238:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000323c:	14ce                	slli	s1,s1,0x33
    8000323e:	90d9                	srli	s1,s1,0x36
    80003240:	00950733          	add	a4,a0,s1
    80003244:	05874703          	lbu	a4,88(a4)
    80003248:	00e7f6b3          	and	a3,a5,a4
    8000324c:	c69d                	beqz	a3,8000327a <bfree+0x6c>
    8000324e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003250:	94aa                	add	s1,s1,a0
    80003252:	fff7c793          	not	a5,a5
    80003256:	8ff9                	and	a5,a5,a4
    80003258:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000325c:	00001097          	auipc	ra,0x1
    80003260:	100080e7          	jalr	256(ra) # 8000435c <log_write>
  brelse(bp);
    80003264:	854a                	mv	a0,s2
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	e92080e7          	jalr	-366(ra) # 800030f8 <brelse>
}
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6902                	ld	s2,0(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret
    panic("freeing free block");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	50650513          	addi	a0,a0,1286 # 80008780 <syscall_name+0x128>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2c6080e7          	jalr	710(ra) # 80000548 <panic>

000000008000328a <balloc>:
{
    8000328a:	711d                	addi	sp,sp,-96
    8000328c:	ec86                	sd	ra,88(sp)
    8000328e:	e8a2                	sd	s0,80(sp)
    80003290:	e4a6                	sd	s1,72(sp)
    80003292:	e0ca                	sd	s2,64(sp)
    80003294:	fc4e                	sd	s3,56(sp)
    80003296:	f852                	sd	s4,48(sp)
    80003298:	f456                	sd	s5,40(sp)
    8000329a:	f05a                	sd	s6,32(sp)
    8000329c:	ec5e                	sd	s7,24(sp)
    8000329e:	e862                	sd	s8,16(sp)
    800032a0:	e466                	sd	s9,8(sp)
    800032a2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032a4:	0001d797          	auipc	a5,0x1d
    800032a8:	da07a783          	lw	a5,-608(a5) # 80020044 <sb+0x4>
    800032ac:	cbd1                	beqz	a5,80003340 <balloc+0xb6>
    800032ae:	8baa                	mv	s7,a0
    800032b0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032b2:	0001db17          	auipc	s6,0x1d
    800032b6:	d8eb0b13          	addi	s6,s6,-626 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ba:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032bc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032be:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032c0:	6c89                	lui	s9,0x2
    800032c2:	a831                	j	800032de <balloc+0x54>
    brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	e32080e7          	jalr	-462(ra) # 800030f8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ce:	015c87bb          	addw	a5,s9,s5
    800032d2:	00078a9b          	sext.w	s5,a5
    800032d6:	004b2703          	lw	a4,4(s6)
    800032da:	06eaf363          	bgeu	s5,a4,80003340 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032de:	41fad79b          	sraiw	a5,s5,0x1f
    800032e2:	0137d79b          	srliw	a5,a5,0x13
    800032e6:	015787bb          	addw	a5,a5,s5
    800032ea:	40d7d79b          	sraiw	a5,a5,0xd
    800032ee:	01cb2583          	lw	a1,28(s6)
    800032f2:	9dbd                	addw	a1,a1,a5
    800032f4:	855e                	mv	a0,s7
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	cd2080e7          	jalr	-814(ra) # 80002fc8 <bread>
    800032fe:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	004b2503          	lw	a0,4(s6)
    80003304:	000a849b          	sext.w	s1,s5
    80003308:	8662                	mv	a2,s8
    8000330a:	faa4fde3          	bgeu	s1,a0,800032c4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000330e:	41f6579b          	sraiw	a5,a2,0x1f
    80003312:	01d7d69b          	srliw	a3,a5,0x1d
    80003316:	00c6873b          	addw	a4,a3,a2
    8000331a:	00777793          	andi	a5,a4,7
    8000331e:	9f95                	subw	a5,a5,a3
    80003320:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003324:	4037571b          	sraiw	a4,a4,0x3
    80003328:	00e906b3          	add	a3,s2,a4
    8000332c:	0586c683          	lbu	a3,88(a3)
    80003330:	00d7f5b3          	and	a1,a5,a3
    80003334:	cd91                	beqz	a1,80003350 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003336:	2605                	addiw	a2,a2,1
    80003338:	2485                	addiw	s1,s1,1
    8000333a:	fd4618e3          	bne	a2,s4,8000330a <balloc+0x80>
    8000333e:	b759                	j	800032c4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003340:	00005517          	auipc	a0,0x5
    80003344:	45850513          	addi	a0,a0,1112 # 80008798 <syscall_name+0x140>
    80003348:	ffffd097          	auipc	ra,0xffffd
    8000334c:	200080e7          	jalr	512(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003350:	974a                	add	a4,a4,s2
    80003352:	8fd5                	or	a5,a5,a3
    80003354:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003358:	854a                	mv	a0,s2
    8000335a:	00001097          	auipc	ra,0x1
    8000335e:	002080e7          	jalr	2(ra) # 8000435c <log_write>
        brelse(bp);
    80003362:	854a                	mv	a0,s2
    80003364:	00000097          	auipc	ra,0x0
    80003368:	d94080e7          	jalr	-620(ra) # 800030f8 <brelse>
  bp = bread(dev, bno);
    8000336c:	85a6                	mv	a1,s1
    8000336e:	855e                	mv	a0,s7
    80003370:	00000097          	auipc	ra,0x0
    80003374:	c58080e7          	jalr	-936(ra) # 80002fc8 <bread>
    80003378:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000337a:	40000613          	li	a2,1024
    8000337e:	4581                	li	a1,0
    80003380:	05850513          	addi	a0,a0,88
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	9d2080e7          	jalr	-1582(ra) # 80000d56 <memset>
  log_write(bp);
    8000338c:	854a                	mv	a0,s2
    8000338e:	00001097          	auipc	ra,0x1
    80003392:	fce080e7          	jalr	-50(ra) # 8000435c <log_write>
  brelse(bp);
    80003396:	854a                	mv	a0,s2
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	d60080e7          	jalr	-672(ra) # 800030f8 <brelse>
}
    800033a0:	8526                	mv	a0,s1
    800033a2:	60e6                	ld	ra,88(sp)
    800033a4:	6446                	ld	s0,80(sp)
    800033a6:	64a6                	ld	s1,72(sp)
    800033a8:	6906                	ld	s2,64(sp)
    800033aa:	79e2                	ld	s3,56(sp)
    800033ac:	7a42                	ld	s4,48(sp)
    800033ae:	7aa2                	ld	s5,40(sp)
    800033b0:	7b02                	ld	s6,32(sp)
    800033b2:	6be2                	ld	s7,24(sp)
    800033b4:	6c42                	ld	s8,16(sp)
    800033b6:	6ca2                	ld	s9,8(sp)
    800033b8:	6125                	addi	sp,sp,96
    800033ba:	8082                	ret

00000000800033bc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033bc:	7179                	addi	sp,sp,-48
    800033be:	f406                	sd	ra,40(sp)
    800033c0:	f022                	sd	s0,32(sp)
    800033c2:	ec26                	sd	s1,24(sp)
    800033c4:	e84a                	sd	s2,16(sp)
    800033c6:	e44e                	sd	s3,8(sp)
    800033c8:	e052                	sd	s4,0(sp)
    800033ca:	1800                	addi	s0,sp,48
    800033cc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033ce:	47ad                	li	a5,11
    800033d0:	04b7fe63          	bgeu	a5,a1,8000342c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033d4:	ff45849b          	addiw	s1,a1,-12
    800033d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033dc:	0ff00793          	li	a5,255
    800033e0:	0ae7e363          	bltu	a5,a4,80003486 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033e4:	08052583          	lw	a1,128(a0)
    800033e8:	c5ad                	beqz	a1,80003452 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033ea:	00092503          	lw	a0,0(s2)
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	bda080e7          	jalr	-1062(ra) # 80002fc8 <bread>
    800033f6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033f8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033fc:	02049593          	slli	a1,s1,0x20
    80003400:	9181                	srli	a1,a1,0x20
    80003402:	058a                	slli	a1,a1,0x2
    80003404:	00b784b3          	add	s1,a5,a1
    80003408:	0004a983          	lw	s3,0(s1)
    8000340c:	04098d63          	beqz	s3,80003466 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003410:	8552                	mv	a0,s4
    80003412:	00000097          	auipc	ra,0x0
    80003416:	ce6080e7          	jalr	-794(ra) # 800030f8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000341a:	854e                	mv	a0,s3
    8000341c:	70a2                	ld	ra,40(sp)
    8000341e:	7402                	ld	s0,32(sp)
    80003420:	64e2                	ld	s1,24(sp)
    80003422:	6942                	ld	s2,16(sp)
    80003424:	69a2                	ld	s3,8(sp)
    80003426:	6a02                	ld	s4,0(sp)
    80003428:	6145                	addi	sp,sp,48
    8000342a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000342c:	02059493          	slli	s1,a1,0x20
    80003430:	9081                	srli	s1,s1,0x20
    80003432:	048a                	slli	s1,s1,0x2
    80003434:	94aa                	add	s1,s1,a0
    80003436:	0504a983          	lw	s3,80(s1)
    8000343a:	fe0990e3          	bnez	s3,8000341a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000343e:	4108                	lw	a0,0(a0)
    80003440:	00000097          	auipc	ra,0x0
    80003444:	e4a080e7          	jalr	-438(ra) # 8000328a <balloc>
    80003448:	0005099b          	sext.w	s3,a0
    8000344c:	0534a823          	sw	s3,80(s1)
    80003450:	b7e9                	j	8000341a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003452:	4108                	lw	a0,0(a0)
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e36080e7          	jalr	-458(ra) # 8000328a <balloc>
    8000345c:	0005059b          	sext.w	a1,a0
    80003460:	08b92023          	sw	a1,128(s2)
    80003464:	b759                	j	800033ea <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003466:	00092503          	lw	a0,0(s2)
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	e20080e7          	jalr	-480(ra) # 8000328a <balloc>
    80003472:	0005099b          	sext.w	s3,a0
    80003476:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000347a:	8552                	mv	a0,s4
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	ee0080e7          	jalr	-288(ra) # 8000435c <log_write>
    80003484:	b771                	j	80003410 <bmap+0x54>
  panic("bmap: out of range");
    80003486:	00005517          	auipc	a0,0x5
    8000348a:	32a50513          	addi	a0,a0,810 # 800087b0 <syscall_name+0x158>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	0ba080e7          	jalr	186(ra) # 80000548 <panic>

0000000080003496 <iget>:
{
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	e052                	sd	s4,0(sp)
    800034a4:	1800                	addi	s0,sp,48
    800034a6:	89aa                	mv	s3,a0
    800034a8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034aa:	0001d517          	auipc	a0,0x1d
    800034ae:	bb650513          	addi	a0,a0,-1098 # 80020060 <icache>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	7a8080e7          	jalr	1960(ra) # 80000c5a <acquire>
  empty = 0;
    800034ba:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034bc:	0001d497          	auipc	s1,0x1d
    800034c0:	bbc48493          	addi	s1,s1,-1092 # 80020078 <icache+0x18>
    800034c4:	0001e697          	auipc	a3,0x1e
    800034c8:	64468693          	addi	a3,a3,1604 # 80021b08 <log>
    800034cc:	a039                	j	800034da <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ce:	02090b63          	beqz	s2,80003504 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034d2:	08848493          	addi	s1,s1,136
    800034d6:	02d48a63          	beq	s1,a3,8000350a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034da:	449c                	lw	a5,8(s1)
    800034dc:	fef059e3          	blez	a5,800034ce <iget+0x38>
    800034e0:	4098                	lw	a4,0(s1)
    800034e2:	ff3716e3          	bne	a4,s3,800034ce <iget+0x38>
    800034e6:	40d8                	lw	a4,4(s1)
    800034e8:	ff4713e3          	bne	a4,s4,800034ce <iget+0x38>
      ip->ref++;
    800034ec:	2785                	addiw	a5,a5,1
    800034ee:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034f0:	0001d517          	auipc	a0,0x1d
    800034f4:	b7050513          	addi	a0,a0,-1168 # 80020060 <icache>
    800034f8:	ffffe097          	auipc	ra,0xffffe
    800034fc:	816080e7          	jalr	-2026(ra) # 80000d0e <release>
      return ip;
    80003500:	8926                	mv	s2,s1
    80003502:	a03d                	j	80003530 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003504:	f7f9                	bnez	a5,800034d2 <iget+0x3c>
    80003506:	8926                	mv	s2,s1
    80003508:	b7e9                	j	800034d2 <iget+0x3c>
  if(empty == 0)
    8000350a:	02090c63          	beqz	s2,80003542 <iget+0xac>
  ip->dev = dev;
    8000350e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003512:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003516:	4785                	li	a5,1
    80003518:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003520:	0001d517          	auipc	a0,0x1d
    80003524:	b4050513          	addi	a0,a0,-1216 # 80020060 <icache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	7e6080e7          	jalr	2022(ra) # 80000d0e <release>
}
    80003530:	854a                	mv	a0,s2
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6a02                	ld	s4,0(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret
    panic("iget: no inodes");
    80003542:	00005517          	auipc	a0,0x5
    80003546:	28650513          	addi	a0,a0,646 # 800087c8 <syscall_name+0x170>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	ffe080e7          	jalr	-2(ra) # 80000548 <panic>

0000000080003552 <fsinit>:
fsinit(int dev) {
    80003552:	7179                	addi	sp,sp,-48
    80003554:	f406                	sd	ra,40(sp)
    80003556:	f022                	sd	s0,32(sp)
    80003558:	ec26                	sd	s1,24(sp)
    8000355a:	e84a                	sd	s2,16(sp)
    8000355c:	e44e                	sd	s3,8(sp)
    8000355e:	1800                	addi	s0,sp,48
    80003560:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003562:	4585                	li	a1,1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	a64080e7          	jalr	-1436(ra) # 80002fc8 <bread>
    8000356c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000356e:	0001d997          	auipc	s3,0x1d
    80003572:	ad298993          	addi	s3,s3,-1326 # 80020040 <sb>
    80003576:	02000613          	li	a2,32
    8000357a:	05850593          	addi	a1,a0,88
    8000357e:	854e                	mv	a0,s3
    80003580:	ffffe097          	auipc	ra,0xffffe
    80003584:	836080e7          	jalr	-1994(ra) # 80000db6 <memmove>
  brelse(bp);
    80003588:	8526                	mv	a0,s1
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	b6e080e7          	jalr	-1170(ra) # 800030f8 <brelse>
  if(sb.magic != FSMAGIC)
    80003592:	0009a703          	lw	a4,0(s3)
    80003596:	102037b7          	lui	a5,0x10203
    8000359a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000359e:	02f71263          	bne	a4,a5,800035c2 <fsinit+0x70>
  initlog(dev, &sb);
    800035a2:	0001d597          	auipc	a1,0x1d
    800035a6:	a9e58593          	addi	a1,a1,-1378 # 80020040 <sb>
    800035aa:	854a                	mv	a0,s2
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	b38080e7          	jalr	-1224(ra) # 800040e4 <initlog>
}
    800035b4:	70a2                	ld	ra,40(sp)
    800035b6:	7402                	ld	s0,32(sp)
    800035b8:	64e2                	ld	s1,24(sp)
    800035ba:	6942                	ld	s2,16(sp)
    800035bc:	69a2                	ld	s3,8(sp)
    800035be:	6145                	addi	sp,sp,48
    800035c0:	8082                	ret
    panic("invalid file system");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	21650513          	addi	a0,a0,534 # 800087d8 <syscall_name+0x180>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f7e080e7          	jalr	-130(ra) # 80000548 <panic>

00000000800035d2 <iinit>:
{
    800035d2:	7179                	addi	sp,sp,-48
    800035d4:	f406                	sd	ra,40(sp)
    800035d6:	f022                	sd	s0,32(sp)
    800035d8:	ec26                	sd	s1,24(sp)
    800035da:	e84a                	sd	s2,16(sp)
    800035dc:	e44e                	sd	s3,8(sp)
    800035de:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035e0:	00005597          	auipc	a1,0x5
    800035e4:	21058593          	addi	a1,a1,528 # 800087f0 <syscall_name+0x198>
    800035e8:	0001d517          	auipc	a0,0x1d
    800035ec:	a7850513          	addi	a0,a0,-1416 # 80020060 <icache>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	5da080e7          	jalr	1498(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f8:	0001d497          	auipc	s1,0x1d
    800035fc:	a9048493          	addi	s1,s1,-1392 # 80020088 <icache+0x28>
    80003600:	0001e997          	auipc	s3,0x1e
    80003604:	51898993          	addi	s3,s3,1304 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003608:	00005917          	auipc	s2,0x5
    8000360c:	1f090913          	addi	s2,s2,496 # 800087f8 <syscall_name+0x1a0>
    80003610:	85ca                	mv	a1,s2
    80003612:	8526                	mv	a0,s1
    80003614:	00001097          	auipc	ra,0x1
    80003618:	e36080e7          	jalr	-458(ra) # 8000444a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361c:	08848493          	addi	s1,s1,136
    80003620:	ff3498e3          	bne	s1,s3,80003610 <iinit+0x3e>
}
    80003624:	70a2                	ld	ra,40(sp)
    80003626:	7402                	ld	s0,32(sp)
    80003628:	64e2                	ld	s1,24(sp)
    8000362a:	6942                	ld	s2,16(sp)
    8000362c:	69a2                	ld	s3,8(sp)
    8000362e:	6145                	addi	sp,sp,48
    80003630:	8082                	ret

0000000080003632 <ialloc>:
{
    80003632:	715d                	addi	sp,sp,-80
    80003634:	e486                	sd	ra,72(sp)
    80003636:	e0a2                	sd	s0,64(sp)
    80003638:	fc26                	sd	s1,56(sp)
    8000363a:	f84a                	sd	s2,48(sp)
    8000363c:	f44e                	sd	s3,40(sp)
    8000363e:	f052                	sd	s4,32(sp)
    80003640:	ec56                	sd	s5,24(sp)
    80003642:	e85a                	sd	s6,16(sp)
    80003644:	e45e                	sd	s7,8(sp)
    80003646:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003648:	0001d717          	auipc	a4,0x1d
    8000364c:	a0472703          	lw	a4,-1532(a4) # 8002004c <sb+0xc>
    80003650:	4785                	li	a5,1
    80003652:	04e7fa63          	bgeu	a5,a4,800036a6 <ialloc+0x74>
    80003656:	8aaa                	mv	s5,a0
    80003658:	8bae                	mv	s7,a1
    8000365a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365c:	0001da17          	auipc	s4,0x1d
    80003660:	9e4a0a13          	addi	s4,s4,-1564 # 80020040 <sb>
    80003664:	00048b1b          	sext.w	s6,s1
    80003668:	0044d593          	srli	a1,s1,0x4
    8000366c:	018a2783          	lw	a5,24(s4)
    80003670:	9dbd                	addw	a1,a1,a5
    80003672:	8556                	mv	a0,s5
    80003674:	00000097          	auipc	ra,0x0
    80003678:	954080e7          	jalr	-1708(ra) # 80002fc8 <bread>
    8000367c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000367e:	05850993          	addi	s3,a0,88
    80003682:	00f4f793          	andi	a5,s1,15
    80003686:	079a                	slli	a5,a5,0x6
    80003688:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000368a:	00099783          	lh	a5,0(s3)
    8000368e:	c785                	beqz	a5,800036b6 <ialloc+0x84>
    brelse(bp);
    80003690:	00000097          	auipc	ra,0x0
    80003694:	a68080e7          	jalr	-1432(ra) # 800030f8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003698:	0485                	addi	s1,s1,1
    8000369a:	00ca2703          	lw	a4,12(s4)
    8000369e:	0004879b          	sext.w	a5,s1
    800036a2:	fce7e1e3          	bltu	a5,a4,80003664 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	15a50513          	addi	a0,a0,346 # 80008800 <syscall_name+0x1a8>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e9a080e7          	jalr	-358(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800036b6:	04000613          	li	a2,64
    800036ba:	4581                	li	a1,0
    800036bc:	854e                	mv	a0,s3
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	698080e7          	jalr	1688(ra) # 80000d56 <memset>
      dip->type = type;
    800036c6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	c90080e7          	jalr	-880(ra) # 8000435c <log_write>
      brelse(bp);
    800036d4:	854a                	mv	a0,s2
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	a22080e7          	jalr	-1502(ra) # 800030f8 <brelse>
      return iget(dev, inum);
    800036de:	85da                	mv	a1,s6
    800036e0:	8556                	mv	a0,s5
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	db4080e7          	jalr	-588(ra) # 80003496 <iget>
}
    800036ea:	60a6                	ld	ra,72(sp)
    800036ec:	6406                	ld	s0,64(sp)
    800036ee:	74e2                	ld	s1,56(sp)
    800036f0:	7942                	ld	s2,48(sp)
    800036f2:	79a2                	ld	s3,40(sp)
    800036f4:	7a02                	ld	s4,32(sp)
    800036f6:	6ae2                	ld	s5,24(sp)
    800036f8:	6b42                	ld	s6,16(sp)
    800036fa:	6ba2                	ld	s7,8(sp)
    800036fc:	6161                	addi	sp,sp,80
    800036fe:	8082                	ret

0000000080003700 <iupdate>:
{
    80003700:	1101                	addi	sp,sp,-32
    80003702:	ec06                	sd	ra,24(sp)
    80003704:	e822                	sd	s0,16(sp)
    80003706:	e426                	sd	s1,8(sp)
    80003708:	e04a                	sd	s2,0(sp)
    8000370a:	1000                	addi	s0,sp,32
    8000370c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000370e:	415c                	lw	a5,4(a0)
    80003710:	0047d79b          	srliw	a5,a5,0x4
    80003714:	0001d597          	auipc	a1,0x1d
    80003718:	9445a583          	lw	a1,-1724(a1) # 80020058 <sb+0x18>
    8000371c:	9dbd                	addw	a1,a1,a5
    8000371e:	4108                	lw	a0,0(a0)
    80003720:	00000097          	auipc	ra,0x0
    80003724:	8a8080e7          	jalr	-1880(ra) # 80002fc8 <bread>
    80003728:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000372a:	05850793          	addi	a5,a0,88
    8000372e:	40c8                	lw	a0,4(s1)
    80003730:	893d                	andi	a0,a0,15
    80003732:	051a                	slli	a0,a0,0x6
    80003734:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003736:	04449703          	lh	a4,68(s1)
    8000373a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000373e:	04649703          	lh	a4,70(s1)
    80003742:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003746:	04849703          	lh	a4,72(s1)
    8000374a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000374e:	04a49703          	lh	a4,74(s1)
    80003752:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003756:	44f8                	lw	a4,76(s1)
    80003758:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000375a:	03400613          	li	a2,52
    8000375e:	05048593          	addi	a1,s1,80
    80003762:	0531                	addi	a0,a0,12
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	652080e7          	jalr	1618(ra) # 80000db6 <memmove>
  log_write(bp);
    8000376c:	854a                	mv	a0,s2
    8000376e:	00001097          	auipc	ra,0x1
    80003772:	bee080e7          	jalr	-1042(ra) # 8000435c <log_write>
  brelse(bp);
    80003776:	854a                	mv	a0,s2
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	980080e7          	jalr	-1664(ra) # 800030f8 <brelse>
}
    80003780:	60e2                	ld	ra,24(sp)
    80003782:	6442                	ld	s0,16(sp)
    80003784:	64a2                	ld	s1,8(sp)
    80003786:	6902                	ld	s2,0(sp)
    80003788:	6105                	addi	sp,sp,32
    8000378a:	8082                	ret

000000008000378c <idup>:
{
    8000378c:	1101                	addi	sp,sp,-32
    8000378e:	ec06                	sd	ra,24(sp)
    80003790:	e822                	sd	s0,16(sp)
    80003792:	e426                	sd	s1,8(sp)
    80003794:	1000                	addi	s0,sp,32
    80003796:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003798:	0001d517          	auipc	a0,0x1d
    8000379c:	8c850513          	addi	a0,a0,-1848 # 80020060 <icache>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	4ba080e7          	jalr	1210(ra) # 80000c5a <acquire>
  ip->ref++;
    800037a8:	449c                	lw	a5,8(s1)
    800037aa:	2785                	addiw	a5,a5,1
    800037ac:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037ae:	0001d517          	auipc	a0,0x1d
    800037b2:	8b250513          	addi	a0,a0,-1870 # 80020060 <icache>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	558080e7          	jalr	1368(ra) # 80000d0e <release>
}
    800037be:	8526                	mv	a0,s1
    800037c0:	60e2                	ld	ra,24(sp)
    800037c2:	6442                	ld	s0,16(sp)
    800037c4:	64a2                	ld	s1,8(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret

00000000800037ca <ilock>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037d6:	c115                	beqz	a0,800037fa <ilock+0x30>
    800037d8:	84aa                	mv	s1,a0
    800037da:	451c                	lw	a5,8(a0)
    800037dc:	00f05f63          	blez	a5,800037fa <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e0:	0541                	addi	a0,a0,16
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	ca2080e7          	jalr	-862(ra) # 80004484 <acquiresleep>
  if(ip->valid == 0){
    800037ea:	40bc                	lw	a5,64(s1)
    800037ec:	cf99                	beqz	a5,8000380a <ilock+0x40>
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6902                	ld	s2,0(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret
    panic("ilock");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	01e50513          	addi	a0,a0,30 # 80008818 <syscall_name+0x1c0>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d46080e7          	jalr	-698(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380a:	40dc                	lw	a5,4(s1)
    8000380c:	0047d79b          	srliw	a5,a5,0x4
    80003810:	0001d597          	auipc	a1,0x1d
    80003814:	8485a583          	lw	a1,-1976(a1) # 80020058 <sb+0x18>
    80003818:	9dbd                	addw	a1,a1,a5
    8000381a:	4088                	lw	a0,0(s1)
    8000381c:	fffff097          	auipc	ra,0xfffff
    80003820:	7ac080e7          	jalr	1964(ra) # 80002fc8 <bread>
    80003824:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003826:	05850593          	addi	a1,a0,88
    8000382a:	40dc                	lw	a5,4(s1)
    8000382c:	8bbd                	andi	a5,a5,15
    8000382e:	079a                	slli	a5,a5,0x6
    80003830:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003832:	00059783          	lh	a5,0(a1)
    80003836:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000383a:	00259783          	lh	a5,2(a1)
    8000383e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003842:	00459783          	lh	a5,4(a1)
    80003846:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000384a:	00659783          	lh	a5,6(a1)
    8000384e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003852:	459c                	lw	a5,8(a1)
    80003854:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003856:	03400613          	li	a2,52
    8000385a:	05b1                	addi	a1,a1,12
    8000385c:	05048513          	addi	a0,s1,80
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	556080e7          	jalr	1366(ra) # 80000db6 <memmove>
    brelse(bp);
    80003868:	854a                	mv	a0,s2
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	88e080e7          	jalr	-1906(ra) # 800030f8 <brelse>
    ip->valid = 1;
    80003872:	4785                	li	a5,1
    80003874:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003876:	04449783          	lh	a5,68(s1)
    8000387a:	fbb5                	bnez	a5,800037ee <ilock+0x24>
      panic("ilock: no type");
    8000387c:	00005517          	auipc	a0,0x5
    80003880:	fa450513          	addi	a0,a0,-92 # 80008820 <syscall_name+0x1c8>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	cc4080e7          	jalr	-828(ra) # 80000548 <panic>

000000008000388c <iunlock>:
{
    8000388c:	1101                	addi	sp,sp,-32
    8000388e:	ec06                	sd	ra,24(sp)
    80003890:	e822                	sd	s0,16(sp)
    80003892:	e426                	sd	s1,8(sp)
    80003894:	e04a                	sd	s2,0(sp)
    80003896:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003898:	c905                	beqz	a0,800038c8 <iunlock+0x3c>
    8000389a:	84aa                	mv	s1,a0
    8000389c:	01050913          	addi	s2,a0,16
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	c7c080e7          	jalr	-900(ra) # 8000451e <holdingsleep>
    800038aa:	cd19                	beqz	a0,800038c8 <iunlock+0x3c>
    800038ac:	449c                	lw	a5,8(s1)
    800038ae:	00f05d63          	blez	a5,800038c8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b2:	854a                	mv	a0,s2
    800038b4:	00001097          	auipc	ra,0x1
    800038b8:	c26080e7          	jalr	-986(ra) # 800044da <releasesleep>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6902                	ld	s2,0(sp)
    800038c4:	6105                	addi	sp,sp,32
    800038c6:	8082                	ret
    panic("iunlock");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	f6850513          	addi	a0,a0,-152 # 80008830 <syscall_name+0x1d8>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	c78080e7          	jalr	-904(ra) # 80000548 <panic>

00000000800038d8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038d8:	7179                	addi	sp,sp,-48
    800038da:	f406                	sd	ra,40(sp)
    800038dc:	f022                	sd	s0,32(sp)
    800038de:	ec26                	sd	s1,24(sp)
    800038e0:	e84a                	sd	s2,16(sp)
    800038e2:	e44e                	sd	s3,8(sp)
    800038e4:	e052                	sd	s4,0(sp)
    800038e6:	1800                	addi	s0,sp,48
    800038e8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ea:	05050493          	addi	s1,a0,80
    800038ee:	08050913          	addi	s2,a0,128
    800038f2:	a021                	j	800038fa <itrunc+0x22>
    800038f4:	0491                	addi	s1,s1,4
    800038f6:	01248d63          	beq	s1,s2,80003910 <itrunc+0x38>
    if(ip->addrs[i]){
    800038fa:	408c                	lw	a1,0(s1)
    800038fc:	dde5                	beqz	a1,800038f4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038fe:	0009a503          	lw	a0,0(s3)
    80003902:	00000097          	auipc	ra,0x0
    80003906:	90c080e7          	jalr	-1780(ra) # 8000320e <bfree>
      ip->addrs[i] = 0;
    8000390a:	0004a023          	sw	zero,0(s1)
    8000390e:	b7dd                	j	800038f4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003910:	0809a583          	lw	a1,128(s3)
    80003914:	e185                	bnez	a1,80003934 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003916:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000391a:	854e                	mv	a0,s3
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	de4080e7          	jalr	-540(ra) # 80003700 <iupdate>
}
    80003924:	70a2                	ld	ra,40(sp)
    80003926:	7402                	ld	s0,32(sp)
    80003928:	64e2                	ld	s1,24(sp)
    8000392a:	6942                	ld	s2,16(sp)
    8000392c:	69a2                	ld	s3,8(sp)
    8000392e:	6a02                	ld	s4,0(sp)
    80003930:	6145                	addi	sp,sp,48
    80003932:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003934:	0009a503          	lw	a0,0(s3)
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	690080e7          	jalr	1680(ra) # 80002fc8 <bread>
    80003940:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003942:	05850493          	addi	s1,a0,88
    80003946:	45850913          	addi	s2,a0,1112
    8000394a:	a811                	j	8000395e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000394c:	0009a503          	lw	a0,0(s3)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	8be080e7          	jalr	-1858(ra) # 8000320e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003958:	0491                	addi	s1,s1,4
    8000395a:	01248563          	beq	s1,s2,80003964 <itrunc+0x8c>
      if(a[j])
    8000395e:	408c                	lw	a1,0(s1)
    80003960:	dde5                	beqz	a1,80003958 <itrunc+0x80>
    80003962:	b7ed                	j	8000394c <itrunc+0x74>
    brelse(bp);
    80003964:	8552                	mv	a0,s4
    80003966:	fffff097          	auipc	ra,0xfffff
    8000396a:	792080e7          	jalr	1938(ra) # 800030f8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000396e:	0809a583          	lw	a1,128(s3)
    80003972:	0009a503          	lw	a0,0(s3)
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	898080e7          	jalr	-1896(ra) # 8000320e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000397e:	0809a023          	sw	zero,128(s3)
    80003982:	bf51                	j	80003916 <itrunc+0x3e>

0000000080003984 <iput>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	e04a                	sd	s2,0(sp)
    8000398e:	1000                	addi	s0,sp,32
    80003990:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003992:	0001c517          	auipc	a0,0x1c
    80003996:	6ce50513          	addi	a0,a0,1742 # 80020060 <icache>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	2c0080e7          	jalr	704(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a2:	4498                	lw	a4,8(s1)
    800039a4:	4785                	li	a5,1
    800039a6:	02f70363          	beq	a4,a5,800039cc <iput+0x48>
  ip->ref--;
    800039aa:	449c                	lw	a5,8(s1)
    800039ac:	37fd                	addiw	a5,a5,-1
    800039ae:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039b0:	0001c517          	auipc	a0,0x1c
    800039b4:	6b050513          	addi	a0,a0,1712 # 80020060 <icache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	356080e7          	jalr	854(ra) # 80000d0e <release>
}
    800039c0:	60e2                	ld	ra,24(sp)
    800039c2:	6442                	ld	s0,16(sp)
    800039c4:	64a2                	ld	s1,8(sp)
    800039c6:	6902                	ld	s2,0(sp)
    800039c8:	6105                	addi	sp,sp,32
    800039ca:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039cc:	40bc                	lw	a5,64(s1)
    800039ce:	dff1                	beqz	a5,800039aa <iput+0x26>
    800039d0:	04a49783          	lh	a5,74(s1)
    800039d4:	fbf9                	bnez	a5,800039aa <iput+0x26>
    acquiresleep(&ip->lock);
    800039d6:	01048913          	addi	s2,s1,16
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	aa8080e7          	jalr	-1368(ra) # 80004484 <acquiresleep>
    release(&icache.lock);
    800039e4:	0001c517          	auipc	a0,0x1c
    800039e8:	67c50513          	addi	a0,a0,1660 # 80020060 <icache>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	322080e7          	jalr	802(ra) # 80000d0e <release>
    itrunc(ip);
    800039f4:	8526                	mv	a0,s1
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	ee2080e7          	jalr	-286(ra) # 800038d8 <itrunc>
    ip->type = 0;
    800039fe:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a02:	8526                	mv	a0,s1
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	cfc080e7          	jalr	-772(ra) # 80003700 <iupdate>
    ip->valid = 0;
    80003a0c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a10:	854a                	mv	a0,s2
    80003a12:	00001097          	auipc	ra,0x1
    80003a16:	ac8080e7          	jalr	-1336(ra) # 800044da <releasesleep>
    acquire(&icache.lock);
    80003a1a:	0001c517          	auipc	a0,0x1c
    80003a1e:	64650513          	addi	a0,a0,1606 # 80020060 <icache>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	238080e7          	jalr	568(ra) # 80000c5a <acquire>
    80003a2a:	b741                	j	800039aa <iput+0x26>

0000000080003a2c <iunlockput>:
{
    80003a2c:	1101                	addi	sp,sp,-32
    80003a2e:	ec06                	sd	ra,24(sp)
    80003a30:	e822                	sd	s0,16(sp)
    80003a32:	e426                	sd	s1,8(sp)
    80003a34:	1000                	addi	s0,sp,32
    80003a36:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	e54080e7          	jalr	-428(ra) # 8000388c <iunlock>
  iput(ip);
    80003a40:	8526                	mv	a0,s1
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	f42080e7          	jalr	-190(ra) # 80003984 <iput>
}
    80003a4a:	60e2                	ld	ra,24(sp)
    80003a4c:	6442                	ld	s0,16(sp)
    80003a4e:	64a2                	ld	s1,8(sp)
    80003a50:	6105                	addi	sp,sp,32
    80003a52:	8082                	ret

0000000080003a54 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a54:	1141                	addi	sp,sp,-16
    80003a56:	e422                	sd	s0,8(sp)
    80003a58:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a5a:	411c                	lw	a5,0(a0)
    80003a5c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a5e:	415c                	lw	a5,4(a0)
    80003a60:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a62:	04451783          	lh	a5,68(a0)
    80003a66:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a6a:	04a51783          	lh	a5,74(a0)
    80003a6e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a72:	04c56783          	lwu	a5,76(a0)
    80003a76:	e99c                	sd	a5,16(a1)
}
    80003a78:	6422                	ld	s0,8(sp)
    80003a7a:	0141                	addi	sp,sp,16
    80003a7c:	8082                	ret

0000000080003a7e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a7e:	457c                	lw	a5,76(a0)
    80003a80:	0ed7e863          	bltu	a5,a3,80003b70 <readi+0xf2>
{
    80003a84:	7159                	addi	sp,sp,-112
    80003a86:	f486                	sd	ra,104(sp)
    80003a88:	f0a2                	sd	s0,96(sp)
    80003a8a:	eca6                	sd	s1,88(sp)
    80003a8c:	e8ca                	sd	s2,80(sp)
    80003a8e:	e4ce                	sd	s3,72(sp)
    80003a90:	e0d2                	sd	s4,64(sp)
    80003a92:	fc56                	sd	s5,56(sp)
    80003a94:	f85a                	sd	s6,48(sp)
    80003a96:	f45e                	sd	s7,40(sp)
    80003a98:	f062                	sd	s8,32(sp)
    80003a9a:	ec66                	sd	s9,24(sp)
    80003a9c:	e86a                	sd	s10,16(sp)
    80003a9e:	e46e                	sd	s11,8(sp)
    80003aa0:	1880                	addi	s0,sp,112
    80003aa2:	8baa                	mv	s7,a0
    80003aa4:	8c2e                	mv	s8,a1
    80003aa6:	8ab2                	mv	s5,a2
    80003aa8:	84b6                	mv	s1,a3
    80003aaa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aac:	9f35                	addw	a4,a4,a3
    return 0;
    80003aae:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab0:	08d76f63          	bltu	a4,a3,80003b4e <readi+0xd0>
  if(off + n > ip->size)
    80003ab4:	00e7f463          	bgeu	a5,a4,80003abc <readi+0x3e>
    n = ip->size - off;
    80003ab8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003abc:	0a0b0863          	beqz	s6,80003b6c <readi+0xee>
    80003ac0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ac6:	5cfd                	li	s9,-1
    80003ac8:	a82d                	j	80003b02 <readi+0x84>
    80003aca:	020a1d93          	slli	s11,s4,0x20
    80003ace:	020ddd93          	srli	s11,s11,0x20
    80003ad2:	05890613          	addi	a2,s2,88
    80003ad6:	86ee                	mv	a3,s11
    80003ad8:	963a                	add	a2,a2,a4
    80003ada:	85d6                	mv	a1,s5
    80003adc:	8562                	mv	a0,s8
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	9c0080e7          	jalr	-1600(ra) # 8000249e <either_copyout>
    80003ae6:	05950d63          	beq	a0,s9,80003b40 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003aea:	854a                	mv	a0,s2
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	60c080e7          	jalr	1548(ra) # 800030f8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af4:	013a09bb          	addw	s3,s4,s3
    80003af8:	009a04bb          	addw	s1,s4,s1
    80003afc:	9aee                	add	s5,s5,s11
    80003afe:	0569f663          	bgeu	s3,s6,80003b4a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b02:	000ba903          	lw	s2,0(s7)
    80003b06:	00a4d59b          	srliw	a1,s1,0xa
    80003b0a:	855e                	mv	a0,s7
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	8b0080e7          	jalr	-1872(ra) # 800033bc <bmap>
    80003b14:	0005059b          	sext.w	a1,a0
    80003b18:	854a                	mv	a0,s2
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	4ae080e7          	jalr	1198(ra) # 80002fc8 <bread>
    80003b22:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b24:	3ff4f713          	andi	a4,s1,1023
    80003b28:	40ed07bb          	subw	a5,s10,a4
    80003b2c:	413b06bb          	subw	a3,s6,s3
    80003b30:	8a3e                	mv	s4,a5
    80003b32:	2781                	sext.w	a5,a5
    80003b34:	0006861b          	sext.w	a2,a3
    80003b38:	f8f679e3          	bgeu	a2,a5,80003aca <readi+0x4c>
    80003b3c:	8a36                	mv	s4,a3
    80003b3e:	b771                	j	80003aca <readi+0x4c>
      brelse(bp);
    80003b40:	854a                	mv	a0,s2
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	5b6080e7          	jalr	1462(ra) # 800030f8 <brelse>
  }
  return tot;
    80003b4a:	0009851b          	sext.w	a0,s3
}
    80003b4e:	70a6                	ld	ra,104(sp)
    80003b50:	7406                	ld	s0,96(sp)
    80003b52:	64e6                	ld	s1,88(sp)
    80003b54:	6946                	ld	s2,80(sp)
    80003b56:	69a6                	ld	s3,72(sp)
    80003b58:	6a06                	ld	s4,64(sp)
    80003b5a:	7ae2                	ld	s5,56(sp)
    80003b5c:	7b42                	ld	s6,48(sp)
    80003b5e:	7ba2                	ld	s7,40(sp)
    80003b60:	7c02                	ld	s8,32(sp)
    80003b62:	6ce2                	ld	s9,24(sp)
    80003b64:	6d42                	ld	s10,16(sp)
    80003b66:	6da2                	ld	s11,8(sp)
    80003b68:	6165                	addi	sp,sp,112
    80003b6a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6c:	89da                	mv	s3,s6
    80003b6e:	bff1                	j	80003b4a <readi+0xcc>
    return 0;
    80003b70:	4501                	li	a0,0
}
    80003b72:	8082                	ret

0000000080003b74 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b74:	457c                	lw	a5,76(a0)
    80003b76:	10d7e663          	bltu	a5,a3,80003c82 <writei+0x10e>
{
    80003b7a:	7159                	addi	sp,sp,-112
    80003b7c:	f486                	sd	ra,104(sp)
    80003b7e:	f0a2                	sd	s0,96(sp)
    80003b80:	eca6                	sd	s1,88(sp)
    80003b82:	e8ca                	sd	s2,80(sp)
    80003b84:	e4ce                	sd	s3,72(sp)
    80003b86:	e0d2                	sd	s4,64(sp)
    80003b88:	fc56                	sd	s5,56(sp)
    80003b8a:	f85a                	sd	s6,48(sp)
    80003b8c:	f45e                	sd	s7,40(sp)
    80003b8e:	f062                	sd	s8,32(sp)
    80003b90:	ec66                	sd	s9,24(sp)
    80003b92:	e86a                	sd	s10,16(sp)
    80003b94:	e46e                	sd	s11,8(sp)
    80003b96:	1880                	addi	s0,sp,112
    80003b98:	8baa                	mv	s7,a0
    80003b9a:	8c2e                	mv	s8,a1
    80003b9c:	8ab2                	mv	s5,a2
    80003b9e:	8936                	mv	s2,a3
    80003ba0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba2:	00e687bb          	addw	a5,a3,a4
    80003ba6:	0ed7e063          	bltu	a5,a3,80003c86 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003baa:	00043737          	lui	a4,0x43
    80003bae:	0cf76e63          	bltu	a4,a5,80003c8a <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb2:	0a0b0763          	beqz	s6,80003c60 <writei+0xec>
    80003bb6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bbc:	5cfd                	li	s9,-1
    80003bbe:	a091                	j	80003c02 <writei+0x8e>
    80003bc0:	02099d93          	slli	s11,s3,0x20
    80003bc4:	020ddd93          	srli	s11,s11,0x20
    80003bc8:	05848513          	addi	a0,s1,88
    80003bcc:	86ee                	mv	a3,s11
    80003bce:	8656                	mv	a2,s5
    80003bd0:	85e2                	mv	a1,s8
    80003bd2:	953a                	add	a0,a0,a4
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	920080e7          	jalr	-1760(ra) # 800024f4 <either_copyin>
    80003bdc:	07950263          	beq	a0,s9,80003c40 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	77a080e7          	jalr	1914(ra) # 8000435c <log_write>
    brelse(bp);
    80003bea:	8526                	mv	a0,s1
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	50c080e7          	jalr	1292(ra) # 800030f8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf4:	01498a3b          	addw	s4,s3,s4
    80003bf8:	0129893b          	addw	s2,s3,s2
    80003bfc:	9aee                	add	s5,s5,s11
    80003bfe:	056a7663          	bgeu	s4,s6,80003c4a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c02:	000ba483          	lw	s1,0(s7)
    80003c06:	00a9559b          	srliw	a1,s2,0xa
    80003c0a:	855e                	mv	a0,s7
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	7b0080e7          	jalr	1968(ra) # 800033bc <bmap>
    80003c14:	0005059b          	sext.w	a1,a0
    80003c18:	8526                	mv	a0,s1
    80003c1a:	fffff097          	auipc	ra,0xfffff
    80003c1e:	3ae080e7          	jalr	942(ra) # 80002fc8 <bread>
    80003c22:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c24:	3ff97713          	andi	a4,s2,1023
    80003c28:	40ed07bb          	subw	a5,s10,a4
    80003c2c:	414b06bb          	subw	a3,s6,s4
    80003c30:	89be                	mv	s3,a5
    80003c32:	2781                	sext.w	a5,a5
    80003c34:	0006861b          	sext.w	a2,a3
    80003c38:	f8f674e3          	bgeu	a2,a5,80003bc0 <writei+0x4c>
    80003c3c:	89b6                	mv	s3,a3
    80003c3e:	b749                	j	80003bc0 <writei+0x4c>
      brelse(bp);
    80003c40:	8526                	mv	a0,s1
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	4b6080e7          	jalr	1206(ra) # 800030f8 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c4a:	04cba783          	lw	a5,76(s7)
    80003c4e:	0127f463          	bgeu	a5,s2,80003c56 <writei+0xe2>
      ip->size = off;
    80003c52:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c56:	855e                	mv	a0,s7
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	aa8080e7          	jalr	-1368(ra) # 80003700 <iupdate>
  }

  return n;
    80003c60:	000b051b          	sext.w	a0,s6
}
    80003c64:	70a6                	ld	ra,104(sp)
    80003c66:	7406                	ld	s0,96(sp)
    80003c68:	64e6                	ld	s1,88(sp)
    80003c6a:	6946                	ld	s2,80(sp)
    80003c6c:	69a6                	ld	s3,72(sp)
    80003c6e:	6a06                	ld	s4,64(sp)
    80003c70:	7ae2                	ld	s5,56(sp)
    80003c72:	7b42                	ld	s6,48(sp)
    80003c74:	7ba2                	ld	s7,40(sp)
    80003c76:	7c02                	ld	s8,32(sp)
    80003c78:	6ce2                	ld	s9,24(sp)
    80003c7a:	6d42                	ld	s10,16(sp)
    80003c7c:	6da2                	ld	s11,8(sp)
    80003c7e:	6165                	addi	sp,sp,112
    80003c80:	8082                	ret
    return -1;
    80003c82:	557d                	li	a0,-1
}
    80003c84:	8082                	ret
    return -1;
    80003c86:	557d                	li	a0,-1
    80003c88:	bff1                	j	80003c64 <writei+0xf0>
    return -1;
    80003c8a:	557d                	li	a0,-1
    80003c8c:	bfe1                	j	80003c64 <writei+0xf0>

0000000080003c8e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c8e:	1141                	addi	sp,sp,-16
    80003c90:	e406                	sd	ra,8(sp)
    80003c92:	e022                	sd	s0,0(sp)
    80003c94:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c96:	4639                	li	a2,14
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	19a080e7          	jalr	410(ra) # 80000e32 <strncmp>
}
    80003ca0:	60a2                	ld	ra,8(sp)
    80003ca2:	6402                	ld	s0,0(sp)
    80003ca4:	0141                	addi	sp,sp,16
    80003ca6:	8082                	ret

0000000080003ca8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ca8:	7139                	addi	sp,sp,-64
    80003caa:	fc06                	sd	ra,56(sp)
    80003cac:	f822                	sd	s0,48(sp)
    80003cae:	f426                	sd	s1,40(sp)
    80003cb0:	f04a                	sd	s2,32(sp)
    80003cb2:	ec4e                	sd	s3,24(sp)
    80003cb4:	e852                	sd	s4,16(sp)
    80003cb6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cb8:	04451703          	lh	a4,68(a0)
    80003cbc:	4785                	li	a5,1
    80003cbe:	00f71a63          	bne	a4,a5,80003cd2 <dirlookup+0x2a>
    80003cc2:	892a                	mv	s2,a0
    80003cc4:	89ae                	mv	s3,a1
    80003cc6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc8:	457c                	lw	a5,76(a0)
    80003cca:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ccc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cce:	e79d                	bnez	a5,80003cfc <dirlookup+0x54>
    80003cd0:	a8a5                	j	80003d48 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd2:	00005517          	auipc	a0,0x5
    80003cd6:	b6650513          	addi	a0,a0,-1178 # 80008838 <syscall_name+0x1e0>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	86e080e7          	jalr	-1938(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003ce2:	00005517          	auipc	a0,0x5
    80003ce6:	b6e50513          	addi	a0,a0,-1170 # 80008850 <syscall_name+0x1f8>
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	85e080e7          	jalr	-1954(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf2:	24c1                	addiw	s1,s1,16
    80003cf4:	04c92783          	lw	a5,76(s2)
    80003cf8:	04f4f763          	bgeu	s1,a5,80003d46 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfc:	4741                	li	a4,16
    80003cfe:	86a6                	mv	a3,s1
    80003d00:	fc040613          	addi	a2,s0,-64
    80003d04:	4581                	li	a1,0
    80003d06:	854a                	mv	a0,s2
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	d76080e7          	jalr	-650(ra) # 80003a7e <readi>
    80003d10:	47c1                	li	a5,16
    80003d12:	fcf518e3          	bne	a0,a5,80003ce2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d16:	fc045783          	lhu	a5,-64(s0)
    80003d1a:	dfe1                	beqz	a5,80003cf2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d1c:	fc240593          	addi	a1,s0,-62
    80003d20:	854e                	mv	a0,s3
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	f6c080e7          	jalr	-148(ra) # 80003c8e <namecmp>
    80003d2a:	f561                	bnez	a0,80003cf2 <dirlookup+0x4a>
      if(poff)
    80003d2c:	000a0463          	beqz	s4,80003d34 <dirlookup+0x8c>
        *poff = off;
    80003d30:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d34:	fc045583          	lhu	a1,-64(s0)
    80003d38:	00092503          	lw	a0,0(s2)
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	75a080e7          	jalr	1882(ra) # 80003496 <iget>
    80003d44:	a011                	j	80003d48 <dirlookup+0xa0>
  return 0;
    80003d46:	4501                	li	a0,0
}
    80003d48:	70e2                	ld	ra,56(sp)
    80003d4a:	7442                	ld	s0,48(sp)
    80003d4c:	74a2                	ld	s1,40(sp)
    80003d4e:	7902                	ld	s2,32(sp)
    80003d50:	69e2                	ld	s3,24(sp)
    80003d52:	6a42                	ld	s4,16(sp)
    80003d54:	6121                	addi	sp,sp,64
    80003d56:	8082                	ret

0000000080003d58 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d58:	711d                	addi	sp,sp,-96
    80003d5a:	ec86                	sd	ra,88(sp)
    80003d5c:	e8a2                	sd	s0,80(sp)
    80003d5e:	e4a6                	sd	s1,72(sp)
    80003d60:	e0ca                	sd	s2,64(sp)
    80003d62:	fc4e                	sd	s3,56(sp)
    80003d64:	f852                	sd	s4,48(sp)
    80003d66:	f456                	sd	s5,40(sp)
    80003d68:	f05a                	sd	s6,32(sp)
    80003d6a:	ec5e                	sd	s7,24(sp)
    80003d6c:	e862                	sd	s8,16(sp)
    80003d6e:	e466                	sd	s9,8(sp)
    80003d70:	1080                	addi	s0,sp,96
    80003d72:	84aa                	mv	s1,a0
    80003d74:	8b2e                	mv	s6,a1
    80003d76:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d78:	00054703          	lbu	a4,0(a0)
    80003d7c:	02f00793          	li	a5,47
    80003d80:	02f70363          	beq	a4,a5,80003da6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d84:	ffffe097          	auipc	ra,0xffffe
    80003d88:	ca4080e7          	jalr	-860(ra) # 80001a28 <myproc>
    80003d8c:	15053503          	ld	a0,336(a0)
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	9fc080e7          	jalr	-1540(ra) # 8000378c <idup>
    80003d98:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d9a:	02f00913          	li	s2,47
  len = path - s;
    80003d9e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003da0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da2:	4c05                	li	s8,1
    80003da4:	a865                	j	80003e5c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003da6:	4585                	li	a1,1
    80003da8:	4505                	li	a0,1
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	6ec080e7          	jalr	1772(ra) # 80003496 <iget>
    80003db2:	89aa                	mv	s3,a0
    80003db4:	b7dd                	j	80003d9a <namex+0x42>
      iunlockput(ip);
    80003db6:	854e                	mv	a0,s3
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	c74080e7          	jalr	-908(ra) # 80003a2c <iunlockput>
      return 0;
    80003dc0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	60e6                	ld	ra,88(sp)
    80003dc6:	6446                	ld	s0,80(sp)
    80003dc8:	64a6                	ld	s1,72(sp)
    80003dca:	6906                	ld	s2,64(sp)
    80003dcc:	79e2                	ld	s3,56(sp)
    80003dce:	7a42                	ld	s4,48(sp)
    80003dd0:	7aa2                	ld	s5,40(sp)
    80003dd2:	7b02                	ld	s6,32(sp)
    80003dd4:	6be2                	ld	s7,24(sp)
    80003dd6:	6c42                	ld	s8,16(sp)
    80003dd8:	6ca2                	ld	s9,8(sp)
    80003dda:	6125                	addi	sp,sp,96
    80003ddc:	8082                	ret
      iunlock(ip);
    80003dde:	854e                	mv	a0,s3
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	aac080e7          	jalr	-1364(ra) # 8000388c <iunlock>
      return ip;
    80003de8:	bfe9                	j	80003dc2 <namex+0x6a>
      iunlockput(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	c40080e7          	jalr	-960(ra) # 80003a2c <iunlockput>
      return 0;
    80003df4:	89d2                	mv	s3,s4
    80003df6:	b7f1                	j	80003dc2 <namex+0x6a>
  len = path - s;
    80003df8:	40b48633          	sub	a2,s1,a1
    80003dfc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e00:	094cd463          	bge	s9,s4,80003e88 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e04:	4639                	li	a2,14
    80003e06:	8556                	mv	a0,s5
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	fae080e7          	jalr	-82(ra) # 80000db6 <memmove>
  while(*path == '/')
    80003e10:	0004c783          	lbu	a5,0(s1)
    80003e14:	01279763          	bne	a5,s2,80003e22 <namex+0xca>
    path++;
    80003e18:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e1a:	0004c783          	lbu	a5,0(s1)
    80003e1e:	ff278de3          	beq	a5,s2,80003e18 <namex+0xc0>
    ilock(ip);
    80003e22:	854e                	mv	a0,s3
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	9a6080e7          	jalr	-1626(ra) # 800037ca <ilock>
    if(ip->type != T_DIR){
    80003e2c:	04499783          	lh	a5,68(s3)
    80003e30:	f98793e3          	bne	a5,s8,80003db6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e34:	000b0563          	beqz	s6,80003e3e <namex+0xe6>
    80003e38:	0004c783          	lbu	a5,0(s1)
    80003e3c:	d3cd                	beqz	a5,80003dde <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e3e:	865e                	mv	a2,s7
    80003e40:	85d6                	mv	a1,s5
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	e64080e7          	jalr	-412(ra) # 80003ca8 <dirlookup>
    80003e4c:	8a2a                	mv	s4,a0
    80003e4e:	dd51                	beqz	a0,80003dea <namex+0x92>
    iunlockput(ip);
    80003e50:	854e                	mv	a0,s3
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	bda080e7          	jalr	-1062(ra) # 80003a2c <iunlockput>
    ip = next;
    80003e5a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	05279763          	bne	a5,s2,80003eae <namex+0x156>
    path++;
    80003e64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e66:	0004c783          	lbu	a5,0(s1)
    80003e6a:	ff278de3          	beq	a5,s2,80003e64 <namex+0x10c>
  if(*path == 0)
    80003e6e:	c79d                	beqz	a5,80003e9c <namex+0x144>
    path++;
    80003e70:	85a6                	mv	a1,s1
  len = path - s;
    80003e72:	8a5e                	mv	s4,s7
    80003e74:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e76:	01278963          	beq	a5,s2,80003e88 <namex+0x130>
    80003e7a:	dfbd                	beqz	a5,80003df8 <namex+0xa0>
    path++;
    80003e7c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e7e:	0004c783          	lbu	a5,0(s1)
    80003e82:	ff279ce3          	bne	a5,s2,80003e7a <namex+0x122>
    80003e86:	bf8d                	j	80003df8 <namex+0xa0>
    memmove(name, s, len);
    80003e88:	2601                	sext.w	a2,a2
    80003e8a:	8556                	mv	a0,s5
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	f2a080e7          	jalr	-214(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003e94:	9a56                	add	s4,s4,s5
    80003e96:	000a0023          	sb	zero,0(s4)
    80003e9a:	bf9d                	j	80003e10 <namex+0xb8>
  if(nameiparent){
    80003e9c:	f20b03e3          	beqz	s6,80003dc2 <namex+0x6a>
    iput(ip);
    80003ea0:	854e                	mv	a0,s3
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	ae2080e7          	jalr	-1310(ra) # 80003984 <iput>
    return 0;
    80003eaa:	4981                	li	s3,0
    80003eac:	bf19                	j	80003dc2 <namex+0x6a>
  if(*path == 0)
    80003eae:	d7fd                	beqz	a5,80003e9c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eb0:	0004c783          	lbu	a5,0(s1)
    80003eb4:	85a6                	mv	a1,s1
    80003eb6:	b7d1                	j	80003e7a <namex+0x122>

0000000080003eb8 <dirlink>:
{
    80003eb8:	7139                	addi	sp,sp,-64
    80003eba:	fc06                	sd	ra,56(sp)
    80003ebc:	f822                	sd	s0,48(sp)
    80003ebe:	f426                	sd	s1,40(sp)
    80003ec0:	f04a                	sd	s2,32(sp)
    80003ec2:	ec4e                	sd	s3,24(sp)
    80003ec4:	e852                	sd	s4,16(sp)
    80003ec6:	0080                	addi	s0,sp,64
    80003ec8:	892a                	mv	s2,a0
    80003eca:	8a2e                	mv	s4,a1
    80003ecc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ece:	4601                	li	a2,0
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	dd8080e7          	jalr	-552(ra) # 80003ca8 <dirlookup>
    80003ed8:	e93d                	bnez	a0,80003f4e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eda:	04c92483          	lw	s1,76(s2)
    80003ede:	c49d                	beqz	s1,80003f0c <dirlink+0x54>
    80003ee0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee2:	4741                	li	a4,16
    80003ee4:	86a6                	mv	a3,s1
    80003ee6:	fc040613          	addi	a2,s0,-64
    80003eea:	4581                	li	a1,0
    80003eec:	854a                	mv	a0,s2
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	b90080e7          	jalr	-1136(ra) # 80003a7e <readi>
    80003ef6:	47c1                	li	a5,16
    80003ef8:	06f51163          	bne	a0,a5,80003f5a <dirlink+0xa2>
    if(de.inum == 0)
    80003efc:	fc045783          	lhu	a5,-64(s0)
    80003f00:	c791                	beqz	a5,80003f0c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f02:	24c1                	addiw	s1,s1,16
    80003f04:	04c92783          	lw	a5,76(s2)
    80003f08:	fcf4ede3          	bltu	s1,a5,80003ee2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f0c:	4639                	li	a2,14
    80003f0e:	85d2                	mv	a1,s4
    80003f10:	fc240513          	addi	a0,s0,-62
    80003f14:	ffffd097          	auipc	ra,0xffffd
    80003f18:	f5a080e7          	jalr	-166(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003f1c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f20:	4741                	li	a4,16
    80003f22:	86a6                	mv	a3,s1
    80003f24:	fc040613          	addi	a2,s0,-64
    80003f28:	4581                	li	a1,0
    80003f2a:	854a                	mv	a0,s2
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	c48080e7          	jalr	-952(ra) # 80003b74 <writei>
    80003f34:	872a                	mv	a4,a0
    80003f36:	47c1                	li	a5,16
  return 0;
    80003f38:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3a:	02f71863          	bne	a4,a5,80003f6a <dirlink+0xb2>
}
    80003f3e:	70e2                	ld	ra,56(sp)
    80003f40:	7442                	ld	s0,48(sp)
    80003f42:	74a2                	ld	s1,40(sp)
    80003f44:	7902                	ld	s2,32(sp)
    80003f46:	69e2                	ld	s3,24(sp)
    80003f48:	6a42                	ld	s4,16(sp)
    80003f4a:	6121                	addi	sp,sp,64
    80003f4c:	8082                	ret
    iput(ip);
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	a36080e7          	jalr	-1482(ra) # 80003984 <iput>
    return -1;
    80003f56:	557d                	li	a0,-1
    80003f58:	b7dd                	j	80003f3e <dirlink+0x86>
      panic("dirlink read");
    80003f5a:	00005517          	auipc	a0,0x5
    80003f5e:	90650513          	addi	a0,a0,-1786 # 80008860 <syscall_name+0x208>
    80003f62:	ffffc097          	auipc	ra,0xffffc
    80003f66:	5e6080e7          	jalr	1510(ra) # 80000548 <panic>
    panic("dirlink");
    80003f6a:	00005517          	auipc	a0,0x5
    80003f6e:	a1650513          	addi	a0,a0,-1514 # 80008980 <syscall_name+0x328>
    80003f72:	ffffc097          	auipc	ra,0xffffc
    80003f76:	5d6080e7          	jalr	1494(ra) # 80000548 <panic>

0000000080003f7a <namei>:

struct inode*
namei(char *path)
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f82:	fe040613          	addi	a2,s0,-32
    80003f86:	4581                	li	a1,0
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	dd0080e7          	jalr	-560(ra) # 80003d58 <namex>
}
    80003f90:	60e2                	ld	ra,24(sp)
    80003f92:	6442                	ld	s0,16(sp)
    80003f94:	6105                	addi	sp,sp,32
    80003f96:	8082                	ret

0000000080003f98 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f98:	1141                	addi	sp,sp,-16
    80003f9a:	e406                	sd	ra,8(sp)
    80003f9c:	e022                	sd	s0,0(sp)
    80003f9e:	0800                	addi	s0,sp,16
    80003fa0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fa2:	4585                	li	a1,1
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	db4080e7          	jalr	-588(ra) # 80003d58 <namex>
}
    80003fac:	60a2                	ld	ra,8(sp)
    80003fae:	6402                	ld	s0,0(sp)
    80003fb0:	0141                	addi	sp,sp,16
    80003fb2:	8082                	ret

0000000080003fb4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb4:	1101                	addi	sp,sp,-32
    80003fb6:	ec06                	sd	ra,24(sp)
    80003fb8:	e822                	sd	s0,16(sp)
    80003fba:	e426                	sd	s1,8(sp)
    80003fbc:	e04a                	sd	s2,0(sp)
    80003fbe:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fc0:	0001e917          	auipc	s2,0x1e
    80003fc4:	b4890913          	addi	s2,s2,-1208 # 80021b08 <log>
    80003fc8:	01892583          	lw	a1,24(s2)
    80003fcc:	02892503          	lw	a0,40(s2)
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	ff8080e7          	jalr	-8(ra) # 80002fc8 <bread>
    80003fd8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fda:	02c92683          	lw	a3,44(s2)
    80003fde:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fe0:	02d05763          	blez	a3,8000400e <write_head+0x5a>
    80003fe4:	0001e797          	auipc	a5,0x1e
    80003fe8:	b5478793          	addi	a5,a5,-1196 # 80021b38 <log+0x30>
    80003fec:	05c50713          	addi	a4,a0,92
    80003ff0:	36fd                	addiw	a3,a3,-1
    80003ff2:	1682                	slli	a3,a3,0x20
    80003ff4:	9281                	srli	a3,a3,0x20
    80003ff6:	068a                	slli	a3,a3,0x2
    80003ff8:	0001e617          	auipc	a2,0x1e
    80003ffc:	b4460613          	addi	a2,a2,-1212 # 80021b3c <log+0x34>
    80004000:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004002:	4390                	lw	a2,0(a5)
    80004004:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004006:	0791                	addi	a5,a5,4
    80004008:	0711                	addi	a4,a4,4
    8000400a:	fed79ce3          	bne	a5,a3,80004002 <write_head+0x4e>
  }
  bwrite(buf);
    8000400e:	8526                	mv	a0,s1
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	0aa080e7          	jalr	170(ra) # 800030ba <bwrite>
  brelse(buf);
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	0de080e7          	jalr	222(ra) # 800030f8 <brelse>
}
    80004022:	60e2                	ld	ra,24(sp)
    80004024:	6442                	ld	s0,16(sp)
    80004026:	64a2                	ld	s1,8(sp)
    80004028:	6902                	ld	s2,0(sp)
    8000402a:	6105                	addi	sp,sp,32
    8000402c:	8082                	ret

000000008000402e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402e:	0001e797          	auipc	a5,0x1e
    80004032:	b067a783          	lw	a5,-1274(a5) # 80021b34 <log+0x2c>
    80004036:	0af05663          	blez	a5,800040e2 <install_trans+0xb4>
{
    8000403a:	7139                	addi	sp,sp,-64
    8000403c:	fc06                	sd	ra,56(sp)
    8000403e:	f822                	sd	s0,48(sp)
    80004040:	f426                	sd	s1,40(sp)
    80004042:	f04a                	sd	s2,32(sp)
    80004044:	ec4e                	sd	s3,24(sp)
    80004046:	e852                	sd	s4,16(sp)
    80004048:	e456                	sd	s5,8(sp)
    8000404a:	0080                	addi	s0,sp,64
    8000404c:	0001ea97          	auipc	s5,0x1e
    80004050:	aeca8a93          	addi	s5,s5,-1300 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004056:	0001e997          	auipc	s3,0x1e
    8000405a:	ab298993          	addi	s3,s3,-1358 # 80021b08 <log>
    8000405e:	0189a583          	lw	a1,24(s3)
    80004062:	014585bb          	addw	a1,a1,s4
    80004066:	2585                	addiw	a1,a1,1
    80004068:	0289a503          	lw	a0,40(s3)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	f5c080e7          	jalr	-164(ra) # 80002fc8 <bread>
    80004074:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004076:	000aa583          	lw	a1,0(s5)
    8000407a:	0289a503          	lw	a0,40(s3)
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	f4a080e7          	jalr	-182(ra) # 80002fc8 <bread>
    80004086:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004088:	40000613          	li	a2,1024
    8000408c:	05890593          	addi	a1,s2,88
    80004090:	05850513          	addi	a0,a0,88
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	d22080e7          	jalr	-734(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	01c080e7          	jalr	28(ra) # 800030ba <bwrite>
    bunpin(dbuf);
    800040a6:	8526                	mv	a0,s1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	12a080e7          	jalr	298(ra) # 800031d2 <bunpin>
    brelse(lbuf);
    800040b0:	854a                	mv	a0,s2
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	046080e7          	jalr	70(ra) # 800030f8 <brelse>
    brelse(dbuf);
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	03c080e7          	jalr	60(ra) # 800030f8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c4:	2a05                	addiw	s4,s4,1
    800040c6:	0a91                	addi	s5,s5,4
    800040c8:	02c9a783          	lw	a5,44(s3)
    800040cc:	f8fa49e3          	blt	s4,a5,8000405e <install_trans+0x30>
}
    800040d0:	70e2                	ld	ra,56(sp)
    800040d2:	7442                	ld	s0,48(sp)
    800040d4:	74a2                	ld	s1,40(sp)
    800040d6:	7902                	ld	s2,32(sp)
    800040d8:	69e2                	ld	s3,24(sp)
    800040da:	6a42                	ld	s4,16(sp)
    800040dc:	6aa2                	ld	s5,8(sp)
    800040de:	6121                	addi	sp,sp,64
    800040e0:	8082                	ret
    800040e2:	8082                	ret

00000000800040e4 <initlog>:
{
    800040e4:	7179                	addi	sp,sp,-48
    800040e6:	f406                	sd	ra,40(sp)
    800040e8:	f022                	sd	s0,32(sp)
    800040ea:	ec26                	sd	s1,24(sp)
    800040ec:	e84a                	sd	s2,16(sp)
    800040ee:	e44e                	sd	s3,8(sp)
    800040f0:	1800                	addi	s0,sp,48
    800040f2:	892a                	mv	s2,a0
    800040f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f6:	0001e497          	auipc	s1,0x1e
    800040fa:	a1248493          	addi	s1,s1,-1518 # 80021b08 <log>
    800040fe:	00004597          	auipc	a1,0x4
    80004102:	77258593          	addi	a1,a1,1906 # 80008870 <syscall_name+0x218>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	ac2080e7          	jalr	-1342(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    80004110:	0149a583          	lw	a1,20(s3)
    80004114:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004116:	0109a783          	lw	a5,16(s3)
    8000411a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000411c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004120:	854a                	mv	a0,s2
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	ea6080e7          	jalr	-346(ra) # 80002fc8 <bread>
  log.lh.n = lh->n;
    8000412a:	4d3c                	lw	a5,88(a0)
    8000412c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000412e:	02f05563          	blez	a5,80004158 <initlog+0x74>
    80004132:	05c50713          	addi	a4,a0,92
    80004136:	0001e697          	auipc	a3,0x1e
    8000413a:	a0268693          	addi	a3,a3,-1534 # 80021b38 <log+0x30>
    8000413e:	37fd                	addiw	a5,a5,-1
    80004140:	1782                	slli	a5,a5,0x20
    80004142:	9381                	srli	a5,a5,0x20
    80004144:	078a                	slli	a5,a5,0x2
    80004146:	06050613          	addi	a2,a0,96
    8000414a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000414c:	4310                	lw	a2,0(a4)
    8000414e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004150:	0711                	addi	a4,a4,4
    80004152:	0691                	addi	a3,a3,4
    80004154:	fef71ce3          	bne	a4,a5,8000414c <initlog+0x68>
  brelse(buf);
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	fa0080e7          	jalr	-96(ra) # 800030f8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004160:	00000097          	auipc	ra,0x0
    80004164:	ece080e7          	jalr	-306(ra) # 8000402e <install_trans>
  log.lh.n = 0;
    80004168:	0001e797          	auipc	a5,0x1e
    8000416c:	9c07a623          	sw	zero,-1588(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004170:	00000097          	auipc	ra,0x0
    80004174:	e44080e7          	jalr	-444(ra) # 80003fb4 <write_head>
}
    80004178:	70a2                	ld	ra,40(sp)
    8000417a:	7402                	ld	s0,32(sp)
    8000417c:	64e2                	ld	s1,24(sp)
    8000417e:	6942                	ld	s2,16(sp)
    80004180:	69a2                	ld	s3,8(sp)
    80004182:	6145                	addi	sp,sp,48
    80004184:	8082                	ret

0000000080004186 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004186:	1101                	addi	sp,sp,-32
    80004188:	ec06                	sd	ra,24(sp)
    8000418a:	e822                	sd	s0,16(sp)
    8000418c:	e426                	sd	s1,8(sp)
    8000418e:	e04a                	sd	s2,0(sp)
    80004190:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004192:	0001e517          	auipc	a0,0x1e
    80004196:	97650513          	addi	a0,a0,-1674 # 80021b08 <log>
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	ac0080e7          	jalr	-1344(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    800041a2:	0001e497          	auipc	s1,0x1e
    800041a6:	96648493          	addi	s1,s1,-1690 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041aa:	4979                	li	s2,30
    800041ac:	a039                	j	800041ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ae:	85a6                	mv	a1,s1
    800041b0:	8526                	mv	a0,s1
    800041b2:	ffffe097          	auipc	ra,0xffffe
    800041b6:	08a080e7          	jalr	138(ra) # 8000223c <sleep>
    if(log.committing){
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	fbed                	bnez	a5,800041ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041be:	509c                	lw	a5,32(s1)
    800041c0:	0017871b          	addiw	a4,a5,1
    800041c4:	0007069b          	sext.w	a3,a4
    800041c8:	0027179b          	slliw	a5,a4,0x2
    800041cc:	9fb9                	addw	a5,a5,a4
    800041ce:	0017979b          	slliw	a5,a5,0x1
    800041d2:	54d8                	lw	a4,44(s1)
    800041d4:	9fb9                	addw	a5,a5,a4
    800041d6:	00f95963          	bge	s2,a5,800041e8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041da:	85a6                	mv	a1,s1
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffe097          	auipc	ra,0xffffe
    800041e2:	05e080e7          	jalr	94(ra) # 8000223c <sleep>
    800041e6:	bfd1                	j	800041ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e8:	0001e517          	auipc	a0,0x1e
    800041ec:	92050513          	addi	a0,a0,-1760 # 80021b08 <log>
    800041f0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	b1c080e7          	jalr	-1252(ra) # 80000d0e <release>
      break;
    }
  }
}
    800041fa:	60e2                	ld	ra,24(sp)
    800041fc:	6442                	ld	s0,16(sp)
    800041fe:	64a2                	ld	s1,8(sp)
    80004200:	6902                	ld	s2,0(sp)
    80004202:	6105                	addi	sp,sp,32
    80004204:	8082                	ret

0000000080004206 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004206:	7139                	addi	sp,sp,-64
    80004208:	fc06                	sd	ra,56(sp)
    8000420a:	f822                	sd	s0,48(sp)
    8000420c:	f426                	sd	s1,40(sp)
    8000420e:	f04a                	sd	s2,32(sp)
    80004210:	ec4e                	sd	s3,24(sp)
    80004212:	e852                	sd	s4,16(sp)
    80004214:	e456                	sd	s5,8(sp)
    80004216:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004218:	0001e497          	auipc	s1,0x1e
    8000421c:	8f048493          	addi	s1,s1,-1808 # 80021b08 <log>
    80004220:	8526                	mv	a0,s1
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	a38080e7          	jalr	-1480(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    8000422a:	509c                	lw	a5,32(s1)
    8000422c:	37fd                	addiw	a5,a5,-1
    8000422e:	0007891b          	sext.w	s2,a5
    80004232:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004234:	50dc                	lw	a5,36(s1)
    80004236:	efb9                	bnez	a5,80004294 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004238:	06091663          	bnez	s2,800042a4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000423c:	0001e497          	auipc	s1,0x1e
    80004240:	8cc48493          	addi	s1,s1,-1844 # 80021b08 <log>
    80004244:	4785                	li	a5,1
    80004246:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	ac4080e7          	jalr	-1340(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004252:	54dc                	lw	a5,44(s1)
    80004254:	06f04763          	bgtz	a5,800042c2 <end_op+0xbc>
    acquire(&log.lock);
    80004258:	0001e497          	auipc	s1,0x1e
    8000425c:	8b048493          	addi	s1,s1,-1872 # 80021b08 <log>
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	9f8080e7          	jalr	-1544(ra) # 80000c5a <acquire>
    log.committing = 0;
    8000426a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffe097          	auipc	ra,0xffffe
    80004274:	152080e7          	jalr	338(ra) # 800023c2 <wakeup>
    release(&log.lock);
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	a94080e7          	jalr	-1388(ra) # 80000d0e <release>
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6aa2                	ld	s5,8(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    panic("log.committing");
    80004294:	00004517          	auipc	a0,0x4
    80004298:	5e450513          	addi	a0,a0,1508 # 80008878 <syscall_name+0x220>
    8000429c:	ffffc097          	auipc	ra,0xffffc
    800042a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>
    wakeup(&log);
    800042a4:	0001e497          	auipc	s1,0x1e
    800042a8:	86448493          	addi	s1,s1,-1948 # 80021b08 <log>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	114080e7          	jalr	276(ra) # 800023c2 <wakeup>
  release(&log.lock);
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	a56080e7          	jalr	-1450(ra) # 80000d0e <release>
  if(do_commit){
    800042c0:	b7c9                	j	80004282 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	0001ea97          	auipc	s5,0x1e
    800042c6:	876a8a93          	addi	s5,s5,-1930 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ca:	0001ea17          	auipc	s4,0x1e
    800042ce:	83ea0a13          	addi	s4,s4,-1986 # 80021b08 <log>
    800042d2:	018a2583          	lw	a1,24(s4)
    800042d6:	012585bb          	addw	a1,a1,s2
    800042da:	2585                	addiw	a1,a1,1
    800042dc:	028a2503          	lw	a0,40(s4)
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	ce8080e7          	jalr	-792(ra) # 80002fc8 <bread>
    800042e8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ea:	000aa583          	lw	a1,0(s5)
    800042ee:	028a2503          	lw	a0,40(s4)
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	cd6080e7          	jalr	-810(ra) # 80002fc8 <bread>
    800042fa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042fc:	40000613          	li	a2,1024
    80004300:	05850593          	addi	a1,a0,88
    80004304:	05848513          	addi	a0,s1,88
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	aae080e7          	jalr	-1362(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	da8080e7          	jalr	-600(ra) # 800030ba <bwrite>
    brelse(from);
    8000431a:	854e                	mv	a0,s3
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	ddc080e7          	jalr	-548(ra) # 800030f8 <brelse>
    brelse(to);
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	dd2080e7          	jalr	-558(ra) # 800030f8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432e:	2905                	addiw	s2,s2,1
    80004330:	0a91                	addi	s5,s5,4
    80004332:	02ca2783          	lw	a5,44(s4)
    80004336:	f8f94ee3          	blt	s2,a5,800042d2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	c7a080e7          	jalr	-902(ra) # 80003fb4 <write_head>
    install_trans(); // Now install writes to home locations
    80004342:	00000097          	auipc	ra,0x0
    80004346:	cec080e7          	jalr	-788(ra) # 8000402e <install_trans>
    log.lh.n = 0;
    8000434a:	0001d797          	auipc	a5,0x1d
    8000434e:	7e07a523          	sw	zero,2026(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c62080e7          	jalr	-926(ra) # 80003fb4 <write_head>
    8000435a:	bdfd                	j	80004258 <end_op+0x52>

000000008000435c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000435c:	1101                	addi	sp,sp,-32
    8000435e:	ec06                	sd	ra,24(sp)
    80004360:	e822                	sd	s0,16(sp)
    80004362:	e426                	sd	s1,8(sp)
    80004364:	e04a                	sd	s2,0(sp)
    80004366:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004368:	0001d717          	auipc	a4,0x1d
    8000436c:	7cc72703          	lw	a4,1996(a4) # 80021b34 <log+0x2c>
    80004370:	47f5                	li	a5,29
    80004372:	08e7c063          	blt	a5,a4,800043f2 <log_write+0x96>
    80004376:	84aa                	mv	s1,a0
    80004378:	0001d797          	auipc	a5,0x1d
    8000437c:	7ac7a783          	lw	a5,1964(a5) # 80021b24 <log+0x1c>
    80004380:	37fd                	addiw	a5,a5,-1
    80004382:	06f75863          	bge	a4,a5,800043f2 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004386:	0001d797          	auipc	a5,0x1d
    8000438a:	7a27a783          	lw	a5,1954(a5) # 80021b28 <log+0x20>
    8000438e:	06f05a63          	blez	a5,80004402 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004392:	0001d917          	auipc	s2,0x1d
    80004396:	77690913          	addi	s2,s2,1910 # 80021b08 <log>
    8000439a:	854a                	mv	a0,s2
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	8be080e7          	jalr	-1858(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	02c92603          	lw	a2,44(s2)
    800043a8:	06c05563          	blez	a2,80004412 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043ac:	44cc                	lw	a1,12(s1)
    800043ae:	0001d717          	auipc	a4,0x1d
    800043b2:	78a70713          	addi	a4,a4,1930 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043b6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043b8:	4314                	lw	a3,0(a4)
    800043ba:	04b68d63          	beq	a3,a1,80004414 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043be:	2785                	addiw	a5,a5,1
    800043c0:	0711                	addi	a4,a4,4
    800043c2:	fec79be3          	bne	a5,a2,800043b8 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043c6:	0621                	addi	a2,a2,8
    800043c8:	060a                	slli	a2,a2,0x2
    800043ca:	0001d797          	auipc	a5,0x1d
    800043ce:	73e78793          	addi	a5,a5,1854 # 80021b08 <log>
    800043d2:	963e                	add	a2,a2,a5
    800043d4:	44dc                	lw	a5,12(s1)
    800043d6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d8:	8526                	mv	a0,s1
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	dbc080e7          	jalr	-580(ra) # 80003196 <bpin>
    log.lh.n++;
    800043e2:	0001d717          	auipc	a4,0x1d
    800043e6:	72670713          	addi	a4,a4,1830 # 80021b08 <log>
    800043ea:	575c                	lw	a5,44(a4)
    800043ec:	2785                	addiw	a5,a5,1
    800043ee:	d75c                	sw	a5,44(a4)
    800043f0:	a83d                	j	8000442e <log_write+0xd2>
    panic("too big a transaction");
    800043f2:	00004517          	auipc	a0,0x4
    800043f6:	49650513          	addi	a0,a0,1174 # 80008888 <syscall_name+0x230>
    800043fa:	ffffc097          	auipc	ra,0xffffc
    800043fe:	14e080e7          	jalr	334(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004402:	00004517          	auipc	a0,0x4
    80004406:	49e50513          	addi	a0,a0,1182 # 800088a0 <syscall_name+0x248>
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	13e080e7          	jalr	318(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004412:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004414:	00878713          	addi	a4,a5,8
    80004418:	00271693          	slli	a3,a4,0x2
    8000441c:	0001d717          	auipc	a4,0x1d
    80004420:	6ec70713          	addi	a4,a4,1772 # 80021b08 <log>
    80004424:	9736                	add	a4,a4,a3
    80004426:	44d4                	lw	a3,12(s1)
    80004428:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442a:	faf607e3          	beq	a2,a5,800043d8 <log_write+0x7c>
  }
  release(&log.lock);
    8000442e:	0001d517          	auipc	a0,0x1d
    80004432:	6da50513          	addi	a0,a0,1754 # 80021b08 <log>
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	8d8080e7          	jalr	-1832(ra) # 80000d0e <release>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444a:	1101                	addi	sp,sp,-32
    8000444c:	ec06                	sd	ra,24(sp)
    8000444e:	e822                	sd	s0,16(sp)
    80004450:	e426                	sd	s1,8(sp)
    80004452:	e04a                	sd	s2,0(sp)
    80004454:	1000                	addi	s0,sp,32
    80004456:	84aa                	mv	s1,a0
    80004458:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445a:	00004597          	auipc	a1,0x4
    8000445e:	46658593          	addi	a1,a1,1126 # 800088c0 <syscall_name+0x268>
    80004462:	0521                	addi	a0,a0,8
    80004464:	ffffc097          	auipc	ra,0xffffc
    80004468:	766080e7          	jalr	1894(ra) # 80000bca <initlock>
  lk->name = name;
    8000446c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004470:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004474:	0204a423          	sw	zero,40(s1)
}
    80004478:	60e2                	ld	ra,24(sp)
    8000447a:	6442                	ld	s0,16(sp)
    8000447c:	64a2                	ld	s1,8(sp)
    8000447e:	6902                	ld	s2,0(sp)
    80004480:	6105                	addi	sp,sp,32
    80004482:	8082                	ret

0000000080004484 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004484:	1101                	addi	sp,sp,-32
    80004486:	ec06                	sd	ra,24(sp)
    80004488:	e822                	sd	s0,16(sp)
    8000448a:	e426                	sd	s1,8(sp)
    8000448c:	e04a                	sd	s2,0(sp)
    8000448e:	1000                	addi	s0,sp,32
    80004490:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004492:	00850913          	addi	s2,a0,8
    80004496:	854a                	mv	a0,s2
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	7c2080e7          	jalr	1986(ra) # 80000c5a <acquire>
  while (lk->locked) {
    800044a0:	409c                	lw	a5,0(s1)
    800044a2:	cb89                	beqz	a5,800044b4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a4:	85ca                	mv	a1,s2
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffe097          	auipc	ra,0xffffe
    800044ac:	d94080e7          	jalr	-620(ra) # 8000223c <sleep>
  while (lk->locked) {
    800044b0:	409c                	lw	a5,0(s1)
    800044b2:	fbed                	bnez	a5,800044a4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b4:	4785                	li	a5,1
    800044b6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	570080e7          	jalr	1392(ra) # 80001a28 <myproc>
    800044c0:	5d1c                	lw	a5,56(a0)
    800044c2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c4:	854a                	mv	a0,s2
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	848080e7          	jalr	-1976(ra) # 80000d0e <release>
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	e426                	sd	s1,8(sp)
    800044e2:	e04a                	sd	s2,0(sp)
    800044e4:	1000                	addi	s0,sp,32
    800044e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e8:	00850913          	addi	s2,a0,8
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	76c080e7          	jalr	1900(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800044f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044fe:	8526                	mv	a0,s1
    80004500:	ffffe097          	auipc	ra,0xffffe
    80004504:	ec2080e7          	jalr	-318(ra) # 800023c2 <wakeup>
  release(&lk->lk);
    80004508:	854a                	mv	a0,s2
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	804080e7          	jalr	-2044(ra) # 80000d0e <release>
}
    80004512:	60e2                	ld	ra,24(sp)
    80004514:	6442                	ld	s0,16(sp)
    80004516:	64a2                	ld	s1,8(sp)
    80004518:	6902                	ld	s2,0(sp)
    8000451a:	6105                	addi	sp,sp,32
    8000451c:	8082                	ret

000000008000451e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000451e:	7179                	addi	sp,sp,-48
    80004520:	f406                	sd	ra,40(sp)
    80004522:	f022                	sd	s0,32(sp)
    80004524:	ec26                	sd	s1,24(sp)
    80004526:	e84a                	sd	s2,16(sp)
    80004528:	e44e                	sd	s3,8(sp)
    8000452a:	1800                	addi	s0,sp,48
    8000452c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000452e:	00850913          	addi	s2,a0,8
    80004532:	854a                	mv	a0,s2
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	726080e7          	jalr	1830(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000453c:	409c                	lw	a5,0(s1)
    8000453e:	ef99                	bnez	a5,8000455c <holdingsleep+0x3e>
    80004540:	4481                	li	s1,0
  release(&lk->lk);
    80004542:	854a                	mv	a0,s2
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	7ca080e7          	jalr	1994(ra) # 80000d0e <release>
  return r;
}
    8000454c:	8526                	mv	a0,s1
    8000454e:	70a2                	ld	ra,40(sp)
    80004550:	7402                	ld	s0,32(sp)
    80004552:	64e2                	ld	s1,24(sp)
    80004554:	6942                	ld	s2,16(sp)
    80004556:	69a2                	ld	s3,8(sp)
    80004558:	6145                	addi	sp,sp,48
    8000455a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000455c:	0284a983          	lw	s3,40(s1)
    80004560:	ffffd097          	auipc	ra,0xffffd
    80004564:	4c8080e7          	jalr	1224(ra) # 80001a28 <myproc>
    80004568:	5d04                	lw	s1,56(a0)
    8000456a:	413484b3          	sub	s1,s1,s3
    8000456e:	0014b493          	seqz	s1,s1
    80004572:	bfc1                	j	80004542 <holdingsleep+0x24>

0000000080004574 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004574:	1141                	addi	sp,sp,-16
    80004576:	e406                	sd	ra,8(sp)
    80004578:	e022                	sd	s0,0(sp)
    8000457a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000457c:	00004597          	auipc	a1,0x4
    80004580:	35458593          	addi	a1,a1,852 # 800088d0 <syscall_name+0x278>
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	6cc50513          	addi	a0,a0,1740 # 80021c50 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	63e080e7          	jalr	1598(ra) # 80000bca <initlock>
}
    80004594:	60a2                	ld	ra,8(sp)
    80004596:	6402                	ld	s0,0(sp)
    80004598:	0141                	addi	sp,sp,16
    8000459a:	8082                	ret

000000008000459c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000459c:	1101                	addi	sp,sp,-32
    8000459e:	ec06                	sd	ra,24(sp)
    800045a0:	e822                	sd	s0,16(sp)
    800045a2:	e426                	sd	s1,8(sp)
    800045a4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a6:	0001d517          	auipc	a0,0x1d
    800045aa:	6aa50513          	addi	a0,a0,1706 # 80021c50 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ac080e7          	jalr	1708(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b6:	0001d497          	auipc	s1,0x1d
    800045ba:	6b248493          	addi	s1,s1,1714 # 80021c68 <ftable+0x18>
    800045be:	0001e717          	auipc	a4,0x1e
    800045c2:	64a70713          	addi	a4,a4,1610 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800045c6:	40dc                	lw	a5,4(s1)
    800045c8:	cf99                	beqz	a5,800045e6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ca:	02848493          	addi	s1,s1,40
    800045ce:	fee49ce3          	bne	s1,a4,800045c6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d2:	0001d517          	auipc	a0,0x1d
    800045d6:	67e50513          	addi	a0,a0,1662 # 80021c50 <ftable>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	734080e7          	jalr	1844(ra) # 80000d0e <release>
  return 0;
    800045e2:	4481                	li	s1,0
    800045e4:	a819                	j	800045fa <filealloc+0x5e>
      f->ref = 1;
    800045e6:	4785                	li	a5,1
    800045e8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ea:	0001d517          	auipc	a0,0x1d
    800045ee:	66650513          	addi	a0,a0,1638 # 80021c50 <ftable>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	71c080e7          	jalr	1820(ra) # 80000d0e <release>
}
    800045fa:	8526                	mv	a0,s1
    800045fc:	60e2                	ld	ra,24(sp)
    800045fe:	6442                	ld	s0,16(sp)
    80004600:	64a2                	ld	s1,8(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	1000                	addi	s0,sp,32
    80004610:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	63e50513          	addi	a0,a0,1598 # 80021c50 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	640080e7          	jalr	1600(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004622:	40dc                	lw	a5,4(s1)
    80004624:	02f05263          	blez	a5,80004648 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004628:	2785                	addiw	a5,a5,1
    8000462a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000462c:	0001d517          	auipc	a0,0x1d
    80004630:	62450513          	addi	a0,a0,1572 # 80021c50 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	6da080e7          	jalr	1754(ra) # 80000d0e <release>
  return f;
}
    8000463c:	8526                	mv	a0,s1
    8000463e:	60e2                	ld	ra,24(sp)
    80004640:	6442                	ld	s0,16(sp)
    80004642:	64a2                	ld	s1,8(sp)
    80004644:	6105                	addi	sp,sp,32
    80004646:	8082                	ret
    panic("filedup");
    80004648:	00004517          	auipc	a0,0x4
    8000464c:	29050513          	addi	a0,a0,656 # 800088d8 <syscall_name+0x280>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>

0000000080004658 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004658:	7139                	addi	sp,sp,-64
    8000465a:	fc06                	sd	ra,56(sp)
    8000465c:	f822                	sd	s0,48(sp)
    8000465e:	f426                	sd	s1,40(sp)
    80004660:	f04a                	sd	s2,32(sp)
    80004662:	ec4e                	sd	s3,24(sp)
    80004664:	e852                	sd	s4,16(sp)
    80004666:	e456                	sd	s5,8(sp)
    80004668:	0080                	addi	s0,sp,64
    8000466a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000466c:	0001d517          	auipc	a0,0x1d
    80004670:	5e450513          	addi	a0,a0,1508 # 80021c50 <ftable>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	5e6080e7          	jalr	1510(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    8000467c:	40dc                	lw	a5,4(s1)
    8000467e:	06f05163          	blez	a5,800046e0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004682:	37fd                	addiw	a5,a5,-1
    80004684:	0007871b          	sext.w	a4,a5
    80004688:	c0dc                	sw	a5,4(s1)
    8000468a:	06e04363          	bgtz	a4,800046f0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000468e:	0004a903          	lw	s2,0(s1)
    80004692:	0094ca83          	lbu	s5,9(s1)
    80004696:	0104ba03          	ld	s4,16(s1)
    8000469a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000469e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	5aa50513          	addi	a0,a0,1450 # 80021c50 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	660080e7          	jalr	1632(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    800046b6:	4785                	li	a5,1
    800046b8:	04f90d63          	beq	s2,a5,80004712 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046bc:	3979                	addiw	s2,s2,-2
    800046be:	4785                	li	a5,1
    800046c0:	0527e063          	bltu	a5,s2,80004700 <fileclose+0xa8>
    begin_op();
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	ac2080e7          	jalr	-1342(ra) # 80004186 <begin_op>
    iput(ff.ip);
    800046cc:	854e                	mv	a0,s3
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	2b6080e7          	jalr	694(ra) # 80003984 <iput>
    end_op();
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	b30080e7          	jalr	-1232(ra) # 80004206 <end_op>
    800046de:	a00d                	j	80004700 <fileclose+0xa8>
    panic("fileclose");
    800046e0:	00004517          	auipc	a0,0x4
    800046e4:	20050513          	addi	a0,a0,512 # 800088e0 <syscall_name+0x288>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	e60080e7          	jalr	-416(ra) # 80000548 <panic>
    release(&ftable.lock);
    800046f0:	0001d517          	auipc	a0,0x1d
    800046f4:	56050513          	addi	a0,a0,1376 # 80021c50 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	616080e7          	jalr	1558(ra) # 80000d0e <release>
  }
}
    80004700:	70e2                	ld	ra,56(sp)
    80004702:	7442                	ld	s0,48(sp)
    80004704:	74a2                	ld	s1,40(sp)
    80004706:	7902                	ld	s2,32(sp)
    80004708:	69e2                	ld	s3,24(sp)
    8000470a:	6a42                	ld	s4,16(sp)
    8000470c:	6aa2                	ld	s5,8(sp)
    8000470e:	6121                	addi	sp,sp,64
    80004710:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004712:	85d6                	mv	a1,s5
    80004714:	8552                	mv	a0,s4
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	372080e7          	jalr	882(ra) # 80004a88 <pipeclose>
    8000471e:	b7cd                	j	80004700 <fileclose+0xa8>

0000000080004720 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004720:	715d                	addi	sp,sp,-80
    80004722:	e486                	sd	ra,72(sp)
    80004724:	e0a2                	sd	s0,64(sp)
    80004726:	fc26                	sd	s1,56(sp)
    80004728:	f84a                	sd	s2,48(sp)
    8000472a:	f44e                	sd	s3,40(sp)
    8000472c:	0880                	addi	s0,sp,80
    8000472e:	84aa                	mv	s1,a0
    80004730:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004732:	ffffd097          	auipc	ra,0xffffd
    80004736:	2f6080e7          	jalr	758(ra) # 80001a28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473a:	409c                	lw	a5,0(s1)
    8000473c:	37f9                	addiw	a5,a5,-2
    8000473e:	4705                	li	a4,1
    80004740:	04f76763          	bltu	a4,a5,8000478e <filestat+0x6e>
    80004744:	892a                	mv	s2,a0
    ilock(f->ip);
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	082080e7          	jalr	130(ra) # 800037ca <ilock>
    stati(f->ip, &st);
    80004750:	fb840593          	addi	a1,s0,-72
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	2fe080e7          	jalr	766(ra) # 80003a54 <stati>
    iunlock(f->ip);
    8000475e:	6c88                	ld	a0,24(s1)
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	12c080e7          	jalr	300(ra) # 8000388c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004768:	46e1                	li	a3,24
    8000476a:	fb840613          	addi	a2,s0,-72
    8000476e:	85ce                	mv	a1,s3
    80004770:	05093503          	ld	a0,80(s2)
    80004774:	ffffd097          	auipc	ra,0xffffd
    80004778:	fa8080e7          	jalr	-88(ra) # 8000171c <copyout>
    8000477c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004780:	60a6                	ld	ra,72(sp)
    80004782:	6406                	ld	s0,64(sp)
    80004784:	74e2                	ld	s1,56(sp)
    80004786:	7942                	ld	s2,48(sp)
    80004788:	79a2                	ld	s3,40(sp)
    8000478a:	6161                	addi	sp,sp,80
    8000478c:	8082                	ret
  return -1;
    8000478e:	557d                	li	a0,-1
    80004790:	bfc5                	j	80004780 <filestat+0x60>

0000000080004792 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004792:	7179                	addi	sp,sp,-48
    80004794:	f406                	sd	ra,40(sp)
    80004796:	f022                	sd	s0,32(sp)
    80004798:	ec26                	sd	s1,24(sp)
    8000479a:	e84a                	sd	s2,16(sp)
    8000479c:	e44e                	sd	s3,8(sp)
    8000479e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a0:	00854783          	lbu	a5,8(a0)
    800047a4:	c3d5                	beqz	a5,80004848 <fileread+0xb6>
    800047a6:	84aa                	mv	s1,a0
    800047a8:	89ae                	mv	s3,a1
    800047aa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ac:	411c                	lw	a5,0(a0)
    800047ae:	4705                	li	a4,1
    800047b0:	04e78963          	beq	a5,a4,80004802 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b4:	470d                	li	a4,3
    800047b6:	04e78d63          	beq	a5,a4,80004810 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ba:	4709                	li	a4,2
    800047bc:	06e79e63          	bne	a5,a4,80004838 <fileread+0xa6>
    ilock(f->ip);
    800047c0:	6d08                	ld	a0,24(a0)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	008080e7          	jalr	8(ra) # 800037ca <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ca:	874a                	mv	a4,s2
    800047cc:	5094                	lw	a3,32(s1)
    800047ce:	864e                	mv	a2,s3
    800047d0:	4585                	li	a1,1
    800047d2:	6c88                	ld	a0,24(s1)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	2aa080e7          	jalr	682(ra) # 80003a7e <readi>
    800047dc:	892a                	mv	s2,a0
    800047de:	00a05563          	blez	a0,800047e8 <fileread+0x56>
      f->off += r;
    800047e2:	509c                	lw	a5,32(s1)
    800047e4:	9fa9                	addw	a5,a5,a0
    800047e6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047e8:	6c88                	ld	a0,24(s1)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	0a2080e7          	jalr	162(ra) # 8000388c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f2:	854a                	mv	a0,s2
    800047f4:	70a2                	ld	ra,40(sp)
    800047f6:	7402                	ld	s0,32(sp)
    800047f8:	64e2                	ld	s1,24(sp)
    800047fa:	6942                	ld	s2,16(sp)
    800047fc:	69a2                	ld	s3,8(sp)
    800047fe:	6145                	addi	sp,sp,48
    80004800:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004802:	6908                	ld	a0,16(a0)
    80004804:	00000097          	auipc	ra,0x0
    80004808:	418080e7          	jalr	1048(ra) # 80004c1c <piperead>
    8000480c:	892a                	mv	s2,a0
    8000480e:	b7d5                	j	800047f2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004810:	02451783          	lh	a5,36(a0)
    80004814:	03079693          	slli	a3,a5,0x30
    80004818:	92c1                	srli	a3,a3,0x30
    8000481a:	4725                	li	a4,9
    8000481c:	02d76863          	bltu	a4,a3,8000484c <fileread+0xba>
    80004820:	0792                	slli	a5,a5,0x4
    80004822:	0001d717          	auipc	a4,0x1d
    80004826:	38e70713          	addi	a4,a4,910 # 80021bb0 <devsw>
    8000482a:	97ba                	add	a5,a5,a4
    8000482c:	639c                	ld	a5,0(a5)
    8000482e:	c38d                	beqz	a5,80004850 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004830:	4505                	li	a0,1
    80004832:	9782                	jalr	a5
    80004834:	892a                	mv	s2,a0
    80004836:	bf75                	j	800047f2 <fileread+0x60>
    panic("fileread");
    80004838:	00004517          	auipc	a0,0x4
    8000483c:	0b850513          	addi	a0,a0,184 # 800088f0 <syscall_name+0x298>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	d08080e7          	jalr	-760(ra) # 80000548 <panic>
    return -1;
    80004848:	597d                	li	s2,-1
    8000484a:	b765                	j	800047f2 <fileread+0x60>
      return -1;
    8000484c:	597d                	li	s2,-1
    8000484e:	b755                	j	800047f2 <fileread+0x60>
    80004850:	597d                	li	s2,-1
    80004852:	b745                	j	800047f2 <fileread+0x60>

0000000080004854 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004854:	00954783          	lbu	a5,9(a0)
    80004858:	14078563          	beqz	a5,800049a2 <filewrite+0x14e>
{
    8000485c:	715d                	addi	sp,sp,-80
    8000485e:	e486                	sd	ra,72(sp)
    80004860:	e0a2                	sd	s0,64(sp)
    80004862:	fc26                	sd	s1,56(sp)
    80004864:	f84a                	sd	s2,48(sp)
    80004866:	f44e                	sd	s3,40(sp)
    80004868:	f052                	sd	s4,32(sp)
    8000486a:	ec56                	sd	s5,24(sp)
    8000486c:	e85a                	sd	s6,16(sp)
    8000486e:	e45e                	sd	s7,8(sp)
    80004870:	e062                	sd	s8,0(sp)
    80004872:	0880                	addi	s0,sp,80
    80004874:	892a                	mv	s2,a0
    80004876:	8aae                	mv	s5,a1
    80004878:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487a:	411c                	lw	a5,0(a0)
    8000487c:	4705                	li	a4,1
    8000487e:	02e78263          	beq	a5,a4,800048a2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004882:	470d                	li	a4,3
    80004884:	02e78563          	beq	a5,a4,800048ae <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004888:	4709                	li	a4,2
    8000488a:	10e79463          	bne	a5,a4,80004992 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000488e:	0ec05e63          	blez	a2,8000498a <filewrite+0x136>
    int i = 0;
    80004892:	4981                	li	s3,0
    80004894:	6b05                	lui	s6,0x1
    80004896:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000489a:	6b85                	lui	s7,0x1
    8000489c:	c00b8b9b          	addiw	s7,s7,-1024
    800048a0:	a851                	j	80004934 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048a2:	6908                	ld	a0,16(a0)
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	254080e7          	jalr	596(ra) # 80004af8 <pipewrite>
    800048ac:	a85d                	j	80004962 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048ae:	02451783          	lh	a5,36(a0)
    800048b2:	03079693          	slli	a3,a5,0x30
    800048b6:	92c1                	srli	a3,a3,0x30
    800048b8:	4725                	li	a4,9
    800048ba:	0ed76663          	bltu	a4,a3,800049a6 <filewrite+0x152>
    800048be:	0792                	slli	a5,a5,0x4
    800048c0:	0001d717          	auipc	a4,0x1d
    800048c4:	2f070713          	addi	a4,a4,752 # 80021bb0 <devsw>
    800048c8:	97ba                	add	a5,a5,a4
    800048ca:	679c                	ld	a5,8(a5)
    800048cc:	cff9                	beqz	a5,800049aa <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048ce:	4505                	li	a0,1
    800048d0:	9782                	jalr	a5
    800048d2:	a841                	j	80004962 <filewrite+0x10e>
    800048d4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	8ae080e7          	jalr	-1874(ra) # 80004186 <begin_op>
      ilock(f->ip);
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	ee6080e7          	jalr	-282(ra) # 800037ca <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ec:	8762                	mv	a4,s8
    800048ee:	02092683          	lw	a3,32(s2)
    800048f2:	01598633          	add	a2,s3,s5
    800048f6:	4585                	li	a1,1
    800048f8:	01893503          	ld	a0,24(s2)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	278080e7          	jalr	632(ra) # 80003b74 <writei>
    80004904:	84aa                	mv	s1,a0
    80004906:	02a05f63          	blez	a0,80004944 <filewrite+0xf0>
        f->off += r;
    8000490a:	02092783          	lw	a5,32(s2)
    8000490e:	9fa9                	addw	a5,a5,a0
    80004910:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004914:	01893503          	ld	a0,24(s2)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	f74080e7          	jalr	-140(ra) # 8000388c <iunlock>
      end_op();
    80004920:	00000097          	auipc	ra,0x0
    80004924:	8e6080e7          	jalr	-1818(ra) # 80004206 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004928:	049c1963          	bne	s8,s1,8000497a <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000492c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004930:	0349d663          	bge	s3,s4,8000495c <filewrite+0x108>
      int n1 = n - i;
    80004934:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004938:	84be                	mv	s1,a5
    8000493a:	2781                	sext.w	a5,a5
    8000493c:	f8fb5ce3          	bge	s6,a5,800048d4 <filewrite+0x80>
    80004940:	84de                	mv	s1,s7
    80004942:	bf49                	j	800048d4 <filewrite+0x80>
      iunlock(f->ip);
    80004944:	01893503          	ld	a0,24(s2)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	f44080e7          	jalr	-188(ra) # 8000388c <iunlock>
      end_op();
    80004950:	00000097          	auipc	ra,0x0
    80004954:	8b6080e7          	jalr	-1866(ra) # 80004206 <end_op>
      if(r < 0)
    80004958:	fc04d8e3          	bgez	s1,80004928 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000495c:	8552                	mv	a0,s4
    8000495e:	033a1863          	bne	s4,s3,8000498e <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004962:	60a6                	ld	ra,72(sp)
    80004964:	6406                	ld	s0,64(sp)
    80004966:	74e2                	ld	s1,56(sp)
    80004968:	7942                	ld	s2,48(sp)
    8000496a:	79a2                	ld	s3,40(sp)
    8000496c:	7a02                	ld	s4,32(sp)
    8000496e:	6ae2                	ld	s5,24(sp)
    80004970:	6b42                	ld	s6,16(sp)
    80004972:	6ba2                	ld	s7,8(sp)
    80004974:	6c02                	ld	s8,0(sp)
    80004976:	6161                	addi	sp,sp,80
    80004978:	8082                	ret
        panic("short filewrite");
    8000497a:	00004517          	auipc	a0,0x4
    8000497e:	f8650513          	addi	a0,a0,-122 # 80008900 <syscall_name+0x2a8>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	bc6080e7          	jalr	-1082(ra) # 80000548 <panic>
    int i = 0;
    8000498a:	4981                	li	s3,0
    8000498c:	bfc1                	j	8000495c <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000498e:	557d                	li	a0,-1
    80004990:	bfc9                	j	80004962 <filewrite+0x10e>
    panic("filewrite");
    80004992:	00004517          	auipc	a0,0x4
    80004996:	f7e50513          	addi	a0,a0,-130 # 80008910 <syscall_name+0x2b8>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	bae080e7          	jalr	-1106(ra) # 80000548 <panic>
    return -1;
    800049a2:	557d                	li	a0,-1
}
    800049a4:	8082                	ret
      return -1;
    800049a6:	557d                	li	a0,-1
    800049a8:	bf6d                	j	80004962 <filewrite+0x10e>
    800049aa:	557d                	li	a0,-1
    800049ac:	bf5d                	j	80004962 <filewrite+0x10e>

00000000800049ae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049ae:	7179                	addi	sp,sp,-48
    800049b0:	f406                	sd	ra,40(sp)
    800049b2:	f022                	sd	s0,32(sp)
    800049b4:	ec26                	sd	s1,24(sp)
    800049b6:	e84a                	sd	s2,16(sp)
    800049b8:	e44e                	sd	s3,8(sp)
    800049ba:	e052                	sd	s4,0(sp)
    800049bc:	1800                	addi	s0,sp,48
    800049be:	84aa                	mv	s1,a0
    800049c0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049c2:	0005b023          	sd	zero,0(a1)
    800049c6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	bd2080e7          	jalr	-1070(ra) # 8000459c <filealloc>
    800049d2:	e088                	sd	a0,0(s1)
    800049d4:	c551                	beqz	a0,80004a60 <pipealloc+0xb2>
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	bc6080e7          	jalr	-1082(ra) # 8000459c <filealloc>
    800049de:	00aa3023          	sd	a0,0(s4)
    800049e2:	c92d                	beqz	a0,80004a54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	13c080e7          	jalr	316(ra) # 80000b20 <kalloc>
    800049ec:	892a                	mv	s2,a0
    800049ee:	c125                	beqz	a0,80004a4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049f0:	4985                	li	s3,1
    800049f2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049f6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049fa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049fe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a02:	00004597          	auipc	a1,0x4
    80004a06:	f1e58593          	addi	a1,a1,-226 # 80008920 <syscall_name+0x2c8>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1c0080e7          	jalr	448(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    80004a12:	609c                	ld	a5,0(s1)
    80004a14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a18:	609c                	ld	a5,0(s1)
    80004a1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a1e:	609c                	ld	a5,0(s1)
    80004a20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a24:	609c                	ld	a5,0(s1)
    80004a26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a2a:	000a3783          	ld	a5,0(s4)
    80004a2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a32:	000a3783          	ld	a5,0(s4)
    80004a36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a3a:	000a3783          	ld	a5,0(s4)
    80004a3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a42:	000a3783          	ld	a5,0(s4)
    80004a46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a4a:	4501                	li	a0,0
    80004a4c:	a025                	j	80004a74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a4e:	6088                	ld	a0,0(s1)
    80004a50:	e501                	bnez	a0,80004a58 <pipealloc+0xaa>
    80004a52:	a039                	j	80004a60 <pipealloc+0xb2>
    80004a54:	6088                	ld	a0,0(s1)
    80004a56:	c51d                	beqz	a0,80004a84 <pipealloc+0xd6>
    fileclose(*f0);
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	c00080e7          	jalr	-1024(ra) # 80004658 <fileclose>
  if(*f1)
    80004a60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a64:	557d                	li	a0,-1
  if(*f1)
    80004a66:	c799                	beqz	a5,80004a74 <pipealloc+0xc6>
    fileclose(*f1);
    80004a68:	853e                	mv	a0,a5
    80004a6a:	00000097          	auipc	ra,0x0
    80004a6e:	bee080e7          	jalr	-1042(ra) # 80004658 <fileclose>
  return -1;
    80004a72:	557d                	li	a0,-1
}
    80004a74:	70a2                	ld	ra,40(sp)
    80004a76:	7402                	ld	s0,32(sp)
    80004a78:	64e2                	ld	s1,24(sp)
    80004a7a:	6942                	ld	s2,16(sp)
    80004a7c:	69a2                	ld	s3,8(sp)
    80004a7e:	6a02                	ld	s4,0(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret
  return -1;
    80004a84:	557d                	li	a0,-1
    80004a86:	b7fd                	j	80004a74 <pipealloc+0xc6>

0000000080004a88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a88:	1101                	addi	sp,sp,-32
    80004a8a:	ec06                	sd	ra,24(sp)
    80004a8c:	e822                	sd	s0,16(sp)
    80004a8e:	e426                	sd	s1,8(sp)
    80004a90:	e04a                	sd	s2,0(sp)
    80004a92:	1000                	addi	s0,sp,32
    80004a94:	84aa                	mv	s1,a0
    80004a96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	1c2080e7          	jalr	450(ra) # 80000c5a <acquire>
  if(writable){
    80004aa0:	02090d63          	beqz	s2,80004ada <pipeclose+0x52>
    pi->writeopen = 0;
    80004aa4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aa8:	21848513          	addi	a0,s1,536
    80004aac:	ffffe097          	auipc	ra,0xffffe
    80004ab0:	916080e7          	jalr	-1770(ra) # 800023c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ab4:	2204b783          	ld	a5,544(s1)
    80004ab8:	eb95                	bnez	a5,80004aec <pipeclose+0x64>
    release(&pi->lock);
    80004aba:	8526                	mv	a0,s1
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	252080e7          	jalr	594(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004ace:	60e2                	ld	ra,24(sp)
    80004ad0:	6442                	ld	s0,16(sp)
    80004ad2:	64a2                	ld	s1,8(sp)
    80004ad4:	6902                	ld	s2,0(sp)
    80004ad6:	6105                	addi	sp,sp,32
    80004ad8:	8082                	ret
    pi->readopen = 0;
    80004ada:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ade:	21c48513          	addi	a0,s1,540
    80004ae2:	ffffe097          	auipc	ra,0xffffe
    80004ae6:	8e0080e7          	jalr	-1824(ra) # 800023c2 <wakeup>
    80004aea:	b7e9                	j	80004ab4 <pipeclose+0x2c>
    release(&pi->lock);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	220080e7          	jalr	544(ra) # 80000d0e <release>
}
    80004af6:	bfe1                	j	80004ace <pipeclose+0x46>

0000000080004af8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004af8:	7119                	addi	sp,sp,-128
    80004afa:	fc86                	sd	ra,120(sp)
    80004afc:	f8a2                	sd	s0,112(sp)
    80004afe:	f4a6                	sd	s1,104(sp)
    80004b00:	f0ca                	sd	s2,96(sp)
    80004b02:	ecce                	sd	s3,88(sp)
    80004b04:	e8d2                	sd	s4,80(sp)
    80004b06:	e4d6                	sd	s5,72(sp)
    80004b08:	e0da                	sd	s6,64(sp)
    80004b0a:	fc5e                	sd	s7,56(sp)
    80004b0c:	f862                	sd	s8,48(sp)
    80004b0e:	f466                	sd	s9,40(sp)
    80004b10:	f06a                	sd	s10,32(sp)
    80004b12:	ec6e                	sd	s11,24(sp)
    80004b14:	0100                	addi	s0,sp,128
    80004b16:	84aa                	mv	s1,a0
    80004b18:	8cae                	mv	s9,a1
    80004b1a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	f0c080e7          	jalr	-244(ra) # 80001a28 <myproc>
    80004b24:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	132080e7          	jalr	306(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004b30:	0d605963          	blez	s6,80004c02 <pipewrite+0x10a>
    80004b34:	89a6                	mv	s3,s1
    80004b36:	3b7d                	addiw	s6,s6,-1
    80004b38:	1b02                	slli	s6,s6,0x20
    80004b3a:	020b5b13          	srli	s6,s6,0x20
    80004b3e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b40:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b44:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b48:	5dfd                	li	s11,-1
    80004b4a:	000b8d1b          	sext.w	s10,s7
    80004b4e:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b50:	2184a783          	lw	a5,536(s1)
    80004b54:	21c4a703          	lw	a4,540(s1)
    80004b58:	2007879b          	addiw	a5,a5,512
    80004b5c:	02f71b63          	bne	a4,a5,80004b92 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b60:	2204a783          	lw	a5,544(s1)
    80004b64:	cbad                	beqz	a5,80004bd6 <pipewrite+0xde>
    80004b66:	03092783          	lw	a5,48(s2)
    80004b6a:	e7b5                	bnez	a5,80004bd6 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b6c:	8556                	mv	a0,s5
    80004b6e:	ffffe097          	auipc	ra,0xffffe
    80004b72:	854080e7          	jalr	-1964(ra) # 800023c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b76:	85ce                	mv	a1,s3
    80004b78:	8552                	mv	a0,s4
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	6c2080e7          	jalr	1730(ra) # 8000223c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b82:	2184a783          	lw	a5,536(s1)
    80004b86:	21c4a703          	lw	a4,540(s1)
    80004b8a:	2007879b          	addiw	a5,a5,512
    80004b8e:	fcf709e3          	beq	a4,a5,80004b60 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b92:	4685                	li	a3,1
    80004b94:	019b8633          	add	a2,s7,s9
    80004b98:	f8f40593          	addi	a1,s0,-113
    80004b9c:	05093503          	ld	a0,80(s2)
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	c08080e7          	jalr	-1016(ra) # 800017a8 <copyin>
    80004ba8:	05b50e63          	beq	a0,s11,80004c04 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bac:	21c4a783          	lw	a5,540(s1)
    80004bb0:	0017871b          	addiw	a4,a5,1
    80004bb4:	20e4ae23          	sw	a4,540(s1)
    80004bb8:	1ff7f793          	andi	a5,a5,511
    80004bbc:	97a6                	add	a5,a5,s1
    80004bbe:	f8f44703          	lbu	a4,-113(s0)
    80004bc2:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bc6:	001d0c1b          	addiw	s8,s10,1
    80004bca:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004bce:	036b8b63          	beq	s7,s6,80004c04 <pipewrite+0x10c>
    80004bd2:	8bbe                	mv	s7,a5
    80004bd4:	bf9d                	j	80004b4a <pipewrite+0x52>
        release(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	136080e7          	jalr	310(ra) # 80000d0e <release>
        return -1;
    80004be0:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004be2:	8562                	mv	a0,s8
    80004be4:	70e6                	ld	ra,120(sp)
    80004be6:	7446                	ld	s0,112(sp)
    80004be8:	74a6                	ld	s1,104(sp)
    80004bea:	7906                	ld	s2,96(sp)
    80004bec:	69e6                	ld	s3,88(sp)
    80004bee:	6a46                	ld	s4,80(sp)
    80004bf0:	6aa6                	ld	s5,72(sp)
    80004bf2:	6b06                	ld	s6,64(sp)
    80004bf4:	7be2                	ld	s7,56(sp)
    80004bf6:	7c42                	ld	s8,48(sp)
    80004bf8:	7ca2                	ld	s9,40(sp)
    80004bfa:	7d02                	ld	s10,32(sp)
    80004bfc:	6de2                	ld	s11,24(sp)
    80004bfe:	6109                	addi	sp,sp,128
    80004c00:	8082                	ret
  for(i = 0; i < n; i++){
    80004c02:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c04:	21848513          	addi	a0,s1,536
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	7ba080e7          	jalr	1978(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	0fc080e7          	jalr	252(ra) # 80000d0e <release>
  return i;
    80004c1a:	b7e1                	j	80004be2 <pipewrite+0xea>

0000000080004c1c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c1c:	715d                	addi	sp,sp,-80
    80004c1e:	e486                	sd	ra,72(sp)
    80004c20:	e0a2                	sd	s0,64(sp)
    80004c22:	fc26                	sd	s1,56(sp)
    80004c24:	f84a                	sd	s2,48(sp)
    80004c26:	f44e                	sd	s3,40(sp)
    80004c28:	f052                	sd	s4,32(sp)
    80004c2a:	ec56                	sd	s5,24(sp)
    80004c2c:	e85a                	sd	s6,16(sp)
    80004c2e:	0880                	addi	s0,sp,80
    80004c30:	84aa                	mv	s1,a0
    80004c32:	892e                	mv	s2,a1
    80004c34:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	df2080e7          	jalr	-526(ra) # 80001a28 <myproc>
    80004c3e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c40:	8b26                	mv	s6,s1
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	016080e7          	jalr	22(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4c:	2184a703          	lw	a4,536(s1)
    80004c50:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c54:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c58:	02f71463          	bne	a4,a5,80004c80 <piperead+0x64>
    80004c5c:	2244a783          	lw	a5,548(s1)
    80004c60:	c385                	beqz	a5,80004c80 <piperead+0x64>
    if(pr->killed){
    80004c62:	030a2783          	lw	a5,48(s4)
    80004c66:	ebc1                	bnez	a5,80004cf6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c68:	85da                	mv	a1,s6
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	5d0080e7          	jalr	1488(ra) # 8000223c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c74:	2184a703          	lw	a4,536(s1)
    80004c78:	21c4a783          	lw	a5,540(s1)
    80004c7c:	fef700e3          	beq	a4,a5,80004c5c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c80:	09505263          	blez	s5,80004d04 <piperead+0xe8>
    80004c84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c86:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c88:	2184a783          	lw	a5,536(s1)
    80004c8c:	21c4a703          	lw	a4,540(s1)
    80004c90:	02f70d63          	beq	a4,a5,80004cca <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c94:	0017871b          	addiw	a4,a5,1
    80004c98:	20e4ac23          	sw	a4,536(s1)
    80004c9c:	1ff7f793          	andi	a5,a5,511
    80004ca0:	97a6                	add	a5,a5,s1
    80004ca2:	0187c783          	lbu	a5,24(a5)
    80004ca6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004caa:	4685                	li	a3,1
    80004cac:	fbf40613          	addi	a2,s0,-65
    80004cb0:	85ca                	mv	a1,s2
    80004cb2:	050a3503          	ld	a0,80(s4)
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	a66080e7          	jalr	-1434(ra) # 8000171c <copyout>
    80004cbe:	01650663          	beq	a0,s6,80004cca <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc2:	2985                	addiw	s3,s3,1
    80004cc4:	0905                	addi	s2,s2,1
    80004cc6:	fd3a91e3          	bne	s5,s3,80004c88 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cca:	21c48513          	addi	a0,s1,540
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	6f4080e7          	jalr	1780(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	036080e7          	jalr	54(ra) # 80000d0e <release>
  return i;
}
    80004ce0:	854e                	mv	a0,s3
    80004ce2:	60a6                	ld	ra,72(sp)
    80004ce4:	6406                	ld	s0,64(sp)
    80004ce6:	74e2                	ld	s1,56(sp)
    80004ce8:	7942                	ld	s2,48(sp)
    80004cea:	79a2                	ld	s3,40(sp)
    80004cec:	7a02                	ld	s4,32(sp)
    80004cee:	6ae2                	ld	s5,24(sp)
    80004cf0:	6b42                	ld	s6,16(sp)
    80004cf2:	6161                	addi	sp,sp,80
    80004cf4:	8082                	ret
      release(&pi->lock);
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	016080e7          	jalr	22(ra) # 80000d0e <release>
      return -1;
    80004d00:	59fd                	li	s3,-1
    80004d02:	bff9                	j	80004ce0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d04:	4981                	li	s3,0
    80004d06:	b7d1                	j	80004cca <piperead+0xae>

0000000080004d08 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d08:	df010113          	addi	sp,sp,-528
    80004d0c:	20113423          	sd	ra,520(sp)
    80004d10:	20813023          	sd	s0,512(sp)
    80004d14:	ffa6                	sd	s1,504(sp)
    80004d16:	fbca                	sd	s2,496(sp)
    80004d18:	f7ce                	sd	s3,488(sp)
    80004d1a:	f3d2                	sd	s4,480(sp)
    80004d1c:	efd6                	sd	s5,472(sp)
    80004d1e:	ebda                	sd	s6,464(sp)
    80004d20:	e7de                	sd	s7,456(sp)
    80004d22:	e3e2                	sd	s8,448(sp)
    80004d24:	ff66                	sd	s9,440(sp)
    80004d26:	fb6a                	sd	s10,432(sp)
    80004d28:	f76e                	sd	s11,424(sp)
    80004d2a:	0c00                	addi	s0,sp,528
    80004d2c:	84aa                	mv	s1,a0
    80004d2e:	dea43c23          	sd	a0,-520(s0)
    80004d32:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d36:	ffffd097          	auipc	ra,0xffffd
    80004d3a:	cf2080e7          	jalr	-782(ra) # 80001a28 <myproc>
    80004d3e:	892a                	mv	s2,a0

  begin_op();
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	446080e7          	jalr	1094(ra) # 80004186 <begin_op>

  if((ip = namei(path)) == 0){
    80004d48:	8526                	mv	a0,s1
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	230080e7          	jalr	560(ra) # 80003f7a <namei>
    80004d52:	c92d                	beqz	a0,80004dc4 <exec+0xbc>
    80004d54:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	a74080e7          	jalr	-1420(ra) # 800037ca <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d5e:	04000713          	li	a4,64
    80004d62:	4681                	li	a3,0
    80004d64:	e4840613          	addi	a2,s0,-440
    80004d68:	4581                	li	a1,0
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	d12080e7          	jalr	-750(ra) # 80003a7e <readi>
    80004d74:	04000793          	li	a5,64
    80004d78:	00f51a63          	bne	a0,a5,80004d8c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d7c:	e4842703          	lw	a4,-440(s0)
    80004d80:	464c47b7          	lui	a5,0x464c4
    80004d84:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d88:	04f70463          	beq	a4,a5,80004dd0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	c9e080e7          	jalr	-866(ra) # 80003a2c <iunlockput>
    end_op();
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	470080e7          	jalr	1136(ra) # 80004206 <end_op>
  }
  return -1;
    80004d9e:	557d                	li	a0,-1
}
    80004da0:	20813083          	ld	ra,520(sp)
    80004da4:	20013403          	ld	s0,512(sp)
    80004da8:	74fe                	ld	s1,504(sp)
    80004daa:	795e                	ld	s2,496(sp)
    80004dac:	79be                	ld	s3,488(sp)
    80004dae:	7a1e                	ld	s4,480(sp)
    80004db0:	6afe                	ld	s5,472(sp)
    80004db2:	6b5e                	ld	s6,464(sp)
    80004db4:	6bbe                	ld	s7,456(sp)
    80004db6:	6c1e                	ld	s8,448(sp)
    80004db8:	7cfa                	ld	s9,440(sp)
    80004dba:	7d5a                	ld	s10,432(sp)
    80004dbc:	7dba                	ld	s11,424(sp)
    80004dbe:	21010113          	addi	sp,sp,528
    80004dc2:	8082                	ret
    end_op();
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	442080e7          	jalr	1090(ra) # 80004206 <end_op>
    return -1;
    80004dcc:	557d                	li	a0,-1
    80004dce:	bfc9                	j	80004da0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd0:	854a                	mv	a0,s2
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	d1a080e7          	jalr	-742(ra) # 80001aec <proc_pagetable>
    80004dda:	8baa                	mv	s7,a0
    80004ddc:	d945                	beqz	a0,80004d8c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dde:	e6842983          	lw	s3,-408(s0)
    80004de2:	e8045783          	lhu	a5,-384(s0)
    80004de6:	c7ad                	beqz	a5,80004e50 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dea:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dec:	6c85                	lui	s9,0x1
    80004dee:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004df2:	def43823          	sd	a5,-528(s0)
    80004df6:	a42d                	j	80005020 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004df8:	00004517          	auipc	a0,0x4
    80004dfc:	b3050513          	addi	a0,a0,-1232 # 80008928 <syscall_name+0x2d0>
    80004e00:	ffffb097          	auipc	ra,0xffffb
    80004e04:	748080e7          	jalr	1864(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e08:	8756                	mv	a4,s5
    80004e0a:	012d86bb          	addw	a3,s11,s2
    80004e0e:	4581                	li	a1,0
    80004e10:	8526                	mv	a0,s1
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	c6c080e7          	jalr	-916(ra) # 80003a7e <readi>
    80004e1a:	2501                	sext.w	a0,a0
    80004e1c:	1aaa9963          	bne	s5,a0,80004fce <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e20:	6785                	lui	a5,0x1
    80004e22:	0127893b          	addw	s2,a5,s2
    80004e26:	77fd                	lui	a5,0xfffff
    80004e28:	01478a3b          	addw	s4,a5,s4
    80004e2c:	1f897163          	bgeu	s2,s8,8000500e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e30:	02091593          	slli	a1,s2,0x20
    80004e34:	9181                	srli	a1,a1,0x20
    80004e36:	95ea                	add	a1,a1,s10
    80004e38:	855e                	mv	a0,s7
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	2ae080e7          	jalr	686(ra) # 800010e8 <walkaddr>
    80004e42:	862a                	mv	a2,a0
    if(pa == 0)
    80004e44:	d955                	beqz	a0,80004df8 <exec+0xf0>
      n = PGSIZE;
    80004e46:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e48:	fd9a70e3          	bgeu	s4,s9,80004e08 <exec+0x100>
      n = sz - i;
    80004e4c:	8ad2                	mv	s5,s4
    80004e4e:	bf6d                	j	80004e08 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e50:	4901                	li	s2,0
  iunlockput(ip);
    80004e52:	8526                	mv	a0,s1
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	bd8080e7          	jalr	-1064(ra) # 80003a2c <iunlockput>
  end_op();
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	3aa080e7          	jalr	938(ra) # 80004206 <end_op>
  p = myproc();
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	bc4080e7          	jalr	-1084(ra) # 80001a28 <myproc>
    80004e6c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e6e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e72:	6785                	lui	a5,0x1
    80004e74:	17fd                	addi	a5,a5,-1
    80004e76:	993e                	add	s2,s2,a5
    80004e78:	757d                	lui	a0,0xfffff
    80004e7a:	00a977b3          	and	a5,s2,a0
    80004e7e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e82:	6609                	lui	a2,0x2
    80004e84:	963e                	add	a2,a2,a5
    80004e86:	85be                	mv	a1,a5
    80004e88:	855e                	mv	a0,s7
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	642080e7          	jalr	1602(ra) # 800014cc <uvmalloc>
    80004e92:	8b2a                	mv	s6,a0
  ip = 0;
    80004e94:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e96:	12050c63          	beqz	a0,80004fce <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e9a:	75f9                	lui	a1,0xffffe
    80004e9c:	95aa                	add	a1,a1,a0
    80004e9e:	855e                	mv	a0,s7
    80004ea0:	ffffd097          	auipc	ra,0xffffd
    80004ea4:	84a080e7          	jalr	-1974(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004ea8:	7c7d                	lui	s8,0xfffff
    80004eaa:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eac:	e0043783          	ld	a5,-512(s0)
    80004eb0:	6388                	ld	a0,0(a5)
    80004eb2:	c535                	beqz	a0,80004f1e <exec+0x216>
    80004eb4:	e8840993          	addi	s3,s0,-376
    80004eb8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ebc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	020080e7          	jalr	32(ra) # 80000ede <strlen>
    80004ec6:	2505                	addiw	a0,a0,1
    80004ec8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ecc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ed0:	13896363          	bltu	s2,s8,80004ff6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ed4:	e0043d83          	ld	s11,-512(s0)
    80004ed8:	000dba03          	ld	s4,0(s11)
    80004edc:	8552                	mv	a0,s4
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	000080e7          	jalr	ra # 80000ede <strlen>
    80004ee6:	0015069b          	addiw	a3,a0,1
    80004eea:	8652                	mv	a2,s4
    80004eec:	85ca                	mv	a1,s2
    80004eee:	855e                	mv	a0,s7
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	82c080e7          	jalr	-2004(ra) # 8000171c <copyout>
    80004ef8:	10054363          	bltz	a0,80004ffe <exec+0x2f6>
    ustack[argc] = sp;
    80004efc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f00:	0485                	addi	s1,s1,1
    80004f02:	008d8793          	addi	a5,s11,8
    80004f06:	e0f43023          	sd	a5,-512(s0)
    80004f0a:	008db503          	ld	a0,8(s11)
    80004f0e:	c911                	beqz	a0,80004f22 <exec+0x21a>
    if(argc >= MAXARG)
    80004f10:	09a1                	addi	s3,s3,8
    80004f12:	fb3c96e3          	bne	s9,s3,80004ebe <exec+0x1b6>
  sz = sz1;
    80004f16:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f1a:	4481                	li	s1,0
    80004f1c:	a84d                	j	80004fce <exec+0x2c6>
  sp = sz;
    80004f1e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f20:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f22:	00349793          	slli	a5,s1,0x3
    80004f26:	f9040713          	addi	a4,s0,-112
    80004f2a:	97ba                	add	a5,a5,a4
    80004f2c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f30:	00148693          	addi	a3,s1,1
    80004f34:	068e                	slli	a3,a3,0x3
    80004f36:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f3a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f3e:	01897663          	bgeu	s2,s8,80004f4a <exec+0x242>
  sz = sz1;
    80004f42:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f46:	4481                	li	s1,0
    80004f48:	a059                	j	80004fce <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f4a:	e8840613          	addi	a2,s0,-376
    80004f4e:	85ca                	mv	a1,s2
    80004f50:	855e                	mv	a0,s7
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	7ca080e7          	jalr	1994(ra) # 8000171c <copyout>
    80004f5a:	0a054663          	bltz	a0,80005006 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f5e:	058ab783          	ld	a5,88(s5)
    80004f62:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f66:	df843783          	ld	a5,-520(s0)
    80004f6a:	0007c703          	lbu	a4,0(a5)
    80004f6e:	cf11                	beqz	a4,80004f8a <exec+0x282>
    80004f70:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f72:	02f00693          	li	a3,47
    80004f76:	a029                	j	80004f80 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f78:	0785                	addi	a5,a5,1
    80004f7a:	fff7c703          	lbu	a4,-1(a5)
    80004f7e:	c711                	beqz	a4,80004f8a <exec+0x282>
    if(*s == '/')
    80004f80:	fed71ce3          	bne	a4,a3,80004f78 <exec+0x270>
      last = s+1;
    80004f84:	def43c23          	sd	a5,-520(s0)
    80004f88:	bfc5                	j	80004f78 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f8a:	4641                	li	a2,16
    80004f8c:	df843583          	ld	a1,-520(s0)
    80004f90:	158a8513          	addi	a0,s5,344
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	f18080e7          	jalr	-232(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f9c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fa0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fa4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fa8:	058ab783          	ld	a5,88(s5)
    80004fac:	e6043703          	ld	a4,-416(s0)
    80004fb0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fb2:	058ab783          	ld	a5,88(s5)
    80004fb6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fba:	85ea                	mv	a1,s10
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	bcc080e7          	jalr	-1076(ra) # 80001b88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fc4:	0004851b          	sext.w	a0,s1
    80004fc8:	bbe1                	j	80004da0 <exec+0x98>
    80004fca:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fce:	e0843583          	ld	a1,-504(s0)
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	bb4080e7          	jalr	-1100(ra) # 80001b88 <proc_freepagetable>
  if(ip){
    80004fdc:	da0498e3          	bnez	s1,80004d8c <exec+0x84>
  return -1;
    80004fe0:	557d                	li	a0,-1
    80004fe2:	bb7d                	j	80004da0 <exec+0x98>
    80004fe4:	e1243423          	sd	s2,-504(s0)
    80004fe8:	b7dd                	j	80004fce <exec+0x2c6>
    80004fea:	e1243423          	sd	s2,-504(s0)
    80004fee:	b7c5                	j	80004fce <exec+0x2c6>
    80004ff0:	e1243423          	sd	s2,-504(s0)
    80004ff4:	bfe9                	j	80004fce <exec+0x2c6>
  sz = sz1;
    80004ff6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ffa:	4481                	li	s1,0
    80004ffc:	bfc9                	j	80004fce <exec+0x2c6>
  sz = sz1;
    80004ffe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005002:	4481                	li	s1,0
    80005004:	b7e9                	j	80004fce <exec+0x2c6>
  sz = sz1;
    80005006:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500a:	4481                	li	s1,0
    8000500c:	b7c9                	j	80004fce <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005012:	2b05                	addiw	s6,s6,1
    80005014:	0389899b          	addiw	s3,s3,56
    80005018:	e8045783          	lhu	a5,-384(s0)
    8000501c:	e2fb5be3          	bge	s6,a5,80004e52 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005020:	2981                	sext.w	s3,s3
    80005022:	03800713          	li	a4,56
    80005026:	86ce                	mv	a3,s3
    80005028:	e1040613          	addi	a2,s0,-496
    8000502c:	4581                	li	a1,0
    8000502e:	8526                	mv	a0,s1
    80005030:	fffff097          	auipc	ra,0xfffff
    80005034:	a4e080e7          	jalr	-1458(ra) # 80003a7e <readi>
    80005038:	03800793          	li	a5,56
    8000503c:	f8f517e3          	bne	a0,a5,80004fca <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005040:	e1042783          	lw	a5,-496(s0)
    80005044:	4705                	li	a4,1
    80005046:	fce796e3          	bne	a5,a4,80005012 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000504a:	e3843603          	ld	a2,-456(s0)
    8000504e:	e3043783          	ld	a5,-464(s0)
    80005052:	f8f669e3          	bltu	a2,a5,80004fe4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005056:	e2043783          	ld	a5,-480(s0)
    8000505a:	963e                	add	a2,a2,a5
    8000505c:	f8f667e3          	bltu	a2,a5,80004fea <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005060:	85ca                	mv	a1,s2
    80005062:	855e                	mv	a0,s7
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	468080e7          	jalr	1128(ra) # 800014cc <uvmalloc>
    8000506c:	e0a43423          	sd	a0,-504(s0)
    80005070:	d141                	beqz	a0,80004ff0 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005072:	e2043d03          	ld	s10,-480(s0)
    80005076:	df043783          	ld	a5,-528(s0)
    8000507a:	00fd77b3          	and	a5,s10,a5
    8000507e:	fba1                	bnez	a5,80004fce <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005080:	e1842d83          	lw	s11,-488(s0)
    80005084:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005088:	f80c03e3          	beqz	s8,8000500e <exec+0x306>
    8000508c:	8a62                	mv	s4,s8
    8000508e:	4901                	li	s2,0
    80005090:	b345                	j	80004e30 <exec+0x128>

0000000080005092 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005092:	7179                	addi	sp,sp,-48
    80005094:	f406                	sd	ra,40(sp)
    80005096:	f022                	sd	s0,32(sp)
    80005098:	ec26                	sd	s1,24(sp)
    8000509a:	e84a                	sd	s2,16(sp)
    8000509c:	1800                	addi	s0,sp,48
    8000509e:	892e                	mv	s2,a1
    800050a0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050a2:	fdc40593          	addi	a1,s0,-36
    800050a6:	ffffe097          	auipc	ra,0xffffe
    800050aa:	b10080e7          	jalr	-1264(ra) # 80002bb6 <argint>
    800050ae:	04054063          	bltz	a0,800050ee <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050b2:	fdc42703          	lw	a4,-36(s0)
    800050b6:	47bd                	li	a5,15
    800050b8:	02e7ed63          	bltu	a5,a4,800050f2 <argfd+0x60>
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	96c080e7          	jalr	-1684(ra) # 80001a28 <myproc>
    800050c4:	fdc42703          	lw	a4,-36(s0)
    800050c8:	01a70793          	addi	a5,a4,26
    800050cc:	078e                	slli	a5,a5,0x3
    800050ce:	953e                	add	a0,a0,a5
    800050d0:	611c                	ld	a5,0(a0)
    800050d2:	c395                	beqz	a5,800050f6 <argfd+0x64>
    return -1;
  if(pfd)
    800050d4:	00090463          	beqz	s2,800050dc <argfd+0x4a>
    *pfd = fd;
    800050d8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050dc:	4501                	li	a0,0
  if(pf)
    800050de:	c091                	beqz	s1,800050e2 <argfd+0x50>
    *pf = f;
    800050e0:	e09c                	sd	a5,0(s1)
}
    800050e2:	70a2                	ld	ra,40(sp)
    800050e4:	7402                	ld	s0,32(sp)
    800050e6:	64e2                	ld	s1,24(sp)
    800050e8:	6942                	ld	s2,16(sp)
    800050ea:	6145                	addi	sp,sp,48
    800050ec:	8082                	ret
    return -1;
    800050ee:	557d                	li	a0,-1
    800050f0:	bfcd                	j	800050e2 <argfd+0x50>
    return -1;
    800050f2:	557d                	li	a0,-1
    800050f4:	b7fd                	j	800050e2 <argfd+0x50>
    800050f6:	557d                	li	a0,-1
    800050f8:	b7ed                	j	800050e2 <argfd+0x50>

00000000800050fa <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050fa:	1101                	addi	sp,sp,-32
    800050fc:	ec06                	sd	ra,24(sp)
    800050fe:	e822                	sd	s0,16(sp)
    80005100:	e426                	sd	s1,8(sp)
    80005102:	1000                	addi	s0,sp,32
    80005104:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	922080e7          	jalr	-1758(ra) # 80001a28 <myproc>
    8000510e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005110:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005114:	4501                	li	a0,0
    80005116:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005118:	6398                	ld	a4,0(a5)
    8000511a:	cb19                	beqz	a4,80005130 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000511c:	2505                	addiw	a0,a0,1
    8000511e:	07a1                	addi	a5,a5,8
    80005120:	fed51ce3          	bne	a0,a3,80005118 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005124:	557d                	li	a0,-1
}
    80005126:	60e2                	ld	ra,24(sp)
    80005128:	6442                	ld	s0,16(sp)
    8000512a:	64a2                	ld	s1,8(sp)
    8000512c:	6105                	addi	sp,sp,32
    8000512e:	8082                	ret
      p->ofile[fd] = f;
    80005130:	01a50793          	addi	a5,a0,26
    80005134:	078e                	slli	a5,a5,0x3
    80005136:	963e                	add	a2,a2,a5
    80005138:	e204                	sd	s1,0(a2)
      return fd;
    8000513a:	b7f5                	j	80005126 <fdalloc+0x2c>

000000008000513c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000513c:	715d                	addi	sp,sp,-80
    8000513e:	e486                	sd	ra,72(sp)
    80005140:	e0a2                	sd	s0,64(sp)
    80005142:	fc26                	sd	s1,56(sp)
    80005144:	f84a                	sd	s2,48(sp)
    80005146:	f44e                	sd	s3,40(sp)
    80005148:	f052                	sd	s4,32(sp)
    8000514a:	ec56                	sd	s5,24(sp)
    8000514c:	0880                	addi	s0,sp,80
    8000514e:	89ae                	mv	s3,a1
    80005150:	8ab2                	mv	s5,a2
    80005152:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005154:	fb040593          	addi	a1,s0,-80
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	e40080e7          	jalr	-448(ra) # 80003f98 <nameiparent>
    80005160:	892a                	mv	s2,a0
    80005162:	12050f63          	beqz	a0,800052a0 <create+0x164>
    return 0;

  ilock(dp);
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	664080e7          	jalr	1636(ra) # 800037ca <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000516e:	4601                	li	a2,0
    80005170:	fb040593          	addi	a1,s0,-80
    80005174:	854a                	mv	a0,s2
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	b32080e7          	jalr	-1230(ra) # 80003ca8 <dirlookup>
    8000517e:	84aa                	mv	s1,a0
    80005180:	c921                	beqz	a0,800051d0 <create+0x94>
    iunlockput(dp);
    80005182:	854a                	mv	a0,s2
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	8a8080e7          	jalr	-1880(ra) # 80003a2c <iunlockput>
    ilock(ip);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	63c080e7          	jalr	1596(ra) # 800037ca <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005196:	2981                	sext.w	s3,s3
    80005198:	4789                	li	a5,2
    8000519a:	02f99463          	bne	s3,a5,800051c2 <create+0x86>
    8000519e:	0444d783          	lhu	a5,68(s1)
    800051a2:	37f9                	addiw	a5,a5,-2
    800051a4:	17c2                	slli	a5,a5,0x30
    800051a6:	93c1                	srli	a5,a5,0x30
    800051a8:	4705                	li	a4,1
    800051aa:	00f76c63          	bltu	a4,a5,800051c2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ae:	8526                	mv	a0,s1
    800051b0:	60a6                	ld	ra,72(sp)
    800051b2:	6406                	ld	s0,64(sp)
    800051b4:	74e2                	ld	s1,56(sp)
    800051b6:	7942                	ld	s2,48(sp)
    800051b8:	79a2                	ld	s3,40(sp)
    800051ba:	7a02                	ld	s4,32(sp)
    800051bc:	6ae2                	ld	s5,24(sp)
    800051be:	6161                	addi	sp,sp,80
    800051c0:	8082                	ret
    iunlockput(ip);
    800051c2:	8526                	mv	a0,s1
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	868080e7          	jalr	-1944(ra) # 80003a2c <iunlockput>
    return 0;
    800051cc:	4481                	li	s1,0
    800051ce:	b7c5                	j	800051ae <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051d0:	85ce                	mv	a1,s3
    800051d2:	00092503          	lw	a0,0(s2)
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	45c080e7          	jalr	1116(ra) # 80003632 <ialloc>
    800051de:	84aa                	mv	s1,a0
    800051e0:	c529                	beqz	a0,8000522a <create+0xee>
  ilock(ip);
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	5e8080e7          	jalr	1512(ra) # 800037ca <ilock>
  ip->major = major;
    800051ea:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051ee:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051f2:	4785                	li	a5,1
    800051f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051f8:	8526                	mv	a0,s1
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	506080e7          	jalr	1286(ra) # 80003700 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005202:	2981                	sext.w	s3,s3
    80005204:	4785                	li	a5,1
    80005206:	02f98a63          	beq	s3,a5,8000523a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000520a:	40d0                	lw	a2,4(s1)
    8000520c:	fb040593          	addi	a1,s0,-80
    80005210:	854a                	mv	a0,s2
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	ca6080e7          	jalr	-858(ra) # 80003eb8 <dirlink>
    8000521a:	06054b63          	bltz	a0,80005290 <create+0x154>
  iunlockput(dp);
    8000521e:	854a                	mv	a0,s2
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	80c080e7          	jalr	-2036(ra) # 80003a2c <iunlockput>
  return ip;
    80005228:	b759                	j	800051ae <create+0x72>
    panic("create: ialloc");
    8000522a:	00003517          	auipc	a0,0x3
    8000522e:	71e50513          	addi	a0,a0,1822 # 80008948 <syscall_name+0x2f0>
    80005232:	ffffb097          	auipc	ra,0xffffb
    80005236:	316080e7          	jalr	790(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000523a:	04a95783          	lhu	a5,74(s2)
    8000523e:	2785                	addiw	a5,a5,1
    80005240:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005244:	854a                	mv	a0,s2
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	4ba080e7          	jalr	1210(ra) # 80003700 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000524e:	40d0                	lw	a2,4(s1)
    80005250:	00003597          	auipc	a1,0x3
    80005254:	70858593          	addi	a1,a1,1800 # 80008958 <syscall_name+0x300>
    80005258:	8526                	mv	a0,s1
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	c5e080e7          	jalr	-930(ra) # 80003eb8 <dirlink>
    80005262:	00054f63          	bltz	a0,80005280 <create+0x144>
    80005266:	00492603          	lw	a2,4(s2)
    8000526a:	00003597          	auipc	a1,0x3
    8000526e:	6f658593          	addi	a1,a1,1782 # 80008960 <syscall_name+0x308>
    80005272:	8526                	mv	a0,s1
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	c44080e7          	jalr	-956(ra) # 80003eb8 <dirlink>
    8000527c:	f80557e3          	bgez	a0,8000520a <create+0xce>
      panic("create dots");
    80005280:	00003517          	auipc	a0,0x3
    80005284:	6e850513          	addi	a0,a0,1768 # 80008968 <syscall_name+0x310>
    80005288:	ffffb097          	auipc	ra,0xffffb
    8000528c:	2c0080e7          	jalr	704(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005290:	00003517          	auipc	a0,0x3
    80005294:	6e850513          	addi	a0,a0,1768 # 80008978 <syscall_name+0x320>
    80005298:	ffffb097          	auipc	ra,0xffffb
    8000529c:	2b0080e7          	jalr	688(ra) # 80000548 <panic>
    return 0;
    800052a0:	84aa                	mv	s1,a0
    800052a2:	b731                	j	800051ae <create+0x72>

00000000800052a4 <sys_dup>:
{
    800052a4:	7179                	addi	sp,sp,-48
    800052a6:	f406                	sd	ra,40(sp)
    800052a8:	f022                	sd	s0,32(sp)
    800052aa:	ec26                	sd	s1,24(sp)
    800052ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ae:	fd840613          	addi	a2,s0,-40
    800052b2:	4581                	li	a1,0
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	ddc080e7          	jalr	-548(ra) # 80005092 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c0:	02054363          	bltz	a0,800052e6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052c4:	fd843503          	ld	a0,-40(s0)
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	e32080e7          	jalr	-462(ra) # 800050fa <fdalloc>
    800052d0:	84aa                	mv	s1,a0
    return -1;
    800052d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052d4:	00054963          	bltz	a0,800052e6 <sys_dup+0x42>
  filedup(f);
    800052d8:	fd843503          	ld	a0,-40(s0)
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	32a080e7          	jalr	810(ra) # 80004606 <filedup>
  return fd;
    800052e4:	87a6                	mv	a5,s1
}
    800052e6:	853e                	mv	a0,a5
    800052e8:	70a2                	ld	ra,40(sp)
    800052ea:	7402                	ld	s0,32(sp)
    800052ec:	64e2                	ld	s1,24(sp)
    800052ee:	6145                	addi	sp,sp,48
    800052f0:	8082                	ret

00000000800052f2 <sys_read>:
{
    800052f2:	7179                	addi	sp,sp,-48
    800052f4:	f406                	sd	ra,40(sp)
    800052f6:	f022                	sd	s0,32(sp)
    800052f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	fe840613          	addi	a2,s0,-24
    800052fe:	4581                	li	a1,0
    80005300:	4501                	li	a0,0
    80005302:	00000097          	auipc	ra,0x0
    80005306:	d90080e7          	jalr	-624(ra) # 80005092 <argfd>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	04054163          	bltz	a0,8000534e <sys_read+0x5c>
    80005310:	fe440593          	addi	a1,s0,-28
    80005314:	4509                	li	a0,2
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	8a0080e7          	jalr	-1888(ra) # 80002bb6 <argint>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005320:	02054763          	bltz	a0,8000534e <sys_read+0x5c>
    80005324:	fd840593          	addi	a1,s0,-40
    80005328:	4505                	li	a0,1
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	8ae080e7          	jalr	-1874(ra) # 80002bd8 <argaddr>
    return -1;
    80005332:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005334:	00054d63          	bltz	a0,8000534e <sys_read+0x5c>
  return fileread(f, p, n);
    80005338:	fe442603          	lw	a2,-28(s0)
    8000533c:	fd843583          	ld	a1,-40(s0)
    80005340:	fe843503          	ld	a0,-24(s0)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	44e080e7          	jalr	1102(ra) # 80004792 <fileread>
    8000534c:	87aa                	mv	a5,a0
}
    8000534e:	853e                	mv	a0,a5
    80005350:	70a2                	ld	ra,40(sp)
    80005352:	7402                	ld	s0,32(sp)
    80005354:	6145                	addi	sp,sp,48
    80005356:	8082                	ret

0000000080005358 <sys_write>:
{
    80005358:	7179                	addi	sp,sp,-48
    8000535a:	f406                	sd	ra,40(sp)
    8000535c:	f022                	sd	s0,32(sp)
    8000535e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	fe840613          	addi	a2,s0,-24
    80005364:	4581                	li	a1,0
    80005366:	4501                	li	a0,0
    80005368:	00000097          	auipc	ra,0x0
    8000536c:	d2a080e7          	jalr	-726(ra) # 80005092 <argfd>
    return -1;
    80005370:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005372:	04054163          	bltz	a0,800053b4 <sys_write+0x5c>
    80005376:	fe440593          	addi	a1,s0,-28
    8000537a:	4509                	li	a0,2
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	83a080e7          	jalr	-1990(ra) # 80002bb6 <argint>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	02054763          	bltz	a0,800053b4 <sys_write+0x5c>
    8000538a:	fd840593          	addi	a1,s0,-40
    8000538e:	4505                	li	a0,1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	848080e7          	jalr	-1976(ra) # 80002bd8 <argaddr>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	00054d63          	bltz	a0,800053b4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000539e:	fe442603          	lw	a2,-28(s0)
    800053a2:	fd843583          	ld	a1,-40(s0)
    800053a6:	fe843503          	ld	a0,-24(s0)
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	4aa080e7          	jalr	1194(ra) # 80004854 <filewrite>
    800053b2:	87aa                	mv	a5,a0
}
    800053b4:	853e                	mv	a0,a5
    800053b6:	70a2                	ld	ra,40(sp)
    800053b8:	7402                	ld	s0,32(sp)
    800053ba:	6145                	addi	sp,sp,48
    800053bc:	8082                	ret

00000000800053be <sys_close>:
{
    800053be:	1101                	addi	sp,sp,-32
    800053c0:	ec06                	sd	ra,24(sp)
    800053c2:	e822                	sd	s0,16(sp)
    800053c4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053c6:	fe040613          	addi	a2,s0,-32
    800053ca:	fec40593          	addi	a1,s0,-20
    800053ce:	4501                	li	a0,0
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	cc2080e7          	jalr	-830(ra) # 80005092 <argfd>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053da:	02054463          	bltz	a0,80005402 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053de:	ffffc097          	auipc	ra,0xffffc
    800053e2:	64a080e7          	jalr	1610(ra) # 80001a28 <myproc>
    800053e6:	fec42783          	lw	a5,-20(s0)
    800053ea:	07e9                	addi	a5,a5,26
    800053ec:	078e                	slli	a5,a5,0x3
    800053ee:	97aa                	add	a5,a5,a0
    800053f0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053f4:	fe043503          	ld	a0,-32(s0)
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	260080e7          	jalr	608(ra) # 80004658 <fileclose>
  return 0;
    80005400:	4781                	li	a5,0
}
    80005402:	853e                	mv	a0,a5
    80005404:	60e2                	ld	ra,24(sp)
    80005406:	6442                	ld	s0,16(sp)
    80005408:	6105                	addi	sp,sp,32
    8000540a:	8082                	ret

000000008000540c <sys_fstat>:
{
    8000540c:	1101                	addi	sp,sp,-32
    8000540e:	ec06                	sd	ra,24(sp)
    80005410:	e822                	sd	s0,16(sp)
    80005412:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005414:	fe840613          	addi	a2,s0,-24
    80005418:	4581                	li	a1,0
    8000541a:	4501                	li	a0,0
    8000541c:	00000097          	auipc	ra,0x0
    80005420:	c76080e7          	jalr	-906(ra) # 80005092 <argfd>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005426:	02054563          	bltz	a0,80005450 <sys_fstat+0x44>
    8000542a:	fe040593          	addi	a1,s0,-32
    8000542e:	4505                	li	a0,1
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	7a8080e7          	jalr	1960(ra) # 80002bd8 <argaddr>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000543a:	00054b63          	bltz	a0,80005450 <sys_fstat+0x44>
  return filestat(f, st);
    8000543e:	fe043583          	ld	a1,-32(s0)
    80005442:	fe843503          	ld	a0,-24(s0)
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	2da080e7          	jalr	730(ra) # 80004720 <filestat>
    8000544e:	87aa                	mv	a5,a0
}
    80005450:	853e                	mv	a0,a5
    80005452:	60e2                	ld	ra,24(sp)
    80005454:	6442                	ld	s0,16(sp)
    80005456:	6105                	addi	sp,sp,32
    80005458:	8082                	ret

000000008000545a <sys_link>:
{
    8000545a:	7169                	addi	sp,sp,-304
    8000545c:	f606                	sd	ra,296(sp)
    8000545e:	f222                	sd	s0,288(sp)
    80005460:	ee26                	sd	s1,280(sp)
    80005462:	ea4a                	sd	s2,272(sp)
    80005464:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005466:	08000613          	li	a2,128
    8000546a:	ed040593          	addi	a1,s0,-304
    8000546e:	4501                	li	a0,0
    80005470:	ffffd097          	auipc	ra,0xffffd
    80005474:	78a080e7          	jalr	1930(ra) # 80002bfa <argstr>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547a:	10054e63          	bltz	a0,80005596 <sys_link+0x13c>
    8000547e:	08000613          	li	a2,128
    80005482:	f5040593          	addi	a1,s0,-176
    80005486:	4505                	li	a0,1
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	772080e7          	jalr	1906(ra) # 80002bfa <argstr>
    return -1;
    80005490:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005492:	10054263          	bltz	a0,80005596 <sys_link+0x13c>
  begin_op();
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	cf0080e7          	jalr	-784(ra) # 80004186 <begin_op>
  if((ip = namei(old)) == 0){
    8000549e:	ed040513          	addi	a0,s0,-304
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	ad8080e7          	jalr	-1320(ra) # 80003f7a <namei>
    800054aa:	84aa                	mv	s1,a0
    800054ac:	c551                	beqz	a0,80005538 <sys_link+0xde>
  ilock(ip);
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	31c080e7          	jalr	796(ra) # 800037ca <ilock>
  if(ip->type == T_DIR){
    800054b6:	04449703          	lh	a4,68(s1)
    800054ba:	4785                	li	a5,1
    800054bc:	08f70463          	beq	a4,a5,80005544 <sys_link+0xea>
  ip->nlink++;
    800054c0:	04a4d783          	lhu	a5,74(s1)
    800054c4:	2785                	addiw	a5,a5,1
    800054c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	234080e7          	jalr	564(ra) # 80003700 <iupdate>
  iunlock(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	3b6080e7          	jalr	950(ra) # 8000388c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054de:	fd040593          	addi	a1,s0,-48
    800054e2:	f5040513          	addi	a0,s0,-176
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	ab2080e7          	jalr	-1358(ra) # 80003f98 <nameiparent>
    800054ee:	892a                	mv	s2,a0
    800054f0:	c935                	beqz	a0,80005564 <sys_link+0x10a>
  ilock(dp);
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	2d8080e7          	jalr	728(ra) # 800037ca <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054fa:	00092703          	lw	a4,0(s2)
    800054fe:	409c                	lw	a5,0(s1)
    80005500:	04f71d63          	bne	a4,a5,8000555a <sys_link+0x100>
    80005504:	40d0                	lw	a2,4(s1)
    80005506:	fd040593          	addi	a1,s0,-48
    8000550a:	854a                	mv	a0,s2
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	9ac080e7          	jalr	-1620(ra) # 80003eb8 <dirlink>
    80005514:	04054363          	bltz	a0,8000555a <sys_link+0x100>
  iunlockput(dp);
    80005518:	854a                	mv	a0,s2
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	512080e7          	jalr	1298(ra) # 80003a2c <iunlockput>
  iput(ip);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	460080e7          	jalr	1120(ra) # 80003984 <iput>
  end_op();
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	cda080e7          	jalr	-806(ra) # 80004206 <end_op>
  return 0;
    80005534:	4781                	li	a5,0
    80005536:	a085                	j	80005596 <sys_link+0x13c>
    end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	cce080e7          	jalr	-818(ra) # 80004206 <end_op>
    return -1;
    80005540:	57fd                	li	a5,-1
    80005542:	a891                	j	80005596 <sys_link+0x13c>
    iunlockput(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	4e6080e7          	jalr	1254(ra) # 80003a2c <iunlockput>
    end_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	cb8080e7          	jalr	-840(ra) # 80004206 <end_op>
    return -1;
    80005556:	57fd                	li	a5,-1
    80005558:	a83d                	j	80005596 <sys_link+0x13c>
    iunlockput(dp);
    8000555a:	854a                	mv	a0,s2
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	4d0080e7          	jalr	1232(ra) # 80003a2c <iunlockput>
  ilock(ip);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	264080e7          	jalr	612(ra) # 800037ca <ilock>
  ip->nlink--;
    8000556e:	04a4d783          	lhu	a5,74(s1)
    80005572:	37fd                	addiw	a5,a5,-1
    80005574:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	186080e7          	jalr	390(ra) # 80003700 <iupdate>
  iunlockput(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	4a8080e7          	jalr	1192(ra) # 80003a2c <iunlockput>
  end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	c7a080e7          	jalr	-902(ra) # 80004206 <end_op>
  return -1;
    80005594:	57fd                	li	a5,-1
}
    80005596:	853e                	mv	a0,a5
    80005598:	70b2                	ld	ra,296(sp)
    8000559a:	7412                	ld	s0,288(sp)
    8000559c:	64f2                	ld	s1,280(sp)
    8000559e:	6952                	ld	s2,272(sp)
    800055a0:	6155                	addi	sp,sp,304
    800055a2:	8082                	ret

00000000800055a4 <sys_unlink>:
{
    800055a4:	7151                	addi	sp,sp,-240
    800055a6:	f586                	sd	ra,232(sp)
    800055a8:	f1a2                	sd	s0,224(sp)
    800055aa:	eda6                	sd	s1,216(sp)
    800055ac:	e9ca                	sd	s2,208(sp)
    800055ae:	e5ce                	sd	s3,200(sp)
    800055b0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055b2:	08000613          	li	a2,128
    800055b6:	f3040593          	addi	a1,s0,-208
    800055ba:	4501                	li	a0,0
    800055bc:	ffffd097          	auipc	ra,0xffffd
    800055c0:	63e080e7          	jalr	1598(ra) # 80002bfa <argstr>
    800055c4:	18054163          	bltz	a0,80005746 <sys_unlink+0x1a2>
  begin_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	bbe080e7          	jalr	-1090(ra) # 80004186 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055d0:	fb040593          	addi	a1,s0,-80
    800055d4:	f3040513          	addi	a0,s0,-208
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	9c0080e7          	jalr	-1600(ra) # 80003f98 <nameiparent>
    800055e0:	84aa                	mv	s1,a0
    800055e2:	c979                	beqz	a0,800056b8 <sys_unlink+0x114>
  ilock(dp);
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	1e6080e7          	jalr	486(ra) # 800037ca <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ec:	00003597          	auipc	a1,0x3
    800055f0:	36c58593          	addi	a1,a1,876 # 80008958 <syscall_name+0x300>
    800055f4:	fb040513          	addi	a0,s0,-80
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	696080e7          	jalr	1686(ra) # 80003c8e <namecmp>
    80005600:	14050a63          	beqz	a0,80005754 <sys_unlink+0x1b0>
    80005604:	00003597          	auipc	a1,0x3
    80005608:	35c58593          	addi	a1,a1,860 # 80008960 <syscall_name+0x308>
    8000560c:	fb040513          	addi	a0,s0,-80
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	67e080e7          	jalr	1662(ra) # 80003c8e <namecmp>
    80005618:	12050e63          	beqz	a0,80005754 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000561c:	f2c40613          	addi	a2,s0,-212
    80005620:	fb040593          	addi	a1,s0,-80
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	682080e7          	jalr	1666(ra) # 80003ca8 <dirlookup>
    8000562e:	892a                	mv	s2,a0
    80005630:	12050263          	beqz	a0,80005754 <sys_unlink+0x1b0>
  ilock(ip);
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	196080e7          	jalr	406(ra) # 800037ca <ilock>
  if(ip->nlink < 1)
    8000563c:	04a91783          	lh	a5,74(s2)
    80005640:	08f05263          	blez	a5,800056c4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005644:	04491703          	lh	a4,68(s2)
    80005648:	4785                	li	a5,1
    8000564a:	08f70563          	beq	a4,a5,800056d4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000564e:	4641                	li	a2,16
    80005650:	4581                	li	a1,0
    80005652:	fc040513          	addi	a0,s0,-64
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	700080e7          	jalr	1792(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000565e:	4741                	li	a4,16
    80005660:	f2c42683          	lw	a3,-212(s0)
    80005664:	fc040613          	addi	a2,s0,-64
    80005668:	4581                	li	a1,0
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	508080e7          	jalr	1288(ra) # 80003b74 <writei>
    80005674:	47c1                	li	a5,16
    80005676:	0af51563          	bne	a0,a5,80005720 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000567a:	04491703          	lh	a4,68(s2)
    8000567e:	4785                	li	a5,1
    80005680:	0af70863          	beq	a4,a5,80005730 <sys_unlink+0x18c>
  iunlockput(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	3a6080e7          	jalr	934(ra) # 80003a2c <iunlockput>
  ip->nlink--;
    8000568e:	04a95783          	lhu	a5,74(s2)
    80005692:	37fd                	addiw	a5,a5,-1
    80005694:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	066080e7          	jalr	102(ra) # 80003700 <iupdate>
  iunlockput(ip);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	388080e7          	jalr	904(ra) # 80003a2c <iunlockput>
  end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	b5a080e7          	jalr	-1190(ra) # 80004206 <end_op>
  return 0;
    800056b4:	4501                	li	a0,0
    800056b6:	a84d                	j	80005768 <sys_unlink+0x1c4>
    end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	b4e080e7          	jalr	-1202(ra) # 80004206 <end_op>
    return -1;
    800056c0:	557d                	li	a0,-1
    800056c2:	a05d                	j	80005768 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056c4:	00003517          	auipc	a0,0x3
    800056c8:	2c450513          	addi	a0,a0,708 # 80008988 <syscall_name+0x330>
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	e7c080e7          	jalr	-388(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d4:	04c92703          	lw	a4,76(s2)
    800056d8:	02000793          	li	a5,32
    800056dc:	f6e7f9e3          	bgeu	a5,a4,8000564e <sys_unlink+0xaa>
    800056e0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056e4:	4741                	li	a4,16
    800056e6:	86ce                	mv	a3,s3
    800056e8:	f1840613          	addi	a2,s0,-232
    800056ec:	4581                	li	a1,0
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	38e080e7          	jalr	910(ra) # 80003a7e <readi>
    800056f8:	47c1                	li	a5,16
    800056fa:	00f51b63          	bne	a0,a5,80005710 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056fe:	f1845783          	lhu	a5,-232(s0)
    80005702:	e7a1                	bnez	a5,8000574a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005704:	29c1                	addiw	s3,s3,16
    80005706:	04c92783          	lw	a5,76(s2)
    8000570a:	fcf9ede3          	bltu	s3,a5,800056e4 <sys_unlink+0x140>
    8000570e:	b781                	j	8000564e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	29050513          	addi	a0,a0,656 # 800089a0 <syscall_name+0x348>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e30080e7          	jalr	-464(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	29850513          	addi	a0,a0,664 # 800089b8 <syscall_name+0x360>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e20080e7          	jalr	-480(ra) # 80000548 <panic>
    dp->nlink--;
    80005730:	04a4d783          	lhu	a5,74(s1)
    80005734:	37fd                	addiw	a5,a5,-1
    80005736:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	fc4080e7          	jalr	-60(ra) # 80003700 <iupdate>
    80005744:	b781                	j	80005684 <sys_unlink+0xe0>
    return -1;
    80005746:	557d                	li	a0,-1
    80005748:	a005                	j	80005768 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	2e0080e7          	jalr	736(ra) # 80003a2c <iunlockput>
  iunlockput(dp);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	2d6080e7          	jalr	726(ra) # 80003a2c <iunlockput>
  end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	aa8080e7          	jalr	-1368(ra) # 80004206 <end_op>
  return -1;
    80005766:	557d                	li	a0,-1
}
    80005768:	70ae                	ld	ra,232(sp)
    8000576a:	740e                	ld	s0,224(sp)
    8000576c:	64ee                	ld	s1,216(sp)
    8000576e:	694e                	ld	s2,208(sp)
    80005770:	69ae                	ld	s3,200(sp)
    80005772:	616d                	addi	sp,sp,240
    80005774:	8082                	ret

0000000080005776 <sys_open>:

uint64
sys_open(void)
{
    80005776:	7131                	addi	sp,sp,-192
    80005778:	fd06                	sd	ra,184(sp)
    8000577a:	f922                	sd	s0,176(sp)
    8000577c:	f526                	sd	s1,168(sp)
    8000577e:	f14a                	sd	s2,160(sp)
    80005780:	ed4e                	sd	s3,152(sp)
    80005782:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005784:	08000613          	li	a2,128
    80005788:	f5040593          	addi	a1,s0,-176
    8000578c:	4501                	li	a0,0
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	46c080e7          	jalr	1132(ra) # 80002bfa <argstr>
    return -1;
    80005796:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005798:	0c054163          	bltz	a0,8000585a <sys_open+0xe4>
    8000579c:	f4c40593          	addi	a1,s0,-180
    800057a0:	4505                	li	a0,1
    800057a2:	ffffd097          	auipc	ra,0xffffd
    800057a6:	414080e7          	jalr	1044(ra) # 80002bb6 <argint>
    800057aa:	0a054863          	bltz	a0,8000585a <sys_open+0xe4>

  begin_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	9d8080e7          	jalr	-1576(ra) # 80004186 <begin_op>

  if(omode & O_CREATE){
    800057b6:	f4c42783          	lw	a5,-180(s0)
    800057ba:	2007f793          	andi	a5,a5,512
    800057be:	cbdd                	beqz	a5,80005874 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057c0:	4681                	li	a3,0
    800057c2:	4601                	li	a2,0
    800057c4:	4589                	li	a1,2
    800057c6:	f5040513          	addi	a0,s0,-176
    800057ca:	00000097          	auipc	ra,0x0
    800057ce:	972080e7          	jalr	-1678(ra) # 8000513c <create>
    800057d2:	892a                	mv	s2,a0
    if(ip == 0){
    800057d4:	c959                	beqz	a0,8000586a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057d6:	04491703          	lh	a4,68(s2)
    800057da:	478d                	li	a5,3
    800057dc:	00f71763          	bne	a4,a5,800057ea <sys_open+0x74>
    800057e0:	04695703          	lhu	a4,70(s2)
    800057e4:	47a5                	li	a5,9
    800057e6:	0ce7ec63          	bltu	a5,a4,800058be <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	db2080e7          	jalr	-590(ra) # 8000459c <filealloc>
    800057f2:	89aa                	mv	s3,a0
    800057f4:	10050263          	beqz	a0,800058f8 <sys_open+0x182>
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	902080e7          	jalr	-1790(ra) # 800050fa <fdalloc>
    80005800:	84aa                	mv	s1,a0
    80005802:	0e054663          	bltz	a0,800058ee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005806:	04491703          	lh	a4,68(s2)
    8000580a:	478d                	li	a5,3
    8000580c:	0cf70463          	beq	a4,a5,800058d4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005810:	4789                	li	a5,2
    80005812:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005816:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000581a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000581e:	f4c42783          	lw	a5,-180(s0)
    80005822:	0017c713          	xori	a4,a5,1
    80005826:	8b05                	andi	a4,a4,1
    80005828:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000582c:	0037f713          	andi	a4,a5,3
    80005830:	00e03733          	snez	a4,a4
    80005834:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005838:	4007f793          	andi	a5,a5,1024
    8000583c:	c791                	beqz	a5,80005848 <sys_open+0xd2>
    8000583e:	04491703          	lh	a4,68(s2)
    80005842:	4789                	li	a5,2
    80005844:	08f70f63          	beq	a4,a5,800058e2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	042080e7          	jalr	66(ra) # 8000388c <iunlock>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9b4080e7          	jalr	-1612(ra) # 80004206 <end_op>

  return fd;
}
    8000585a:	8526                	mv	a0,s1
    8000585c:	70ea                	ld	ra,184(sp)
    8000585e:	744a                	ld	s0,176(sp)
    80005860:	74aa                	ld	s1,168(sp)
    80005862:	790a                	ld	s2,160(sp)
    80005864:	69ea                	ld	s3,152(sp)
    80005866:	6129                	addi	sp,sp,192
    80005868:	8082                	ret
      end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	99c080e7          	jalr	-1636(ra) # 80004206 <end_op>
      return -1;
    80005872:	b7e5                	j	8000585a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005874:	f5040513          	addi	a0,s0,-176
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	702080e7          	jalr	1794(ra) # 80003f7a <namei>
    80005880:	892a                	mv	s2,a0
    80005882:	c905                	beqz	a0,800058b2 <sys_open+0x13c>
    ilock(ip);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	f46080e7          	jalr	-186(ra) # 800037ca <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000588c:	04491703          	lh	a4,68(s2)
    80005890:	4785                	li	a5,1
    80005892:	f4f712e3          	bne	a4,a5,800057d6 <sys_open+0x60>
    80005896:	f4c42783          	lw	a5,-180(s0)
    8000589a:	dba1                	beqz	a5,800057ea <sys_open+0x74>
      iunlockput(ip);
    8000589c:	854a                	mv	a0,s2
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	18e080e7          	jalr	398(ra) # 80003a2c <iunlockput>
      end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	960080e7          	jalr	-1696(ra) # 80004206 <end_op>
      return -1;
    800058ae:	54fd                	li	s1,-1
    800058b0:	b76d                	j	8000585a <sys_open+0xe4>
      end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	954080e7          	jalr	-1708(ra) # 80004206 <end_op>
      return -1;
    800058ba:	54fd                	li	s1,-1
    800058bc:	bf79                	j	8000585a <sys_open+0xe4>
    iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	16c080e7          	jalr	364(ra) # 80003a2c <iunlockput>
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	93e080e7          	jalr	-1730(ra) # 80004206 <end_op>
    return -1;
    800058d0:	54fd                	li	s1,-1
    800058d2:	b761                	j	8000585a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058d4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058d8:	04691783          	lh	a5,70(s2)
    800058dc:	02f99223          	sh	a5,36(s3)
    800058e0:	bf2d                	j	8000581a <sys_open+0xa4>
    itrunc(ip);
    800058e2:	854a                	mv	a0,s2
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	ff4080e7          	jalr	-12(ra) # 800038d8 <itrunc>
    800058ec:	bfb1                	j	80005848 <sys_open+0xd2>
      fileclose(f);
    800058ee:	854e                	mv	a0,s3
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	d68080e7          	jalr	-664(ra) # 80004658 <fileclose>
    iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	132080e7          	jalr	306(ra) # 80003a2c <iunlockput>
    end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	904080e7          	jalr	-1788(ra) # 80004206 <end_op>
    return -1;
    8000590a:	54fd                	li	s1,-1
    8000590c:	b7b9                	j	8000585a <sys_open+0xe4>

000000008000590e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000590e:	7175                	addi	sp,sp,-144
    80005910:	e506                	sd	ra,136(sp)
    80005912:	e122                	sd	s0,128(sp)
    80005914:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	870080e7          	jalr	-1936(ra) # 80004186 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000591e:	08000613          	li	a2,128
    80005922:	f7040593          	addi	a1,s0,-144
    80005926:	4501                	li	a0,0
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	2d2080e7          	jalr	722(ra) # 80002bfa <argstr>
    80005930:	02054963          	bltz	a0,80005962 <sys_mkdir+0x54>
    80005934:	4681                	li	a3,0
    80005936:	4601                	li	a2,0
    80005938:	4585                	li	a1,1
    8000593a:	f7040513          	addi	a0,s0,-144
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	7fe080e7          	jalr	2046(ra) # 8000513c <create>
    80005946:	cd11                	beqz	a0,80005962 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	0e4080e7          	jalr	228(ra) # 80003a2c <iunlockput>
  end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	8b6080e7          	jalr	-1866(ra) # 80004206 <end_op>
  return 0;
    80005958:	4501                	li	a0,0
}
    8000595a:	60aa                	ld	ra,136(sp)
    8000595c:	640a                	ld	s0,128(sp)
    8000595e:	6149                	addi	sp,sp,144
    80005960:	8082                	ret
    end_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	8a4080e7          	jalr	-1884(ra) # 80004206 <end_op>
    return -1;
    8000596a:	557d                	li	a0,-1
    8000596c:	b7fd                	j	8000595a <sys_mkdir+0x4c>

000000008000596e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000596e:	7135                	addi	sp,sp,-160
    80005970:	ed06                	sd	ra,152(sp)
    80005972:	e922                	sd	s0,144(sp)
    80005974:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	810080e7          	jalr	-2032(ra) # 80004186 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597e:	08000613          	li	a2,128
    80005982:	f7040593          	addi	a1,s0,-144
    80005986:	4501                	li	a0,0
    80005988:	ffffd097          	auipc	ra,0xffffd
    8000598c:	272080e7          	jalr	626(ra) # 80002bfa <argstr>
    80005990:	04054a63          	bltz	a0,800059e4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005994:	f6c40593          	addi	a1,s0,-148
    80005998:	4505                	li	a0,1
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	21c080e7          	jalr	540(ra) # 80002bb6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a2:	04054163          	bltz	a0,800059e4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059a6:	f6840593          	addi	a1,s0,-152
    800059aa:	4509                	li	a0,2
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	20a080e7          	jalr	522(ra) # 80002bb6 <argint>
     argint(1, &major) < 0 ||
    800059b4:	02054863          	bltz	a0,800059e4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059b8:	f6841683          	lh	a3,-152(s0)
    800059bc:	f6c41603          	lh	a2,-148(s0)
    800059c0:	458d                	li	a1,3
    800059c2:	f7040513          	addi	a0,s0,-144
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	776080e7          	jalr	1910(ra) # 8000513c <create>
     argint(2, &minor) < 0 ||
    800059ce:	c919                	beqz	a0,800059e4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	05c080e7          	jalr	92(ra) # 80003a2c <iunlockput>
  end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	82e080e7          	jalr	-2002(ra) # 80004206 <end_op>
  return 0;
    800059e0:	4501                	li	a0,0
    800059e2:	a031                	j	800059ee <sys_mknod+0x80>
    end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	822080e7          	jalr	-2014(ra) # 80004206 <end_op>
    return -1;
    800059ec:	557d                	li	a0,-1
}
    800059ee:	60ea                	ld	ra,152(sp)
    800059f0:	644a                	ld	s0,144(sp)
    800059f2:	610d                	addi	sp,sp,160
    800059f4:	8082                	ret

00000000800059f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059f6:	7135                	addi	sp,sp,-160
    800059f8:	ed06                	sd	ra,152(sp)
    800059fa:	e922                	sd	s0,144(sp)
    800059fc:	e526                	sd	s1,136(sp)
    800059fe:	e14a                	sd	s2,128(sp)
    80005a00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a02:	ffffc097          	auipc	ra,0xffffc
    80005a06:	026080e7          	jalr	38(ra) # 80001a28 <myproc>
    80005a0a:	892a                	mv	s2,a0
  
  begin_op();
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	77a080e7          	jalr	1914(ra) # 80004186 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a14:	08000613          	li	a2,128
    80005a18:	f6040593          	addi	a1,s0,-160
    80005a1c:	4501                	li	a0,0
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	1dc080e7          	jalr	476(ra) # 80002bfa <argstr>
    80005a26:	04054b63          	bltz	a0,80005a7c <sys_chdir+0x86>
    80005a2a:	f6040513          	addi	a0,s0,-160
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	54c080e7          	jalr	1356(ra) # 80003f7a <namei>
    80005a36:	84aa                	mv	s1,a0
    80005a38:	c131                	beqz	a0,80005a7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	d90080e7          	jalr	-624(ra) # 800037ca <ilock>
  if(ip->type != T_DIR){
    80005a42:	04449703          	lh	a4,68(s1)
    80005a46:	4785                	li	a5,1
    80005a48:	04f71063          	bne	a4,a5,80005a88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	e3e080e7          	jalr	-450(ra) # 8000388c <iunlock>
  iput(p->cwd);
    80005a56:	15093503          	ld	a0,336(s2)
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	f2a080e7          	jalr	-214(ra) # 80003984 <iput>
  end_op();
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	7a4080e7          	jalr	1956(ra) # 80004206 <end_op>
  p->cwd = ip;
    80005a6a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a6e:	4501                	li	a0,0
}
    80005a70:	60ea                	ld	ra,152(sp)
    80005a72:	644a                	ld	s0,144(sp)
    80005a74:	64aa                	ld	s1,136(sp)
    80005a76:	690a                	ld	s2,128(sp)
    80005a78:	610d                	addi	sp,sp,160
    80005a7a:	8082                	ret
    end_op();
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	78a080e7          	jalr	1930(ra) # 80004206 <end_op>
    return -1;
    80005a84:	557d                	li	a0,-1
    80005a86:	b7ed                	j	80005a70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	fa2080e7          	jalr	-94(ra) # 80003a2c <iunlockput>
    end_op();
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	774080e7          	jalr	1908(ra) # 80004206 <end_op>
    return -1;
    80005a9a:	557d                	li	a0,-1
    80005a9c:	bfd1                	j	80005a70 <sys_chdir+0x7a>

0000000080005a9e <sys_exec>:

uint64
sys_exec(void)
{
    80005a9e:	7145                	addi	sp,sp,-464
    80005aa0:	e786                	sd	ra,456(sp)
    80005aa2:	e3a2                	sd	s0,448(sp)
    80005aa4:	ff26                	sd	s1,440(sp)
    80005aa6:	fb4a                	sd	s2,432(sp)
    80005aa8:	f74e                	sd	s3,424(sp)
    80005aaa:	f352                	sd	s4,416(sp)
    80005aac:	ef56                	sd	s5,408(sp)
    80005aae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f4040593          	addi	a1,s0,-192
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	140080e7          	jalr	320(ra) # 80002bfa <argstr>
    return -1;
    80005ac2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ac4:	0c054a63          	bltz	a0,80005b98 <sys_exec+0xfa>
    80005ac8:	e3840593          	addi	a1,s0,-456
    80005acc:	4505                	li	a0,1
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	10a080e7          	jalr	266(ra) # 80002bd8 <argaddr>
    80005ad6:	0c054163          	bltz	a0,80005b98 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ada:	10000613          	li	a2,256
    80005ade:	4581                	li	a1,0
    80005ae0:	e4040513          	addi	a0,s0,-448
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	272080e7          	jalr	626(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005af0:	89a6                	mv	s3,s1
    80005af2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005af4:	02000a13          	li	s4,32
    80005af8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005afc:	00391513          	slli	a0,s2,0x3
    80005b00:	e3040593          	addi	a1,s0,-464
    80005b04:	e3843783          	ld	a5,-456(s0)
    80005b08:	953e                	add	a0,a0,a5
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	012080e7          	jalr	18(ra) # 80002b1c <fetchaddr>
    80005b12:	02054a63          	bltz	a0,80005b46 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b16:	e3043783          	ld	a5,-464(s0)
    80005b1a:	c3b9                	beqz	a5,80005b60 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	004080e7          	jalr	4(ra) # 80000b20 <kalloc>
    80005b24:	85aa                	mv	a1,a0
    80005b26:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b2a:	cd11                	beqz	a0,80005b46 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b2c:	6605                	lui	a2,0x1
    80005b2e:	e3043503          	ld	a0,-464(s0)
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	03c080e7          	jalr	60(ra) # 80002b6e <fetchstr>
    80005b3a:	00054663          	bltz	a0,80005b46 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b3e:	0905                	addi	s2,s2,1
    80005b40:	09a1                	addi	s3,s3,8
    80005b42:	fb491be3          	bne	s2,s4,80005af8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b46:	10048913          	addi	s2,s1,256
    80005b4a:	6088                	ld	a0,0(s1)
    80005b4c:	c529                	beqz	a0,80005b96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b4e:	ffffb097          	auipc	ra,0xffffb
    80005b52:	ed6080e7          	jalr	-298(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b56:	04a1                	addi	s1,s1,8
    80005b58:	ff2499e3          	bne	s1,s2,80005b4a <sys_exec+0xac>
  return -1;
    80005b5c:	597d                	li	s2,-1
    80005b5e:	a82d                	j	80005b98 <sys_exec+0xfa>
      argv[i] = 0;
    80005b60:	0a8e                	slli	s5,s5,0x3
    80005b62:	fc040793          	addi	a5,s0,-64
    80005b66:	9abe                	add	s5,s5,a5
    80005b68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b6c:	e4040593          	addi	a1,s0,-448
    80005b70:	f4040513          	addi	a0,s0,-192
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	194080e7          	jalr	404(ra) # 80004d08 <exec>
    80005b7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7e:	10048993          	addi	s3,s1,256
    80005b82:	6088                	ld	a0,0(s1)
    80005b84:	c911                	beqz	a0,80005b98 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b86:	ffffb097          	auipc	ra,0xffffb
    80005b8a:	e9e080e7          	jalr	-354(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	04a1                	addi	s1,s1,8
    80005b90:	ff3499e3          	bne	s1,s3,80005b82 <sys_exec+0xe4>
    80005b94:	a011                	j	80005b98 <sys_exec+0xfa>
  return -1;
    80005b96:	597d                	li	s2,-1
}
    80005b98:	854a                	mv	a0,s2
    80005b9a:	60be                	ld	ra,456(sp)
    80005b9c:	641e                	ld	s0,448(sp)
    80005b9e:	74fa                	ld	s1,440(sp)
    80005ba0:	795a                	ld	s2,432(sp)
    80005ba2:	79ba                	ld	s3,424(sp)
    80005ba4:	7a1a                	ld	s4,416(sp)
    80005ba6:	6afa                	ld	s5,408(sp)
    80005ba8:	6179                	addi	sp,sp,464
    80005baa:	8082                	ret

0000000080005bac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bac:	7139                	addi	sp,sp,-64
    80005bae:	fc06                	sd	ra,56(sp)
    80005bb0:	f822                	sd	s0,48(sp)
    80005bb2:	f426                	sd	s1,40(sp)
    80005bb4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bb6:	ffffc097          	auipc	ra,0xffffc
    80005bba:	e72080e7          	jalr	-398(ra) # 80001a28 <myproc>
    80005bbe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bc0:	fd840593          	addi	a1,s0,-40
    80005bc4:	4501                	li	a0,0
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	012080e7          	jalr	18(ra) # 80002bd8 <argaddr>
    return -1;
    80005bce:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bd0:	0e054063          	bltz	a0,80005cb0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bd4:	fc840593          	addi	a1,s0,-56
    80005bd8:	fd040513          	addi	a0,s0,-48
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	dd2080e7          	jalr	-558(ra) # 800049ae <pipealloc>
    return -1;
    80005be4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005be6:	0c054563          	bltz	a0,80005cb0 <sys_pipe+0x104>
  fd0 = -1;
    80005bea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bee:	fd043503          	ld	a0,-48(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	508080e7          	jalr	1288(ra) # 800050fa <fdalloc>
    80005bfa:	fca42223          	sw	a0,-60(s0)
    80005bfe:	08054c63          	bltz	a0,80005c96 <sys_pipe+0xea>
    80005c02:	fc843503          	ld	a0,-56(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	4f4080e7          	jalr	1268(ra) # 800050fa <fdalloc>
    80005c0e:	fca42023          	sw	a0,-64(s0)
    80005c12:	06054863          	bltz	a0,80005c82 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c16:	4691                	li	a3,4
    80005c18:	fc440613          	addi	a2,s0,-60
    80005c1c:	fd843583          	ld	a1,-40(s0)
    80005c20:	68a8                	ld	a0,80(s1)
    80005c22:	ffffc097          	auipc	ra,0xffffc
    80005c26:	afa080e7          	jalr	-1286(ra) # 8000171c <copyout>
    80005c2a:	02054063          	bltz	a0,80005c4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c2e:	4691                	li	a3,4
    80005c30:	fc040613          	addi	a2,s0,-64
    80005c34:	fd843583          	ld	a1,-40(s0)
    80005c38:	0591                	addi	a1,a1,4
    80005c3a:	68a8                	ld	a0,80(s1)
    80005c3c:	ffffc097          	auipc	ra,0xffffc
    80005c40:	ae0080e7          	jalr	-1312(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c46:	06055563          	bgez	a0,80005cb0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c4a:	fc442783          	lw	a5,-60(s0)
    80005c4e:	07e9                	addi	a5,a5,26
    80005c50:	078e                	slli	a5,a5,0x3
    80005c52:	97a6                	add	a5,a5,s1
    80005c54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c58:	fc042503          	lw	a0,-64(s0)
    80005c5c:	0569                	addi	a0,a0,26
    80005c5e:	050e                	slli	a0,a0,0x3
    80005c60:	9526                	add	a0,a0,s1
    80005c62:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c66:	fd043503          	ld	a0,-48(s0)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	9ee080e7          	jalr	-1554(ra) # 80004658 <fileclose>
    fileclose(wf);
    80005c72:	fc843503          	ld	a0,-56(s0)
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	9e2080e7          	jalr	-1566(ra) # 80004658 <fileclose>
    return -1;
    80005c7e:	57fd                	li	a5,-1
    80005c80:	a805                	j	80005cb0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c82:	fc442783          	lw	a5,-60(s0)
    80005c86:	0007c863          	bltz	a5,80005c96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c8a:	01a78513          	addi	a0,a5,26
    80005c8e:	050e                	slli	a0,a0,0x3
    80005c90:	9526                	add	a0,a0,s1
    80005c92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c96:	fd043503          	ld	a0,-48(s0)
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	9be080e7          	jalr	-1602(ra) # 80004658 <fileclose>
    fileclose(wf);
    80005ca2:	fc843503          	ld	a0,-56(s0)
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	9b2080e7          	jalr	-1614(ra) # 80004658 <fileclose>
    return -1;
    80005cae:	57fd                	li	a5,-1
}
    80005cb0:	853e                	mv	a0,a5
    80005cb2:	70e2                	ld	ra,56(sp)
    80005cb4:	7442                	ld	s0,48(sp)
    80005cb6:	74a2                	ld	s1,40(sp)
    80005cb8:	6121                	addi	sp,sp,64
    80005cba:	8082                	ret
    80005cbc:	0000                	unimp
	...

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	ce9fc0ef          	jal	ra,800029e8 <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	710c                	ld	a1,32(a0)
    80005d5c:	7510                	ld	a2,40(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c64080e7          	jalr	-924(ra) # 800019fc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	c2c080e7          	jalr	-980(ra) # 800019fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	c04080e7          	jalr	-1020(ra) # 800019fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cc63          	blt	a5,a0,80005e78 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e24:	0001d797          	auipc	a5,0x1d
    80005e28:	1dc78793          	addi	a5,a5,476 # 80023000 <disk>
    80005e2c:	00a78733          	add	a4,a5,a0
    80005e30:	6789                	lui	a5,0x2
    80005e32:	97ba                	add	a5,a5,a4
    80005e34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e38:	eba1                	bnez	a5,80005e88 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e3a:	00451713          	slli	a4,a0,0x4
    80005e3e:	0001f797          	auipc	a5,0x1f
    80005e42:	1c27b783          	ld	a5,450(a5) # 80025000 <disk+0x2000>
    80005e46:	97ba                	add	a5,a5,a4
    80005e48:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e4c:	0001d797          	auipc	a5,0x1d
    80005e50:	1b478793          	addi	a5,a5,436 # 80023000 <disk>
    80005e54:	97aa                	add	a5,a5,a0
    80005e56:	6509                	lui	a0,0x2
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	4785                	li	a5,1
    80005e5c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e60:	0001f517          	auipc	a0,0x1f
    80005e64:	1b850513          	addi	a0,a0,440 # 80025018 <disk+0x2018>
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	55a080e7          	jalr	1370(ra) # 800023c2 <wakeup>
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	b5050513          	addi	a0,a0,-1200 # 800089c8 <syscall_name+0x370>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c8080e7          	jalr	1736(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	b5850513          	addi	a0,a0,-1192 # 800089e0 <syscall_name+0x388>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6b8080e7          	jalr	1720(ra) # 80000548 <panic>

0000000080005e98 <virtio_disk_init>:
{
    80005e98:	1101                	addi	sp,sp,-32
    80005e9a:	ec06                	sd	ra,24(sp)
    80005e9c:	e822                	sd	s0,16(sp)
    80005e9e:	e426                	sd	s1,8(sp)
    80005ea0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea2:	00003597          	auipc	a1,0x3
    80005ea6:	b5658593          	addi	a1,a1,-1194 # 800089f8 <syscall_name+0x3a0>
    80005eaa:	0001f517          	auipc	a0,0x1f
    80005eae:	1fe50513          	addi	a0,a0,510 # 800250a8 <disk+0x20a8>
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	d18080e7          	jalr	-744(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	4398                	lw	a4,0(a5)
    80005ec0:	2701                	sext.w	a4,a4
    80005ec2:	747277b7          	lui	a5,0x74727
    80005ec6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eca:	0ef71163          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	43dc                	lw	a5,4(a5)
    80005ed4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed6:	4705                	li	a4,1
    80005ed8:	0ce79a63          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	479c                	lw	a5,8(a5)
    80005ee2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ee4:	4709                	li	a4,2
    80005ee6:	0ce79363          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eea:	100017b7          	lui	a5,0x10001
    80005eee:	47d8                	lw	a4,12(a5)
    80005ef0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef2:	554d47b7          	lui	a5,0x554d4
    80005ef6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005efa:	0af71963          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	4705                	li	a4,1
    80005f04:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	470d                	li	a4,3
    80005f08:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f0a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f0c:	c7ffe737          	lui	a4,0xc7ffe
    80005f10:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f14:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f16:	2701                	sext.w	a4,a4
    80005f18:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1a:	472d                	li	a4,11
    80005f1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	473d                	li	a4,15
    80005f20:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f22:	6705                	lui	a4,0x1
    80005f24:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f26:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2a:	5bdc                	lw	a5,52(a5)
    80005f2c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f2e:	c7d9                	beqz	a5,80005fbc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f30:	471d                	li	a4,7
    80005f32:	08f77d63          	bgeu	a4,a5,80005fcc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f36:	100014b7          	lui	s1,0x10001
    80005f3a:	47a1                	li	a5,8
    80005f3c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f3e:	6609                	lui	a2,0x2
    80005f40:	4581                	li	a1,0
    80005f42:	0001d517          	auipc	a0,0x1d
    80005f46:	0be50513          	addi	a0,a0,190 # 80023000 <disk>
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	e0c080e7          	jalr	-500(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f52:	0001d717          	auipc	a4,0x1d
    80005f56:	0ae70713          	addi	a4,a4,174 # 80023000 <disk>
    80005f5a:	00c75793          	srli	a5,a4,0xc
    80005f5e:	2781                	sext.w	a5,a5
    80005f60:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f62:	0001f797          	auipc	a5,0x1f
    80005f66:	09e78793          	addi	a5,a5,158 # 80025000 <disk+0x2000>
    80005f6a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f6c:	0001d717          	auipc	a4,0x1d
    80005f70:	11470713          	addi	a4,a4,276 # 80023080 <disk+0x80>
    80005f74:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f76:	0001e717          	auipc	a4,0x1e
    80005f7a:	08a70713          	addi	a4,a4,138 # 80024000 <disk+0x1000>
    80005f7e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f80:	4705                	li	a4,1
    80005f82:	00e78c23          	sb	a4,24(a5)
    80005f86:	00e78ca3          	sb	a4,25(a5)
    80005f8a:	00e78d23          	sb	a4,26(a5)
    80005f8e:	00e78da3          	sb	a4,27(a5)
    80005f92:	00e78e23          	sb	a4,28(a5)
    80005f96:	00e78ea3          	sb	a4,29(a5)
    80005f9a:	00e78f23          	sb	a4,30(a5)
    80005f9e:	00e78fa3          	sb	a4,31(a5)
}
    80005fa2:	60e2                	ld	ra,24(sp)
    80005fa4:	6442                	ld	s0,16(sp)
    80005fa6:	64a2                	ld	s1,8(sp)
    80005fa8:	6105                	addi	sp,sp,32
    80005faa:	8082                	ret
    panic("could not find virtio disk");
    80005fac:	00003517          	auipc	a0,0x3
    80005fb0:	a5c50513          	addi	a0,a0,-1444 # 80008a08 <syscall_name+0x3b0>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005fbc:	00003517          	auipc	a0,0x3
    80005fc0:	a6c50513          	addi	a0,a0,-1428 # 80008a28 <syscall_name+0x3d0>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	584080e7          	jalr	1412(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005fcc:	00003517          	auipc	a0,0x3
    80005fd0:	a7c50513          	addi	a0,a0,-1412 # 80008a48 <syscall_name+0x3f0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	574080e7          	jalr	1396(ra) # 80000548 <panic>

0000000080005fdc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fdc:	7119                	addi	sp,sp,-128
    80005fde:	fc86                	sd	ra,120(sp)
    80005fe0:	f8a2                	sd	s0,112(sp)
    80005fe2:	f4a6                	sd	s1,104(sp)
    80005fe4:	f0ca                	sd	s2,96(sp)
    80005fe6:	ecce                	sd	s3,88(sp)
    80005fe8:	e8d2                	sd	s4,80(sp)
    80005fea:	e4d6                	sd	s5,72(sp)
    80005fec:	e0da                	sd	s6,64(sp)
    80005fee:	fc5e                	sd	s7,56(sp)
    80005ff0:	f862                	sd	s8,48(sp)
    80005ff2:	f466                	sd	s9,40(sp)
    80005ff4:	f06a                	sd	s10,32(sp)
    80005ff6:	0100                	addi	s0,sp,128
    80005ff8:	892a                	mv	s2,a0
    80005ffa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ffc:	00c52c83          	lw	s9,12(a0)
    80006000:	001c9c9b          	slliw	s9,s9,0x1
    80006004:	1c82                	slli	s9,s9,0x20
    80006006:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000600a:	0001f517          	auipc	a0,0x1f
    8000600e:	09e50513          	addi	a0,a0,158 # 800250a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	c48080e7          	jalr	-952(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    8000601a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000601c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000601e:	0001db97          	auipc	s7,0x1d
    80006022:	fe2b8b93          	addi	s7,s7,-30 # 80023000 <disk>
    80006026:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006028:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000602a:	8a4e                	mv	s4,s3
    8000602c:	a051                	j	800060b0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000602e:	00fb86b3          	add	a3,s7,a5
    80006032:	96da                	add	a3,a3,s6
    80006034:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006038:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000603a:	0207c563          	bltz	a5,80006064 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000603e:	2485                	addiw	s1,s1,1
    80006040:	0711                	addi	a4,a4,4
    80006042:	23548d63          	beq	s1,s5,8000627c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006046:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006048:	0001f697          	auipc	a3,0x1f
    8000604c:	fd068693          	addi	a3,a3,-48 # 80025018 <disk+0x2018>
    80006050:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006052:	0006c583          	lbu	a1,0(a3)
    80006056:	fde1                	bnez	a1,8000602e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006058:	2785                	addiw	a5,a5,1
    8000605a:	0685                	addi	a3,a3,1
    8000605c:	ff879be3          	bne	a5,s8,80006052 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006060:	57fd                	li	a5,-1
    80006062:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006064:	02905a63          	blez	s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006068:	f9042503          	lw	a0,-112(s0)
    8000606c:	00000097          	auipc	ra,0x0
    80006070:	daa080e7          	jalr	-598(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006074:	4785                	li	a5,1
    80006076:	0297d163          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000607a:	f9442503          	lw	a0,-108(s0)
    8000607e:	00000097          	auipc	ra,0x0
    80006082:	d98080e7          	jalr	-616(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006086:	4789                	li	a5,2
    80006088:	0097d863          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000608c:	f9842503          	lw	a0,-104(s0)
    80006090:	00000097          	auipc	ra,0x0
    80006094:	d86080e7          	jalr	-634(ra) # 80005e16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006098:	0001f597          	auipc	a1,0x1f
    8000609c:	01058593          	addi	a1,a1,16 # 800250a8 <disk+0x20a8>
    800060a0:	0001f517          	auipc	a0,0x1f
    800060a4:	f7850513          	addi	a0,a0,-136 # 80025018 <disk+0x2018>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	194080e7          	jalr	404(ra) # 8000223c <sleep>
  for(int i = 0; i < 3; i++){
    800060b0:	f9040713          	addi	a4,s0,-112
    800060b4:	84ce                	mv	s1,s3
    800060b6:	bf41                	j	80006046 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060b8:	4785                	li	a5,1
    800060ba:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060be:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060c2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060c6:	f9042983          	lw	s3,-112(s0)
    800060ca:	00499493          	slli	s1,s3,0x4
    800060ce:	0001fa17          	auipc	s4,0x1f
    800060d2:	f32a0a13          	addi	s4,s4,-206 # 80025000 <disk+0x2000>
    800060d6:	000a3a83          	ld	s5,0(s4)
    800060da:	9aa6                	add	s5,s5,s1
    800060dc:	f8040513          	addi	a0,s0,-128
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	04a080e7          	jalr	74(ra) # 8000112a <kvmpa>
    800060e8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060ec:	000a3783          	ld	a5,0(s4)
    800060f0:	97a6                	add	a5,a5,s1
    800060f2:	4741                	li	a4,16
    800060f4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f6:	000a3783          	ld	a5,0(s4)
    800060fa:	97a6                	add	a5,a5,s1
    800060fc:	4705                	li	a4,1
    800060fe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006102:	f9442703          	lw	a4,-108(s0)
    80006106:	000a3783          	ld	a5,0(s4)
    8000610a:	97a6                	add	a5,a5,s1
    8000610c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0712                	slli	a4,a4,0x4
    80006112:	000a3783          	ld	a5,0(s4)
    80006116:	97ba                	add	a5,a5,a4
    80006118:	05890693          	addi	a3,s2,88
    8000611c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000611e:	000a3783          	ld	a5,0(s4)
    80006122:	97ba                	add	a5,a5,a4
    80006124:	40000693          	li	a3,1024
    80006128:	c794                	sw	a3,8(a5)
  if(write)
    8000612a:	100d0a63          	beqz	s10,8000623e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000612e:	0001f797          	auipc	a5,0x1f
    80006132:	ed27b783          	ld	a5,-302(a5) # 80025000 <disk+0x2000>
    80006136:	97ba                	add	a5,a5,a4
    80006138:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000613c:	0001d517          	auipc	a0,0x1d
    80006140:	ec450513          	addi	a0,a0,-316 # 80023000 <disk>
    80006144:	0001f797          	auipc	a5,0x1f
    80006148:	ebc78793          	addi	a5,a5,-324 # 80025000 <disk+0x2000>
    8000614c:	6394                	ld	a3,0(a5)
    8000614e:	96ba                	add	a3,a3,a4
    80006150:	00c6d603          	lhu	a2,12(a3)
    80006154:	00166613          	ori	a2,a2,1
    80006158:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000615c:	f9842683          	lw	a3,-104(s0)
    80006160:	6390                	ld	a2,0(a5)
    80006162:	9732                	add	a4,a4,a2
    80006164:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006168:	20098613          	addi	a2,s3,512
    8000616c:	0612                	slli	a2,a2,0x4
    8000616e:	962a                	add	a2,a2,a0
    80006170:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006174:	00469713          	slli	a4,a3,0x4
    80006178:	6394                	ld	a3,0(a5)
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	6589                	lui	a1,0x2
    8000617e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006182:	94ae                	add	s1,s1,a1
    80006184:	94aa                	add	s1,s1,a0
    80006186:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006188:	6394                	ld	a3,0(a5)
    8000618a:	96ba                	add	a3,a3,a4
    8000618c:	4585                	li	a1,1
    8000618e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006190:	6394                	ld	a3,0(a5)
    80006192:	96ba                	add	a3,a3,a4
    80006194:	4509                	li	a0,2
    80006196:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000619a:	6394                	ld	a3,0(a5)
    8000619c:	9736                	add	a4,a4,a3
    8000619e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061a2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061a6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061aa:	6794                	ld	a3,8(a5)
    800061ac:	0026d703          	lhu	a4,2(a3)
    800061b0:	8b1d                	andi	a4,a4,7
    800061b2:	2709                	addiw	a4,a4,2
    800061b4:	0706                	slli	a4,a4,0x1
    800061b6:	9736                	add	a4,a4,a3
    800061b8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061bc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061c0:	6798                	ld	a4,8(a5)
    800061c2:	00275783          	lhu	a5,2(a4)
    800061c6:	2785                	addiw	a5,a5,1
    800061c8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061cc:	100017b7          	lui	a5,0x10001
    800061d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061d4:	00492703          	lw	a4,4(s2)
    800061d8:	4785                	li	a5,1
    800061da:	02f71163          	bne	a4,a5,800061fc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061de:	0001f997          	auipc	s3,0x1f
    800061e2:	eca98993          	addi	s3,s3,-310 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061e8:	85ce                	mv	a1,s3
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffc097          	auipc	ra,0xffffc
    800061f0:	050080e7          	jalr	80(ra) # 8000223c <sleep>
  while(b->disk == 1) {
    800061f4:	00492783          	lw	a5,4(s2)
    800061f8:	fe9788e3          	beq	a5,s1,800061e8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061fc:	f9042483          	lw	s1,-112(s0)
    80006200:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006204:	00479713          	slli	a4,a5,0x4
    80006208:	0001d797          	auipc	a5,0x1d
    8000620c:	df878793          	addi	a5,a5,-520 # 80023000 <disk>
    80006210:	97ba                	add	a5,a5,a4
    80006212:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006216:	0001f917          	auipc	s2,0x1f
    8000621a:	dea90913          	addi	s2,s2,-534 # 80025000 <disk+0x2000>
    free_desc(i);
    8000621e:	8526                	mv	a0,s1
    80006220:	00000097          	auipc	ra,0x0
    80006224:	bf6080e7          	jalr	-1034(ra) # 80005e16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006228:	0492                	slli	s1,s1,0x4
    8000622a:	00093783          	ld	a5,0(s2)
    8000622e:	94be                	add	s1,s1,a5
    80006230:	00c4d783          	lhu	a5,12(s1)
    80006234:	8b85                	andi	a5,a5,1
    80006236:	cf89                	beqz	a5,80006250 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006238:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000623c:	b7cd                	j	8000621e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623e:	0001f797          	auipc	a5,0x1f
    80006242:	dc27b783          	ld	a5,-574(a5) # 80025000 <disk+0x2000>
    80006246:	97ba                	add	a5,a5,a4
    80006248:	4689                	li	a3,2
    8000624a:	00d79623          	sh	a3,12(a5)
    8000624e:	b5fd                	j	8000613c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006250:	0001f517          	auipc	a0,0x1f
    80006254:	e5850513          	addi	a0,a0,-424 # 800250a8 <disk+0x20a8>
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	ab6080e7          	jalr	-1354(ra) # 80000d0e <release>
}
    80006260:	70e6                	ld	ra,120(sp)
    80006262:	7446                	ld	s0,112(sp)
    80006264:	74a6                	ld	s1,104(sp)
    80006266:	7906                	ld	s2,96(sp)
    80006268:	69e6                	ld	s3,88(sp)
    8000626a:	6a46                	ld	s4,80(sp)
    8000626c:	6aa6                	ld	s5,72(sp)
    8000626e:	6b06                	ld	s6,64(sp)
    80006270:	7be2                	ld	s7,56(sp)
    80006272:	7c42                	ld	s8,48(sp)
    80006274:	7ca2                	ld	s9,40(sp)
    80006276:	7d02                	ld	s10,32(sp)
    80006278:	6109                	addi	sp,sp,128
    8000627a:	8082                	ret
  if(write)
    8000627c:	e20d1ee3          	bnez	s10,800060b8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006280:	f8042023          	sw	zero,-128(s0)
    80006284:	bd2d                	j	800060be <virtio_disk_rw+0xe2>

0000000080006286 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006286:	1101                	addi	sp,sp,-32
    80006288:	ec06                	sd	ra,24(sp)
    8000628a:	e822                	sd	s0,16(sp)
    8000628c:	e426                	sd	s1,8(sp)
    8000628e:	e04a                	sd	s2,0(sp)
    80006290:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006292:	0001f517          	auipc	a0,0x1f
    80006296:	e1650513          	addi	a0,a0,-490 # 800250a8 <disk+0x20a8>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	9c0080e7          	jalr	-1600(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062a2:	0001f717          	auipc	a4,0x1f
    800062a6:	d5e70713          	addi	a4,a4,-674 # 80025000 <disk+0x2000>
    800062aa:	02075783          	lhu	a5,32(a4)
    800062ae:	6b18                	ld	a4,16(a4)
    800062b0:	00275683          	lhu	a3,2(a4)
    800062b4:	8ebd                	xor	a3,a3,a5
    800062b6:	8a9d                	andi	a3,a3,7
    800062b8:	cab9                	beqz	a3,8000630e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062ba:	0001d917          	auipc	s2,0x1d
    800062be:	d4690913          	addi	s2,s2,-698 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062c2:	0001f497          	auipc	s1,0x1f
    800062c6:	d3e48493          	addi	s1,s1,-706 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ca:	078e                	slli	a5,a5,0x3
    800062cc:	97ba                	add	a5,a5,a4
    800062ce:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062d0:	20078713          	addi	a4,a5,512
    800062d4:	0712                	slli	a4,a4,0x4
    800062d6:	974a                	add	a4,a4,s2
    800062d8:	03074703          	lbu	a4,48(a4)
    800062dc:	ef21                	bnez	a4,80006334 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062de:	20078793          	addi	a5,a5,512
    800062e2:	0792                	slli	a5,a5,0x4
    800062e4:	97ca                	add	a5,a5,s2
    800062e6:	7798                	ld	a4,40(a5)
    800062e8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062ec:	7788                	ld	a0,40(a5)
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	0d4080e7          	jalr	212(ra) # 800023c2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062f6:	0204d783          	lhu	a5,32(s1)
    800062fa:	2785                	addiw	a5,a5,1
    800062fc:	8b9d                	andi	a5,a5,7
    800062fe:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006302:	6898                	ld	a4,16(s1)
    80006304:	00275683          	lhu	a3,2(a4)
    80006308:	8a9d                	andi	a3,a3,7
    8000630a:	fcf690e3          	bne	a3,a5,800062ca <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000630e:	10001737          	lui	a4,0x10001
    80006312:	533c                	lw	a5,96(a4)
    80006314:	8b8d                	andi	a5,a5,3
    80006316:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006318:	0001f517          	auipc	a0,0x1f
    8000631c:	d9050513          	addi	a0,a0,-624 # 800250a8 <disk+0x20a8>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	9ee080e7          	jalr	-1554(ra) # 80000d0e <release>
}
    80006328:	60e2                	ld	ra,24(sp)
    8000632a:	6442                	ld	s0,16(sp)
    8000632c:	64a2                	ld	s1,8(sp)
    8000632e:	6902                	ld	s2,0(sp)
    80006330:	6105                	addi	sp,sp,32
    80006332:	8082                	ret
      panic("virtio_disk_intr status");
    80006334:	00002517          	auipc	a0,0x2
    80006338:	73450513          	addi	a0,a0,1844 # 80008a68 <syscall_name+0x410>
    8000633c:	ffffa097          	auipc	ra,0xffffa
    80006340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
