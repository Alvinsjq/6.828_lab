
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 19 10 f0 	movl   $0xf0101980,(%esp)
f0100055:	e8 d4 08 00 00       	call   f010092e <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 18 07 00 00       	call   f010079f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 19 10 f0 	movl   $0xf010199c,(%esp)
f0100092:	e8 97 08 00 00       	call   f010092e <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 9e 13 00 00       	call   f0101463 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a2 04 00 00       	call   f010056c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 19 10 f0 	movl   $0xf01019b7,(%esp)
f01000d9:	e8 50 08 00 00       	call   f010092e <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 b3 06 00 00       	call   f01007a9 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f010012c:	e8 fd 07 00 00       	call   f010092e <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 be 07 00 00       	call   f01008fb <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100144:	e8 e5 07 00 00       	call   f010092e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 54 06 00 00       	call   f01007a9 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 19 10 f0 	movl   $0xf01019ea,(%esp)
f0100176:	e8 b3 07 00 00       	call   f010092e <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 71 07 00 00       	call   f01008fb <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100191:	e8 98 07 00 00       	call   f010092e <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 2c             	sub    $0x2c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	bb 01 32 00 00       	mov    $0x3201,%ebx
f010021a:	be fd 03 00 00       	mov    $0x3fd,%esi
f010021f:	eb 05                	jmp    f0100226 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100221:	e8 7a ff ff ff       	call   f01001a0 <delay>
f0100226:	89 f2                	mov    %esi,%edx
f0100228:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100229:	a8 20                	test   $0x20,%al
f010022b:	75 05                	jne    f0100232 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022d:	83 eb 01             	sub    $0x1,%ebx
f0100230:	75 ef                	jne    f0100221 <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100232:	89 f8                	mov    %edi,%eax
f0100234:	25 ff 00 00 00       	and    $0xff,%eax
f0100239:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100241:	ee                   	out    %al,(%dx)
f0100242:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100247:	be 79 03 00 00       	mov    $0x379,%esi
f010024c:	eb 05                	jmp    f0100253 <cons_putc+0x49>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f010024e:	e8 4d ff ff ff       	call   f01001a0 <delay>
f0100253:	89 f2                	mov    %esi,%edx
f0100255:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100256:	84 c0                	test   %al,%al
f0100258:	78 05                	js     f010025f <cons_putc+0x55>
f010025a:	83 eb 01             	sub    $0x1,%ebx
f010025d:	75 ef                	jne    f010024e <cons_putc+0x44>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010025f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100264:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100268:	ee                   	out    %al,(%dx)
f0100269:	b2 7a                	mov    $0x7a,%dl
f010026b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100270:	ee                   	out    %al,(%dx)
f0100271:	b8 08 00 00 00       	mov    $0x8,%eax
f0100276:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100277:	89 fa                	mov    %edi,%edx
f0100279:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010027f:	89 f8                	mov    %edi,%eax
f0100281:	80 cc 07             	or     $0x7,%ah
f0100284:	85 d2                	test   %edx,%edx
f0100286:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100289:	89 f8                	mov    %edi,%eax
f010028b:	25 ff 00 00 00       	and    $0xff,%eax
f0100290:	83 f8 09             	cmp    $0x9,%eax
f0100293:	74 7a                	je     f010030f <cons_putc+0x105>
f0100295:	83 f8 09             	cmp    $0x9,%eax
f0100298:	7f 0b                	jg     f01002a5 <cons_putc+0x9b>
f010029a:	83 f8 08             	cmp    $0x8,%eax
f010029d:	0f 85 a0 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002a3:	eb 13                	jmp    f01002b8 <cons_putc+0xae>
f01002a5:	83 f8 0a             	cmp    $0xa,%eax
f01002a8:	74 3f                	je     f01002e9 <cons_putc+0xdf>
f01002aa:	83 f8 0d             	cmp    $0xd,%eax
f01002ad:	8d 76 00             	lea    0x0(%esi),%esi
f01002b0:	0f 85 8d 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002b6:	eb 39                	jmp    f01002f1 <cons_putc+0xe7>
	case '\b':
		if (crt_pos > 0) {
f01002b8:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002bf:	66 85 c0             	test   %ax,%ax
f01002c2:	0f 84 e5 00 00 00    	je     f01003ad <cons_putc+0x1a3>
			crt_pos--;
f01002c8:	83 e8 01             	sub    $0x1,%eax
f01002cb:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002d1:	0f b7 c0             	movzwl %ax,%eax
f01002d4:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002da:	83 cf 20             	or     $0x20,%edi
f01002dd:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002e7:	eb 77                	jmp    f0100360 <cons_putc+0x156>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002e9:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002f0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002f1:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002fe:	c1 e8 16             	shr    $0x16,%eax
f0100301:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100304:	c1 e0 04             	shl    $0x4,%eax
f0100307:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f010030d:	eb 51                	jmp    f0100360 <cons_putc+0x156>
		break;
	case '\t':
		cons_putc(' ');
f010030f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100314:	e8 f1 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e7 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 dd fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d3 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 c9 fe ff ff       	call   f010020a <cons_putc>
f0100341:	eb 1d                	jmp    f0100360 <cons_putc+0x156>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100343:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f010034a:	0f b7 c8             	movzwl %ax,%ecx
f010034d:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f0100353:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100357:	83 c0 01             	add    $0x1,%eax
f010035a:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100360:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100367:	cf 07 
f0100369:	76 42                	jbe    f01003ad <cons_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010036b:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100370:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100377:	00 
f0100378:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010037e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100382:	89 04 24             	mov    %eax,(%esp)
f0100385:	e8 37 11 00 00       	call   f01014c1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010038a:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100390:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100395:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039b:	83 c0 01             	add    $0x1,%eax
f010039e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003a3:	75 f0                	jne    f0100395 <cons_putc+0x18b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003a5:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003ac:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003ad:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003b3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003b8:	89 ca                	mov    %ecx,%edx
f01003ba:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003bb:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003c2:	8d 71 01             	lea    0x1(%ecx),%esi
f01003c5:	89 d8                	mov    %ebx,%eax
f01003c7:	66 c1 e8 08          	shr    $0x8,%ax
f01003cb:	89 f2                	mov    %esi,%edx
f01003cd:	ee                   	out    %al,(%dx)
f01003ce:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003d3:	89 ca                	mov    %ecx,%edx
f01003d5:	ee                   	out    %al,(%dx)
f01003d6:	89 d8                	mov    %ebx,%eax
f01003d8:	89 f2                	mov    %esi,%edx
f01003da:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003db:	83 c4 2c             	add    $0x2c,%esp
f01003de:	5b                   	pop    %ebx
f01003df:	5e                   	pop    %esi
f01003e0:	5f                   	pop    %edi
f01003e1:	5d                   	pop    %ebp
f01003e2:	c3                   	ret    

f01003e3 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003e3:	55                   	push   %ebp
f01003e4:	89 e5                	mov    %esp,%ebp
f01003e6:	53                   	push   %ebx
f01003e7:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ea:	ba 64 00 00 00       	mov    $0x64,%edx
f01003ef:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003f0:	a8 01                	test   $0x1,%al
f01003f2:	0f 84 ed 00 00 00    	je     f01004e5 <kbd_proc_data+0x102>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003f8:	a8 20                	test   $0x20,%al
f01003fa:	0f 85 ec 00 00 00    	jne    f01004ec <kbd_proc_data+0x109>
f0100400:	b2 60                	mov    $0x60,%dl
f0100402:	ec                   	in     (%dx),%al
f0100403:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100405:	3c e0                	cmp    $0xe0,%al
f0100407:	75 11                	jne    f010041a <kbd_proc_data+0x37>
		// E0 escape character
		shift |= E0ESC;
f0100409:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100410:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100415:	e9 d7 00 00 00       	jmp    f01004f1 <kbd_proc_data+0x10e>
	} else if (data & 0x80) {
f010041a:	84 c0                	test   %al,%al
f010041c:	79 37                	jns    f0100455 <kbd_proc_data+0x72>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010041e:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100424:	89 cb                	mov    %ecx,%ebx
f0100426:	83 e3 40             	and    $0x40,%ebx
f0100429:	83 e0 7f             	and    $0x7f,%eax
f010042c:	85 db                	test   %ebx,%ebx
f010042e:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100431:	0f b6 d2             	movzbl %dl,%edx
f0100434:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f010043b:	83 c8 40             	or     $0x40,%eax
f010043e:	0f b6 c0             	movzbl %al,%eax
f0100441:	f7 d0                	not    %eax
f0100443:	21 c1                	and    %eax,%ecx
f0100445:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f010044b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100450:	e9 9c 00 00 00       	jmp    f01004f1 <kbd_proc_data+0x10e>
	} else if (shift & E0ESC) {
f0100455:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010045b:	f6 c1 40             	test   $0x40,%cl
f010045e:	74 0e                	je     f010046e <kbd_proc_data+0x8b>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100460:	89 c2                	mov    %eax,%edx
f0100462:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100465:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100468:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f010046e:	0f b6 d2             	movzbl %dl,%edx
f0100471:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100478:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f010047e:	0f b6 8a 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%ecx
f0100485:	31 c8                	xor    %ecx,%eax
f0100487:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f010048c:	89 c1                	mov    %eax,%ecx
f010048e:	83 e1 03             	and    $0x3,%ecx
f0100491:	8b 0c 8d 40 1c 10 f0 	mov    -0xfefe3c0(,%ecx,4),%ecx
f0100498:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010049c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010049f:	a8 08                	test   $0x8,%al
f01004a1:	74 1b                	je     f01004be <kbd_proc_data+0xdb>
		if ('a' <= c && c <= 'z')
f01004a3:	89 da                	mov    %ebx,%edx
f01004a5:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004a8:	83 f9 19             	cmp    $0x19,%ecx
f01004ab:	77 05                	ja     f01004b2 <kbd_proc_data+0xcf>
			c += 'A' - 'a';
f01004ad:	83 eb 20             	sub    $0x20,%ebx
f01004b0:	eb 0c                	jmp    f01004be <kbd_proc_data+0xdb>
		else if ('A' <= c && c <= 'Z')
f01004b2:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004b5:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004b8:	83 fa 19             	cmp    $0x19,%edx
f01004bb:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004be:	f7 d0                	not    %eax
f01004c0:	a8 06                	test   $0x6,%al
f01004c2:	75 2d                	jne    f01004f1 <kbd_proc_data+0x10e>
f01004c4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004ca:	75 25                	jne    f01004f1 <kbd_proc_data+0x10e>
		cprintf("Rebooting!\n");
f01004cc:	c7 04 24 04 1a 10 f0 	movl   $0xf0101a04,(%esp)
f01004d3:	e8 56 04 00 00       	call   f010092e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d8:	ba 92 00 00 00       	mov    $0x92,%edx
f01004dd:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e2:	ee                   	out    %al,(%dx)
f01004e3:	eb 0c                	jmp    f01004f1 <kbd_proc_data+0x10e>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004e5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004ea:	eb 05                	jmp    f01004f1 <kbd_proc_data+0x10e>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004ec:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004f1:	89 d8                	mov    %ebx,%eax
f01004f3:	83 c4 14             	add    $0x14,%esp
f01004f6:	5b                   	pop    %ebx
f01004f7:	5d                   	pop    %ebp
f01004f8:	c3                   	ret    

f01004f9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f9:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f0100500:	74 11                	je     f0100513 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100502:	55                   	push   %ebp
f0100503:	89 e5                	mov    %esp,%ebp
f0100505:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100508:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f010050d:	e8 b8 fc ff ff       	call   f01001ca <cons_intr>
}
f0100512:	c9                   	leave  
f0100513:	f3 c3                	repz ret 

