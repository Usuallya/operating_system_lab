
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
    80000060:	f1478793          	addi	a5,a5,-236 # 80005f70 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	6f0080e7          	jalr	1776(ra) # 80002816 <either_copyin>
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
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	9ee080e7          	jalr	-1554(ra) # 80001bbc <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	380080e7          	jalr	896(ra) # 8000255e <sleep>
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
    8000021e:	5a6080e7          	jalr	1446(ra) # 800027c0 <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	570080e7          	jalr	1392(ra) # 8000286c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	294080e7          	jalr	660(ra) # 800026e4 <wakeup>
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
    80000466:	b9e58593          	addi	a1,a1,-1122 # 80008000 <etext>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

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
    800004c8:	b6c60613          	addi	a2,a2,-1172 # 80008030 <digits>
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
    80000560:	aac50513          	addi	a0,a0,-1364 # 80008008 <etext+0x8>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b4250513          	addi	a0,a0,-1214 # 800080b8 <digits+0x88>
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
    800005f4:	a40b8b93          	addi	s7,s7,-1472 # 80008030 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a0450513          	addi	a0,a0,-1532 # 80008018 <etext+0x18>
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
    80000718:	8fc90913          	addi	s2,s2,-1796 # 80008010 <etext+0x10>
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
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
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
    8000078e:	89e58593          	addi	a1,a1,-1890 # 80008028 <etext+0x28>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
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
    800007de:	86e58593          	addi	a1,a1,-1938 # 80008048 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
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
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

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
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
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
    800008ba:	e2e080e7          	jalr	-466(ra) # 800026e4 <wakeup>
    
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
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
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
    80000954:	c0e080e7          	jalr	-1010(ra) # 8000255e <sleep>
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
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
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
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5c650513          	addi	a0,a0,1478 # 80008050 <digits+0x20>
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
    80000af0:	56c58593          	addi	a1,a1,1388 # 80008058 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
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
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
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
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	ff6080e7          	jalr	-10(ra) # 80001ba0 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32

static inline uint64
r_sstatus()
{
  uint64 x;
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus

// disable device interrupts
static inline void
intr_off()
{
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	fc4080e7          	jalr	-60(ra) # 80001ba0 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	fb8080e7          	jalr	-72(ra) # 80001ba0 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	fa0080e7          	jalr	-96(ra) # 80001ba0 <mycpu>
// are device interrupts enabled?
static inline int
intr_get()
{
  uint64 x = r_sstatus();
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	f60080e7          	jalr	-160(ra) # 80001ba0 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	40c50513          	addi	a0,a0,1036 # 80008060 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	f34080e7          	jalr	-204(ra) # 80001ba0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3c450513          	addi	a0,a0,964 # 80008068 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3cc50513          	addi	a0,a0,972 # 80008080 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	38c50513          	addi	a0,a0,908 # 80008088 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	cca080e7          	jalr	-822(ra) # 80001b90 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	cae080e7          	jalr	-850(ra) # 80001b90 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1bc50513          	addi	a0,a0,444 # 800080a8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	aa8080e7          	jalr	-1368(ra) # 800029ac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	0a4080e7          	jalr	164(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	35c080e7          	jalr	860(ra) # 80002270 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00006097          	auipc	ra,0x6
    80000f28:	84e080e7          	jalr	-1970(ra) # 80006772 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	18450513          	addi	a0,a0,388 # 800080b8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	14c50513          	addi	a0,a0,332 # 80008090 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	16450513          	addi	a0,a0,356 # 800080b8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2a8080e7          	jalr	680(ra) # 80001214 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	bb4080e7          	jalr	-1100(ra) # 80001b30 <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	a00080e7          	jalr	-1536(ra) # 80002984 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	a20080e7          	jalr	-1504(ra) # 800029ac <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	006080e7          	jalr	6(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	014080e7          	jalr	20(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	14a080e7          	jalr	330(ra) # 800030ee <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	7da080e7          	jalr	2010(ra) # 80003786 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	774080e7          	jalr	1908(ra) # 80004728 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	0fc080e7          	jalr	252(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	fa4080e7          	jalr	-92(ra) # 80001f68 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	09a50513          	addi	a0,a0,154 # 800080c0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	e04a                	sd	s2,0(sp)
    800010f2:	1000                	addi	s0,sp,32
    800010f4:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800010f6:	1552                	slli	a0,a0,0x34
    800010f8:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->kpagetable, va, 0);
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	ac0080e7          	jalr	-1344(ra) # 80001bbc <myproc>
    80001104:	4601                	li	a2,0
    80001106:	85a6                	mv	a1,s1
    80001108:	6d28                	ld	a0,88(a0)
    8000110a:	00000097          	auipc	ra,0x0
    8000110e:	ef6080e7          	jalr	-266(ra) # 80001000 <walk>
  if(pte == 0)
    80001112:	cd11                	beqz	a0,8000112e <kvmpa+0x46>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001114:	6108                	ld	a0,0(a0)
    80001116:	00157793          	andi	a5,a0,1
    8000111a:	c395                	beqz	a5,8000113e <kvmpa+0x56>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111c:	8129                	srli	a0,a0,0xa
    8000111e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001120:	954a                	add	a0,a0,s2
    80001122:	60e2                	ld	ra,24(sp)
    80001124:	6442                	ld	s0,16(sp)
    80001126:	64a2                	ld	s1,8(sp)
    80001128:	6902                	ld	s2,0(sp)
    8000112a:	6105                	addi	sp,sp,32
    8000112c:	8082                	ret
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	f9a50513          	addi	a0,a0,-102 # 800080c8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>
    panic("kvmpa");
    8000113e:	00007517          	auipc	a0,0x7
    80001142:	f8a50513          	addi	a0,a0,-118 # 800080c8 <digits+0x98>
    80001146:	fffff097          	auipc	ra,0xfffff
    8000114a:	402080e7          	jalr	1026(ra) # 80000548 <panic>

000000008000114e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114e:	715d                	addi	sp,sp,-80
    80001150:	e486                	sd	ra,72(sp)
    80001152:	e0a2                	sd	s0,64(sp)
    80001154:	fc26                	sd	s1,56(sp)
    80001156:	f84a                	sd	s2,48(sp)
    80001158:	f44e                	sd	s3,40(sp)
    8000115a:	f052                	sd	s4,32(sp)
    8000115c:	ec56                	sd	s5,24(sp)
    8000115e:	e85a                	sd	s6,16(sp)
    80001160:	e45e                	sd	s7,8(sp)
    80001162:	0880                	addi	s0,sp,80
    80001164:	8aaa                	mv	s5,a0
    80001166:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001168:	777d                	lui	a4,0xfffff
    8000116a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000116e:	167d                	addi	a2,a2,-1
    80001170:	00b609b3          	add	s3,a2,a1
    80001174:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001178:	893e                	mv	s2,a5
    8000117a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000117e:	6b85                	lui	s7,0x1
    80001180:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001184:	4605                	li	a2,1
    80001186:	85ca                	mv	a1,s2
    80001188:	8556                	mv	a0,s5
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	e76080e7          	jalr	-394(ra) # 80001000 <walk>
    80001192:	c51d                	beqz	a0,800011c0 <mappages+0x72>
    if(*pte & PTE_V)
    80001194:	611c                	ld	a5,0(a0)
    80001196:	8b85                	andi	a5,a5,1
    80001198:	ef81                	bnez	a5,800011b0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119a:	80b1                	srli	s1,s1,0xc
    8000119c:	04aa                	slli	s1,s1,0xa
    8000119e:	0164e4b3          	or	s1,s1,s6
    800011a2:	0014e493          	ori	s1,s1,1
    800011a6:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a8:	03390863          	beq	s2,s3,800011d8 <mappages+0x8a>
    a += PGSIZE;
    800011ac:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ae:	bfc9                	j	80001180 <mappages+0x32>
      panic("remap");
    800011b0:	00007517          	auipc	a0,0x7
    800011b4:	f2050513          	addi	a0,a0,-224 # 800080d0 <digits+0xa0>
    800011b8:	fffff097          	auipc	ra,0xfffff
    800011bc:	390080e7          	jalr	912(ra) # 80000548 <panic>
      return -1;
    800011c0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c2:	60a6                	ld	ra,72(sp)
    800011c4:	6406                	ld	s0,64(sp)
    800011c6:	74e2                	ld	s1,56(sp)
    800011c8:	7942                	ld	s2,48(sp)
    800011ca:	79a2                	ld	s3,40(sp)
    800011cc:	7a02                	ld	s4,32(sp)
    800011ce:	6ae2                	ld	s5,24(sp)
    800011d0:	6b42                	ld	s6,16(sp)
    800011d2:	6ba2                	ld	s7,8(sp)
    800011d4:	6161                	addi	sp,sp,80
    800011d6:	8082                	ret
  return 0;
    800011d8:	4501                	li	a0,0
    800011da:	b7e5                	j	800011c2 <mappages+0x74>

00000000800011dc <kvmmap>:
{
    800011dc:	1141                	addi	sp,sp,-16
    800011de:	e406                	sd	ra,8(sp)
    800011e0:	e022                	sd	s0,0(sp)
    800011e2:	0800                	addi	s0,sp,16
    800011e4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e6:	86ae                	mv	a3,a1
    800011e8:	85aa                	mv	a1,a0
    800011ea:	00008517          	auipc	a0,0x8
    800011ee:	e2653503          	ld	a0,-474(a0) # 80009010 <kernel_pagetable>
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	f5c080e7          	jalr	-164(ra) # 8000114e <mappages>
    800011fa:	e509                	bnez	a0,80001204 <kvmmap+0x28>
}
    800011fc:	60a2                	ld	ra,8(sp)
    800011fe:	6402                	ld	s0,0(sp)
    80001200:	0141                	addi	sp,sp,16
    80001202:	8082                	ret
    panic("kvmmap");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ed450513          	addi	a0,a0,-300 # 800080d8 <digits+0xa8>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	33c080e7          	jalr	828(ra) # 80000548 <panic>

0000000080001214 <kvminit>:
{
    80001214:	1101                	addi	sp,sp,-32
    80001216:	ec06                	sd	ra,24(sp)
    80001218:	e822                	sd	s0,16(sp)
    8000121a:	e426                	sd	s1,8(sp)
    8000121c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	902080e7          	jalr	-1790(ra) # 80000b20 <kalloc>
    80001226:	00008797          	auipc	a5,0x8
    8000122a:	dea7b523          	sd	a0,-534(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000122e:	6605                	lui	a2,0x1
    80001230:	4581                	li	a1,0
    80001232:	00000097          	auipc	ra,0x0
    80001236:	ada080e7          	jalr	-1318(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000123a:	4699                	li	a3,6
    8000123c:	6605                	lui	a2,0x1
    8000123e:	100005b7          	lui	a1,0x10000
    80001242:	10000537          	lui	a0,0x10000
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f96080e7          	jalr	-106(ra) # 800011dc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000124e:	4699                	li	a3,6
    80001250:	6605                	lui	a2,0x1
    80001252:	100015b7          	lui	a1,0x10001
    80001256:	10001537          	lui	a0,0x10001
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f82080e7          	jalr	-126(ra) # 800011dc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001262:	4699                	li	a3,6
    80001264:	6641                	lui	a2,0x10
    80001266:	020005b7          	lui	a1,0x2000
    8000126a:	02000537          	lui	a0,0x2000
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f6e080e7          	jalr	-146(ra) # 800011dc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	00400637          	lui	a2,0x400
    8000127c:	0c0005b7          	lui	a1,0xc000
    80001280:	0c000537          	lui	a0,0xc000
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f58080e7          	jalr	-168(ra) # 800011dc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128c:	00007497          	auipc	s1,0x7
    80001290:	d7448493          	addi	s1,s1,-652 # 80008000 <etext>
    80001294:	46a9                	li	a3,10
    80001296:	80007617          	auipc	a2,0x80007
    8000129a:	d6a60613          	addi	a2,a2,-662 # 8000 <_entry-0x7fff8000>
    8000129e:	4585                	li	a1,1
    800012a0:	05fe                	slli	a1,a1,0x1f
    800012a2:	852e                	mv	a0,a1
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f38080e7          	jalr	-200(ra) # 800011dc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	4645                	li	a2,17
    800012b0:	066e                	slli	a2,a2,0x1b
    800012b2:	8e05                	sub	a2,a2,s1
    800012b4:	85a6                	mv	a1,s1
    800012b6:	8526                	mv	a0,s1
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f24080e7          	jalr	-220(ra) # 800011dc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012c0:	46a9                	li	a3,10
    800012c2:	6605                	lui	a2,0x1
    800012c4:	00006597          	auipc	a1,0x6
    800012c8:	d3c58593          	addi	a1,a1,-708 # 80007000 <_trampoline>
    800012cc:	04000537          	lui	a0,0x4000
    800012d0:	157d                	addi	a0,a0,-1
    800012d2:	0532                	slli	a0,a0,0xc
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f08080e7          	jalr	-248(ra) # 800011dc <kvmmap>
}
    800012dc:	60e2                	ld	ra,24(sp)
    800012de:	6442                	ld	s0,16(sp)
    800012e0:	64a2                	ld	s1,8(sp)
    800012e2:	6105                	addi	sp,sp,32
    800012e4:	8082                	ret

00000000800012e6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e6:	715d                	addi	sp,sp,-80
    800012e8:	e486                	sd	ra,72(sp)
    800012ea:	e0a2                	sd	s0,64(sp)
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	f84a                	sd	s2,48(sp)
    800012f0:	f44e                	sd	s3,40(sp)
    800012f2:	f052                	sd	s4,32(sp)
    800012f4:	ec56                	sd	s5,24(sp)
    800012f6:	e85a                	sd	s6,16(sp)
    800012f8:	e45e                	sd	s7,8(sp)
    800012fa:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fc:	03459793          	slli	a5,a1,0x34
    80001300:	e795                	bnez	a5,8000132c <uvmunmap+0x46>
    80001302:	8a2a                	mv	s4,a0
    80001304:	892e                	mv	s2,a1
    80001306:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	0632                	slli	a2,a2,0xc
    8000130a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	6b05                	lui	s6,0x1
    80001312:	0735e863          	bltu	a1,s3,80001382 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001316:	60a6                	ld	ra,72(sp)
    80001318:	6406                	ld	s0,64(sp)
    8000131a:	74e2                	ld	s1,56(sp)
    8000131c:	7942                	ld	s2,48(sp)
    8000131e:	79a2                	ld	s3,40(sp)
    80001320:	7a02                	ld	s4,32(sp)
    80001322:	6ae2                	ld	s5,24(sp)
    80001324:	6b42                	ld	s6,16(sp)
    80001326:	6ba2                	ld	s7,8(sp)
    80001328:	6161                	addi	sp,sp,80
    8000132a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	db450513          	addi	a0,a0,-588 # 800080e0 <digits+0xb0>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	dbc50513          	addi	a0,a0,-580 # 800080f8 <digits+0xc8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	dbc50513          	addi	a0,a0,-580 # 80008108 <digits+0xd8>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000135c:	00007517          	auipc	a0,0x7
    80001360:	dc450513          	addi	a0,a0,-572 # 80008120 <digits+0xf0>
    80001364:	fffff097          	auipc	ra,0xfffff
    80001368:	1e4080e7          	jalr	484(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000136c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000136e:	0532                	slli	a0,a0,0xc
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	6b4080e7          	jalr	1716(ra) # 80000a24 <kfree>
    *pte = 0;
    80001378:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137c:	995a                	add	s2,s2,s6
    8000137e:	f9397ce3          	bgeu	s2,s3,80001316 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001382:	4601                	li	a2,0
    80001384:	85ca                	mv	a1,s2
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	c78080e7          	jalr	-904(ra) # 80001000 <walk>
    80001390:	84aa                	mv	s1,a0
    80001392:	d54d                	beqz	a0,8000133c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001394:	6108                	ld	a0,0(a0)
    80001396:	00157793          	andi	a5,a0,1
    8000139a:	dbcd                	beqz	a5,8000134c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139c:	3ff57793          	andi	a5,a0,1023
    800013a0:	fb778ee3          	beq	a5,s7,8000135c <uvmunmap+0x76>
    if(do_free){
    800013a4:	fc0a8ae3          	beqz	s5,80001378 <uvmunmap+0x92>
    800013a8:	b7d1                	j	8000136c <uvmunmap+0x86>

00000000800013aa <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013aa:	1101                	addi	sp,sp,-32
    800013ac:	ec06                	sd	ra,24(sp)
    800013ae:	e822                	sd	s0,16(sp)
    800013b0:	e426                	sd	s1,8(sp)
    800013b2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b4:	fffff097          	auipc	ra,0xfffff
    800013b8:	76c080e7          	jalr	1900(ra) # 80000b20 <kalloc>
    800013bc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013be:	c519                	beqz	a0,800013cc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	948080e7          	jalr	-1720(ra) # 80000d0c <memset>
  return pagetable;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret

00000000800013d8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d8:	7179                	addi	sp,sp,-48
    800013da:	f406                	sd	ra,40(sp)
    800013dc:	f022                	sd	s0,32(sp)
    800013de:	ec26                	sd	s1,24(sp)
    800013e0:	e84a                	sd	s2,16(sp)
    800013e2:	e44e                	sd	s3,8(sp)
    800013e4:	e052                	sd	s4,0(sp)
    800013e6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e8:	6785                	lui	a5,0x1
    800013ea:	04f67863          	bgeu	a2,a5,8000143a <uvminit+0x62>
    800013ee:	8a2a                	mv	s4,a0
    800013f0:	89ae                	mv	s3,a1
    800013f2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	72c080e7          	jalr	1836(ra) # 80000b20 <kalloc>
    800013fc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	90a080e7          	jalr	-1782(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000140a:	4779                	li	a4,30
    8000140c:	86ca                	mv	a3,s2
    8000140e:	6605                	lui	a2,0x1
    80001410:	4581                	li	a1,0
    80001412:	8552                	mv	a0,s4
    80001414:	00000097          	auipc	ra,0x0
    80001418:	d3a080e7          	jalr	-710(ra) # 8000114e <mappages>
  memmove(mem, src, sz);
    8000141c:	8626                	mv	a2,s1
    8000141e:	85ce                	mv	a1,s3
    80001420:	854a                	mv	a0,s2
    80001422:	00000097          	auipc	ra,0x0
    80001426:	94a080e7          	jalr	-1718(ra) # 80000d6c <memmove>
}
    8000142a:	70a2                	ld	ra,40(sp)
    8000142c:	7402                	ld	s0,32(sp)
    8000142e:	64e2                	ld	s1,24(sp)
    80001430:	6942                	ld	s2,16(sp)
    80001432:	69a2                	ld	s3,8(sp)
    80001434:	6a02                	ld	s4,0(sp)
    80001436:	6145                	addi	sp,sp,48
    80001438:	8082                	ret
    panic("inituvm: more than a page");
    8000143a:	00007517          	auipc	a0,0x7
    8000143e:	cfe50513          	addi	a0,a0,-770 # 80008138 <digits+0x108>
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	106080e7          	jalr	262(ra) # 80000548 <panic>

000000008000144a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000144a:	1101                	addi	sp,sp,-32
    8000144c:	ec06                	sd	ra,24(sp)
    8000144e:	e822                	sd	s0,16(sp)
    80001450:	e426                	sd	s1,8(sp)
    80001452:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001454:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001456:	00b67d63          	bgeu	a2,a1,80001470 <uvmdealloc+0x26>
    8000145a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145c:	6785                	lui	a5,0x1
    8000145e:	17fd                	addi	a5,a5,-1
    80001460:	00f60733          	add	a4,a2,a5
    80001464:	767d                	lui	a2,0xfffff
    80001466:	8f71                	and	a4,a4,a2
    80001468:	97ae                	add	a5,a5,a1
    8000146a:	8ff1                	and	a5,a5,a2
    8000146c:	00f76863          	bltu	a4,a5,8000147c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001470:	8526                	mv	a0,s1
    80001472:	60e2                	ld	ra,24(sp)
    80001474:	6442                	ld	s0,16(sp)
    80001476:	64a2                	ld	s1,8(sp)
    80001478:	6105                	addi	sp,sp,32
    8000147a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147c:	8f99                	sub	a5,a5,a4
    8000147e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001480:	4685                	li	a3,1
    80001482:	0007861b          	sext.w	a2,a5
    80001486:	85ba                	mv	a1,a4
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	e5e080e7          	jalr	-418(ra) # 800012e6 <uvmunmap>
    80001490:	b7c5                	j	80001470 <uvmdealloc+0x26>

0000000080001492 <uvmalloc>:
  if(newsz < oldsz)
    80001492:	0ab66163          	bltu	a2,a1,80001534 <uvmalloc+0xa2>
{
    80001496:	7139                	addi	sp,sp,-64
    80001498:	fc06                	sd	ra,56(sp)
    8000149a:	f822                	sd	s0,48(sp)
    8000149c:	f426                	sd	s1,40(sp)
    8000149e:	f04a                	sd	s2,32(sp)
    800014a0:	ec4e                	sd	s3,24(sp)
    800014a2:	e852                	sd	s4,16(sp)
    800014a4:	e456                	sd	s5,8(sp)
    800014a6:	0080                	addi	s0,sp,64
    800014a8:	8aaa                	mv	s5,a0
    800014aa:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ac:	6985                	lui	s3,0x1
    800014ae:	19fd                	addi	s3,s3,-1
    800014b0:	95ce                	add	a1,a1,s3
    800014b2:	79fd                	lui	s3,0xfffff
    800014b4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b8:	08c9f063          	bgeu	s3,a2,80001538 <uvmalloc+0xa6>
    800014bc:	894e                	mv	s2,s3
    mem = kalloc();
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	662080e7          	jalr	1634(ra) # 80000b20 <kalloc>
    800014c6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c8:	c51d                	beqz	a0,800014f6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ca:	6605                	lui	a2,0x1
    800014cc:	4581                	li	a1,0
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	83e080e7          	jalr	-1986(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d6:	4779                	li	a4,30
    800014d8:	86a6                	mv	a3,s1
    800014da:	6605                	lui	a2,0x1
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	c6e080e7          	jalr	-914(ra) # 8000114e <mappages>
    800014e8:	e905                	bnez	a0,80001518 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ea:	6785                	lui	a5,0x1
    800014ec:	993e                	add	s2,s2,a5
    800014ee:	fd4968e3          	bltu	s2,s4,800014be <uvmalloc+0x2c>
  return newsz;
    800014f2:	8552                	mv	a0,s4
    800014f4:	a809                	j	80001506 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f6:	864e                	mv	a2,s3
    800014f8:	85ca                	mv	a1,s2
    800014fa:	8556                	mv	a0,s5
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	f4e080e7          	jalr	-178(ra) # 8000144a <uvmdealloc>
      return 0;
    80001504:	4501                	li	a0,0
}
    80001506:	70e2                	ld	ra,56(sp)
    80001508:	7442                	ld	s0,48(sp)
    8000150a:	74a2                	ld	s1,40(sp)
    8000150c:	7902                	ld	s2,32(sp)
    8000150e:	69e2                	ld	s3,24(sp)
    80001510:	6a42                	ld	s4,16(sp)
    80001512:	6aa2                	ld	s5,8(sp)
    80001514:	6121                	addi	sp,sp,64
    80001516:	8082                	ret
      kfree(mem);
    80001518:	8526                	mv	a0,s1
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	50a080e7          	jalr	1290(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001522:	864e                	mv	a2,s3
    80001524:	85ca                	mv	a1,s2
    80001526:	8556                	mv	a0,s5
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f22080e7          	jalr	-222(ra) # 8000144a <uvmdealloc>
      return 0;
    80001530:	4501                	li	a0,0
    80001532:	bfd1                	j	80001506 <uvmalloc+0x74>
    return oldsz;
    80001534:	852e                	mv	a0,a1
}
    80001536:	8082                	ret
  return newsz;
    80001538:	8532                	mv	a0,a2
    8000153a:	b7f1                	j	80001506 <uvmalloc+0x74>

000000008000153c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153c:	7179                	addi	sp,sp,-48
    8000153e:	f406                	sd	ra,40(sp)
    80001540:	f022                	sd	s0,32(sp)
    80001542:	ec26                	sd	s1,24(sp)
    80001544:	e84a                	sd	s2,16(sp)
    80001546:	e44e                	sd	s3,8(sp)
    80001548:	e052                	sd	s4,0(sp)
    8000154a:	1800                	addi	s0,sp,48
    8000154c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154e:	84aa                	mv	s1,a0
    80001550:	6905                	lui	s2,0x1
    80001552:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001554:	4985                	li	s3,1
    80001556:	a821                	j	8000156e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001558:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000155a:	0532                	slli	a0,a0,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fe0080e7          	jalr	-32(ra) # 8000153c <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000156e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f57793          	andi	a5,a0,15
    80001574:	ff3782e3          	beq	a5,s3,80001558 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8905                	andi	a0,a0,1
    8000157a:	d57d                	beqz	a0,80001568 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bdc50513          	addi	a0,a0,-1060 # 80008158 <digits+0x128>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fc4080e7          	jalr	-60(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	496080e7          	jalr	1174(ra) # 80000a24 <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f86080e7          	jalr	-122(ra) # 8000153c <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6605                	lui	a2,0x1
    800015ca:	167d                	addi	a2,a2,-1
    800015cc:	962e                	add	a2,a2,a1
    800015ce:	4685                	li	a3,1
    800015d0:	8231                	srli	a2,a2,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	d12080e7          	jalr	-750(ra) # 800012e6 <uvmunmap>
    800015dc:	bfe1                	j	800015b4 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	9fc080e7          	jalr	-1540(ra) # 80001000 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	4fe080e7          	jalr	1278(ra) # 80000b20 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	73a080e7          	jalr	1850(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	b0a080e7          	jalr	-1270(ra) # 8000114e <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b1050513          	addi	a0,a0,-1264 # 80008168 <digits+0x138>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b2050513          	addi	a0,a0,-1248 # 80008188 <digits+0x158>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ed8080e7          	jalr	-296(ra) # 80000548 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3aa080e7          	jalr	938(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c5a080e7          	jalr	-934(ra) # 800012e6 <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <kvmcopy>:

//向进程的内核页表(非全局内核页表）中拷贝用户页表数据
int
kvmcopy(pagetable_t src, pagetable_t dst, uint64 oldsz,uint64 newsz)
{
    800016b0:	715d                	addi	sp,sp,-80
    800016b2:	e486                	sd	ra,72(sp)
    800016b4:	e0a2                	sd	s0,64(sp)
    800016b6:	fc26                	sd	s1,56(sp)
    800016b8:	f84a                	sd	s2,48(sp)
    800016ba:	f44e                	sd	s3,40(sp)
    800016bc:	f052                	sd	s4,32(sp)
    800016be:	ec56                	sd	s5,24(sp)
    800016c0:	e85a                	sd	s6,16(sp)
    800016c2:	e45e                	sd	s7,8(sp)
    800016c4:	e062                	sd	s8,0(sp)
    800016c6:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = PGROUNDUP(oldsz); i < newsz; i += PGSIZE){
    800016c8:	6485                	lui	s1,0x1
    800016ca:	14fd                	addi	s1,s1,-1
    800016cc:	9626                	add	a2,a2,s1
    800016ce:	74fd                	lui	s1,0xfffff
    800016d0:	8cf1                	and	s1,s1,a2
    800016d2:	0cd4fe63          	bgeu	s1,a3,800017ae <kvmcopy+0xfe>
    800016d6:	8b2a                	mv	s6,a0
    800016d8:	8aae                	mv	s5,a1
    800016da:	8a36                	mv	s4,a3
    if(i > PLIC)
    800016dc:	0c0007b7          	lui	a5,0xc000
    800016e0:	0697e163          	bltu	a5,s1,80001742 <kvmcopy+0x92>
    800016e4:	0c001bb7          	lui	s7,0xc001
      panic("kvmcopy: pte should restrain less than PLIC");
    if((pte = walk(src, i, 0)) == 0)
    800016e8:	4601                	li	a2,0
    800016ea:	85a6                	mv	a1,s1
    800016ec:	855a                	mv	a0,s6
    800016ee:	00000097          	auipc	ra,0x0
    800016f2:	912080e7          	jalr	-1774(ra) # 80001000 <walk>
    800016f6:	cd31                	beqz	a0,80001752 <kvmcopy+0xa2>
      panic("kvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016f8:	6118                	ld	a4,0(a0)
    800016fa:	00177793          	andi	a5,a4,1
    800016fe:	c3b5                	beqz	a5,80001762 <kvmcopy+0xb2>
      panic("kvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001700:	00a75c13          	srli	s8,a4,0xa
    80001704:	0c32                	slli	s8,s8,0xc
    flags = PTE_FLAGS(*pte) & (~PTE_U);
    80001706:	3ef77913          	andi	s2,a4,1007
    if((mem = kalloc()) == 0)
    8000170a:	fffff097          	auipc	ra,0xfffff
    8000170e:	416080e7          	jalr	1046(ra) # 80000b20 <kalloc>
    80001712:	89aa                	mv	s3,a0
    80001714:	cd39                	beqz	a0,80001772 <kvmcopy+0xc2>
      panic("kvmcopy:kalloc error");
    memmove(mem, (char*)pa, PGSIZE);
    80001716:	6605                	lui	a2,0x1
    80001718:	85e2                	mv	a1,s8
    8000171a:	fffff097          	auipc	ra,0xfffff
    8000171e:	652080e7          	jalr	1618(ra) # 80000d6c <memmove>
    //todo 这里有一个疑问点，这里我映射i，这个i可能是低于0x10000的，也就是低于硬件地址，这合理吗？
    if(mappages(dst, i, PGSIZE, (uint64)mem, flags) != 0){
    80001722:	874a                	mv	a4,s2
    80001724:	86ce                	mv	a3,s3
    80001726:	6605                	lui	a2,0x1
    80001728:	85a6                	mv	a1,s1
    8000172a:	8556                	mv	a0,s5
    8000172c:	00000097          	auipc	ra,0x0
    80001730:	a22080e7          	jalr	-1502(ra) # 8000114e <mappages>
    80001734:	e539                	bnez	a0,80001782 <kvmcopy+0xd2>
  for(i = PGROUNDUP(oldsz); i < newsz; i += PGSIZE){
    80001736:	6785                	lui	a5,0x1
    80001738:	94be                	add	s1,s1,a5
    8000173a:	0544fe63          	bgeu	s1,s4,80001796 <kvmcopy+0xe6>
    if(i > PLIC)
    8000173e:	fb7495e3          	bne	s1,s7,800016e8 <kvmcopy+0x38>
      panic("kvmcopy: pte should restrain less than PLIC");
    80001742:	00007517          	auipc	a0,0x7
    80001746:	a6650513          	addi	a0,a0,-1434 # 800081a8 <digits+0x178>
    8000174a:	fffff097          	auipc	ra,0xfffff
    8000174e:	dfe080e7          	jalr	-514(ra) # 80000548 <panic>
      panic("kvmcopy: pte should exist");
    80001752:	00007517          	auipc	a0,0x7
    80001756:	a8650513          	addi	a0,a0,-1402 # 800081d8 <digits+0x1a8>
    8000175a:	fffff097          	auipc	ra,0xfffff
    8000175e:	dee080e7          	jalr	-530(ra) # 80000548 <panic>
      panic("kvmcopy: page not present");
    80001762:	00007517          	auipc	a0,0x7
    80001766:	a9650513          	addi	a0,a0,-1386 # 800081f8 <digits+0x1c8>
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	dde080e7          	jalr	-546(ra) # 80000548 <panic>
      panic("kvmcopy:kalloc error");
    80001772:	00007517          	auipc	a0,0x7
    80001776:	aa650513          	addi	a0,a0,-1370 # 80008218 <digits+0x1e8>
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	dce080e7          	jalr	-562(ra) # 80000548 <panic>
      //清理已经映射的部分，但是不释放物理内存
      uvmunmap(dst,0,i/PGSIZE,0);
    80001782:	4681                	li	a3,0
    80001784:	00c4d613          	srli	a2,s1,0xc
    80001788:	4581                	li	a1,0
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	b5a080e7          	jalr	-1190(ra) # 800012e6 <uvmunmap>
      return -1;
    80001794:	557d                	li	a0,-1
    }
  }
  return 0;
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret
  return 0;
    800017ae:	4501                	li	a0,0
    800017b0:	b7dd                	j	80001796 <kvmcopy+0xe6>

00000000800017b2 <kvmdealloc>:


uint64
kvmdealloc(pagetable_t kpagetable, uint64 oldsz, uint64 newsz)
{
    800017b2:	1101                	addi	sp,sp,-32
    800017b4:	ec06                	sd	ra,24(sp)
    800017b6:	e822                	sd	s0,16(sp)
    800017b8:	e426                	sd	s1,8(sp)
    800017ba:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017bc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017be:	00b67d63          	bgeu	a2,a1,800017d8 <kvmdealloc+0x26>
    800017c2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017c4:	6785                	lui	a5,0x1
    800017c6:	17fd                	addi	a5,a5,-1
    800017c8:	00f60733          	add	a4,a2,a5
    800017cc:	767d                	lui	a2,0xfffff
    800017ce:	8f71                	and	a4,a4,a2
    800017d0:	97ae                	add	a5,a5,a1
    800017d2:	8ff1                	and	a5,a5,a2
    800017d4:	00f76863          	bltu	a4,a5,800017e4 <kvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(kpagetable, PGROUNDUP(newsz), npages, 0);
  }

  return newsz;
}
    800017d8:	8526                	mv	a0,s1
    800017da:	60e2                	ld	ra,24(sp)
    800017dc:	6442                	ld	s0,16(sp)
    800017de:	64a2                	ld	s1,8(sp)
    800017e0:	6105                	addi	sp,sp,32
    800017e2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017e4:	8f99                	sub	a5,a5,a4
    800017e6:	83b1                	srli	a5,a5,0xc
    uvmunmap(kpagetable, PGROUNDUP(newsz), npages, 0);
    800017e8:	4681                	li	a3,0
    800017ea:	0007861b          	sext.w	a2,a5
    800017ee:	85ba                	mv	a1,a4
    800017f0:	00000097          	auipc	ra,0x0
    800017f4:	af6080e7          	jalr	-1290(ra) # 800012e6 <uvmunmap>
    800017f8:	b7c5                	j	800017d8 <kvmdealloc+0x26>

00000000800017fa <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017fa:	1141                	addi	sp,sp,-16
    800017fc:	e406                	sd	ra,8(sp)
    800017fe:	e022                	sd	s0,0(sp)
    80001800:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001802:	4601                	li	a2,0
    80001804:	fffff097          	auipc	ra,0xfffff
    80001808:	7fc080e7          	jalr	2044(ra) # 80001000 <walk>
  if(pte == 0)
    8000180c:	c901                	beqz	a0,8000181c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000180e:	611c                	ld	a5,0(a0)
    80001810:	9bbd                	andi	a5,a5,-17
    80001812:	e11c                	sd	a5,0(a0)
}
    80001814:	60a2                	ld	ra,8(sp)
    80001816:	6402                	ld	s0,0(sp)
    80001818:	0141                	addi	sp,sp,16
    8000181a:	8082                	ret
    panic("uvmclear");
    8000181c:	00007517          	auipc	a0,0x7
    80001820:	a1450513          	addi	a0,a0,-1516 # 80008230 <digits+0x200>
    80001824:	fffff097          	auipc	ra,0xfffff
    80001828:	d24080e7          	jalr	-732(ra) # 80000548 <panic>

000000008000182c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000182c:	c6bd                	beqz	a3,8000189a <copyout+0x6e>
{
    8000182e:	715d                	addi	sp,sp,-80
    80001830:	e486                	sd	ra,72(sp)
    80001832:	e0a2                	sd	s0,64(sp)
    80001834:	fc26                	sd	s1,56(sp)
    80001836:	f84a                	sd	s2,48(sp)
    80001838:	f44e                	sd	s3,40(sp)
    8000183a:	f052                	sd	s4,32(sp)
    8000183c:	ec56                	sd	s5,24(sp)
    8000183e:	e85a                	sd	s6,16(sp)
    80001840:	e45e                	sd	s7,8(sp)
    80001842:	e062                	sd	s8,0(sp)
    80001844:	0880                	addi	s0,sp,80
    80001846:	8b2a                	mv	s6,a0
    80001848:	8c2e                	mv	s8,a1
    8000184a:	8a32                	mv	s4,a2
    8000184c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000184e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001850:	6a85                	lui	s5,0x1
    80001852:	a015                	j	80001876 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001854:	9562                	add	a0,a0,s8
    80001856:	0004861b          	sext.w	a2,s1
    8000185a:	85d2                	mv	a1,s4
    8000185c:	41250533          	sub	a0,a0,s2
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	50c080e7          	jalr	1292(ra) # 80000d6c <memmove>

    len -= n;
    80001868:	409989b3          	sub	s3,s3,s1
    src += n;
    8000186c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000186e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001872:	02098263          	beqz	s3,80001896 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001876:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000187a:	85ca                	mv	a1,s2
    8000187c:	855a                	mv	a0,s6
    8000187e:	00000097          	auipc	ra,0x0
    80001882:	828080e7          	jalr	-2008(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001886:	cd01                	beqz	a0,8000189e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001888:	418904b3          	sub	s1,s2,s8
    8000188c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000188e:	fc99f3e3          	bgeu	s3,s1,80001854 <copyout+0x28>
    80001892:	84ce                	mv	s1,s3
    80001894:	b7c1                	j	80001854 <copyout+0x28>
  }
  return 0;
    80001896:	4501                	li	a0,0
    80001898:	a021                	j	800018a0 <copyout+0x74>
    8000189a:	4501                	li	a0,0
}
    8000189c:	8082                	ret
      return -1;
    8000189e:	557d                	li	a0,-1
}
    800018a0:	60a6                	ld	ra,72(sp)
    800018a2:	6406                	ld	s0,64(sp)
    800018a4:	74e2                	ld	s1,56(sp)
    800018a6:	7942                	ld	s2,48(sp)
    800018a8:	79a2                	ld	s3,40(sp)
    800018aa:	7a02                	ld	s4,32(sp)
    800018ac:	6ae2                	ld	s5,24(sp)
    800018ae:	6b42                	ld	s6,16(sp)
    800018b0:	6ba2                	ld	s7,8(sp)
    800018b2:	6c02                	ld	s8,0(sp)
    800018b4:	6161                	addi	sp,sp,80
    800018b6:	8082                	ret

00000000800018b8 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800018b8:	1141                	addi	sp,sp,-16
    800018ba:	e406                	sd	ra,8(sp)
    800018bc:	e022                	sd	s0,0(sp)
    800018be:	0800                	addi	s0,sp,16
  return copyin_new(pagetable,dst,srcva,len);
    800018c0:	00005097          	auipc	ra,0x5
    800018c4:	d00080e7          	jalr	-768(ra) # 800065c0 <copyin_new>
  //   len -= n;
  //   dst += n;
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
}
    800018c8:	60a2                	ld	ra,8(sp)
    800018ca:	6402                	ld	s0,0(sp)
    800018cc:	0141                	addi	sp,sp,16
    800018ce:	8082                	ret

00000000800018d0 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800018d0:	1141                	addi	sp,sp,-16
    800018d2:	e406                	sd	ra,8(sp)
    800018d4:	e022                	sd	s0,0(sp)
    800018d6:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable,dst,srcva,max);
    800018d8:	00005097          	auipc	ra,0x5
    800018dc:	d50080e7          	jalr	-688(ra) # 80006628 <copyinstr_new>
  // if(got_null){
  //   return 0;
  // } else {
  //   return -1;
  // }
}
    800018e0:	60a2                	ld	ra,8(sp)
    800018e2:	6402                	ld	s0,0(sp)
    800018e4:	0141                	addi	sp,sp,16
    800018e6:	8082                	ret

00000000800018e8 <vmprint>:
void
vmprint(pagetable_t pagetable,uint level){
    // there are 2^9 = 512 PTEs in a page table.
  if(pagetable == 0){
    800018e8:	c56d                	beqz	a0,800019d2 <vmprint+0xea>
vmprint(pagetable_t pagetable,uint level){
    800018ea:	711d                	addi	sp,sp,-96
    800018ec:	ec86                	sd	ra,88(sp)
    800018ee:	e8a2                	sd	s0,80(sp)
    800018f0:	e4a6                	sd	s1,72(sp)
    800018f2:	e0ca                	sd	s2,64(sp)
    800018f4:	fc4e                	sd	s3,56(sp)
    800018f6:	f852                	sd	s4,48(sp)
    800018f8:	f456                	sd	s5,40(sp)
    800018fa:	f05a                	sd	s6,32(sp)
    800018fc:	ec5e                	sd	s7,24(sp)
    800018fe:	e862                	sd	s8,16(sp)
    80001900:	e466                	sd	s9,8(sp)
    80001902:	e06a                	sd	s10,0(sp)
    80001904:	1080                	addi	s0,sp,96
    80001906:	8b2a                	mv	s6,a0
    80001908:	8a2e                	mv	s4,a1
    return;
  }
  if(level == 0){
    8000190a:	c185                	beqz	a1,8000192a <vmprint+0x42>
vmprint(pagetable_t pagetable,uint level){
    8000190c:	4981                	li	s3,0
    printf("page table %p\n",pagetable);
  }

  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000190e:	4c05                	li	s8,1
    80001910:	2a05                	addiw	s4,s4,1
      }
      printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
      uint64 child = PTE2PA(pte);
      vmprint((pagetable_t)child,level+1);
    } else if(pte & PTE_V){
      for(int j = 0;j<=level;j++){
    80001912:	4d01                	li	s10,0
        printf(" ..");
    80001914:	00007a97          	auipc	s5,0x7
    80001918:	93ca8a93          	addi	s5,s5,-1732 # 80008250 <digits+0x220>
      }
      printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    8000191c:	00007c97          	auipc	s9,0x7
    80001920:	93cc8c93          	addi	s9,s9,-1732 # 80008258 <digits+0x228>
  for(int i = 0; i < 512; i++){
    80001924:	20000b93          	li	s7,512
    80001928:	a0a5                	j	80001990 <vmprint+0xa8>
    printf("page table %p\n",pagetable);
    8000192a:	85aa                	mv	a1,a0
    8000192c:	00007517          	auipc	a0,0x7
    80001930:	91450513          	addi	a0,a0,-1772 # 80008240 <digits+0x210>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	c5e080e7          	jalr	-930(ra) # 80000592 <printf>
    8000193c:	bfc1                	j	8000190c <vmprint+0x24>
      for(int j = 0;j<=level;j++){
    8000193e:	84ea                	mv	s1,s10
        printf(" ..");
    80001940:	8556                	mv	a0,s5
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	c50080e7          	jalr	-944(ra) # 80000592 <printf>
      for(int j = 0;j<=level;j++){
    8000194a:	2485                	addiw	s1,s1,1
    8000194c:	ff449ae3          	bne	s1,s4,80001940 <vmprint+0x58>
      printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    80001950:	00a95493          	srli	s1,s2,0xa
    80001954:	04b2                	slli	s1,s1,0xc
    80001956:	86a6                	mv	a3,s1
    80001958:	864a                	mv	a2,s2
    8000195a:	85ce                	mv	a1,s3
    8000195c:	8566                	mv	a0,s9
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	c34080e7          	jalr	-972(ra) # 80000592 <printf>
      vmprint((pagetable_t)child,level+1);
    80001966:	85d2                	mv	a1,s4
    80001968:	8526                	mv	a0,s1
    8000196a:	00000097          	auipc	ra,0x0
    8000196e:	f7e080e7          	jalr	-130(ra) # 800018e8 <vmprint>
    80001972:	a819                	j	80001988 <vmprint+0xa0>
      printf("%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    80001974:	00a95693          	srli	a3,s2,0xa
    80001978:	06b2                	slli	a3,a3,0xc
    8000197a:	864a                	mv	a2,s2
    8000197c:	85ce                	mv	a1,s3
    8000197e:	8566                	mv	a0,s9
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	c12080e7          	jalr	-1006(ra) # 80000592 <printf>
  for(int i = 0; i < 512; i++){
    80001988:	2985                	addiw	s3,s3,1
    8000198a:	0b21                	addi	s6,s6,8
    8000198c:	03798563          	beq	s3,s7,800019b6 <vmprint+0xce>
    pte_t pte = pagetable[i];
    80001990:	000b3903          	ld	s2,0(s6) # 1000 <_entry-0x7ffff000>
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001994:	00f97793          	andi	a5,s2,15
    80001998:	fb8783e3          	beq	a5,s8,8000193e <vmprint+0x56>
    } else if(pte & PTE_V){
    8000199c:	00197793          	andi	a5,s2,1
    800019a0:	d7e5                	beqz	a5,80001988 <vmprint+0xa0>
      for(int j = 0;j<=level;j++){
    800019a2:	84ea                	mv	s1,s10
        printf(" ..");
    800019a4:	8556                	mv	a0,s5
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	bec080e7          	jalr	-1044(ra) # 80000592 <printf>
      for(int j = 0;j<=level;j++){
    800019ae:	2485                	addiw	s1,s1,1
    800019b0:	ff449ae3          	bne	s1,s4,800019a4 <vmprint+0xbc>
    800019b4:	b7c1                	j	80001974 <vmprint+0x8c>
    }
  }
}
    800019b6:	60e6                	ld	ra,88(sp)
    800019b8:	6446                	ld	s0,80(sp)
    800019ba:	64a6                	ld	s1,72(sp)
    800019bc:	6906                	ld	s2,64(sp)
    800019be:	79e2                	ld	s3,56(sp)
    800019c0:	7a42                	ld	s4,48(sp)
    800019c2:	7aa2                	ld	s5,40(sp)
    800019c4:	7b02                	ld	s6,32(sp)
    800019c6:	6be2                	ld	s7,24(sp)
    800019c8:	6c42                	ld	s8,16(sp)
    800019ca:	6ca2                	ld	s9,8(sp)
    800019cc:	6d02                	ld	s10,0(sp)
    800019ce:	6125                	addi	sp,sp,96
    800019d0:	8082                	ret
    800019d2:	8082                	ret

00000000800019d4 <ukvmmap>:
  return kpagetable;
}

void
ukvmmap(pagetable_t kernel_pagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    800019d4:	1141                	addi	sp,sp,-16
    800019d6:	e406                	sd	ra,8(sp)
    800019d8:	e022                	sd	s0,0(sp)
    800019da:	0800                	addi	s0,sp,16
    800019dc:	87b6                	mv	a5,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800019de:	86b2                	mv	a3,a2
    800019e0:	863e                	mv	a2,a5
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	76c080e7          	jalr	1900(ra) # 8000114e <mappages>
    800019ea:	e509                	bnez	a0,800019f4 <ukvmmap+0x20>
    panic("kvmmap");
}
    800019ec:	60a2                	ld	ra,8(sp)
    800019ee:	6402                	ld	s0,0(sp)
    800019f0:	0141                	addi	sp,sp,16
    800019f2:	8082                	ret
    panic("kvmmap");
    800019f4:	00006517          	auipc	a0,0x6
    800019f8:	6e450513          	addi	a0,a0,1764 # 800080d8 <digits+0xa8>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	b4c080e7          	jalr	-1204(ra) # 80000548 <panic>

0000000080001a04 <proc_kvminit>:
{
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	e04a                	sd	s2,0(sp)
    80001a0e:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc();
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	110080e7          	jalr	272(ra) # 80000b20 <kalloc>
    80001a18:	84aa                	mv	s1,a0
  memset(kpagetable,0,PGSIZE);
    80001a1a:	6605                	lui	a2,0x1
    80001a1c:	4581                	li	a1,0
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	2ee080e7          	jalr	750(ra) # 80000d0c <memset>
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001a26:	4719                	li	a4,6
    80001a28:	6685                	lui	a3,0x1
    80001a2a:	10000637          	lui	a2,0x10000
    80001a2e:	100005b7          	lui	a1,0x10000
    80001a32:	8526                	mv	a0,s1
    80001a34:	00000097          	auipc	ra,0x0
    80001a38:	fa0080e7          	jalr	-96(ra) # 800019d4 <ukvmmap>
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001a3c:	4719                	li	a4,6
    80001a3e:	6685                	lui	a3,0x1
    80001a40:	10001637          	lui	a2,0x10001
    80001a44:	100015b7          	lui	a1,0x10001
    80001a48:	8526                	mv	a0,s1
    80001a4a:	00000097          	auipc	ra,0x0
    80001a4e:	f8a080e7          	jalr	-118(ra) # 800019d4 <ukvmmap>
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001a52:	4719                	li	a4,6
    80001a54:	004006b7          	lui	a3,0x400
    80001a58:	0c000637          	lui	a2,0xc000
    80001a5c:	0c0005b7          	lui	a1,0xc000
    80001a60:	8526                	mv	a0,s1
    80001a62:	00000097          	auipc	ra,0x0
    80001a66:	f72080e7          	jalr	-142(ra) # 800019d4 <ukvmmap>
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001a6a:	00006917          	auipc	s2,0x6
    80001a6e:	59690913          	addi	s2,s2,1430 # 80008000 <etext>
    80001a72:	4729                	li	a4,10
    80001a74:	80006697          	auipc	a3,0x80006
    80001a78:	58c68693          	addi	a3,a3,1420 # 8000 <_entry-0x7fff8000>
    80001a7c:	4605                	li	a2,1
    80001a7e:	067e                	slli	a2,a2,0x1f
    80001a80:	85b2                	mv	a1,a2
    80001a82:	8526                	mv	a0,s1
    80001a84:	00000097          	auipc	ra,0x0
    80001a88:	f50080e7          	jalr	-176(ra) # 800019d4 <ukvmmap>
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001a8c:	4719                	li	a4,6
    80001a8e:	46c5                	li	a3,17
    80001a90:	06ee                	slli	a3,a3,0x1b
    80001a92:	412686b3          	sub	a3,a3,s2
    80001a96:	864a                	mv	a2,s2
    80001a98:	85ca                	mv	a1,s2
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	f38080e7          	jalr	-200(ra) # 800019d4 <ukvmmap>
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001aa4:	4729                	li	a4,10
    80001aa6:	6685                	lui	a3,0x1
    80001aa8:	00005617          	auipc	a2,0x5
    80001aac:	55860613          	addi	a2,a2,1368 # 80007000 <_trampoline>
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	8526                	mv	a0,s1
    80001aba:	00000097          	auipc	ra,0x0
    80001abe:	f1a080e7          	jalr	-230(ra) # 800019d4 <ukvmmap>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret

0000000080001ad0 <ukvminithart>:

void ukvminithart(pagetable_t kpagetable){
    80001ad0:	1141                	addi	sp,sp,-16
    80001ad2:	e422                	sd	s0,8(sp)
    80001ad4:	0800                	addi	s0,sp,16
    w_satp(MAKE_SATP(kpagetable));
    80001ad6:	8131                	srli	a0,a0,0xc
    80001ad8:	57fd                	li	a5,-1
    80001ada:	17fe                	slli	a5,a5,0x3f
    80001adc:	8d5d                	or	a0,a0,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80001ade:	18051073          	csrw	satp,a0
  asm volatile("sfence.vma zero, zero");
    80001ae2:	12000073          	sfence.vma
    sfence_vma();
}
    80001ae6:	6422                	ld	s0,8(sp)
    80001ae8:	0141                	addi	sp,sp,16
    80001aea:	8082                	ret

0000000080001aec <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	1000                	addi	s0,sp,32
    80001af6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	09e080e7          	jalr	158(ra) # 80000b96 <holding>
    80001b00:	c909                	beqz	a0,80001b12 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001b02:	749c                	ld	a5,40(s1)
    80001b04:	00978f63          	beq	a5,s1,80001b22 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001b08:	60e2                	ld	ra,24(sp)
    80001b0a:	6442                	ld	s0,16(sp)
    80001b0c:	64a2                	ld	s1,8(sp)
    80001b0e:	6105                	addi	sp,sp,32
    80001b10:	8082                	ret
    panic("wakeup1");
    80001b12:	00006517          	auipc	a0,0x6
    80001b16:	75e50513          	addi	a0,a0,1886 # 80008270 <digits+0x240>
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b22:	4c98                	lw	a4,24(s1)
    80001b24:	4785                	li	a5,1
    80001b26:	fef711e3          	bne	a4,a5,80001b08 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b2a:	4789                	li	a5,2
    80001b2c:	cc9c                	sw	a5,24(s1)
}
    80001b2e:	bfe9                	j	80001b08 <wakeup1+0x1c>

0000000080001b30 <procinit>:
{
    80001b30:	7179                	addi	sp,sp,-48
    80001b32:	f406                	sd	ra,40(sp)
    80001b34:	f022                	sd	s0,32(sp)
    80001b36:	ec26                	sd	s1,24(sp)
    80001b38:	e84a                	sd	s2,16(sp)
    80001b3a:	e44e                	sd	s3,8(sp)
    80001b3c:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001b3e:	00006597          	auipc	a1,0x6
    80001b42:	73a58593          	addi	a1,a1,1850 # 80008278 <digits+0x248>
    80001b46:	00010517          	auipc	a0,0x10
    80001b4a:	e0a50513          	addi	a0,a0,-502 # 80011950 <pid_lock>
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	032080e7          	jalr	50(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b56:	00010497          	auipc	s1,0x10
    80001b5a:	21248493          	addi	s1,s1,530 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001b5e:	00006997          	auipc	s3,0x6
    80001b62:	72298993          	addi	s3,s3,1826 # 80008280 <digits+0x250>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b66:	00016917          	auipc	s2,0x16
    80001b6a:	e0290913          	addi	s2,s2,-510 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001b6e:	85ce                	mv	a1,s3
    80001b70:	8526                	mv	a0,s1
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	00e080e7          	jalr	14(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7a:	17048493          	addi	s1,s1,368
    80001b7e:	ff2498e3          	bne	s1,s2,80001b6e <procinit+0x3e>
}
    80001b82:	70a2                	ld	ra,40(sp)
    80001b84:	7402                	ld	s0,32(sp)
    80001b86:	64e2                	ld	s1,24(sp)
    80001b88:	6942                	ld	s2,16(sp)
    80001b8a:	69a2                	ld	s3,8(sp)
    80001b8c:	6145                	addi	sp,sp,48
    80001b8e:	8082                	ret

0000000080001b90 <cpuid>:
{
    80001b90:	1141                	addi	sp,sp,-16
    80001b92:	e422                	sd	s0,8(sp)
    80001b94:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b96:	8512                	mv	a0,tp
}
    80001b98:	2501                	sext.w	a0,a0
    80001b9a:	6422                	ld	s0,8(sp)
    80001b9c:	0141                	addi	sp,sp,16
    80001b9e:	8082                	ret

0000000080001ba0 <mycpu>:
mycpu(void) {
    80001ba0:	1141                	addi	sp,sp,-16
    80001ba2:	e422                	sd	s0,8(sp)
    80001ba4:	0800                	addi	s0,sp,16
    80001ba6:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ba8:	2781                	sext.w	a5,a5
    80001baa:	079e                	slli	a5,a5,0x7
}
    80001bac:	00010517          	auipc	a0,0x10
    80001bb0:	dbc50513          	addi	a0,a0,-580 # 80011968 <cpus>
    80001bb4:	953e                	add	a0,a0,a5
    80001bb6:	6422                	ld	s0,8(sp)
    80001bb8:	0141                	addi	sp,sp,16
    80001bba:	8082                	ret

0000000080001bbc <myproc>:
myproc(void) {
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	1000                	addi	s0,sp,32
  push_off();
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	ffe080e7          	jalr	-2(ra) # 80000bc4 <push_off>
    80001bce:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001bd0:	2781                	sext.w	a5,a5
    80001bd2:	079e                	slli	a5,a5,0x7
    80001bd4:	00010717          	auipc	a4,0x10
    80001bd8:	d7c70713          	addi	a4,a4,-644 # 80011950 <pid_lock>
    80001bdc:	97ba                	add	a5,a5,a4
    80001bde:	6f84                	ld	s1,24(a5)
  pop_off();
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	084080e7          	jalr	132(ra) # 80000c64 <pop_off>
}
    80001be8:	8526                	mv	a0,s1
    80001bea:	60e2                	ld	ra,24(sp)
    80001bec:	6442                	ld	s0,16(sp)
    80001bee:	64a2                	ld	s1,8(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret

0000000080001bf4 <forkret>:
{
    80001bf4:	1141                	addi	sp,sp,-16
    80001bf6:	e406                	sd	ra,8(sp)
    80001bf8:	e022                	sd	s0,0(sp)
    80001bfa:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	fc0080e7          	jalr	-64(ra) # 80001bbc <myproc>
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	0c0080e7          	jalr	192(ra) # 80000cc4 <release>
  if (first) {
    80001c0c:	00007797          	auipc	a5,0x7
    80001c10:	d347a783          	lw	a5,-716(a5) # 80008940 <first.1721>
    80001c14:	eb89                	bnez	a5,80001c26 <forkret+0x32>
  usertrapret();
    80001c16:	00001097          	auipc	ra,0x1
    80001c1a:	dae080e7          	jalr	-594(ra) # 800029c4 <usertrapret>
}
    80001c1e:	60a2                	ld	ra,8(sp)
    80001c20:	6402                	ld	s0,0(sp)
    80001c22:	0141                	addi	sp,sp,16
    80001c24:	8082                	ret
    first = 0;
    80001c26:	00007797          	auipc	a5,0x7
    80001c2a:	d007ad23          	sw	zero,-742(a5) # 80008940 <first.1721>
    fsinit(ROOTDEV);
    80001c2e:	4505                	li	a0,1
    80001c30:	00002097          	auipc	ra,0x2
    80001c34:	ad6080e7          	jalr	-1322(ra) # 80003706 <fsinit>
    80001c38:	bff9                	j	80001c16 <forkret+0x22>

0000000080001c3a <allocpid>:
allocpid() {
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c46:	00010917          	auipc	s2,0x10
    80001c4a:	d0a90913          	addi	s2,s2,-758 # 80011950 <pid_lock>
    80001c4e:	854a                	mv	a0,s2
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	fc0080e7          	jalr	-64(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001c58:	00007797          	auipc	a5,0x7
    80001c5c:	cec78793          	addi	a5,a5,-788 # 80008944 <nextpid>
    80001c60:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c62:	0014871b          	addiw	a4,s1,1
    80001c66:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c68:	854a                	mv	a0,s2
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	05a080e7          	jalr	90(ra) # 80000cc4 <release>
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret

0000000080001c80 <proc_pagetable>:
{
    80001c80:	1101                	addi	sp,sp,-32
    80001c82:	ec06                	sd	ra,24(sp)
    80001c84:	e822                	sd	s0,16(sp)
    80001c86:	e426                	sd	s1,8(sp)
    80001c88:	e04a                	sd	s2,0(sp)
    80001c8a:	1000                	addi	s0,sp,32
    80001c8c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	71c080e7          	jalr	1820(ra) # 800013aa <uvmcreate>
    80001c96:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c98:	c121                	beqz	a0,80001cd8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c9a:	4729                	li	a4,10
    80001c9c:	00005697          	auipc	a3,0x5
    80001ca0:	36468693          	addi	a3,a3,868 # 80007000 <_trampoline>
    80001ca4:	6605                	lui	a2,0x1
    80001ca6:	040005b7          	lui	a1,0x4000
    80001caa:	15fd                	addi	a1,a1,-1
    80001cac:	05b2                	slli	a1,a1,0xc
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	4a0080e7          	jalr	1184(ra) # 8000114e <mappages>
    80001cb6:	02054863          	bltz	a0,80001ce6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cba:	4719                	li	a4,6
    80001cbc:	06093683          	ld	a3,96(s2)
    80001cc0:	6605                	lui	a2,0x1
    80001cc2:	020005b7          	lui	a1,0x2000
    80001cc6:	15fd                	addi	a1,a1,-1
    80001cc8:	05b6                	slli	a1,a1,0xd
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	482080e7          	jalr	1154(ra) # 8000114e <mappages>
    80001cd4:	02054163          	bltz	a0,80001cf6 <proc_pagetable+0x76>
}
    80001cd8:	8526                	mv	a0,s1
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6902                	ld	s2,0(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ce6:	4581                	li	a1,0
    80001ce8:	8526                	mv	a0,s1
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	8bc080e7          	jalr	-1860(ra) # 800015a6 <uvmfree>
    return 0;
    80001cf2:	4481                	li	s1,0
    80001cf4:	b7d5                	j	80001cd8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf6:	4681                	li	a3,0
    80001cf8:	4605                	li	a2,1
    80001cfa:	040005b7          	lui	a1,0x4000
    80001cfe:	15fd                	addi	a1,a1,-1
    80001d00:	05b2                	slli	a1,a1,0xc
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	5e2080e7          	jalr	1506(ra) # 800012e6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d0c:	4581                	li	a1,0
    80001d0e:	8526                	mv	a0,s1
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	896080e7          	jalr	-1898(ra) # 800015a6 <uvmfree>
    return 0;
    80001d18:	4481                	li	s1,0
    80001d1a:	bf7d                	j	80001cd8 <proc_pagetable+0x58>

0000000080001d1c <proc_freepagetable>:
{
    80001d1c:	1101                	addi	sp,sp,-32
    80001d1e:	ec06                	sd	ra,24(sp)
    80001d20:	e822                	sd	s0,16(sp)
    80001d22:	e426                	sd	s1,8(sp)
    80001d24:	e04a                	sd	s2,0(sp)
    80001d26:	1000                	addi	s0,sp,32
    80001d28:	84aa                	mv	s1,a0
    80001d2a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d2c:	4681                	li	a3,0
    80001d2e:	4605                	li	a2,1
    80001d30:	040005b7          	lui	a1,0x4000
    80001d34:	15fd                	addi	a1,a1,-1
    80001d36:	05b2                	slli	a1,a1,0xc
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	5ae080e7          	jalr	1454(ra) # 800012e6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d40:	4681                	li	a3,0
    80001d42:	4605                	li	a2,1
    80001d44:	020005b7          	lui	a1,0x2000
    80001d48:	15fd                	addi	a1,a1,-1
    80001d4a:	05b6                	slli	a1,a1,0xd
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	598080e7          	jalr	1432(ra) # 800012e6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d56:	85ca                	mv	a1,s2
    80001d58:	8526                	mv	a0,s1
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	84c080e7          	jalr	-1972(ra) # 800015a6 <uvmfree>
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret

0000000080001d6e <proc_freekpagetable>:
void proc_freekpagetable(pagetable_t kpagetable){
    80001d6e:	7179                	addi	sp,sp,-48
    80001d70:	f406                	sd	ra,40(sp)
    80001d72:	f022                	sd	s0,32(sp)
    80001d74:	ec26                	sd	s1,24(sp)
    80001d76:	e84a                	sd	s2,16(sp)
    80001d78:	e44e                	sd	s3,8(sp)
    80001d7a:	1800                	addi	s0,sp,48
    80001d7c:	89aa                	mv	s3,a0
  for(int i = 0;i<512;i++){
    80001d7e:	84aa                	mv	s1,a0
    80001d80:	6905                	lui	s2,0x1
    80001d82:	992a                	add	s2,s2,a0
    80001d84:	a811                	j	80001d98 <proc_freekpagetable+0x2a>
        uint64 child = PTE2PA(pte);
    80001d86:	8129                	srli	a0,a0,0xa
        proc_freekpagetable((pagetable_t)child);
    80001d88:	0532                	slli	a0,a0,0xc
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	fe4080e7          	jalr	-28(ra) # 80001d6e <proc_freekpagetable>
  for(int i = 0;i<512;i++){
    80001d92:	04a1                	addi	s1,s1,8
    80001d94:	01248c63          	beq	s1,s2,80001dac <proc_freekpagetable+0x3e>
    uint64 pte = kpagetable[i];
    80001d98:	6088                	ld	a0,0(s1)
    if(pte & PTE_V) {
    80001d9a:	00157793          	andi	a5,a0,1
    80001d9e:	dbf5                	beqz	a5,80001d92 <proc_freekpagetable+0x24>
      kpagetable[i] = 0;
    80001da0:	0004b023          	sd	zero,0(s1)
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001da4:	00e57793          	andi	a5,a0,14
    80001da8:	f7ed                	bnez	a5,80001d92 <proc_freekpagetable+0x24>
    80001daa:	bff1                	j	80001d86 <proc_freekpagetable+0x18>
  kfree(kpagetable);
    80001dac:	854e                	mv	a0,s3
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	c76080e7          	jalr	-906(ra) # 80000a24 <kfree>
}
    80001db6:	70a2                	ld	ra,40(sp)
    80001db8:	7402                	ld	s0,32(sp)
    80001dba:	64e2                	ld	s1,24(sp)
    80001dbc:	6942                	ld	s2,16(sp)
    80001dbe:	69a2                	ld	s3,8(sp)
    80001dc0:	6145                	addi	sp,sp,48
    80001dc2:	8082                	ret

0000000080001dc4 <freeproc>:
{
    80001dc4:	1101                	addi	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dd0:	7128                	ld	a0,96(a0)
    80001dd2:	c509                	beqz	a0,80001ddc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	c50080e7          	jalr	-944(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ddc:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001de0:	68a8                	ld	a0,80(s1)
    80001de2:	c511                	beqz	a0,80001dee <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001de4:	64ac                	ld	a1,72(s1)
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	f36080e7          	jalr	-202(ra) # 80001d1c <proc_freepagetable>
  p->pagetable = 0;
    80001dee:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001df2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001df6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001dfa:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001dfe:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001e02:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e06:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e0a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e0e:	0004ac23          	sw	zero,24(s1)
  if(p->kstack){
    80001e12:	60ac                	ld	a1,64(s1)
    80001e14:	e185                	bnez	a1,80001e34 <freeproc+0x70>
  p->kstack = 0;
    80001e16:	0404b023          	sd	zero,64(s1)
  if(p->kpagetable){
    80001e1a:	6ca8                	ld	a0,88(s1)
    80001e1c:	c509                	beqz	a0,80001e26 <freeproc+0x62>
    proc_freekpagetable(p->kpagetable);
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	f50080e7          	jalr	-176(ra) # 80001d6e <proc_freekpagetable>
  p->kpagetable = 0;
    80001e26:	0404bc23          	sd	zero,88(s1)
}
    80001e2a:	60e2                	ld	ra,24(sp)
    80001e2c:	6442                	ld	s0,16(sp)
    80001e2e:	64a2                	ld	s1,8(sp)
    80001e30:	6105                	addi	sp,sp,32
    80001e32:	8082                	ret
    pte_t * pte = walk(p->kpagetable,p->kstack,0);
    80001e34:	4601                	li	a2,0
    80001e36:	6ca8                	ld	a0,88(s1)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	1c8080e7          	jalr	456(ra) # 80001000 <walk>
    if(pte == 0){
    80001e40:	c909                	beqz	a0,80001e52 <freeproc+0x8e>
    kfree((void *)PTE2PA(*pte));
    80001e42:	6108                	ld	a0,0(a0)
    80001e44:	8129                	srli	a0,a0,0xa
    80001e46:	0532                	slli	a0,a0,0xc
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	bdc080e7          	jalr	-1060(ra) # 80000a24 <kfree>
    80001e50:	b7d9                	j	80001e16 <freeproc+0x52>
      panic("freeproc:kstack is null");
    80001e52:	00006517          	auipc	a0,0x6
    80001e56:	43650513          	addi	a0,a0,1078 # 80008288 <digits+0x258>
    80001e5a:	ffffe097          	auipc	ra,0xffffe
    80001e5e:	6ee080e7          	jalr	1774(ra) # 80000548 <panic>

0000000080001e62 <allocproc>:
{
    80001e62:	1101                	addi	sp,sp,-32
    80001e64:	ec06                	sd	ra,24(sp)
    80001e66:	e822                	sd	s0,16(sp)
    80001e68:	e426                	sd	s1,8(sp)
    80001e6a:	e04a                	sd	s2,0(sp)
    80001e6c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e6e:	00010497          	auipc	s1,0x10
    80001e72:	efa48493          	addi	s1,s1,-262 # 80011d68 <proc>
    80001e76:	00016917          	auipc	s2,0x16
    80001e7a:	af290913          	addi	s2,s2,-1294 # 80017968 <tickslock>
    acquire(&p->lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	d90080e7          	jalr	-624(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001e88:	4c9c                	lw	a5,24(s1)
    80001e8a:	cf81                	beqz	a5,80001ea2 <allocproc+0x40>
      release(&p->lock);
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e36080e7          	jalr	-458(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e96:	17048493          	addi	s1,s1,368
    80001e9a:	ff2492e3          	bne	s1,s2,80001e7e <allocproc+0x1c>
  return 0;
    80001e9e:	4481                	li	s1,0
    80001ea0:	a051                	j	80001f24 <allocproc+0xc2>
  p->pid = allocpid();
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	d98080e7          	jalr	-616(ra) # 80001c3a <allocpid>
    80001eaa:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	c74080e7          	jalr	-908(ra) # 80000b20 <kalloc>
    80001eb4:	892a                	mv	s2,a0
    80001eb6:	f0a8                	sd	a0,96(s1)
    80001eb8:	cd2d                	beqz	a0,80001f32 <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	dc4080e7          	jalr	-572(ra) # 80001c80 <proc_pagetable>
    80001ec4:	892a                	mv	s2,a0
    80001ec6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ec8:	cd25                	beqz	a0,80001f40 <allocproc+0xde>
  p->kpagetable = proc_kvminit(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	b38080e7          	jalr	-1224(ra) # 80001a04 <proc_kvminit>
    80001ed4:	eca8                	sd	a0,88(s1)
  char *pa = kalloc();
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	c4a080e7          	jalr	-950(ra) # 80000b20 <kalloc>
    80001ede:	862a                	mv	a2,a0
  if(pa == 0)
    80001ee0:	cd25                	beqz	a0,80001f58 <allocproc+0xf6>
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ee2:	4719                	li	a4,6
    80001ee4:	6685                	lui	a3,0x1
    80001ee6:	04000937          	lui	s2,0x4000
    80001eea:	1975                	addi	s2,s2,-3
    80001eec:	00c91593          	slli	a1,s2,0xc
    80001ef0:	6ca8                	ld	a0,88(s1)
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	ae2080e7          	jalr	-1310(ra) # 800019d4 <ukvmmap>
  p->kstack = va;
    80001efa:	0932                	slli	s2,s2,0xc
    80001efc:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001f00:	07000613          	li	a2,112
    80001f04:	4581                	li	a1,0
    80001f06:	06848513          	addi	a0,s1,104
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	e02080e7          	jalr	-510(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001f12:	00000797          	auipc	a5,0x0
    80001f16:	ce278793          	addi	a5,a5,-798 # 80001bf4 <forkret>
    80001f1a:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f1c:	60bc                	ld	a5,64(s1)
    80001f1e:	6705                	lui	a4,0x1
    80001f20:	97ba                	add	a5,a5,a4
    80001f22:	f8bc                	sd	a5,112(s1)
}
    80001f24:	8526                	mv	a0,s1
    80001f26:	60e2                	ld	ra,24(sp)
    80001f28:	6442                	ld	s0,16(sp)
    80001f2a:	64a2                	ld	s1,8(sp)
    80001f2c:	6902                	ld	s2,0(sp)
    80001f2e:	6105                	addi	sp,sp,32
    80001f30:	8082                	ret
    release(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	d90080e7          	jalr	-624(ra) # 80000cc4 <release>
    return 0;
    80001f3c:	84ca                	mv	s1,s2
    80001f3e:	b7dd                	j	80001f24 <allocproc+0xc2>
    freeproc(p);
    80001f40:	8526                	mv	a0,s1
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	e82080e7          	jalr	-382(ra) # 80001dc4 <freeproc>
    release(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	d78080e7          	jalr	-648(ra) # 80000cc4 <release>
    return 0;
    80001f54:	84ca                	mv	s1,s2
    80001f56:	b7f9                	j	80001f24 <allocproc+0xc2>
    panic("kalloc");
    80001f58:	00006517          	auipc	a0,0x6
    80001f5c:	34850513          	addi	a0,a0,840 # 800082a0 <digits+0x270>
    80001f60:	ffffe097          	auipc	ra,0xffffe
    80001f64:	5e8080e7          	jalr	1512(ra) # 80000548 <panic>

0000000080001f68 <userinit>:
{
    80001f68:	1101                	addi	sp,sp,-32
    80001f6a:	ec06                	sd	ra,24(sp)
    80001f6c:	e822                	sd	s0,16(sp)
    80001f6e:	e426                	sd	s1,8(sp)
    80001f70:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	ef0080e7          	jalr	-272(ra) # 80001e62 <allocproc>
    80001f7a:	84aa                	mv	s1,a0
  initproc = p;
    80001f7c:	00007797          	auipc	a5,0x7
    80001f80:	08a7be23          	sd	a0,156(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f84:	03400613          	li	a2,52
    80001f88:	00007597          	auipc	a1,0x7
    80001f8c:	9c858593          	addi	a1,a1,-1592 # 80008950 <initcode>
    80001f90:	6928                	ld	a0,80(a0)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	446080e7          	jalr	1094(ra) # 800013d8 <uvminit>
  p->sz = PGSIZE;
    80001f9a:	6785                	lui	a5,0x1
    80001f9c:	e4bc                	sd	a5,72(s1)
  if(kvmcopy(p->pagetable,p->kpagetable,0,sizeof(initcode)) < 0){
    80001f9e:	03400693          	li	a3,52
    80001fa2:	4601                	li	a2,0
    80001fa4:	6cac                	ld	a1,88(s1)
    80001fa6:	68a8                	ld	a0,80(s1)
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	708080e7          	jalr	1800(ra) # 800016b0 <kvmcopy>
    80001fb0:	04054963          	bltz	a0,80002002 <userinit+0x9a>
  p->trapframe->epc = 0;      // user program counter
    80001fb4:	70bc                	ld	a5,96(s1)
    80001fb6:	0007bc23          	sd	zero,24(a5) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fba:	70bc                	ld	a5,96(s1)
    80001fbc:	6705                	lui	a4,0x1
    80001fbe:	fb98                	sd	a4,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fc0:	4641                	li	a2,16
    80001fc2:	00006597          	auipc	a1,0x6
    80001fc6:	30658593          	addi	a1,a1,774 # 800082c8 <digits+0x298>
    80001fca:	16048513          	addi	a0,s1,352
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	e94080e7          	jalr	-364(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001fd6:	00006517          	auipc	a0,0x6
    80001fda:	30250513          	addi	a0,a0,770 # 800082d8 <digits+0x2a8>
    80001fde:	00002097          	auipc	ra,0x2
    80001fe2:	150080e7          	jalr	336(ra) # 8000412e <namei>
    80001fe6:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001fea:	4789                	li	a5,2
    80001fec:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	cd4080e7          	jalr	-812(ra) # 80000cc4 <release>
}
    80001ff8:	60e2                	ld	ra,24(sp)
    80001ffa:	6442                	ld	s0,16(sp)
    80001ffc:	64a2                	ld	s1,8(sp)
    80001ffe:	6105                	addi	sp,sp,32
    80002000:	8082                	ret
    panic("userinit:error to kvmcopy");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	2a650513          	addi	a0,a0,678 # 800082a8 <digits+0x278>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	53e080e7          	jalr	1342(ra) # 80000548 <panic>

0000000080002012 <growproc>:
{
    80002012:	7139                	addi	sp,sp,-64
    80002014:	fc06                	sd	ra,56(sp)
    80002016:	f822                	sd	s0,48(sp)
    80002018:	f426                	sd	s1,40(sp)
    8000201a:	f04a                	sd	s2,32(sp)
    8000201c:	ec4e                	sd	s3,24(sp)
    8000201e:	e852                	sd	s4,16(sp)
    80002020:	e456                	sd	s5,8(sp)
    80002022:	0080                	addi	s0,sp,64
    80002024:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	b96080e7          	jalr	-1130(ra) # 80001bbc <myproc>
    8000202e:	84aa                	mv	s1,a0
  sz = p->sz;
    80002030:	652c                	ld	a1,72(a0)
    80002032:	0005899b          	sext.w	s3,a1
  if(n > 0){
    80002036:	03204263          	bgtz	s2,8000205a <growproc+0x48>
  } else if(n < 0){
    8000203a:	06094963          	bltz	s2,800020ac <growproc+0x9a>
  p->sz = sz;
    8000203e:	02099613          	slli	a2,s3,0x20
    80002042:	9201                	srli	a2,a2,0x20
    80002044:	e4b0                	sd	a2,72(s1)
  return 0;
    80002046:	4501                	li	a0,0
}
    80002048:	70e2                	ld	ra,56(sp)
    8000204a:	7442                	ld	s0,48(sp)
    8000204c:	74a2                	ld	s1,40(sp)
    8000204e:	7902                	ld	s2,32(sp)
    80002050:	69e2                	ld	s3,24(sp)
    80002052:	6a42                	ld	s4,16(sp)
    80002054:	6aa2                	ld	s5,8(sp)
    80002056:	6121                	addi	sp,sp,64
    80002058:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000205a:	02059a13          	slli	s4,a1,0x20
    8000205e:	020a5a13          	srli	s4,s4,0x20
    80002062:	0139063b          	addw	a2,s2,s3
    80002066:	1602                	slli	a2,a2,0x20
    80002068:	9201                	srli	a2,a2,0x20
    8000206a:	85d2                	mv	a1,s4
    8000206c:	6928                	ld	a0,80(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	424080e7          	jalr	1060(ra) # 80001492 <uvmalloc>
    80002076:	0005099b          	sext.w	s3,a0
    8000207a:	06098363          	beqz	s3,800020e0 <growproc+0xce>
    if(kvmcopy(p->pagetable,p->kpagetable,oldsz,sz) < 0){
    8000207e:	02051913          	slli	s2,a0,0x20
    80002082:	02095913          	srli	s2,s2,0x20
    80002086:	86ca                	mv	a3,s2
    80002088:	8652                	mv	a2,s4
    8000208a:	6cac                	ld	a1,88(s1)
    8000208c:	68a8                	ld	a0,80(s1)
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	622080e7          	jalr	1570(ra) # 800016b0 <kvmcopy>
    80002096:	fa0554e3          	bgez	a0,8000203e <growproc+0x2c>
      uvmdealloc(p->pagetable,sz,oldsz);
    8000209a:	8652                	mv	a2,s4
    8000209c:	85ca                	mv	a1,s2
    8000209e:	68a8                	ld	a0,80(s1)
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	3aa080e7          	jalr	938(ra) # 8000144a <uvmdealloc>
      return -1;
    800020a8:	557d                	li	a0,-1
    800020aa:	bf79                	j	80002048 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020ac:	5afd                	li	s5,-1
    800020ae:	020ada93          	srli	s5,s5,0x20
    800020b2:	0155fa33          	and	s4,a1,s5
    800020b6:	0139063b          	addw	a2,s2,s3
    800020ba:	1602                	slli	a2,a2,0x20
    800020bc:	9201                	srli	a2,a2,0x20
    800020be:	85d2                	mv	a1,s4
    800020c0:	6928                	ld	a0,80(a0)
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	388080e7          	jalr	904(ra) # 8000144a <uvmdealloc>
    800020ca:	0005099b          	sext.w	s3,a0
    kvmdealloc(p->kpagetable,oldsz,sz);
    800020ce:	01557633          	and	a2,a0,s5
    800020d2:	85d2                	mv	a1,s4
    800020d4:	6ca8                	ld	a0,88(s1)
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	6dc080e7          	jalr	1756(ra) # 800017b2 <kvmdealloc>
    800020de:	b785                	j	8000203e <growproc+0x2c>
      return -1;
    800020e0:	557d                	li	a0,-1
    800020e2:	b79d                	j	80002048 <growproc+0x36>

00000000800020e4 <fork>:
{
    800020e4:	7179                	addi	sp,sp,-48
    800020e6:	f406                	sd	ra,40(sp)
    800020e8:	f022                	sd	s0,32(sp)
    800020ea:	ec26                	sd	s1,24(sp)
    800020ec:	e84a                	sd	s2,16(sp)
    800020ee:	e44e                	sd	s3,8(sp)
    800020f0:	e052                	sd	s4,0(sp)
    800020f2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	ac8080e7          	jalr	-1336(ra) # 80001bbc <myproc>
    800020fc:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	d64080e7          	jalr	-668(ra) # 80001e62 <allocproc>
    80002106:	10050063          	beqz	a0,80002206 <fork+0x122>
    8000210a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 
    8000210c:	04893603          	ld	a2,72(s2) # 4000048 <_entry-0x7bffffb8>
    80002110:	692c                	ld	a1,80(a0)
    80002112:	05093503          	ld	a0,80(s2)
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	4c8080e7          	jalr	1224(ra) # 800015de <uvmcopy>
    8000211e:	06054563          	bltz	a0,80002188 <fork+0xa4>
  || kvmcopy(np->pagetable,np->kpagetable,0,p->sz) < 0
    80002122:	04893683          	ld	a3,72(s2)
    80002126:	4601                	li	a2,0
    80002128:	0589b583          	ld	a1,88(s3)
    8000212c:	0509b503          	ld	a0,80(s3)
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	580080e7          	jalr	1408(ra) # 800016b0 <kvmcopy>
    80002138:	04054863          	bltz	a0,80002188 <fork+0xa4>
  np->sz = p->sz;
    8000213c:	04893783          	ld	a5,72(s2)
    80002140:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80002144:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002148:	06093683          	ld	a3,96(s2)
    8000214c:	87b6                	mv	a5,a3
    8000214e:	0609b703          	ld	a4,96(s3)
    80002152:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002156:	0007b803          	ld	a6,0(a5)
    8000215a:	6788                	ld	a0,8(a5)
    8000215c:	6b8c                	ld	a1,16(a5)
    8000215e:	6f90                	ld	a2,24(a5)
    80002160:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80002164:	e708                	sd	a0,8(a4)
    80002166:	eb0c                	sd	a1,16(a4)
    80002168:	ef10                	sd	a2,24(a4)
    8000216a:	02078793          	addi	a5,a5,32
    8000216e:	02070713          	addi	a4,a4,32
    80002172:	fed792e3          	bne	a5,a3,80002156 <fork+0x72>
  np->trapframe->a0 = 0;
    80002176:	0609b783          	ld	a5,96(s3)
    8000217a:	0607b823          	sd	zero,112(a5)
    8000217e:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80002182:	15800a13          	li	s4,344
    80002186:	a03d                	j	800021b4 <fork+0xd0>
    freeproc(np);
    80002188:	854e                	mv	a0,s3
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	c3a080e7          	jalr	-966(ra) # 80001dc4 <freeproc>
    release(&np->lock);
    80002192:	854e                	mv	a0,s3
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b30080e7          	jalr	-1232(ra) # 80000cc4 <release>
    return -1;
    8000219c:	54fd                	li	s1,-1
    8000219e:	a899                	j	800021f4 <fork+0x110>
      np->ofile[i] = filedup(p->ofile[i]);
    800021a0:	00002097          	auipc	ra,0x2
    800021a4:	61a080e7          	jalr	1562(ra) # 800047ba <filedup>
    800021a8:	009987b3          	add	a5,s3,s1
    800021ac:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021ae:	04a1                	addi	s1,s1,8
    800021b0:	01448763          	beq	s1,s4,800021be <fork+0xda>
    if(p->ofile[i])
    800021b4:	009907b3          	add	a5,s2,s1
    800021b8:	6388                	ld	a0,0(a5)
    800021ba:	f17d                	bnez	a0,800021a0 <fork+0xbc>
    800021bc:	bfcd                	j	800021ae <fork+0xca>
  np->cwd = idup(p->cwd);
    800021be:	15893503          	ld	a0,344(s2)
    800021c2:	00001097          	auipc	ra,0x1
    800021c6:	77e080e7          	jalr	1918(ra) # 80003940 <idup>
    800021ca:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021ce:	4641                	li	a2,16
    800021d0:	16090593          	addi	a1,s2,352
    800021d4:	16098513          	addi	a0,s3,352
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	c8a080e7          	jalr	-886(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    800021e0:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800021e4:	4789                	li	a5,2
    800021e6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021ea:	854e                	mv	a0,s3
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	ad8080e7          	jalr	-1320(ra) # 80000cc4 <release>
}
    800021f4:	8526                	mv	a0,s1
    800021f6:	70a2                	ld	ra,40(sp)
    800021f8:	7402                	ld	s0,32(sp)
    800021fa:	64e2                	ld	s1,24(sp)
    800021fc:	6942                	ld	s2,16(sp)
    800021fe:	69a2                	ld	s3,8(sp)
    80002200:	6a02                	ld	s4,0(sp)
    80002202:	6145                	addi	sp,sp,48
    80002204:	8082                	ret
    return -1;
    80002206:	54fd                	li	s1,-1
    80002208:	b7f5                	j	800021f4 <fork+0x110>

000000008000220a <reparent>:
{
    8000220a:	7179                	addi	sp,sp,-48
    8000220c:	f406                	sd	ra,40(sp)
    8000220e:	f022                	sd	s0,32(sp)
    80002210:	ec26                	sd	s1,24(sp)
    80002212:	e84a                	sd	s2,16(sp)
    80002214:	e44e                	sd	s3,8(sp)
    80002216:	e052                	sd	s4,0(sp)
    80002218:	1800                	addi	s0,sp,48
    8000221a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221c:	00010497          	auipc	s1,0x10
    80002220:	b4c48493          	addi	s1,s1,-1204 # 80011d68 <proc>
      pp->parent = initproc;
    80002224:	00007a17          	auipc	s4,0x7
    80002228:	df4a0a13          	addi	s4,s4,-524 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222c:	00015997          	auipc	s3,0x15
    80002230:	73c98993          	addi	s3,s3,1852 # 80017968 <tickslock>
    80002234:	a029                	j	8000223e <reparent+0x34>
    80002236:	17048493          	addi	s1,s1,368
    8000223a:	03348363          	beq	s1,s3,80002260 <reparent+0x56>
    if(pp->parent == p){
    8000223e:	709c                	ld	a5,32(s1)
    80002240:	ff279be3          	bne	a5,s2,80002236 <reparent+0x2c>
      acquire(&pp->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	9ca080e7          	jalr	-1590(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    8000224e:	000a3783          	ld	a5,0(s4)
    80002252:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	a6e080e7          	jalr	-1426(ra) # 80000cc4 <release>
    8000225e:	bfe1                	j	80002236 <reparent+0x2c>
}
    80002260:	70a2                	ld	ra,40(sp)
    80002262:	7402                	ld	s0,32(sp)
    80002264:	64e2                	ld	s1,24(sp)
    80002266:	6942                	ld	s2,16(sp)
    80002268:	69a2                	ld	s3,8(sp)
    8000226a:	6a02                	ld	s4,0(sp)
    8000226c:	6145                	addi	sp,sp,48
    8000226e:	8082                	ret

0000000080002270 <scheduler>:
{
    80002270:	715d                	addi	sp,sp,-80
    80002272:	e486                	sd	ra,72(sp)
    80002274:	e0a2                	sd	s0,64(sp)
    80002276:	fc26                	sd	s1,56(sp)
    80002278:	f84a                	sd	s2,48(sp)
    8000227a:	f44e                	sd	s3,40(sp)
    8000227c:	f052                	sd	s4,32(sp)
    8000227e:	ec56                	sd	s5,24(sp)
    80002280:	e85a                	sd	s6,16(sp)
    80002282:	e45e                	sd	s7,8(sp)
    80002284:	e062                	sd	s8,0(sp)
    80002286:	0880                	addi	s0,sp,80
    80002288:	8792                	mv	a5,tp
  int id = r_tp();
    8000228a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000228c:	00779b13          	slli	s6,a5,0x7
    80002290:	0000f717          	auipc	a4,0xf
    80002294:	6c070713          	addi	a4,a4,1728 # 80011950 <pid_lock>
    80002298:	975a                	add	a4,a4,s6
    8000229a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000229e:	0000f717          	auipc	a4,0xf
    800022a2:	6d270713          	addi	a4,a4,1746 # 80011970 <cpus+0x8>
    800022a6:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    800022a8:	4c0d                	li	s8,3
        c->proc = p;
    800022aa:	079e                	slli	a5,a5,0x7
    800022ac:	0000fa17          	auipc	s4,0xf
    800022b0:	6a4a0a13          	addi	s4,s4,1700 # 80011950 <pid_lock>
    800022b4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b6:	00015997          	auipc	s3,0x15
    800022ba:	6b298993          	addi	s3,s3,1714 # 80017968 <tickslock>
        found = 1;
    800022be:	4b85                	li	s7,1
    800022c0:	a0a5                	j	80002328 <scheduler+0xb8>
        p->state = RUNNING;
    800022c2:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800022c6:	009a3c23          	sd	s1,24(s4)
        ukvminithart(p->kpagetable);
    800022ca:	6ca8                	ld	a0,88(s1)
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	804080e7          	jalr	-2044(ra) # 80001ad0 <ukvminithart>
        swtch(&c->context, &p->context);
    800022d4:	06848593          	addi	a1,s1,104
    800022d8:	855a                	mv	a0,s6
    800022da:	00000097          	auipc	ra,0x0
    800022de:	640080e7          	jalr	1600(ra) # 8000291a <swtch>
        kvminithart();
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	cfa080e7          	jalr	-774(ra) # 80000fdc <kvminithart>
        c->proc = 0;
    800022ea:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800022ee:	8ade                	mv	s5,s7
      release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9d2080e7          	jalr	-1582(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022fa:	17048493          	addi	s1,s1,368
    800022fe:	01348b63          	beq	s1,s3,80002314 <scheduler+0xa4>
      acquire(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	90c080e7          	jalr	-1780(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    8000230c:	4c9c                	lw	a5,24(s1)
    8000230e:	ff2791e3          	bne	a5,s2,800022f0 <scheduler+0x80>
    80002312:	bf45                	j	800022c2 <scheduler+0x52>
    if(found == 0) {
    80002314:	000a9a63          	bnez	s5,80002328 <scheduler+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002318:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002320:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002324:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002328:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000232c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002330:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002334:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002336:	00010497          	auipc	s1,0x10
    8000233a:	a3248493          	addi	s1,s1,-1486 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000233e:	4909                	li	s2,2
    80002340:	b7c9                	j	80002302 <scheduler+0x92>

0000000080002342 <sched>:
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	86c080e7          	jalr	-1940(ra) # 80001bbc <myproc>
    80002358:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	83c080e7          	jalr	-1988(ra) # 80000b96 <holding>
    80002362:	c93d                	beqz	a0,800023d8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002364:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	slli	a5,a5,0x7
    8000236a:	0000f717          	auipc	a4,0xf
    8000236e:	5e670713          	addi	a4,a4,1510 # 80011950 <pid_lock>
    80002372:	97ba                	add	a5,a5,a4
    80002374:	0907a703          	lw	a4,144(a5)
    80002378:	4785                	li	a5,1
    8000237a:	06f71763          	bne	a4,a5,800023e8 <sched+0xa6>
  if(p->state == RUNNING)
    8000237e:	4c98                	lw	a4,24(s1)
    80002380:	478d                	li	a5,3
    80002382:	06f70b63          	beq	a4,a5,800023f8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002386:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000238a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000238c:	efb5                	bnez	a5,80002408 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000238e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002390:	0000f917          	auipc	s2,0xf
    80002394:	5c090913          	addi	s2,s2,1472 # 80011950 <pid_lock>
    80002398:	2781                	sext.w	a5,a5
    8000239a:	079e                	slli	a5,a5,0x7
    8000239c:	97ca                	add	a5,a5,s2
    8000239e:	0947a983          	lw	s3,148(a5)
    800023a2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023a4:	2781                	sext.w	a5,a5
    800023a6:	079e                	slli	a5,a5,0x7
    800023a8:	0000f597          	auipc	a1,0xf
    800023ac:	5c858593          	addi	a1,a1,1480 # 80011970 <cpus+0x8>
    800023b0:	95be                	add	a1,a1,a5
    800023b2:	06848513          	addi	a0,s1,104
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	564080e7          	jalr	1380(ra) # 8000291a <swtch>
    800023be:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023c0:	2781                	sext.w	a5,a5
    800023c2:	079e                	slli	a5,a5,0x7
    800023c4:	97ca                	add	a5,a5,s2
    800023c6:	0937aa23          	sw	s3,148(a5)
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret
    panic("sched p->lock");
    800023d8:	00006517          	auipc	a0,0x6
    800023dc:	f0850513          	addi	a0,a0,-248 # 800082e0 <digits+0x2b0>
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	168080e7          	jalr	360(ra) # 80000548 <panic>
    panic("sched locks");
    800023e8:	00006517          	auipc	a0,0x6
    800023ec:	f0850513          	addi	a0,a0,-248 # 800082f0 <digits+0x2c0>
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	158080e7          	jalr	344(ra) # 80000548 <panic>
    panic("sched running");
    800023f8:	00006517          	auipc	a0,0x6
    800023fc:	f0850513          	addi	a0,a0,-248 # 80008300 <digits+0x2d0>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	148080e7          	jalr	328(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002408:	00006517          	auipc	a0,0x6
    8000240c:	f0850513          	addi	a0,a0,-248 # 80008310 <digits+0x2e0>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	138080e7          	jalr	312(ra) # 80000548 <panic>

0000000080002418 <exit>:
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	792080e7          	jalr	1938(ra) # 80001bbc <myproc>
    80002432:	89aa                	mv	s3,a0
  if(p == initproc)
    80002434:	00007797          	auipc	a5,0x7
    80002438:	be47b783          	ld	a5,-1052(a5) # 80009018 <initproc>
    8000243c:	0d850493          	addi	s1,a0,216
    80002440:	15850913          	addi	s2,a0,344
    80002444:	02a79363          	bne	a5,a0,8000246a <exit+0x52>
    panic("init exiting");
    80002448:	00006517          	auipc	a0,0x6
    8000244c:	ee050513          	addi	a0,a0,-288 # 80008328 <digits+0x2f8>
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	0f8080e7          	jalr	248(ra) # 80000548 <panic>
      fileclose(f);
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	3b4080e7          	jalr	948(ra) # 8000480c <fileclose>
      p->ofile[fd] = 0;
    80002460:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002464:	04a1                	addi	s1,s1,8
    80002466:	01248563          	beq	s1,s2,80002470 <exit+0x58>
    if(p->ofile[fd]){
    8000246a:	6088                	ld	a0,0(s1)
    8000246c:	f575                	bnez	a0,80002458 <exit+0x40>
    8000246e:	bfdd                	j	80002464 <exit+0x4c>
  begin_op();
    80002470:	00002097          	auipc	ra,0x2
    80002474:	eca080e7          	jalr	-310(ra) # 8000433a <begin_op>
  iput(p->cwd);
    80002478:	1589b503          	ld	a0,344(s3)
    8000247c:	00001097          	auipc	ra,0x1
    80002480:	6bc080e7          	jalr	1724(ra) # 80003b38 <iput>
  end_op();
    80002484:	00002097          	auipc	ra,0x2
    80002488:	f36080e7          	jalr	-202(ra) # 800043ba <end_op>
  p->cwd = 0;
    8000248c:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002490:	00007497          	auipc	s1,0x7
    80002494:	b8848493          	addi	s1,s1,-1144 # 80009018 <initproc>
    80002498:	6088                	ld	a0,0(s1)
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	776080e7          	jalr	1910(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    800024a2:	6088                	ld	a0,0(s1)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	648080e7          	jalr	1608(ra) # 80001aec <wakeup1>
  release(&initproc->lock);
    800024ac:	6088                	ld	a0,0(s1)
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	816080e7          	jalr	-2026(ra) # 80000cc4 <release>
  acquire(&p->lock);
    800024b6:	854e                	mv	a0,s3
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	758080e7          	jalr	1880(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    800024c0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7fe080e7          	jalr	2046(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	740080e7          	jalr	1856(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800024d8:	854e                	mv	a0,s3
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	736080e7          	jalr	1846(ra) # 80000c10 <acquire>
  reparent(p);
    800024e2:	854e                	mv	a0,s3
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	d26080e7          	jalr	-730(ra) # 8000220a <reparent>
  wakeup1(original_parent);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	5fe080e7          	jalr	1534(ra) # 80001aec <wakeup1>
  p->xstate = status;
    800024f6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800024fa:	4791                	li	a5,4
    800024fc:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	7c2080e7          	jalr	1986(ra) # 80000cc4 <release>
  sched();
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	e38080e7          	jalr	-456(ra) # 80002342 <sched>
  panic("zombie exit");
    80002512:	00006517          	auipc	a0,0x6
    80002516:	e2650513          	addi	a0,a0,-474 # 80008338 <digits+0x308>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	02e080e7          	jalr	46(ra) # 80000548 <panic>

0000000080002522 <yield>:
{
    80002522:	1101                	addi	sp,sp,-32
    80002524:	ec06                	sd	ra,24(sp)
    80002526:	e822                	sd	s0,16(sp)
    80002528:	e426                	sd	s1,8(sp)
    8000252a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	690080e7          	jalr	1680(ra) # 80001bbc <myproc>
    80002534:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	6da080e7          	jalr	1754(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    8000253e:	4789                	li	a5,2
    80002540:	cc9c                	sw	a5,24(s1)
  sched();
    80002542:	00000097          	auipc	ra,0x0
    80002546:	e00080e7          	jalr	-512(ra) # 80002342 <sched>
  release(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	778080e7          	jalr	1912(ra) # 80000cc4 <release>
}
    80002554:	60e2                	ld	ra,24(sp)
    80002556:	6442                	ld	s0,16(sp)
    80002558:	64a2                	ld	s1,8(sp)
    8000255a:	6105                	addi	sp,sp,32
    8000255c:	8082                	ret

000000008000255e <sleep>:
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	89aa                	mv	s3,a0
    8000256e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	64c080e7          	jalr	1612(ra) # 80001bbc <myproc>
    80002578:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000257a:	05250663          	beq	a0,s2,800025c6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	692080e7          	jalr	1682(ra) # 80000c10 <acquire>
    release(lk);
    80002586:	854a                	mv	a0,s2
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	73c080e7          	jalr	1852(ra) # 80000cc4 <release>
  p->chan = chan;
    80002590:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002594:	4785                	li	a5,1
    80002596:	cc9c                	sw	a5,24(s1)
  sched();
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	daa080e7          	jalr	-598(ra) # 80002342 <sched>
  p->chan = 0;
    800025a0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	71e080e7          	jalr	1822(ra) # 80000cc4 <release>
    acquire(lk);
    800025ae:	854a                	mv	a0,s2
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	660080e7          	jalr	1632(ra) # 80000c10 <acquire>
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6145                	addi	sp,sp,48
    800025c4:	8082                	ret
  p->chan = chan;
    800025c6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800025ca:	4785                	li	a5,1
    800025cc:	cd1c                	sw	a5,24(a0)
  sched();
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	d74080e7          	jalr	-652(ra) # 80002342 <sched>
  p->chan = 0;
    800025d6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800025da:	bff9                	j	800025b8 <sleep+0x5a>

00000000800025dc <wait>:
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	e062                	sd	s8,0(sp)
    800025f2:	0880                	addi	s0,sp,80
    800025f4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	5c6080e7          	jalr	1478(ra) # 80001bbc <myproc>
    800025fe:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002600:	8c2a                	mv	s8,a0
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	60e080e7          	jalr	1550(ra) # 80000c10 <acquire>
    havekids = 0;
    8000260a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000260c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000260e:	00015997          	auipc	s3,0x15
    80002612:	35a98993          	addi	s3,s3,858 # 80017968 <tickslock>
        havekids = 1;
    80002616:	4a85                	li	s5,1
    havekids = 0;
    80002618:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	74e48493          	addi	s1,s1,1870 # 80011d68 <proc>
    80002622:	a08d                	j	80002684 <wait+0xa8>
          pid = np->pid;
    80002624:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002628:	000b0e63          	beqz	s6,80002644 <wait+0x68>
    8000262c:	4691                	li	a3,4
    8000262e:	03448613          	addi	a2,s1,52
    80002632:	85da                	mv	a1,s6
    80002634:	05093503          	ld	a0,80(s2)
    80002638:	fffff097          	auipc	ra,0xfffff
    8000263c:	1f4080e7          	jalr	500(ra) # 8000182c <copyout>
    80002640:	02054263          	bltz	a0,80002664 <wait+0x88>
          freeproc(np);
    80002644:	8526                	mv	a0,s1
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	77e080e7          	jalr	1918(ra) # 80001dc4 <freeproc>
          release(&np->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	674080e7          	jalr	1652(ra) # 80000cc4 <release>
          release(&p->lock);
    80002658:	854a                	mv	a0,s2
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	66a080e7          	jalr	1642(ra) # 80000cc4 <release>
          return pid;
    80002662:	a8a9                	j	800026bc <wait+0xe0>
            release(&np->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	65e080e7          	jalr	1630(ra) # 80000cc4 <release>
            release(&p->lock);
    8000266e:	854a                	mv	a0,s2
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	654080e7          	jalr	1620(ra) # 80000cc4 <release>
            return -1;
    80002678:	59fd                	li	s3,-1
    8000267a:	a089                	j	800026bc <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000267c:	17048493          	addi	s1,s1,368
    80002680:	03348463          	beq	s1,s3,800026a8 <wait+0xcc>
      if(np->parent == p){
    80002684:	709c                	ld	a5,32(s1)
    80002686:	ff279be3          	bne	a5,s2,8000267c <wait+0xa0>
        acquire(&np->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	584080e7          	jalr	1412(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002694:	4c9c                	lw	a5,24(s1)
    80002696:	f94787e3          	beq	a5,s4,80002624 <wait+0x48>
        release(&np->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	628080e7          	jalr	1576(ra) # 80000cc4 <release>
        havekids = 1;
    800026a4:	8756                	mv	a4,s5
    800026a6:	bfd9                	j	8000267c <wait+0xa0>
    if(!havekids || p->killed){
    800026a8:	c701                	beqz	a4,800026b0 <wait+0xd4>
    800026aa:	03092783          	lw	a5,48(s2)
    800026ae:	c785                	beqz	a5,800026d6 <wait+0xfa>
      release(&p->lock);
    800026b0:	854a                	mv	a0,s2
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	612080e7          	jalr	1554(ra) # 80000cc4 <release>
      return -1;
    800026ba:	59fd                	li	s3,-1
}
    800026bc:	854e                	mv	a0,s3
    800026be:	60a6                	ld	ra,72(sp)
    800026c0:	6406                	ld	s0,64(sp)
    800026c2:	74e2                	ld	s1,56(sp)
    800026c4:	7942                	ld	s2,48(sp)
    800026c6:	79a2                	ld	s3,40(sp)
    800026c8:	7a02                	ld	s4,32(sp)
    800026ca:	6ae2                	ld	s5,24(sp)
    800026cc:	6b42                	ld	s6,16(sp)
    800026ce:	6ba2                	ld	s7,8(sp)
    800026d0:	6c02                	ld	s8,0(sp)
    800026d2:	6161                	addi	sp,sp,80
    800026d4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026d6:	85e2                	mv	a1,s8
    800026d8:	854a                	mv	a0,s2
    800026da:	00000097          	auipc	ra,0x0
    800026de:	e84080e7          	jalr	-380(ra) # 8000255e <sleep>
    havekids = 0;
    800026e2:	bf1d                	j	80002618 <wait+0x3c>

00000000800026e4 <wakeup>:
{
    800026e4:	7139                	addi	sp,sp,-64
    800026e6:	fc06                	sd	ra,56(sp)
    800026e8:	f822                	sd	s0,48(sp)
    800026ea:	f426                	sd	s1,40(sp)
    800026ec:	f04a                	sd	s2,32(sp)
    800026ee:	ec4e                	sd	s3,24(sp)
    800026f0:	e852                	sd	s4,16(sp)
    800026f2:	e456                	sd	s5,8(sp)
    800026f4:	0080                	addi	s0,sp,64
    800026f6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f8:	0000f497          	auipc	s1,0xf
    800026fc:	67048493          	addi	s1,s1,1648 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002700:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002702:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002704:	00015917          	auipc	s2,0x15
    80002708:	26490913          	addi	s2,s2,612 # 80017968 <tickslock>
    8000270c:	a821                	j	80002724 <wakeup+0x40>
      p->state = RUNNABLE;
    8000270e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	5b0080e7          	jalr	1456(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000271c:	17048493          	addi	s1,s1,368
    80002720:	01248e63          	beq	s1,s2,8000273c <wakeup+0x58>
    acquire(&p->lock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	4ea080e7          	jalr	1258(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000272e:	4c9c                	lw	a5,24(s1)
    80002730:	ff3791e3          	bne	a5,s3,80002712 <wakeup+0x2e>
    80002734:	749c                	ld	a5,40(s1)
    80002736:	fd479ee3          	bne	a5,s4,80002712 <wakeup+0x2e>
    8000273a:	bfd1                	j	8000270e <wakeup+0x2a>
}
    8000273c:	70e2                	ld	ra,56(sp)
    8000273e:	7442                	ld	s0,48(sp)
    80002740:	74a2                	ld	s1,40(sp)
    80002742:	7902                	ld	s2,32(sp)
    80002744:	69e2                	ld	s3,24(sp)
    80002746:	6a42                	ld	s4,16(sp)
    80002748:	6aa2                	ld	s5,8(sp)
    8000274a:	6121                	addi	sp,sp,64
    8000274c:	8082                	ret

000000008000274e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000274e:	7179                	addi	sp,sp,-48
    80002750:	f406                	sd	ra,40(sp)
    80002752:	f022                	sd	s0,32(sp)
    80002754:	ec26                	sd	s1,24(sp)
    80002756:	e84a                	sd	s2,16(sp)
    80002758:	e44e                	sd	s3,8(sp)
    8000275a:	1800                	addi	s0,sp,48
    8000275c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000275e:	0000f497          	auipc	s1,0xf
    80002762:	60a48493          	addi	s1,s1,1546 # 80011d68 <proc>
    80002766:	00015997          	auipc	s3,0x15
    8000276a:	20298993          	addi	s3,s3,514 # 80017968 <tickslock>
    acquire(&p->lock);
    8000276e:	8526                	mv	a0,s1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	4a0080e7          	jalr	1184(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002778:	5c9c                	lw	a5,56(s1)
    8000277a:	01278d63          	beq	a5,s2,80002794 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	544080e7          	jalr	1348(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002788:	17048493          	addi	s1,s1,368
    8000278c:	ff3491e3          	bne	s1,s3,8000276e <kill+0x20>
  }
  return -1;
    80002790:	557d                	li	a0,-1
    80002792:	a829                	j	800027ac <kill+0x5e>
      p->killed = 1;
    80002794:	4785                	li	a5,1
    80002796:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002798:	4c98                	lw	a4,24(s1)
    8000279a:	4785                	li	a5,1
    8000279c:	00f70f63          	beq	a4,a5,800027ba <kill+0x6c>
      release(&p->lock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	522080e7          	jalr	1314(ra) # 80000cc4 <release>
      return 0;
    800027aa:	4501                	li	a0,0
}
    800027ac:	70a2                	ld	ra,40(sp)
    800027ae:	7402                	ld	s0,32(sp)
    800027b0:	64e2                	ld	s1,24(sp)
    800027b2:	6942                	ld	s2,16(sp)
    800027b4:	69a2                	ld	s3,8(sp)
    800027b6:	6145                	addi	sp,sp,48
    800027b8:	8082                	ret
        p->state = RUNNABLE;
    800027ba:	4789                	li	a5,2
    800027bc:	cc9c                	sw	a5,24(s1)
    800027be:	b7cd                	j	800027a0 <kill+0x52>

00000000800027c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c0:	7179                	addi	sp,sp,-48
    800027c2:	f406                	sd	ra,40(sp)
    800027c4:	f022                	sd	s0,32(sp)
    800027c6:	ec26                	sd	s1,24(sp)
    800027c8:	e84a                	sd	s2,16(sp)
    800027ca:	e44e                	sd	s3,8(sp)
    800027cc:	e052                	sd	s4,0(sp)
    800027ce:	1800                	addi	s0,sp,48
    800027d0:	84aa                	mv	s1,a0
    800027d2:	892e                	mv	s2,a1
    800027d4:	89b2                	mv	s3,a2
    800027d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	3e4080e7          	jalr	996(ra) # 80001bbc <myproc>
  if(user_dst){
    800027e0:	c08d                	beqz	s1,80002802 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027e2:	86d2                	mv	a3,s4
    800027e4:	864e                	mv	a2,s3
    800027e6:	85ca                	mv	a1,s2
    800027e8:	6928                	ld	a0,80(a0)
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	042080e7          	jalr	66(ra) # 8000182c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027f2:	70a2                	ld	ra,40(sp)
    800027f4:	7402                	ld	s0,32(sp)
    800027f6:	64e2                	ld	s1,24(sp)
    800027f8:	6942                	ld	s2,16(sp)
    800027fa:	69a2                	ld	s3,8(sp)
    800027fc:	6a02                	ld	s4,0(sp)
    800027fe:	6145                	addi	sp,sp,48
    80002800:	8082                	ret
    memmove((char *)dst, src, len);
    80002802:	000a061b          	sext.w	a2,s4
    80002806:	85ce                	mv	a1,s3
    80002808:	854a                	mv	a0,s2
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	562080e7          	jalr	1378(ra) # 80000d6c <memmove>
    return 0;
    80002812:	8526                	mv	a0,s1
    80002814:	bff9                	j	800027f2 <either_copyout+0x32>

0000000080002816 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002816:	7179                	addi	sp,sp,-48
    80002818:	f406                	sd	ra,40(sp)
    8000281a:	f022                	sd	s0,32(sp)
    8000281c:	ec26                	sd	s1,24(sp)
    8000281e:	e84a                	sd	s2,16(sp)
    80002820:	e44e                	sd	s3,8(sp)
    80002822:	e052                	sd	s4,0(sp)
    80002824:	1800                	addi	s0,sp,48
    80002826:	892a                	mv	s2,a0
    80002828:	84ae                	mv	s1,a1
    8000282a:	89b2                	mv	s3,a2
    8000282c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	38e080e7          	jalr	910(ra) # 80001bbc <myproc>
  if(user_src){
    80002836:	c08d                	beqz	s1,80002858 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002838:	86d2                	mv	a3,s4
    8000283a:	864e                	mv	a2,s3
    8000283c:	85ca                	mv	a1,s2
    8000283e:	6928                	ld	a0,80(a0)
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	078080e7          	jalr	120(ra) # 800018b8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002848:	70a2                	ld	ra,40(sp)
    8000284a:	7402                	ld	s0,32(sp)
    8000284c:	64e2                	ld	s1,24(sp)
    8000284e:	6942                	ld	s2,16(sp)
    80002850:	69a2                	ld	s3,8(sp)
    80002852:	6a02                	ld	s4,0(sp)
    80002854:	6145                	addi	sp,sp,48
    80002856:	8082                	ret
    memmove(dst, (char*)src, len);
    80002858:	000a061b          	sext.w	a2,s4
    8000285c:	85ce                	mv	a1,s3
    8000285e:	854a                	mv	a0,s2
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	50c080e7          	jalr	1292(ra) # 80000d6c <memmove>
    return 0;
    80002868:	8526                	mv	a0,s1
    8000286a:	bff9                	j	80002848 <either_copyin+0x32>

000000008000286c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000286c:	715d                	addi	sp,sp,-80
    8000286e:	e486                	sd	ra,72(sp)
    80002870:	e0a2                	sd	s0,64(sp)
    80002872:	fc26                	sd	s1,56(sp)
    80002874:	f84a                	sd	s2,48(sp)
    80002876:	f44e                	sd	s3,40(sp)
    80002878:	f052                	sd	s4,32(sp)
    8000287a:	ec56                	sd	s5,24(sp)
    8000287c:	e85a                	sd	s6,16(sp)
    8000287e:	e45e                	sd	s7,8(sp)
    80002880:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002882:	00006517          	auipc	a0,0x6
    80002886:	83650513          	addi	a0,a0,-1994 # 800080b8 <digits+0x88>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	d08080e7          	jalr	-760(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002892:	0000f497          	auipc	s1,0xf
    80002896:	63648493          	addi	s1,s1,1590 # 80011ec8 <proc+0x160>
    8000289a:	00015917          	auipc	s2,0x15
    8000289e:	22e90913          	addi	s2,s2,558 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800028a4:	00006997          	auipc	s3,0x6
    800028a8:	aa498993          	addi	s3,s3,-1372 # 80008348 <digits+0x318>
    printf("%d %s %s", p->pid, state, p->name);
    800028ac:	00006a97          	auipc	s5,0x6
    800028b0:	aa4a8a93          	addi	s5,s5,-1372 # 80008350 <digits+0x320>
    printf("\n");
    800028b4:	00006a17          	auipc	s4,0x6
    800028b8:	804a0a13          	addi	s4,s4,-2044 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028bc:	00006b97          	auipc	s7,0x6
    800028c0:	accb8b93          	addi	s7,s7,-1332 # 80008388 <states.1761>
    800028c4:	a00d                	j	800028e6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028c6:	ed86a583          	lw	a1,-296(a3)
    800028ca:	8556                	mv	a0,s5
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	cc6080e7          	jalr	-826(ra) # 80000592 <printf>
    printf("\n");
    800028d4:	8552                	mv	a0,s4
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	cbc080e7          	jalr	-836(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028de:	17048493          	addi	s1,s1,368
    800028e2:	03248163          	beq	s1,s2,80002904 <procdump+0x98>
    if(p->state == UNUSED)
    800028e6:	86a6                	mv	a3,s1
    800028e8:	eb84a783          	lw	a5,-328(s1)
    800028ec:	dbed                	beqz	a5,800028de <procdump+0x72>
      state = "???";
    800028ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f0:	fcfb6be3          	bltu	s6,a5,800028c6 <procdump+0x5a>
    800028f4:	1782                	slli	a5,a5,0x20
    800028f6:	9381                	srli	a5,a5,0x20
    800028f8:	078e                	slli	a5,a5,0x3
    800028fa:	97de                	add	a5,a5,s7
    800028fc:	6390                	ld	a2,0(a5)
    800028fe:	f661                	bnez	a2,800028c6 <procdump+0x5a>
      state = "???";
    80002900:	864e                	mv	a2,s3
    80002902:	b7d1                	j	800028c6 <procdump+0x5a>
  }
}
    80002904:	60a6                	ld	ra,72(sp)
    80002906:	6406                	ld	s0,64(sp)
    80002908:	74e2                	ld	s1,56(sp)
    8000290a:	7942                	ld	s2,48(sp)
    8000290c:	79a2                	ld	s3,40(sp)
    8000290e:	7a02                	ld	s4,32(sp)
    80002910:	6ae2                	ld	s5,24(sp)
    80002912:	6b42                	ld	s6,16(sp)
    80002914:	6ba2                	ld	s7,8(sp)
    80002916:	6161                	addi	sp,sp,80
    80002918:	8082                	ret

000000008000291a <swtch>:
    8000291a:	00153023          	sd	ra,0(a0)
    8000291e:	00253423          	sd	sp,8(a0)
    80002922:	e900                	sd	s0,16(a0)
    80002924:	ed04                	sd	s1,24(a0)
    80002926:	03253023          	sd	s2,32(a0)
    8000292a:	03353423          	sd	s3,40(a0)
    8000292e:	03453823          	sd	s4,48(a0)
    80002932:	03553c23          	sd	s5,56(a0)
    80002936:	05653023          	sd	s6,64(a0)
    8000293a:	05753423          	sd	s7,72(a0)
    8000293e:	05853823          	sd	s8,80(a0)
    80002942:	05953c23          	sd	s9,88(a0)
    80002946:	07a53023          	sd	s10,96(a0)
    8000294a:	07b53423          	sd	s11,104(a0)
    8000294e:	0005b083          	ld	ra,0(a1)
    80002952:	0085b103          	ld	sp,8(a1)
    80002956:	6980                	ld	s0,16(a1)
    80002958:	6d84                	ld	s1,24(a1)
    8000295a:	0205b903          	ld	s2,32(a1)
    8000295e:	0285b983          	ld	s3,40(a1)
    80002962:	0305ba03          	ld	s4,48(a1)
    80002966:	0385ba83          	ld	s5,56(a1)
    8000296a:	0405bb03          	ld	s6,64(a1)
    8000296e:	0485bb83          	ld	s7,72(a1)
    80002972:	0505bc03          	ld	s8,80(a1)
    80002976:	0585bc83          	ld	s9,88(a1)
    8000297a:	0605bd03          	ld	s10,96(a1)
    8000297e:	0685bd83          	ld	s11,104(a1)
    80002982:	8082                	ret

0000000080002984 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002984:	1141                	addi	sp,sp,-16
    80002986:	e406                	sd	ra,8(sp)
    80002988:	e022                	sd	s0,0(sp)
    8000298a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000298c:	00006597          	auipc	a1,0x6
    80002990:	a2458593          	addi	a1,a1,-1500 # 800083b0 <states.1761+0x28>
    80002994:	00015517          	auipc	a0,0x15
    80002998:	fd450513          	addi	a0,a0,-44 # 80017968 <tickslock>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	1e4080e7          	jalr	484(ra) # 80000b80 <initlock>
}
    800029a4:	60a2                	ld	ra,8(sp)
    800029a6:	6402                	ld	s0,0(sp)
    800029a8:	0141                	addi	sp,sp,16
    800029aa:	8082                	ret

00000000800029ac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029ac:	1141                	addi	sp,sp,-16
    800029ae:	e422                	sd	s0,8(sp)
    800029b0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b2:	00003797          	auipc	a5,0x3
    800029b6:	52e78793          	addi	a5,a5,1326 # 80005ee0 <kernelvec>
    800029ba:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029be:	6422                	ld	s0,8(sp)
    800029c0:	0141                	addi	sp,sp,16
    800029c2:	8082                	ret

00000000800029c4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029c4:	1141                	addi	sp,sp,-16
    800029c6:	e406                	sd	ra,8(sp)
    800029c8:	e022                	sd	s0,0(sp)
    800029ca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	1f0080e7          	jalr	496(ra) # 80001bbc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029da:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029de:	00004617          	auipc	a2,0x4
    800029e2:	62260613          	addi	a2,a2,1570 # 80007000 <_trampoline>
    800029e6:	00004697          	auipc	a3,0x4
    800029ea:	61a68693          	addi	a3,a3,1562 # 80007000 <_trampoline>
    800029ee:	8e91                	sub	a3,a3,a2
    800029f0:	040007b7          	lui	a5,0x4000
    800029f4:	17fd                	addi	a5,a5,-1
    800029f6:	07b2                	slli	a5,a5,0xc
    800029f8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fa:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029fe:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a00:	180026f3          	csrr	a3,satp
    80002a04:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a06:	7138                	ld	a4,96(a0)
    80002a08:	6134                	ld	a3,64(a0)
    80002a0a:	6585                	lui	a1,0x1
    80002a0c:	96ae                	add	a3,a3,a1
    80002a0e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a10:	7138                	ld	a4,96(a0)
    80002a12:	00000697          	auipc	a3,0x0
    80002a16:	13868693          	addi	a3,a3,312 # 80002b4a <usertrap>
    80002a1a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a1c:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a1e:	8692                	mv	a3,tp
    80002a20:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a26:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a2a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a32:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a34:	6f18                	ld	a4,24(a4)
    80002a36:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a3a:	692c                	ld	a1,80(a0)
    80002a3c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a3e:	00004717          	auipc	a4,0x4
    80002a42:	65270713          	addi	a4,a4,1618 # 80007090 <userret>
    80002a46:	8f11                	sub	a4,a4,a2
    80002a48:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a4a:	577d                	li	a4,-1
    80002a4c:	177e                	slli	a4,a4,0x3f
    80002a4e:	8dd9                	or	a1,a1,a4
    80002a50:	02000537          	lui	a0,0x2000
    80002a54:	157d                	addi	a0,a0,-1
    80002a56:	0536                	slli	a0,a0,0xd
    80002a58:	9782                	jalr	a5
}
    80002a5a:	60a2                	ld	ra,8(sp)
    80002a5c:	6402                	ld	s0,0(sp)
    80002a5e:	0141                	addi	sp,sp,16
    80002a60:	8082                	ret

0000000080002a62 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a62:	1101                	addi	sp,sp,-32
    80002a64:	ec06                	sd	ra,24(sp)
    80002a66:	e822                	sd	s0,16(sp)
    80002a68:	e426                	sd	s1,8(sp)
    80002a6a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a6c:	00015497          	auipc	s1,0x15
    80002a70:	efc48493          	addi	s1,s1,-260 # 80017968 <tickslock>
    80002a74:	8526                	mv	a0,s1
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	19a080e7          	jalr	410(ra) # 80000c10 <acquire>
  ticks++;
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	5a250513          	addi	a0,a0,1442 # 80009020 <ticks>
    80002a86:	411c                	lw	a5,0(a0)
    80002a88:	2785                	addiw	a5,a5,1
    80002a8a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	c58080e7          	jalr	-936(ra) # 800026e4 <wakeup>
  release(&tickslock);
    80002a94:	8526                	mv	a0,s1
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	22e080e7          	jalr	558(ra) # 80000cc4 <release>
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret

0000000080002aa8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002aa8:	1101                	addi	sp,sp,-32
    80002aaa:	ec06                	sd	ra,24(sp)
    80002aac:	e822                	sd	s0,16(sp)
    80002aae:	e426                	sd	s1,8(sp)
    80002ab0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ab6:	00074d63          	bltz	a4,80002ad0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aba:	57fd                	li	a5,-1
    80002abc:	17fe                	slli	a5,a5,0x3f
    80002abe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ac0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ac2:	06f70363          	beq	a4,a5,80002b28 <devintr+0x80>
  }
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret
     (scause & 0xff) == 9){
    80002ad0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ad4:	46a5                	li	a3,9
    80002ad6:	fed792e3          	bne	a5,a3,80002aba <devintr+0x12>
    int irq = plic_claim();
    80002ada:	00003097          	auipc	ra,0x3
    80002ade:	50e080e7          	jalr	1294(ra) # 80005fe8 <plic_claim>
    80002ae2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ae4:	47a9                	li	a5,10
    80002ae6:	02f50763          	beq	a0,a5,80002b14 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aea:	4785                	li	a5,1
    80002aec:	02f50963          	beq	a0,a5,80002b1e <devintr+0x76>
    return 1;
    80002af0:	4505                	li	a0,1
    } else if(irq){
    80002af2:	d8f1                	beqz	s1,80002ac6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002af4:	85a6                	mv	a1,s1
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	8c250513          	addi	a0,a0,-1854 # 800083b8 <states.1761+0x30>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a94080e7          	jalr	-1388(ra) # 80000592 <printf>
      plic_complete(irq);
    80002b06:	8526                	mv	a0,s1
    80002b08:	00003097          	auipc	ra,0x3
    80002b0c:	504080e7          	jalr	1284(ra) # 8000600c <plic_complete>
    return 1;
    80002b10:	4505                	li	a0,1
    80002b12:	bf55                	j	80002ac6 <devintr+0x1e>
      uartintr();
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	ec0080e7          	jalr	-320(ra) # 800009d4 <uartintr>
    80002b1c:	b7ed                	j	80002b06 <devintr+0x5e>
      virtio_disk_intr();
    80002b1e:	00004097          	auipc	ra,0x4
    80002b22:	988080e7          	jalr	-1656(ra) # 800064a6 <virtio_disk_intr>
    80002b26:	b7c5                	j	80002b06 <devintr+0x5e>
    if(cpuid() == 0){
    80002b28:	fffff097          	auipc	ra,0xfffff
    80002b2c:	068080e7          	jalr	104(ra) # 80001b90 <cpuid>
    80002b30:	c901                	beqz	a0,80002b40 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b32:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b36:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b38:	14479073          	csrw	sip,a5
    return 2;
    80002b3c:	4509                	li	a0,2
    80002b3e:	b761                	j	80002ac6 <devintr+0x1e>
      clockintr();
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	f22080e7          	jalr	-222(ra) # 80002a62 <clockintr>
    80002b48:	b7ed                	j	80002b32 <devintr+0x8a>

0000000080002b4a <usertrap>:
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	e04a                	sd	s2,0(sp)
    80002b54:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b56:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b5a:	1007f793          	andi	a5,a5,256
    80002b5e:	e3ad                	bnez	a5,80002bc0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b60:	00003797          	auipc	a5,0x3
    80002b64:	38078793          	addi	a5,a5,896 # 80005ee0 <kernelvec>
    80002b68:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	050080e7          	jalr	80(ra) # 80001bbc <myproc>
    80002b74:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b76:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b78:	14102773          	csrr	a4,sepc
    80002b7c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b7e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b82:	47a1                	li	a5,8
    80002b84:	04f71c63          	bne	a4,a5,80002bdc <usertrap+0x92>
    if(p->killed)
    80002b88:	591c                	lw	a5,48(a0)
    80002b8a:	e3b9                	bnez	a5,80002bd0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b8c:	70b8                	ld	a4,96(s1)
    80002b8e:	6f1c                	ld	a5,24(a4)
    80002b90:	0791                	addi	a5,a5,4
    80002b92:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b9c:	10079073          	csrw	sstatus,a5
    syscall();
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	2e0080e7          	jalr	736(ra) # 80002e80 <syscall>
  if(p->killed)
    80002ba8:	589c                	lw	a5,48(s1)
    80002baa:	ebc1                	bnez	a5,80002c3a <usertrap+0xf0>
  usertrapret();
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	e18080e7          	jalr	-488(ra) # 800029c4 <usertrapret>
}
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6902                	ld	s2,0(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret
    panic("usertrap: not from user mode");
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	81850513          	addi	a0,a0,-2024 # 800083d8 <states.1761+0x50>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	980080e7          	jalr	-1664(ra) # 80000548 <panic>
      exit(-1);
    80002bd0:	557d                	li	a0,-1
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	846080e7          	jalr	-1978(ra) # 80002418 <exit>
    80002bda:	bf4d                	j	80002b8c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	ecc080e7          	jalr	-308(ra) # 80002aa8 <devintr>
    80002be4:	892a                	mv	s2,a0
    80002be6:	c501                	beqz	a0,80002bee <usertrap+0xa4>
  if(p->killed)
    80002be8:	589c                	lw	a5,48(s1)
    80002bea:	c3a1                	beqz	a5,80002c2a <usertrap+0xe0>
    80002bec:	a815                	j	80002c20 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bf2:	5c90                	lw	a2,56(s1)
    80002bf4:	00006517          	auipc	a0,0x6
    80002bf8:	80450513          	addi	a0,a0,-2044 # 800083f8 <states.1761+0x70>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	996080e7          	jalr	-1642(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c08:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	81c50513          	addi	a0,a0,-2020 # 80008428 <states.1761+0xa0>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	97e080e7          	jalr	-1666(ra) # 80000592 <printf>
    p->killed = 1;
    80002c1c:	4785                	li	a5,1
    80002c1e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c20:	557d                	li	a0,-1
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	7f6080e7          	jalr	2038(ra) # 80002418 <exit>
  if(which_dev == 2)
    80002c2a:	4789                	li	a5,2
    80002c2c:	f8f910e3          	bne	s2,a5,80002bac <usertrap+0x62>
    yield();
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	8f2080e7          	jalr	-1806(ra) # 80002522 <yield>
    80002c38:	bf95                	j	80002bac <usertrap+0x62>
  int which_dev = 0;
    80002c3a:	4901                	li	s2,0
    80002c3c:	b7d5                	j	80002c20 <usertrap+0xd6>

0000000080002c3e <kerneltrap>:
{
    80002c3e:	7179                	addi	sp,sp,-48
    80002c40:	f406                	sd	ra,40(sp)
    80002c42:	f022                	sd	s0,32(sp)
    80002c44:	ec26                	sd	s1,24(sp)
    80002c46:	e84a                	sd	s2,16(sp)
    80002c48:	e44e                	sd	s3,8(sp)
    80002c4a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c50:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c54:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c58:	1004f793          	andi	a5,s1,256
    80002c5c:	cb85                	beqz	a5,80002c8c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c62:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c64:	ef85                	bnez	a5,80002c9c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	e42080e7          	jalr	-446(ra) # 80002aa8 <devintr>
    80002c6e:	cd1d                	beqz	a0,80002cac <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c70:	4789                	li	a5,2
    80002c72:	06f50a63          	beq	a0,a5,80002ce6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c76:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7a:	10049073          	csrw	sstatus,s1
}
    80002c7e:	70a2                	ld	ra,40(sp)
    80002c80:	7402                	ld	s0,32(sp)
    80002c82:	64e2                	ld	s1,24(sp)
    80002c84:	6942                	ld	s2,16(sp)
    80002c86:	69a2                	ld	s3,8(sp)
    80002c88:	6145                	addi	sp,sp,48
    80002c8a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	7bc50513          	addi	a0,a0,1980 # 80008448 <states.1761+0xc0>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8b4080e7          	jalr	-1868(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	7d450513          	addi	a0,a0,2004 # 80008470 <states.1761+0xe8>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	8a4080e7          	jalr	-1884(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002cac:	85ce                	mv	a1,s3
    80002cae:	00005517          	auipc	a0,0x5
    80002cb2:	7e250513          	addi	a0,a0,2018 # 80008490 <states.1761+0x108>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	8dc080e7          	jalr	-1828(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cbe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cc2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	7da50513          	addi	a0,a0,2010 # 800084a0 <states.1761+0x118>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8c4080e7          	jalr	-1852(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	7e250513          	addi	a0,a0,2018 # 800084b8 <states.1761+0x130>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	86a080e7          	jalr	-1942(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	ed6080e7          	jalr	-298(ra) # 80001bbc <myproc>
    80002cee:	d541                	beqz	a0,80002c76 <kerneltrap+0x38>
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	ecc080e7          	jalr	-308(ra) # 80001bbc <myproc>
    80002cf8:	4d18                	lw	a4,24(a0)
    80002cfa:	478d                	li	a5,3
    80002cfc:	f6f71de3          	bne	a4,a5,80002c76 <kerneltrap+0x38>
    yield();
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	822080e7          	jalr	-2014(ra) # 80002522 <yield>
    80002d08:	b7bd                	j	80002c76 <kerneltrap+0x38>

0000000080002d0a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	e426                	sd	s1,8(sp)
    80002d12:	1000                	addi	s0,sp,32
    80002d14:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	ea6080e7          	jalr	-346(ra) # 80001bbc <myproc>
  switch (n) {
    80002d1e:	4795                	li	a5,5
    80002d20:	0497e163          	bltu	a5,s1,80002d62 <argraw+0x58>
    80002d24:	048a                	slli	s1,s1,0x2
    80002d26:	00005717          	auipc	a4,0x5
    80002d2a:	7ca70713          	addi	a4,a4,1994 # 800084f0 <states.1761+0x168>
    80002d2e:	94ba                	add	s1,s1,a4
    80002d30:	409c                	lw	a5,0(s1)
    80002d32:	97ba                	add	a5,a5,a4
    80002d34:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d36:	713c                	ld	a5,96(a0)
    80002d38:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret
    return p->trapframe->a1;
    80002d44:	713c                	ld	a5,96(a0)
    80002d46:	7fa8                	ld	a0,120(a5)
    80002d48:	bfcd                	j	80002d3a <argraw+0x30>
    return p->trapframe->a2;
    80002d4a:	713c                	ld	a5,96(a0)
    80002d4c:	63c8                	ld	a0,128(a5)
    80002d4e:	b7f5                	j	80002d3a <argraw+0x30>
    return p->trapframe->a3;
    80002d50:	713c                	ld	a5,96(a0)
    80002d52:	67c8                	ld	a0,136(a5)
    80002d54:	b7dd                	j	80002d3a <argraw+0x30>
    return p->trapframe->a4;
    80002d56:	713c                	ld	a5,96(a0)
    80002d58:	6bc8                	ld	a0,144(a5)
    80002d5a:	b7c5                	j	80002d3a <argraw+0x30>
    return p->trapframe->a5;
    80002d5c:	713c                	ld	a5,96(a0)
    80002d5e:	6fc8                	ld	a0,152(a5)
    80002d60:	bfe9                	j	80002d3a <argraw+0x30>
  panic("argraw");
    80002d62:	00005517          	auipc	a0,0x5
    80002d66:	76650513          	addi	a0,a0,1894 # 800084c8 <states.1761+0x140>
    80002d6a:	ffffd097          	auipc	ra,0xffffd
    80002d6e:	7de080e7          	jalr	2014(ra) # 80000548 <panic>

0000000080002d72 <fetchaddr>:
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	e04a                	sd	s2,0(sp)
    80002d7c:	1000                	addi	s0,sp,32
    80002d7e:	84aa                	mv	s1,a0
    80002d80:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	e3a080e7          	jalr	-454(ra) # 80001bbc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d8a:	653c                	ld	a5,72(a0)
    80002d8c:	02f4f863          	bgeu	s1,a5,80002dbc <fetchaddr+0x4a>
    80002d90:	00848713          	addi	a4,s1,8
    80002d94:	02e7e663          	bltu	a5,a4,80002dc0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d98:	46a1                	li	a3,8
    80002d9a:	8626                	mv	a2,s1
    80002d9c:	85ca                	mv	a1,s2
    80002d9e:	6928                	ld	a0,80(a0)
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	b18080e7          	jalr	-1256(ra) # 800018b8 <copyin>
    80002da8:	00a03533          	snez	a0,a0
    80002dac:	40a00533          	neg	a0,a0
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6902                	ld	s2,0(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret
    return -1;
    80002dbc:	557d                	li	a0,-1
    80002dbe:	bfcd                	j	80002db0 <fetchaddr+0x3e>
    80002dc0:	557d                	li	a0,-1
    80002dc2:	b7fd                	j	80002db0 <fetchaddr+0x3e>

0000000080002dc4 <fetchstr>:
{
    80002dc4:	7179                	addi	sp,sp,-48
    80002dc6:	f406                	sd	ra,40(sp)
    80002dc8:	f022                	sd	s0,32(sp)
    80002dca:	ec26                	sd	s1,24(sp)
    80002dcc:	e84a                	sd	s2,16(sp)
    80002dce:	e44e                	sd	s3,8(sp)
    80002dd0:	1800                	addi	s0,sp,48
    80002dd2:	892a                	mv	s2,a0
    80002dd4:	84ae                	mv	s1,a1
    80002dd6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	de4080e7          	jalr	-540(ra) # 80001bbc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002de0:	86ce                	mv	a3,s3
    80002de2:	864a                	mv	a2,s2
    80002de4:	85a6                	mv	a1,s1
    80002de6:	6928                	ld	a0,80(a0)
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	ae8080e7          	jalr	-1304(ra) # 800018d0 <copyinstr>
  if(err < 0)
    80002df0:	00054763          	bltz	a0,80002dfe <fetchstr+0x3a>
  return strlen(buf);
    80002df4:	8526                	mv	a0,s1
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	09e080e7          	jalr	158(ra) # 80000e94 <strlen>
}
    80002dfe:	70a2                	ld	ra,40(sp)
    80002e00:	7402                	ld	s0,32(sp)
    80002e02:	64e2                	ld	s1,24(sp)
    80002e04:	6942                	ld	s2,16(sp)
    80002e06:	69a2                	ld	s3,8(sp)
    80002e08:	6145                	addi	sp,sp,48
    80002e0a:	8082                	ret

0000000080002e0c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	1000                	addi	s0,sp,32
    80002e16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	ef2080e7          	jalr	-270(ra) # 80002d0a <argraw>
    80002e20:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e22:	4501                	li	a0,0
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	1000                	addi	s0,sp,32
    80002e38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	ed0080e7          	jalr	-304(ra) # 80002d0a <argraw>
    80002e42:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e44:	4501                	li	a0,0
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	64a2                	ld	s1,8(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret

0000000080002e50 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e50:	1101                	addi	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	e426                	sd	s1,8(sp)
    80002e58:	e04a                	sd	s2,0(sp)
    80002e5a:	1000                	addi	s0,sp,32
    80002e5c:	84ae                	mv	s1,a1
    80002e5e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	eaa080e7          	jalr	-342(ra) # 80002d0a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e68:	864a                	mv	a2,s2
    80002e6a:	85a6                	mv	a1,s1
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	f58080e7          	jalr	-168(ra) # 80002dc4 <fetchstr>
}
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	64a2                	ld	s1,8(sp)
    80002e7a:	6902                	ld	s2,0(sp)
    80002e7c:	6105                	addi	sp,sp,32
    80002e7e:	8082                	ret

0000000080002e80 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e80:	1101                	addi	sp,sp,-32
    80002e82:	ec06                	sd	ra,24(sp)
    80002e84:	e822                	sd	s0,16(sp)
    80002e86:	e426                	sd	s1,8(sp)
    80002e88:	e04a                	sd	s2,0(sp)
    80002e8a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	d30080e7          	jalr	-720(ra) # 80001bbc <myproc>
    80002e94:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e96:	06053903          	ld	s2,96(a0)
    80002e9a:	0a893783          	ld	a5,168(s2)
    80002e9e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ea2:	37fd                	addiw	a5,a5,-1
    80002ea4:	4751                	li	a4,20
    80002ea6:	00f76f63          	bltu	a4,a5,80002ec4 <syscall+0x44>
    80002eaa:	00369713          	slli	a4,a3,0x3
    80002eae:	00005797          	auipc	a5,0x5
    80002eb2:	65a78793          	addi	a5,a5,1626 # 80008508 <syscalls>
    80002eb6:	97ba                	add	a5,a5,a4
    80002eb8:	639c                	ld	a5,0(a5)
    80002eba:	c789                	beqz	a5,80002ec4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ebc:	9782                	jalr	a5
    80002ebe:	06a93823          	sd	a0,112(s2)
    80002ec2:	a839                	j	80002ee0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ec4:	16048613          	addi	a2,s1,352
    80002ec8:	5c8c                	lw	a1,56(s1)
    80002eca:	00005517          	auipc	a0,0x5
    80002ece:	60650513          	addi	a0,a0,1542 # 800084d0 <states.1761+0x148>
    80002ed2:	ffffd097          	auipc	ra,0xffffd
    80002ed6:	6c0080e7          	jalr	1728(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eda:	70bc                	ld	a5,96(s1)
    80002edc:	577d                	li	a4,-1
    80002ede:	fbb8                	sd	a4,112(a5)
  }
}
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6902                	ld	s2,0(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret

0000000080002eec <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eec:	1101                	addi	sp,sp,-32
    80002eee:	ec06                	sd	ra,24(sp)
    80002ef0:	e822                	sd	s0,16(sp)
    80002ef2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ef4:	fec40593          	addi	a1,s0,-20
    80002ef8:	4501                	li	a0,0
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	f12080e7          	jalr	-238(ra) # 80002e0c <argint>
    return -1;
    80002f02:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f04:	00054963          	bltz	a0,80002f16 <sys_exit+0x2a>
  exit(n);
    80002f08:	fec42503          	lw	a0,-20(s0)
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	50c080e7          	jalr	1292(ra) # 80002418 <exit>
  return 0;  // not reached
    80002f14:	4781                	li	a5,0
}
    80002f16:	853e                	mv	a0,a5
    80002f18:	60e2                	ld	ra,24(sp)
    80002f1a:	6442                	ld	s0,16(sp)
    80002f1c:	6105                	addi	sp,sp,32
    80002f1e:	8082                	ret

0000000080002f20 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f20:	1141                	addi	sp,sp,-16
    80002f22:	e406                	sd	ra,8(sp)
    80002f24:	e022                	sd	s0,0(sp)
    80002f26:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	c94080e7          	jalr	-876(ra) # 80001bbc <myproc>
}
    80002f30:	5d08                	lw	a0,56(a0)
    80002f32:	60a2                	ld	ra,8(sp)
    80002f34:	6402                	ld	s0,0(sp)
    80002f36:	0141                	addi	sp,sp,16
    80002f38:	8082                	ret

0000000080002f3a <sys_fork>:

uint64
sys_fork(void)
{
    80002f3a:	1141                	addi	sp,sp,-16
    80002f3c:	e406                	sd	ra,8(sp)
    80002f3e:	e022                	sd	s0,0(sp)
    80002f40:	0800                	addi	s0,sp,16
  return fork();
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	1a2080e7          	jalr	418(ra) # 800020e4 <fork>
}
    80002f4a:	60a2                	ld	ra,8(sp)
    80002f4c:	6402                	ld	s0,0(sp)
    80002f4e:	0141                	addi	sp,sp,16
    80002f50:	8082                	ret

0000000080002f52 <sys_wait>:

uint64
sys_wait(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f5a:	fe840593          	addi	a1,s0,-24
    80002f5e:	4501                	li	a0,0
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	ece080e7          	jalr	-306(ra) # 80002e2e <argaddr>
    80002f68:	87aa                	mv	a5,a0
    return -1;
    80002f6a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f6c:	0007c863          	bltz	a5,80002f7c <sys_wait+0x2a>
  return wait(p);
    80002f70:	fe843503          	ld	a0,-24(s0)
    80002f74:	fffff097          	auipc	ra,0xfffff
    80002f78:	668080e7          	jalr	1640(ra) # 800025dc <wait>
}
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	6105                	addi	sp,sp,32
    80002f82:	8082                	ret

0000000080002f84 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f84:	7179                	addi	sp,sp,-48
    80002f86:	f406                	sd	ra,40(sp)
    80002f88:	f022                	sd	s0,32(sp)
    80002f8a:	ec26                	sd	s1,24(sp)
    80002f8c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f8e:	fdc40593          	addi	a1,s0,-36
    80002f92:	4501                	li	a0,0
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	e78080e7          	jalr	-392(ra) # 80002e0c <argint>
    80002f9c:	87aa                	mv	a5,a0
    return -1;
    80002f9e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fa0:	0207c063          	bltz	a5,80002fc0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	c18080e7          	jalr	-1000(ra) # 80001bbc <myproc>
    80002fac:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fae:	fdc42503          	lw	a0,-36(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	060080e7          	jalr	96(ra) # 80002012 <growproc>
    80002fba:	00054863          	bltz	a0,80002fca <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fbe:	8526                	mv	a0,s1
}
    80002fc0:	70a2                	ld	ra,40(sp)
    80002fc2:	7402                	ld	s0,32(sp)
    80002fc4:	64e2                	ld	s1,24(sp)
    80002fc6:	6145                	addi	sp,sp,48
    80002fc8:	8082                	ret
    return -1;
    80002fca:	557d                	li	a0,-1
    80002fcc:	bfd5                	j	80002fc0 <sys_sbrk+0x3c>

0000000080002fce <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fce:	7139                	addi	sp,sp,-64
    80002fd0:	fc06                	sd	ra,56(sp)
    80002fd2:	f822                	sd	s0,48(sp)
    80002fd4:	f426                	sd	s1,40(sp)
    80002fd6:	f04a                	sd	s2,32(sp)
    80002fd8:	ec4e                	sd	s3,24(sp)
    80002fda:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fdc:	fcc40593          	addi	a1,s0,-52
    80002fe0:	4501                	li	a0,0
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	e2a080e7          	jalr	-470(ra) # 80002e0c <argint>
    return -1;
    80002fea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fec:	06054563          	bltz	a0,80003056 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff0:	00015517          	auipc	a0,0x15
    80002ff4:	97850513          	addi	a0,a0,-1672 # 80017968 <tickslock>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	c18080e7          	jalr	-1000(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80003000:	00006917          	auipc	s2,0x6
    80003004:	02092903          	lw	s2,32(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003008:	fcc42783          	lw	a5,-52(s0)
    8000300c:	cf85                	beqz	a5,80003044 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000300e:	00015997          	auipc	s3,0x15
    80003012:	95a98993          	addi	s3,s3,-1702 # 80017968 <tickslock>
    80003016:	00006497          	auipc	s1,0x6
    8000301a:	00a48493          	addi	s1,s1,10 # 80009020 <ticks>
    if(myproc()->killed){
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	b9e080e7          	jalr	-1122(ra) # 80001bbc <myproc>
    80003026:	591c                	lw	a5,48(a0)
    80003028:	ef9d                	bnez	a5,80003066 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000302a:	85ce                	mv	a1,s3
    8000302c:	8526                	mv	a0,s1
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	530080e7          	jalr	1328(ra) # 8000255e <sleep>
  while(ticks - ticks0 < n){
    80003036:	409c                	lw	a5,0(s1)
    80003038:	412787bb          	subw	a5,a5,s2
    8000303c:	fcc42703          	lw	a4,-52(s0)
    80003040:	fce7efe3          	bltu	a5,a4,8000301e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003044:	00015517          	auipc	a0,0x15
    80003048:	92450513          	addi	a0,a0,-1756 # 80017968 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c78080e7          	jalr	-904(ra) # 80000cc4 <release>
  return 0;
    80003054:	4781                	li	a5,0
}
    80003056:	853e                	mv	a0,a5
    80003058:	70e2                	ld	ra,56(sp)
    8000305a:	7442                	ld	s0,48(sp)
    8000305c:	74a2                	ld	s1,40(sp)
    8000305e:	7902                	ld	s2,32(sp)
    80003060:	69e2                	ld	s3,24(sp)
    80003062:	6121                	addi	sp,sp,64
    80003064:	8082                	ret
      release(&tickslock);
    80003066:	00015517          	auipc	a0,0x15
    8000306a:	90250513          	addi	a0,a0,-1790 # 80017968 <tickslock>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	c56080e7          	jalr	-938(ra) # 80000cc4 <release>
      return -1;
    80003076:	57fd                	li	a5,-1
    80003078:	bff9                	j	80003056 <sys_sleep+0x88>

000000008000307a <sys_kill>:

uint64
sys_kill(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003082:	fec40593          	addi	a1,s0,-20
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	d84080e7          	jalr	-636(ra) # 80002e0c <argint>
    80003090:	87aa                	mv	a5,a0
    return -1;
    80003092:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003094:	0007c863          	bltz	a5,800030a4 <sys_kill+0x2a>
  return kill(pid);
    80003098:	fec42503          	lw	a0,-20(s0)
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	6b2080e7          	jalr	1714(ra) # 8000274e <kill>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030ac:	1101                	addi	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	e426                	sd	s1,8(sp)
    800030b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b6:	00015517          	auipc	a0,0x15
    800030ba:	8b250513          	addi	a0,a0,-1870 # 80017968 <tickslock>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	b52080e7          	jalr	-1198(ra) # 80000c10 <acquire>
  xticks = ticks;
    800030c6:	00006497          	auipc	s1,0x6
    800030ca:	f5a4a483          	lw	s1,-166(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ce:	00015517          	auipc	a0,0x15
    800030d2:	89a50513          	addi	a0,a0,-1894 # 80017968 <tickslock>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	bee080e7          	jalr	-1042(ra) # 80000cc4 <release>
  return xticks;
}
    800030de:	02049513          	slli	a0,s1,0x20
    800030e2:	9101                	srli	a0,a0,0x20
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030ee:	7179                	addi	sp,sp,-48
    800030f0:	f406                	sd	ra,40(sp)
    800030f2:	f022                	sd	s0,32(sp)
    800030f4:	ec26                	sd	s1,24(sp)
    800030f6:	e84a                	sd	s2,16(sp)
    800030f8:	e44e                	sd	s3,8(sp)
    800030fa:	e052                	sd	s4,0(sp)
    800030fc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030fe:	00005597          	auipc	a1,0x5
    80003102:	4ba58593          	addi	a1,a1,1210 # 800085b8 <syscalls+0xb0>
    80003106:	00015517          	auipc	a0,0x15
    8000310a:	87a50513          	addi	a0,a0,-1926 # 80017980 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	a72080e7          	jalr	-1422(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003116:	0001d797          	auipc	a5,0x1d
    8000311a:	86a78793          	addi	a5,a5,-1942 # 8001f980 <bcache+0x8000>
    8000311e:	0001d717          	auipc	a4,0x1d
    80003122:	aca70713          	addi	a4,a4,-1334 # 8001fbe8 <bcache+0x8268>
    80003126:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000312a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000312e:	00015497          	auipc	s1,0x15
    80003132:	86a48493          	addi	s1,s1,-1942 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003136:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003138:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000313a:	00005a17          	auipc	s4,0x5
    8000313e:	486a0a13          	addi	s4,s4,1158 # 800085c0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003142:	2b893783          	ld	a5,696(s2)
    80003146:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003148:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000314c:	85d2                	mv	a1,s4
    8000314e:	01048513          	addi	a0,s1,16
    80003152:	00001097          	auipc	ra,0x1
    80003156:	4ac080e7          	jalr	1196(ra) # 800045fe <initsleeplock>
    bcache.head.next->prev = b;
    8000315a:	2b893783          	ld	a5,696(s2)
    8000315e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003160:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003164:	45848493          	addi	s1,s1,1112
    80003168:	fd349de3          	bne	s1,s3,80003142 <binit+0x54>
  }
}
    8000316c:	70a2                	ld	ra,40(sp)
    8000316e:	7402                	ld	s0,32(sp)
    80003170:	64e2                	ld	s1,24(sp)
    80003172:	6942                	ld	s2,16(sp)
    80003174:	69a2                	ld	s3,8(sp)
    80003176:	6a02                	ld	s4,0(sp)
    80003178:	6145                	addi	sp,sp,48
    8000317a:	8082                	ret

000000008000317c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000317c:	7179                	addi	sp,sp,-48
    8000317e:	f406                	sd	ra,40(sp)
    80003180:	f022                	sd	s0,32(sp)
    80003182:	ec26                	sd	s1,24(sp)
    80003184:	e84a                	sd	s2,16(sp)
    80003186:	e44e                	sd	s3,8(sp)
    80003188:	1800                	addi	s0,sp,48
    8000318a:	89aa                	mv	s3,a0
    8000318c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	7f250513          	addi	a0,a0,2034 # 80017980 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a7a080e7          	jalr	-1414(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000319e:	0001d497          	auipc	s1,0x1d
    800031a2:	a9a4b483          	ld	s1,-1382(s1) # 8001fc38 <bcache+0x82b8>
    800031a6:	0001d797          	auipc	a5,0x1d
    800031aa:	a4278793          	addi	a5,a5,-1470 # 8001fbe8 <bcache+0x8268>
    800031ae:	02f48f63          	beq	s1,a5,800031ec <bread+0x70>
    800031b2:	873e                	mv	a4,a5
    800031b4:	a021                	j	800031bc <bread+0x40>
    800031b6:	68a4                	ld	s1,80(s1)
    800031b8:	02e48a63          	beq	s1,a4,800031ec <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031bc:	449c                	lw	a5,8(s1)
    800031be:	ff379ce3          	bne	a5,s3,800031b6 <bread+0x3a>
    800031c2:	44dc                	lw	a5,12(s1)
    800031c4:	ff2799e3          	bne	a5,s2,800031b6 <bread+0x3a>
      b->refcnt++;
    800031c8:	40bc                	lw	a5,64(s1)
    800031ca:	2785                	addiw	a5,a5,1
    800031cc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	7b250513          	addi	a0,a0,1970 # 80017980 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	aee080e7          	jalr	-1298(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800031de:	01048513          	addi	a0,s1,16
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	456080e7          	jalr	1110(ra) # 80004638 <acquiresleep>
      return b;
    800031ea:	a8b9                	j	80003248 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ec:	0001d497          	auipc	s1,0x1d
    800031f0:	a444b483          	ld	s1,-1468(s1) # 8001fc30 <bcache+0x82b0>
    800031f4:	0001d797          	auipc	a5,0x1d
    800031f8:	9f478793          	addi	a5,a5,-1548 # 8001fbe8 <bcache+0x8268>
    800031fc:	00f48863          	beq	s1,a5,8000320c <bread+0x90>
    80003200:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	cf81                	beqz	a5,8000321c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003206:	64a4                	ld	s1,72(s1)
    80003208:	fee49de3          	bne	s1,a4,80003202 <bread+0x86>
  panic("bget: no buffers");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	3bc50513          	addi	a0,a0,956 # 800085c8 <syscalls+0xc0>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	334080e7          	jalr	820(ra) # 80000548 <panic>
      b->dev = dev;
    8000321c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003220:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003224:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003228:	4785                	li	a5,1
    8000322a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000322c:	00014517          	auipc	a0,0x14
    80003230:	75450513          	addi	a0,a0,1876 # 80017980 <bcache>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	a90080e7          	jalr	-1392(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000323c:	01048513          	addi	a0,s1,16
    80003240:	00001097          	auipc	ra,0x1
    80003244:	3f8080e7          	jalr	1016(ra) # 80004638 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003248:	409c                	lw	a5,0(s1)
    8000324a:	cb89                	beqz	a5,8000325c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000324c:	8526                	mv	a0,s1
    8000324e:	70a2                	ld	ra,40(sp)
    80003250:	7402                	ld	s0,32(sp)
    80003252:	64e2                	ld	s1,24(sp)
    80003254:	6942                	ld	s2,16(sp)
    80003256:	69a2                	ld	s3,8(sp)
    80003258:	6145                	addi	sp,sp,48
    8000325a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000325c:	4581                	li	a1,0
    8000325e:	8526                	mv	a0,s1
    80003260:	00003097          	auipc	ra,0x3
    80003264:	f9c080e7          	jalr	-100(ra) # 800061fc <virtio_disk_rw>
    b->valid = 1;
    80003268:	4785                	li	a5,1
    8000326a:	c09c                	sw	a5,0(s1)
  return b;
    8000326c:	b7c5                	j	8000324c <bread+0xd0>

000000008000326e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	1000                	addi	s0,sp,32
    80003278:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000327a:	0541                	addi	a0,a0,16
    8000327c:	00001097          	auipc	ra,0x1
    80003280:	456080e7          	jalr	1110(ra) # 800046d2 <holdingsleep>
    80003284:	cd01                	beqz	a0,8000329c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003286:	4585                	li	a1,1
    80003288:	8526                	mv	a0,s1
    8000328a:	00003097          	auipc	ra,0x3
    8000328e:	f72080e7          	jalr	-142(ra) # 800061fc <virtio_disk_rw>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret
    panic("bwrite");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	34450513          	addi	a0,a0,836 # 800085e0 <syscalls+0xd8>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	2a4080e7          	jalr	676(ra) # 80000548 <panic>

00000000800032ac <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	e04a                	sd	s2,0(sp)
    800032b6:	1000                	addi	s0,sp,32
    800032b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ba:	01050913          	addi	s2,a0,16
    800032be:	854a                	mv	a0,s2
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	412080e7          	jalr	1042(ra) # 800046d2 <holdingsleep>
    800032c8:	c92d                	beqz	a0,8000333a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ca:	854a                	mv	a0,s2
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	3c2080e7          	jalr	962(ra) # 8000468e <releasesleep>

  acquire(&bcache.lock);
    800032d4:	00014517          	auipc	a0,0x14
    800032d8:	6ac50513          	addi	a0,a0,1708 # 80017980 <bcache>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	934080e7          	jalr	-1740(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032e4:	40bc                	lw	a5,64(s1)
    800032e6:	37fd                	addiw	a5,a5,-1
    800032e8:	0007871b          	sext.w	a4,a5
    800032ec:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032ee:	eb05                	bnez	a4,8000331e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032f0:	68bc                	ld	a5,80(s1)
    800032f2:	64b8                	ld	a4,72(s1)
    800032f4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032f6:	64bc                	ld	a5,72(s1)
    800032f8:	68b8                	ld	a4,80(s1)
    800032fa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032fc:	0001c797          	auipc	a5,0x1c
    80003300:	68478793          	addi	a5,a5,1668 # 8001f980 <bcache+0x8000>
    80003304:	2b87b703          	ld	a4,696(a5)
    80003308:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000330a:	0001d717          	auipc	a4,0x1d
    8000330e:	8de70713          	addi	a4,a4,-1826 # 8001fbe8 <bcache+0x8268>
    80003312:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003314:	2b87b703          	ld	a4,696(a5)
    80003318:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000331a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000331e:	00014517          	auipc	a0,0x14
    80003322:	66250513          	addi	a0,a0,1634 # 80017980 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	99e080e7          	jalr	-1634(ra) # 80000cc4 <release>
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6902                	ld	s2,0(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret
    panic("brelse");
    8000333a:	00005517          	auipc	a0,0x5
    8000333e:	2ae50513          	addi	a0,a0,686 # 800085e8 <syscalls+0xe0>
    80003342:	ffffd097          	auipc	ra,0xffffd
    80003346:	206080e7          	jalr	518(ra) # 80000548 <panic>

000000008000334a <bpin>:

void
bpin(struct buf *b) {
    8000334a:	1101                	addi	sp,sp,-32
    8000334c:	ec06                	sd	ra,24(sp)
    8000334e:	e822                	sd	s0,16(sp)
    80003350:	e426                	sd	s1,8(sp)
    80003352:	1000                	addi	s0,sp,32
    80003354:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003356:	00014517          	auipc	a0,0x14
    8000335a:	62a50513          	addi	a0,a0,1578 # 80017980 <bcache>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	8b2080e7          	jalr	-1870(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003366:	40bc                	lw	a5,64(s1)
    80003368:	2785                	addiw	a5,a5,1
    8000336a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000336c:	00014517          	auipc	a0,0x14
    80003370:	61450513          	addi	a0,a0,1556 # 80017980 <bcache>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	950080e7          	jalr	-1712(ra) # 80000cc4 <release>
}
    8000337c:	60e2                	ld	ra,24(sp)
    8000337e:	6442                	ld	s0,16(sp)
    80003380:	64a2                	ld	s1,8(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret

0000000080003386 <bunpin>:

void
bunpin(struct buf *b) {
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	e426                	sd	s1,8(sp)
    8000338e:	1000                	addi	s0,sp,32
    80003390:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003392:	00014517          	auipc	a0,0x14
    80003396:	5ee50513          	addi	a0,a0,1518 # 80017980 <bcache>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	876080e7          	jalr	-1930(ra) # 80000c10 <acquire>
  b->refcnt--;
    800033a2:	40bc                	lw	a5,64(s1)
    800033a4:	37fd                	addiw	a5,a5,-1
    800033a6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a8:	00014517          	auipc	a0,0x14
    800033ac:	5d850513          	addi	a0,a0,1496 # 80017980 <bcache>
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	914080e7          	jalr	-1772(ra) # 80000cc4 <release>
}
    800033b8:	60e2                	ld	ra,24(sp)
    800033ba:	6442                	ld	s0,16(sp)
    800033bc:	64a2                	ld	s1,8(sp)
    800033be:	6105                	addi	sp,sp,32
    800033c0:	8082                	ret

00000000800033c2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	e426                	sd	s1,8(sp)
    800033ca:	e04a                	sd	s2,0(sp)
    800033cc:	1000                	addi	s0,sp,32
    800033ce:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033d0:	00d5d59b          	srliw	a1,a1,0xd
    800033d4:	0001d797          	auipc	a5,0x1d
    800033d8:	c887a783          	lw	a5,-888(a5) # 8002005c <sb+0x1c>
    800033dc:	9dbd                	addw	a1,a1,a5
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	d9e080e7          	jalr	-610(ra) # 8000317c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033e6:	0074f713          	andi	a4,s1,7
    800033ea:	4785                	li	a5,1
    800033ec:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033f0:	14ce                	slli	s1,s1,0x33
    800033f2:	90d9                	srli	s1,s1,0x36
    800033f4:	00950733          	add	a4,a0,s1
    800033f8:	05874703          	lbu	a4,88(a4)
    800033fc:	00e7f6b3          	and	a3,a5,a4
    80003400:	c69d                	beqz	a3,8000342e <bfree+0x6c>
    80003402:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003404:	94aa                	add	s1,s1,a0
    80003406:	fff7c793          	not	a5,a5
    8000340a:	8ff9                	and	a5,a5,a4
    8000340c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003410:	00001097          	auipc	ra,0x1
    80003414:	100080e7          	jalr	256(ra) # 80004510 <log_write>
  brelse(bp);
    80003418:	854a                	mv	a0,s2
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e92080e7          	jalr	-366(ra) # 800032ac <brelse>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    panic("freeing free block");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	1c250513          	addi	a0,a0,450 # 800085f0 <syscalls+0xe8>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	112080e7          	jalr	274(ra) # 80000548 <panic>

000000008000343e <balloc>:
{
    8000343e:	711d                	addi	sp,sp,-96
    80003440:	ec86                	sd	ra,88(sp)
    80003442:	e8a2                	sd	s0,80(sp)
    80003444:	e4a6                	sd	s1,72(sp)
    80003446:	e0ca                	sd	s2,64(sp)
    80003448:	fc4e                	sd	s3,56(sp)
    8000344a:	f852                	sd	s4,48(sp)
    8000344c:	f456                	sd	s5,40(sp)
    8000344e:	f05a                	sd	s6,32(sp)
    80003450:	ec5e                	sd	s7,24(sp)
    80003452:	e862                	sd	s8,16(sp)
    80003454:	e466                	sd	s9,8(sp)
    80003456:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003458:	0001d797          	auipc	a5,0x1d
    8000345c:	bec7a783          	lw	a5,-1044(a5) # 80020044 <sb+0x4>
    80003460:	cbd1                	beqz	a5,800034f4 <balloc+0xb6>
    80003462:	8baa                	mv	s7,a0
    80003464:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003466:	0001db17          	auipc	s6,0x1d
    8000346a:	bdab0b13          	addi	s6,s6,-1062 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003470:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003474:	6c89                	lui	s9,0x2
    80003476:	a831                	j	80003492 <balloc+0x54>
    brelse(bp);
    80003478:	854a                	mv	a0,s2
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	e32080e7          	jalr	-462(ra) # 800032ac <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003482:	015c87bb          	addw	a5,s9,s5
    80003486:	00078a9b          	sext.w	s5,a5
    8000348a:	004b2703          	lw	a4,4(s6)
    8000348e:	06eaf363          	bgeu	s5,a4,800034f4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003492:	41fad79b          	sraiw	a5,s5,0x1f
    80003496:	0137d79b          	srliw	a5,a5,0x13
    8000349a:	015787bb          	addw	a5,a5,s5
    8000349e:	40d7d79b          	sraiw	a5,a5,0xd
    800034a2:	01cb2583          	lw	a1,28(s6)
    800034a6:	9dbd                	addw	a1,a1,a5
    800034a8:	855e                	mv	a0,s7
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	cd2080e7          	jalr	-814(ra) # 8000317c <bread>
    800034b2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b4:	004b2503          	lw	a0,4(s6)
    800034b8:	000a849b          	sext.w	s1,s5
    800034bc:	8662                	mv	a2,s8
    800034be:	faa4fde3          	bgeu	s1,a0,80003478 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034c2:	41f6579b          	sraiw	a5,a2,0x1f
    800034c6:	01d7d69b          	srliw	a3,a5,0x1d
    800034ca:	00c6873b          	addw	a4,a3,a2
    800034ce:	00777793          	andi	a5,a4,7
    800034d2:	9f95                	subw	a5,a5,a3
    800034d4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034d8:	4037571b          	sraiw	a4,a4,0x3
    800034dc:	00e906b3          	add	a3,s2,a4
    800034e0:	0586c683          	lbu	a3,88(a3)
    800034e4:	00d7f5b3          	and	a1,a5,a3
    800034e8:	cd91                	beqz	a1,80003504 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ea:	2605                	addiw	a2,a2,1
    800034ec:	2485                	addiw	s1,s1,1
    800034ee:	fd4618e3          	bne	a2,s4,800034be <balloc+0x80>
    800034f2:	b759                	j	80003478 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	11450513          	addi	a0,a0,276 # 80008608 <syscalls+0x100>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	04c080e7          	jalr	76(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003504:	974a                	add	a4,a4,s2
    80003506:	8fd5                	or	a5,a5,a3
    80003508:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	002080e7          	jalr	2(ra) # 80004510 <log_write>
        brelse(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	d94080e7          	jalr	-620(ra) # 800032ac <brelse>
  bp = bread(dev, bno);
    80003520:	85a6                	mv	a1,s1
    80003522:	855e                	mv	a0,s7
    80003524:	00000097          	auipc	ra,0x0
    80003528:	c58080e7          	jalr	-936(ra) # 8000317c <bread>
    8000352c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000352e:	40000613          	li	a2,1024
    80003532:	4581                	li	a1,0
    80003534:	05850513          	addi	a0,a0,88
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	7d4080e7          	jalr	2004(ra) # 80000d0c <memset>
  log_write(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	fce080e7          	jalr	-50(ra) # 80004510 <log_write>
  brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	d60080e7          	jalr	-672(ra) # 800032ac <brelse>
}
    80003554:	8526                	mv	a0,s1
    80003556:	60e6                	ld	ra,88(sp)
    80003558:	6446                	ld	s0,80(sp)
    8000355a:	64a6                	ld	s1,72(sp)
    8000355c:	6906                	ld	s2,64(sp)
    8000355e:	79e2                	ld	s3,56(sp)
    80003560:	7a42                	ld	s4,48(sp)
    80003562:	7aa2                	ld	s5,40(sp)
    80003564:	7b02                	ld	s6,32(sp)
    80003566:	6be2                	ld	s7,24(sp)
    80003568:	6c42                	ld	s8,16(sp)
    8000356a:	6ca2                	ld	s9,8(sp)
    8000356c:	6125                	addi	sp,sp,96
    8000356e:	8082                	ret

0000000080003570 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	e052                	sd	s4,0(sp)
    8000357e:	1800                	addi	s0,sp,48
    80003580:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003582:	47ad                	li	a5,11
    80003584:	04b7fe63          	bgeu	a5,a1,800035e0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003588:	ff45849b          	addiw	s1,a1,-12
    8000358c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003590:	0ff00793          	li	a5,255
    80003594:	0ae7e363          	bltu	a5,a4,8000363a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003598:	08052583          	lw	a1,128(a0)
    8000359c:	c5ad                	beqz	a1,80003606 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000359e:	00092503          	lw	a0,0(s2)
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	bda080e7          	jalr	-1062(ra) # 8000317c <bread>
    800035aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b0:	02049593          	slli	a1,s1,0x20
    800035b4:	9181                	srli	a1,a1,0x20
    800035b6:	058a                	slli	a1,a1,0x2
    800035b8:	00b784b3          	add	s1,a5,a1
    800035bc:	0004a983          	lw	s3,0(s1)
    800035c0:	04098d63          	beqz	s3,8000361a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035c4:	8552                	mv	a0,s4
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	ce6080e7          	jalr	-794(ra) # 800032ac <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ce:	854e                	mv	a0,s3
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6a02                	ld	s4,0(sp)
    800035dc:	6145                	addi	sp,sp,48
    800035de:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e0:	02059493          	slli	s1,a1,0x20
    800035e4:	9081                	srli	s1,s1,0x20
    800035e6:	048a                	slli	s1,s1,0x2
    800035e8:	94aa                	add	s1,s1,a0
    800035ea:	0504a983          	lw	s3,80(s1)
    800035ee:	fe0990e3          	bnez	s3,800035ce <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	e4a080e7          	jalr	-438(ra) # 8000343e <balloc>
    800035fc:	0005099b          	sext.w	s3,a0
    80003600:	0534a823          	sw	s3,80(s1)
    80003604:	b7e9                	j	800035ce <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003606:	4108                	lw	a0,0(a0)
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	e36080e7          	jalr	-458(ra) # 8000343e <balloc>
    80003610:	0005059b          	sext.w	a1,a0
    80003614:	08b92023          	sw	a1,128(s2)
    80003618:	b759                	j	8000359e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000361a:	00092503          	lw	a0,0(s2)
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	e20080e7          	jalr	-480(ra) # 8000343e <balloc>
    80003626:	0005099b          	sext.w	s3,a0
    8000362a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000362e:	8552                	mv	a0,s4
    80003630:	00001097          	auipc	ra,0x1
    80003634:	ee0080e7          	jalr	-288(ra) # 80004510 <log_write>
    80003638:	b771                	j	800035c4 <bmap+0x54>
  panic("bmap: out of range");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	fe650513          	addi	a0,a0,-26 # 80008620 <syscalls+0x118>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	f06080e7          	jalr	-250(ra) # 80000548 <panic>

000000008000364a <iget>:
{
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	e052                	sd	s4,0(sp)
    80003658:	1800                	addi	s0,sp,48
    8000365a:	89aa                	mv	s3,a0
    8000365c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000365e:	0001d517          	auipc	a0,0x1d
    80003662:	a0250513          	addi	a0,a0,-1534 # 80020060 <icache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	5aa080e7          	jalr	1450(ra) # 80000c10 <acquire>
  empty = 0;
    8000366e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003670:	0001d497          	auipc	s1,0x1d
    80003674:	a0848493          	addi	s1,s1,-1528 # 80020078 <icache+0x18>
    80003678:	0001e697          	auipc	a3,0x1e
    8000367c:	49068693          	addi	a3,a3,1168 # 80021b08 <log>
    80003680:	a039                	j	8000368e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003682:	02090b63          	beqz	s2,800036b8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003686:	08848493          	addi	s1,s1,136
    8000368a:	02d48a63          	beq	s1,a3,800036be <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000368e:	449c                	lw	a5,8(s1)
    80003690:	fef059e3          	blez	a5,80003682 <iget+0x38>
    80003694:	4098                	lw	a4,0(s1)
    80003696:	ff3716e3          	bne	a4,s3,80003682 <iget+0x38>
    8000369a:	40d8                	lw	a4,4(s1)
    8000369c:	ff4713e3          	bne	a4,s4,80003682 <iget+0x38>
      ip->ref++;
    800036a0:	2785                	addiw	a5,a5,1
    800036a2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036a4:	0001d517          	auipc	a0,0x1d
    800036a8:	9bc50513          	addi	a0,a0,-1604 # 80020060 <icache>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	618080e7          	jalr	1560(ra) # 80000cc4 <release>
      return ip;
    800036b4:	8926                	mv	s2,s1
    800036b6:	a03d                	j	800036e4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b8:	f7f9                	bnez	a5,80003686 <iget+0x3c>
    800036ba:	8926                	mv	s2,s1
    800036bc:	b7e9                	j	80003686 <iget+0x3c>
  if(empty == 0)
    800036be:	02090c63          	beqz	s2,800036f6 <iget+0xac>
  ip->dev = dev;
    800036c2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036c6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036ca:	4785                	li	a5,1
    800036cc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036d4:	0001d517          	auipc	a0,0x1d
    800036d8:	98c50513          	addi	a0,a0,-1652 # 80020060 <icache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5e8080e7          	jalr	1512(ra) # 80000cc4 <release>
}
    800036e4:	854a                	mv	a0,s2
    800036e6:	70a2                	ld	ra,40(sp)
    800036e8:	7402                	ld	s0,32(sp)
    800036ea:	64e2                	ld	s1,24(sp)
    800036ec:	6942                	ld	s2,16(sp)
    800036ee:	69a2                	ld	s3,8(sp)
    800036f0:	6a02                	ld	s4,0(sp)
    800036f2:	6145                	addi	sp,sp,48
    800036f4:	8082                	ret
    panic("iget: no inodes");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	f4250513          	addi	a0,a0,-190 # 80008638 <syscalls+0x130>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e4a080e7          	jalr	-438(ra) # 80000548 <panic>

0000000080003706 <fsinit>:
fsinit(int dev) {
    80003706:	7179                	addi	sp,sp,-48
    80003708:	f406                	sd	ra,40(sp)
    8000370a:	f022                	sd	s0,32(sp)
    8000370c:	ec26                	sd	s1,24(sp)
    8000370e:	e84a                	sd	s2,16(sp)
    80003710:	e44e                	sd	s3,8(sp)
    80003712:	1800                	addi	s0,sp,48
    80003714:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003716:	4585                	li	a1,1
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	a64080e7          	jalr	-1436(ra) # 8000317c <bread>
    80003720:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003722:	0001d997          	auipc	s3,0x1d
    80003726:	91e98993          	addi	s3,s3,-1762 # 80020040 <sb>
    8000372a:	02000613          	li	a2,32
    8000372e:	05850593          	addi	a1,a0,88
    80003732:	854e                	mv	a0,s3
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	638080e7          	jalr	1592(ra) # 80000d6c <memmove>
  brelse(bp);
    8000373c:	8526                	mv	a0,s1
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	b6e080e7          	jalr	-1170(ra) # 800032ac <brelse>
  if(sb.magic != FSMAGIC)
    80003746:	0009a703          	lw	a4,0(s3)
    8000374a:	102037b7          	lui	a5,0x10203
    8000374e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003752:	02f71263          	bne	a4,a5,80003776 <fsinit+0x70>
  initlog(dev, &sb);
    80003756:	0001d597          	auipc	a1,0x1d
    8000375a:	8ea58593          	addi	a1,a1,-1814 # 80020040 <sb>
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	b38080e7          	jalr	-1224(ra) # 80004298 <initlog>
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6942                	ld	s2,16(sp)
    80003770:	69a2                	ld	s3,8(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret
    panic("invalid file system");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	ed250513          	addi	a0,a0,-302 # 80008648 <syscalls+0x140>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dca080e7          	jalr	-566(ra) # 80000548 <panic>

0000000080003786 <iinit>:
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003794:	00005597          	auipc	a1,0x5
    80003798:	ecc58593          	addi	a1,a1,-308 # 80008660 <syscalls+0x158>
    8000379c:	0001d517          	auipc	a0,0x1d
    800037a0:	8c450513          	addi	a0,a0,-1852 # 80020060 <icache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	3dc080e7          	jalr	988(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ac:	0001d497          	auipc	s1,0x1d
    800037b0:	8dc48493          	addi	s1,s1,-1828 # 80020088 <icache+0x28>
    800037b4:	0001e997          	auipc	s3,0x1e
    800037b8:	36498993          	addi	s3,s3,868 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037bc:	00005917          	auipc	s2,0x5
    800037c0:	eac90913          	addi	s2,s2,-340 # 80008668 <syscalls+0x160>
    800037c4:	85ca                	mv	a1,s2
    800037c6:	8526                	mv	a0,s1
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	e36080e7          	jalr	-458(ra) # 800045fe <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d0:	08848493          	addi	s1,s1,136
    800037d4:	ff3498e3          	bne	s1,s3,800037c4 <iinit+0x3e>
}
    800037d8:	70a2                	ld	ra,40(sp)
    800037da:	7402                	ld	s0,32(sp)
    800037dc:	64e2                	ld	s1,24(sp)
    800037de:	6942                	ld	s2,16(sp)
    800037e0:	69a2                	ld	s3,8(sp)
    800037e2:	6145                	addi	sp,sp,48
    800037e4:	8082                	ret

00000000800037e6 <ialloc>:
{
    800037e6:	715d                	addi	sp,sp,-80
    800037e8:	e486                	sd	ra,72(sp)
    800037ea:	e0a2                	sd	s0,64(sp)
    800037ec:	fc26                	sd	s1,56(sp)
    800037ee:	f84a                	sd	s2,48(sp)
    800037f0:	f44e                	sd	s3,40(sp)
    800037f2:	f052                	sd	s4,32(sp)
    800037f4:	ec56                	sd	s5,24(sp)
    800037f6:	e85a                	sd	s6,16(sp)
    800037f8:	e45e                	sd	s7,8(sp)
    800037fa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fc:	0001d717          	auipc	a4,0x1d
    80003800:	85072703          	lw	a4,-1968(a4) # 8002004c <sb+0xc>
    80003804:	4785                	li	a5,1
    80003806:	04e7fa63          	bgeu	a5,a4,8000385a <ialloc+0x74>
    8000380a:	8aaa                	mv	s5,a0
    8000380c:	8bae                	mv	s7,a1
    8000380e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003810:	0001da17          	auipc	s4,0x1d
    80003814:	830a0a13          	addi	s4,s4,-2000 # 80020040 <sb>
    80003818:	00048b1b          	sext.w	s6,s1
    8000381c:	0044d593          	srli	a1,s1,0x4
    80003820:	018a2783          	lw	a5,24(s4)
    80003824:	9dbd                	addw	a1,a1,a5
    80003826:	8556                	mv	a0,s5
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	954080e7          	jalr	-1708(ra) # 8000317c <bread>
    80003830:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003832:	05850993          	addi	s3,a0,88
    80003836:	00f4f793          	andi	a5,s1,15
    8000383a:	079a                	slli	a5,a5,0x6
    8000383c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000383e:	00099783          	lh	a5,0(s3)
    80003842:	c785                	beqz	a5,8000386a <ialloc+0x84>
    brelse(bp);
    80003844:	00000097          	auipc	ra,0x0
    80003848:	a68080e7          	jalr	-1432(ra) # 800032ac <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384c:	0485                	addi	s1,s1,1
    8000384e:	00ca2703          	lw	a4,12(s4)
    80003852:	0004879b          	sext.w	a5,s1
    80003856:	fce7e1e3          	bltu	a5,a4,80003818 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	e1650513          	addi	a0,a0,-490 # 80008670 <syscalls+0x168>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	ce6080e7          	jalr	-794(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000386a:	04000613          	li	a2,64
    8000386e:	4581                	li	a1,0
    80003870:	854e                	mv	a0,s3
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	49a080e7          	jalr	1178(ra) # 80000d0c <memset>
      dip->type = type;
    8000387a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c90080e7          	jalr	-880(ra) # 80004510 <log_write>
      brelse(bp);
    80003888:	854a                	mv	a0,s2
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	a22080e7          	jalr	-1502(ra) # 800032ac <brelse>
      return iget(dev, inum);
    80003892:	85da                	mv	a1,s6
    80003894:	8556                	mv	a0,s5
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	db4080e7          	jalr	-588(ra) # 8000364a <iget>
}
    8000389e:	60a6                	ld	ra,72(sp)
    800038a0:	6406                	ld	s0,64(sp)
    800038a2:	74e2                	ld	s1,56(sp)
    800038a4:	7942                	ld	s2,48(sp)
    800038a6:	79a2                	ld	s3,40(sp)
    800038a8:	7a02                	ld	s4,32(sp)
    800038aa:	6ae2                	ld	s5,24(sp)
    800038ac:	6b42                	ld	s6,16(sp)
    800038ae:	6ba2                	ld	s7,8(sp)
    800038b0:	6161                	addi	sp,sp,80
    800038b2:	8082                	ret

00000000800038b4 <iupdate>:
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	e04a                	sd	s2,0(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c2:	415c                	lw	a5,4(a0)
    800038c4:	0047d79b          	srliw	a5,a5,0x4
    800038c8:	0001c597          	auipc	a1,0x1c
    800038cc:	7905a583          	lw	a1,1936(a1) # 80020058 <sb+0x18>
    800038d0:	9dbd                	addw	a1,a1,a5
    800038d2:	4108                	lw	a0,0(a0)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	8a8080e7          	jalr	-1880(ra) # 8000317c <bread>
    800038dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038de:	05850793          	addi	a5,a0,88
    800038e2:	40c8                	lw	a0,4(s1)
    800038e4:	893d                	andi	a0,a0,15
    800038e6:	051a                	slli	a0,a0,0x6
    800038e8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038ea:	04449703          	lh	a4,68(s1)
    800038ee:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038f2:	04649703          	lh	a4,70(s1)
    800038f6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038fa:	04849703          	lh	a4,72(s1)
    800038fe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003902:	04a49703          	lh	a4,74(s1)
    80003906:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000390a:	44f8                	lw	a4,76(s1)
    8000390c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000390e:	03400613          	li	a2,52
    80003912:	05048593          	addi	a1,s1,80
    80003916:	0531                	addi	a0,a0,12
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	454080e7          	jalr	1108(ra) # 80000d6c <memmove>
  log_write(bp);
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	bee080e7          	jalr	-1042(ra) # 80004510 <log_write>
  brelse(bp);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	980080e7          	jalr	-1664(ra) # 800032ac <brelse>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6902                	ld	s2,0(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret

0000000080003940 <idup>:
{
    80003940:	1101                	addi	sp,sp,-32
    80003942:	ec06                	sd	ra,24(sp)
    80003944:	e822                	sd	s0,16(sp)
    80003946:	e426                	sd	s1,8(sp)
    80003948:	1000                	addi	s0,sp,32
    8000394a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000394c:	0001c517          	auipc	a0,0x1c
    80003950:	71450513          	addi	a0,a0,1812 # 80020060 <icache>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	2bc080e7          	jalr	700(ra) # 80000c10 <acquire>
  ip->ref++;
    8000395c:	449c                	lw	a5,8(s1)
    8000395e:	2785                	addiw	a5,a5,1
    80003960:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003962:	0001c517          	auipc	a0,0x1c
    80003966:	6fe50513          	addi	a0,a0,1790 # 80020060 <icache>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	35a080e7          	jalr	858(ra) # 80000cc4 <release>
}
    80003972:	8526                	mv	a0,s1
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6105                	addi	sp,sp,32
    8000397c:	8082                	ret

000000008000397e <ilock>:
{
    8000397e:	1101                	addi	sp,sp,-32
    80003980:	ec06                	sd	ra,24(sp)
    80003982:	e822                	sd	s0,16(sp)
    80003984:	e426                	sd	s1,8(sp)
    80003986:	e04a                	sd	s2,0(sp)
    80003988:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000398a:	c115                	beqz	a0,800039ae <ilock+0x30>
    8000398c:	84aa                	mv	s1,a0
    8000398e:	451c                	lw	a5,8(a0)
    80003990:	00f05f63          	blez	a5,800039ae <ilock+0x30>
  acquiresleep(&ip->lock);
    80003994:	0541                	addi	a0,a0,16
    80003996:	00001097          	auipc	ra,0x1
    8000399a:	ca2080e7          	jalr	-862(ra) # 80004638 <acquiresleep>
  if(ip->valid == 0){
    8000399e:	40bc                	lw	a5,64(s1)
    800039a0:	cf99                	beqz	a5,800039be <ilock+0x40>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret
    panic("ilock");
    800039ae:	00005517          	auipc	a0,0x5
    800039b2:	cda50513          	addi	a0,a0,-806 # 80008688 <syscalls+0x180>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	b92080e7          	jalr	-1134(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039be:	40dc                	lw	a5,4(s1)
    800039c0:	0047d79b          	srliw	a5,a5,0x4
    800039c4:	0001c597          	auipc	a1,0x1c
    800039c8:	6945a583          	lw	a1,1684(a1) # 80020058 <sb+0x18>
    800039cc:	9dbd                	addw	a1,a1,a5
    800039ce:	4088                	lw	a0,0(s1)
    800039d0:	fffff097          	auipc	ra,0xfffff
    800039d4:	7ac080e7          	jalr	1964(ra) # 8000317c <bread>
    800039d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039da:	05850593          	addi	a1,a0,88
    800039de:	40dc                	lw	a5,4(s1)
    800039e0:	8bbd                	andi	a5,a5,15
    800039e2:	079a                	slli	a5,a5,0x6
    800039e4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e6:	00059783          	lh	a5,0(a1)
    800039ea:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039ee:	00259783          	lh	a5,2(a1)
    800039f2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039f6:	00459783          	lh	a5,4(a1)
    800039fa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039fe:	00659783          	lh	a5,6(a1)
    80003a02:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a06:	459c                	lw	a5,8(a1)
    80003a08:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a0a:	03400613          	li	a2,52
    80003a0e:	05b1                	addi	a1,a1,12
    80003a10:	05048513          	addi	a0,s1,80
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	358080e7          	jalr	856(ra) # 80000d6c <memmove>
    brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	88e080e7          	jalr	-1906(ra) # 800032ac <brelse>
    ip->valid = 1;
    80003a26:	4785                	li	a5,1
    80003a28:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a2a:	04449783          	lh	a5,68(s1)
    80003a2e:	fbb5                	bnez	a5,800039a2 <ilock+0x24>
      panic("ilock: no type");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	c6050513          	addi	a0,a0,-928 # 80008690 <syscalls+0x188>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>

0000000080003a40 <iunlock>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	e04a                	sd	s2,0(sp)
    80003a4a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a4c:	c905                	beqz	a0,80003a7c <iunlock+0x3c>
    80003a4e:	84aa                	mv	s1,a0
    80003a50:	01050913          	addi	s2,a0,16
    80003a54:	854a                	mv	a0,s2
    80003a56:	00001097          	auipc	ra,0x1
    80003a5a:	c7c080e7          	jalr	-900(ra) # 800046d2 <holdingsleep>
    80003a5e:	cd19                	beqz	a0,80003a7c <iunlock+0x3c>
    80003a60:	449c                	lw	a5,8(s1)
    80003a62:	00f05d63          	blez	a5,80003a7c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	c26080e7          	jalr	-986(ra) # 8000468e <releasesleep>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret
    panic("iunlock");
    80003a7c:	00005517          	auipc	a0,0x5
    80003a80:	c2450513          	addi	a0,a0,-988 # 800086a0 <syscalls+0x198>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	ac4080e7          	jalr	-1340(ra) # 80000548 <panic>

0000000080003a8c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a8c:	7179                	addi	sp,sp,-48
    80003a8e:	f406                	sd	ra,40(sp)
    80003a90:	f022                	sd	s0,32(sp)
    80003a92:	ec26                	sd	s1,24(sp)
    80003a94:	e84a                	sd	s2,16(sp)
    80003a96:	e44e                	sd	s3,8(sp)
    80003a98:	e052                	sd	s4,0(sp)
    80003a9a:	1800                	addi	s0,sp,48
    80003a9c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a9e:	05050493          	addi	s1,a0,80
    80003aa2:	08050913          	addi	s2,a0,128
    80003aa6:	a021                	j	80003aae <itrunc+0x22>
    80003aa8:	0491                	addi	s1,s1,4
    80003aaa:	01248d63          	beq	s1,s2,80003ac4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aae:	408c                	lw	a1,0(s1)
    80003ab0:	dde5                	beqz	a1,80003aa8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ab2:	0009a503          	lw	a0,0(s3)
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	90c080e7          	jalr	-1780(ra) # 800033c2 <bfree>
      ip->addrs[i] = 0;
    80003abe:	0004a023          	sw	zero,0(s1)
    80003ac2:	b7dd                	j	80003aa8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ac4:	0809a583          	lw	a1,128(s3)
    80003ac8:	e185                	bnez	a1,80003ae8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aca:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ace:	854e                	mv	a0,s3
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	de4080e7          	jalr	-540(ra) # 800038b4 <iupdate>
}
    80003ad8:	70a2                	ld	ra,40(sp)
    80003ada:	7402                	ld	s0,32(sp)
    80003adc:	64e2                	ld	s1,24(sp)
    80003ade:	6942                	ld	s2,16(sp)
    80003ae0:	69a2                	ld	s3,8(sp)
    80003ae2:	6a02                	ld	s4,0(sp)
    80003ae4:	6145                	addi	sp,sp,48
    80003ae6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae8:	0009a503          	lw	a0,0(s3)
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	690080e7          	jalr	1680(ra) # 8000317c <bread>
    80003af4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af6:	05850493          	addi	s1,a0,88
    80003afa:	45850913          	addi	s2,a0,1112
    80003afe:	a811                	j	80003b12 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b00:	0009a503          	lw	a0,0(s3)
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	8be080e7          	jalr	-1858(ra) # 800033c2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b0c:	0491                	addi	s1,s1,4
    80003b0e:	01248563          	beq	s1,s2,80003b18 <itrunc+0x8c>
      if(a[j])
    80003b12:	408c                	lw	a1,0(s1)
    80003b14:	dde5                	beqz	a1,80003b0c <itrunc+0x80>
    80003b16:	b7ed                	j	80003b00 <itrunc+0x74>
    brelse(bp);
    80003b18:	8552                	mv	a0,s4
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	792080e7          	jalr	1938(ra) # 800032ac <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b22:	0809a583          	lw	a1,128(s3)
    80003b26:	0009a503          	lw	a0,0(s3)
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	898080e7          	jalr	-1896(ra) # 800033c2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b32:	0809a023          	sw	zero,128(s3)
    80003b36:	bf51                	j	80003aca <itrunc+0x3e>

0000000080003b38 <iput>:
{
    80003b38:	1101                	addi	sp,sp,-32
    80003b3a:	ec06                	sd	ra,24(sp)
    80003b3c:	e822                	sd	s0,16(sp)
    80003b3e:	e426                	sd	s1,8(sp)
    80003b40:	e04a                	sd	s2,0(sp)
    80003b42:	1000                	addi	s0,sp,32
    80003b44:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b46:	0001c517          	auipc	a0,0x1c
    80003b4a:	51a50513          	addi	a0,a0,1306 # 80020060 <icache>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	0c2080e7          	jalr	194(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b56:	4498                	lw	a4,8(s1)
    80003b58:	4785                	li	a5,1
    80003b5a:	02f70363          	beq	a4,a5,80003b80 <iput+0x48>
  ip->ref--;
    80003b5e:	449c                	lw	a5,8(s1)
    80003b60:	37fd                	addiw	a5,a5,-1
    80003b62:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b64:	0001c517          	auipc	a0,0x1c
    80003b68:	4fc50513          	addi	a0,a0,1276 # 80020060 <icache>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	158080e7          	jalr	344(ra) # 80000cc4 <release>
}
    80003b74:	60e2                	ld	ra,24(sp)
    80003b76:	6442                	ld	s0,16(sp)
    80003b78:	64a2                	ld	s1,8(sp)
    80003b7a:	6902                	ld	s2,0(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b80:	40bc                	lw	a5,64(s1)
    80003b82:	dff1                	beqz	a5,80003b5e <iput+0x26>
    80003b84:	04a49783          	lh	a5,74(s1)
    80003b88:	fbf9                	bnez	a5,80003b5e <iput+0x26>
    acquiresleep(&ip->lock);
    80003b8a:	01048913          	addi	s2,s1,16
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	aa8080e7          	jalr	-1368(ra) # 80004638 <acquiresleep>
    release(&icache.lock);
    80003b98:	0001c517          	auipc	a0,0x1c
    80003b9c:	4c850513          	addi	a0,a0,1224 # 80020060 <icache>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	124080e7          	jalr	292(ra) # 80000cc4 <release>
    itrunc(ip);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	ee2080e7          	jalr	-286(ra) # 80003a8c <itrunc>
    ip->type = 0;
    80003bb2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	cfc080e7          	jalr	-772(ra) # 800038b4 <iupdate>
    ip->valid = 0;
    80003bc0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	ac8080e7          	jalr	-1336(ra) # 8000468e <releasesleep>
    acquire(&icache.lock);
    80003bce:	0001c517          	auipc	a0,0x1c
    80003bd2:	49250513          	addi	a0,a0,1170 # 80020060 <icache>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	03a080e7          	jalr	58(ra) # 80000c10 <acquire>
    80003bde:	b741                	j	80003b5e <iput+0x26>

0000000080003be0 <iunlockput>:
{
    80003be0:	1101                	addi	sp,sp,-32
    80003be2:	ec06                	sd	ra,24(sp)
    80003be4:	e822                	sd	s0,16(sp)
    80003be6:	e426                	sd	s1,8(sp)
    80003be8:	1000                	addi	s0,sp,32
    80003bea:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	e54080e7          	jalr	-428(ra) # 80003a40 <iunlock>
  iput(ip);
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	f42080e7          	jalr	-190(ra) # 80003b38 <iput>
}
    80003bfe:	60e2                	ld	ra,24(sp)
    80003c00:	6442                	ld	s0,16(sp)
    80003c02:	64a2                	ld	s1,8(sp)
    80003c04:	6105                	addi	sp,sp,32
    80003c06:	8082                	ret

0000000080003c08 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c08:	1141                	addi	sp,sp,-16
    80003c0a:	e422                	sd	s0,8(sp)
    80003c0c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c0e:	411c                	lw	a5,0(a0)
    80003c10:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c12:	415c                	lw	a5,4(a0)
    80003c14:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c16:	04451783          	lh	a5,68(a0)
    80003c1a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c1e:	04a51783          	lh	a5,74(a0)
    80003c22:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c26:	04c56783          	lwu	a5,76(a0)
    80003c2a:	e99c                	sd	a5,16(a1)
}
    80003c2c:	6422                	ld	s0,8(sp)
    80003c2e:	0141                	addi	sp,sp,16
    80003c30:	8082                	ret

0000000080003c32 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	0ed7e863          	bltu	a5,a3,80003d24 <readi+0xf2>
{
    80003c38:	7159                	addi	sp,sp,-112
    80003c3a:	f486                	sd	ra,104(sp)
    80003c3c:	f0a2                	sd	s0,96(sp)
    80003c3e:	eca6                	sd	s1,88(sp)
    80003c40:	e8ca                	sd	s2,80(sp)
    80003c42:	e4ce                	sd	s3,72(sp)
    80003c44:	e0d2                	sd	s4,64(sp)
    80003c46:	fc56                	sd	s5,56(sp)
    80003c48:	f85a                	sd	s6,48(sp)
    80003c4a:	f45e                	sd	s7,40(sp)
    80003c4c:	f062                	sd	s8,32(sp)
    80003c4e:	ec66                	sd	s9,24(sp)
    80003c50:	e86a                	sd	s10,16(sp)
    80003c52:	e46e                	sd	s11,8(sp)
    80003c54:	1880                	addi	s0,sp,112
    80003c56:	8baa                	mv	s7,a0
    80003c58:	8c2e                	mv	s8,a1
    80003c5a:	8ab2                	mv	s5,a2
    80003c5c:	84b6                	mv	s1,a3
    80003c5e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c60:	9f35                	addw	a4,a4,a3
    return 0;
    80003c62:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c64:	08d76f63          	bltu	a4,a3,80003d02 <readi+0xd0>
  if(off + n > ip->size)
    80003c68:	00e7f463          	bgeu	a5,a4,80003c70 <readi+0x3e>
    n = ip->size - off;
    80003c6c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c70:	0a0b0863          	beqz	s6,80003d20 <readi+0xee>
    80003c74:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c76:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c7a:	5cfd                	li	s9,-1
    80003c7c:	a82d                	j	80003cb6 <readi+0x84>
    80003c7e:	020a1d93          	slli	s11,s4,0x20
    80003c82:	020ddd93          	srli	s11,s11,0x20
    80003c86:	05890613          	addi	a2,s2,88
    80003c8a:	86ee                	mv	a3,s11
    80003c8c:	963a                	add	a2,a2,a4
    80003c8e:	85d6                	mv	a1,s5
    80003c90:	8562                	mv	a0,s8
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	b2e080e7          	jalr	-1234(ra) # 800027c0 <either_copyout>
    80003c9a:	05950d63          	beq	a0,s9,80003cf4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	60c080e7          	jalr	1548(ra) # 800032ac <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca8:	013a09bb          	addw	s3,s4,s3
    80003cac:	009a04bb          	addw	s1,s4,s1
    80003cb0:	9aee                	add	s5,s5,s11
    80003cb2:	0569f663          	bgeu	s3,s6,80003cfe <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb6:	000ba903          	lw	s2,0(s7)
    80003cba:	00a4d59b          	srliw	a1,s1,0xa
    80003cbe:	855e                	mv	a0,s7
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	8b0080e7          	jalr	-1872(ra) # 80003570 <bmap>
    80003cc8:	0005059b          	sext.w	a1,a0
    80003ccc:	854a                	mv	a0,s2
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	4ae080e7          	jalr	1198(ra) # 8000317c <bread>
    80003cd6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd8:	3ff4f713          	andi	a4,s1,1023
    80003cdc:	40ed07bb          	subw	a5,s10,a4
    80003ce0:	413b06bb          	subw	a3,s6,s3
    80003ce4:	8a3e                	mv	s4,a5
    80003ce6:	2781                	sext.w	a5,a5
    80003ce8:	0006861b          	sext.w	a2,a3
    80003cec:	f8f679e3          	bgeu	a2,a5,80003c7e <readi+0x4c>
    80003cf0:	8a36                	mv	s4,a3
    80003cf2:	b771                	j	80003c7e <readi+0x4c>
      brelse(bp);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	5b6080e7          	jalr	1462(ra) # 800032ac <brelse>
  }
  return tot;
    80003cfe:	0009851b          	sext.w	a0,s3
}
    80003d02:	70a6                	ld	ra,104(sp)
    80003d04:	7406                	ld	s0,96(sp)
    80003d06:	64e6                	ld	s1,88(sp)
    80003d08:	6946                	ld	s2,80(sp)
    80003d0a:	69a6                	ld	s3,72(sp)
    80003d0c:	6a06                	ld	s4,64(sp)
    80003d0e:	7ae2                	ld	s5,56(sp)
    80003d10:	7b42                	ld	s6,48(sp)
    80003d12:	7ba2                	ld	s7,40(sp)
    80003d14:	7c02                	ld	s8,32(sp)
    80003d16:	6ce2                	ld	s9,24(sp)
    80003d18:	6d42                	ld	s10,16(sp)
    80003d1a:	6da2                	ld	s11,8(sp)
    80003d1c:	6165                	addi	sp,sp,112
    80003d1e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d20:	89da                	mv	s3,s6
    80003d22:	bff1                	j	80003cfe <readi+0xcc>
    return 0;
    80003d24:	4501                	li	a0,0
}
    80003d26:	8082                	ret

0000000080003d28 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d28:	457c                	lw	a5,76(a0)
    80003d2a:	10d7e663          	bltu	a5,a3,80003e36 <writei+0x10e>
{
    80003d2e:	7159                	addi	sp,sp,-112
    80003d30:	f486                	sd	ra,104(sp)
    80003d32:	f0a2                	sd	s0,96(sp)
    80003d34:	eca6                	sd	s1,88(sp)
    80003d36:	e8ca                	sd	s2,80(sp)
    80003d38:	e4ce                	sd	s3,72(sp)
    80003d3a:	e0d2                	sd	s4,64(sp)
    80003d3c:	fc56                	sd	s5,56(sp)
    80003d3e:	f85a                	sd	s6,48(sp)
    80003d40:	f45e                	sd	s7,40(sp)
    80003d42:	f062                	sd	s8,32(sp)
    80003d44:	ec66                	sd	s9,24(sp)
    80003d46:	e86a                	sd	s10,16(sp)
    80003d48:	e46e                	sd	s11,8(sp)
    80003d4a:	1880                	addi	s0,sp,112
    80003d4c:	8baa                	mv	s7,a0
    80003d4e:	8c2e                	mv	s8,a1
    80003d50:	8ab2                	mv	s5,a2
    80003d52:	8936                	mv	s2,a3
    80003d54:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d56:	00e687bb          	addw	a5,a3,a4
    80003d5a:	0ed7e063          	bltu	a5,a3,80003e3a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d5e:	00043737          	lui	a4,0x43
    80003d62:	0cf76e63          	bltu	a4,a5,80003e3e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d66:	0a0b0763          	beqz	s6,80003e14 <writei+0xec>
    80003d6a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d70:	5cfd                	li	s9,-1
    80003d72:	a091                	j	80003db6 <writei+0x8e>
    80003d74:	02099d93          	slli	s11,s3,0x20
    80003d78:	020ddd93          	srli	s11,s11,0x20
    80003d7c:	05848513          	addi	a0,s1,88
    80003d80:	86ee                	mv	a3,s11
    80003d82:	8656                	mv	a2,s5
    80003d84:	85e2                	mv	a1,s8
    80003d86:	953a                	add	a0,a0,a4
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	a8e080e7          	jalr	-1394(ra) # 80002816 <either_copyin>
    80003d90:	07950263          	beq	a0,s9,80003df4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d94:	8526                	mv	a0,s1
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	77a080e7          	jalr	1914(ra) # 80004510 <log_write>
    brelse(bp);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	50c080e7          	jalr	1292(ra) # 800032ac <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da8:	01498a3b          	addw	s4,s3,s4
    80003dac:	0129893b          	addw	s2,s3,s2
    80003db0:	9aee                	add	s5,s5,s11
    80003db2:	056a7663          	bgeu	s4,s6,80003dfe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003db6:	000ba483          	lw	s1,0(s7)
    80003dba:	00a9559b          	srliw	a1,s2,0xa
    80003dbe:	855e                	mv	a0,s7
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	7b0080e7          	jalr	1968(ra) # 80003570 <bmap>
    80003dc8:	0005059b          	sext.w	a1,a0
    80003dcc:	8526                	mv	a0,s1
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	3ae080e7          	jalr	942(ra) # 8000317c <bread>
    80003dd6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd8:	3ff97713          	andi	a4,s2,1023
    80003ddc:	40ed07bb          	subw	a5,s10,a4
    80003de0:	414b06bb          	subw	a3,s6,s4
    80003de4:	89be                	mv	s3,a5
    80003de6:	2781                	sext.w	a5,a5
    80003de8:	0006861b          	sext.w	a2,a3
    80003dec:	f8f674e3          	bgeu	a2,a5,80003d74 <writei+0x4c>
    80003df0:	89b6                	mv	s3,a3
    80003df2:	b749                	j	80003d74 <writei+0x4c>
      brelse(bp);
    80003df4:	8526                	mv	a0,s1
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	4b6080e7          	jalr	1206(ra) # 800032ac <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003dfe:	04cba783          	lw	a5,76(s7)
    80003e02:	0127f463          	bgeu	a5,s2,80003e0a <writei+0xe2>
      ip->size = off;
    80003e06:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e0a:	855e                	mv	a0,s7
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	aa8080e7          	jalr	-1368(ra) # 800038b4 <iupdate>
  }

  return n;
    80003e14:	000b051b          	sext.w	a0,s6
}
    80003e18:	70a6                	ld	ra,104(sp)
    80003e1a:	7406                	ld	s0,96(sp)
    80003e1c:	64e6                	ld	s1,88(sp)
    80003e1e:	6946                	ld	s2,80(sp)
    80003e20:	69a6                	ld	s3,72(sp)
    80003e22:	6a06                	ld	s4,64(sp)
    80003e24:	7ae2                	ld	s5,56(sp)
    80003e26:	7b42                	ld	s6,48(sp)
    80003e28:	7ba2                	ld	s7,40(sp)
    80003e2a:	7c02                	ld	s8,32(sp)
    80003e2c:	6ce2                	ld	s9,24(sp)
    80003e2e:	6d42                	ld	s10,16(sp)
    80003e30:	6da2                	ld	s11,8(sp)
    80003e32:	6165                	addi	sp,sp,112
    80003e34:	8082                	ret
    return -1;
    80003e36:	557d                	li	a0,-1
}
    80003e38:	8082                	ret
    return -1;
    80003e3a:	557d                	li	a0,-1
    80003e3c:	bff1                	j	80003e18 <writei+0xf0>
    return -1;
    80003e3e:	557d                	li	a0,-1
    80003e40:	bfe1                	j	80003e18 <writei+0xf0>

0000000080003e42 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e42:	1141                	addi	sp,sp,-16
    80003e44:	e406                	sd	ra,8(sp)
    80003e46:	e022                	sd	s0,0(sp)
    80003e48:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e4a:	4639                	li	a2,14
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	f9c080e7          	jalr	-100(ra) # 80000de8 <strncmp>
}
    80003e54:	60a2                	ld	ra,8(sp)
    80003e56:	6402                	ld	s0,0(sp)
    80003e58:	0141                	addi	sp,sp,16
    80003e5a:	8082                	ret

0000000080003e5c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5c:	7139                	addi	sp,sp,-64
    80003e5e:	fc06                	sd	ra,56(sp)
    80003e60:	f822                	sd	s0,48(sp)
    80003e62:	f426                	sd	s1,40(sp)
    80003e64:	f04a                	sd	s2,32(sp)
    80003e66:	ec4e                	sd	s3,24(sp)
    80003e68:	e852                	sd	s4,16(sp)
    80003e6a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6c:	04451703          	lh	a4,68(a0)
    80003e70:	4785                	li	a5,1
    80003e72:	00f71a63          	bne	a4,a5,80003e86 <dirlookup+0x2a>
    80003e76:	892a                	mv	s2,a0
    80003e78:	89ae                	mv	s3,a1
    80003e7a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7c:	457c                	lw	a5,76(a0)
    80003e7e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e80:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	e79d                	bnez	a5,80003eb0 <dirlookup+0x54>
    80003e84:	a8a5                	j	80003efc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	82250513          	addi	a0,a0,-2014 # 800086a8 <syscalls+0x1a0>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6ba080e7          	jalr	1722(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003e96:	00005517          	auipc	a0,0x5
    80003e9a:	82a50513          	addi	a0,a0,-2006 # 800086c0 <syscalls+0x1b8>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6aa080e7          	jalr	1706(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea6:	24c1                	addiw	s1,s1,16
    80003ea8:	04c92783          	lw	a5,76(s2)
    80003eac:	04f4f763          	bgeu	s1,a5,80003efa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb0:	4741                	li	a4,16
    80003eb2:	86a6                	mv	a3,s1
    80003eb4:	fc040613          	addi	a2,s0,-64
    80003eb8:	4581                	li	a1,0
    80003eba:	854a                	mv	a0,s2
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	d76080e7          	jalr	-650(ra) # 80003c32 <readi>
    80003ec4:	47c1                	li	a5,16
    80003ec6:	fcf518e3          	bne	a0,a5,80003e96 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eca:	fc045783          	lhu	a5,-64(s0)
    80003ece:	dfe1                	beqz	a5,80003ea6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed0:	fc240593          	addi	a1,s0,-62
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	f6c080e7          	jalr	-148(ra) # 80003e42 <namecmp>
    80003ede:	f561                	bnez	a0,80003ea6 <dirlookup+0x4a>
      if(poff)
    80003ee0:	000a0463          	beqz	s4,80003ee8 <dirlookup+0x8c>
        *poff = off;
    80003ee4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ee8:	fc045583          	lhu	a1,-64(s0)
    80003eec:	00092503          	lw	a0,0(s2)
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	75a080e7          	jalr	1882(ra) # 8000364a <iget>
    80003ef8:	a011                	j	80003efc <dirlookup+0xa0>
  return 0;
    80003efa:	4501                	li	a0,0
}
    80003efc:	70e2                	ld	ra,56(sp)
    80003efe:	7442                	ld	s0,48(sp)
    80003f00:	74a2                	ld	s1,40(sp)
    80003f02:	7902                	ld	s2,32(sp)
    80003f04:	69e2                	ld	s3,24(sp)
    80003f06:	6a42                	ld	s4,16(sp)
    80003f08:	6121                	addi	sp,sp,64
    80003f0a:	8082                	ret

0000000080003f0c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0c:	711d                	addi	sp,sp,-96
    80003f0e:	ec86                	sd	ra,88(sp)
    80003f10:	e8a2                	sd	s0,80(sp)
    80003f12:	e4a6                	sd	s1,72(sp)
    80003f14:	e0ca                	sd	s2,64(sp)
    80003f16:	fc4e                	sd	s3,56(sp)
    80003f18:	f852                	sd	s4,48(sp)
    80003f1a:	f456                	sd	s5,40(sp)
    80003f1c:	f05a                	sd	s6,32(sp)
    80003f1e:	ec5e                	sd	s7,24(sp)
    80003f20:	e862                	sd	s8,16(sp)
    80003f22:	e466                	sd	s9,8(sp)
    80003f24:	1080                	addi	s0,sp,96
    80003f26:	84aa                	mv	s1,a0
    80003f28:	8b2e                	mv	s6,a1
    80003f2a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2c:	00054703          	lbu	a4,0(a0)
    80003f30:	02f00793          	li	a5,47
    80003f34:	02f70363          	beq	a4,a5,80003f5a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f38:	ffffe097          	auipc	ra,0xffffe
    80003f3c:	c84080e7          	jalr	-892(ra) # 80001bbc <myproc>
    80003f40:	15853503          	ld	a0,344(a0)
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	9fc080e7          	jalr	-1540(ra) # 80003940 <idup>
    80003f4c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f4e:	02f00913          	li	s2,47
  len = path - s;
    80003f52:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f54:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f56:	4c05                	li	s8,1
    80003f58:	a865                	j	80004010 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f5a:	4585                	li	a1,1
    80003f5c:	4505                	li	a0,1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	6ec080e7          	jalr	1772(ra) # 8000364a <iget>
    80003f66:	89aa                	mv	s3,a0
    80003f68:	b7dd                	j	80003f4e <namex+0x42>
      iunlockput(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	c74080e7          	jalr	-908(ra) # 80003be0 <iunlockput>
      return 0;
    80003f74:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f76:	854e                	mv	a0,s3
    80003f78:	60e6                	ld	ra,88(sp)
    80003f7a:	6446                	ld	s0,80(sp)
    80003f7c:	64a6                	ld	s1,72(sp)
    80003f7e:	6906                	ld	s2,64(sp)
    80003f80:	79e2                	ld	s3,56(sp)
    80003f82:	7a42                	ld	s4,48(sp)
    80003f84:	7aa2                	ld	s5,40(sp)
    80003f86:	7b02                	ld	s6,32(sp)
    80003f88:	6be2                	ld	s7,24(sp)
    80003f8a:	6c42                	ld	s8,16(sp)
    80003f8c:	6ca2                	ld	s9,8(sp)
    80003f8e:	6125                	addi	sp,sp,96
    80003f90:	8082                	ret
      iunlock(ip);
    80003f92:	854e                	mv	a0,s3
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	aac080e7          	jalr	-1364(ra) # 80003a40 <iunlock>
      return ip;
    80003f9c:	bfe9                	j	80003f76 <namex+0x6a>
      iunlockput(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	c40080e7          	jalr	-960(ra) # 80003be0 <iunlockput>
      return 0;
    80003fa8:	89d2                	mv	s3,s4
    80003faa:	b7f1                	j	80003f76 <namex+0x6a>
  len = path - s;
    80003fac:	40b48633          	sub	a2,s1,a1
    80003fb0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fb4:	094cd463          	bge	s9,s4,8000403c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fb8:	4639                	li	a2,14
    80003fba:	8556                	mv	a0,s5
    80003fbc:	ffffd097          	auipc	ra,0xffffd
    80003fc0:	db0080e7          	jalr	-592(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003fc4:	0004c783          	lbu	a5,0(s1)
    80003fc8:	01279763          	bne	a5,s2,80003fd6 <namex+0xca>
    path++;
    80003fcc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	ff278de3          	beq	a5,s2,80003fcc <namex+0xc0>
    ilock(ip);
    80003fd6:	854e                	mv	a0,s3
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	9a6080e7          	jalr	-1626(ra) # 8000397e <ilock>
    if(ip->type != T_DIR){
    80003fe0:	04499783          	lh	a5,68(s3)
    80003fe4:	f98793e3          	bne	a5,s8,80003f6a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fe8:	000b0563          	beqz	s6,80003ff2 <namex+0xe6>
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	d3cd                	beqz	a5,80003f92 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff2:	865e                	mv	a2,s7
    80003ff4:	85d6                	mv	a1,s5
    80003ff6:	854e                	mv	a0,s3
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	e64080e7          	jalr	-412(ra) # 80003e5c <dirlookup>
    80004000:	8a2a                	mv	s4,a0
    80004002:	dd51                	beqz	a0,80003f9e <namex+0x92>
    iunlockput(ip);
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	bda080e7          	jalr	-1062(ra) # 80003be0 <iunlockput>
    ip = next;
    8000400e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	05279763          	bne	a5,s2,80004062 <namex+0x156>
    path++;
    80004018:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	ff278de3          	beq	a5,s2,80004018 <namex+0x10c>
  if(*path == 0)
    80004022:	c79d                	beqz	a5,80004050 <namex+0x144>
    path++;
    80004024:	85a6                	mv	a1,s1
  len = path - s;
    80004026:	8a5e                	mv	s4,s7
    80004028:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000402a:	01278963          	beq	a5,s2,8000403c <namex+0x130>
    8000402e:	dfbd                	beqz	a5,80003fac <namex+0xa0>
    path++;
    80004030:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	ff279ce3          	bne	a5,s2,8000402e <namex+0x122>
    8000403a:	bf8d                	j	80003fac <namex+0xa0>
    memmove(name, s, len);
    8000403c:	2601                	sext.w	a2,a2
    8000403e:	8556                	mv	a0,s5
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	d2c080e7          	jalr	-724(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004048:	9a56                	add	s4,s4,s5
    8000404a:	000a0023          	sb	zero,0(s4)
    8000404e:	bf9d                	j	80003fc4 <namex+0xb8>
  if(nameiparent){
    80004050:	f20b03e3          	beqz	s6,80003f76 <namex+0x6a>
    iput(ip);
    80004054:	854e                	mv	a0,s3
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	ae2080e7          	jalr	-1310(ra) # 80003b38 <iput>
    return 0;
    8000405e:	4981                	li	s3,0
    80004060:	bf19                	j	80003f76 <namex+0x6a>
  if(*path == 0)
    80004062:	d7fd                	beqz	a5,80004050 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004064:	0004c783          	lbu	a5,0(s1)
    80004068:	85a6                	mv	a1,s1
    8000406a:	b7d1                	j	8000402e <namex+0x122>

000000008000406c <dirlink>:
{
    8000406c:	7139                	addi	sp,sp,-64
    8000406e:	fc06                	sd	ra,56(sp)
    80004070:	f822                	sd	s0,48(sp)
    80004072:	f426                	sd	s1,40(sp)
    80004074:	f04a                	sd	s2,32(sp)
    80004076:	ec4e                	sd	s3,24(sp)
    80004078:	e852                	sd	s4,16(sp)
    8000407a:	0080                	addi	s0,sp,64
    8000407c:	892a                	mv	s2,a0
    8000407e:	8a2e                	mv	s4,a1
    80004080:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004082:	4601                	li	a2,0
    80004084:	00000097          	auipc	ra,0x0
    80004088:	dd8080e7          	jalr	-552(ra) # 80003e5c <dirlookup>
    8000408c:	e93d                	bnez	a0,80004102 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408e:	04c92483          	lw	s1,76(s2)
    80004092:	c49d                	beqz	s1,800040c0 <dirlink+0x54>
    80004094:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004096:	4741                	li	a4,16
    80004098:	86a6                	mv	a3,s1
    8000409a:	fc040613          	addi	a2,s0,-64
    8000409e:	4581                	li	a1,0
    800040a0:	854a                	mv	a0,s2
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	b90080e7          	jalr	-1136(ra) # 80003c32 <readi>
    800040aa:	47c1                	li	a5,16
    800040ac:	06f51163          	bne	a0,a5,8000410e <dirlink+0xa2>
    if(de.inum == 0)
    800040b0:	fc045783          	lhu	a5,-64(s0)
    800040b4:	c791                	beqz	a5,800040c0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b6:	24c1                	addiw	s1,s1,16
    800040b8:	04c92783          	lw	a5,76(s2)
    800040bc:	fcf4ede3          	bltu	s1,a5,80004096 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c0:	4639                	li	a2,14
    800040c2:	85d2                	mv	a1,s4
    800040c4:	fc240513          	addi	a0,s0,-62
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	d5c080e7          	jalr	-676(ra) # 80000e24 <strncpy>
  de.inum = inum;
    800040d0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d4:	4741                	li	a4,16
    800040d6:	86a6                	mv	a3,s1
    800040d8:	fc040613          	addi	a2,s0,-64
    800040dc:	4581                	li	a1,0
    800040de:	854a                	mv	a0,s2
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	c48080e7          	jalr	-952(ra) # 80003d28 <writei>
    800040e8:	872a                	mv	a4,a0
    800040ea:	47c1                	li	a5,16
  return 0;
    800040ec:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ee:	02f71863          	bne	a4,a5,8000411e <dirlink+0xb2>
}
    800040f2:	70e2                	ld	ra,56(sp)
    800040f4:	7442                	ld	s0,48(sp)
    800040f6:	74a2                	ld	s1,40(sp)
    800040f8:	7902                	ld	s2,32(sp)
    800040fa:	69e2                	ld	s3,24(sp)
    800040fc:	6a42                	ld	s4,16(sp)
    800040fe:	6121                	addi	sp,sp,64
    80004100:	8082                	ret
    iput(ip);
    80004102:	00000097          	auipc	ra,0x0
    80004106:	a36080e7          	jalr	-1482(ra) # 80003b38 <iput>
    return -1;
    8000410a:	557d                	li	a0,-1
    8000410c:	b7dd                	j	800040f2 <dirlink+0x86>
      panic("dirlink read");
    8000410e:	00004517          	auipc	a0,0x4
    80004112:	5c250513          	addi	a0,a0,1474 # 800086d0 <syscalls+0x1c8>
    80004116:	ffffc097          	auipc	ra,0xffffc
    8000411a:	432080e7          	jalr	1074(ra) # 80000548 <panic>
    panic("dirlink");
    8000411e:	00004517          	auipc	a0,0x4
    80004122:	6e250513          	addi	a0,a0,1762 # 80008800 <syscalls+0x2f8>
    80004126:	ffffc097          	auipc	ra,0xffffc
    8000412a:	422080e7          	jalr	1058(ra) # 80000548 <panic>

000000008000412e <namei>:

struct inode*
namei(char *path)
{
    8000412e:	1101                	addi	sp,sp,-32
    80004130:	ec06                	sd	ra,24(sp)
    80004132:	e822                	sd	s0,16(sp)
    80004134:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004136:	fe040613          	addi	a2,s0,-32
    8000413a:	4581                	li	a1,0
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	dd0080e7          	jalr	-560(ra) # 80003f0c <namex>
}
    80004144:	60e2                	ld	ra,24(sp)
    80004146:	6442                	ld	s0,16(sp)
    80004148:	6105                	addi	sp,sp,32
    8000414a:	8082                	ret

000000008000414c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000414c:	1141                	addi	sp,sp,-16
    8000414e:	e406                	sd	ra,8(sp)
    80004150:	e022                	sd	s0,0(sp)
    80004152:	0800                	addi	s0,sp,16
    80004154:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004156:	4585                	li	a1,1
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	db4080e7          	jalr	-588(ra) # 80003f0c <namex>
}
    80004160:	60a2                	ld	ra,8(sp)
    80004162:	6402                	ld	s0,0(sp)
    80004164:	0141                	addi	sp,sp,16
    80004166:	8082                	ret

0000000080004168 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004168:	1101                	addi	sp,sp,-32
    8000416a:	ec06                	sd	ra,24(sp)
    8000416c:	e822                	sd	s0,16(sp)
    8000416e:	e426                	sd	s1,8(sp)
    80004170:	e04a                	sd	s2,0(sp)
    80004172:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004174:	0001e917          	auipc	s2,0x1e
    80004178:	99490913          	addi	s2,s2,-1644 # 80021b08 <log>
    8000417c:	01892583          	lw	a1,24(s2)
    80004180:	02892503          	lw	a0,40(s2)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	ff8080e7          	jalr	-8(ra) # 8000317c <bread>
    8000418c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000418e:	02c92683          	lw	a3,44(s2)
    80004192:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004194:	02d05763          	blez	a3,800041c2 <write_head+0x5a>
    80004198:	0001e797          	auipc	a5,0x1e
    8000419c:	9a078793          	addi	a5,a5,-1632 # 80021b38 <log+0x30>
    800041a0:	05c50713          	addi	a4,a0,92
    800041a4:	36fd                	addiw	a3,a3,-1
    800041a6:	1682                	slli	a3,a3,0x20
    800041a8:	9281                	srli	a3,a3,0x20
    800041aa:	068a                	slli	a3,a3,0x2
    800041ac:	0001e617          	auipc	a2,0x1e
    800041b0:	99060613          	addi	a2,a2,-1648 # 80021b3c <log+0x34>
    800041b4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b6:	4390                	lw	a2,0(a5)
    800041b8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ba:	0791                	addi	a5,a5,4
    800041bc:	0711                	addi	a4,a4,4
    800041be:	fed79ce3          	bne	a5,a3,800041b6 <write_head+0x4e>
  }
  bwrite(buf);
    800041c2:	8526                	mv	a0,s1
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	0aa080e7          	jalr	170(ra) # 8000326e <bwrite>
  brelse(buf);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	0de080e7          	jalr	222(ra) # 800032ac <brelse>
}
    800041d6:	60e2                	ld	ra,24(sp)
    800041d8:	6442                	ld	s0,16(sp)
    800041da:	64a2                	ld	s1,8(sp)
    800041dc:	6902                	ld	s2,0(sp)
    800041de:	6105                	addi	sp,sp,32
    800041e0:	8082                	ret

00000000800041e2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	0001e797          	auipc	a5,0x1e
    800041e6:	9527a783          	lw	a5,-1710(a5) # 80021b34 <log+0x2c>
    800041ea:	0af05663          	blez	a5,80004296 <install_trans+0xb4>
{
    800041ee:	7139                	addi	sp,sp,-64
    800041f0:	fc06                	sd	ra,56(sp)
    800041f2:	f822                	sd	s0,48(sp)
    800041f4:	f426                	sd	s1,40(sp)
    800041f6:	f04a                	sd	s2,32(sp)
    800041f8:	ec4e                	sd	s3,24(sp)
    800041fa:	e852                	sd	s4,16(sp)
    800041fc:	e456                	sd	s5,8(sp)
    800041fe:	0080                	addi	s0,sp,64
    80004200:	0001ea97          	auipc	s5,0x1e
    80004204:	938a8a93          	addi	s5,s5,-1736 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004208:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420a:	0001e997          	auipc	s3,0x1e
    8000420e:	8fe98993          	addi	s3,s3,-1794 # 80021b08 <log>
    80004212:	0189a583          	lw	a1,24(s3)
    80004216:	014585bb          	addw	a1,a1,s4
    8000421a:	2585                	addiw	a1,a1,1
    8000421c:	0289a503          	lw	a0,40(s3)
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	f5c080e7          	jalr	-164(ra) # 8000317c <bread>
    80004228:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000422a:	000aa583          	lw	a1,0(s5)
    8000422e:	0289a503          	lw	a0,40(s3)
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	f4a080e7          	jalr	-182(ra) # 8000317c <bread>
    8000423a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000423c:	40000613          	li	a2,1024
    80004240:	05890593          	addi	a1,s2,88
    80004244:	05850513          	addi	a0,a0,88
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	b24080e7          	jalr	-1244(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004250:	8526                	mv	a0,s1
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	01c080e7          	jalr	28(ra) # 8000326e <bwrite>
    bunpin(dbuf);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	12a080e7          	jalr	298(ra) # 80003386 <bunpin>
    brelse(lbuf);
    80004264:	854a                	mv	a0,s2
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	046080e7          	jalr	70(ra) # 800032ac <brelse>
    brelse(dbuf);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	03c080e7          	jalr	60(ra) # 800032ac <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004278:	2a05                	addiw	s4,s4,1
    8000427a:	0a91                	addi	s5,s5,4
    8000427c:	02c9a783          	lw	a5,44(s3)
    80004280:	f8fa49e3          	blt	s4,a5,80004212 <install_trans+0x30>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6aa2                	ld	s5,8(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    80004296:	8082                	ret

0000000080004298 <initlog>:
{
    80004298:	7179                	addi	sp,sp,-48
    8000429a:	f406                	sd	ra,40(sp)
    8000429c:	f022                	sd	s0,32(sp)
    8000429e:	ec26                	sd	s1,24(sp)
    800042a0:	e84a                	sd	s2,16(sp)
    800042a2:	e44e                	sd	s3,8(sp)
    800042a4:	1800                	addi	s0,sp,48
    800042a6:	892a                	mv	s2,a0
    800042a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042aa:	0001e497          	auipc	s1,0x1e
    800042ae:	85e48493          	addi	s1,s1,-1954 # 80021b08 <log>
    800042b2:	00004597          	auipc	a1,0x4
    800042b6:	42e58593          	addi	a1,a1,1070 # 800086e0 <syscalls+0x1d8>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	8c4080e7          	jalr	-1852(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    800042c4:	0149a583          	lw	a1,20(s3)
    800042c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042ca:	0109a783          	lw	a5,16(s3)
    800042ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d4:	854a                	mv	a0,s2
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	ea6080e7          	jalr	-346(ra) # 8000317c <bread>
  log.lh.n = lh->n;
    800042de:	4d3c                	lw	a5,88(a0)
    800042e0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	02f05563          	blez	a5,8000430c <initlog+0x74>
    800042e6:	05c50713          	addi	a4,a0,92
    800042ea:	0001e697          	auipc	a3,0x1e
    800042ee:	84e68693          	addi	a3,a3,-1970 # 80021b38 <log+0x30>
    800042f2:	37fd                	addiw	a5,a5,-1
    800042f4:	1782                	slli	a5,a5,0x20
    800042f6:	9381                	srli	a5,a5,0x20
    800042f8:	078a                	slli	a5,a5,0x2
    800042fa:	06050613          	addi	a2,a0,96
    800042fe:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004300:	4310                	lw	a2,0(a4)
    80004302:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0711                	addi	a4,a4,4
    80004306:	0691                	addi	a3,a3,4
    80004308:	fef71ce3          	bne	a4,a5,80004300 <initlog+0x68>
  brelse(buf);
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	fa0080e7          	jalr	-96(ra) # 800032ac <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004314:	00000097          	auipc	ra,0x0
    80004318:	ece080e7          	jalr	-306(ra) # 800041e2 <install_trans>
  log.lh.n = 0;
    8000431c:	0001e797          	auipc	a5,0x1e
    80004320:	8007ac23          	sw	zero,-2024(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004324:	00000097          	auipc	ra,0x0
    80004328:	e44080e7          	jalr	-444(ra) # 80004168 <write_head>
}
    8000432c:	70a2                	ld	ra,40(sp)
    8000432e:	7402                	ld	s0,32(sp)
    80004330:	64e2                	ld	s1,24(sp)
    80004332:	6942                	ld	s2,16(sp)
    80004334:	69a2                	ld	s3,8(sp)
    80004336:	6145                	addi	sp,sp,48
    80004338:	8082                	ret

000000008000433a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004346:	0001d517          	auipc	a0,0x1d
    8000434a:	7c250513          	addi	a0,a0,1986 # 80021b08 <log>
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	8c2080e7          	jalr	-1854(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004356:	0001d497          	auipc	s1,0x1d
    8000435a:	7b248493          	addi	s1,s1,1970 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435e:	4979                	li	s2,30
    80004360:	a039                	j	8000436e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004362:	85a6                	mv	a1,s1
    80004364:	8526                	mv	a0,s1
    80004366:	ffffe097          	auipc	ra,0xffffe
    8000436a:	1f8080e7          	jalr	504(ra) # 8000255e <sleep>
    if(log.committing){
    8000436e:	50dc                	lw	a5,36(s1)
    80004370:	fbed                	bnez	a5,80004362 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004372:	509c                	lw	a5,32(s1)
    80004374:	0017871b          	addiw	a4,a5,1
    80004378:	0007069b          	sext.w	a3,a4
    8000437c:	0027179b          	slliw	a5,a4,0x2
    80004380:	9fb9                	addw	a5,a5,a4
    80004382:	0017979b          	slliw	a5,a5,0x1
    80004386:	54d8                	lw	a4,44(s1)
    80004388:	9fb9                	addw	a5,a5,a4
    8000438a:	00f95963          	bge	s2,a5,8000439c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000438e:	85a6                	mv	a1,s1
    80004390:	8526                	mv	a0,s1
    80004392:	ffffe097          	auipc	ra,0xffffe
    80004396:	1cc080e7          	jalr	460(ra) # 8000255e <sleep>
    8000439a:	bfd1                	j	8000436e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000439c:	0001d517          	auipc	a0,0x1d
    800043a0:	76c50513          	addi	a0,a0,1900 # 80021b08 <log>
    800043a4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	91e080e7          	jalr	-1762(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043ba:	7139                	addi	sp,sp,-64
    800043bc:	fc06                	sd	ra,56(sp)
    800043be:	f822                	sd	s0,48(sp)
    800043c0:	f426                	sd	s1,40(sp)
    800043c2:	f04a                	sd	s2,32(sp)
    800043c4:	ec4e                	sd	s3,24(sp)
    800043c6:	e852                	sd	s4,16(sp)
    800043c8:	e456                	sd	s5,8(sp)
    800043ca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043cc:	0001d497          	auipc	s1,0x1d
    800043d0:	73c48493          	addi	s1,s1,1852 # 80021b08 <log>
    800043d4:	8526                	mv	a0,s1
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	83a080e7          	jalr	-1990(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800043de:	509c                	lw	a5,32(s1)
    800043e0:	37fd                	addiw	a5,a5,-1
    800043e2:	0007891b          	sext.w	s2,a5
    800043e6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043e8:	50dc                	lw	a5,36(s1)
    800043ea:	efb9                	bnez	a5,80004448 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ec:	06091663          	bnez	s2,80004458 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043f0:	0001d497          	auipc	s1,0x1d
    800043f4:	71848493          	addi	s1,s1,1816 # 80021b08 <log>
    800043f8:	4785                	li	a5,1
    800043fa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	8c6080e7          	jalr	-1850(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004406:	54dc                	lw	a5,44(s1)
    80004408:	06f04763          	bgtz	a5,80004476 <end_op+0xbc>
    acquire(&log.lock);
    8000440c:	0001d497          	auipc	s1,0x1d
    80004410:	6fc48493          	addi	s1,s1,1788 # 80021b08 <log>
    80004414:	8526                	mv	a0,s1
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7fa080e7          	jalr	2042(ra) # 80000c10 <acquire>
    log.committing = 0;
    8000441e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004422:	8526                	mv	a0,s1
    80004424:	ffffe097          	auipc	ra,0xffffe
    80004428:	2c0080e7          	jalr	704(ra) # 800026e4 <wakeup>
    release(&log.lock);
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	896080e7          	jalr	-1898(ra) # 80000cc4 <release>
}
    80004436:	70e2                	ld	ra,56(sp)
    80004438:	7442                	ld	s0,48(sp)
    8000443a:	74a2                	ld	s1,40(sp)
    8000443c:	7902                	ld	s2,32(sp)
    8000443e:	69e2                	ld	s3,24(sp)
    80004440:	6a42                	ld	s4,16(sp)
    80004442:	6aa2                	ld	s5,8(sp)
    80004444:	6121                	addi	sp,sp,64
    80004446:	8082                	ret
    panic("log.committing");
    80004448:	00004517          	auipc	a0,0x4
    8000444c:	2a050513          	addi	a0,a0,672 # 800086e8 <syscalls+0x1e0>
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	0f8080e7          	jalr	248(ra) # 80000548 <panic>
    wakeup(&log);
    80004458:	0001d497          	auipc	s1,0x1d
    8000445c:	6b048493          	addi	s1,s1,1712 # 80021b08 <log>
    80004460:	8526                	mv	a0,s1
    80004462:	ffffe097          	auipc	ra,0xffffe
    80004466:	282080e7          	jalr	642(ra) # 800026e4 <wakeup>
  release(&log.lock);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	858080e7          	jalr	-1960(ra) # 80000cc4 <release>
  if(do_commit){
    80004474:	b7c9                	j	80004436 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004476:	0001da97          	auipc	s5,0x1d
    8000447a:	6c2a8a93          	addi	s5,s5,1730 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000447e:	0001da17          	auipc	s4,0x1d
    80004482:	68aa0a13          	addi	s4,s4,1674 # 80021b08 <log>
    80004486:	018a2583          	lw	a1,24(s4)
    8000448a:	012585bb          	addw	a1,a1,s2
    8000448e:	2585                	addiw	a1,a1,1
    80004490:	028a2503          	lw	a0,40(s4)
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	ce8080e7          	jalr	-792(ra) # 8000317c <bread>
    8000449c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000449e:	000aa583          	lw	a1,0(s5)
    800044a2:	028a2503          	lw	a0,40(s4)
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	cd6080e7          	jalr	-810(ra) # 8000317c <bread>
    800044ae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b0:	40000613          	li	a2,1024
    800044b4:	05850593          	addi	a1,a0,88
    800044b8:	05848513          	addi	a0,s1,88
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	8b0080e7          	jalr	-1872(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	da8080e7          	jalr	-600(ra) # 8000326e <bwrite>
    brelse(from);
    800044ce:	854e                	mv	a0,s3
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	ddc080e7          	jalr	-548(ra) # 800032ac <brelse>
    brelse(to);
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	dd2080e7          	jalr	-558(ra) # 800032ac <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e2:	2905                	addiw	s2,s2,1
    800044e4:	0a91                	addi	s5,s5,4
    800044e6:	02ca2783          	lw	a5,44(s4)
    800044ea:	f8f94ee3          	blt	s2,a5,80004486 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	c7a080e7          	jalr	-902(ra) # 80004168 <write_head>
    install_trans(); // Now install writes to home locations
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	cec080e7          	jalr	-788(ra) # 800041e2 <install_trans>
    log.lh.n = 0;
    800044fe:	0001d797          	auipc	a5,0x1d
    80004502:	6207ab23          	sw	zero,1590(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	c62080e7          	jalr	-926(ra) # 80004168 <write_head>
    8000450e:	bdfd                	j	8000440c <end_op+0x52>

0000000080004510 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000451c:	0001d717          	auipc	a4,0x1d
    80004520:	61872703          	lw	a4,1560(a4) # 80021b34 <log+0x2c>
    80004524:	47f5                	li	a5,29
    80004526:	08e7c063          	blt	a5,a4,800045a6 <log_write+0x96>
    8000452a:	84aa                	mv	s1,a0
    8000452c:	0001d797          	auipc	a5,0x1d
    80004530:	5f87a783          	lw	a5,1528(a5) # 80021b24 <log+0x1c>
    80004534:	37fd                	addiw	a5,a5,-1
    80004536:	06f75863          	bge	a4,a5,800045a6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000453a:	0001d797          	auipc	a5,0x1d
    8000453e:	5ee7a783          	lw	a5,1518(a5) # 80021b28 <log+0x20>
    80004542:	06f05a63          	blez	a5,800045b6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004546:	0001d917          	auipc	s2,0x1d
    8000454a:	5c290913          	addi	s2,s2,1474 # 80021b08 <log>
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	6c0080e7          	jalr	1728(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004558:	02c92603          	lw	a2,44(s2)
    8000455c:	06c05563          	blez	a2,800045c6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004560:	44cc                	lw	a1,12(s1)
    80004562:	0001d717          	auipc	a4,0x1d
    80004566:	5d670713          	addi	a4,a4,1494 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456c:	4314                	lw	a3,0(a4)
    8000456e:	04b68d63          	beq	a3,a1,800045c8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004572:	2785                	addiw	a5,a5,1
    80004574:	0711                	addi	a4,a4,4
    80004576:	fec79be3          	bne	a5,a2,8000456c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000457a:	0621                	addi	a2,a2,8
    8000457c:	060a                	slli	a2,a2,0x2
    8000457e:	0001d797          	auipc	a5,0x1d
    80004582:	58a78793          	addi	a5,a5,1418 # 80021b08 <log>
    80004586:	963e                	add	a2,a2,a5
    80004588:	44dc                	lw	a5,12(s1)
    8000458a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	dbc080e7          	jalr	-580(ra) # 8000334a <bpin>
    log.lh.n++;
    80004596:	0001d717          	auipc	a4,0x1d
    8000459a:	57270713          	addi	a4,a4,1394 # 80021b08 <log>
    8000459e:	575c                	lw	a5,44(a4)
    800045a0:	2785                	addiw	a5,a5,1
    800045a2:	d75c                	sw	a5,44(a4)
    800045a4:	a83d                	j	800045e2 <log_write+0xd2>
    panic("too big a transaction");
    800045a6:	00004517          	auipc	a0,0x4
    800045aa:	15250513          	addi	a0,a0,338 # 800086f8 <syscalls+0x1f0>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f9a080e7          	jalr	-102(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	15a50513          	addi	a0,a0,346 # 80008710 <syscalls+0x208>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045c6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045c8:	00878713          	addi	a4,a5,8
    800045cc:	00271693          	slli	a3,a4,0x2
    800045d0:	0001d717          	auipc	a4,0x1d
    800045d4:	53870713          	addi	a4,a4,1336 # 80021b08 <log>
    800045d8:	9736                	add	a4,a4,a3
    800045da:	44d4                	lw	a3,12(s1)
    800045dc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045de:	faf607e3          	beq	a2,a5,8000458c <log_write+0x7c>
  }
  release(&log.lock);
    800045e2:	0001d517          	auipc	a0,0x1d
    800045e6:	52650513          	addi	a0,a0,1318 # 80021b08 <log>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6da080e7          	jalr	1754(ra) # 80000cc4 <release>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
    8000460c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460e:	00004597          	auipc	a1,0x4
    80004612:	12258593          	addi	a1,a1,290 # 80008730 <syscalls+0x228>
    80004616:	0521                	addi	a0,a0,8
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	568080e7          	jalr	1384(ra) # 80000b80 <initlock>
  lk->name = name;
    80004620:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004624:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004628:	0204a423          	sw	zero,40(s1)
}
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6902                	ld	s2,0(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret

0000000080004638 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	e426                	sd	s1,8(sp)
    80004640:	e04a                	sd	s2,0(sp)
    80004642:	1000                	addi	s0,sp,32
    80004644:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004646:	00850913          	addi	s2,a0,8
    8000464a:	854a                	mv	a0,s2
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	5c4080e7          	jalr	1476(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004654:	409c                	lw	a5,0(s1)
    80004656:	cb89                	beqz	a5,80004668 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004658:	85ca                	mv	a1,s2
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffe097          	auipc	ra,0xffffe
    80004660:	f02080e7          	jalr	-254(ra) # 8000255e <sleep>
  while (lk->locked) {
    80004664:	409c                	lw	a5,0(s1)
    80004666:	fbed                	bnez	a5,80004658 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004668:	4785                	li	a5,1
    8000466a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000466c:	ffffd097          	auipc	ra,0xffffd
    80004670:	550080e7          	jalr	1360(ra) # 80001bbc <myproc>
    80004674:	5d1c                	lw	a5,56(a0)
    80004676:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004678:	854a                	mv	a0,s2
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	64a080e7          	jalr	1610(ra) # 80000cc4 <release>
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	e04a                	sd	s2,0(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000469c:	00850913          	addi	s2,a0,8
    800046a0:	854a                	mv	a0,s2
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	56e080e7          	jalr	1390(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800046aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ae:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046b2:	8526                	mv	a0,s1
    800046b4:	ffffe097          	auipc	ra,0xffffe
    800046b8:	030080e7          	jalr	48(ra) # 800026e4 <wakeup>
  release(&lk->lk);
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	606080e7          	jalr	1542(ra) # 80000cc4 <release>
}
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6902                	ld	s2,0(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret

00000000800046d2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046d2:	7179                	addi	sp,sp,-48
    800046d4:	f406                	sd	ra,40(sp)
    800046d6:	f022                	sd	s0,32(sp)
    800046d8:	ec26                	sd	s1,24(sp)
    800046da:	e84a                	sd	s2,16(sp)
    800046dc:	e44e                	sd	s3,8(sp)
    800046de:	1800                	addi	s0,sp,48
    800046e0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046e2:	00850913          	addi	s2,a0,8
    800046e6:	854a                	mv	a0,s2
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	528080e7          	jalr	1320(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f0:	409c                	lw	a5,0(s1)
    800046f2:	ef99                	bnez	a5,80004710 <holdingsleep+0x3e>
    800046f4:	4481                	li	s1,0
  release(&lk->lk);
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	5cc080e7          	jalr	1484(ra) # 80000cc4 <release>
  return r;
}
    80004700:	8526                	mv	a0,s1
    80004702:	70a2                	ld	ra,40(sp)
    80004704:	7402                	ld	s0,32(sp)
    80004706:	64e2                	ld	s1,24(sp)
    80004708:	6942                	ld	s2,16(sp)
    8000470a:	69a2                	ld	s3,8(sp)
    8000470c:	6145                	addi	sp,sp,48
    8000470e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004710:	0284a983          	lw	s3,40(s1)
    80004714:	ffffd097          	auipc	ra,0xffffd
    80004718:	4a8080e7          	jalr	1192(ra) # 80001bbc <myproc>
    8000471c:	5d04                	lw	s1,56(a0)
    8000471e:	413484b3          	sub	s1,s1,s3
    80004722:	0014b493          	seqz	s1,s1
    80004726:	bfc1                	j	800046f6 <holdingsleep+0x24>

0000000080004728 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004728:	1141                	addi	sp,sp,-16
    8000472a:	e406                	sd	ra,8(sp)
    8000472c:	e022                	sd	s0,0(sp)
    8000472e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004730:	00004597          	auipc	a1,0x4
    80004734:	01058593          	addi	a1,a1,16 # 80008740 <syscalls+0x238>
    80004738:	0001d517          	auipc	a0,0x1d
    8000473c:	51850513          	addi	a0,a0,1304 # 80021c50 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	440080e7          	jalr	1088(ra) # 80000b80 <initlock>
}
    80004748:	60a2                	ld	ra,8(sp)
    8000474a:	6402                	ld	s0,0(sp)
    8000474c:	0141                	addi	sp,sp,16
    8000474e:	8082                	ret

0000000080004750 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000475a:	0001d517          	auipc	a0,0x1d
    8000475e:	4f650513          	addi	a0,a0,1270 # 80021c50 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	4ae080e7          	jalr	1198(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476a:	0001d497          	auipc	s1,0x1d
    8000476e:	4fe48493          	addi	s1,s1,1278 # 80021c68 <ftable+0x18>
    80004772:	0001e717          	auipc	a4,0x1e
    80004776:	49670713          	addi	a4,a4,1174 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000477a:	40dc                	lw	a5,4(s1)
    8000477c:	cf99                	beqz	a5,8000479a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477e:	02848493          	addi	s1,s1,40
    80004782:	fee49ce3          	bne	s1,a4,8000477a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004786:	0001d517          	auipc	a0,0x1d
    8000478a:	4ca50513          	addi	a0,a0,1226 # 80021c50 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	536080e7          	jalr	1334(ra) # 80000cc4 <release>
  return 0;
    80004796:	4481                	li	s1,0
    80004798:	a819                	j	800047ae <filealloc+0x5e>
      f->ref = 1;
    8000479a:	4785                	li	a5,1
    8000479c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479e:	0001d517          	auipc	a0,0x1d
    800047a2:	4b250513          	addi	a0,a0,1202 # 80021c50 <ftable>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	51e080e7          	jalr	1310(ra) # 80000cc4 <release>
}
    800047ae:	8526                	mv	a0,s1
    800047b0:	60e2                	ld	ra,24(sp)
    800047b2:	6442                	ld	s0,16(sp)
    800047b4:	64a2                	ld	s1,8(sp)
    800047b6:	6105                	addi	sp,sp,32
    800047b8:	8082                	ret

00000000800047ba <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047ba:	1101                	addi	sp,sp,-32
    800047bc:	ec06                	sd	ra,24(sp)
    800047be:	e822                	sd	s0,16(sp)
    800047c0:	e426                	sd	s1,8(sp)
    800047c2:	1000                	addi	s0,sp,32
    800047c4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	48a50513          	addi	a0,a0,1162 # 80021c50 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	442080e7          	jalr	1090(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047d6:	40dc                	lw	a5,4(s1)
    800047d8:	02f05263          	blez	a5,800047fc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047dc:	2785                	addiw	a5,a5,1
    800047de:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e0:	0001d517          	auipc	a0,0x1d
    800047e4:	47050513          	addi	a0,a0,1136 # 80021c50 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	4dc080e7          	jalr	1244(ra) # 80000cc4 <release>
  return f;
}
    800047f0:	8526                	mv	a0,s1
    800047f2:	60e2                	ld	ra,24(sp)
    800047f4:	6442                	ld	s0,16(sp)
    800047f6:	64a2                	ld	s1,8(sp)
    800047f8:	6105                	addi	sp,sp,32
    800047fa:	8082                	ret
    panic("filedup");
    800047fc:	00004517          	auipc	a0,0x4
    80004800:	f4c50513          	addi	a0,a0,-180 # 80008748 <syscalls+0x240>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	d44080e7          	jalr	-700(ra) # 80000548 <panic>

000000008000480c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000480c:	7139                	addi	sp,sp,-64
    8000480e:	fc06                	sd	ra,56(sp)
    80004810:	f822                	sd	s0,48(sp)
    80004812:	f426                	sd	s1,40(sp)
    80004814:	f04a                	sd	s2,32(sp)
    80004816:	ec4e                	sd	s3,24(sp)
    80004818:	e852                	sd	s4,16(sp)
    8000481a:	e456                	sd	s5,8(sp)
    8000481c:	0080                	addi	s0,sp,64
    8000481e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004820:	0001d517          	auipc	a0,0x1d
    80004824:	43050513          	addi	a0,a0,1072 # 80021c50 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	3e8080e7          	jalr	1000(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004830:	40dc                	lw	a5,4(s1)
    80004832:	06f05163          	blez	a5,80004894 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004836:	37fd                	addiw	a5,a5,-1
    80004838:	0007871b          	sext.w	a4,a5
    8000483c:	c0dc                	sw	a5,4(s1)
    8000483e:	06e04363          	bgtz	a4,800048a4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004842:	0004a903          	lw	s2,0(s1)
    80004846:	0094ca83          	lbu	s5,9(s1)
    8000484a:	0104ba03          	ld	s4,16(s1)
    8000484e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004852:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004856:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000485a:	0001d517          	auipc	a0,0x1d
    8000485e:	3f650513          	addi	a0,a0,1014 # 80021c50 <ftable>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	462080e7          	jalr	1122(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000486a:	4785                	li	a5,1
    8000486c:	04f90d63          	beq	s2,a5,800048c6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004870:	3979                	addiw	s2,s2,-2
    80004872:	4785                	li	a5,1
    80004874:	0527e063          	bltu	a5,s2,800048b4 <fileclose+0xa8>
    begin_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	ac2080e7          	jalr	-1342(ra) # 8000433a <begin_op>
    iput(ff.ip);
    80004880:	854e                	mv	a0,s3
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	2b6080e7          	jalr	694(ra) # 80003b38 <iput>
    end_op();
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	b30080e7          	jalr	-1232(ra) # 800043ba <end_op>
    80004892:	a00d                	j	800048b4 <fileclose+0xa8>
    panic("fileclose");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	ebc50513          	addi	a0,a0,-324 # 80008750 <syscalls+0x248>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
    release(&ftable.lock);
    800048a4:	0001d517          	auipc	a0,0x1d
    800048a8:	3ac50513          	addi	a0,a0,940 # 80021c50 <ftable>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	418080e7          	jalr	1048(ra) # 80000cc4 <release>
  }
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6aa2                	ld	s5,8(sp)
    800048c2:	6121                	addi	sp,sp,64
    800048c4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c6:	85d6                	mv	a1,s5
    800048c8:	8552                	mv	a0,s4
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	372080e7          	jalr	882(ra) # 80004c3c <pipeclose>
    800048d2:	b7cd                	j	800048b4 <fileclose+0xa8>

00000000800048d4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d4:	715d                	addi	sp,sp,-80
    800048d6:	e486                	sd	ra,72(sp)
    800048d8:	e0a2                	sd	s0,64(sp)
    800048da:	fc26                	sd	s1,56(sp)
    800048dc:	f84a                	sd	s2,48(sp)
    800048de:	f44e                	sd	s3,40(sp)
    800048e0:	0880                	addi	s0,sp,80
    800048e2:	84aa                	mv	s1,a0
    800048e4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e6:	ffffd097          	auipc	ra,0xffffd
    800048ea:	2d6080e7          	jalr	726(ra) # 80001bbc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ee:	409c                	lw	a5,0(s1)
    800048f0:	37f9                	addiw	a5,a5,-2
    800048f2:	4705                	li	a4,1
    800048f4:	04f76763          	bltu	a4,a5,80004942 <filestat+0x6e>
    800048f8:	892a                	mv	s2,a0
    ilock(f->ip);
    800048fa:	6c88                	ld	a0,24(s1)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	082080e7          	jalr	130(ra) # 8000397e <ilock>
    stati(f->ip, &st);
    80004904:	fb840593          	addi	a1,s0,-72
    80004908:	6c88                	ld	a0,24(s1)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	2fe080e7          	jalr	766(ra) # 80003c08 <stati>
    iunlock(f->ip);
    80004912:	6c88                	ld	a0,24(s1)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	12c080e7          	jalr	300(ra) # 80003a40 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000491c:	46e1                	li	a3,24
    8000491e:	fb840613          	addi	a2,s0,-72
    80004922:	85ce                	mv	a1,s3
    80004924:	05093503          	ld	a0,80(s2)
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	f04080e7          	jalr	-252(ra) # 8000182c <copyout>
    80004930:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	6161                	addi	sp,sp,80
    80004940:	8082                	ret
  return -1;
    80004942:	557d                	li	a0,-1
    80004944:	bfc5                	j	80004934 <filestat+0x60>

0000000080004946 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004946:	7179                	addi	sp,sp,-48
    80004948:	f406                	sd	ra,40(sp)
    8000494a:	f022                	sd	s0,32(sp)
    8000494c:	ec26                	sd	s1,24(sp)
    8000494e:	e84a                	sd	s2,16(sp)
    80004950:	e44e                	sd	s3,8(sp)
    80004952:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004954:	00854783          	lbu	a5,8(a0)
    80004958:	c3d5                	beqz	a5,800049fc <fileread+0xb6>
    8000495a:	84aa                	mv	s1,a0
    8000495c:	89ae                	mv	s3,a1
    8000495e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004960:	411c                	lw	a5,0(a0)
    80004962:	4705                	li	a4,1
    80004964:	04e78963          	beq	a5,a4,800049b6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004968:	470d                	li	a4,3
    8000496a:	04e78d63          	beq	a5,a4,800049c4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496e:	4709                	li	a4,2
    80004970:	06e79e63          	bne	a5,a4,800049ec <fileread+0xa6>
    ilock(f->ip);
    80004974:	6d08                	ld	a0,24(a0)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	008080e7          	jalr	8(ra) # 8000397e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497e:	874a                	mv	a4,s2
    80004980:	5094                	lw	a3,32(s1)
    80004982:	864e                	mv	a2,s3
    80004984:	4585                	li	a1,1
    80004986:	6c88                	ld	a0,24(s1)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	2aa080e7          	jalr	682(ra) # 80003c32 <readi>
    80004990:	892a                	mv	s2,a0
    80004992:	00a05563          	blez	a0,8000499c <fileread+0x56>
      f->off += r;
    80004996:	509c                	lw	a5,32(s1)
    80004998:	9fa9                	addw	a5,a5,a0
    8000499a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000499c:	6c88                	ld	a0,24(s1)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	0a2080e7          	jalr	162(ra) # 80003a40 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a6:	854a                	mv	a0,s2
    800049a8:	70a2                	ld	ra,40(sp)
    800049aa:	7402                	ld	s0,32(sp)
    800049ac:	64e2                	ld	s1,24(sp)
    800049ae:	6942                	ld	s2,16(sp)
    800049b0:	69a2                	ld	s3,8(sp)
    800049b2:	6145                	addi	sp,sp,48
    800049b4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b6:	6908                	ld	a0,16(a0)
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	418080e7          	jalr	1048(ra) # 80004dd0 <piperead>
    800049c0:	892a                	mv	s2,a0
    800049c2:	b7d5                	j	800049a6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c4:	02451783          	lh	a5,36(a0)
    800049c8:	03079693          	slli	a3,a5,0x30
    800049cc:	92c1                	srli	a3,a3,0x30
    800049ce:	4725                	li	a4,9
    800049d0:	02d76863          	bltu	a4,a3,80004a00 <fileread+0xba>
    800049d4:	0792                	slli	a5,a5,0x4
    800049d6:	0001d717          	auipc	a4,0x1d
    800049da:	1da70713          	addi	a4,a4,474 # 80021bb0 <devsw>
    800049de:	97ba                	add	a5,a5,a4
    800049e0:	639c                	ld	a5,0(a5)
    800049e2:	c38d                	beqz	a5,80004a04 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e4:	4505                	li	a0,1
    800049e6:	9782                	jalr	a5
    800049e8:	892a                	mv	s2,a0
    800049ea:	bf75                	j	800049a6 <fileread+0x60>
    panic("fileread");
    800049ec:	00004517          	auipc	a0,0x4
    800049f0:	d7450513          	addi	a0,a0,-652 # 80008760 <syscalls+0x258>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>
    return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b765                	j	800049a6 <fileread+0x60>
      return -1;
    80004a00:	597d                	li	s2,-1
    80004a02:	b755                	j	800049a6 <fileread+0x60>
    80004a04:	597d                	li	s2,-1
    80004a06:	b745                	j	800049a6 <fileread+0x60>

0000000080004a08 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a08:	00954783          	lbu	a5,9(a0)
    80004a0c:	14078563          	beqz	a5,80004b56 <filewrite+0x14e>
{
    80004a10:	715d                	addi	sp,sp,-80
    80004a12:	e486                	sd	ra,72(sp)
    80004a14:	e0a2                	sd	s0,64(sp)
    80004a16:	fc26                	sd	s1,56(sp)
    80004a18:	f84a                	sd	s2,48(sp)
    80004a1a:	f44e                	sd	s3,40(sp)
    80004a1c:	f052                	sd	s4,32(sp)
    80004a1e:	ec56                	sd	s5,24(sp)
    80004a20:	e85a                	sd	s6,16(sp)
    80004a22:	e45e                	sd	s7,8(sp)
    80004a24:	e062                	sd	s8,0(sp)
    80004a26:	0880                	addi	s0,sp,80
    80004a28:	892a                	mv	s2,a0
    80004a2a:	8aae                	mv	s5,a1
    80004a2c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2e:	411c                	lw	a5,0(a0)
    80004a30:	4705                	li	a4,1
    80004a32:	02e78263          	beq	a5,a4,80004a56 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a36:	470d                	li	a4,3
    80004a38:	02e78563          	beq	a5,a4,80004a62 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a3c:	4709                	li	a4,2
    80004a3e:	10e79463          	bne	a5,a4,80004b46 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a42:	0ec05e63          	blez	a2,80004b3e <filewrite+0x136>
    int i = 0;
    80004a46:	4981                	li	s3,0
    80004a48:	6b05                	lui	s6,0x1
    80004a4a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a4e:	6b85                	lui	s7,0x1
    80004a50:	c00b8b9b          	addiw	s7,s7,-1024
    80004a54:	a851                	j	80004ae8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a56:	6908                	ld	a0,16(a0)
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	254080e7          	jalr	596(ra) # 80004cac <pipewrite>
    80004a60:	a85d                	j	80004b16 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a62:	02451783          	lh	a5,36(a0)
    80004a66:	03079693          	slli	a3,a5,0x30
    80004a6a:	92c1                	srli	a3,a3,0x30
    80004a6c:	4725                	li	a4,9
    80004a6e:	0ed76663          	bltu	a4,a3,80004b5a <filewrite+0x152>
    80004a72:	0792                	slli	a5,a5,0x4
    80004a74:	0001d717          	auipc	a4,0x1d
    80004a78:	13c70713          	addi	a4,a4,316 # 80021bb0 <devsw>
    80004a7c:	97ba                	add	a5,a5,a4
    80004a7e:	679c                	ld	a5,8(a5)
    80004a80:	cff9                	beqz	a5,80004b5e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a82:	4505                	li	a0,1
    80004a84:	9782                	jalr	a5
    80004a86:	a841                	j	80004b16 <filewrite+0x10e>
    80004a88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8ae080e7          	jalr	-1874(ra) # 8000433a <begin_op>
      ilock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	ee6080e7          	jalr	-282(ra) # 8000397e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa0:	8762                	mv	a4,s8
    80004aa2:	02092683          	lw	a3,32(s2)
    80004aa6:	01598633          	add	a2,s3,s5
    80004aaa:	4585                	li	a1,1
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	278080e7          	jalr	632(ra) # 80003d28 <writei>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	02a05f63          	blez	a0,80004af8 <filewrite+0xf0>
        f->off += r;
    80004abe:	02092783          	lw	a5,32(s2)
    80004ac2:	9fa9                	addw	a5,a5,a0
    80004ac4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f74080e7          	jalr	-140(ra) # 80003a40 <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8e6080e7          	jalr	-1818(ra) # 800043ba <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004adc:	049c1963          	bne	s8,s1,80004b2e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ae0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae4:	0349d663          	bge	s3,s4,80004b10 <filewrite+0x108>
      int n1 = n - i;
    80004ae8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aec:	84be                	mv	s1,a5
    80004aee:	2781                	sext.w	a5,a5
    80004af0:	f8fb5ce3          	bge	s6,a5,80004a88 <filewrite+0x80>
    80004af4:	84de                	mv	s1,s7
    80004af6:	bf49                	j	80004a88 <filewrite+0x80>
      iunlock(f->ip);
    80004af8:	01893503          	ld	a0,24(s2)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	f44080e7          	jalr	-188(ra) # 80003a40 <iunlock>
      end_op();
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	8b6080e7          	jalr	-1866(ra) # 800043ba <end_op>
      if(r < 0)
    80004b0c:	fc04d8e3          	bgez	s1,80004adc <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b10:	8552                	mv	a0,s4
    80004b12:	033a1863          	bne	s4,s3,80004b42 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b16:	60a6                	ld	ra,72(sp)
    80004b18:	6406                	ld	s0,64(sp)
    80004b1a:	74e2                	ld	s1,56(sp)
    80004b1c:	7942                	ld	s2,48(sp)
    80004b1e:	79a2                	ld	s3,40(sp)
    80004b20:	7a02                	ld	s4,32(sp)
    80004b22:	6ae2                	ld	s5,24(sp)
    80004b24:	6b42                	ld	s6,16(sp)
    80004b26:	6ba2                	ld	s7,8(sp)
    80004b28:	6c02                	ld	s8,0(sp)
    80004b2a:	6161                	addi	sp,sp,80
    80004b2c:	8082                	ret
        panic("short filewrite");
    80004b2e:	00004517          	auipc	a0,0x4
    80004b32:	c4250513          	addi	a0,a0,-958 # 80008770 <syscalls+0x268>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	a12080e7          	jalr	-1518(ra) # 80000548 <panic>
    int i = 0;
    80004b3e:	4981                	li	s3,0
    80004b40:	bfc1                	j	80004b10 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b42:	557d                	li	a0,-1
    80004b44:	bfc9                	j	80004b16 <filewrite+0x10e>
    panic("filewrite");
    80004b46:	00004517          	auipc	a0,0x4
    80004b4a:	c3a50513          	addi	a0,a0,-966 # 80008780 <syscalls+0x278>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	9fa080e7          	jalr	-1542(ra) # 80000548 <panic>
    return -1;
    80004b56:	557d                	li	a0,-1
}
    80004b58:	8082                	ret
      return -1;
    80004b5a:	557d                	li	a0,-1
    80004b5c:	bf6d                	j	80004b16 <filewrite+0x10e>
    80004b5e:	557d                	li	a0,-1
    80004b60:	bf5d                	j	80004b16 <filewrite+0x10e>

0000000080004b62 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b62:	7179                	addi	sp,sp,-48
    80004b64:	f406                	sd	ra,40(sp)
    80004b66:	f022                	sd	s0,32(sp)
    80004b68:	ec26                	sd	s1,24(sp)
    80004b6a:	e84a                	sd	s2,16(sp)
    80004b6c:	e44e                	sd	s3,8(sp)
    80004b6e:	e052                	sd	s4,0(sp)
    80004b70:	1800                	addi	s0,sp,48
    80004b72:	84aa                	mv	s1,a0
    80004b74:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b76:	0005b023          	sd	zero,0(a1)
    80004b7a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	bd2080e7          	jalr	-1070(ra) # 80004750 <filealloc>
    80004b86:	e088                	sd	a0,0(s1)
    80004b88:	c551                	beqz	a0,80004c14 <pipealloc+0xb2>
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	bc6080e7          	jalr	-1082(ra) # 80004750 <filealloc>
    80004b92:	00aa3023          	sd	a0,0(s4)
    80004b96:	c92d                	beqz	a0,80004c08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	f88080e7          	jalr	-120(ra) # 80000b20 <kalloc>
    80004ba0:	892a                	mv	s2,a0
    80004ba2:	c125                	beqz	a0,80004c02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ba4:	4985                	li	s3,1
    80004ba6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004baa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bb2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bb6:	00004597          	auipc	a1,0x4
    80004bba:	bda58593          	addi	a1,a1,-1062 # 80008790 <syscalls+0x288>
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	fc2080e7          	jalr	-62(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004bc6:	609c                	ld	a5,0(s1)
    80004bc8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bcc:	609c                	ld	a5,0(s1)
    80004bce:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bd2:	609c                	ld	a5,0(s1)
    80004bd4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bd8:	609c                	ld	a5,0(s1)
    80004bda:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bde:	000a3783          	ld	a5,0(s4)
    80004be2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004be6:	000a3783          	ld	a5,0(s4)
    80004bea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bee:	000a3783          	ld	a5,0(s4)
    80004bf2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bf6:	000a3783          	ld	a5,0(s4)
    80004bfa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bfe:	4501                	li	a0,0
    80004c00:	a025                	j	80004c28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c02:	6088                	ld	a0,0(s1)
    80004c04:	e501                	bnez	a0,80004c0c <pipealloc+0xaa>
    80004c06:	a039                	j	80004c14 <pipealloc+0xb2>
    80004c08:	6088                	ld	a0,0(s1)
    80004c0a:	c51d                	beqz	a0,80004c38 <pipealloc+0xd6>
    fileclose(*f0);
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	c00080e7          	jalr	-1024(ra) # 8000480c <fileclose>
  if(*f1)
    80004c14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c18:	557d                	li	a0,-1
  if(*f1)
    80004c1a:	c799                	beqz	a5,80004c28 <pipealloc+0xc6>
    fileclose(*f1);
    80004c1c:	853e                	mv	a0,a5
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	bee080e7          	jalr	-1042(ra) # 8000480c <fileclose>
  return -1;
    80004c26:	557d                	li	a0,-1
}
    80004c28:	70a2                	ld	ra,40(sp)
    80004c2a:	7402                	ld	s0,32(sp)
    80004c2c:	64e2                	ld	s1,24(sp)
    80004c2e:	6942                	ld	s2,16(sp)
    80004c30:	69a2                	ld	s3,8(sp)
    80004c32:	6a02                	ld	s4,0(sp)
    80004c34:	6145                	addi	sp,sp,48
    80004c36:	8082                	ret
  return -1;
    80004c38:	557d                	li	a0,-1
    80004c3a:	b7fd                	j	80004c28 <pipealloc+0xc6>

0000000080004c3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c3c:	1101                	addi	sp,sp,-32
    80004c3e:	ec06                	sd	ra,24(sp)
    80004c40:	e822                	sd	s0,16(sp)
    80004c42:	e426                	sd	s1,8(sp)
    80004c44:	e04a                	sd	s2,0(sp)
    80004c46:	1000                	addi	s0,sp,32
    80004c48:	84aa                	mv	s1,a0
    80004c4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	fc4080e7          	jalr	-60(ra) # 80000c10 <acquire>
  if(writable){
    80004c54:	02090d63          	beqz	s2,80004c8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c5c:	21848513          	addi	a0,s1,536
    80004c60:	ffffe097          	auipc	ra,0xffffe
    80004c64:	a84080e7          	jalr	-1404(ra) # 800026e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c68:	2204b783          	ld	a5,544(s1)
    80004c6c:	eb95                	bnez	a5,80004ca0 <pipeclose+0x64>
    release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	054080e7          	jalr	84(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	daa080e7          	jalr	-598(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6902                	ld	s2,0(sp)
    80004c8a:	6105                	addi	sp,sp,32
    80004c8c:	8082                	ret
    pi->readopen = 0;
    80004c8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c92:	21c48513          	addi	a0,s1,540
    80004c96:	ffffe097          	auipc	ra,0xffffe
    80004c9a:	a4e080e7          	jalr	-1458(ra) # 800026e4 <wakeup>
    80004c9e:	b7e9                	j	80004c68 <pipeclose+0x2c>
    release(&pi->lock);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	022080e7          	jalr	34(ra) # 80000cc4 <release>
}
    80004caa:	bfe1                	j	80004c82 <pipeclose+0x46>

0000000080004cac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cac:	7119                	addi	sp,sp,-128
    80004cae:	fc86                	sd	ra,120(sp)
    80004cb0:	f8a2                	sd	s0,112(sp)
    80004cb2:	f4a6                	sd	s1,104(sp)
    80004cb4:	f0ca                	sd	s2,96(sp)
    80004cb6:	ecce                	sd	s3,88(sp)
    80004cb8:	e8d2                	sd	s4,80(sp)
    80004cba:	e4d6                	sd	s5,72(sp)
    80004cbc:	e0da                	sd	s6,64(sp)
    80004cbe:	fc5e                	sd	s7,56(sp)
    80004cc0:	f862                	sd	s8,48(sp)
    80004cc2:	f466                	sd	s9,40(sp)
    80004cc4:	f06a                	sd	s10,32(sp)
    80004cc6:	ec6e                	sd	s11,24(sp)
    80004cc8:	0100                	addi	s0,sp,128
    80004cca:	84aa                	mv	s1,a0
    80004ccc:	8cae                	mv	s9,a1
    80004cce:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	eec080e7          	jalr	-276(ra) # 80001bbc <myproc>
    80004cd8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	f34080e7          	jalr	-204(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004ce4:	0d605963          	blez	s6,80004db6 <pipewrite+0x10a>
    80004ce8:	89a6                	mv	s3,s1
    80004cea:	3b7d                	addiw	s6,s6,-1
    80004cec:	1b02                	slli	s6,s6,0x20
    80004cee:	020b5b13          	srli	s6,s6,0x20
    80004cf2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cf4:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cf8:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cfc:	5dfd                	li	s11,-1
    80004cfe:	000b8d1b          	sext.w	s10,s7
    80004d02:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d04:	2184a783          	lw	a5,536(s1)
    80004d08:	21c4a703          	lw	a4,540(s1)
    80004d0c:	2007879b          	addiw	a5,a5,512
    80004d10:	02f71b63          	bne	a4,a5,80004d46 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004d14:	2204a783          	lw	a5,544(s1)
    80004d18:	cbad                	beqz	a5,80004d8a <pipewrite+0xde>
    80004d1a:	03092783          	lw	a5,48(s2)
    80004d1e:	e7b5                	bnez	a5,80004d8a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004d20:	8556                	mv	a0,s5
    80004d22:	ffffe097          	auipc	ra,0xffffe
    80004d26:	9c2080e7          	jalr	-1598(ra) # 800026e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d2a:	85ce                	mv	a1,s3
    80004d2c:	8552                	mv	a0,s4
    80004d2e:	ffffe097          	auipc	ra,0xffffe
    80004d32:	830080e7          	jalr	-2000(ra) # 8000255e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	2007879b          	addiw	a5,a5,512
    80004d42:	fcf709e3          	beq	a4,a5,80004d14 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d46:	4685                	li	a3,1
    80004d48:	019b8633          	add	a2,s7,s9
    80004d4c:	f8f40593          	addi	a1,s0,-113
    80004d50:	05093503          	ld	a0,80(s2)
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	b64080e7          	jalr	-1180(ra) # 800018b8 <copyin>
    80004d5c:	05b50e63          	beq	a0,s11,80004db8 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d60:	21c4a783          	lw	a5,540(s1)
    80004d64:	0017871b          	addiw	a4,a5,1
    80004d68:	20e4ae23          	sw	a4,540(s1)
    80004d6c:	1ff7f793          	andi	a5,a5,511
    80004d70:	97a6                	add	a5,a5,s1
    80004d72:	f8f44703          	lbu	a4,-113(s0)
    80004d76:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d7a:	001d0c1b          	addiw	s8,s10,1
    80004d7e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d82:	036b8b63          	beq	s7,s6,80004db8 <pipewrite+0x10c>
    80004d86:	8bbe                	mv	s7,a5
    80004d88:	bf9d                	j	80004cfe <pipewrite+0x52>
        release(&pi->lock);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	f38080e7          	jalr	-200(ra) # 80000cc4 <release>
        return -1;
    80004d94:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d96:	8562                	mv	a0,s8
    80004d98:	70e6                	ld	ra,120(sp)
    80004d9a:	7446                	ld	s0,112(sp)
    80004d9c:	74a6                	ld	s1,104(sp)
    80004d9e:	7906                	ld	s2,96(sp)
    80004da0:	69e6                	ld	s3,88(sp)
    80004da2:	6a46                	ld	s4,80(sp)
    80004da4:	6aa6                	ld	s5,72(sp)
    80004da6:	6b06                	ld	s6,64(sp)
    80004da8:	7be2                	ld	s7,56(sp)
    80004daa:	7c42                	ld	s8,48(sp)
    80004dac:	7ca2                	ld	s9,40(sp)
    80004dae:	7d02                	ld	s10,32(sp)
    80004db0:	6de2                	ld	s11,24(sp)
    80004db2:	6109                	addi	sp,sp,128
    80004db4:	8082                	ret
  for(i = 0; i < n; i++){
    80004db6:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004db8:	21848513          	addi	a0,s1,536
    80004dbc:	ffffe097          	auipc	ra,0xffffe
    80004dc0:	928080e7          	jalr	-1752(ra) # 800026e4 <wakeup>
  release(&pi->lock);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	efe080e7          	jalr	-258(ra) # 80000cc4 <release>
  return i;
    80004dce:	b7e1                	j	80004d96 <pipewrite+0xea>

0000000080004dd0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dd0:	715d                	addi	sp,sp,-80
    80004dd2:	e486                	sd	ra,72(sp)
    80004dd4:	e0a2                	sd	s0,64(sp)
    80004dd6:	fc26                	sd	s1,56(sp)
    80004dd8:	f84a                	sd	s2,48(sp)
    80004dda:	f44e                	sd	s3,40(sp)
    80004ddc:	f052                	sd	s4,32(sp)
    80004dde:	ec56                	sd	s5,24(sp)
    80004de0:	e85a                	sd	s6,16(sp)
    80004de2:	0880                	addi	s0,sp,80
    80004de4:	84aa                	mv	s1,a0
    80004de6:	892e                	mv	s2,a1
    80004de8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	dd2080e7          	jalr	-558(ra) # 80001bbc <myproc>
    80004df2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004df4:	8b26                	mv	s6,s1
    80004df6:	8526                	mv	a0,s1
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	e18080e7          	jalr	-488(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e00:	2184a703          	lw	a4,536(s1)
    80004e04:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e08:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e0c:	02f71463          	bne	a4,a5,80004e34 <piperead+0x64>
    80004e10:	2244a783          	lw	a5,548(s1)
    80004e14:	c385                	beqz	a5,80004e34 <piperead+0x64>
    if(pr->killed){
    80004e16:	030a2783          	lw	a5,48(s4)
    80004e1a:	ebc1                	bnez	a5,80004eaa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e1c:	85da                	mv	a1,s6
    80004e1e:	854e                	mv	a0,s3
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	73e080e7          	jalr	1854(ra) # 8000255e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e28:	2184a703          	lw	a4,536(s1)
    80004e2c:	21c4a783          	lw	a5,540(s1)
    80004e30:	fef700e3          	beq	a4,a5,80004e10 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e34:	09505263          	blez	s5,80004eb8 <piperead+0xe8>
    80004e38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e3a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e3c:	2184a783          	lw	a5,536(s1)
    80004e40:	21c4a703          	lw	a4,540(s1)
    80004e44:	02f70d63          	beq	a4,a5,80004e7e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e48:	0017871b          	addiw	a4,a5,1
    80004e4c:	20e4ac23          	sw	a4,536(s1)
    80004e50:	1ff7f793          	andi	a5,a5,511
    80004e54:	97a6                	add	a5,a5,s1
    80004e56:	0187c783          	lbu	a5,24(a5)
    80004e5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e5e:	4685                	li	a3,1
    80004e60:	fbf40613          	addi	a2,s0,-65
    80004e64:	85ca                	mv	a1,s2
    80004e66:	050a3503          	ld	a0,80(s4)
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	9c2080e7          	jalr	-1598(ra) # 8000182c <copyout>
    80004e72:	01650663          	beq	a0,s6,80004e7e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e76:	2985                	addiw	s3,s3,1
    80004e78:	0905                	addi	s2,s2,1
    80004e7a:	fd3a91e3          	bne	s5,s3,80004e3c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e7e:	21c48513          	addi	a0,s1,540
    80004e82:	ffffe097          	auipc	ra,0xffffe
    80004e86:	862080e7          	jalr	-1950(ra) # 800026e4 <wakeup>
  release(&pi->lock);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	e38080e7          	jalr	-456(ra) # 80000cc4 <release>
  return i;
}
    80004e94:	854e                	mv	a0,s3
    80004e96:	60a6                	ld	ra,72(sp)
    80004e98:	6406                	ld	s0,64(sp)
    80004e9a:	74e2                	ld	s1,56(sp)
    80004e9c:	7942                	ld	s2,48(sp)
    80004e9e:	79a2                	ld	s3,40(sp)
    80004ea0:	7a02                	ld	s4,32(sp)
    80004ea2:	6ae2                	ld	s5,24(sp)
    80004ea4:	6b42                	ld	s6,16(sp)
    80004ea6:	6161                	addi	sp,sp,80
    80004ea8:	8082                	ret
      release(&pi->lock);
    80004eaa:	8526                	mv	a0,s1
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	e18080e7          	jalr	-488(ra) # 80000cc4 <release>
      return -1;
    80004eb4:	59fd                	li	s3,-1
    80004eb6:	bff9                	j	80004e94 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb8:	4981                	li	s3,0
    80004eba:	b7d1                	j	80004e7e <piperead+0xae>

0000000080004ebc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ebc:	df010113          	addi	sp,sp,-528
    80004ec0:	20113423          	sd	ra,520(sp)
    80004ec4:	20813023          	sd	s0,512(sp)
    80004ec8:	ffa6                	sd	s1,504(sp)
    80004eca:	fbca                	sd	s2,496(sp)
    80004ecc:	f7ce                	sd	s3,488(sp)
    80004ece:	f3d2                	sd	s4,480(sp)
    80004ed0:	efd6                	sd	s5,472(sp)
    80004ed2:	ebda                	sd	s6,464(sp)
    80004ed4:	e7de                	sd	s7,456(sp)
    80004ed6:	e3e2                	sd	s8,448(sp)
    80004ed8:	ff66                	sd	s9,440(sp)
    80004eda:	fb6a                	sd	s10,432(sp)
    80004edc:	f76e                	sd	s11,424(sp)
    80004ede:	0c00                	addi	s0,sp,528
    80004ee0:	84aa                	mv	s1,a0
    80004ee2:	dea43c23          	sd	a0,-520(s0)
    80004ee6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	cd2080e7          	jalr	-814(ra) # 80001bbc <myproc>
    80004ef2:	892a                	mv	s2,a0

  begin_op();
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	446080e7          	jalr	1094(ra) # 8000433a <begin_op>

  if((ip = namei(path)) == 0){
    80004efc:	8526                	mv	a0,s1
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	230080e7          	jalr	560(ra) # 8000412e <namei>
    80004f06:	c92d                	beqz	a0,80004f78 <exec+0xbc>
    80004f08:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	a74080e7          	jalr	-1420(ra) # 8000397e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f12:	04000713          	li	a4,64
    80004f16:	4681                	li	a3,0
    80004f18:	e4840613          	addi	a2,s0,-440
    80004f1c:	4581                	li	a1,0
    80004f1e:	8526                	mv	a0,s1
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	d12080e7          	jalr	-750(ra) # 80003c32 <readi>
    80004f28:	04000793          	li	a5,64
    80004f2c:	00f51a63          	bne	a0,a5,80004f40 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f30:	e4842703          	lw	a4,-440(s0)
    80004f34:	464c47b7          	lui	a5,0x464c4
    80004f38:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f3c:	04f70463          	beq	a4,a5,80004f84 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f40:	8526                	mv	a0,s1
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	c9e080e7          	jalr	-866(ra) # 80003be0 <iunlockput>
    end_op();
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	470080e7          	jalr	1136(ra) # 800043ba <end_op>
  }
  return -1;
    80004f52:	557d                	li	a0,-1
}
    80004f54:	20813083          	ld	ra,520(sp)
    80004f58:	20013403          	ld	s0,512(sp)
    80004f5c:	74fe                	ld	s1,504(sp)
    80004f5e:	795e                	ld	s2,496(sp)
    80004f60:	79be                	ld	s3,488(sp)
    80004f62:	7a1e                	ld	s4,480(sp)
    80004f64:	6afe                	ld	s5,472(sp)
    80004f66:	6b5e                	ld	s6,464(sp)
    80004f68:	6bbe                	ld	s7,456(sp)
    80004f6a:	6c1e                	ld	s8,448(sp)
    80004f6c:	7cfa                	ld	s9,440(sp)
    80004f6e:	7d5a                	ld	s10,432(sp)
    80004f70:	7dba                	ld	s11,424(sp)
    80004f72:	21010113          	addi	sp,sp,528
    80004f76:	8082                	ret
    end_op();
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	442080e7          	jalr	1090(ra) # 800043ba <end_op>
    return -1;
    80004f80:	557d                	li	a0,-1
    80004f82:	bfc9                	j	80004f54 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f84:	854a                	mv	a0,s2
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	cfa080e7          	jalr	-774(ra) # 80001c80 <proc_pagetable>
    80004f8e:	8baa                	mv	s7,a0
    80004f90:	d945                	beqz	a0,80004f40 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f92:	e6842983          	lw	s3,-408(s0)
    80004f96:	e8045783          	lhu	a5,-384(s0)
    80004f9a:	c7ad                	beqz	a5,80005004 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f9c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f9e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004fa0:	6c85                	lui	s9,0x1
    80004fa2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fa6:	def43823          	sd	a5,-528(s0)
    80004faa:	a471                	j	80005236 <exec+0x37a>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fac:	00003517          	auipc	a0,0x3
    80004fb0:	7ec50513          	addi	a0,a0,2028 # 80008798 <syscalls+0x290>
    80004fb4:	ffffb097          	auipc	ra,0xffffb
    80004fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fbc:	8756                	mv	a4,s5
    80004fbe:	012d86bb          	addw	a3,s11,s2
    80004fc2:	4581                	li	a1,0
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	c6c080e7          	jalr	-916(ra) # 80003c32 <readi>
    80004fce:	2501                	sext.w	a0,a0
    80004fd0:	20aa9c63          	bne	s5,a0,800051e8 <exec+0x32c>
  for(i = 0; i < sz; i += PGSIZE){
    80004fd4:	6785                	lui	a5,0x1
    80004fd6:	0127893b          	addw	s2,a5,s2
    80004fda:	77fd                	lui	a5,0xfffff
    80004fdc:	01478a3b          	addw	s4,a5,s4
    80004fe0:	25897263          	bgeu	s2,s8,80005224 <exec+0x368>
    pa = walkaddr(pagetable, va + i);
    80004fe4:	02091593          	slli	a1,s2,0x20
    80004fe8:	9181                	srli	a1,a1,0x20
    80004fea:	95ea                	add	a1,a1,s10
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	0b8080e7          	jalr	184(ra) # 800010a6 <walkaddr>
    80004ff6:	862a                	mv	a2,a0
    if(pa == 0)
    80004ff8:	d955                	beqz	a0,80004fac <exec+0xf0>
      n = PGSIZE;
    80004ffa:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ffc:	fd9a70e3          	bgeu	s4,s9,80004fbc <exec+0x100>
      n = sz - i;
    80005000:	8ad2                	mv	s5,s4
    80005002:	bf6d                	j	80004fbc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005004:	4901                	li	s2,0
  iunlockput(ip);
    80005006:	8526                	mv	a0,s1
    80005008:	fffff097          	auipc	ra,0xfffff
    8000500c:	bd8080e7          	jalr	-1064(ra) # 80003be0 <iunlockput>
  end_op();
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	3aa080e7          	jalr	938(ra) # 800043ba <end_op>
  p = myproc();
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	ba4080e7          	jalr	-1116(ra) # 80001bbc <myproc>
    80005020:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005022:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005026:	6785                	lui	a5,0x1
    80005028:	17fd                	addi	a5,a5,-1
    8000502a:	993e                	add	s2,s2,a5
    8000502c:	77fd                	lui	a5,0xfffff
    8000502e:	00f97933          	and	s2,s2,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005032:	6609                	lui	a2,0x2
    80005034:	964a                	add	a2,a2,s2
    80005036:	85ca                	mv	a1,s2
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	458080e7          	jalr	1112(ra) # 80001492 <uvmalloc>
    80005042:	e0a43423          	sd	a0,-504(s0)
    80005046:	1c050563          	beqz	a0,80005210 <exec+0x354>
  if(sz > PLIC){
    8000504a:	0c0007b7          	lui	a5,0xc000
    8000504e:	08a7e263          	bltu	a5,a0,800050d2 <exec+0x216>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005052:	75f9                	lui	a1,0xffffe
    80005054:	e0843483          	ld	s1,-504(s0)
    80005058:	95a6                	add	a1,a1,s1
    8000505a:	855e                	mv	a0,s7
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	79e080e7          	jalr	1950(ra) # 800017fa <uvmclear>
  stackbase = sp - PGSIZE;
    80005064:	7b7d                	lui	s6,0xfffff
    80005066:	9b26                	add	s6,s6,s1
  for(argc = 0; argv[argc]; argc++) {
    80005068:	e0043783          	ld	a5,-512(s0)
    8000506c:	6388                	ld	a0,0(a5)
    8000506e:	c935                	beqz	a0,800050e2 <exec+0x226>
    80005070:	e8840993          	addi	s3,s0,-376
    80005074:	f8840c13          	addi	s8,s0,-120
    80005078:	4901                	li	s2,0
    sp -= strlen(argv[argc]) + 1;
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	e1a080e7          	jalr	-486(ra) # 80000e94 <strlen>
    80005082:	2505                	addiw	a0,a0,1
    80005084:	8c89                	sub	s1,s1,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005086:	98c1                	andi	s1,s1,-16
    if(sp < stackbase)
    80005088:	1964e863          	bltu	s1,s6,80005218 <exec+0x35c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000508c:	e0043d03          	ld	s10,-512(s0)
    80005090:	000d3a03          	ld	s4,0(s10)
    80005094:	8552                	mv	a0,s4
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	dfe080e7          	jalr	-514(ra) # 80000e94 <strlen>
    8000509e:	0015069b          	addiw	a3,a0,1
    800050a2:	8652                	mv	a2,s4
    800050a4:	85a6                	mv	a1,s1
    800050a6:	855e                	mv	a0,s7
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	784080e7          	jalr	1924(ra) # 8000182c <copyout>
    800050b0:	16054663          	bltz	a0,8000521c <exec+0x360>
    ustack[argc] = sp;
    800050b4:	0099b023          	sd	s1,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050b8:	0905                	addi	s2,s2,1
    800050ba:	008d0793          	addi	a5,s10,8
    800050be:	e0f43023          	sd	a5,-512(s0)
    800050c2:	008d3503          	ld	a0,8(s10)
    800050c6:	c10d                	beqz	a0,800050e8 <exec+0x22c>
    if(argc >= MAXARG)
    800050c8:	09a1                	addi	s3,s3,8
    800050ca:	fb3c18e3          	bne	s8,s3,8000507a <exec+0x1be>
  ip = 0;
    800050ce:	4481                	li	s1,0
    800050d0:	aa21                	j	800051e8 <exec+0x32c>
    panic("exec: sz > PLIC");
    800050d2:	00003517          	auipc	a0,0x3
    800050d6:	6e650513          	addi	a0,a0,1766 # 800087b8 <syscalls+0x2b0>
    800050da:	ffffb097          	auipc	ra,0xffffb
    800050de:	46e080e7          	jalr	1134(ra) # 80000548 <panic>
  sp = sz;
    800050e2:	e0843483          	ld	s1,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800050e6:	4901                	li	s2,0
  ustack[argc] = 0;
    800050e8:	00391793          	slli	a5,s2,0x3
    800050ec:	f9040713          	addi	a4,s0,-112
    800050f0:	97ba                	add	a5,a5,a4
    800050f2:	ee07bc23          	sd	zero,-264(a5) # bfffef8 <_entry-0x74000108>
  sp -= (argc+1) * sizeof(uint64);
    800050f6:	00190693          	addi	a3,s2,1
    800050fa:	068e                	slli	a3,a3,0x3
    800050fc:	8c95                	sub	s1,s1,a3
  sp -= sp % 16;
    800050fe:	ff04f993          	andi	s3,s1,-16
  ip = 0;
    80005102:	4481                	li	s1,0
  if(sp < stackbase)
    80005104:	0f69e263          	bltu	s3,s6,800051e8 <exec+0x32c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005108:	e8840613          	addi	a2,s0,-376
    8000510c:	85ce                	mv	a1,s3
    8000510e:	855e                	mv	a0,s7
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	71c080e7          	jalr	1820(ra) # 8000182c <copyout>
    80005118:	10054463          	bltz	a0,80005220 <exec+0x364>
  p->trapframe->a1 = sp;
    8000511c:	060ab783          	ld	a5,96(s5)
    80005120:	0737bc23          	sd	s3,120(a5)
  for(last=s=path; *s; s++)
    80005124:	df843783          	ld	a5,-520(s0)
    80005128:	0007c703          	lbu	a4,0(a5)
    8000512c:	cf11                	beqz	a4,80005148 <exec+0x28c>
    8000512e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005130:	02f00693          	li	a3,47
    80005134:	a029                	j	8000513e <exec+0x282>
  for(last=s=path; *s; s++)
    80005136:	0785                	addi	a5,a5,1
    80005138:	fff7c703          	lbu	a4,-1(a5)
    8000513c:	c711                	beqz	a4,80005148 <exec+0x28c>
    if(*s == '/')
    8000513e:	fed71ce3          	bne	a4,a3,80005136 <exec+0x27a>
      last = s+1;
    80005142:	def43c23          	sd	a5,-520(s0)
    80005146:	bfc5                	j	80005136 <exec+0x27a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005148:	4641                	li	a2,16
    8000514a:	df843583          	ld	a1,-520(s0)
    8000514e:	160a8513          	addi	a0,s5,352
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	d10080e7          	jalr	-752(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000515a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000515e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005162:	e0843783          	ld	a5,-504(s0)
    80005166:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000516a:	060ab783          	ld	a5,96(s5)
    8000516e:	e6043703          	ld	a4,-416(s0)
    80005172:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005174:	060ab783          	ld	a5,96(s5)
    80005178:	0337b823          	sd	s3,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000517c:	85e6                	mv	a1,s9
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	b9e080e7          	jalr	-1122(ra) # 80001d1c <proc_freepagetable>
  uvmunmap(p->kpagetable,0,PGROUNDUP(oldsz)/PGSIZE,0);
    80005186:	6605                	lui	a2,0x1
    80005188:	167d                	addi	a2,a2,-1
    8000518a:	9666                	add	a2,a2,s9
    8000518c:	4681                	li	a3,0
    8000518e:	8231                	srli	a2,a2,0xc
    80005190:	4581                	li	a1,0
    80005192:	058ab503          	ld	a0,88(s5)
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	150080e7          	jalr	336(ra) # 800012e6 <uvmunmap>
  if(kvmcopy(p->pagetable,p->kpagetable,0,p->sz) < 0){
    8000519e:	048ab683          	ld	a3,72(s5)
    800051a2:	4601                	li	a2,0
    800051a4:	058ab583          	ld	a1,88(s5)
    800051a8:	050ab503          	ld	a0,80(s5)
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	504080e7          	jalr	1284(ra) # 800016b0 <kvmcopy>
    800051b4:	00054c63          	bltz	a0,800051cc <exec+0x310>
  vmprint(p->pagetable,0);
    800051b8:	4581                	li	a1,0
    800051ba:	050ab503          	ld	a0,80(s5)
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	72a080e7          	jalr	1834(ra) # 800018e8 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051c6:	0009051b          	sext.w	a0,s2
    800051ca:	b369                	j	80004f54 <exec+0x98>
    uvmunmap(p->kpagetable,0,p->sz,0);
    800051cc:	4681                	li	a3,0
    800051ce:	048ab603          	ld	a2,72(s5)
    800051d2:	4581                	li	a1,0
    800051d4:	058ab503          	ld	a0,88(s5)
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	10e080e7          	jalr	270(ra) # 800012e6 <uvmunmap>
  ip = 0;
    800051e0:	4481                	li	s1,0
    goto bad;
    800051e2:	a019                	j	800051e8 <exec+0x32c>
    800051e4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051e8:	e0843583          	ld	a1,-504(s0)
    800051ec:	855e                	mv	a0,s7
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	b2e080e7          	jalr	-1234(ra) # 80001d1c <proc_freepagetable>
  if(ip){
    800051f6:	d40495e3          	bnez	s1,80004f40 <exec+0x84>
  return -1;
    800051fa:	557d                	li	a0,-1
    800051fc:	bba1                	j	80004f54 <exec+0x98>
    800051fe:	e1243423          	sd	s2,-504(s0)
    80005202:	b7dd                	j	800051e8 <exec+0x32c>
    80005204:	e1243423          	sd	s2,-504(s0)
    80005208:	b7c5                	j	800051e8 <exec+0x32c>
    8000520a:	e1243423          	sd	s2,-504(s0)
    8000520e:	bfe9                	j	800051e8 <exec+0x32c>
  sz = PGROUNDUP(sz);
    80005210:	e1243423          	sd	s2,-504(s0)
  ip = 0;
    80005214:	4481                	li	s1,0
    80005216:	bfc9                	j	800051e8 <exec+0x32c>
    80005218:	4481                	li	s1,0
    8000521a:	b7f9                	j	800051e8 <exec+0x32c>
    8000521c:	4481                	li	s1,0
    8000521e:	b7e9                	j	800051e8 <exec+0x32c>
    80005220:	4481                	li	s1,0
    80005222:	b7d9                	j	800051e8 <exec+0x32c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005224:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005228:	2b05                	addiw	s6,s6,1
    8000522a:	0389899b          	addiw	s3,s3,56
    8000522e:	e8045783          	lhu	a5,-384(s0)
    80005232:	dcfb5ae3          	bge	s6,a5,80005006 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005236:	2981                	sext.w	s3,s3
    80005238:	03800713          	li	a4,56
    8000523c:	86ce                	mv	a3,s3
    8000523e:	e1040613          	addi	a2,s0,-496
    80005242:	4581                	li	a1,0
    80005244:	8526                	mv	a0,s1
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	9ec080e7          	jalr	-1556(ra) # 80003c32 <readi>
    8000524e:	03800793          	li	a5,56
    80005252:	f8f519e3          	bne	a0,a5,800051e4 <exec+0x328>
    if(ph.type != ELF_PROG_LOAD)
    80005256:	e1042783          	lw	a5,-496(s0)
    8000525a:	4705                	li	a4,1
    8000525c:	fce796e3          	bne	a5,a4,80005228 <exec+0x36c>
    if(ph.memsz < ph.filesz)
    80005260:	e3843603          	ld	a2,-456(s0)
    80005264:	e3043783          	ld	a5,-464(s0)
    80005268:	f8f66be3          	bltu	a2,a5,800051fe <exec+0x342>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000526c:	e2043783          	ld	a5,-480(s0)
    80005270:	963e                	add	a2,a2,a5
    80005272:	f8f669e3          	bltu	a2,a5,80005204 <exec+0x348>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005276:	85ca                	mv	a1,s2
    80005278:	855e                	mv	a0,s7
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	218080e7          	jalr	536(ra) # 80001492 <uvmalloc>
    80005282:	e0a43423          	sd	a0,-504(s0)
    80005286:	d151                	beqz	a0,8000520a <exec+0x34e>
    if(ph.vaddr % PGSIZE != 0)
    80005288:	e2043d03          	ld	s10,-480(s0)
    8000528c:	df043783          	ld	a5,-528(s0)
    80005290:	00fd77b3          	and	a5,s10,a5
    80005294:	fbb1                	bnez	a5,800051e8 <exec+0x32c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005296:	e1842d83          	lw	s11,-488(s0)
    8000529a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000529e:	f80c03e3          	beqz	s8,80005224 <exec+0x368>
    800052a2:	8a62                	mv	s4,s8
    800052a4:	4901                	li	s2,0
    800052a6:	bb3d                	j	80004fe4 <exec+0x128>

00000000800052a8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	ec26                	sd	s1,24(sp)
    800052b0:	e84a                	sd	s2,16(sp)
    800052b2:	1800                	addi	s0,sp,48
    800052b4:	892e                	mv	s2,a1
    800052b6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052b8:	fdc40593          	addi	a1,s0,-36
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	b50080e7          	jalr	-1200(ra) # 80002e0c <argint>
    800052c4:	04054063          	bltz	a0,80005304 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052c8:	fdc42703          	lw	a4,-36(s0)
    800052cc:	47bd                	li	a5,15
    800052ce:	02e7ed63          	bltu	a5,a4,80005308 <argfd+0x60>
    800052d2:	ffffd097          	auipc	ra,0xffffd
    800052d6:	8ea080e7          	jalr	-1814(ra) # 80001bbc <myproc>
    800052da:	fdc42703          	lw	a4,-36(s0)
    800052de:	01a70793          	addi	a5,a4,26
    800052e2:	078e                	slli	a5,a5,0x3
    800052e4:	953e                	add	a0,a0,a5
    800052e6:	651c                	ld	a5,8(a0)
    800052e8:	c395                	beqz	a5,8000530c <argfd+0x64>
    return -1;
  if(pfd)
    800052ea:	00090463          	beqz	s2,800052f2 <argfd+0x4a>
    *pfd = fd;
    800052ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052f2:	4501                	li	a0,0
  if(pf)
    800052f4:	c091                	beqz	s1,800052f8 <argfd+0x50>
    *pf = f;
    800052f6:	e09c                	sd	a5,0(s1)
}
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	64e2                	ld	s1,24(sp)
    800052fe:	6942                	ld	s2,16(sp)
    80005300:	6145                	addi	sp,sp,48
    80005302:	8082                	ret
    return -1;
    80005304:	557d                	li	a0,-1
    80005306:	bfcd                	j	800052f8 <argfd+0x50>
    return -1;
    80005308:	557d                	li	a0,-1
    8000530a:	b7fd                	j	800052f8 <argfd+0x50>
    8000530c:	557d                	li	a0,-1
    8000530e:	b7ed                	j	800052f8 <argfd+0x50>

0000000080005310 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005310:	1101                	addi	sp,sp,-32
    80005312:	ec06                	sd	ra,24(sp)
    80005314:	e822                	sd	s0,16(sp)
    80005316:	e426                	sd	s1,8(sp)
    80005318:	1000                	addi	s0,sp,32
    8000531a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	8a0080e7          	jalr	-1888(ra) # 80001bbc <myproc>
    80005324:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005326:	0d850793          	addi	a5,a0,216
    8000532a:	4501                	li	a0,0
    8000532c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000532e:	6398                	ld	a4,0(a5)
    80005330:	cb19                	beqz	a4,80005346 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005332:	2505                	addiw	a0,a0,1
    80005334:	07a1                	addi	a5,a5,8
    80005336:	fed51ce3          	bne	a0,a3,8000532e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000533a:	557d                	li	a0,-1
}
    8000533c:	60e2                	ld	ra,24(sp)
    8000533e:	6442                	ld	s0,16(sp)
    80005340:	64a2                	ld	s1,8(sp)
    80005342:	6105                	addi	sp,sp,32
    80005344:	8082                	ret
      p->ofile[fd] = f;
    80005346:	01a50793          	addi	a5,a0,26
    8000534a:	078e                	slli	a5,a5,0x3
    8000534c:	963e                	add	a2,a2,a5
    8000534e:	e604                	sd	s1,8(a2)
      return fd;
    80005350:	b7f5                	j	8000533c <fdalloc+0x2c>

0000000080005352 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005352:	715d                	addi	sp,sp,-80
    80005354:	e486                	sd	ra,72(sp)
    80005356:	e0a2                	sd	s0,64(sp)
    80005358:	fc26                	sd	s1,56(sp)
    8000535a:	f84a                	sd	s2,48(sp)
    8000535c:	f44e                	sd	s3,40(sp)
    8000535e:	f052                	sd	s4,32(sp)
    80005360:	ec56                	sd	s5,24(sp)
    80005362:	0880                	addi	s0,sp,80
    80005364:	89ae                	mv	s3,a1
    80005366:	8ab2                	mv	s5,a2
    80005368:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	dde080e7          	jalr	-546(ra) # 8000414c <nameiparent>
    80005376:	892a                	mv	s2,a0
    80005378:	12050f63          	beqz	a0,800054b6 <create+0x164>
    return 0;

  ilock(dp);
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	602080e7          	jalr	1538(ra) # 8000397e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005384:	4601                	li	a2,0
    80005386:	fb040593          	addi	a1,s0,-80
    8000538a:	854a                	mv	a0,s2
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	ad0080e7          	jalr	-1328(ra) # 80003e5c <dirlookup>
    80005394:	84aa                	mv	s1,a0
    80005396:	c921                	beqz	a0,800053e6 <create+0x94>
    iunlockput(dp);
    80005398:	854a                	mv	a0,s2
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	846080e7          	jalr	-1978(ra) # 80003be0 <iunlockput>
    ilock(ip);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	5da080e7          	jalr	1498(ra) # 8000397e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ac:	2981                	sext.w	s3,s3
    800053ae:	4789                	li	a5,2
    800053b0:	02f99463          	bne	s3,a5,800053d8 <create+0x86>
    800053b4:	0444d783          	lhu	a5,68(s1)
    800053b8:	37f9                	addiw	a5,a5,-2
    800053ba:	17c2                	slli	a5,a5,0x30
    800053bc:	93c1                	srli	a5,a5,0x30
    800053be:	4705                	li	a4,1
    800053c0:	00f76c63          	bltu	a4,a5,800053d8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053c4:	8526                	mv	a0,s1
    800053c6:	60a6                	ld	ra,72(sp)
    800053c8:	6406                	ld	s0,64(sp)
    800053ca:	74e2                	ld	s1,56(sp)
    800053cc:	7942                	ld	s2,48(sp)
    800053ce:	79a2                	ld	s3,40(sp)
    800053d0:	7a02                	ld	s4,32(sp)
    800053d2:	6ae2                	ld	s5,24(sp)
    800053d4:	6161                	addi	sp,sp,80
    800053d6:	8082                	ret
    iunlockput(ip);
    800053d8:	8526                	mv	a0,s1
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	806080e7          	jalr	-2042(ra) # 80003be0 <iunlockput>
    return 0;
    800053e2:	4481                	li	s1,0
    800053e4:	b7c5                	j	800053c4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053e6:	85ce                	mv	a1,s3
    800053e8:	00092503          	lw	a0,0(s2)
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	3fa080e7          	jalr	1018(ra) # 800037e6 <ialloc>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	c529                	beqz	a0,80005440 <create+0xee>
  ilock(ip);
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	586080e7          	jalr	1414(ra) # 8000397e <ilock>
  ip->major = major;
    80005400:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005404:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005408:	4785                	li	a5,1
    8000540a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	4a4080e7          	jalr	1188(ra) # 800038b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005418:	2981                	sext.w	s3,s3
    8000541a:	4785                	li	a5,1
    8000541c:	02f98a63          	beq	s3,a5,80005450 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005420:	40d0                	lw	a2,4(s1)
    80005422:	fb040593          	addi	a1,s0,-80
    80005426:	854a                	mv	a0,s2
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	c44080e7          	jalr	-956(ra) # 8000406c <dirlink>
    80005430:	06054b63          	bltz	a0,800054a6 <create+0x154>
  iunlockput(dp);
    80005434:	854a                	mv	a0,s2
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	7aa080e7          	jalr	1962(ra) # 80003be0 <iunlockput>
  return ip;
    8000543e:	b759                	j	800053c4 <create+0x72>
    panic("create: ialloc");
    80005440:	00003517          	auipc	a0,0x3
    80005444:	38850513          	addi	a0,a0,904 # 800087c8 <syscalls+0x2c0>
    80005448:	ffffb097          	auipc	ra,0xffffb
    8000544c:	100080e7          	jalr	256(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005450:	04a95783          	lhu	a5,74(s2)
    80005454:	2785                	addiw	a5,a5,1
    80005456:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000545a:	854a                	mv	a0,s2
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	458080e7          	jalr	1112(ra) # 800038b4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005464:	40d0                	lw	a2,4(s1)
    80005466:	00003597          	auipc	a1,0x3
    8000546a:	37258593          	addi	a1,a1,882 # 800087d8 <syscalls+0x2d0>
    8000546e:	8526                	mv	a0,s1
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	bfc080e7          	jalr	-1028(ra) # 8000406c <dirlink>
    80005478:	00054f63          	bltz	a0,80005496 <create+0x144>
    8000547c:	00492603          	lw	a2,4(s2)
    80005480:	00003597          	auipc	a1,0x3
    80005484:	36058593          	addi	a1,a1,864 # 800087e0 <syscalls+0x2d8>
    80005488:	8526                	mv	a0,s1
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	be2080e7          	jalr	-1054(ra) # 8000406c <dirlink>
    80005492:	f80557e3          	bgez	a0,80005420 <create+0xce>
      panic("create dots");
    80005496:	00003517          	auipc	a0,0x3
    8000549a:	35250513          	addi	a0,a0,850 # 800087e8 <syscalls+0x2e0>
    8000549e:	ffffb097          	auipc	ra,0xffffb
    800054a2:	0aa080e7          	jalr	170(ra) # 80000548 <panic>
    panic("create: dirlink");
    800054a6:	00003517          	auipc	a0,0x3
    800054aa:	35250513          	addi	a0,a0,850 # 800087f8 <syscalls+0x2f0>
    800054ae:	ffffb097          	auipc	ra,0xffffb
    800054b2:	09a080e7          	jalr	154(ra) # 80000548 <panic>
    return 0;
    800054b6:	84aa                	mv	s1,a0
    800054b8:	b731                	j	800053c4 <create+0x72>

00000000800054ba <sys_dup>:
{
    800054ba:	7179                	addi	sp,sp,-48
    800054bc:	f406                	sd	ra,40(sp)
    800054be:	f022                	sd	s0,32(sp)
    800054c0:	ec26                	sd	s1,24(sp)
    800054c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054c4:	fd840613          	addi	a2,s0,-40
    800054c8:	4581                	li	a1,0
    800054ca:	4501                	li	a0,0
    800054cc:	00000097          	auipc	ra,0x0
    800054d0:	ddc080e7          	jalr	-548(ra) # 800052a8 <argfd>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054d6:	02054363          	bltz	a0,800054fc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054da:	fd843503          	ld	a0,-40(s0)
    800054de:	00000097          	auipc	ra,0x0
    800054e2:	e32080e7          	jalr	-462(ra) # 80005310 <fdalloc>
    800054e6:	84aa                	mv	s1,a0
    return -1;
    800054e8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054ea:	00054963          	bltz	a0,800054fc <sys_dup+0x42>
  filedup(f);
    800054ee:	fd843503          	ld	a0,-40(s0)
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	2c8080e7          	jalr	712(ra) # 800047ba <filedup>
  return fd;
    800054fa:	87a6                	mv	a5,s1
}
    800054fc:	853e                	mv	a0,a5
    800054fe:	70a2                	ld	ra,40(sp)
    80005500:	7402                	ld	s0,32(sp)
    80005502:	64e2                	ld	s1,24(sp)
    80005504:	6145                	addi	sp,sp,48
    80005506:	8082                	ret

0000000080005508 <sys_read>:
{
    80005508:	7179                	addi	sp,sp,-48
    8000550a:	f406                	sd	ra,40(sp)
    8000550c:	f022                	sd	s0,32(sp)
    8000550e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005510:	fe840613          	addi	a2,s0,-24
    80005514:	4581                	li	a1,0
    80005516:	4501                	li	a0,0
    80005518:	00000097          	auipc	ra,0x0
    8000551c:	d90080e7          	jalr	-624(ra) # 800052a8 <argfd>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005522:	04054163          	bltz	a0,80005564 <sys_read+0x5c>
    80005526:	fe440593          	addi	a1,s0,-28
    8000552a:	4509                	li	a0,2
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	8e0080e7          	jalr	-1824(ra) # 80002e0c <argint>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005536:	02054763          	bltz	a0,80005564 <sys_read+0x5c>
    8000553a:	fd840593          	addi	a1,s0,-40
    8000553e:	4505                	li	a0,1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	8ee080e7          	jalr	-1810(ra) # 80002e2e <argaddr>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554a:	00054d63          	bltz	a0,80005564 <sys_read+0x5c>
  return fileread(f, p, n);
    8000554e:	fe442603          	lw	a2,-28(s0)
    80005552:	fd843583          	ld	a1,-40(s0)
    80005556:	fe843503          	ld	a0,-24(s0)
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	3ec080e7          	jalr	1004(ra) # 80004946 <fileread>
    80005562:	87aa                	mv	a5,a0
}
    80005564:	853e                	mv	a0,a5
    80005566:	70a2                	ld	ra,40(sp)
    80005568:	7402                	ld	s0,32(sp)
    8000556a:	6145                	addi	sp,sp,48
    8000556c:	8082                	ret

000000008000556e <sys_write>:
{
    8000556e:	7179                	addi	sp,sp,-48
    80005570:	f406                	sd	ra,40(sp)
    80005572:	f022                	sd	s0,32(sp)
    80005574:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005576:	fe840613          	addi	a2,s0,-24
    8000557a:	4581                	li	a1,0
    8000557c:	4501                	li	a0,0
    8000557e:	00000097          	auipc	ra,0x0
    80005582:	d2a080e7          	jalr	-726(ra) # 800052a8 <argfd>
    return -1;
    80005586:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005588:	04054163          	bltz	a0,800055ca <sys_write+0x5c>
    8000558c:	fe440593          	addi	a1,s0,-28
    80005590:	4509                	li	a0,2
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	87a080e7          	jalr	-1926(ra) # 80002e0c <argint>
    return -1;
    8000559a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000559c:	02054763          	bltz	a0,800055ca <sys_write+0x5c>
    800055a0:	fd840593          	addi	a1,s0,-40
    800055a4:	4505                	li	a0,1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	888080e7          	jalr	-1912(ra) # 80002e2e <argaddr>
    return -1;
    800055ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b0:	00054d63          	bltz	a0,800055ca <sys_write+0x5c>
  return filewrite(f, p, n);
    800055b4:	fe442603          	lw	a2,-28(s0)
    800055b8:	fd843583          	ld	a1,-40(s0)
    800055bc:	fe843503          	ld	a0,-24(s0)
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	448080e7          	jalr	1096(ra) # 80004a08 <filewrite>
    800055c8:	87aa                	mv	a5,a0
}
    800055ca:	853e                	mv	a0,a5
    800055cc:	70a2                	ld	ra,40(sp)
    800055ce:	7402                	ld	s0,32(sp)
    800055d0:	6145                	addi	sp,sp,48
    800055d2:	8082                	ret

00000000800055d4 <sys_close>:
{
    800055d4:	1101                	addi	sp,sp,-32
    800055d6:	ec06                	sd	ra,24(sp)
    800055d8:	e822                	sd	s0,16(sp)
    800055da:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055dc:	fe040613          	addi	a2,s0,-32
    800055e0:	fec40593          	addi	a1,s0,-20
    800055e4:	4501                	li	a0,0
    800055e6:	00000097          	auipc	ra,0x0
    800055ea:	cc2080e7          	jalr	-830(ra) # 800052a8 <argfd>
    return -1;
    800055ee:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055f0:	02054463          	bltz	a0,80005618 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	5c8080e7          	jalr	1480(ra) # 80001bbc <myproc>
    800055fc:	fec42783          	lw	a5,-20(s0)
    80005600:	07e9                	addi	a5,a5,26
    80005602:	078e                	slli	a5,a5,0x3
    80005604:	97aa                	add	a5,a5,a0
    80005606:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000560a:	fe043503          	ld	a0,-32(s0)
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	1fe080e7          	jalr	510(ra) # 8000480c <fileclose>
  return 0;
    80005616:	4781                	li	a5,0
}
    80005618:	853e                	mv	a0,a5
    8000561a:	60e2                	ld	ra,24(sp)
    8000561c:	6442                	ld	s0,16(sp)
    8000561e:	6105                	addi	sp,sp,32
    80005620:	8082                	ret

0000000080005622 <sys_fstat>:
{
    80005622:	1101                	addi	sp,sp,-32
    80005624:	ec06                	sd	ra,24(sp)
    80005626:	e822                	sd	s0,16(sp)
    80005628:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000562a:	fe840613          	addi	a2,s0,-24
    8000562e:	4581                	li	a1,0
    80005630:	4501                	li	a0,0
    80005632:	00000097          	auipc	ra,0x0
    80005636:	c76080e7          	jalr	-906(ra) # 800052a8 <argfd>
    return -1;
    8000563a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000563c:	02054563          	bltz	a0,80005666 <sys_fstat+0x44>
    80005640:	fe040593          	addi	a1,s0,-32
    80005644:	4505                	li	a0,1
    80005646:	ffffd097          	auipc	ra,0xffffd
    8000564a:	7e8080e7          	jalr	2024(ra) # 80002e2e <argaddr>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005650:	00054b63          	bltz	a0,80005666 <sys_fstat+0x44>
  return filestat(f, st);
    80005654:	fe043583          	ld	a1,-32(s0)
    80005658:	fe843503          	ld	a0,-24(s0)
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	278080e7          	jalr	632(ra) # 800048d4 <filestat>
    80005664:	87aa                	mv	a5,a0
}
    80005666:	853e                	mv	a0,a5
    80005668:	60e2                	ld	ra,24(sp)
    8000566a:	6442                	ld	s0,16(sp)
    8000566c:	6105                	addi	sp,sp,32
    8000566e:	8082                	ret

0000000080005670 <sys_link>:
{
    80005670:	7169                	addi	sp,sp,-304
    80005672:	f606                	sd	ra,296(sp)
    80005674:	f222                	sd	s0,288(sp)
    80005676:	ee26                	sd	s1,280(sp)
    80005678:	ea4a                	sd	s2,272(sp)
    8000567a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000567c:	08000613          	li	a2,128
    80005680:	ed040593          	addi	a1,s0,-304
    80005684:	4501                	li	a0,0
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	7ca080e7          	jalr	1994(ra) # 80002e50 <argstr>
    return -1;
    8000568e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005690:	10054e63          	bltz	a0,800057ac <sys_link+0x13c>
    80005694:	08000613          	li	a2,128
    80005698:	f5040593          	addi	a1,s0,-176
    8000569c:	4505                	li	a0,1
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	7b2080e7          	jalr	1970(ra) # 80002e50 <argstr>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a8:	10054263          	bltz	a0,800057ac <sys_link+0x13c>
  begin_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	c8e080e7          	jalr	-882(ra) # 8000433a <begin_op>
  if((ip = namei(old)) == 0){
    800056b4:	ed040513          	addi	a0,s0,-304
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	a76080e7          	jalr	-1418(ra) # 8000412e <namei>
    800056c0:	84aa                	mv	s1,a0
    800056c2:	c551                	beqz	a0,8000574e <sys_link+0xde>
  ilock(ip);
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	2ba080e7          	jalr	698(ra) # 8000397e <ilock>
  if(ip->type == T_DIR){
    800056cc:	04449703          	lh	a4,68(s1)
    800056d0:	4785                	li	a5,1
    800056d2:	08f70463          	beq	a4,a5,8000575a <sys_link+0xea>
  ip->nlink++;
    800056d6:	04a4d783          	lhu	a5,74(s1)
    800056da:	2785                	addiw	a5,a5,1
    800056dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1d2080e7          	jalr	466(ra) # 800038b4 <iupdate>
  iunlock(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	354080e7          	jalr	852(ra) # 80003a40 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056f4:	fd040593          	addi	a1,s0,-48
    800056f8:	f5040513          	addi	a0,s0,-176
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	a50080e7          	jalr	-1456(ra) # 8000414c <nameiparent>
    80005704:	892a                	mv	s2,a0
    80005706:	c935                	beqz	a0,8000577a <sys_link+0x10a>
  ilock(dp);
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	276080e7          	jalr	630(ra) # 8000397e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005710:	00092703          	lw	a4,0(s2)
    80005714:	409c                	lw	a5,0(s1)
    80005716:	04f71d63          	bne	a4,a5,80005770 <sys_link+0x100>
    8000571a:	40d0                	lw	a2,4(s1)
    8000571c:	fd040593          	addi	a1,s0,-48
    80005720:	854a                	mv	a0,s2
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	94a080e7          	jalr	-1718(ra) # 8000406c <dirlink>
    8000572a:	04054363          	bltz	a0,80005770 <sys_link+0x100>
  iunlockput(dp);
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	4b0080e7          	jalr	1200(ra) # 80003be0 <iunlockput>
  iput(ip);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	3fe080e7          	jalr	1022(ra) # 80003b38 <iput>
  end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	c78080e7          	jalr	-904(ra) # 800043ba <end_op>
  return 0;
    8000574a:	4781                	li	a5,0
    8000574c:	a085                	j	800057ac <sys_link+0x13c>
    end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	c6c080e7          	jalr	-916(ra) # 800043ba <end_op>
    return -1;
    80005756:	57fd                	li	a5,-1
    80005758:	a891                	j	800057ac <sys_link+0x13c>
    iunlockput(ip);
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	484080e7          	jalr	1156(ra) # 80003be0 <iunlockput>
    end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	c56080e7          	jalr	-938(ra) # 800043ba <end_op>
    return -1;
    8000576c:	57fd                	li	a5,-1
    8000576e:	a83d                	j	800057ac <sys_link+0x13c>
    iunlockput(dp);
    80005770:	854a                	mv	a0,s2
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	46e080e7          	jalr	1134(ra) # 80003be0 <iunlockput>
  ilock(ip);
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	202080e7          	jalr	514(ra) # 8000397e <ilock>
  ip->nlink--;
    80005784:	04a4d783          	lhu	a5,74(s1)
    80005788:	37fd                	addiw	a5,a5,-1
    8000578a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	124080e7          	jalr	292(ra) # 800038b4 <iupdate>
  iunlockput(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	446080e7          	jalr	1094(ra) # 80003be0 <iunlockput>
  end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	c18080e7          	jalr	-1000(ra) # 800043ba <end_op>
  return -1;
    800057aa:	57fd                	li	a5,-1
}
    800057ac:	853e                	mv	a0,a5
    800057ae:	70b2                	ld	ra,296(sp)
    800057b0:	7412                	ld	s0,288(sp)
    800057b2:	64f2                	ld	s1,280(sp)
    800057b4:	6952                	ld	s2,272(sp)
    800057b6:	6155                	addi	sp,sp,304
    800057b8:	8082                	ret

00000000800057ba <sys_unlink>:
{
    800057ba:	7151                	addi	sp,sp,-240
    800057bc:	f586                	sd	ra,232(sp)
    800057be:	f1a2                	sd	s0,224(sp)
    800057c0:	eda6                	sd	s1,216(sp)
    800057c2:	e9ca                	sd	s2,208(sp)
    800057c4:	e5ce                	sd	s3,200(sp)
    800057c6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057c8:	08000613          	li	a2,128
    800057cc:	f3040593          	addi	a1,s0,-208
    800057d0:	4501                	li	a0,0
    800057d2:	ffffd097          	auipc	ra,0xffffd
    800057d6:	67e080e7          	jalr	1662(ra) # 80002e50 <argstr>
    800057da:	18054163          	bltz	a0,8000595c <sys_unlink+0x1a2>
  begin_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	b5c080e7          	jalr	-1188(ra) # 8000433a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057e6:	fb040593          	addi	a1,s0,-80
    800057ea:	f3040513          	addi	a0,s0,-208
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	95e080e7          	jalr	-1698(ra) # 8000414c <nameiparent>
    800057f6:	84aa                	mv	s1,a0
    800057f8:	c979                	beqz	a0,800058ce <sys_unlink+0x114>
  ilock(dp);
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	184080e7          	jalr	388(ra) # 8000397e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005802:	00003597          	auipc	a1,0x3
    80005806:	fd658593          	addi	a1,a1,-42 # 800087d8 <syscalls+0x2d0>
    8000580a:	fb040513          	addi	a0,s0,-80
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	634080e7          	jalr	1588(ra) # 80003e42 <namecmp>
    80005816:	14050a63          	beqz	a0,8000596a <sys_unlink+0x1b0>
    8000581a:	00003597          	auipc	a1,0x3
    8000581e:	fc658593          	addi	a1,a1,-58 # 800087e0 <syscalls+0x2d8>
    80005822:	fb040513          	addi	a0,s0,-80
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	61c080e7          	jalr	1564(ra) # 80003e42 <namecmp>
    8000582e:	12050e63          	beqz	a0,8000596a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005832:	f2c40613          	addi	a2,s0,-212
    80005836:	fb040593          	addi	a1,s0,-80
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	620080e7          	jalr	1568(ra) # 80003e5c <dirlookup>
    80005844:	892a                	mv	s2,a0
    80005846:	12050263          	beqz	a0,8000596a <sys_unlink+0x1b0>
  ilock(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	134080e7          	jalr	308(ra) # 8000397e <ilock>
  if(ip->nlink < 1)
    80005852:	04a91783          	lh	a5,74(s2)
    80005856:	08f05263          	blez	a5,800058da <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000585a:	04491703          	lh	a4,68(s2)
    8000585e:	4785                	li	a5,1
    80005860:	08f70563          	beq	a4,a5,800058ea <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005864:	4641                	li	a2,16
    80005866:	4581                	li	a1,0
    80005868:	fc040513          	addi	a0,s0,-64
    8000586c:	ffffb097          	auipc	ra,0xffffb
    80005870:	4a0080e7          	jalr	1184(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005874:	4741                	li	a4,16
    80005876:	f2c42683          	lw	a3,-212(s0)
    8000587a:	fc040613          	addi	a2,s0,-64
    8000587e:	4581                	li	a1,0
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	4a6080e7          	jalr	1190(ra) # 80003d28 <writei>
    8000588a:	47c1                	li	a5,16
    8000588c:	0af51563          	bne	a0,a5,80005936 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005890:	04491703          	lh	a4,68(s2)
    80005894:	4785                	li	a5,1
    80005896:	0af70863          	beq	a4,a5,80005946 <sys_unlink+0x18c>
  iunlockput(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	344080e7          	jalr	836(ra) # 80003be0 <iunlockput>
  ip->nlink--;
    800058a4:	04a95783          	lhu	a5,74(s2)
    800058a8:	37fd                	addiw	a5,a5,-1
    800058aa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	004080e7          	jalr	4(ra) # 800038b4 <iupdate>
  iunlockput(ip);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	326080e7          	jalr	806(ra) # 80003be0 <iunlockput>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	af8080e7          	jalr	-1288(ra) # 800043ba <end_op>
  return 0;
    800058ca:	4501                	li	a0,0
    800058cc:	a84d                	j	8000597e <sys_unlink+0x1c4>
    end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	aec080e7          	jalr	-1300(ra) # 800043ba <end_op>
    return -1;
    800058d6:	557d                	li	a0,-1
    800058d8:	a05d                	j	8000597e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058da:	00003517          	auipc	a0,0x3
    800058de:	f2e50513          	addi	a0,a0,-210 # 80008808 <syscalls+0x300>
    800058e2:	ffffb097          	auipc	ra,0xffffb
    800058e6:	c66080e7          	jalr	-922(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058ea:	04c92703          	lw	a4,76(s2)
    800058ee:	02000793          	li	a5,32
    800058f2:	f6e7f9e3          	bgeu	a5,a4,80005864 <sys_unlink+0xaa>
    800058f6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058fa:	4741                	li	a4,16
    800058fc:	86ce                	mv	a3,s3
    800058fe:	f1840613          	addi	a2,s0,-232
    80005902:	4581                	li	a1,0
    80005904:	854a                	mv	a0,s2
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	32c080e7          	jalr	812(ra) # 80003c32 <readi>
    8000590e:	47c1                	li	a5,16
    80005910:	00f51b63          	bne	a0,a5,80005926 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005914:	f1845783          	lhu	a5,-232(s0)
    80005918:	e7a1                	bnez	a5,80005960 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000591a:	29c1                	addiw	s3,s3,16
    8000591c:	04c92783          	lw	a5,76(s2)
    80005920:	fcf9ede3          	bltu	s3,a5,800058fa <sys_unlink+0x140>
    80005924:	b781                	j	80005864 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005926:	00003517          	auipc	a0,0x3
    8000592a:	efa50513          	addi	a0,a0,-262 # 80008820 <syscalls+0x318>
    8000592e:	ffffb097          	auipc	ra,0xffffb
    80005932:	c1a080e7          	jalr	-998(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005936:	00003517          	auipc	a0,0x3
    8000593a:	f0250513          	addi	a0,a0,-254 # 80008838 <syscalls+0x330>
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	c0a080e7          	jalr	-1014(ra) # 80000548 <panic>
    dp->nlink--;
    80005946:	04a4d783          	lhu	a5,74(s1)
    8000594a:	37fd                	addiw	a5,a5,-1
    8000594c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	f62080e7          	jalr	-158(ra) # 800038b4 <iupdate>
    8000595a:	b781                	j	8000589a <sys_unlink+0xe0>
    return -1;
    8000595c:	557d                	li	a0,-1
    8000595e:	a005                	j	8000597e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005960:	854a                	mv	a0,s2
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	27e080e7          	jalr	638(ra) # 80003be0 <iunlockput>
  iunlockput(dp);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	274080e7          	jalr	628(ra) # 80003be0 <iunlockput>
  end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	a46080e7          	jalr	-1466(ra) # 800043ba <end_op>
  return -1;
    8000597c:	557d                	li	a0,-1
}
    8000597e:	70ae                	ld	ra,232(sp)
    80005980:	740e                	ld	s0,224(sp)
    80005982:	64ee                	ld	s1,216(sp)
    80005984:	694e                	ld	s2,208(sp)
    80005986:	69ae                	ld	s3,200(sp)
    80005988:	616d                	addi	sp,sp,240
    8000598a:	8082                	ret

000000008000598c <sys_open>:

uint64
sys_open(void)
{
    8000598c:	7131                	addi	sp,sp,-192
    8000598e:	fd06                	sd	ra,184(sp)
    80005990:	f922                	sd	s0,176(sp)
    80005992:	f526                	sd	s1,168(sp)
    80005994:	f14a                	sd	s2,160(sp)
    80005996:	ed4e                	sd	s3,152(sp)
    80005998:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000599a:	08000613          	li	a2,128
    8000599e:	f5040593          	addi	a1,s0,-176
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	4ac080e7          	jalr	1196(ra) # 80002e50 <argstr>
    return -1;
    800059ac:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059ae:	0c054163          	bltz	a0,80005a70 <sys_open+0xe4>
    800059b2:	f4c40593          	addi	a1,s0,-180
    800059b6:	4505                	li	a0,1
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	454080e7          	jalr	1108(ra) # 80002e0c <argint>
    800059c0:	0a054863          	bltz	a0,80005a70 <sys_open+0xe4>

  begin_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	976080e7          	jalr	-1674(ra) # 8000433a <begin_op>

  if(omode & O_CREATE){
    800059cc:	f4c42783          	lw	a5,-180(s0)
    800059d0:	2007f793          	andi	a5,a5,512
    800059d4:	cbdd                	beqz	a5,80005a8a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059d6:	4681                	li	a3,0
    800059d8:	4601                	li	a2,0
    800059da:	4589                	li	a1,2
    800059dc:	f5040513          	addi	a0,s0,-176
    800059e0:	00000097          	auipc	ra,0x0
    800059e4:	972080e7          	jalr	-1678(ra) # 80005352 <create>
    800059e8:	892a                	mv	s2,a0
    if(ip == 0){
    800059ea:	c959                	beqz	a0,80005a80 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059ec:	04491703          	lh	a4,68(s2)
    800059f0:	478d                	li	a5,3
    800059f2:	00f71763          	bne	a4,a5,80005a00 <sys_open+0x74>
    800059f6:	04695703          	lhu	a4,70(s2)
    800059fa:	47a5                	li	a5,9
    800059fc:	0ce7ec63          	bltu	a5,a4,80005ad4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	d50080e7          	jalr	-688(ra) # 80004750 <filealloc>
    80005a08:	89aa                	mv	s3,a0
    80005a0a:	10050263          	beqz	a0,80005b0e <sys_open+0x182>
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	902080e7          	jalr	-1790(ra) # 80005310 <fdalloc>
    80005a16:	84aa                	mv	s1,a0
    80005a18:	0e054663          	bltz	a0,80005b04 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a1c:	04491703          	lh	a4,68(s2)
    80005a20:	478d                	li	a5,3
    80005a22:	0cf70463          	beq	a4,a5,80005aea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a26:	4789                	li	a5,2
    80005a28:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a2c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a30:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a34:	f4c42783          	lw	a5,-180(s0)
    80005a38:	0017c713          	xori	a4,a5,1
    80005a3c:	8b05                	andi	a4,a4,1
    80005a3e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a42:	0037f713          	andi	a4,a5,3
    80005a46:	00e03733          	snez	a4,a4
    80005a4a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a4e:	4007f793          	andi	a5,a5,1024
    80005a52:	c791                	beqz	a5,80005a5e <sys_open+0xd2>
    80005a54:	04491703          	lh	a4,68(s2)
    80005a58:	4789                	li	a5,2
    80005a5a:	08f70f63          	beq	a4,a5,80005af8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	fe0080e7          	jalr	-32(ra) # 80003a40 <iunlock>
  end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	952080e7          	jalr	-1710(ra) # 800043ba <end_op>

  return fd;
}
    80005a70:	8526                	mv	a0,s1
    80005a72:	70ea                	ld	ra,184(sp)
    80005a74:	744a                	ld	s0,176(sp)
    80005a76:	74aa                	ld	s1,168(sp)
    80005a78:	790a                	ld	s2,160(sp)
    80005a7a:	69ea                	ld	s3,152(sp)
    80005a7c:	6129                	addi	sp,sp,192
    80005a7e:	8082                	ret
      end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	93a080e7          	jalr	-1734(ra) # 800043ba <end_op>
      return -1;
    80005a88:	b7e5                	j	80005a70 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a8a:	f5040513          	addi	a0,s0,-176
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	6a0080e7          	jalr	1696(ra) # 8000412e <namei>
    80005a96:	892a                	mv	s2,a0
    80005a98:	c905                	beqz	a0,80005ac8 <sys_open+0x13c>
    ilock(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	ee4080e7          	jalr	-284(ra) # 8000397e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aa2:	04491703          	lh	a4,68(s2)
    80005aa6:	4785                	li	a5,1
    80005aa8:	f4f712e3          	bne	a4,a5,800059ec <sys_open+0x60>
    80005aac:	f4c42783          	lw	a5,-180(s0)
    80005ab0:	dba1                	beqz	a5,80005a00 <sys_open+0x74>
      iunlockput(ip);
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	12c080e7          	jalr	300(ra) # 80003be0 <iunlockput>
      end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	8fe080e7          	jalr	-1794(ra) # 800043ba <end_op>
      return -1;
    80005ac4:	54fd                	li	s1,-1
    80005ac6:	b76d                	j	80005a70 <sys_open+0xe4>
      end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	8f2080e7          	jalr	-1806(ra) # 800043ba <end_op>
      return -1;
    80005ad0:	54fd                	li	s1,-1
    80005ad2:	bf79                	j	80005a70 <sys_open+0xe4>
    iunlockput(ip);
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	10a080e7          	jalr	266(ra) # 80003be0 <iunlockput>
    end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	8dc080e7          	jalr	-1828(ra) # 800043ba <end_op>
    return -1;
    80005ae6:	54fd                	li	s1,-1
    80005ae8:	b761                	j	80005a70 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005aea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005aee:	04691783          	lh	a5,70(s2)
    80005af2:	02f99223          	sh	a5,36(s3)
    80005af6:	bf2d                	j	80005a30 <sys_open+0xa4>
    itrunc(ip);
    80005af8:	854a                	mv	a0,s2
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	f92080e7          	jalr	-110(ra) # 80003a8c <itrunc>
    80005b02:	bfb1                	j	80005a5e <sys_open+0xd2>
      fileclose(f);
    80005b04:	854e                	mv	a0,s3
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	d06080e7          	jalr	-762(ra) # 8000480c <fileclose>
    iunlockput(ip);
    80005b0e:	854a                	mv	a0,s2
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	0d0080e7          	jalr	208(ra) # 80003be0 <iunlockput>
    end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	8a2080e7          	jalr	-1886(ra) # 800043ba <end_op>
    return -1;
    80005b20:	54fd                	li	s1,-1
    80005b22:	b7b9                	j	80005a70 <sys_open+0xe4>

0000000080005b24 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b24:	7175                	addi	sp,sp,-144
    80005b26:	e506                	sd	ra,136(sp)
    80005b28:	e122                	sd	s0,128(sp)
    80005b2a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	80e080e7          	jalr	-2034(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b34:	08000613          	li	a2,128
    80005b38:	f7040593          	addi	a1,s0,-144
    80005b3c:	4501                	li	a0,0
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	312080e7          	jalr	786(ra) # 80002e50 <argstr>
    80005b46:	02054963          	bltz	a0,80005b78 <sys_mkdir+0x54>
    80005b4a:	4681                	li	a3,0
    80005b4c:	4601                	li	a2,0
    80005b4e:	4585                	li	a1,1
    80005b50:	f7040513          	addi	a0,s0,-144
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	7fe080e7          	jalr	2046(ra) # 80005352 <create>
    80005b5c:	cd11                	beqz	a0,80005b78 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	082080e7          	jalr	130(ra) # 80003be0 <iunlockput>
  end_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	854080e7          	jalr	-1964(ra) # 800043ba <end_op>
  return 0;
    80005b6e:	4501                	li	a0,0
}
    80005b70:	60aa                	ld	ra,136(sp)
    80005b72:	640a                	ld	s0,128(sp)
    80005b74:	6149                	addi	sp,sp,144
    80005b76:	8082                	ret
    end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	842080e7          	jalr	-1982(ra) # 800043ba <end_op>
    return -1;
    80005b80:	557d                	li	a0,-1
    80005b82:	b7fd                	j	80005b70 <sys_mkdir+0x4c>

0000000080005b84 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b84:	7135                	addi	sp,sp,-160
    80005b86:	ed06                	sd	ra,152(sp)
    80005b88:	e922                	sd	s0,144(sp)
    80005b8a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	7ae080e7          	jalr	1966(ra) # 8000433a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b94:	08000613          	li	a2,128
    80005b98:	f7040593          	addi	a1,s0,-144
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	2b2080e7          	jalr	690(ra) # 80002e50 <argstr>
    80005ba6:	04054a63          	bltz	a0,80005bfa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005baa:	f6c40593          	addi	a1,s0,-148
    80005bae:	4505                	li	a0,1
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	25c080e7          	jalr	604(ra) # 80002e0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb8:	04054163          	bltz	a0,80005bfa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bbc:	f6840593          	addi	a1,s0,-152
    80005bc0:	4509                	li	a0,2
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	24a080e7          	jalr	586(ra) # 80002e0c <argint>
     argint(1, &major) < 0 ||
    80005bca:	02054863          	bltz	a0,80005bfa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bce:	f6841683          	lh	a3,-152(s0)
    80005bd2:	f6c41603          	lh	a2,-148(s0)
    80005bd6:	458d                	li	a1,3
    80005bd8:	f7040513          	addi	a0,s0,-144
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	776080e7          	jalr	1910(ra) # 80005352 <create>
     argint(2, &minor) < 0 ||
    80005be4:	c919                	beqz	a0,80005bfa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	ffa080e7          	jalr	-6(ra) # 80003be0 <iunlockput>
  end_op();
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	7cc080e7          	jalr	1996(ra) # 800043ba <end_op>
  return 0;
    80005bf6:	4501                	li	a0,0
    80005bf8:	a031                	j	80005c04 <sys_mknod+0x80>
    end_op();
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	7c0080e7          	jalr	1984(ra) # 800043ba <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
}
    80005c04:	60ea                	ld	ra,152(sp)
    80005c06:	644a                	ld	s0,144(sp)
    80005c08:	610d                	addi	sp,sp,160
    80005c0a:	8082                	ret

0000000080005c0c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c0c:	7135                	addi	sp,sp,-160
    80005c0e:	ed06                	sd	ra,152(sp)
    80005c10:	e922                	sd	s0,144(sp)
    80005c12:	e526                	sd	s1,136(sp)
    80005c14:	e14a                	sd	s2,128(sp)
    80005c16:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	fa4080e7          	jalr	-92(ra) # 80001bbc <myproc>
    80005c20:	892a                	mv	s2,a0
  
  begin_op();
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	718080e7          	jalr	1816(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c2a:	08000613          	li	a2,128
    80005c2e:	f6040593          	addi	a1,s0,-160
    80005c32:	4501                	li	a0,0
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	21c080e7          	jalr	540(ra) # 80002e50 <argstr>
    80005c3c:	04054b63          	bltz	a0,80005c92 <sys_chdir+0x86>
    80005c40:	f6040513          	addi	a0,s0,-160
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	4ea080e7          	jalr	1258(ra) # 8000412e <namei>
    80005c4c:	84aa                	mv	s1,a0
    80005c4e:	c131                	beqz	a0,80005c92 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	d2e080e7          	jalr	-722(ra) # 8000397e <ilock>
  if(ip->type != T_DIR){
    80005c58:	04449703          	lh	a4,68(s1)
    80005c5c:	4785                	li	a5,1
    80005c5e:	04f71063          	bne	a4,a5,80005c9e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	ddc080e7          	jalr	-548(ra) # 80003a40 <iunlock>
  iput(p->cwd);
    80005c6c:	15893503          	ld	a0,344(s2)
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	ec8080e7          	jalr	-312(ra) # 80003b38 <iput>
  end_op();
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	742080e7          	jalr	1858(ra) # 800043ba <end_op>
  p->cwd = ip;
    80005c80:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c84:	4501                	li	a0,0
}
    80005c86:	60ea                	ld	ra,152(sp)
    80005c88:	644a                	ld	s0,144(sp)
    80005c8a:	64aa                	ld	s1,136(sp)
    80005c8c:	690a                	ld	s2,128(sp)
    80005c8e:	610d                	addi	sp,sp,160
    80005c90:	8082                	ret
    end_op();
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	728080e7          	jalr	1832(ra) # 800043ba <end_op>
    return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	b7ed                	j	80005c86 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	f40080e7          	jalr	-192(ra) # 80003be0 <iunlockput>
    end_op();
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	712080e7          	jalr	1810(ra) # 800043ba <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	bfd1                	j	80005c86 <sys_chdir+0x7a>

0000000080005cb4 <sys_exec>:

uint64
sys_exec(void)
{
    80005cb4:	7145                	addi	sp,sp,-464
    80005cb6:	e786                	sd	ra,456(sp)
    80005cb8:	e3a2                	sd	s0,448(sp)
    80005cba:	ff26                	sd	s1,440(sp)
    80005cbc:	fb4a                	sd	s2,432(sp)
    80005cbe:	f74e                	sd	s3,424(sp)
    80005cc0:	f352                	sd	s4,416(sp)
    80005cc2:	ef56                	sd	s5,408(sp)
    80005cc4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cc6:	08000613          	li	a2,128
    80005cca:	f4040593          	addi	a1,s0,-192
    80005cce:	4501                	li	a0,0
    80005cd0:	ffffd097          	auipc	ra,0xffffd
    80005cd4:	180080e7          	jalr	384(ra) # 80002e50 <argstr>
    return -1;
    80005cd8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cda:	0c054a63          	bltz	a0,80005dae <sys_exec+0xfa>
    80005cde:	e3840593          	addi	a1,s0,-456
    80005ce2:	4505                	li	a0,1
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	14a080e7          	jalr	330(ra) # 80002e2e <argaddr>
    80005cec:	0c054163          	bltz	a0,80005dae <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cf0:	10000613          	li	a2,256
    80005cf4:	4581                	li	a1,0
    80005cf6:	e4040513          	addi	a0,s0,-448
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	012080e7          	jalr	18(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d02:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d06:	89a6                	mv	s3,s1
    80005d08:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d0a:	02000a13          	li	s4,32
    80005d0e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d12:	00391513          	slli	a0,s2,0x3
    80005d16:	e3040593          	addi	a1,s0,-464
    80005d1a:	e3843783          	ld	a5,-456(s0)
    80005d1e:	953e                	add	a0,a0,a5
    80005d20:	ffffd097          	auipc	ra,0xffffd
    80005d24:	052080e7          	jalr	82(ra) # 80002d72 <fetchaddr>
    80005d28:	02054a63          	bltz	a0,80005d5c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d2c:	e3043783          	ld	a5,-464(s0)
    80005d30:	c3b9                	beqz	a5,80005d76 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	dee080e7          	jalr	-530(ra) # 80000b20 <kalloc>
    80005d3a:	85aa                	mv	a1,a0
    80005d3c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d40:	cd11                	beqz	a0,80005d5c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d42:	6605                	lui	a2,0x1
    80005d44:	e3043503          	ld	a0,-464(s0)
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	07c080e7          	jalr	124(ra) # 80002dc4 <fetchstr>
    80005d50:	00054663          	bltz	a0,80005d5c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d54:	0905                	addi	s2,s2,1
    80005d56:	09a1                	addi	s3,s3,8
    80005d58:	fb491be3          	bne	s2,s4,80005d0e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5c:	10048913          	addi	s2,s1,256
    80005d60:	6088                	ld	a0,0(s1)
    80005d62:	c529                	beqz	a0,80005dac <sys_exec+0xf8>
    kfree(argv[i]);
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	cc0080e7          	jalr	-832(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6c:	04a1                	addi	s1,s1,8
    80005d6e:	ff2499e3          	bne	s1,s2,80005d60 <sys_exec+0xac>
  return -1;
    80005d72:	597d                	li	s2,-1
    80005d74:	a82d                	j	80005dae <sys_exec+0xfa>
      argv[i] = 0;
    80005d76:	0a8e                	slli	s5,s5,0x3
    80005d78:	fc040793          	addi	a5,s0,-64
    80005d7c:	9abe                	add	s5,s5,a5
    80005d7e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d82:	e4040593          	addi	a1,s0,-448
    80005d86:	f4040513          	addi	a0,s0,-192
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	132080e7          	jalr	306(ra) # 80004ebc <exec>
    80005d92:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d94:	10048993          	addi	s3,s1,256
    80005d98:	6088                	ld	a0,0(s1)
    80005d9a:	c911                	beqz	a0,80005dae <sys_exec+0xfa>
    kfree(argv[i]);
    80005d9c:	ffffb097          	auipc	ra,0xffffb
    80005da0:	c88080e7          	jalr	-888(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da4:	04a1                	addi	s1,s1,8
    80005da6:	ff3499e3          	bne	s1,s3,80005d98 <sys_exec+0xe4>
    80005daa:	a011                	j	80005dae <sys_exec+0xfa>
  return -1;
    80005dac:	597d                	li	s2,-1
}
    80005dae:	854a                	mv	a0,s2
    80005db0:	60be                	ld	ra,456(sp)
    80005db2:	641e                	ld	s0,448(sp)
    80005db4:	74fa                	ld	s1,440(sp)
    80005db6:	795a                	ld	s2,432(sp)
    80005db8:	79ba                	ld	s3,424(sp)
    80005dba:	7a1a                	ld	s4,416(sp)
    80005dbc:	6afa                	ld	s5,408(sp)
    80005dbe:	6179                	addi	sp,sp,464
    80005dc0:	8082                	ret

0000000080005dc2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dc2:	7139                	addi	sp,sp,-64
    80005dc4:	fc06                	sd	ra,56(sp)
    80005dc6:	f822                	sd	s0,48(sp)
    80005dc8:	f426                	sd	s1,40(sp)
    80005dca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dcc:	ffffc097          	auipc	ra,0xffffc
    80005dd0:	df0080e7          	jalr	-528(ra) # 80001bbc <myproc>
    80005dd4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005dd6:	fd840593          	addi	a1,s0,-40
    80005dda:	4501                	li	a0,0
    80005ddc:	ffffd097          	auipc	ra,0xffffd
    80005de0:	052080e7          	jalr	82(ra) # 80002e2e <argaddr>
    return -1;
    80005de4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005de6:	0e054063          	bltz	a0,80005ec6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005dea:	fc840593          	addi	a1,s0,-56
    80005dee:	fd040513          	addi	a0,s0,-48
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	d70080e7          	jalr	-656(ra) # 80004b62 <pipealloc>
    return -1;
    80005dfa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dfc:	0c054563          	bltz	a0,80005ec6 <sys_pipe+0x104>
  fd0 = -1;
    80005e00:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e04:	fd043503          	ld	a0,-48(s0)
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	508080e7          	jalr	1288(ra) # 80005310 <fdalloc>
    80005e10:	fca42223          	sw	a0,-60(s0)
    80005e14:	08054c63          	bltz	a0,80005eac <sys_pipe+0xea>
    80005e18:	fc843503          	ld	a0,-56(s0)
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	4f4080e7          	jalr	1268(ra) # 80005310 <fdalloc>
    80005e24:	fca42023          	sw	a0,-64(s0)
    80005e28:	06054863          	bltz	a0,80005e98 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2c:	4691                	li	a3,4
    80005e2e:	fc440613          	addi	a2,s0,-60
    80005e32:	fd843583          	ld	a1,-40(s0)
    80005e36:	68a8                	ld	a0,80(s1)
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	9f4080e7          	jalr	-1548(ra) # 8000182c <copyout>
    80005e40:	02054063          	bltz	a0,80005e60 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e44:	4691                	li	a3,4
    80005e46:	fc040613          	addi	a2,s0,-64
    80005e4a:	fd843583          	ld	a1,-40(s0)
    80005e4e:	0591                	addi	a1,a1,4
    80005e50:	68a8                	ld	a0,80(s1)
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	9da080e7          	jalr	-1574(ra) # 8000182c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e5a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5c:	06055563          	bgez	a0,80005ec6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e60:	fc442783          	lw	a5,-60(s0)
    80005e64:	07e9                	addi	a5,a5,26
    80005e66:	078e                	slli	a5,a5,0x3
    80005e68:	97a6                	add	a5,a5,s1
    80005e6a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e6e:	fc042503          	lw	a0,-64(s0)
    80005e72:	0569                	addi	a0,a0,26
    80005e74:	050e                	slli	a0,a0,0x3
    80005e76:	9526                	add	a0,a0,s1
    80005e78:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e7c:	fd043503          	ld	a0,-48(s0)
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	98c080e7          	jalr	-1652(ra) # 8000480c <fileclose>
    fileclose(wf);
    80005e88:	fc843503          	ld	a0,-56(s0)
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	980080e7          	jalr	-1664(ra) # 8000480c <fileclose>
    return -1;
    80005e94:	57fd                	li	a5,-1
    80005e96:	a805                	j	80005ec6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e98:	fc442783          	lw	a5,-60(s0)
    80005e9c:	0007c863          	bltz	a5,80005eac <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ea0:	01a78513          	addi	a0,a5,26
    80005ea4:	050e                	slli	a0,a0,0x3
    80005ea6:	9526                	add	a0,a0,s1
    80005ea8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005eac:	fd043503          	ld	a0,-48(s0)
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	95c080e7          	jalr	-1700(ra) # 8000480c <fileclose>
    fileclose(wf);
    80005eb8:	fc843503          	ld	a0,-56(s0)
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	950080e7          	jalr	-1712(ra) # 8000480c <fileclose>
    return -1;
    80005ec4:	57fd                	li	a5,-1
}
    80005ec6:	853e                	mv	a0,a5
    80005ec8:	70e2                	ld	ra,56(sp)
    80005eca:	7442                	ld	s0,48(sp)
    80005ecc:	74a2                	ld	s1,40(sp)
    80005ece:	6121                	addi	sp,sp,64
    80005ed0:	8082                	ret
	...

0000000080005ee0 <kernelvec>:
    80005ee0:	7111                	addi	sp,sp,-256
    80005ee2:	e006                	sd	ra,0(sp)
    80005ee4:	e40a                	sd	sp,8(sp)
    80005ee6:	e80e                	sd	gp,16(sp)
    80005ee8:	ec12                	sd	tp,24(sp)
    80005eea:	f016                	sd	t0,32(sp)
    80005eec:	f41a                	sd	t1,40(sp)
    80005eee:	f81e                	sd	t2,48(sp)
    80005ef0:	fc22                	sd	s0,56(sp)
    80005ef2:	e0a6                	sd	s1,64(sp)
    80005ef4:	e4aa                	sd	a0,72(sp)
    80005ef6:	e8ae                	sd	a1,80(sp)
    80005ef8:	ecb2                	sd	a2,88(sp)
    80005efa:	f0b6                	sd	a3,96(sp)
    80005efc:	f4ba                	sd	a4,104(sp)
    80005efe:	f8be                	sd	a5,112(sp)
    80005f00:	fcc2                	sd	a6,120(sp)
    80005f02:	e146                	sd	a7,128(sp)
    80005f04:	e54a                	sd	s2,136(sp)
    80005f06:	e94e                	sd	s3,144(sp)
    80005f08:	ed52                	sd	s4,152(sp)
    80005f0a:	f156                	sd	s5,160(sp)
    80005f0c:	f55a                	sd	s6,168(sp)
    80005f0e:	f95e                	sd	s7,176(sp)
    80005f10:	fd62                	sd	s8,184(sp)
    80005f12:	e1e6                	sd	s9,192(sp)
    80005f14:	e5ea                	sd	s10,200(sp)
    80005f16:	e9ee                	sd	s11,208(sp)
    80005f18:	edf2                	sd	t3,216(sp)
    80005f1a:	f1f6                	sd	t4,224(sp)
    80005f1c:	f5fa                	sd	t5,232(sp)
    80005f1e:	f9fe                	sd	t6,240(sp)
    80005f20:	d1ffc0ef          	jal	ra,80002c3e <kerneltrap>
    80005f24:	6082                	ld	ra,0(sp)
    80005f26:	6122                	ld	sp,8(sp)
    80005f28:	61c2                	ld	gp,16(sp)
    80005f2a:	7282                	ld	t0,32(sp)
    80005f2c:	7322                	ld	t1,40(sp)
    80005f2e:	73c2                	ld	t2,48(sp)
    80005f30:	7462                	ld	s0,56(sp)
    80005f32:	6486                	ld	s1,64(sp)
    80005f34:	6526                	ld	a0,72(sp)
    80005f36:	65c6                	ld	a1,80(sp)
    80005f38:	6666                	ld	a2,88(sp)
    80005f3a:	7686                	ld	a3,96(sp)
    80005f3c:	7726                	ld	a4,104(sp)
    80005f3e:	77c6                	ld	a5,112(sp)
    80005f40:	7866                	ld	a6,120(sp)
    80005f42:	688a                	ld	a7,128(sp)
    80005f44:	692a                	ld	s2,136(sp)
    80005f46:	69ca                	ld	s3,144(sp)
    80005f48:	6a6a                	ld	s4,152(sp)
    80005f4a:	7a8a                	ld	s5,160(sp)
    80005f4c:	7b2a                	ld	s6,168(sp)
    80005f4e:	7bca                	ld	s7,176(sp)
    80005f50:	7c6a                	ld	s8,184(sp)
    80005f52:	6c8e                	ld	s9,192(sp)
    80005f54:	6d2e                	ld	s10,200(sp)
    80005f56:	6dce                	ld	s11,208(sp)
    80005f58:	6e6e                	ld	t3,216(sp)
    80005f5a:	7e8e                	ld	t4,224(sp)
    80005f5c:	7f2e                	ld	t5,232(sp)
    80005f5e:	7fce                	ld	t6,240(sp)
    80005f60:	6111                	addi	sp,sp,256
    80005f62:	10200073          	sret
    80005f66:	00000013          	nop
    80005f6a:	00000013          	nop
    80005f6e:	0001                	nop

0000000080005f70 <timervec>:
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	e10c                	sd	a1,0(a0)
    80005f76:	e510                	sd	a2,8(a0)
    80005f78:	e914                	sd	a3,16(a0)
    80005f7a:	710c                	ld	a1,32(a0)
    80005f7c:	7510                	ld	a2,40(a0)
    80005f7e:	6194                	ld	a3,0(a1)
    80005f80:	96b2                	add	a3,a3,a2
    80005f82:	e194                	sd	a3,0(a1)
    80005f84:	4589                	li	a1,2
    80005f86:	14459073          	csrw	sip,a1
    80005f8a:	6914                	ld	a3,16(a0)
    80005f8c:	6510                	ld	a2,8(a0)
    80005f8e:	610c                	ld	a1,0(a0)
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	30200073          	mret
	...

0000000080005f9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f9a:	1141                	addi	sp,sp,-16
    80005f9c:	e422                	sd	s0,8(sp)
    80005f9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fa0:	0c0007b7          	lui	a5,0xc000
    80005fa4:	4705                	li	a4,1
    80005fa6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fa8:	c3d8                	sw	a4,4(a5)
}
    80005faa:	6422                	ld	s0,8(sp)
    80005fac:	0141                	addi	sp,sp,16
    80005fae:	8082                	ret

0000000080005fb0 <plicinithart>:

void
plicinithart(void)
{
    80005fb0:	1141                	addi	sp,sp,-16
    80005fb2:	e406                	sd	ra,8(sp)
    80005fb4:	e022                	sd	s0,0(sp)
    80005fb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	bd8080e7          	jalr	-1064(ra) # 80001b90 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fc0:	0085171b          	slliw	a4,a0,0x8
    80005fc4:	0c0027b7          	lui	a5,0xc002
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	40200713          	li	a4,1026
    80005fce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fd2:	00d5151b          	slliw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	953e                	add	a0,a0,a5
    80005fdc:	00052023          	sw	zero,0(a0)
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	addi	sp,sp,16
    80005fe6:	8082                	ret

0000000080005fe8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fe8:	1141                	addi	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	ba0080e7          	jalr	-1120(ra) # 80001b90 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ff8:	00d5179b          	slliw	a5,a0,0xd
    80005ffc:	0c201537          	lui	a0,0xc201
    80006000:	953e                	add	a0,a0,a5
  return irq;
}
    80006002:	4148                	lw	a0,4(a0)
    80006004:	60a2                	ld	ra,8(sp)
    80006006:	6402                	ld	s0,0(sp)
    80006008:	0141                	addi	sp,sp,16
    8000600a:	8082                	ret

000000008000600c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000600c:	1101                	addi	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	1000                	addi	s0,sp,32
    80006016:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	b78080e7          	jalr	-1160(ra) # 80001b90 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006020:	00d5151b          	slliw	a0,a0,0xd
    80006024:	0c2017b7          	lui	a5,0xc201
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	c3c4                	sw	s1,4(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret

0000000080006036 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006036:	1141                	addi	sp,sp,-16
    80006038:	e406                	sd	ra,8(sp)
    8000603a:	e022                	sd	s0,0(sp)
    8000603c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000603e:	479d                	li	a5,7
    80006040:	04a7cc63          	blt	a5,a0,80006098 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006044:	0001d797          	auipc	a5,0x1d
    80006048:	fbc78793          	addi	a5,a5,-68 # 80023000 <disk>
    8000604c:	00a78733          	add	a4,a5,a0
    80006050:	6789                	lui	a5,0x2
    80006052:	97ba                	add	a5,a5,a4
    80006054:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006058:	eba1                	bnez	a5,800060a8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000605a:	00451713          	slli	a4,a0,0x4
    8000605e:	0001f797          	auipc	a5,0x1f
    80006062:	fa27b783          	ld	a5,-94(a5) # 80025000 <disk+0x2000>
    80006066:	97ba                	add	a5,a5,a4
    80006068:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000606c:	0001d797          	auipc	a5,0x1d
    80006070:	f9478793          	addi	a5,a5,-108 # 80023000 <disk>
    80006074:	97aa                	add	a5,a5,a0
    80006076:	6509                	lui	a0,0x2
    80006078:	953e                	add	a0,a0,a5
    8000607a:	4785                	li	a5,1
    8000607c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006080:	0001f517          	auipc	a0,0x1f
    80006084:	f9850513          	addi	a0,a0,-104 # 80025018 <disk+0x2018>
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	65c080e7          	jalr	1628(ra) # 800026e4 <wakeup>
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret
    panic("virtio_disk_intr 1");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	7b050513          	addi	a0,a0,1968 # 80008848 <syscalls+0x340>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a8080e7          	jalr	1192(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	7b850513          	addi	a0,a0,1976 # 80008860 <syscalls+0x358>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	498080e7          	jalr	1176(ra) # 80000548 <panic>

00000000800060b8 <virtio_disk_init>:
{
    800060b8:	1101                	addi	sp,sp,-32
    800060ba:	ec06                	sd	ra,24(sp)
    800060bc:	e822                	sd	s0,16(sp)
    800060be:	e426                	sd	s1,8(sp)
    800060c0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060c2:	00002597          	auipc	a1,0x2
    800060c6:	7b658593          	addi	a1,a1,1974 # 80008878 <syscalls+0x370>
    800060ca:	0001f517          	auipc	a0,0x1f
    800060ce:	fde50513          	addi	a0,a0,-34 # 800250a8 <disk+0x20a8>
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	aae080e7          	jalr	-1362(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060da:	100017b7          	lui	a5,0x10001
    800060de:	4398                	lw	a4,0(a5)
    800060e0:	2701                	sext.w	a4,a4
    800060e2:	747277b7          	lui	a5,0x74727
    800060e6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ea:	0ef71163          	bne	a4,a5,800061cc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	43dc                	lw	a5,4(a5)
    800060f4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f6:	4705                	li	a4,1
    800060f8:	0ce79a63          	bne	a5,a4,800061cc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060fc:	100017b7          	lui	a5,0x10001
    80006100:	479c                	lw	a5,8(a5)
    80006102:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006104:	4709                	li	a4,2
    80006106:	0ce79363          	bne	a5,a4,800061cc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000610a:	100017b7          	lui	a5,0x10001
    8000610e:	47d8                	lw	a4,12(a5)
    80006110:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006112:	554d47b7          	lui	a5,0x554d4
    80006116:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000611a:	0af71963          	bne	a4,a5,800061cc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	4705                	li	a4,1
    80006124:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006126:	470d                	li	a4,3
    80006128:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000612a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000612c:	c7ffe737          	lui	a4,0xc7ffe
    80006130:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006134:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006136:	2701                	sext.w	a4,a4
    80006138:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613a:	472d                	li	a4,11
    8000613c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613e:	473d                	li	a4,15
    80006140:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006142:	6705                	lui	a4,0x1
    80006144:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006146:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000614a:	5bdc                	lw	a5,52(a5)
    8000614c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000614e:	c7d9                	beqz	a5,800061dc <virtio_disk_init+0x124>
  if(max < NUM)
    80006150:	471d                	li	a4,7
    80006152:	08f77d63          	bgeu	a4,a5,800061ec <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006156:	100014b7          	lui	s1,0x10001
    8000615a:	47a1                	li	a5,8
    8000615c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000615e:	6609                	lui	a2,0x2
    80006160:	4581                	li	a1,0
    80006162:	0001d517          	auipc	a0,0x1d
    80006166:	e9e50513          	addi	a0,a0,-354 # 80023000 <disk>
    8000616a:	ffffb097          	auipc	ra,0xffffb
    8000616e:	ba2080e7          	jalr	-1118(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006172:	0001d717          	auipc	a4,0x1d
    80006176:	e8e70713          	addi	a4,a4,-370 # 80023000 <disk>
    8000617a:	00c75793          	srli	a5,a4,0xc
    8000617e:	2781                	sext.w	a5,a5
    80006180:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006182:	0001f797          	auipc	a5,0x1f
    80006186:	e7e78793          	addi	a5,a5,-386 # 80025000 <disk+0x2000>
    8000618a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000618c:	0001d717          	auipc	a4,0x1d
    80006190:	ef470713          	addi	a4,a4,-268 # 80023080 <disk+0x80>
    80006194:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006196:	0001e717          	auipc	a4,0x1e
    8000619a:	e6a70713          	addi	a4,a4,-406 # 80024000 <disk+0x1000>
    8000619e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061a0:	4705                	li	a4,1
    800061a2:	00e78c23          	sb	a4,24(a5)
    800061a6:	00e78ca3          	sb	a4,25(a5)
    800061aa:	00e78d23          	sb	a4,26(a5)
    800061ae:	00e78da3          	sb	a4,27(a5)
    800061b2:	00e78e23          	sb	a4,28(a5)
    800061b6:	00e78ea3          	sb	a4,29(a5)
    800061ba:	00e78f23          	sb	a4,30(a5)
    800061be:	00e78fa3          	sb	a4,31(a5)
}
    800061c2:	60e2                	ld	ra,24(sp)
    800061c4:	6442                	ld	s0,16(sp)
    800061c6:	64a2                	ld	s1,8(sp)
    800061c8:	6105                	addi	sp,sp,32
    800061ca:	8082                	ret
    panic("could not find virtio disk");
    800061cc:	00002517          	auipc	a0,0x2
    800061d0:	6bc50513          	addi	a0,a0,1724 # 80008888 <syscalls+0x380>
    800061d4:	ffffa097          	auipc	ra,0xffffa
    800061d8:	374080e7          	jalr	884(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800061dc:	00002517          	auipc	a0,0x2
    800061e0:	6cc50513          	addi	a0,a0,1740 # 800088a8 <syscalls+0x3a0>
    800061e4:	ffffa097          	auipc	ra,0xffffa
    800061e8:	364080e7          	jalr	868(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800061ec:	00002517          	auipc	a0,0x2
    800061f0:	6dc50513          	addi	a0,a0,1756 # 800088c8 <syscalls+0x3c0>
    800061f4:	ffffa097          	auipc	ra,0xffffa
    800061f8:	354080e7          	jalr	852(ra) # 80000548 <panic>

00000000800061fc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061fc:	7119                	addi	sp,sp,-128
    800061fe:	fc86                	sd	ra,120(sp)
    80006200:	f8a2                	sd	s0,112(sp)
    80006202:	f4a6                	sd	s1,104(sp)
    80006204:	f0ca                	sd	s2,96(sp)
    80006206:	ecce                	sd	s3,88(sp)
    80006208:	e8d2                	sd	s4,80(sp)
    8000620a:	e4d6                	sd	s5,72(sp)
    8000620c:	e0da                	sd	s6,64(sp)
    8000620e:	fc5e                	sd	s7,56(sp)
    80006210:	f862                	sd	s8,48(sp)
    80006212:	f466                	sd	s9,40(sp)
    80006214:	f06a                	sd	s10,32(sp)
    80006216:	0100                	addi	s0,sp,128
    80006218:	892a                	mv	s2,a0
    8000621a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000621c:	00c52c83          	lw	s9,12(a0)
    80006220:	001c9c9b          	slliw	s9,s9,0x1
    80006224:	1c82                	slli	s9,s9,0x20
    80006226:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000622a:	0001f517          	auipc	a0,0x1f
    8000622e:	e7e50513          	addi	a0,a0,-386 # 800250a8 <disk+0x20a8>
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	9de080e7          	jalr	-1570(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000623a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000623c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000623e:	0001db97          	auipc	s7,0x1d
    80006242:	dc2b8b93          	addi	s7,s7,-574 # 80023000 <disk>
    80006246:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006248:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000624a:	8a4e                	mv	s4,s3
    8000624c:	a051                	j	800062d0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000624e:	00fb86b3          	add	a3,s7,a5
    80006252:	96da                	add	a3,a3,s6
    80006254:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006258:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000625a:	0207c563          	bltz	a5,80006284 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000625e:	2485                	addiw	s1,s1,1
    80006260:	0711                	addi	a4,a4,4
    80006262:	23548d63          	beq	s1,s5,8000649c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006266:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006268:	0001f697          	auipc	a3,0x1f
    8000626c:	db068693          	addi	a3,a3,-592 # 80025018 <disk+0x2018>
    80006270:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006272:	0006c583          	lbu	a1,0(a3)
    80006276:	fde1                	bnez	a1,8000624e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006278:	2785                	addiw	a5,a5,1
    8000627a:	0685                	addi	a3,a3,1
    8000627c:	ff879be3          	bne	a5,s8,80006272 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006280:	57fd                	li	a5,-1
    80006282:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006284:	02905a63          	blez	s1,800062b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006288:	f9042503          	lw	a0,-112(s0)
    8000628c:	00000097          	auipc	ra,0x0
    80006290:	daa080e7          	jalr	-598(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    80006294:	4785                	li	a5,1
    80006296:	0297d163          	bge	a5,s1,800062b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000629a:	f9442503          	lw	a0,-108(s0)
    8000629e:	00000097          	auipc	ra,0x0
    800062a2:	d98080e7          	jalr	-616(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    800062a6:	4789                	li	a5,2
    800062a8:	0097d863          	bge	a5,s1,800062b8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062ac:	f9842503          	lw	a0,-104(s0)
    800062b0:	00000097          	auipc	ra,0x0
    800062b4:	d86080e7          	jalr	-634(ra) # 80006036 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062b8:	0001f597          	auipc	a1,0x1f
    800062bc:	df058593          	addi	a1,a1,-528 # 800250a8 <disk+0x20a8>
    800062c0:	0001f517          	auipc	a0,0x1f
    800062c4:	d5850513          	addi	a0,a0,-680 # 80025018 <disk+0x2018>
    800062c8:	ffffc097          	auipc	ra,0xffffc
    800062cc:	296080e7          	jalr	662(ra) # 8000255e <sleep>
  for(int i = 0; i < 3; i++){
    800062d0:	f9040713          	addi	a4,s0,-112
    800062d4:	84ce                	mv	s1,s3
    800062d6:	bf41                	j	80006266 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800062d8:	4785                	li	a5,1
    800062da:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800062de:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800062e2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062e6:	f9042983          	lw	s3,-112(s0)
    800062ea:	00499493          	slli	s1,s3,0x4
    800062ee:	0001fa17          	auipc	s4,0x1f
    800062f2:	d12a0a13          	addi	s4,s4,-750 # 80025000 <disk+0x2000>
    800062f6:	000a3a83          	ld	s5,0(s4)
    800062fa:	9aa6                	add	s5,s5,s1
    800062fc:	f8040513          	addi	a0,s0,-128
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	de8080e7          	jalr	-536(ra) # 800010e8 <kvmpa>
    80006308:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000630c:	000a3783          	ld	a5,0(s4)
    80006310:	97a6                	add	a5,a5,s1
    80006312:	4741                	li	a4,16
    80006314:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006316:	000a3783          	ld	a5,0(s4)
    8000631a:	97a6                	add	a5,a5,s1
    8000631c:	4705                	li	a4,1
    8000631e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006322:	f9442703          	lw	a4,-108(s0)
    80006326:	000a3783          	ld	a5,0(s4)
    8000632a:	97a6                	add	a5,a5,s1
    8000632c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006330:	0712                	slli	a4,a4,0x4
    80006332:	000a3783          	ld	a5,0(s4)
    80006336:	97ba                	add	a5,a5,a4
    80006338:	05890693          	addi	a3,s2,88
    8000633c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000633e:	000a3783          	ld	a5,0(s4)
    80006342:	97ba                	add	a5,a5,a4
    80006344:	40000693          	li	a3,1024
    80006348:	c794                	sw	a3,8(a5)
  if(write)
    8000634a:	100d0a63          	beqz	s10,8000645e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000634e:	0001f797          	auipc	a5,0x1f
    80006352:	cb27b783          	ld	a5,-846(a5) # 80025000 <disk+0x2000>
    80006356:	97ba                	add	a5,a5,a4
    80006358:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000635c:	0001d517          	auipc	a0,0x1d
    80006360:	ca450513          	addi	a0,a0,-860 # 80023000 <disk>
    80006364:	0001f797          	auipc	a5,0x1f
    80006368:	c9c78793          	addi	a5,a5,-868 # 80025000 <disk+0x2000>
    8000636c:	6394                	ld	a3,0(a5)
    8000636e:	96ba                	add	a3,a3,a4
    80006370:	00c6d603          	lhu	a2,12(a3)
    80006374:	00166613          	ori	a2,a2,1
    80006378:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000637c:	f9842683          	lw	a3,-104(s0)
    80006380:	6390                	ld	a2,0(a5)
    80006382:	9732                	add	a4,a4,a2
    80006384:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006388:	20098613          	addi	a2,s3,512
    8000638c:	0612                	slli	a2,a2,0x4
    8000638e:	962a                	add	a2,a2,a0
    80006390:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006394:	00469713          	slli	a4,a3,0x4
    80006398:	6394                	ld	a3,0(a5)
    8000639a:	96ba                	add	a3,a3,a4
    8000639c:	6589                	lui	a1,0x2
    8000639e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800063a2:	94ae                	add	s1,s1,a1
    800063a4:	94aa                	add	s1,s1,a0
    800063a6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800063a8:	6394                	ld	a3,0(a5)
    800063aa:	96ba                	add	a3,a3,a4
    800063ac:	4585                	li	a1,1
    800063ae:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063b0:	6394                	ld	a3,0(a5)
    800063b2:	96ba                	add	a3,a3,a4
    800063b4:	4509                	li	a0,2
    800063b6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800063ba:	6394                	ld	a3,0(a5)
    800063bc:	9736                	add	a4,a4,a3
    800063be:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063c2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800063c6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800063ca:	6794                	ld	a3,8(a5)
    800063cc:	0026d703          	lhu	a4,2(a3)
    800063d0:	8b1d                	andi	a4,a4,7
    800063d2:	2709                	addiw	a4,a4,2
    800063d4:	0706                	slli	a4,a4,0x1
    800063d6:	9736                	add	a4,a4,a3
    800063d8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800063dc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800063e0:	6798                	ld	a4,8(a5)
    800063e2:	00275783          	lhu	a5,2(a4)
    800063e6:	2785                	addiw	a5,a5,1
    800063e8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063f4:	00492703          	lw	a4,4(s2)
    800063f8:	4785                	li	a5,1
    800063fa:	02f71163          	bne	a4,a5,8000641c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800063fe:	0001f997          	auipc	s3,0x1f
    80006402:	caa98993          	addi	s3,s3,-854 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006406:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006408:	85ce                	mv	a1,s3
    8000640a:	854a                	mv	a0,s2
    8000640c:	ffffc097          	auipc	ra,0xffffc
    80006410:	152080e7          	jalr	338(ra) # 8000255e <sleep>
  while(b->disk == 1) {
    80006414:	00492783          	lw	a5,4(s2)
    80006418:	fe9788e3          	beq	a5,s1,80006408 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000641c:	f9042483          	lw	s1,-112(s0)
    80006420:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006424:	00479713          	slli	a4,a5,0x4
    80006428:	0001d797          	auipc	a5,0x1d
    8000642c:	bd878793          	addi	a5,a5,-1064 # 80023000 <disk>
    80006430:	97ba                	add	a5,a5,a4
    80006432:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006436:	0001f917          	auipc	s2,0x1f
    8000643a:	bca90913          	addi	s2,s2,-1078 # 80025000 <disk+0x2000>
    free_desc(i);
    8000643e:	8526                	mv	a0,s1
    80006440:	00000097          	auipc	ra,0x0
    80006444:	bf6080e7          	jalr	-1034(ra) # 80006036 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006448:	0492                	slli	s1,s1,0x4
    8000644a:	00093783          	ld	a5,0(s2)
    8000644e:	94be                	add	s1,s1,a5
    80006450:	00c4d783          	lhu	a5,12(s1)
    80006454:	8b85                	andi	a5,a5,1
    80006456:	cf89                	beqz	a5,80006470 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006458:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000645c:	b7cd                	j	8000643e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000645e:	0001f797          	auipc	a5,0x1f
    80006462:	ba27b783          	ld	a5,-1118(a5) # 80025000 <disk+0x2000>
    80006466:	97ba                	add	a5,a5,a4
    80006468:	4689                	li	a3,2
    8000646a:	00d79623          	sh	a3,12(a5)
    8000646e:	b5fd                	j	8000635c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006470:	0001f517          	auipc	a0,0x1f
    80006474:	c3850513          	addi	a0,a0,-968 # 800250a8 <disk+0x20a8>
    80006478:	ffffb097          	auipc	ra,0xffffb
    8000647c:	84c080e7          	jalr	-1972(ra) # 80000cc4 <release>
}
    80006480:	70e6                	ld	ra,120(sp)
    80006482:	7446                	ld	s0,112(sp)
    80006484:	74a6                	ld	s1,104(sp)
    80006486:	7906                	ld	s2,96(sp)
    80006488:	69e6                	ld	s3,88(sp)
    8000648a:	6a46                	ld	s4,80(sp)
    8000648c:	6aa6                	ld	s5,72(sp)
    8000648e:	6b06                	ld	s6,64(sp)
    80006490:	7be2                	ld	s7,56(sp)
    80006492:	7c42                	ld	s8,48(sp)
    80006494:	7ca2                	ld	s9,40(sp)
    80006496:	7d02                	ld	s10,32(sp)
    80006498:	6109                	addi	sp,sp,128
    8000649a:	8082                	ret
  if(write)
    8000649c:	e20d1ee3          	bnez	s10,800062d8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800064a0:	f8042023          	sw	zero,-128(s0)
    800064a4:	bd2d                	j	800062de <virtio_disk_rw+0xe2>

00000000800064a6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064a6:	1101                	addi	sp,sp,-32
    800064a8:	ec06                	sd	ra,24(sp)
    800064aa:	e822                	sd	s0,16(sp)
    800064ac:	e426                	sd	s1,8(sp)
    800064ae:	e04a                	sd	s2,0(sp)
    800064b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064b2:	0001f517          	auipc	a0,0x1f
    800064b6:	bf650513          	addi	a0,a0,-1034 # 800250a8 <disk+0x20a8>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	756080e7          	jalr	1878(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064c2:	0001f717          	auipc	a4,0x1f
    800064c6:	b3e70713          	addi	a4,a4,-1218 # 80025000 <disk+0x2000>
    800064ca:	02075783          	lhu	a5,32(a4)
    800064ce:	6b18                	ld	a4,16(a4)
    800064d0:	00275683          	lhu	a3,2(a4)
    800064d4:	8ebd                	xor	a3,a3,a5
    800064d6:	8a9d                	andi	a3,a3,7
    800064d8:	cab9                	beqz	a3,8000652e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800064da:	0001d917          	auipc	s2,0x1d
    800064de:	b2690913          	addi	s2,s2,-1242 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064e2:	0001f497          	auipc	s1,0x1f
    800064e6:	b1e48493          	addi	s1,s1,-1250 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800064ea:	078e                	slli	a5,a5,0x3
    800064ec:	97ba                	add	a5,a5,a4
    800064ee:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064f0:	20078713          	addi	a4,a5,512
    800064f4:	0712                	slli	a4,a4,0x4
    800064f6:	974a                	add	a4,a4,s2
    800064f8:	03074703          	lbu	a4,48(a4)
    800064fc:	ef21                	bnez	a4,80006554 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800064fe:	20078793          	addi	a5,a5,512
    80006502:	0792                	slli	a5,a5,0x4
    80006504:	97ca                	add	a5,a5,s2
    80006506:	7798                	ld	a4,40(a5)
    80006508:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000650c:	7788                	ld	a0,40(a5)
    8000650e:	ffffc097          	auipc	ra,0xffffc
    80006512:	1d6080e7          	jalr	470(ra) # 800026e4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006516:	0204d783          	lhu	a5,32(s1)
    8000651a:	2785                	addiw	a5,a5,1
    8000651c:	8b9d                	andi	a5,a5,7
    8000651e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006522:	6898                	ld	a4,16(s1)
    80006524:	00275683          	lhu	a3,2(a4)
    80006528:	8a9d                	andi	a3,a3,7
    8000652a:	fcf690e3          	bne	a3,a5,800064ea <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000652e:	10001737          	lui	a4,0x10001
    80006532:	533c                	lw	a5,96(a4)
    80006534:	8b8d                	andi	a5,a5,3
    80006536:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006538:	0001f517          	auipc	a0,0x1f
    8000653c:	b7050513          	addi	a0,a0,-1168 # 800250a8 <disk+0x20a8>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	784080e7          	jalr	1924(ra) # 80000cc4 <release>
}
    80006548:	60e2                	ld	ra,24(sp)
    8000654a:	6442                	ld	s0,16(sp)
    8000654c:	64a2                	ld	s1,8(sp)
    8000654e:	6902                	ld	s2,0(sp)
    80006550:	6105                	addi	sp,sp,32
    80006552:	8082                	ret
      panic("virtio_disk_intr status");
    80006554:	00002517          	auipc	a0,0x2
    80006558:	39450513          	addi	a0,a0,916 # 800088e8 <syscalls+0x3e0>
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	fec080e7          	jalr	-20(ra) # 80000548 <panic>

0000000080006564 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006564:	7179                	addi	sp,sp,-48
    80006566:	f406                	sd	ra,40(sp)
    80006568:	f022                	sd	s0,32(sp)
    8000656a:	ec26                	sd	s1,24(sp)
    8000656c:	e84a                	sd	s2,16(sp)
    8000656e:	e44e                	sd	s3,8(sp)
    80006570:	e052                	sd	s4,0(sp)
    80006572:	1800                	addi	s0,sp,48
    80006574:	892a                	mv	s2,a0
    80006576:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006578:	00003a17          	auipc	s4,0x3
    8000657c:	ab0a0a13          	addi	s4,s4,-1360 # 80009028 <stats>
    80006580:	000a2683          	lw	a3,0(s4)
    80006584:	00002617          	auipc	a2,0x2
    80006588:	37c60613          	addi	a2,a2,892 # 80008900 <syscalls+0x3f8>
    8000658c:	00000097          	auipc	ra,0x0
    80006590:	2c2080e7          	jalr	706(ra) # 8000684e <snprintf>
    80006594:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006596:	004a2683          	lw	a3,4(s4)
    8000659a:	00002617          	auipc	a2,0x2
    8000659e:	37660613          	addi	a2,a2,886 # 80008910 <syscalls+0x408>
    800065a2:	85ce                	mv	a1,s3
    800065a4:	954a                	add	a0,a0,s2
    800065a6:	00000097          	auipc	ra,0x0
    800065aa:	2a8080e7          	jalr	680(ra) # 8000684e <snprintf>
  return n;
}
    800065ae:	9d25                	addw	a0,a0,s1
    800065b0:	70a2                	ld	ra,40(sp)
    800065b2:	7402                	ld	s0,32(sp)
    800065b4:	64e2                	ld	s1,24(sp)
    800065b6:	6942                	ld	s2,16(sp)
    800065b8:	69a2                	ld	s3,8(sp)
    800065ba:	6a02                	ld	s4,0(sp)
    800065bc:	6145                	addi	sp,sp,48
    800065be:	8082                	ret

00000000800065c0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800065c0:	7179                	addi	sp,sp,-48
    800065c2:	f406                	sd	ra,40(sp)
    800065c4:	f022                	sd	s0,32(sp)
    800065c6:	ec26                	sd	s1,24(sp)
    800065c8:	e84a                	sd	s2,16(sp)
    800065ca:	e44e                	sd	s3,8(sp)
    800065cc:	1800                	addi	s0,sp,48
    800065ce:	89ae                	mv	s3,a1
    800065d0:	84b2                	mv	s1,a2
    800065d2:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800065d4:	ffffb097          	auipc	ra,0xffffb
    800065d8:	5e8080e7          	jalr	1512(ra) # 80001bbc <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800065dc:	653c                	ld	a5,72(a0)
    800065de:	02f4ff63          	bgeu	s1,a5,8000661c <copyin_new+0x5c>
    800065e2:	01248733          	add	a4,s1,s2
    800065e6:	02f77d63          	bgeu	a4,a5,80006620 <copyin_new+0x60>
    800065ea:	02976d63          	bltu	a4,s1,80006624 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800065ee:	0009061b          	sext.w	a2,s2
    800065f2:	85a6                	mv	a1,s1
    800065f4:	854e                	mv	a0,s3
    800065f6:	ffffa097          	auipc	ra,0xffffa
    800065fa:	776080e7          	jalr	1910(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    800065fe:	00003717          	auipc	a4,0x3
    80006602:	a2a70713          	addi	a4,a4,-1494 # 80009028 <stats>
    80006606:	431c                	lw	a5,0(a4)
    80006608:	2785                	addiw	a5,a5,1
    8000660a:	c31c                	sw	a5,0(a4)
  return 0;
    8000660c:	4501                	li	a0,0
}
    8000660e:	70a2                	ld	ra,40(sp)
    80006610:	7402                	ld	s0,32(sp)
    80006612:	64e2                	ld	s1,24(sp)
    80006614:	6942                	ld	s2,16(sp)
    80006616:	69a2                	ld	s3,8(sp)
    80006618:	6145                	addi	sp,sp,48
    8000661a:	8082                	ret
    return -1;
    8000661c:	557d                	li	a0,-1
    8000661e:	bfc5                	j	8000660e <copyin_new+0x4e>
    80006620:	557d                	li	a0,-1
    80006622:	b7f5                	j	8000660e <copyin_new+0x4e>
    80006624:	557d                	li	a0,-1
    80006626:	b7e5                	j	8000660e <copyin_new+0x4e>

0000000080006628 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006628:	7179                	addi	sp,sp,-48
    8000662a:	f406                	sd	ra,40(sp)
    8000662c:	f022                	sd	s0,32(sp)
    8000662e:	ec26                	sd	s1,24(sp)
    80006630:	e84a                	sd	s2,16(sp)
    80006632:	e44e                	sd	s3,8(sp)
    80006634:	1800                	addi	s0,sp,48
    80006636:	89ae                	mv	s3,a1
    80006638:	8932                	mv	s2,a2
    8000663a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000663c:	ffffb097          	auipc	ra,0xffffb
    80006640:	580080e7          	jalr	1408(ra) # 80001bbc <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006644:	00003717          	auipc	a4,0x3
    80006648:	9e470713          	addi	a4,a4,-1564 # 80009028 <stats>
    8000664c:	435c                	lw	a5,4(a4)
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006652:	cc85                	beqz	s1,8000668a <copyinstr_new+0x62>
    80006654:	00990833          	add	a6,s2,s1
    80006658:	87ca                	mv	a5,s2
    8000665a:	6538                	ld	a4,72(a0)
    8000665c:	00e7ff63          	bgeu	a5,a4,8000667a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006660:	0007c683          	lbu	a3,0(a5)
    80006664:	41278733          	sub	a4,a5,s2
    80006668:	974e                	add	a4,a4,s3
    8000666a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000666e:	c285                	beqz	a3,8000668e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006670:	0785                	addi	a5,a5,1
    80006672:	ff0794e3          	bne	a5,a6,8000665a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006676:	557d                	li	a0,-1
    80006678:	a011                	j	8000667c <copyinstr_new+0x54>
    8000667a:	557d                	li	a0,-1
}
    8000667c:	70a2                	ld	ra,40(sp)
    8000667e:	7402                	ld	s0,32(sp)
    80006680:	64e2                	ld	s1,24(sp)
    80006682:	6942                	ld	s2,16(sp)
    80006684:	69a2                	ld	s3,8(sp)
    80006686:	6145                	addi	sp,sp,48
    80006688:	8082                	ret
  return -1;
    8000668a:	557d                	li	a0,-1
    8000668c:	bfc5                	j	8000667c <copyinstr_new+0x54>
      return 0;
    8000668e:	4501                	li	a0,0
    80006690:	b7f5                	j	8000667c <copyinstr_new+0x54>

0000000080006692 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006692:	1141                	addi	sp,sp,-16
    80006694:	e422                	sd	s0,8(sp)
    80006696:	0800                	addi	s0,sp,16
  return -1;
}
    80006698:	557d                	li	a0,-1
    8000669a:	6422                	ld	s0,8(sp)
    8000669c:	0141                	addi	sp,sp,16
    8000669e:	8082                	ret

00000000800066a0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800066a0:	7179                	addi	sp,sp,-48
    800066a2:	f406                	sd	ra,40(sp)
    800066a4:	f022                	sd	s0,32(sp)
    800066a6:	ec26                	sd	s1,24(sp)
    800066a8:	e84a                	sd	s2,16(sp)
    800066aa:	e44e                	sd	s3,8(sp)
    800066ac:	e052                	sd	s4,0(sp)
    800066ae:	1800                	addi	s0,sp,48
    800066b0:	892a                	mv	s2,a0
    800066b2:	89ae                	mv	s3,a1
    800066b4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800066b6:	00020517          	auipc	a0,0x20
    800066ba:	94a50513          	addi	a0,a0,-1718 # 80026000 <stats>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	552080e7          	jalr	1362(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    800066c6:	00021797          	auipc	a5,0x21
    800066ca:	9527a783          	lw	a5,-1710(a5) # 80027018 <stats+0x1018>
    800066ce:	cbb5                	beqz	a5,80006742 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800066d0:	00021797          	auipc	a5,0x21
    800066d4:	93078793          	addi	a5,a5,-1744 # 80027000 <stats+0x1000>
    800066d8:	4fd8                	lw	a4,28(a5)
    800066da:	4f9c                	lw	a5,24(a5)
    800066dc:	9f99                	subw	a5,a5,a4
    800066de:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800066e2:	06d05e63          	blez	a3,8000675e <statsread+0xbe>
    if(m > n)
    800066e6:	8a3e                	mv	s4,a5
    800066e8:	00d4d363          	bge	s1,a3,800066ee <statsread+0x4e>
    800066ec:	8a26                	mv	s4,s1
    800066ee:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066f2:	86a6                	mv	a3,s1
    800066f4:	00020617          	auipc	a2,0x20
    800066f8:	92460613          	addi	a2,a2,-1756 # 80026018 <stats+0x18>
    800066fc:	963a                	add	a2,a2,a4
    800066fe:	85ce                	mv	a1,s3
    80006700:	854a                	mv	a0,s2
    80006702:	ffffc097          	auipc	ra,0xffffc
    80006706:	0be080e7          	jalr	190(ra) # 800027c0 <either_copyout>
    8000670a:	57fd                	li	a5,-1
    8000670c:	00f50a63          	beq	a0,a5,80006720 <statsread+0x80>
      stats.off += m;
    80006710:	00021717          	auipc	a4,0x21
    80006714:	8f070713          	addi	a4,a4,-1808 # 80027000 <stats+0x1000>
    80006718:	4f5c                	lw	a5,28(a4)
    8000671a:	014787bb          	addw	a5,a5,s4
    8000671e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006720:	00020517          	auipc	a0,0x20
    80006724:	8e050513          	addi	a0,a0,-1824 # 80026000 <stats>
    80006728:	ffffa097          	auipc	ra,0xffffa
    8000672c:	59c080e7          	jalr	1436(ra) # 80000cc4 <release>
  return m;
}
    80006730:	8526                	mv	a0,s1
    80006732:	70a2                	ld	ra,40(sp)
    80006734:	7402                	ld	s0,32(sp)
    80006736:	64e2                	ld	s1,24(sp)
    80006738:	6942                	ld	s2,16(sp)
    8000673a:	69a2                	ld	s3,8(sp)
    8000673c:	6a02                	ld	s4,0(sp)
    8000673e:	6145                	addi	sp,sp,48
    80006740:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006742:	6585                	lui	a1,0x1
    80006744:	00020517          	auipc	a0,0x20
    80006748:	8d450513          	addi	a0,a0,-1836 # 80026018 <stats+0x18>
    8000674c:	00000097          	auipc	ra,0x0
    80006750:	e18080e7          	jalr	-488(ra) # 80006564 <statscopyin>
    80006754:	00021797          	auipc	a5,0x21
    80006758:	8ca7a223          	sw	a0,-1852(a5) # 80027018 <stats+0x1018>
    8000675c:	bf95                	j	800066d0 <statsread+0x30>
    stats.sz = 0;
    8000675e:	00021797          	auipc	a5,0x21
    80006762:	8a278793          	addi	a5,a5,-1886 # 80027000 <stats+0x1000>
    80006766:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000676a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000676e:	54fd                	li	s1,-1
    80006770:	bf45                	j	80006720 <statsread+0x80>

0000000080006772 <statsinit>:

void
statsinit(void)
{
    80006772:	1141                	addi	sp,sp,-16
    80006774:	e406                	sd	ra,8(sp)
    80006776:	e022                	sd	s0,0(sp)
    80006778:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000677a:	00002597          	auipc	a1,0x2
    8000677e:	1a658593          	addi	a1,a1,422 # 80008920 <syscalls+0x418>
    80006782:	00020517          	auipc	a0,0x20
    80006786:	87e50513          	addi	a0,a0,-1922 # 80026000 <stats>
    8000678a:	ffffa097          	auipc	ra,0xffffa
    8000678e:	3f6080e7          	jalr	1014(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    80006792:	0001b797          	auipc	a5,0x1b
    80006796:	41e78793          	addi	a5,a5,1054 # 80021bb0 <devsw>
    8000679a:	00000717          	auipc	a4,0x0
    8000679e:	f0670713          	addi	a4,a4,-250 # 800066a0 <statsread>
    800067a2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800067a4:	00000717          	auipc	a4,0x0
    800067a8:	eee70713          	addi	a4,a4,-274 # 80006692 <statswrite>
    800067ac:	f798                	sd	a4,40(a5)
}
    800067ae:	60a2                	ld	ra,8(sp)
    800067b0:	6402                	ld	s0,0(sp)
    800067b2:	0141                	addi	sp,sp,16
    800067b4:	8082                	ret

00000000800067b6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800067b6:	1101                	addi	sp,sp,-32
    800067b8:	ec22                	sd	s0,24(sp)
    800067ba:	1000                	addi	s0,sp,32
    800067bc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800067be:	c299                	beqz	a3,800067c4 <sprintint+0xe>
    800067c0:	0805c163          	bltz	a1,80006842 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800067c4:	2581                	sext.w	a1,a1
    800067c6:	4301                	li	t1,0

  i = 0;
    800067c8:	fe040713          	addi	a4,s0,-32
    800067cc:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800067ce:	2601                	sext.w	a2,a2
    800067d0:	00002697          	auipc	a3,0x2
    800067d4:	15868693          	addi	a3,a3,344 # 80008928 <digits>
    800067d8:	88aa                	mv	a7,a0
    800067da:	2505                	addiw	a0,a0,1
    800067dc:	02c5f7bb          	remuw	a5,a1,a2
    800067e0:	1782                	slli	a5,a5,0x20
    800067e2:	9381                	srli	a5,a5,0x20
    800067e4:	97b6                	add	a5,a5,a3
    800067e6:	0007c783          	lbu	a5,0(a5)
    800067ea:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067ee:	0005879b          	sext.w	a5,a1
    800067f2:	02c5d5bb          	divuw	a1,a1,a2
    800067f6:	0705                	addi	a4,a4,1
    800067f8:	fec7f0e3          	bgeu	a5,a2,800067d8 <sprintint+0x22>

  if(sign)
    800067fc:	00030b63          	beqz	t1,80006812 <sprintint+0x5c>
    buf[i++] = '-';
    80006800:	ff040793          	addi	a5,s0,-16
    80006804:	97aa                	add	a5,a5,a0
    80006806:	02d00713          	li	a4,45
    8000680a:	fee78823          	sb	a4,-16(a5)
    8000680e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006812:	02a05c63          	blez	a0,8000684a <sprintint+0x94>
    80006816:	fe040793          	addi	a5,s0,-32
    8000681a:	00a78733          	add	a4,a5,a0
    8000681e:	87c2                	mv	a5,a6
    80006820:	0805                	addi	a6,a6,1
    80006822:	fff5061b          	addiw	a2,a0,-1
    80006826:	1602                	slli	a2,a2,0x20
    80006828:	9201                	srli	a2,a2,0x20
    8000682a:	9642                	add	a2,a2,a6
  *s = c;
    8000682c:	fff74683          	lbu	a3,-1(a4)
    80006830:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006834:	177d                	addi	a4,a4,-1
    80006836:	0785                	addi	a5,a5,1
    80006838:	fec79ae3          	bne	a5,a2,8000682c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000683c:	6462                	ld	s0,24(sp)
    8000683e:	6105                	addi	sp,sp,32
    80006840:	8082                	ret
    x = -xx;
    80006842:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006846:	4305                	li	t1,1
    x = -xx;
    80006848:	b741                	j	800067c8 <sprintint+0x12>
  while(--i >= 0)
    8000684a:	4501                	li	a0,0
    8000684c:	bfc5                	j	8000683c <sprintint+0x86>

000000008000684e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000684e:	7171                	addi	sp,sp,-176
    80006850:	fc86                	sd	ra,120(sp)
    80006852:	f8a2                	sd	s0,112(sp)
    80006854:	f4a6                	sd	s1,104(sp)
    80006856:	f0ca                	sd	s2,96(sp)
    80006858:	ecce                	sd	s3,88(sp)
    8000685a:	e8d2                	sd	s4,80(sp)
    8000685c:	e4d6                	sd	s5,72(sp)
    8000685e:	e0da                	sd	s6,64(sp)
    80006860:	fc5e                	sd	s7,56(sp)
    80006862:	f862                	sd	s8,48(sp)
    80006864:	f466                	sd	s9,40(sp)
    80006866:	f06a                	sd	s10,32(sp)
    80006868:	ec6e                	sd	s11,24(sp)
    8000686a:	0100                	addi	s0,sp,128
    8000686c:	e414                	sd	a3,8(s0)
    8000686e:	e818                	sd	a4,16(s0)
    80006870:	ec1c                	sd	a5,24(s0)
    80006872:	03043023          	sd	a6,32(s0)
    80006876:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000687a:	ca0d                	beqz	a2,800068ac <snprintf+0x5e>
    8000687c:	8baa                	mv	s7,a0
    8000687e:	89ae                	mv	s3,a1
    80006880:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006882:	00840793          	addi	a5,s0,8
    80006886:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000688a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000688c:	4901                	li	s2,0
    8000688e:	02b05763          	blez	a1,800068bc <snprintf+0x6e>
    if(c != '%'){
    80006892:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006896:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000689a:	02800d93          	li	s11,40
  *s = c;
    8000689e:	02500d13          	li	s10,37
    switch(c){
    800068a2:	07800c93          	li	s9,120
    800068a6:	06400c13          	li	s8,100
    800068aa:	a01d                	j	800068d0 <snprintf+0x82>
    panic("null fmt");
    800068ac:	00001517          	auipc	a0,0x1
    800068b0:	76c50513          	addi	a0,a0,1900 # 80008018 <etext+0x18>
    800068b4:	ffffa097          	auipc	ra,0xffffa
    800068b8:	c94080e7          	jalr	-876(ra) # 80000548 <panic>
  int off = 0;
    800068bc:	4481                	li	s1,0
    800068be:	a86d                	j	80006978 <snprintf+0x12a>
  *s = c;
    800068c0:	009b8733          	add	a4,s7,s1
    800068c4:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068c8:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068ca:	2905                	addiw	s2,s2,1
    800068cc:	0b34d663          	bge	s1,s3,80006978 <snprintf+0x12a>
    800068d0:	012a07b3          	add	a5,s4,s2
    800068d4:	0007c783          	lbu	a5,0(a5)
    800068d8:	0007871b          	sext.w	a4,a5
    800068dc:	cfd1                	beqz	a5,80006978 <snprintf+0x12a>
    if(c != '%'){
    800068de:	ff5711e3          	bne	a4,s5,800068c0 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800068e2:	2905                	addiw	s2,s2,1
    800068e4:	012a07b3          	add	a5,s4,s2
    800068e8:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800068ec:	c7d1                	beqz	a5,80006978 <snprintf+0x12a>
    switch(c){
    800068ee:	05678c63          	beq	a5,s6,80006946 <snprintf+0xf8>
    800068f2:	02fb6763          	bltu	s6,a5,80006920 <snprintf+0xd2>
    800068f6:	0b578763          	beq	a5,s5,800069a4 <snprintf+0x156>
    800068fa:	0b879b63          	bne	a5,s8,800069b0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800068fe:	f8843783          	ld	a5,-120(s0)
    80006902:	00878713          	addi	a4,a5,8
    80006906:	f8e43423          	sd	a4,-120(s0)
    8000690a:	4685                	li	a3,1
    8000690c:	4629                	li	a2,10
    8000690e:	438c                	lw	a1,0(a5)
    80006910:	009b8533          	add	a0,s7,s1
    80006914:	00000097          	auipc	ra,0x0
    80006918:	ea2080e7          	jalr	-350(ra) # 800067b6 <sprintint>
    8000691c:	9ca9                	addw	s1,s1,a0
      break;
    8000691e:	b775                	j	800068ca <snprintf+0x7c>
    switch(c){
    80006920:	09979863          	bne	a5,s9,800069b0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006924:	f8843783          	ld	a5,-120(s0)
    80006928:	00878713          	addi	a4,a5,8
    8000692c:	f8e43423          	sd	a4,-120(s0)
    80006930:	4685                	li	a3,1
    80006932:	4641                	li	a2,16
    80006934:	438c                	lw	a1,0(a5)
    80006936:	009b8533          	add	a0,s7,s1
    8000693a:	00000097          	auipc	ra,0x0
    8000693e:	e7c080e7          	jalr	-388(ra) # 800067b6 <sprintint>
    80006942:	9ca9                	addw	s1,s1,a0
      break;
    80006944:	b759                	j	800068ca <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006946:	f8843783          	ld	a5,-120(s0)
    8000694a:	00878713          	addi	a4,a5,8
    8000694e:	f8e43423          	sd	a4,-120(s0)
    80006952:	639c                	ld	a5,0(a5)
    80006954:	c3b1                	beqz	a5,80006998 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006956:	0007c703          	lbu	a4,0(a5)
    8000695a:	db25                	beqz	a4,800068ca <snprintf+0x7c>
    8000695c:	0134de63          	bge	s1,s3,80006978 <snprintf+0x12a>
    80006960:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006964:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006968:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000696a:	0785                	addi	a5,a5,1
    8000696c:	0007c703          	lbu	a4,0(a5)
    80006970:	df29                	beqz	a4,800068ca <snprintf+0x7c>
    80006972:	0685                	addi	a3,a3,1
    80006974:	fe9998e3          	bne	s3,s1,80006964 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006978:	8526                	mv	a0,s1
    8000697a:	70e6                	ld	ra,120(sp)
    8000697c:	7446                	ld	s0,112(sp)
    8000697e:	74a6                	ld	s1,104(sp)
    80006980:	7906                	ld	s2,96(sp)
    80006982:	69e6                	ld	s3,88(sp)
    80006984:	6a46                	ld	s4,80(sp)
    80006986:	6aa6                	ld	s5,72(sp)
    80006988:	6b06                	ld	s6,64(sp)
    8000698a:	7be2                	ld	s7,56(sp)
    8000698c:	7c42                	ld	s8,48(sp)
    8000698e:	7ca2                	ld	s9,40(sp)
    80006990:	7d02                	ld	s10,32(sp)
    80006992:	6de2                	ld	s11,24(sp)
    80006994:	614d                	addi	sp,sp,176
    80006996:	8082                	ret
        s = "(null)";
    80006998:	00001797          	auipc	a5,0x1
    8000699c:	67878793          	addi	a5,a5,1656 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    800069a0:	876e                	mv	a4,s11
    800069a2:	bf6d                	j	8000695c <snprintf+0x10e>
  *s = c;
    800069a4:	009b87b3          	add	a5,s7,s1
    800069a8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800069ac:	2485                	addiw	s1,s1,1
      break;
    800069ae:	bf31                	j	800068ca <snprintf+0x7c>
  *s = c;
    800069b0:	009b8733          	add	a4,s7,s1
    800069b4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800069b8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800069bc:	975e                	add	a4,a4,s7
    800069be:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069c2:	2489                	addiw	s1,s1,2
      break;
    800069c4:	b719                	j	800068ca <snprintf+0x7c>
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