f0100515 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010051b:	b8 e3 03 10 f0       	mov    $0xf01003e3,%eax
f0100520:	e8 a5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100525:	c9                   	leave  
f0100526:	c3                   	ret    

f0100527 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100527:	55                   	push   %ebp
f0100528:	89 e5                	mov    %esp,%ebp
f010052a:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052d:	e8 c7 ff ff ff       	call   f01004f9 <serial_intr>
	kbd_intr();
f0100532:	e8 de ff ff ff       	call   f0100515 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100537:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f010053d:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100543:	74 20                	je     f0100565 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100545:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f010054c:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010054f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100555:	b9 00 00 00 00       	mov    $0x0,%ecx
f010055a:	0f 44 d1             	cmove  %ecx,%edx
f010055d:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100563:	eb 05                	jmp    f010056a <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100565:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056a:	c9                   	leave  
f010056b:	c3                   	ret    

f010056c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056c:	55                   	push   %ebp
f010056d:	89 e5                	mov    %esp,%ebp
f010056f:	57                   	push   %edi
f0100570:	56                   	push   %esi
f0100571:	53                   	push   %ebx
f0100572:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100575:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100583:	5a a5 
	if (*cp != 0xA55A) {
f0100585:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100590:	74 11                	je     f01005a3 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100592:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100599:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059c:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a1:	eb 16                	jmp    f01005b9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a3:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005aa:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005b1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b4:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b9:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005bf:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c7:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ca:	89 da                	mov    %ebx,%edx
f01005cc:	ec                   	in     (%dx),%al
f01005cd:	0f b6 f0             	movzbl %al,%esi
f01005d0:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d8:	89 ca                	mov    %ecx,%edx
f01005da:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005db:	89 da                	mov    %ebx,%edx
f01005dd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005de:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e4:	0f b6 d8             	movzbl %al,%ebx
f01005e7:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e9:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f0:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fa:	89 f2                	mov    %esi,%edx
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b2 fb                	mov    $0xfb,%dl
f01005ff:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100604:	ee                   	out    %al,(%dx)
f0100605:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060f:	89 da                	mov    %ebx,%edx
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 f9                	mov    $0xf9,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 fb                	mov    $0xfb,%dl
f010061c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100621:	ee                   	out    %al,(%dx)
f0100622:	b2 fc                	mov    $0xfc,%dl
f0100624:	b8 00 00 00 00       	mov    $0x0,%eax
f0100629:	ee                   	out    %al,(%dx)
f010062a:	b2 f9                	mov    $0xf9,%dl
f010062c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100631:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100632:	b2 fd                	mov    $0xfd,%dl
f0100634:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100635:	3c ff                	cmp    $0xff,%al
f0100637:	0f 95 c1             	setne  %cl
f010063a:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f0100640:	89 f2                	mov    %esi,%edx
f0100642:	ec                   	in     (%dx),%al
f0100643:	89 da                	mov    %ebx,%edx
f0100645:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100646:	84 c9                	test   %cl,%cl
f0100648:	75 0c                	jne    f0100656 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064a:	c7 04 24 10 1a 10 f0 	movl   $0xf0101a10,(%esp)
f0100651:	e8 d8 02 00 00       	call   f010092e <cprintf>
}
f0100656:	83 c4 1c             	add    $0x1c,%esp
f0100659:	5b                   	pop    %ebx
f010065a:	5e                   	pop    %esi
f010065b:	5f                   	pop    %edi
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    

f010065e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100664:	8b 45 08             	mov    0x8(%ebp),%eax
f0100667:	e8 9e fb ff ff       	call   f010020a <cons_putc>
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <getchar>:

int
getchar(void)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
f0100671:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100674:	e8 ae fe ff ff       	call   f0100527 <cons_getc>
f0100679:	85 c0                	test   %eax,%eax
f010067b:	74 f7                	je     f0100674 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067d:	c9                   	leave  
f010067e:	c3                   	ret    

f010067f <iscons>:

int
iscons(int fdnum)
{
f010067f:	55                   	push   %ebp
f0100680:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100682:	b8 01 00 00 00       	mov    $0x1,%eax
f0100687:	5d                   	pop    %ebp
f0100688:	c3                   	ret    
f0100689:	66 90                	xchg   %ax,%ax
f010068b:	66 90                	xchg   %ax,%ax
f010068d:	66 90                	xchg   %ax,%ax
f010068f:	90                   	nop

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 50 1c 10 f0 	movl   $0xf0101c50,(%esp)
f010069d:	e8 8c 02 00 00       	call   f010092e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 dc 1c 10 f0 	movl   $0xf0101cdc,(%esp)
f01006b1:	e8 78 02 00 00       	call   f010092e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f01006cd:	e8 5c 02 00 00       	call   f010092e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 6f 19 10 	movl   $0x10196f,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 6f 19 10 	movl   $0xf010196f,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 28 1d 10 f0 	movl   $0xf0101d28,(%esp)
f01006e9:	e8 40 02 00 00       	call   f010092e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f0100705:	e8 24 02 00 00       	call   f010092e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 70 1d 10 f0 	movl   $0xf0101d70,(%esp)
f0100721:	e8 08 02 00 00       	call   f010092e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 94 1d 10 f0 	movl   $0xf0101d94,(%esp)
f010074e:	e8 db 01 00 00       	call   f010092e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100760:	c7 44 24 08 69 1c 10 	movl   $0xf0101c69,0x8(%esp)
f0100767:	f0 
f0100768:	c7 44 24 04 87 1c 10 	movl   $0xf0101c87,0x4(%esp)
f010076f:	f0 
f0100770:	c7 04 24 8c 1c 10 f0 	movl   $0xf0101c8c,(%esp)
f0100777:	e8 b2 01 00 00       	call   f010092e <cprintf>
f010077c:	c7 44 24 08 c0 1d 10 	movl   $0xf0101dc0,0x8(%esp)
f0100783:	f0 
f0100784:	c7 44 24 04 95 1c 10 	movl   $0xf0101c95,0x4(%esp)
f010078b:	f0 
f010078c:	c7 04 24 8c 1c 10 f0 	movl   $0xf0101c8c,(%esp)
f0100793:	e8 96 01 00 00       	call   f010092e <cprintf>
	return 0;
}
f0100798:	b8 00 00 00 00       	mov    $0x0,%eax
f010079d:	c9                   	leave  
f010079e:	c3                   	ret    

f010079f <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a7:	5d                   	pop    %ebp
f01007a8:	c3                   	ret    

f01007a9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a9:	55                   	push   %ebp
f01007aa:	89 e5                	mov    %esp,%ebp
f01007ac:	57                   	push   %edi
f01007ad:	56                   	push   %esi
f01007ae:	53                   	push   %ebx
f01007af:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b2:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f01007b9:	e8 70 01 00 00       	call   f010092e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f01007c5:	e8 64 01 00 00       	call   f010092e <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007ca:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007cd:	c7 04 24 9e 1c 10 f0 	movl   $0xf0101c9e,(%esp)
f01007d4:	e8 37 0a 00 00       	call   f0101210 <readline>
f01007d9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007db:	85 c0                	test   %eax,%eax
f01007dd:	74 ee                	je     f01007cd <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007df:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e6:	be 00 00 00 00       	mov    $0x0,%esi
f01007eb:	eb 06                	jmp    f01007f3 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ed:	c6 03 00             	movb   $0x0,(%ebx)
f01007f0:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f3:	0f b6 03             	movzbl (%ebx),%eax
f01007f6:	84 c0                	test   %al,%al
f01007f8:	74 63                	je     f010085d <monitor+0xb4>
f01007fa:	0f be c0             	movsbl %al,%eax
f01007fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100801:	c7 04 24 a2 1c 10 f0 	movl   $0xf0101ca2,(%esp)
f0100808:	e8 19 0c 00 00       	call   f0101426 <strchr>
f010080d:	85 c0                	test   %eax,%eax
f010080f:	75 dc                	jne    f01007ed <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100811:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100814:	74 47                	je     f010085d <monitor+0xb4>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100816:	83 fe 0f             	cmp    $0xf,%esi
f0100819:	75 16                	jne    f0100831 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010081b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100822:	00 
f0100823:	c7 04 24 a7 1c 10 f0 	movl   $0xf0101ca7,(%esp)
f010082a:	e8 ff 00 00 00       	call   f010092e <cprintf>
f010082f:	eb 9c                	jmp    f01007cd <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100831:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100835:	83 c6 01             	add    $0x1,%esi
f0100838:	eb 03                	jmp    f010083d <monitor+0x94>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010083a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083d:	0f b6 03             	movzbl (%ebx),%eax
f0100840:	84 c0                	test   %al,%al
f0100842:	74 af                	je     f01007f3 <monitor+0x4a>
f0100844:	0f be c0             	movsbl %al,%eax
f0100847:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084b:	c7 04 24 a2 1c 10 f0 	movl   $0xf0101ca2,(%esp)
f0100852:	e8 cf 0b 00 00       	call   f0101426 <strchr>
f0100857:	85 c0                	test   %eax,%eax
f0100859:	74 df                	je     f010083a <monitor+0x91>
f010085b:	eb 96                	jmp    f01007f3 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f010085d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100864:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100865:	85 f6                	test   %esi,%esi
f0100867:	0f 84 60 ff ff ff    	je     f01007cd <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010086d:	c7 44 24 04 87 1c 10 	movl   $0xf0101c87,0x4(%esp)
f0100874:	f0 
f0100875:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100878:	89 04 24             	mov    %eax,(%esp)
f010087b:	e8 48 0b 00 00       	call   f01013c8 <strcmp>
f0100880:	85 c0                	test   %eax,%eax
f0100882:	74 1b                	je     f010089f <monitor+0xf6>
f0100884:	c7 44 24 04 95 1c 10 	movl   $0xf0101c95,0x4(%esp)
f010088b:	f0 
f010088c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010088f:	89 04 24             	mov    %eax,(%esp)
f0100892:	e8 31 0b 00 00       	call   f01013c8 <strcmp>
f0100897:	85 c0                	test   %eax,%eax
f0100899:	75 2c                	jne    f01008c7 <monitor+0x11e>
f010089b:	b0 01                	mov    $0x1,%al
f010089d:	eb 05                	jmp    f01008a4 <monitor+0xfb>
f010089f:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a4:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a7:	01 d0                	add    %edx,%eax
f01008a9:	8b 55 08             	mov    0x8(%ebp),%edx
f01008ac:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008b4:	89 34 24             	mov    %esi,(%esp)
f01008b7:	ff 14 85 3c 1e 10 f0 	call   *-0xfefe1c4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	78 1d                	js     f01008df <monitor+0x136>
f01008c2:	e9 06 ff ff ff       	jmp    f01007cd <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008c7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ce:	c7 04 24 c4 1c 10 f0 	movl   $0xf0101cc4,(%esp)
f01008d5:	e8 54 00 00 00       	call   f010092e <cprintf>
f01008da:	e9 ee fe ff ff       	jmp    f01007cd <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008df:	83 c4 5c             	add    $0x5c,%esp
f01008e2:	5b                   	pop    %ebx
f01008e3:	5e                   	pop    %esi
f01008e4:	5f                   	pop    %edi
f01008e5:	5d                   	pop    %ebp
f01008e6:	c3                   	ret    
f01008e7:	90                   	nop

f01008e8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008e8:	55                   	push   %ebp
f01008e9:	89 e5                	mov    %esp,%ebp
f01008eb:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01008f1:	89 04 24             	mov    %eax,(%esp)
f01008f4:	e8 65 fd ff ff       	call   f010065e <cputchar>
	*cnt++;
}
f01008f9:	c9                   	leave  
f01008fa:	c3                   	ret    

f01008fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100901:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100908:	8b 45 0c             	mov    0xc(%ebp),%eax
f010090b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010090f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100912:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100916:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100919:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091d:	c7 04 24 e8 08 10 f0 	movl   $0xf01008e8,(%esp)
f0100924:	e8 4c 04 00 00       	call   f0100d75 <vprintfmt>
	return cnt;
}
f0100929:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100934:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100937:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093b:	8b 45 08             	mov    0x8(%ebp),%eax
f010093e:	89 04 24             	mov    %eax,(%esp)
f0100941:	e8 b5 ff ff ff       	call   f01008fb <vcprintf>
	va_end(ap);

	return cnt;
}
f0100946:	c9                   	leave  
f0100947:	c3                   	ret    

f0100948 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100948:	55                   	push   %ebp
f0100949:	89 e5                	mov    %esp,%ebp
f010094b:	57                   	push   %edi
f010094c:	56                   	push   %esi
f010094d:	53                   	push   %ebx
f010094e:	83 ec 10             	sub    $0x10,%esp
f0100951:	89 c6                	mov    %eax,%esi
f0100953:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100956:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100959:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010095c:	8b 1a                	mov    (%edx),%ebx
f010095e:	8b 09                	mov    (%ecx),%ecx
f0100960:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100963:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010096a:	eb 77                	jmp    f01009e3 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010096c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010096f:	01 d8                	add    %ebx,%eax
f0100971:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100976:	99                   	cltd   
f0100977:	f7 f9                	idiv   %ecx
f0100979:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010097b:	eb 01                	jmp    f010097e <stab_binsearch+0x36>
			m--;
f010097d:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010097e:	39 d9                	cmp    %ebx,%ecx
f0100980:	7c 1d                	jl     f010099f <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100982:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100985:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010098a:	39 fa                	cmp    %edi,%edx
f010098c:	75 ef                	jne    f010097d <stab_binsearch+0x35>
f010098e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100991:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100994:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100998:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010099b:	73 18                	jae    f01009b5 <stab_binsearch+0x6d>
f010099d:	eb 05                	jmp    f01009a4 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010099f:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009a2:	eb 3f                	jmp    f01009e3 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009a4:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009a7:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f01009a9:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009ac:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009b3:	eb 2e                	jmp    f01009e3 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009b5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009b8:	73 15                	jae    f01009cf <stab_binsearch+0x87>
			*region_right = m - 1;
f01009ba:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009bd:	49                   	dec    %ecx
f01009be:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01009c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009c4:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c6:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009cd:	eb 14                	jmp    f01009e3 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009d2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009d5:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f01009d7:	ff 45 0c             	incl   0xc(%ebp)
f01009da:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009dc:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009e3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009e6:	7e 84                	jle    f010096c <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009e8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009ec:	75 0d                	jne    f01009fb <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009ee:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009f1:	8b 02                	mov    (%edx),%eax
f01009f3:	48                   	dec    %eax
f01009f4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009f7:	89 01                	mov    %eax,(%ecx)
f01009f9:	eb 22                	jmp    f0100a1d <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009fb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009fe:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a00:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a03:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a05:	eb 01                	jmp    f0100a08 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a07:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a08:	39 c1                	cmp    %eax,%ecx
f0100a0a:	7d 0c                	jge    f0100a18 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a0c:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100a0f:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a14:	39 fa                	cmp    %edi,%edx
f0100a16:	75 ef                	jne    f0100a07 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a18:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a1b:	89 02                	mov    %eax,(%edx)
	}
}
f0100a1d:	83 c4 10             	add    $0x10,%esp
f0100a20:	5b                   	pop    %ebx
f0100a21:	5e                   	pop    %esi
f0100a22:	5f                   	pop    %edi
f0100a23:	5d                   	pop    %ebp
f0100a24:	c3                   	ret    

f0100a25 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
f0100a28:	83 ec 38             	sub    $0x38,%esp
f0100a2b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a2e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a31:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a34:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a37:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a3a:	c7 03 4c 1e 10 f0    	movl   $0xf0101e4c,(%ebx)
	info->eip_line = 0;
f0100a40:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a47:	c7 43 08 4c 1e 10 f0 	movl   $0xf0101e4c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a4e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a55:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a58:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a5f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a65:	76 12                	jbe    f0100a79 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a67:	b8 41 74 10 f0       	mov    $0xf0107441,%eax
f0100a6c:	3d 41 5b 10 f0       	cmp    $0xf0105b41,%eax
f0100a71:	0f 86 6b 01 00 00    	jbe    f0100be2 <debuginfo_eip+0x1bd>
f0100a77:	eb 1c                	jmp    f0100a95 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a79:	c7 44 24 08 56 1e 10 	movl   $0xf0101e56,0x8(%esp)
f0100a80:	f0 
f0100a81:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a88:	00 
f0100a89:	c7 04 24 63 1e 10 f0 	movl   $0xf0101e63,(%esp)
f0100a90:	e8 63 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a95:	80 3d 40 74 10 f0 00 	cmpb   $0x0,0xf0107440
f0100a9c:	0f 85 47 01 00 00    	jne    f0100be9 <debuginfo_eip+0x1c4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aa2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aa9:	b8 40 5b 10 f0       	mov    $0xf0105b40,%eax
f0100aae:	2d 84 20 10 f0       	sub    $0xf0102084,%eax
f0100ab3:	c1 f8 02             	sar    $0x2,%eax
f0100ab6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100abc:	83 e8 01             	sub    $0x1,%eax
f0100abf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ac2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ac6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100acd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ad0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ad3:	b8 84 20 10 f0       	mov    $0xf0102084,%eax
f0100ad8:	e8 6b fe ff ff       	call   f0100948 <stab_binsearch>
	if (lfile == 0)
f0100add:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae0:	85 c0                	test   %eax,%eax
f0100ae2:	0f 84 08 01 00 00    	je     f0100bf0 <debuginfo_eip+0x1cb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ae8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aee:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100af1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100af5:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100afc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aff:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b02:	b8 84 20 10 f0       	mov    $0xf0102084,%eax
f0100b07:	e8 3c fe ff ff       	call   f0100948 <stab_binsearch>

	if (lfun <= rfun) {
f0100b0c:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b0f:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b12:	7f 2e                	jg     f0100b42 <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b14:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b17:	8d 90 84 20 10 f0    	lea    -0xfefdf7c(%eax),%edx
f0100b1d:	8b 80 84 20 10 f0    	mov    -0xfefdf7c(%eax),%eax
f0100b23:	b9 41 74 10 f0       	mov    $0xf0107441,%ecx
f0100b28:	81 e9 41 5b 10 f0    	sub    $0xf0105b41,%ecx
f0100b2e:	39 c8                	cmp    %ecx,%eax
f0100b30:	73 08                	jae    f0100b3a <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b32:	05 41 5b 10 f0       	add    $0xf0105b41,%eax
f0100b37:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b3a:	8b 42 08             	mov    0x8(%edx),%eax
f0100b3d:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b40:	eb 06                	jmp    f0100b48 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b42:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b48:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b4f:	00 
f0100b50:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b53:	89 04 24             	mov    %eax,(%esp)
f0100b56:	e8 ec 08 00 00       	call   f0101447 <strfind>
f0100b5b:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b5e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b61:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100b64:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b67:	05 84 20 10 f0       	add    $0xf0102084,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b6c:	eb 06                	jmp    f0100b74 <debuginfo_eip+0x14f>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b6e:	83 ef 01             	sub    $0x1,%edi
f0100b71:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b74:	39 cf                	cmp    %ecx,%edi
f0100b76:	7c 33                	jl     f0100bab <debuginfo_eip+0x186>
	       && stabs[lline].n_type != N_SOL
f0100b78:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b7c:	80 fa 84             	cmp    $0x84,%dl
f0100b7f:	74 0b                	je     f0100b8c <debuginfo_eip+0x167>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b81:	80 fa 64             	cmp    $0x64,%dl
f0100b84:	75 e8                	jne    f0100b6e <debuginfo_eip+0x149>
f0100b86:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b8a:	74 e2                	je     f0100b6e <debuginfo_eip+0x149>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b8c:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b8f:	8b 87 84 20 10 f0    	mov    -0xfefdf7c(%edi),%eax
f0100b95:	ba 41 74 10 f0       	mov    $0xf0107441,%edx
f0100b9a:	81 ea 41 5b 10 f0    	sub    $0xf0105b41,%edx
f0100ba0:	39 d0                	cmp    %edx,%eax
f0100ba2:	73 07                	jae    f0100bab <debuginfo_eip+0x186>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ba4:	05 41 5b 10 f0       	add    $0xf0105b41,%eax
f0100ba9:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bab:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100bae:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bb1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bb6:	39 f1                	cmp    %esi,%ecx
f0100bb8:	7d 42                	jge    f0100bfc <debuginfo_eip+0x1d7>
		for (lline = lfun + 1;
f0100bba:	8d 51 01             	lea    0x1(%ecx),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100bbd:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bc0:	05 84 20 10 f0       	add    $0xf0102084,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bc5:	eb 07                	jmp    f0100bce <debuginfo_eip+0x1a9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bc7:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bcb:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bce:	39 f2                	cmp    %esi,%edx
f0100bd0:	74 25                	je     f0100bf7 <debuginfo_eip+0x1d2>
f0100bd2:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bd5:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bd9:	74 ec                	je     f0100bc7 <debuginfo_eip+0x1a2>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bdb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be0:	eb 1a                	jmp    f0100bfc <debuginfo_eip+0x1d7>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100be2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be7:	eb 13                	jmp    f0100bfc <debuginfo_eip+0x1d7>
f0100be9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bee:	eb 0c                	jmp    f0100bfc <debuginfo_eip+0x1d7>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf5:	eb 05                	jmp    f0100bfc <debuginfo_eip+0x1d7>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bf7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bfc:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100bff:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c02:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c05:	89 ec                	mov    %ebp,%esp
f0100c07:	5d                   	pop    %ebp
f0100c08:	c3                   	ret    
f0100c09:	66 90                	xchg   %ax,%ax
f0100c0b:	66 90                	xchg   %ax,%ax
f0100c0d:	66 90                	xchg   %ax,%ax
f0100c0f:	90                   	nop

f0100c10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 4c             	sub    $0x4c,%esp
f0100c19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c1c:	89 d7                	mov    %edx,%edi
f0100c1e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c21:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100c24:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100c27:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100c2a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c2d:	85 db                	test   %ebx,%ebx
f0100c2f:	75 08                	jne    f0100c39 <printnum+0x29>
f0100c31:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c34:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100c37:	77 6c                	ja     f0100ca5 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c39:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100c3c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100c40:	83 ee 01             	sub    $0x1,%esi
f0100c43:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c47:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100c4a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c4e:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c52:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c56:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c59:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100c5c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100c63:	00 
f0100c64:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c67:	89 1c 24             	mov    %ebx,(%esp)
f0100c6a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c6d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c71:	e8 1a 0a 00 00       	call   f0101690 <__udivdi3>
f0100c76:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c79:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c7c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c80:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100c84:	89 04 24             	mov    %eax,(%esp)
f0100c87:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c8b:	89 fa                	mov    %edi,%edx
f0100c8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c90:	e8 7b ff ff ff       	call   f0100c10 <printnum>
f0100c95:	eb 1b                	jmp    f0100cb2 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c97:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c9b:	8b 45 18             	mov    0x18(%ebp),%eax
f0100c9e:	89 04 24             	mov    %eax,(%esp)
f0100ca1:	ff d3                	call   *%ebx
f0100ca3:	eb 03                	jmp    f0100ca8 <printnum+0x98>
f0100ca5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ca8:	83 ee 01             	sub    $0x1,%esi
f0100cab:	85 f6                	test   %esi,%esi
f0100cad:	7f e8                	jg     f0100c97 <printnum+0x87>
f0100caf:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cb2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cb6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cba:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100cbd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cc1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cc8:	00 
f0100cc9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100ccc:	89 1c 24             	mov    %ebx,(%esp)
f0100ccf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cd2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100cd6:	e8 05 0b 00 00       	call   f01017e0 <__umoddi3>
f0100cdb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cdf:	0f be 80 71 1e 10 f0 	movsbl -0xfefe18f(%eax),%eax
f0100ce6:	89 04 24             	mov    %eax,(%esp)
f0100ce9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cec:	ff d0                	call   *%eax
}
f0100cee:	83 c4 4c             	add    $0x4c,%esp
f0100cf1:	5b                   	pop    %ebx
f0100cf2:	5e                   	pop    %esi
f0100cf3:	5f                   	pop    %edi
f0100cf4:	5d                   	pop    %ebp
f0100cf5:	c3                   	ret    

f0100cf6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cf6:	55                   	push   %ebp
f0100cf7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100cf9:	83 fa 01             	cmp    $0x1,%edx
f0100cfc:	7e 0e                	jle    f0100d0c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100cfe:	8b 10                	mov    (%eax),%edx
f0100d00:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d03:	89 08                	mov    %ecx,(%eax)
f0100d05:	8b 02                	mov    (%edx),%eax
f0100d07:	8b 52 04             	mov    0x4(%edx),%edx
f0100d0a:	eb 22                	jmp    f0100d2e <getuint+0x38>
	else if (lflag)
f0100d0c:	85 d2                	test   %edx,%edx
f0100d0e:	74 10                	je     f0100d20 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d10:	8b 10                	mov    (%eax),%edx
f0100d12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d15:	89 08                	mov    %ecx,(%eax)
f0100d17:	8b 02                	mov    (%edx),%eax
f0100d19:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d1e:	eb 0e                	jmp    f0100d2e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d20:	8b 10                	mov    (%eax),%edx
f0100d22:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d25:	89 08                	mov    %ecx,(%eax)
f0100d27:	8b 02                	mov    (%edx),%eax
f0100d29:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d2e:	5d                   	pop    %ebp
f0100d2f:	c3                   	ret    

f0100d30 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
f0100d33:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d36:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d3a:	8b 10                	mov    (%eax),%edx
f0100d3c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d3f:	73 0a                	jae    f0100d4b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d41:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100d44:	88 0a                	mov    %cl,(%edx)
f0100d46:	83 c2 01             	add    $0x1,%edx
f0100d49:	89 10                	mov    %edx,(%eax)
}
f0100d4b:	5d                   	pop    %ebp
f0100d4c:	c3                   	ret    

f0100d4d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d4d:	55                   	push   %ebp
f0100d4e:	89 e5                	mov    %esp,%ebp
f0100d50:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d53:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d56:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d5a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d5d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d61:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d68:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d6b:	89 04 24             	mov    %eax,(%esp)
f0100d6e:	e8 02 00 00 00       	call   f0100d75 <vprintfmt>
	va_end(ap);
}
f0100d73:	c9                   	leave  
f0100d74:	c3                   	ret    

f0100d75 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d75:	55                   	push   %ebp
f0100d76:	89 e5                	mov    %esp,%ebp
f0100d78:	57                   	push   %edi
f0100d79:	56                   	push   %esi
f0100d7a:	53                   	push   %ebx
f0100d7b:	83 ec 4c             	sub    $0x4c,%esp
f0100d7e:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d84:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d87:	eb 11                	jmp    f0100d9a <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d89:	85 c0                	test   %eax,%eax
f0100d8b:	0f 84 f4 03 00 00    	je     f0101185 <vprintfmt+0x410>
				return;
			putch(ch, putdat);
f0100d91:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d95:	89 04 24             	mov    %eax,(%esp)
f0100d98:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d9a:	0f b6 07             	movzbl (%edi),%eax
f0100d9d:	83 c7 01             	add    $0x1,%edi
f0100da0:	83 f8 25             	cmp    $0x25,%eax
f0100da3:	75 e4                	jne    f0100d89 <vprintfmt+0x14>
f0100da5:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100da9:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100db0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100db7:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100dbe:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dc3:	eb 2b                	jmp    f0100df0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc5:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dc8:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100dcc:	eb 22                	jmp    f0100df0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dce:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100dd1:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100dd5:	eb 19                	jmp    f0100df0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dd7:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100dda:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100de1:	eb 0d                	jmp    f0100df0 <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100de3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100de6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100de9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df0:	0f b6 07             	movzbl (%edi),%eax
f0100df3:	8d 4f 01             	lea    0x1(%edi),%ecx
f0100df6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100df9:	0f b6 0f             	movzbl (%edi),%ecx
f0100dfc:	83 e9 23             	sub    $0x23,%ecx
f0100dff:	80 f9 55             	cmp    $0x55,%cl
f0100e02:	0f 87 5f 03 00 00    	ja     f0101167 <vprintfmt+0x3f2>
f0100e08:	0f b6 c9             	movzbl %cl,%ecx
f0100e0b:	ff 24 8d 00 1f 10 f0 	jmp    *-0xfefe100(,%ecx,4)
f0100e12:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e15:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e1c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e1f:	ba 00 00 00 00       	mov    $0x0,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e24:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e27:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e2b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100e2e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e31:	83 f9 09             	cmp    $0x9,%ecx
f0100e34:	77 2f                	ja     f0100e65 <vprintfmt+0xf0>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e36:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e39:	eb e9                	jmp    f0100e24 <vprintfmt+0xaf>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e3e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e41:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e44:	8b 00                	mov    (%eax),%eax
f0100e46:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e49:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e4c:	eb 1d                	jmp    f0100e6b <vprintfmt+0xf6>

		case '.':
			if (width < 0)
f0100e4e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e52:	78 83                	js     f0100dd7 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e54:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e57:	eb 97                	jmp    f0100df0 <vprintfmt+0x7b>
f0100e59:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e5c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100e63:	eb 8b                	jmp    f0100df0 <vprintfmt+0x7b>
f0100e65:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100e68:	8b 55 e0             	mov    -0x20(%ebp),%edx

		process_precision:
			if (width < 0)
f0100e6b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e6f:	0f 89 7b ff ff ff    	jns    f0100df0 <vprintfmt+0x7b>
f0100e75:	e9 69 ff ff ff       	jmp    f0100de3 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e7a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e80:	e9 6b ff ff ff       	jmp    f0100df0 <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e85:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e88:	8d 50 04             	lea    0x4(%eax),%edx
f0100e8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e8e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e92:	8b 00                	mov    (%eax),%eax
f0100e94:	89 04 24             	mov    %eax,(%esp)
f0100e97:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e99:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e9c:	e9 f9 fe ff ff       	jmp    f0100d9a <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ea1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ea4:	8d 50 04             	lea    0x4(%eax),%edx
f0100ea7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eaa:	8b 00                	mov    (%eax),%eax
f0100eac:	89 c2                	mov    %eax,%edx
f0100eae:	c1 fa 1f             	sar    $0x1f,%edx
f0100eb1:	31 d0                	xor    %edx,%eax
f0100eb3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eb5:	83 f8 06             	cmp    $0x6,%eax
f0100eb8:	7f 0b                	jg     f0100ec5 <vprintfmt+0x150>
f0100eba:	8b 14 85 58 20 10 f0 	mov    -0xfefdfa8(,%eax,4),%edx
f0100ec1:	85 d2                	test   %edx,%edx
f0100ec3:	75 20                	jne    f0100ee5 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0100ec5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec9:	c7 44 24 08 89 1e 10 	movl   $0xf0101e89,0x8(%esp)
f0100ed0:	f0 
f0100ed1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ed5:	89 34 24             	mov    %esi,(%esp)
f0100ed8:	e8 70 fe ff ff       	call   f0100d4d <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edd:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ee0:	e9 b5 fe ff ff       	jmp    f0100d9a <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ee5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ee9:	c7 44 24 08 92 1e 10 	movl   $0xf0101e92,0x8(%esp)
f0100ef0:	f0 
f0100ef1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ef5:	89 34 24             	mov    %esi,(%esp)
f0100ef8:	e8 50 fe ff ff       	call   f0100d4d <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f00:	e9 95 fe ff ff       	jmp    f0100d9a <vprintfmt+0x25>
f0100f05:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f08:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100f0b:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f11:	8d 50 04             	lea    0x4(%eax),%edx
f0100f14:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f17:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f19:	85 ff                	test   %edi,%edi
f0100f1b:	b8 82 1e 10 f0       	mov    $0xf0101e82,%eax
f0100f20:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f23:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0100f27:	0f 84 9b 00 00 00    	je     f0100fc8 <vprintfmt+0x253>
f0100f2d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100f31:	0f 8e 9f 00 00 00    	jle    f0100fd6 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f37:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f3b:	89 3c 24             	mov    %edi,(%esp)
f0100f3e:	e8 b5 03 00 00       	call   f01012f8 <strnlen>
f0100f43:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100f46:	29 c2                	sub    %eax,%edx
f0100f48:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f0100f4b:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0100f4f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f52:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0100f55:	89 d7                	mov    %edx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f57:	eb 0f                	jmp    f0100f68 <vprintfmt+0x1f3>
					putch(padc, putdat);
f0100f59:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f60:	89 04 24             	mov    %eax,(%esp)
f0100f63:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f65:	83 ef 01             	sub    $0x1,%edi
f0100f68:	85 ff                	test   %edi,%edi
f0100f6a:	7f ed                	jg     f0100f59 <vprintfmt+0x1e4>
f0100f6c:	8b 7d c8             	mov    -0x38(%ebp),%edi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0100f6f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f73:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f78:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f0100f7c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f7f:	29 c2                	sub    %eax,%edx
f0100f81:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f84:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100f87:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100f8a:	89 d3                	mov    %edx,%ebx
f0100f8c:	eb 54                	jmp    f0100fe2 <vprintfmt+0x26d>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f8e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f92:	74 20                	je     f0100fb4 <vprintfmt+0x23f>
f0100f94:	0f be d2             	movsbl %dl,%edx
f0100f97:	83 ea 20             	sub    $0x20,%edx
f0100f9a:	83 fa 5e             	cmp    $0x5e,%edx
f0100f9d:	76 15                	jbe    f0100fb4 <vprintfmt+0x23f>
					putch('?', putdat);
f0100f9f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100fa2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fa6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fb0:	ff d0                	call   *%eax
f0100fb2:	eb 0f                	jmp    f0100fc3 <vprintfmt+0x24e>
				else
					putch(ch, putdat);
f0100fb4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fb7:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fbb:	89 04 24             	mov    %eax,(%esp)
f0100fbe:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fc1:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fc3:	83 eb 01             	sub    $0x1,%ebx
f0100fc6:	eb 1a                	jmp    f0100fe2 <vprintfmt+0x26d>
f0100fc8:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100fcb:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100fce:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100fd1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100fd4:	eb 0c                	jmp    f0100fe2 <vprintfmt+0x26d>
f0100fd6:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100fd9:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100fdc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100fdf:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100fe2:	0f b6 17             	movzbl (%edi),%edx
f0100fe5:	0f be c2             	movsbl %dl,%eax
f0100fe8:	83 c7 01             	add    $0x1,%edi
f0100feb:	85 c0                	test   %eax,%eax
f0100fed:	74 29                	je     f0101018 <vprintfmt+0x2a3>
f0100fef:	85 f6                	test   %esi,%esi
f0100ff1:	78 9b                	js     f0100f8e <vprintfmt+0x219>
f0100ff3:	83 ee 01             	sub    $0x1,%esi
f0100ff6:	79 96                	jns    f0100f8e <vprintfmt+0x219>
f0100ff8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100ffb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ffe:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101001:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101004:	eb 1a                	jmp    f0101020 <vprintfmt+0x2ab>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101006:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010100a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101011:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101013:	83 ef 01             	sub    $0x1,%edi
f0101016:	eb 08                	jmp    f0101020 <vprintfmt+0x2ab>
f0101018:	89 df                	mov    %ebx,%edi
f010101a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010101d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101020:	85 ff                	test   %edi,%edi
f0101022:	7f e2                	jg     f0101006 <vprintfmt+0x291>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101024:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101027:	e9 6e fd ff ff       	jmp    f0100d9a <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010102c:	83 fa 01             	cmp    $0x1,%edx
f010102f:	7e 16                	jle    f0101047 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0101031:	8b 45 14             	mov    0x14(%ebp),%eax
f0101034:	8d 50 08             	lea    0x8(%eax),%edx
f0101037:	89 55 14             	mov    %edx,0x14(%ebp)
f010103a:	8b 10                	mov    (%eax),%edx
f010103c:	8b 48 04             	mov    0x4(%eax),%ecx
f010103f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101042:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101045:	eb 32                	jmp    f0101079 <vprintfmt+0x304>
	else if (lflag)
f0101047:	85 d2                	test   %edx,%edx
f0101049:	74 18                	je     f0101063 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f010104b:	8b 45 14             	mov    0x14(%ebp),%eax
f010104e:	8d 50 04             	lea    0x4(%eax),%edx
f0101051:	89 55 14             	mov    %edx,0x14(%ebp)
f0101054:	8b 00                	mov    (%eax),%eax
f0101056:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101059:	89 c1                	mov    %eax,%ecx
f010105b:	c1 f9 1f             	sar    $0x1f,%ecx
f010105e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101061:	eb 16                	jmp    f0101079 <vprintfmt+0x304>
	else
		return va_arg(*ap, int);
f0101063:	8b 45 14             	mov    0x14(%ebp),%eax
f0101066:	8d 50 04             	lea    0x4(%eax),%edx
f0101069:	89 55 14             	mov    %edx,0x14(%ebp)
f010106c:	8b 00                	mov    (%eax),%eax
f010106e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101071:	89 c7                	mov    %eax,%edi
f0101073:	c1 ff 1f             	sar    $0x1f,%edi
f0101076:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101079:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010107c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010107f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101084:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101088:	0f 89 9d 00 00 00    	jns    f010112b <vprintfmt+0x3b6>
				putch('-', putdat);
f010108e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101092:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101099:	ff d6                	call   *%esi
				num = -(long long) num;
f010109b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010109e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01010a1:	f7 d8                	neg    %eax
f01010a3:	83 d2 00             	adc    $0x0,%edx
f01010a6:	f7 da                	neg    %edx
			}
			base = 10;
f01010a8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010ad:	eb 7c                	jmp    f010112b <vprintfmt+0x3b6>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010af:	8d 45 14             	lea    0x14(%ebp),%eax
f01010b2:	e8 3f fc ff ff       	call   f0100cf6 <getuint>
			base = 10;
f01010b7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010bc:	eb 6d                	jmp    f010112b <vprintfmt+0x3b6>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c2:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010c9:	ff d6                	call   *%esi
			putch('X', putdat);
f01010cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010cf:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010d6:	ff d6                	call   *%esi
			putch('X', putdat);
f01010d8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010dc:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010e3:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010e5:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010e8:	e9 ad fc ff ff       	jmp    f0100d9a <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f01010ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010f1:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010f8:	ff d6                	call   *%esi
			putch('x', putdat);
f01010fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010fe:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101105:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101107:	8b 45 14             	mov    0x14(%ebp),%eax
f010110a:	8d 50 04             	lea    0x4(%eax),%edx
f010110d:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101110:	8b 00                	mov    (%eax),%eax
f0101112:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101117:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010111c:	eb 0d                	jmp    f010112b <vprintfmt+0x3b6>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010111e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101121:	e8 d0 fb ff ff       	call   f0100cf6 <getuint>
			base = 16;
f0101126:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010112b:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010112f:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101133:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101136:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010113a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010113e:	89 04 24             	mov    %eax,(%esp)
f0101141:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101145:	89 da                	mov    %ebx,%edx
f0101147:	89 f0                	mov    %esi,%eax
f0101149:	e8 c2 fa ff ff       	call   f0100c10 <printnum>
			break;
f010114e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101151:	e9 44 fc ff ff       	jmp    f0100d9a <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101156:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010115a:	89 04 24             	mov    %eax,(%esp)
f010115d:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010115f:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101162:	e9 33 fc ff ff       	jmp    f0100d9a <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101167:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010116b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101172:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101174:	eb 03                	jmp    f0101179 <vprintfmt+0x404>
f0101176:	83 ef 01             	sub    $0x1,%edi
f0101179:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010117d:	75 f7                	jne    f0101176 <vprintfmt+0x401>
f010117f:	90                   	nop
f0101180:	e9 15 fc ff ff       	jmp    f0100d9a <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101185:	83 c4 4c             	add    $0x4c,%esp
f0101188:	5b                   	pop    %ebx
f0101189:	5e                   	pop    %esi
f010118a:	5f                   	pop    %edi
f010118b:	5d                   	pop    %ebp
f010118c:	c3                   	ret    

f010118d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010118d:	55                   	push   %ebp
f010118e:	89 e5                	mov    %esp,%ebp
f0101190:	83 ec 28             	sub    $0x28,%esp
f0101193:	8b 45 08             	mov    0x8(%ebp),%eax
f0101196:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101199:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010119c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011a0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011aa:	85 d2                	test   %edx,%edx
f01011ac:	7e 30                	jle    f01011de <vsnprintf+0x51>
f01011ae:	85 c0                	test   %eax,%eax
f01011b0:	74 2c                	je     f01011de <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011b9:	8b 45 10             	mov    0x10(%ebp),%eax
f01011bc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011c7:	c7 04 24 30 0d 10 f0 	movl   $0xf0100d30,(%esp)
f01011ce:	e8 a2 fb ff ff       	call   f0100d75 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011d6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011dc:	eb 05                	jmp    f01011e3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011de:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011e3:	c9                   	leave  
f01011e4:	c3                   	ret    

f01011e5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011e5:	55                   	push   %ebp
f01011e6:	89 e5                	mov    %esp,%ebp
f01011e8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011eb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011f2:	8b 45 10             	mov    0x10(%ebp),%eax
f01011f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101200:	8b 45 08             	mov    0x8(%ebp),%eax
f0101203:	89 04 24             	mov    %eax,(%esp)
f0101206:	e8 82 ff ff ff       	call   f010118d <vsnprintf>
	va_end(ap);

	return rc;
}
f010120b:	c9                   	leave  
f010120c:	c3                   	ret    
f010120d:	66 90                	xchg   %ax,%ax
f010120f:	90                   	nop

f0101210 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101210:	55                   	push   %ebp
f0101211:	89 e5                	mov    %esp,%ebp
f0101213:	57                   	push   %edi
f0101214:	56                   	push   %esi
f0101215:	53                   	push   %ebx
f0101216:	83 ec 1c             	sub    $0x1c,%esp
f0101219:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010121c:	85 c0                	test   %eax,%eax
f010121e:	74 10                	je     f0101230 <readline+0x20>
		cprintf("%s", prompt);
f0101220:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101224:	c7 04 24 92 1e 10 f0 	movl   $0xf0101e92,(%esp)
f010122b:	e8 fe f6 ff ff       	call   f010092e <cprintf>

	i = 0;
	echoing = iscons(0);
f0101230:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101237:	e8 43 f4 ff ff       	call   f010067f <iscons>
f010123c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010123e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101243:	e8 26 f4 ff ff       	call   f010066e <getchar>
f0101248:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010124a:	85 c0                	test   %eax,%eax
f010124c:	79 17                	jns    f0101265 <readline+0x55>
			cprintf("read error: %e\n", c);
f010124e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101252:	c7 04 24 74 20 10 f0 	movl   $0xf0102074,(%esp)
f0101259:	e8 d0 f6 ff ff       	call   f010092e <cprintf>
			return NULL;
f010125e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101263:	eb 6d                	jmp    f01012d2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101265:	83 f8 7f             	cmp    $0x7f,%eax
f0101268:	74 05                	je     f010126f <readline+0x5f>
f010126a:	83 f8 08             	cmp    $0x8,%eax
f010126d:	75 19                	jne    f0101288 <readline+0x78>
f010126f:	85 f6                	test   %esi,%esi
f0101271:	7e 15                	jle    f0101288 <readline+0x78>
			if (echoing)
f0101273:	85 ff                	test   %edi,%edi
f0101275:	74 0c                	je     f0101283 <readline+0x73>
				cputchar('\b');
f0101277:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010127e:	e8 db f3 ff ff       	call   f010065e <cputchar>
			i--;
f0101283:	83 ee 01             	sub    $0x1,%esi
f0101286:	eb bb                	jmp    f0101243 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101288:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010128e:	7f 1c                	jg     f01012ac <readline+0x9c>
f0101290:	83 fb 1f             	cmp    $0x1f,%ebx
f0101293:	7e 17                	jle    f01012ac <readline+0x9c>
			if (echoing)
f0101295:	85 ff                	test   %edi,%edi
f0101297:	74 08                	je     f01012a1 <readline+0x91>
				cputchar(c);
f0101299:	89 1c 24             	mov    %ebx,(%esp)
f010129c:	e8 bd f3 ff ff       	call   f010065e <cputchar>
			buf[i++] = c;
f01012a1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012a7:	83 c6 01             	add    $0x1,%esi
f01012aa:	eb 97                	jmp    f0101243 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012ac:	83 fb 0d             	cmp    $0xd,%ebx
f01012af:	74 05                	je     f01012b6 <readline+0xa6>
f01012b1:	83 fb 0a             	cmp    $0xa,%ebx
f01012b4:	75 8d                	jne    f0101243 <readline+0x33>
			if (echoing)
f01012b6:	85 ff                	test   %edi,%edi
f01012b8:	74 0c                	je     f01012c6 <readline+0xb6>
				cputchar('\n');
f01012ba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012c1:	e8 98 f3 ff ff       	call   f010065e <cputchar>
			buf[i] = 0;
f01012c6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012cd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012d2:	83 c4 1c             	add    $0x1c,%esp
f01012d5:	5b                   	pop    %ebx
f01012d6:	5e                   	pop    %esi
f01012d7:	5f                   	pop    %edi
f01012d8:	5d                   	pop    %ebp
f01012d9:	c3                   	ret    
f01012da:	66 90                	xchg   %ax,%ax
f01012dc:	66 90                	xchg   %ax,%ax
f01012de:	66 90                	xchg   %ax,%ax

f01012e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012e0:	55                   	push   %ebp
f01012e1:	89 e5                	mov    %esp,%ebp
f01012e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012eb:	eb 03                	jmp    f01012f0 <strlen+0x10>
		n++;
f01012ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012f4:	75 f7                	jne    f01012ed <strlen+0xd>
		n++;
	return n;
}
f01012f6:	5d                   	pop    %ebp
f01012f7:	c3                   	ret    

f01012f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012f8:	55                   	push   %ebp
f01012f9:	89 e5                	mov    %esp,%ebp
f01012fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01012fe:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101301:	b8 00 00 00 00       	mov    $0x0,%eax
f0101306:	eb 03                	jmp    f010130b <strnlen+0x13>
		n++;
f0101308:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010130b:	39 d0                	cmp    %edx,%eax
f010130d:	74 06                	je     f0101315 <strnlen+0x1d>
f010130f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101313:	75 f3                	jne    f0101308 <strnlen+0x10>
		n++;
	return n;
}
f0101315:	5d                   	pop    %ebp
f0101316:	c3                   	ret    

f0101317 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101317:	55                   	push   %ebp
f0101318:	89 e5                	mov    %esp,%ebp
f010131a:	53                   	push   %ebx
f010131b:	8b 45 08             	mov    0x8(%ebp),%eax
f010131e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101321:	89 c2                	mov    %eax,%edx
f0101323:	0f b6 19             	movzbl (%ecx),%ebx
f0101326:	88 1a                	mov    %bl,(%edx)
f0101328:	83 c2 01             	add    $0x1,%edx
f010132b:	83 c1 01             	add    $0x1,%ecx
f010132e:	84 db                	test   %bl,%bl
f0101330:	75 f1                	jne    f0101323 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101332:	5b                   	pop    %ebx
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	53                   	push   %ebx
f0101339:	83 ec 08             	sub    $0x8,%esp
f010133c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010133f:	89 1c 24             	mov    %ebx,(%esp)
f0101342:	e8 99 ff ff ff       	call   f01012e0 <strlen>
	strcpy(dst + len, src);
f0101347:	8b 55 0c             	mov    0xc(%ebp),%edx
f010134a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010134e:	01 d8                	add    %ebx,%eax
f0101350:	89 04 24             	mov    %eax,(%esp)
f0101353:	e8 bf ff ff ff       	call   f0101317 <strcpy>
	return dst;
}
f0101358:	89 d8                	mov    %ebx,%eax
f010135a:	83 c4 08             	add    $0x8,%esp
f010135d:	5b                   	pop    %ebx
f010135e:	5d                   	pop    %ebp
f010135f:	c3                   	ret    

f0101360 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101360:	55                   	push   %ebp
f0101361:	89 e5                	mov    %esp,%ebp
f0101363:	56                   	push   %esi
f0101364:	53                   	push   %ebx
f0101365:	8b 75 08             	mov    0x8(%ebp),%esi
f0101368:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010136b:	89 f3                	mov    %esi,%ebx
f010136d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101370:	89 f2                	mov    %esi,%edx
f0101372:	eb 0e                	jmp    f0101382 <strncpy+0x22>
		*dst++ = *src;
f0101374:	0f b6 01             	movzbl (%ecx),%eax
f0101377:	88 02                	mov    %al,(%edx)
f0101379:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010137c:	80 39 01             	cmpb   $0x1,(%ecx)
f010137f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101382:	39 da                	cmp    %ebx,%edx
f0101384:	75 ee                	jne    f0101374 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101386:	89 f0                	mov    %esi,%eax
f0101388:	5b                   	pop    %ebx
f0101389:	5e                   	pop    %esi
f010138a:	5d                   	pop    %ebp
f010138b:	c3                   	ret    

f010138c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010138c:	55                   	push   %ebp
f010138d:	89 e5                	mov    %esp,%ebp
f010138f:	56                   	push   %esi
f0101390:	53                   	push   %ebx
f0101391:	8b 75 08             	mov    0x8(%ebp),%esi
f0101394:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101397:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010139a:	89 f0                	mov    %esi,%eax
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010139c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013a0:	85 c9                	test   %ecx,%ecx
f01013a2:	75 0a                	jne    f01013ae <strlcpy+0x22>
f01013a4:	eb 1c                	jmp    f01013c2 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013a6:	88 08                	mov    %cl,(%eax)
f01013a8:	83 c0 01             	add    $0x1,%eax
f01013ab:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013ae:	39 d8                	cmp    %ebx,%eax
f01013b0:	74 0b                	je     f01013bd <strlcpy+0x31>
f01013b2:	0f b6 0a             	movzbl (%edx),%ecx
f01013b5:	84 c9                	test   %cl,%cl
f01013b7:	75 ed                	jne    f01013a6 <strlcpy+0x1a>
f01013b9:	89 c2                	mov    %eax,%edx
f01013bb:	eb 02                	jmp    f01013bf <strlcpy+0x33>
f01013bd:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013bf:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013c2:	29 f0                	sub    %esi,%eax
}
f01013c4:	5b                   	pop    %ebx
f01013c5:	5e                   	pop    %esi
f01013c6:	5d                   	pop    %ebp
f01013c7:	c3                   	ret    

f01013c8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ce:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013d1:	eb 06                	jmp    f01013d9 <strcmp+0x11>
		p++, q++;
f01013d3:	83 c1 01             	add    $0x1,%ecx
f01013d6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013d9:	0f b6 01             	movzbl (%ecx),%eax
f01013dc:	84 c0                	test   %al,%al
f01013de:	74 04                	je     f01013e4 <strcmp+0x1c>
f01013e0:	3a 02                	cmp    (%edx),%al
f01013e2:	74 ef                	je     f01013d3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013e4:	0f b6 c0             	movzbl %al,%eax
f01013e7:	0f b6 12             	movzbl (%edx),%edx
f01013ea:	29 d0                	sub    %edx,%eax
}
f01013ec:	5d                   	pop    %ebp
f01013ed:	c3                   	ret    

f01013ee <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013ee:	55                   	push   %ebp
f01013ef:	89 e5                	mov    %esp,%ebp
f01013f1:	53                   	push   %ebx
f01013f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f5:	8b 55 0c             	mov    0xc(%ebp),%edx
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f01013f8:	89 c3                	mov    %eax,%ebx
f01013fa:	03 5d 10             	add    0x10(%ebp),%ebx
{
	while (n > 0 && *p && *p == *q)
f01013fd:	eb 06                	jmp    f0101405 <strncmp+0x17>
		n--, p++, q++;
f01013ff:	83 c0 01             	add    $0x1,%eax
f0101402:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101405:	39 d8                	cmp    %ebx,%eax
f0101407:	74 15                	je     f010141e <strncmp+0x30>
f0101409:	0f b6 08             	movzbl (%eax),%ecx
f010140c:	84 c9                	test   %cl,%cl
f010140e:	74 04                	je     f0101414 <strncmp+0x26>
f0101410:	3a 0a                	cmp    (%edx),%cl
f0101412:	74 eb                	je     f01013ff <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101414:	0f b6 00             	movzbl (%eax),%eax
f0101417:	0f b6 12             	movzbl (%edx),%edx
f010141a:	29 d0                	sub    %edx,%eax
f010141c:	eb 05                	jmp    f0101423 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010141e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101423:	5b                   	pop    %ebx
f0101424:	5d                   	pop    %ebp
f0101425:	c3                   	ret    

f0101426 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101426:	55                   	push   %ebp
f0101427:	89 e5                	mov    %esp,%ebp
f0101429:	8b 45 08             	mov    0x8(%ebp),%eax
f010142c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101430:	eb 07                	jmp    f0101439 <strchr+0x13>
		if (*s == c)
f0101432:	38 ca                	cmp    %cl,%dl
f0101434:	74 0f                	je     f0101445 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101436:	83 c0 01             	add    $0x1,%eax
f0101439:	0f b6 10             	movzbl (%eax),%edx
f010143c:	84 d2                	test   %dl,%dl
f010143e:	75 f2                	jne    f0101432 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101440:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101445:	5d                   	pop    %ebp
f0101446:	c3                   	ret    

f0101447 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	8b 45 08             	mov    0x8(%ebp),%eax
f010144d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101451:	eb 07                	jmp    f010145a <strfind+0x13>
		if (*s == c)
f0101453:	38 ca                	cmp    %cl,%dl
f0101455:	74 0a                	je     f0101461 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101457:	83 c0 01             	add    $0x1,%eax
f010145a:	0f b6 10             	movzbl (%eax),%edx
f010145d:	84 d2                	test   %dl,%dl
f010145f:	75 f2                	jne    f0101453 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101461:	5d                   	pop    %ebp
f0101462:	c3                   	ret    

f0101463 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101463:	55                   	push   %ebp
f0101464:	89 e5                	mov    %esp,%ebp
f0101466:	83 ec 0c             	sub    $0xc,%esp
f0101469:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010146c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010146f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101472:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101475:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101478:	85 c9                	test   %ecx,%ecx
f010147a:	74 36                	je     f01014b2 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010147c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101482:	75 28                	jne    f01014ac <memset+0x49>
f0101484:	f6 c1 03             	test   $0x3,%cl
f0101487:	75 23                	jne    f01014ac <memset+0x49>
		c &= 0xFF;
f0101489:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010148d:	89 d3                	mov    %edx,%ebx
f010148f:	c1 e3 08             	shl    $0x8,%ebx
f0101492:	89 d6                	mov    %edx,%esi
f0101494:	c1 e6 18             	shl    $0x18,%esi
f0101497:	89 d0                	mov    %edx,%eax
f0101499:	c1 e0 10             	shl    $0x10,%eax
f010149c:	09 f0                	or     %esi,%eax
f010149e:	09 c2                	or     %eax,%edx
f01014a0:	89 d0                	mov    %edx,%eax
f01014a2:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014a4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014a7:	fc                   	cld    
f01014a8:	f3 ab                	rep stos %eax,%es:(%edi)
f01014aa:	eb 06                	jmp    f01014b2 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014ac:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014af:	fc                   	cld    
f01014b0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014b2:	89 f8                	mov    %edi,%eax
f01014b4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01014b7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01014ba:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01014bd:	89 ec                	mov    %ebp,%esp
f01014bf:	5d                   	pop    %ebp
f01014c0:	c3                   	ret    

f01014c1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014c1:	55                   	push   %ebp
f01014c2:	89 e5                	mov    %esp,%ebp
f01014c4:	83 ec 08             	sub    $0x8,%esp
f01014c7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01014ca:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01014cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014d3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014d6:	39 c6                	cmp    %eax,%esi
f01014d8:	73 36                	jae    f0101510 <memmove+0x4f>
f01014da:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014dd:	39 d0                	cmp    %edx,%eax
f01014df:	73 2f                	jae    f0101510 <memmove+0x4f>
		s += n;
		d += n;
f01014e1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014e4:	f6 c2 03             	test   $0x3,%dl
f01014e7:	75 1b                	jne    f0101504 <memmove+0x43>
f01014e9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ef:	75 13                	jne    f0101504 <memmove+0x43>
f01014f1:	f6 c1 03             	test   $0x3,%cl
f01014f4:	75 0e                	jne    f0101504 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014f6:	83 ef 04             	sub    $0x4,%edi
f01014f9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014fc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01014ff:	fd                   	std    
f0101500:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101502:	eb 09                	jmp    f010150d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101504:	83 ef 01             	sub    $0x1,%edi
f0101507:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010150a:	fd                   	std    
f010150b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010150d:	fc                   	cld    
f010150e:	eb 20                	jmp    f0101530 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101510:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101516:	75 13                	jne    f010152b <memmove+0x6a>
f0101518:	a8 03                	test   $0x3,%al
f010151a:	75 0f                	jne    f010152b <memmove+0x6a>
f010151c:	f6 c1 03             	test   $0x3,%cl
f010151f:	75 0a                	jne    f010152b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101521:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101524:	89 c7                	mov    %eax,%edi
f0101526:	fc                   	cld    
f0101527:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101529:	eb 05                	jmp    f0101530 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010152b:	89 c7                	mov    %eax,%edi
f010152d:	fc                   	cld    
f010152e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101530:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101533:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101536:	89 ec                	mov    %ebp,%esp
f0101538:	5d                   	pop    %ebp
f0101539:	c3                   	ret    

f010153a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010153a:	55                   	push   %ebp
f010153b:	89 e5                	mov    %esp,%ebp
f010153d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101540:	8b 45 10             	mov    0x10(%ebp),%eax
f0101543:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101547:	8b 45 0c             	mov    0xc(%ebp),%eax
f010154a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010154e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101551:	89 04 24             	mov    %eax,(%esp)
f0101554:	e8 68 ff ff ff       	call   f01014c1 <memmove>
}
f0101559:	c9                   	leave  
f010155a:	c3                   	ret    

f010155b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010155b:	55                   	push   %ebp
f010155c:	89 e5                	mov    %esp,%ebp
f010155e:	56                   	push   %esi
f010155f:	53                   	push   %ebx
f0101560:	8b 55 08             	mov    0x8(%ebp),%edx
f0101563:	8b 4d 0c             	mov    0xc(%ebp),%ecx
{
	return memmove(dst, src, n);
}

int
memcmp(const void *v1, const void *v2, size_t n)
f0101566:	89 d6                	mov    %edx,%esi
f0101568:	03 75 10             	add    0x10(%ebp),%esi
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010156b:	eb 1a                	jmp    f0101587 <memcmp+0x2c>
		if (*s1 != *s2)
f010156d:	0f b6 02             	movzbl (%edx),%eax
f0101570:	0f b6 19             	movzbl (%ecx),%ebx
f0101573:	38 d8                	cmp    %bl,%al
f0101575:	74 0a                	je     f0101581 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101577:	0f b6 c0             	movzbl %al,%eax
f010157a:	0f b6 db             	movzbl %bl,%ebx
f010157d:	29 d8                	sub    %ebx,%eax
f010157f:	eb 0f                	jmp    f0101590 <memcmp+0x35>
		s1++, s2++;
f0101581:	83 c2 01             	add    $0x1,%edx
f0101584:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101587:	39 f2                	cmp    %esi,%edx
f0101589:	75 e2                	jne    f010156d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010158b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101590:	5b                   	pop    %ebx
f0101591:	5e                   	pop    %esi
f0101592:	5d                   	pop    %ebp
f0101593:	c3                   	ret    

f0101594 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101594:	55                   	push   %ebp
f0101595:	89 e5                	mov    %esp,%ebp
f0101597:	8b 45 08             	mov    0x8(%ebp),%eax
f010159a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010159d:	89 c2                	mov    %eax,%edx
f010159f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015a2:	eb 07                	jmp    f01015ab <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a4:	38 08                	cmp    %cl,(%eax)
f01015a6:	74 07                	je     f01015af <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a8:	83 c0 01             	add    $0x1,%eax
f01015ab:	39 d0                	cmp    %edx,%eax
f01015ad:	72 f5                	jb     f01015a4 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015af:	5d                   	pop    %ebp
f01015b0:	c3                   	ret    

f01015b1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b1:	55                   	push   %ebp
f01015b2:	89 e5                	mov    %esp,%ebp
f01015b4:	57                   	push   %edi
f01015b5:	56                   	push   %esi
f01015b6:	53                   	push   %ebx
f01015b7:	83 ec 04             	sub    $0x4,%esp
f01015ba:	8b 55 08             	mov    0x8(%ebp),%edx
f01015bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c0:	eb 03                	jmp    f01015c5 <strtol+0x14>
		s++;
f01015c2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c5:	0f b6 02             	movzbl (%edx),%eax
f01015c8:	3c 09                	cmp    $0x9,%al
f01015ca:	74 f6                	je     f01015c2 <strtol+0x11>
f01015cc:	3c 20                	cmp    $0x20,%al
f01015ce:	74 f2                	je     f01015c2 <strtol+0x11>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015d0:	3c 2b                	cmp    $0x2b,%al
f01015d2:	75 0a                	jne    f01015de <strtol+0x2d>
		s++;
f01015d4:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01015dc:	eb 10                	jmp    f01015ee <strtol+0x3d>
f01015de:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015e3:	3c 2d                	cmp    $0x2d,%al
f01015e5:	75 07                	jne    f01015ee <strtol+0x3d>
		s++, neg = 1;
f01015e7:	8d 52 01             	lea    0x1(%edx),%edx
f01015ea:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015ee:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015f4:	75 15                	jne    f010160b <strtol+0x5a>
f01015f6:	80 3a 30             	cmpb   $0x30,(%edx)
f01015f9:	75 10                	jne    f010160b <strtol+0x5a>
f01015fb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01015ff:	75 0a                	jne    f010160b <strtol+0x5a>
		s += 2, base = 16;
f0101601:	83 c2 02             	add    $0x2,%edx
f0101604:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101609:	eb 10                	jmp    f010161b <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010160b:	85 db                	test   %ebx,%ebx
f010160d:	75 0c                	jne    f010161b <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010160f:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101611:	80 3a 30             	cmpb   $0x30,(%edx)
f0101614:	75 05                	jne    f010161b <strtol+0x6a>
		s++, base = 8;
f0101616:	83 c2 01             	add    $0x1,%edx
f0101619:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010161b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101620:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101623:	0f b6 0a             	movzbl (%edx),%ecx
f0101626:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101629:	89 f3                	mov    %esi,%ebx
f010162b:	80 fb 09             	cmp    $0x9,%bl
f010162e:	77 08                	ja     f0101638 <strtol+0x87>
			dig = *s - '0';
f0101630:	0f be c9             	movsbl %cl,%ecx
f0101633:	83 e9 30             	sub    $0x30,%ecx
f0101636:	eb 22                	jmp    f010165a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0101638:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010163b:	89 f3                	mov    %esi,%ebx
f010163d:	80 fb 19             	cmp    $0x19,%bl
f0101640:	77 08                	ja     f010164a <strtol+0x99>
			dig = *s - 'a' + 10;
f0101642:	0f be c9             	movsbl %cl,%ecx
f0101645:	83 e9 57             	sub    $0x57,%ecx
f0101648:	eb 10                	jmp    f010165a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f010164a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010164d:	89 f3                	mov    %esi,%ebx
f010164f:	80 fb 19             	cmp    $0x19,%bl
f0101652:	77 16                	ja     f010166a <strtol+0xb9>
			dig = *s - 'A' + 10;
f0101654:	0f be c9             	movsbl %cl,%ecx
f0101657:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010165a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010165d:	7d 0f                	jge    f010166e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010165f:	83 c2 01             	add    $0x1,%edx
f0101662:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101666:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101668:	eb b9                	jmp    f0101623 <strtol+0x72>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010166a:	89 c1                	mov    %eax,%ecx
f010166c:	eb 02                	jmp    f0101670 <strtol+0xbf>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010166e:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101670:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101674:	74 05                	je     f010167b <strtol+0xca>
		*endptr = (char *) s;
f0101676:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101679:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010167b:	89 ca                	mov    %ecx,%edx
f010167d:	f7 da                	neg    %edx
f010167f:	85 ff                	test   %edi,%edi
f0101681:	0f 45 c2             	cmovne %edx,%eax
}
f0101684:	83 c4 04             	add    $0x4,%esp
f0101687:	5b                   	pop    %ebx
f0101688:	5e                   	pop    %esi
f0101689:	5f                   	pop    %edi
f010168a:	5d                   	pop    %ebp
f010168b:	c3                   	ret    
f010168c:	66 90                	xchg   %ax,%ax
f010168e:	66 90                	xchg   %ax,%ax

f0101690 <__udivdi3>:
f0101690:	83 ec 1c             	sub    $0x1c,%esp
f0101693:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101697:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010169b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010169f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01016a3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01016a7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f01016ab:	85 c0                	test   %eax,%eax
f01016ad:	89 74 24 10          	mov    %esi,0x10(%esp)
f01016b1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01016b5:	89 ea                	mov    %ebp,%edx
f01016b7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01016bb:	75 33                	jne    f01016f0 <__udivdi3+0x60>
f01016bd:	39 e9                	cmp    %ebp,%ecx
f01016bf:	77 6f                	ja     f0101730 <__udivdi3+0xa0>
f01016c1:	85 c9                	test   %ecx,%ecx
f01016c3:	89 ce                	mov    %ecx,%esi
f01016c5:	75 0b                	jne    f01016d2 <__udivdi3+0x42>
f01016c7:	b8 01 00 00 00       	mov    $0x1,%eax
f01016cc:	31 d2                	xor    %edx,%edx
f01016ce:	f7 f1                	div    %ecx
f01016d0:	89 c6                	mov    %eax,%esi
f01016d2:	31 d2                	xor    %edx,%edx
f01016d4:	89 e8                	mov    %ebp,%eax
f01016d6:	f7 f6                	div    %esi
f01016d8:	89 c5                	mov    %eax,%ebp
f01016da:	89 f8                	mov    %edi,%eax
f01016dc:	f7 f6                	div    %esi
f01016de:	89 ea                	mov    %ebp,%edx
f01016e0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01016e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01016e8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01016ec:	83 c4 1c             	add    $0x1c,%esp
f01016ef:	c3                   	ret    
f01016f0:	39 e8                	cmp    %ebp,%eax
f01016f2:	77 24                	ja     f0101718 <__udivdi3+0x88>
f01016f4:	0f bd c8             	bsr    %eax,%ecx
f01016f7:	83 f1 1f             	xor    $0x1f,%ecx
f01016fa:	89 0c 24             	mov    %ecx,(%esp)
f01016fd:	75 49                	jne    f0101748 <__udivdi3+0xb8>
f01016ff:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101703:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0101707:	0f 86 ab 00 00 00    	jbe    f01017b8 <__udivdi3+0x128>
f010170d:	39 e8                	cmp    %ebp,%eax
f010170f:	0f 82 a3 00 00 00    	jb     f01017b8 <__udivdi3+0x128>
f0101715:	8d 76 00             	lea    0x0(%esi),%esi
f0101718:	31 d2                	xor    %edx,%edx
f010171a:	31 c0                	xor    %eax,%eax
f010171c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101720:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101724:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101728:	83 c4 1c             	add    $0x1c,%esp
f010172b:	c3                   	ret    
f010172c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101730:	89 f8                	mov    %edi,%eax
f0101732:	f7 f1                	div    %ecx
f0101734:	31 d2                	xor    %edx,%edx
f0101736:	8b 74 24 10          	mov    0x10(%esp),%esi
f010173a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010173e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101742:	83 c4 1c             	add    $0x1c,%esp
f0101745:	c3                   	ret    
f0101746:	66 90                	xchg   %ax,%ax
f0101748:	0f b6 0c 24          	movzbl (%esp),%ecx
f010174c:	89 c6                	mov    %eax,%esi
f010174e:	b8 20 00 00 00       	mov    $0x20,%eax
f0101753:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101757:	2b 04 24             	sub    (%esp),%eax
f010175a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010175e:	d3 e6                	shl    %cl,%esi
f0101760:	89 c1                	mov    %eax,%ecx
f0101762:	d3 ed                	shr    %cl,%ebp
f0101764:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101768:	09 f5                	or     %esi,%ebp
f010176a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010176e:	d3 e6                	shl    %cl,%esi
f0101770:	89 c1                	mov    %eax,%ecx
f0101772:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101776:	89 d6                	mov    %edx,%esi
f0101778:	d3 ee                	shr    %cl,%esi
f010177a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010177e:	d3 e2                	shl    %cl,%edx
f0101780:	89 c1                	mov    %eax,%ecx
f0101782:	d3 ef                	shr    %cl,%edi
f0101784:	09 d7                	or     %edx,%edi
f0101786:	89 f2                	mov    %esi,%edx
f0101788:	89 f8                	mov    %edi,%eax
f010178a:	f7 f5                	div    %ebp
f010178c:	89 d6                	mov    %edx,%esi
f010178e:	89 c7                	mov    %eax,%edi
f0101790:	f7 64 24 04          	mull   0x4(%esp)
f0101794:	39 d6                	cmp    %edx,%esi
f0101796:	72 30                	jb     f01017c8 <__udivdi3+0x138>
f0101798:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010179c:	0f b6 0c 24          	movzbl (%esp),%ecx
f01017a0:	d3 e5                	shl    %cl,%ebp
f01017a2:	39 c5                	cmp    %eax,%ebp
f01017a4:	73 04                	jae    f01017aa <__udivdi3+0x11a>
f01017a6:	39 d6                	cmp    %edx,%esi
f01017a8:	74 1e                	je     f01017c8 <__udivdi3+0x138>
f01017aa:	89 f8                	mov    %edi,%eax
f01017ac:	31 d2                	xor    %edx,%edx
f01017ae:	e9 69 ff ff ff       	jmp    f010171c <__udivdi3+0x8c>
f01017b3:	90                   	nop
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01017bf:	e9 58 ff ff ff       	jmp    f010171c <__udivdi3+0x8c>
f01017c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017d1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017d5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017d9:	83 c4 1c             	add    $0x1c,%esp
f01017dc:	c3                   	ret    
f01017dd:	66 90                	xchg   %ax,%ax
f01017df:	90                   	nop

f01017e0 <__umoddi3>:
f01017e0:	83 ec 2c             	sub    $0x2c,%esp
f01017e3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01017e7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017eb:	89 74 24 20          	mov    %esi,0x20(%esp)
f01017ef:	8b 74 24 38          	mov    0x38(%esp),%esi
f01017f3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f01017f7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f01017fb:	85 c0                	test   %eax,%eax
f01017fd:	89 c2                	mov    %eax,%edx
f01017ff:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0101803:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101807:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010180b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010180f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101813:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101817:	75 1f                	jne    f0101838 <__umoddi3+0x58>
f0101819:	39 fe                	cmp    %edi,%esi
f010181b:	76 63                	jbe    f0101880 <__umoddi3+0xa0>
f010181d:	89 c8                	mov    %ecx,%eax
f010181f:	89 fa                	mov    %edi,%edx
f0101821:	f7 f6                	div    %esi
f0101823:	89 d0                	mov    %edx,%eax
f0101825:	31 d2                	xor    %edx,%edx
f0101827:	8b 74 24 20          	mov    0x20(%esp),%esi
f010182b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010182f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101833:	83 c4 2c             	add    $0x2c,%esp
f0101836:	c3                   	ret    
f0101837:	90                   	nop
f0101838:	39 f8                	cmp    %edi,%eax
f010183a:	77 64                	ja     f01018a0 <__umoddi3+0xc0>
f010183c:	0f bd e8             	bsr    %eax,%ebp
f010183f:	83 f5 1f             	xor    $0x1f,%ebp
f0101842:	75 74                	jne    f01018b8 <__umoddi3+0xd8>
f0101844:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101848:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010184c:	0f 87 0e 01 00 00    	ja     f0101960 <__umoddi3+0x180>
f0101852:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101856:	29 f1                	sub    %esi,%ecx
f0101858:	19 c7                	sbb    %eax,%edi
f010185a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010185e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101862:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101866:	8b 54 24 18          	mov    0x18(%esp),%edx
f010186a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010186e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101872:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101876:	83 c4 2c             	add    $0x2c,%esp
f0101879:	c3                   	ret    
f010187a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101880:	85 f6                	test   %esi,%esi
f0101882:	89 f5                	mov    %esi,%ebp
f0101884:	75 0b                	jne    f0101891 <__umoddi3+0xb1>
f0101886:	b8 01 00 00 00       	mov    $0x1,%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	f7 f6                	div    %esi
f010188f:	89 c5                	mov    %eax,%ebp
f0101891:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101895:	31 d2                	xor    %edx,%edx
f0101897:	f7 f5                	div    %ebp
f0101899:	89 c8                	mov    %ecx,%eax
f010189b:	f7 f5                	div    %ebp
f010189d:	eb 84                	jmp    f0101823 <__umoddi3+0x43>
f010189f:	90                   	nop
f01018a0:	89 c8                	mov    %ecx,%eax
f01018a2:	89 fa                	mov    %edi,%edx
f01018a4:	8b 74 24 20          	mov    0x20(%esp),%esi
f01018a8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01018ac:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01018b0:	83 c4 2c             	add    $0x2c,%esp
f01018b3:	c3                   	ret    
f01018b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b8:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018bc:	be 20 00 00 00       	mov    $0x20,%esi
f01018c1:	89 e9                	mov    %ebp,%ecx
f01018c3:	29 ee                	sub    %ebp,%esi
f01018c5:	d3 e2                	shl    %cl,%edx
f01018c7:	89 f1                	mov    %esi,%ecx
f01018c9:	d3 e8                	shr    %cl,%eax
f01018cb:	89 e9                	mov    %ebp,%ecx
f01018cd:	09 d0                	or     %edx,%eax
f01018cf:	89 fa                	mov    %edi,%edx
f01018d1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018d5:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018d9:	d3 e0                	shl    %cl,%eax
f01018db:	89 f1                	mov    %esi,%ecx
f01018dd:	89 44 24 10          	mov    %eax,0x10(%esp)
f01018e1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01018e5:	d3 ea                	shr    %cl,%edx
f01018e7:	89 e9                	mov    %ebp,%ecx
f01018e9:	d3 e7                	shl    %cl,%edi
f01018eb:	89 f1                	mov    %esi,%ecx
f01018ed:	d3 e8                	shr    %cl,%eax
f01018ef:	89 e9                	mov    %ebp,%ecx
f01018f1:	09 f8                	or     %edi,%eax
f01018f3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01018f7:	f7 74 24 0c          	divl   0xc(%esp)
f01018fb:	d3 e7                	shl    %cl,%edi
f01018fd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101901:	89 d7                	mov    %edx,%edi
f0101903:	f7 64 24 10          	mull   0x10(%esp)
f0101907:	39 d7                	cmp    %edx,%edi
f0101909:	89 c1                	mov    %eax,%ecx
f010190b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010190f:	72 3b                	jb     f010194c <__umoddi3+0x16c>
f0101911:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0101915:	72 31                	jb     f0101948 <__umoddi3+0x168>
f0101917:	8b 44 24 18          	mov    0x18(%esp),%eax
f010191b:	29 c8                	sub    %ecx,%eax
f010191d:	19 d7                	sbb    %edx,%edi
f010191f:	89 e9                	mov    %ebp,%ecx
f0101921:	89 fa                	mov    %edi,%edx
f0101923:	d3 e8                	shr    %cl,%eax
f0101925:	89 f1                	mov    %esi,%ecx
f0101927:	d3 e2                	shl    %cl,%edx
f0101929:	89 e9                	mov    %ebp,%ecx
f010192b:	09 d0                	or     %edx,%eax
f010192d:	89 fa                	mov    %edi,%edx
f010192f:	d3 ea                	shr    %cl,%edx
f0101931:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101935:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101939:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f010193d:	83 c4 2c             	add    $0x2c,%esp
f0101940:	c3                   	ret    
f0101941:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101948:	39 d7                	cmp    %edx,%edi
f010194a:	75 cb                	jne    f0101917 <__umoddi3+0x137>
f010194c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101950:	89 c1                	mov    %eax,%ecx
f0101952:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101956:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010195a:	eb bb                	jmp    f0101917 <__umoddi3+0x137>
f010195c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101960:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101964:	0f 82 e8 fe ff ff    	jb     f0101852 <__umoddi3+0x72>
f010196a:	e9 f3 fe ff ff       	jmp    f0101862 <__umoddi3+0x82>
