
obj/kern/kernel：     文件格式 elf32-i386


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
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 bc 72 01 00    	add    $0x172bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 f4 3c 00 00       	call   f0103d5d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 98 ce fe ff    	lea    -0x13168(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 d5 30 00 00       	call   f0103157 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 86 12 00 00       	call   f010130d <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 62 08 00 00       	call   f01008f6 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 61 72 01 00    	add    $0x17261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 31 08 00 00       	call   f01008f6 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 b3 ce fe ff    	lea    -0x1314d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 71 30 00 00       	call   f0103157 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 30 30 00 00       	call   f0103120 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 80 dd fe ff    	lea    -0x12280(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 59 30 00 00       	call   f0103157 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 fb 71 01 00    	add    $0x171fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 cb ce fe ff    	lea    -0x13135(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 2c 30 00 00       	call   f0103157 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 e9 2f 00 00       	call   f0103120 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 80 dd fe ff    	lea    -0x12280(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 12 30 00 00       	call   f0103157 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 8c 71 01 00    	add    $0x1718c,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 41 71 01 00    	add    $0x17141,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 18 d0 fe 	movzbl -0x12fe8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 18 cf fe 	movzbl -0x130e8(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 e5 ce fe ff    	lea    -0x1311b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 e1 2e 00 00       	call   f0103157 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 18 d0 fe 	movzbl -0x12fe8(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0b 70 01 00    	add    $0x1700b,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 d3 38 00 00       	call   f0103daa <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 6d 01 00       	add    $0x16dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b 8e fe ff    	lea    -0x171b5(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d0 6d 01 00       	add    $0x16dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 8e fe ff    	lea    -0x1714b(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b2 6d 01 00    	add    $0x16db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 56 6d 01 00    	add    $0x16d56,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 f1 ce fe ff    	lea    -0x1310f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 96 2a 00 00       	call   f0103157 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 09 6c 01 00    	add    $0x16c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 18 d1 fe ff    	lea    -0x12ee8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 36 d1 fe ff    	lea    -0x12eca(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 3b d1 fe ff    	lea    -0x12ec5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 35 2a 00 00       	call   f0103157 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 e8 d1 fe ff    	lea    -0x12e18(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 44 d1 fe ff    	lea    -0x12ebc(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 1e 2a 00 00       	call   f0103157 <cprintf>
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100741:	5b                   	pop    %ebx
f0100742:	5e                   	pop    %esi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	57                   	push   %edi
f0100749:	56                   	push   %esi
f010074a:	53                   	push   %ebx
f010074b:	83 ec 18             	sub    $0x18,%esp
f010074e:	e8 fc f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100753:	81 c3 b5 6b 01 00    	add    $0x16bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 4d d1 fe ff    	lea    -0x12eb3(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 f2 29 00 00       	call   f0103157 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 10 d2 fe ff    	lea    -0x12df0(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 dd 29 00 00       	call   f0103157 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 38 d2 fe ff    	lea    -0x12dc8(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 c0 29 00 00       	call   f0103157 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 99 41 10 f0    	mov    $0xf0104199,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 5c d2 fe ff    	lea    -0x12da4(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 a3 29 00 00       	call   f0103157 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 80 d2 fe ff    	lea    -0x12d80(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 86 29 00 00       	call   f0103157 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 a4 d2 fe ff    	lea    -0x12d5c(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 69 29 00 00       	call   f0103157 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 c8 d2 fe ff    	lea    -0x12d38(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 4e 29 00 00       	call   f0103157 <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100811:	5b                   	pop    %ebx
f0100812:	5e                   	pop    %esi
f0100813:	5f                   	pop    %edi
f0100814:	5d                   	pop    %ebp
f0100815:	c3                   	ret    

f0100816 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100816:	55                   	push   %ebp
f0100817:	89 e5                	mov    %esp,%ebp
f0100819:	57                   	push   %edi
f010081a:	56                   	push   %esi
f010081b:	53                   	push   %ebx
f010081c:	83 ec 48             	sub    $0x48,%esp
f010081f:	e8 2b f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100824:	81 c3 e4 6a 01 00    	add    $0x16ae4,%ebx
	// Your code here.
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f010082a:	8d 83 66 d1 fe ff    	lea    -0x12e9a(%ebx),%eax
f0100830:	50                   	push   %eax
f0100831:	e8 21 29 00 00       	call   f0103157 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100836:	89 ee                	mov    %ebp,%esi
	uint32_t *  ebp=(uint32_t *)read_ebp();
	while(ebp!=0x0){
f0100838:	83 c4 10             	add    $0x10,%esp
	debuginfo_eip(*(ebp+1),&info);
f010083b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010083e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	cprintf("ebp %08x eip %08x",ebp,*(ebp+1));
f0100841:	8d 83 78 d1 fe ff    	lea    -0x12e88(%ebx),%eax
f0100847:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while(ebp!=0x0){
f010084a:	e9 92 00 00 00       	jmp    f01008e1 <mon_backtrace+0xcb>
	debuginfo_eip(*(ebp+1),&info);
f010084f:	83 ec 08             	sub    $0x8,%esp
f0100852:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100855:	ff 76 04             	pushl  0x4(%esi)
f0100858:	e8 fe 29 00 00       	call   f010325b <debuginfo_eip>
	cprintf("ebp %08x eip %08x",ebp,*(ebp+1));
f010085d:	83 c4 0c             	add    $0xc,%esp
f0100860:	ff 76 04             	pushl  0x4(%esi)
f0100863:	56                   	push   %esi
f0100864:	ff 75 c0             	pushl  -0x40(%ebp)
f0100867:	e8 eb 28 00 00       	call   f0103157 <cprintf>
	cprintf(" args %08x",*(ebp+2));
f010086c:	83 c4 08             	add    $0x8,%esp
f010086f:	ff 76 08             	pushl  0x8(%esi)
f0100872:	8d 83 8a d1 fe ff    	lea    -0x12e76(%ebx),%eax
f0100878:	50                   	push   %eax
f0100879:	e8 d9 28 00 00       	call   f0103157 <cprintf>
	cprintf(" %08x",*(ebp+3));
f010087e:	83 c4 08             	add    $0x8,%esp
f0100881:	ff 76 0c             	pushl  0xc(%esi)
f0100884:	8d bb 84 d1 fe ff    	lea    -0x12e7c(%ebx),%edi
f010088a:	57                   	push   %edi
f010088b:	e8 c7 28 00 00       	call   f0103157 <cprintf>
	cprintf(" %08x",*(ebp+4));
f0100890:	83 c4 08             	add    $0x8,%esp
f0100893:	ff 76 10             	pushl  0x10(%esi)
f0100896:	57                   	push   %edi
f0100897:	e8 bb 28 00 00       	call   f0103157 <cprintf>
	cprintf(" %08x",*(ebp+5));
f010089c:	83 c4 08             	add    $0x8,%esp
f010089f:	ff 76 14             	pushl  0x14(%esi)
f01008a2:	57                   	push   %edi
f01008a3:	e8 af 28 00 00       	call   f0103157 <cprintf>
	cprintf(" %08x\n",*(ebp+6));
f01008a8:	83 c4 08             	add    $0x8,%esp
f01008ab:	ff 76 18             	pushl  0x18(%esi)
f01008ae:	8d 83 95 d1 fe ff    	lea    -0x12e6b(%ebx),%eax
f01008b4:	50                   	push   %eax
f01008b5:	e8 9d 28 00 00       	call   f0103157 <cprintf>
	cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,*(ebp+1)-info.eip_fn_addr);
f01008ba:	83 c4 08             	add    $0x8,%esp
f01008bd:	8b 46 04             	mov    0x4(%esi),%eax
f01008c0:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008c3:	50                   	push   %eax
f01008c4:	ff 75 d8             	pushl  -0x28(%ebp)
f01008c7:	ff 75 dc             	pushl  -0x24(%ebp)
f01008ca:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008cd:	ff 75 d0             	pushl  -0x30(%ebp)
f01008d0:	8d 83 9c d1 fe ff    	lea    -0x12e64(%ebx),%eax
f01008d6:	50                   	push   %eax
f01008d7:	e8 7b 28 00 00       	call   f0103157 <cprintf>
	ebp=(uint32_t *) *(ebp);
f01008dc:	8b 36                	mov    (%esi),%esi
f01008de:	83 c4 20             	add    $0x20,%esp
	while(ebp!=0x0){
f01008e1:	85 f6                	test   %esi,%esi
f01008e3:	0f 85 66 ff ff ff    	jne    f010084f <mon_backtrace+0x39>
	}
 
	return 0;
}
f01008e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f1:	5b                   	pop    %ebx
f01008f2:	5e                   	pop    %esi
f01008f3:	5f                   	pop    %edi
f01008f4:	5d                   	pop    %ebp
f01008f5:	c3                   	ret    

f01008f6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008f6:	55                   	push   %ebp
f01008f7:	89 e5                	mov    %esp,%ebp
f01008f9:	57                   	push   %edi
f01008fa:	56                   	push   %esi
f01008fb:	53                   	push   %ebx
f01008fc:	83 ec 68             	sub    $0x68,%esp
f01008ff:	e8 4b f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100904:	81 c3 04 6a 01 00    	add    $0x16a04,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010090a:	8d 83 f4 d2 fe ff    	lea    -0x12d0c(%ebx),%eax
f0100910:	50                   	push   %eax
f0100911:	e8 41 28 00 00       	call   f0103157 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100916:	8d 83 18 d3 fe ff    	lea    -0x12ce8(%ebx),%eax
f010091c:	89 04 24             	mov    %eax,(%esp)
f010091f:	e8 33 28 00 00       	call   f0103157 <cprintf>
f0100924:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100927:	8d bb b0 d1 fe ff    	lea    -0x12e50(%ebx),%edi
f010092d:	eb 4a                	jmp    f0100979 <monitor+0x83>
f010092f:	83 ec 08             	sub    $0x8,%esp
f0100932:	0f be c0             	movsbl %al,%eax
f0100935:	50                   	push   %eax
f0100936:	57                   	push   %edi
f0100937:	e8 e4 33 00 00       	call   f0103d20 <strchr>
f010093c:	83 c4 10             	add    $0x10,%esp
f010093f:	85 c0                	test   %eax,%eax
f0100941:	74 08                	je     f010094b <monitor+0x55>
			*buf++ = 0;
f0100943:	c6 06 00             	movb   $0x0,(%esi)
f0100946:	8d 76 01             	lea    0x1(%esi),%esi
f0100949:	eb 79                	jmp    f01009c4 <monitor+0xce>
		if (*buf == 0)
f010094b:	80 3e 00             	cmpb   $0x0,(%esi)
f010094e:	74 7f                	je     f01009cf <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100950:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100954:	74 0f                	je     f0100965 <monitor+0x6f>
		argv[argc++] = buf;
f0100956:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100959:	8d 48 01             	lea    0x1(%eax),%ecx
f010095c:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010095f:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100963:	eb 44                	jmp    f01009a9 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100965:	83 ec 08             	sub    $0x8,%esp
f0100968:	6a 10                	push   $0x10
f010096a:	8d 83 b5 d1 fe ff    	lea    -0x12e4b(%ebx),%eax
f0100970:	50                   	push   %eax
f0100971:	e8 e1 27 00 00       	call   f0103157 <cprintf>
f0100976:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100979:	8d 83 ac d1 fe ff    	lea    -0x12e54(%ebx),%eax
f010097f:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100982:	83 ec 0c             	sub    $0xc,%esp
f0100985:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100988:	e8 5b 31 00 00       	call   f0103ae8 <readline>
f010098d:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010098f:	83 c4 10             	add    $0x10,%esp
f0100992:	85 c0                	test   %eax,%eax
f0100994:	74 ec                	je     f0100982 <monitor+0x8c>
	argv[argc] = 0;
f0100996:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010099d:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009a4:	eb 1e                	jmp    f01009c4 <monitor+0xce>
			buf++;
f01009a6:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009a9:	0f b6 06             	movzbl (%esi),%eax
f01009ac:	84 c0                	test   %al,%al
f01009ae:	74 14                	je     f01009c4 <monitor+0xce>
f01009b0:	83 ec 08             	sub    $0x8,%esp
f01009b3:	0f be c0             	movsbl %al,%eax
f01009b6:	50                   	push   %eax
f01009b7:	57                   	push   %edi
f01009b8:	e8 63 33 00 00       	call   f0103d20 <strchr>
f01009bd:	83 c4 10             	add    $0x10,%esp
f01009c0:	85 c0                	test   %eax,%eax
f01009c2:	74 e2                	je     f01009a6 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01009c4:	0f b6 06             	movzbl (%esi),%eax
f01009c7:	84 c0                	test   %al,%al
f01009c9:	0f 85 60 ff ff ff    	jne    f010092f <monitor+0x39>
	argv[argc] = 0;
f01009cf:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009d2:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009d9:	00 
	if (argc == 0)
f01009da:	85 c0                	test   %eax,%eax
f01009dc:	74 9b                	je     f0100979 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009de:	83 ec 08             	sub    $0x8,%esp
f01009e1:	8d 83 36 d1 fe ff    	lea    -0x12eca(%ebx),%eax
f01009e7:	50                   	push   %eax
f01009e8:	ff 75 a8             	pushl  -0x58(%ebp)
f01009eb:	e8 d2 32 00 00       	call   f0103cc2 <strcmp>
f01009f0:	83 c4 10             	add    $0x10,%esp
f01009f3:	85 c0                	test   %eax,%eax
f01009f5:	74 38                	je     f0100a2f <monitor+0x139>
f01009f7:	83 ec 08             	sub    $0x8,%esp
f01009fa:	8d 83 44 d1 fe ff    	lea    -0x12ebc(%ebx),%eax
f0100a00:	50                   	push   %eax
f0100a01:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a04:	e8 b9 32 00 00       	call   f0103cc2 <strcmp>
f0100a09:	83 c4 10             	add    $0x10,%esp
f0100a0c:	85 c0                	test   %eax,%eax
f0100a0e:	74 1a                	je     f0100a2a <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a10:	83 ec 08             	sub    $0x8,%esp
f0100a13:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a16:	8d 83 d2 d1 fe ff    	lea    -0x12e2e(%ebx),%eax
f0100a1c:	50                   	push   %eax
f0100a1d:	e8 35 27 00 00       	call   f0103157 <cprintf>
f0100a22:	83 c4 10             	add    $0x10,%esp
f0100a25:	e9 4f ff ff ff       	jmp    f0100979 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a2a:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a2f:	83 ec 04             	sub    $0x4,%esp
f0100a32:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a35:	ff 75 08             	pushl  0x8(%ebp)
f0100a38:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a3b:	52                   	push   %edx
f0100a3c:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a3f:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a46:	83 c4 10             	add    $0x10,%esp
f0100a49:	85 c0                	test   %eax,%eax
f0100a4b:	0f 89 28 ff ff ff    	jns    f0100979 <monitor+0x83>
				break;
	}
}
f0100a51:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a54:	5b                   	pop    %ebx
f0100a55:	5e                   	pop    %esi
f0100a56:	5f                   	pop    %edi
f0100a57:	5d                   	pop    %ebp
f0100a58:	c3                   	ret    

f0100a59 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a59:	55                   	push   %ebp
f0100a5a:	89 e5                	mov    %esp,%ebp
f0100a5c:	e8 5f 26 00 00       	call   f01030c0 <__x86.get_pc_thunk.dx>
f0100a61:	81 c2 a7 68 01 00    	add    $0x168a7,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a67:	83 ba 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%edx)
f0100a6e:	74 20                	je     f0100a90 <boot_alloc+0x37>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0)
f0100a70:	85 c0                	test   %eax,%eax
f0100a72:	74 36                	je     f0100aaa <boot_alloc+0x51>
		return nextfree;
	result = nextfree;
f0100a74:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
	nextfree += n;
	nextfree = ROUNDUP((char*)nextfree,PGSIZE);
f0100a7a:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100a81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a86:	89 82 90 1f 00 00    	mov    %eax,0x1f90(%edx)
	return result;
}
f0100a8c:	89 c8                	mov    %ecx,%eax
f0100a8e:	5d                   	pop    %ebp
f0100a8f:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a90:	c7 c1 c0 96 11 f0    	mov    $0xf01196c0,%ecx
f0100a96:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100a9c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100aa2:	89 8a 90 1f 00 00    	mov    %ecx,0x1f90(%edx)
f0100aa8:	eb c6                	jmp    f0100a70 <boot_alloc+0x17>
		return nextfree;
f0100aaa:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
f0100ab0:	eb da                	jmp    f0100a8c <boot_alloc+0x33>

f0100ab2 <nvram_read>:
{
f0100ab2:	55                   	push   %ebp
f0100ab3:	89 e5                	mov    %esp,%ebp
f0100ab5:	57                   	push   %edi
f0100ab6:	56                   	push   %esi
f0100ab7:	53                   	push   %ebx
f0100ab8:	83 ec 18             	sub    $0x18,%esp
f0100abb:	e8 8f f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100ac0:	81 c3 48 68 01 00    	add    $0x16848,%ebx
f0100ac6:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ac8:	50                   	push   %eax
f0100ac9:	e8 02 26 00 00       	call   f01030d0 <mc146818_read>
f0100ace:	89 c6                	mov    %eax,%esi
f0100ad0:	83 c7 01             	add    $0x1,%edi
f0100ad3:	89 3c 24             	mov    %edi,(%esp)
f0100ad6:	e8 f5 25 00 00       	call   f01030d0 <mc146818_read>
f0100adb:	c1 e0 08             	shl    $0x8,%eax
f0100ade:	09 f0                	or     %esi,%eax
}
f0100ae0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ae3:	5b                   	pop    %ebx
f0100ae4:	5e                   	pop    %esi
f0100ae5:	5f                   	pop    %edi
f0100ae6:	5d                   	pop    %ebp
f0100ae7:	c3                   	ret    

f0100ae8 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ae8:	55                   	push   %ebp
f0100ae9:	89 e5                	mov    %esp,%ebp
f0100aeb:	56                   	push   %esi
f0100aec:	53                   	push   %ebx
f0100aed:	e8 d2 25 00 00       	call   f01030c4 <__x86.get_pc_thunk.cx>
f0100af2:	81 c1 16 68 01 00    	add    $0x16816,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100af8:	89 d3                	mov    %edx,%ebx
f0100afa:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100afd:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b00:	a8 01                	test   $0x1,%al
f0100b02:	74 5a                	je     f0100b5e <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b04:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b09:	89 c6                	mov    %eax,%esi
f0100b0b:	c1 ee 0c             	shr    $0xc,%esi
f0100b0e:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100b14:	3b 33                	cmp    (%ebx),%esi
f0100b16:	73 2b                	jae    f0100b43 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b18:	c1 ea 0c             	shr    $0xc,%edx
f0100b1b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b21:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b28:	89 c2                	mov    %eax,%edx
f0100b2a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b2d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b32:	85 d2                	test   %edx,%edx
f0100b34:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b39:	0f 44 c2             	cmove  %edx,%eax
}
f0100b3c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b3f:	5b                   	pop    %ebx
f0100b40:	5e                   	pop    %esi
f0100b41:	5d                   	pop    %ebp
f0100b42:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b43:	50                   	push   %eax
f0100b44:	8d 81 40 d3 fe ff    	lea    -0x12cc0(%ecx),%eax
f0100b4a:	50                   	push   %eax
f0100b4b:	68 eb 02 00 00       	push   $0x2eb
f0100b50:	8d 81 b8 da fe ff    	lea    -0x12548(%ecx),%eax
f0100b56:	50                   	push   %eax
f0100b57:	89 cb                	mov    %ecx,%ebx
f0100b59:	e8 3b f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100b5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b63:	eb d7                	jmp    f0100b3c <check_va2pa+0x54>

f0100b65 <check_page_free_list>:
{
f0100b65:	55                   	push   %ebp
f0100b66:	89 e5                	mov    %esp,%ebp
f0100b68:	57                   	push   %edi
f0100b69:	56                   	push   %esi
f0100b6a:	53                   	push   %ebx
f0100b6b:	83 ec 3c             	sub    $0x3c,%esp
f0100b6e:	e8 59 25 00 00       	call   f01030cc <__x86.get_pc_thunk.di>
f0100b73:	81 c7 95 67 01 00    	add    $0x16795,%edi
f0100b79:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b7c:	84 c0                	test   %al,%al
f0100b7e:	0f 85 dd 02 00 00    	jne    f0100e61 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100b84:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100b87:	83 b8 94 1f 00 00 00 	cmpl   $0x0,0x1f94(%eax)
f0100b8e:	74 0c                	je     f0100b9c <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b90:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100b97:	e9 2f 03 00 00       	jmp    f0100ecb <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100b9c:	83 ec 04             	sub    $0x4,%esp
f0100b9f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ba2:	8d 83 64 d3 fe ff    	lea    -0x12c9c(%ebx),%eax
f0100ba8:	50                   	push   %eax
f0100ba9:	68 2c 02 00 00       	push   $0x22c
f0100bae:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100bb4:	50                   	push   %eax
f0100bb5:	e8 df f4 ff ff       	call   f0100099 <_panic>
f0100bba:	50                   	push   %eax
f0100bbb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bbe:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0100bc4:	50                   	push   %eax
f0100bc5:	6a 52                	push   $0x52
f0100bc7:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0100bcd:	50                   	push   %eax
f0100bce:	e8 c6 f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd3:	8b 36                	mov    (%esi),%esi
f0100bd5:	85 f6                	test   %esi,%esi
f0100bd7:	74 40                	je     f0100c19 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bd9:	89 f0                	mov    %esi,%eax
f0100bdb:	2b 07                	sub    (%edi),%eax
f0100bdd:	c1 f8 03             	sar    $0x3,%eax
f0100be0:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100be3:	89 c2                	mov    %eax,%edx
f0100be5:	c1 ea 16             	shr    $0x16,%edx
f0100be8:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100beb:	73 e6                	jae    f0100bd3 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100bed:	89 c2                	mov    %eax,%edx
f0100bef:	c1 ea 0c             	shr    $0xc,%edx
f0100bf2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100bf5:	3b 11                	cmp    (%ecx),%edx
f0100bf7:	73 c1                	jae    f0100bba <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100bf9:	83 ec 04             	sub    $0x4,%esp
f0100bfc:	68 80 00 00 00       	push   $0x80
f0100c01:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c0b:	50                   	push   %eax
f0100c0c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c0f:	e8 49 31 00 00       	call   f0103d5d <memset>
f0100c14:	83 c4 10             	add    $0x10,%esp
f0100c17:	eb ba                	jmp    f0100bd3 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c1e:	e8 36 fe ff ff       	call   f0100a59 <boot_alloc>
f0100c23:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c26:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c29:	8b 97 94 1f 00 00    	mov    0x1f94(%edi),%edx
		assert(pp >= pages);
f0100c2f:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100c35:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c37:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100c3d:	8b 00                	mov    (%eax),%eax
f0100c3f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c42:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c45:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c48:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c4d:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c50:	e9 08 01 00 00       	jmp    f0100d5d <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c55:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c58:	8d 83 d2 da fe ff    	lea    -0x1252e(%ebx),%eax
f0100c5e:	50                   	push   %eax
f0100c5f:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100c65:	50                   	push   %eax
f0100c66:	68 46 02 00 00       	push   $0x246
f0100c6b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100c71:	50                   	push   %eax
f0100c72:	e8 22 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c77:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c7a:	8d 83 f3 da fe ff    	lea    -0x1250d(%ebx),%eax
f0100c80:	50                   	push   %eax
f0100c81:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100c87:	50                   	push   %eax
f0100c88:	68 47 02 00 00       	push   $0x247
f0100c8d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100c93:	50                   	push   %eax
f0100c94:	e8 00 f4 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c99:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c9c:	8d 83 88 d3 fe ff    	lea    -0x12c78(%ebx),%eax
f0100ca2:	50                   	push   %eax
f0100ca3:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100ca9:	50                   	push   %eax
f0100caa:	68 48 02 00 00       	push   $0x248
f0100caf:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100cb5:	50                   	push   %eax
f0100cb6:	e8 de f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cbb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cbe:	8d 83 07 db fe ff    	lea    -0x124f9(%ebx),%eax
f0100cc4:	50                   	push   %eax
f0100cc5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100ccb:	50                   	push   %eax
f0100ccc:	68 4b 02 00 00       	push   $0x24b
f0100cd1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100cd7:	50                   	push   %eax
f0100cd8:	e8 bc f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cdd:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ce0:	8d 83 18 db fe ff    	lea    -0x124e8(%ebx),%eax
f0100ce6:	50                   	push   %eax
f0100ce7:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100ced:	50                   	push   %eax
f0100cee:	68 4c 02 00 00       	push   $0x24c
f0100cf3:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100cf9:	50                   	push   %eax
f0100cfa:	e8 9a f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cff:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d02:	8d 83 bc d3 fe ff    	lea    -0x12c44(%ebx),%eax
f0100d08:	50                   	push   %eax
f0100d09:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100d0f:	50                   	push   %eax
f0100d10:	68 4d 02 00 00       	push   $0x24d
f0100d15:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100d1b:	50                   	push   %eax
f0100d1c:	e8 78 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d21:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d24:	8d 83 31 db fe ff    	lea    -0x124cf(%ebx),%eax
f0100d2a:	50                   	push   %eax
f0100d2b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100d31:	50                   	push   %eax
f0100d32:	68 4e 02 00 00       	push   $0x24e
f0100d37:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100d3d:	50                   	push   %eax
f0100d3e:	e8 56 f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d43:	89 c6                	mov    %eax,%esi
f0100d45:	c1 ee 0c             	shr    $0xc,%esi
f0100d48:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d4b:	76 70                	jbe    f0100dbd <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d4d:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d52:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d55:	77 7f                	ja     f0100dd6 <check_page_free_list+0x271>
			++nfree_extmem;
f0100d57:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d5b:	8b 12                	mov    (%edx),%edx
f0100d5d:	85 d2                	test   %edx,%edx
f0100d5f:	0f 84 93 00 00 00    	je     f0100df8 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d65:	39 d1                	cmp    %edx,%ecx
f0100d67:	0f 87 e8 fe ff ff    	ja     f0100c55 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100d6d:	39 d3                	cmp    %edx,%ebx
f0100d6f:	0f 86 02 ff ff ff    	jbe    f0100c77 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d75:	89 d0                	mov    %edx,%eax
f0100d77:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d7a:	a8 07                	test   $0x7,%al
f0100d7c:	0f 85 17 ff ff ff    	jne    f0100c99 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100d82:	c1 f8 03             	sar    $0x3,%eax
f0100d85:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100d88:	85 c0                	test   %eax,%eax
f0100d8a:	0f 84 2b ff ff ff    	je     f0100cbb <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d90:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d95:	0f 84 42 ff ff ff    	je     f0100cdd <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d9b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100da0:	0f 84 59 ff ff ff    	je     f0100cff <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100da6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dab:	0f 84 70 ff ff ff    	je     f0100d21 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100db1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100db6:	77 8b                	ja     f0100d43 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100db8:	83 c7 01             	add    $0x1,%edi
f0100dbb:	eb 9e                	jmp    f0100d5b <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dbd:	50                   	push   %eax
f0100dbe:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dc1:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0100dc7:	50                   	push   %eax
f0100dc8:	6a 52                	push   $0x52
f0100dca:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0100dd0:	50                   	push   %eax
f0100dd1:	e8 c3 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dd6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dd9:	8d 83 e0 d3 fe ff    	lea    -0x12c20(%ebx),%eax
f0100ddf:	50                   	push   %eax
f0100de0:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100de6:	50                   	push   %eax
f0100de7:	68 4f 02 00 00       	push   $0x24f
f0100dec:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100df2:	50                   	push   %eax
f0100df3:	e8 a1 f2 ff ff       	call   f0100099 <_panic>
f0100df8:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100dfb:	85 ff                	test   %edi,%edi
f0100dfd:	7e 1e                	jle    f0100e1d <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100dff:	85 f6                	test   %esi,%esi
f0100e01:	7e 3c                	jle    f0100e3f <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e03:	83 ec 0c             	sub    $0xc,%esp
f0100e06:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e09:	8d 83 28 d4 fe ff    	lea    -0x12bd8(%ebx),%eax
f0100e0f:	50                   	push   %eax
f0100e10:	e8 42 23 00 00       	call   f0103157 <cprintf>
}
f0100e15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e18:	5b                   	pop    %ebx
f0100e19:	5e                   	pop    %esi
f0100e1a:	5f                   	pop    %edi
f0100e1b:	5d                   	pop    %ebp
f0100e1c:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e1d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e20:	8d 83 4b db fe ff    	lea    -0x124b5(%ebx),%eax
f0100e26:	50                   	push   %eax
f0100e27:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100e2d:	50                   	push   %eax
f0100e2e:	68 57 02 00 00       	push   $0x257
f0100e33:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100e39:	50                   	push   %eax
f0100e3a:	e8 5a f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e3f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e42:	8d 83 5d db fe ff    	lea    -0x124a3(%ebx),%eax
f0100e48:	50                   	push   %eax
f0100e49:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0100e4f:	50                   	push   %eax
f0100e50:	68 58 02 00 00       	push   $0x258
f0100e55:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0100e5b:	50                   	push   %eax
f0100e5c:	e8 38 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e61:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e64:	8b 80 94 1f 00 00    	mov    0x1f94(%eax),%eax
f0100e6a:	85 c0                	test   %eax,%eax
f0100e6c:	0f 84 2a fd ff ff    	je     f0100b9c <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e72:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e75:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e78:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e7b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e7e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e81:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100e87:	89 c2                	mov    %eax,%edx
f0100e89:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e8b:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e91:	0f 95 c2             	setne  %dl
f0100e94:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e97:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e9b:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e9d:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ea1:	8b 00                	mov    (%eax),%eax
f0100ea3:	85 c0                	test   %eax,%eax
f0100ea5:	75 e0                	jne    f0100e87 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100ea7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eaa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100eb0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100eb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eb6:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100eb8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ebb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ebe:	89 87 94 1f 00 00    	mov    %eax,0x1f94(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ec4:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ecb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ece:	8b b0 94 1f 00 00    	mov    0x1f94(%eax),%esi
f0100ed4:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100eda:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100ee0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ee3:	e9 ed fc ff ff       	jmp    f0100bd5 <check_page_free_list+0x70>

f0100ee8 <page_init>:
{
f0100ee8:	55                   	push   %ebp
f0100ee9:	89 e5                	mov    %esp,%ebp
f0100eeb:	57                   	push   %edi
f0100eec:	56                   	push   %esi
f0100eed:	53                   	push   %ebx
f0100eee:	83 ec 08             	sub    $0x8,%esp
f0100ef1:	e8 d2 21 00 00       	call   f01030c8 <__x86.get_pc_thunk.si>
f0100ef6:	81 c6 12 64 01 00    	add    $0x16412,%esi
	for (i = 0; i < npages; i++) {
f0100efc:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f01:	c7 c7 c8 96 11 f0    	mov    $0xf01196c8,%edi
			pages[i].pp_ref = 0;
f0100f07:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < npages; i++) {
f0100f10:	eb 38                	jmp    f0100f4a <page_init+0x62>
		else if(i>=1 && i<npages_basemem)
f0100f12:	39 9e 98 1f 00 00    	cmp    %ebx,0x1f98(%esi)
f0100f18:	76 52                	jbe    f0100f6c <page_init+0x84>
f0100f1a:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
			pages[i].pp_ref = 0;
f0100f21:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f27:	89 ca                	mov    %ecx,%edx
f0100f29:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100f2c:	03 10                	add    (%eax),%edx
f0100f2e:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list; 
f0100f34:	8b 86 94 1f 00 00    	mov    0x1f94(%esi),%eax
f0100f3a:	89 02                	mov    %eax,(%edx)
			page_free_list = &pages[i];
f0100f3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f3f:	03 08                	add    (%eax),%ecx
f0100f41:	89 8e 94 1f 00 00    	mov    %ecx,0x1f94(%esi)
	for (i = 0; i < npages; i++) {
f0100f47:	83 c3 01             	add    $0x1,%ebx
f0100f4a:	39 1f                	cmp    %ebx,(%edi)
f0100f4c:	0f 86 a1 00 00 00    	jbe    f0100ff3 <page_init+0x10b>
		if(i == 0)
f0100f52:	85 db                	test   %ebx,%ebx
f0100f54:	75 bc                	jne    f0100f12 <page_init+0x2a>
			pages[i].pp_ref = 1;
f0100f56:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f5c:	8b 00                	mov    (%eax),%eax
f0100f5e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f6a:	eb db                	jmp    f0100f47 <page_init+0x5f>
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE )
f0100f6c:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100f72:	83 f8 5f             	cmp    $0x5f,%eax
f0100f75:	77 19                	ja     f0100f90 <page_init+0xa8>
			pages[i].pp_ref = 1;
f0100f77:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f7d:	8b 00                	mov    (%eax),%eax
f0100f7f:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100f82:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f8e:	eb b7                	jmp    f0100f47 <page_init+0x5f>
		else if(i>=EXTPHYSMEM/PGSIZE && i<((int)(boot_alloc(0))-KERNBASE)/PGSIZE)
f0100f90:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100f96:	77 29                	ja     f0100fc1 <page_init+0xd9>
f0100f98:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0100f9f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100fa2:	89 c2                	mov    %eax,%edx
f0100fa4:	03 11                	add    (%ecx),%edx
f0100fa6:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100fac:	8b 8e 94 1f 00 00    	mov    0x1f94(%esi),%ecx
f0100fb2:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100fb4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100fb7:	03 01                	add    (%ecx),%eax
f0100fb9:	89 86 94 1f 00 00    	mov    %eax,0x1f94(%esi)
f0100fbf:	eb 86                	jmp    f0100f47 <page_init+0x5f>
		else if(i>=EXTPHYSMEM/PGSIZE && i<((int)(boot_alloc(0))-KERNBASE)/PGSIZE)
f0100fc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc6:	e8 8e fa ff ff       	call   f0100a59 <boot_alloc>
f0100fcb:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fd0:	c1 e8 0c             	shr    $0xc,%eax
f0100fd3:	39 d8                	cmp    %ebx,%eax
f0100fd5:	76 c1                	jbe    f0100f98 <page_init+0xb0>
			pages[i].pp_ref = 1;
f0100fd7:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100fdd:	8b 00                	mov    (%eax),%eax
f0100fdf:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100fe2:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link =NULL;
f0100fe8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fee:	e9 54 ff ff ff       	jmp    f0100f47 <page_init+0x5f>
}
f0100ff3:	83 c4 08             	add    $0x8,%esp
f0100ff6:	5b                   	pop    %ebx
f0100ff7:	5e                   	pop    %esi
f0100ff8:	5f                   	pop    %edi
f0100ff9:	5d                   	pop    %ebp
f0100ffa:	c3                   	ret    

f0100ffb <page_alloc>:
{
f0100ffb:	55                   	push   %ebp
f0100ffc:	89 e5                	mov    %esp,%ebp
f0100ffe:	56                   	push   %esi
f0100fff:	53                   	push   %ebx
f0101000:	e8 4a f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101005:	81 c3 03 63 01 00    	add    $0x16303,%ebx
	if(page_free_list == NULL)
f010100b:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0101011:	85 f6                	test   %esi,%esi
f0101013:	74 14                	je     f0101029 <page_alloc+0x2e>
	page_free_list = page->pp_link;
f0101015:	8b 06                	mov    (%esi),%eax
f0101017:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page->pp_link = 0;
f010101d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(alloc_flags & ALLOC_ZERO)
f0101023:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101027:	75 09                	jne    f0101032 <page_alloc+0x37>
}
f0101029:	89 f0                	mov    %esi,%eax
f010102b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010102e:	5b                   	pop    %ebx
f010102f:	5e                   	pop    %esi
f0101030:	5d                   	pop    %ebp
f0101031:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101032:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101038:	89 f2                	mov    %esi,%edx
f010103a:	2b 10                	sub    (%eax),%edx
f010103c:	89 d0                	mov    %edx,%eax
f010103e:	c1 f8 03             	sar    $0x3,%eax
f0101041:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101044:	89 c1                	mov    %eax,%ecx
f0101046:	c1 e9 0c             	shr    $0xc,%ecx
f0101049:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010104f:	3b 0a                	cmp    (%edx),%ecx
f0101051:	73 1a                	jae    f010106d <page_alloc+0x72>
		memset(page2kva(page), 0, PGSIZE);
f0101053:	83 ec 04             	sub    $0x4,%esp
f0101056:	68 00 10 00 00       	push   $0x1000
f010105b:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010105d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101062:	50                   	push   %eax
f0101063:	e8 f5 2c 00 00       	call   f0103d5d <memset>
f0101068:	83 c4 10             	add    $0x10,%esp
f010106b:	eb bc                	jmp    f0101029 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010106d:	50                   	push   %eax
f010106e:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0101074:	50                   	push   %eax
f0101075:	6a 52                	push   $0x52
f0101077:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f010107d:	50                   	push   %eax
f010107e:	e8 16 f0 ff ff       	call   f0100099 <_panic>

f0101083 <page_free>:
{
f0101083:	55                   	push   %ebp
f0101084:	89 e5                	mov    %esp,%ebp
f0101086:	53                   	push   %ebx
f0101087:	83 ec 04             	sub    $0x4,%esp
f010108a:	e8 c0 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010108f:	81 c3 79 62 01 00    	add    $0x16279,%ebx
f0101095:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_link != 0  || pp->pp_ref != 0)
f0101098:	83 38 00             	cmpl   $0x0,(%eax)
f010109b:	75 1a                	jne    f01010b7 <page_free+0x34>
f010109d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010a2:	75 13                	jne    f01010b7 <page_free+0x34>
	pp->pp_link = page_free_list;
f01010a4:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f01010aa:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010ac:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f01010b2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010b5:	c9                   	leave  
f01010b6:	c3                   	ret    
		panic("page_free is not right");
f01010b7:	83 ec 04             	sub    $0x4,%esp
f01010ba:	8d 83 6e db fe ff    	lea    -0x12492(%ebx),%eax
f01010c0:	50                   	push   %eax
f01010c1:	68 53 01 00 00       	push   $0x153
f01010c6:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01010cc:	50                   	push   %eax
f01010cd:	e8 c7 ef ff ff       	call   f0100099 <_panic>

f01010d2 <page_decref>:
{
f01010d2:	55                   	push   %ebp
f01010d3:	89 e5                	mov    %esp,%ebp
f01010d5:	83 ec 08             	sub    $0x8,%esp
f01010d8:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01010db:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010df:	83 e8 01             	sub    $0x1,%eax
f01010e2:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010e6:	66 85 c0             	test   %ax,%ax
f01010e9:	74 02                	je     f01010ed <page_decref+0x1b>
}
f01010eb:	c9                   	leave  
f01010ec:	c3                   	ret    
		page_free(pp);
f01010ed:	83 ec 0c             	sub    $0xc,%esp
f01010f0:	52                   	push   %edx
f01010f1:	e8 8d ff ff ff       	call   f0101083 <page_free>
f01010f6:	83 c4 10             	add    $0x10,%esp
}
f01010f9:	eb f0                	jmp    f01010eb <page_decref+0x19>

f01010fb <pgdir_walk>:
{
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
f01010fe:	57                   	push   %edi
f01010ff:	56                   	push   %esi
f0101100:	53                   	push   %ebx
f0101101:	83 ec 0c             	sub    $0xc,%esp
f0101104:	e8 46 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101109:	81 c3 ff 61 01 00    	add    $0x161ff,%ebx
f010110f:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdeIndex = (unsigned int)va >>22;
f0101112:	89 f7                	mov    %esi,%edi
f0101114:	c1 ef 16             	shr    $0x16,%edi
	if(pgdir[pdeIndex] == 0 && create == 0)
f0101117:	c1 e7 02             	shl    $0x2,%edi
f010111a:	03 7d 08             	add    0x8(%ebp),%edi
f010111d:	8b 07                	mov    (%edi),%eax
f010111f:	89 c2                	mov    %eax,%edx
f0101121:	0b 55 10             	or     0x10(%ebp),%edx
f0101124:	74 76                	je     f010119c <pgdir_walk+0xa1>
	if(pgdir[pdeIndex] == 0){
f0101126:	85 c0                	test   %eax,%eax
f0101128:	74 2e                	je     f0101158 <pgdir_walk+0x5d>
	pte_t pgAdd = pgdir[pdeIndex];
f010112a:	8b 07                	mov    (%edi),%eax
	int pteIndex =(pte_t)va >>12 & 0x3ff;
f010112c:	c1 ee 0a             	shr    $0xa,%esi
	pte_t * pte =(pte_t*) pgAdd + pteIndex;
f010112f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	pgAdd = pgAdd>>12<<12;
f0101135:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	pte_t * pte =(pte_t*) pgAdd + pteIndex;
f010113a:	01 f0                	add    %esi,%eax
	if (PGNUM(pa) >= npages)
f010113c:	89 c1                	mov    %eax,%ecx
f010113e:	c1 e9 0c             	shr    $0xc,%ecx
f0101141:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101147:	3b 0a                	cmp    (%edx),%ecx
f0101149:	73 38                	jae    f0101183 <pgdir_walk+0x88>
	return (void *)(pa + KERNBASE);
f010114b:	2d 00 00 00 10       	sub    $0x10000000,%eax
}
f0101150:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101153:	5b                   	pop    %ebx
f0101154:	5e                   	pop    %esi
f0101155:	5f                   	pop    %edi
f0101156:	5d                   	pop    %ebp
f0101157:	c3                   	ret    
		struct PageInfo* page = page_alloc(1);
f0101158:	83 ec 0c             	sub    $0xc,%esp
f010115b:	6a 01                	push   $0x1
f010115d:	e8 99 fe ff ff       	call   f0100ffb <page_alloc>
		if(page == NULL)
f0101162:	83 c4 10             	add    $0x10,%esp
f0101165:	85 c0                	test   %eax,%eax
f0101167:	74 3a                	je     f01011a3 <pgdir_walk+0xa8>
		page->pp_ref++;
f0101169:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010116e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101174:	2b 02                	sub    (%edx),%eax
f0101176:	c1 f8 03             	sar    $0x3,%eax
f0101179:	c1 e0 0c             	shl    $0xc,%eax
		pgAddress |= PTE_W;
f010117c:	83 c8 07             	or     $0x7,%eax
f010117f:	89 07                	mov    %eax,(%edi)
f0101181:	eb a7                	jmp    f010112a <pgdir_walk+0x2f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101183:	50                   	push   %eax
f0101184:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f010118a:	50                   	push   %eax
f010118b:	68 90 01 00 00       	push   $0x190
f0101190:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101196:	50                   	push   %eax
f0101197:	e8 fd ee ff ff       	call   f0100099 <_panic>
		return NULL;
f010119c:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a1:	eb ad                	jmp    f0101150 <pgdir_walk+0x55>
			return NULL;
f01011a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a8:	eb a6                	jmp    f0101150 <pgdir_walk+0x55>

f01011aa <page_lookup>:
{
f01011aa:	55                   	push   %ebp
f01011ab:	89 e5                	mov    %esp,%ebp
f01011ad:	56                   	push   %esi
f01011ae:	53                   	push   %ebx
f01011af:	e8 9b ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01011b4:	81 c3 54 61 01 00    	add    $0x16154,%ebx
f01011ba:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t* pte = pgdir_walk(pgdir, va, 0);
f01011bd:	83 ec 04             	sub    $0x4,%esp
f01011c0:	6a 00                	push   $0x0
f01011c2:	ff 75 0c             	pushl  0xc(%ebp)
f01011c5:	ff 75 08             	pushl  0x8(%ebp)
f01011c8:	e8 2e ff ff ff       	call   f01010fb <pgdir_walk>
	if(pte == NULL)
f01011cd:	83 c4 10             	add    $0x10,%esp
f01011d0:	85 c0                	test   %eax,%eax
f01011d2:	74 41                	je     f0101215 <page_lookup+0x6b>
	pte_t pa =  *pte>>12<<12;
f01011d4:	8b 10                	mov    (%eax),%edx
	if(pte_store != 0)
f01011d6:	85 f6                	test   %esi,%esi
f01011d8:	74 02                	je     f01011dc <page_lookup+0x32>
		*pte_store = pte ;
f01011da:	89 06                	mov    %eax,(%esi)
f01011dc:	89 d0                	mov    %edx,%eax
f01011de:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011e1:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01011e7:	39 02                	cmp    %eax,(%edx)
f01011e9:	76 12                	jbe    f01011fd <page_lookup+0x53>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011eb:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f01011f1:	8b 12                	mov    (%edx),%edx
f01011f3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01011f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011f9:	5b                   	pop    %ebx
f01011fa:	5e                   	pop    %esi
f01011fb:	5d                   	pop    %ebp
f01011fc:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011fd:	83 ec 04             	sub    $0x4,%esp
f0101200:	8d 83 4c d4 fe ff    	lea    -0x12bb4(%ebx),%eax
f0101206:	50                   	push   %eax
f0101207:	6a 4b                	push   $0x4b
f0101209:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f010120f:	50                   	push   %eax
f0101210:	e8 84 ee ff ff       	call   f0100099 <_panic>
		return NULL;
f0101215:	b8 00 00 00 00       	mov    $0x0,%eax
f010121a:	eb da                	jmp    f01011f6 <page_lookup+0x4c>

f010121c <page_remove>:
{
f010121c:	55                   	push   %ebp
f010121d:	89 e5                	mov    %esp,%ebp
f010121f:	53                   	push   %ebx
f0101220:	83 ec 18             	sub    $0x18,%esp
f0101223:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo* page = page_lookup(pgdir, va, &pte);
f0101226:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101229:	50                   	push   %eax
f010122a:	53                   	push   %ebx
f010122b:	ff 75 08             	pushl  0x8(%ebp)
f010122e:	e8 77 ff ff ff       	call   f01011aa <page_lookup>
	if(page == 0)
f0101233:	83 c4 10             	add    $0x10,%esp
f0101236:	85 c0                	test   %eax,%eax
f0101238:	74 1c                	je     f0101256 <page_remove+0x3a>
	*pte = 0;
f010123a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010123d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	page->pp_ref--;
f0101243:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101247:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010124a:	66 89 50 04          	mov    %dx,0x4(%eax)
	if(page->pp_ref ==0)
f010124e:	66 85 d2             	test   %dx,%dx
f0101251:	74 08                	je     f010125b <page_remove+0x3f>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101253:	0f 01 3b             	invlpg (%ebx)
}
f0101256:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101259:	c9                   	leave  
f010125a:	c3                   	ret    
		page_free(page);
f010125b:	83 ec 0c             	sub    $0xc,%esp
f010125e:	50                   	push   %eax
f010125f:	e8 1f fe ff ff       	call   f0101083 <page_free>
f0101264:	83 c4 10             	add    $0x10,%esp
f0101267:	eb ea                	jmp    f0101253 <page_remove+0x37>

f0101269 <page_insert>:
{
f0101269:	55                   	push   %ebp
f010126a:	89 e5                	mov    %esp,%ebp
f010126c:	57                   	push   %edi
f010126d:	56                   	push   %esi
f010126e:	53                   	push   %ebx
f010126f:	83 ec 20             	sub    $0x20,%esp
f0101272:	e8 55 1e 00 00       	call   f01030cc <__x86.get_pc_thunk.di>
f0101277:	81 c7 91 60 01 00    	add    $0x16091,%edi
f010127d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = pgdir_walk(pgdir, va, 1);
f0101280:	6a 01                	push   $0x1
f0101282:	ff 75 10             	pushl  0x10(%ebp)
f0101285:	ff 75 08             	pushl  0x8(%ebp)
f0101288:	e8 6e fe ff ff       	call   f01010fb <pgdir_walk>
	if(pte == NULL)
f010128d:	83 c4 10             	add    $0x10,%esp
f0101290:	85 c0                	test   %eax,%eax
f0101292:	74 72                	je     f0101306 <page_insert+0x9d>
f0101294:	89 c6                	mov    %eax,%esi
	if( (pte[0] &  ~0xfff) == page2pa(pp))
f0101296:	8b 10                	mov    (%eax),%edx
f0101298:	89 d1                	mov    %edx,%ecx
f010129a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01012a0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f01012a3:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01012a9:	89 d9                	mov    %ebx,%ecx
f01012ab:	2b 08                	sub    (%eax),%ecx
f01012ad:	89 c8                	mov    %ecx,%eax
f01012af:	c1 f8 03             	sar    $0x3,%eax
f01012b2:	c1 e0 0c             	shl    $0xc,%eax
f01012b5:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01012b8:	74 32                	je     f01012ec <page_insert+0x83>
	else if(*pte != 0)
f01012ba:	85 d2                	test   %edx,%edx
f01012bc:	75 35                	jne    f01012f3 <page_insert+0x8a>
f01012be:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01012c4:	89 df                	mov    %ebx,%edi
f01012c6:	2b 38                	sub    (%eax),%edi
f01012c8:	89 f8                	mov    %edi,%eax
f01012ca:	c1 f8 03             	sar    $0x3,%eax
f01012cd:	c1 e0 0c             	shl    $0xc,%eax
	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;
f01012d0:	8b 55 14             	mov    0x14(%ebp),%edx
f01012d3:	83 ca 01             	or     $0x1,%edx
f01012d6:	09 d0                	or     %edx,%eax
f01012d8:	89 06                	mov    %eax,(%esi)
	pp->pp_ref++;
f01012da:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01012df:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e7:	5b                   	pop    %ebx
f01012e8:	5e                   	pop    %esi
f01012e9:	5f                   	pop    %edi
f01012ea:	5d                   	pop    %ebp
f01012eb:	c3                   	ret    
		pp->pp_ref--;
f01012ec:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f01012f1:	eb cb                	jmp    f01012be <page_insert+0x55>
		page_remove(pgdir, va);
f01012f3:	83 ec 08             	sub    $0x8,%esp
f01012f6:	ff 75 10             	pushl  0x10(%ebp)
f01012f9:	ff 75 08             	pushl  0x8(%ebp)
f01012fc:	e8 1b ff ff ff       	call   f010121c <page_remove>
f0101301:	83 c4 10             	add    $0x10,%esp
f0101304:	eb b8                	jmp    f01012be <page_insert+0x55>
		return -E_NO_MEM;
f0101306:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010130b:	eb d7                	jmp    f01012e4 <page_insert+0x7b>

f010130d <mem_init>:
{
f010130d:	55                   	push   %ebp
f010130e:	89 e5                	mov    %esp,%ebp
f0101310:	57                   	push   %edi
f0101311:	56                   	push   %esi
f0101312:	53                   	push   %ebx
f0101313:	83 ec 3c             	sub    $0x3c,%esp
f0101316:	e8 d6 f3 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010131b:	05 ed 5f 01 00       	add    $0x15fed,%eax
f0101320:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101323:	b8 15 00 00 00       	mov    $0x15,%eax
f0101328:	e8 85 f7 ff ff       	call   f0100ab2 <nvram_read>
f010132d:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010132f:	b8 17 00 00 00       	mov    $0x17,%eax
f0101334:	e8 79 f7 ff ff       	call   f0100ab2 <nvram_read>
f0101339:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010133b:	b8 34 00 00 00       	mov    $0x34,%eax
f0101340:	e8 6d f7 ff ff       	call   f0100ab2 <nvram_read>
f0101345:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101348:	85 c0                	test   %eax,%eax
f010134a:	0f 85 cd 00 00 00    	jne    f010141d <mem_init+0x110>
		totalmem = 1 * 1024 + extmem;
f0101350:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101356:	85 f6                	test   %esi,%esi
f0101358:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f010135b:	89 c1                	mov    %eax,%ecx
f010135d:	c1 e9 02             	shr    $0x2,%ecx
f0101360:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101363:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101369:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f010136b:	89 da                	mov    %ebx,%edx
f010136d:	c1 ea 02             	shr    $0x2,%edx
f0101370:	89 97 98 1f 00 00    	mov    %edx,0x1f98(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101376:	89 c2                	mov    %eax,%edx
f0101378:	29 da                	sub    %ebx,%edx
f010137a:	52                   	push   %edx
f010137b:	53                   	push   %ebx
f010137c:	50                   	push   %eax
f010137d:	8d 87 6c d4 fe ff    	lea    -0x12b94(%edi),%eax
f0101383:	50                   	push   %eax
f0101384:	89 fb                	mov    %edi,%ebx
f0101386:	e8 cc 1d 00 00       	call   f0103157 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010138b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101390:	e8 c4 f6 ff ff       	call   f0100a59 <boot_alloc>
f0101395:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f010139b:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f010139d:	83 c4 0c             	add    $0xc,%esp
f01013a0:	68 00 10 00 00       	push   $0x1000
f01013a5:	6a 00                	push   $0x0
f01013a7:	50                   	push   %eax
f01013a8:	e8 b0 29 00 00       	call   f0103d5d <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013ad:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01013af:	83 c4 10             	add    $0x10,%esp
f01013b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013b7:	76 6e                	jbe    f0101427 <mem_init+0x11a>
	return (physaddr_t)kva - KERNBASE;
f01013b9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013bf:	83 ca 05             	or     $0x5,%edx
f01013c2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = boot_alloc(npages * sizeof (struct PageInfo));
f01013c8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013cb:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f01013d1:	8b 03                	mov    (%ebx),%eax
f01013d3:	c1 e0 03             	shl    $0x3,%eax
f01013d6:	e8 7e f6 ff ff       	call   f0100a59 <boot_alloc>
f01013db:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f01013e1:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01013e3:	83 ec 04             	sub    $0x4,%esp
f01013e6:	8b 13                	mov    (%ebx),%edx
f01013e8:	c1 e2 03             	shl    $0x3,%edx
f01013eb:	52                   	push   %edx
f01013ec:	6a 00                	push   $0x0
f01013ee:	50                   	push   %eax
f01013ef:	89 fb                	mov    %edi,%ebx
f01013f1:	e8 67 29 00 00       	call   f0103d5d <memset>
	page_init();
f01013f6:	e8 ed fa ff ff       	call   f0100ee8 <page_init>
	check_page_free_list(1);
f01013fb:	b8 01 00 00 00       	mov    $0x1,%eax
f0101400:	e8 60 f7 ff ff       	call   f0100b65 <check_page_free_list>
	if (!pages)
f0101405:	83 c4 10             	add    $0x10,%esp
f0101408:	83 3e 00             	cmpl   $0x0,(%esi)
f010140b:	74 36                	je     f0101443 <mem_init+0x136>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010140d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101410:	8b 80 94 1f 00 00    	mov    0x1f94(%eax),%eax
f0101416:	be 00 00 00 00       	mov    $0x0,%esi
f010141b:	eb 49                	jmp    f0101466 <mem_init+0x159>
		totalmem = 16 * 1024 + ext16mem;
f010141d:	05 00 40 00 00       	add    $0x4000,%eax
f0101422:	e9 34 ff ff ff       	jmp    f010135b <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101427:	50                   	push   %eax
f0101428:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010142b:	8d 83 a8 d4 fe ff    	lea    -0x12b58(%ebx),%eax
f0101431:	50                   	push   %eax
f0101432:	68 91 00 00 00       	push   $0x91
f0101437:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010143d:	50                   	push   %eax
f010143e:	e8 56 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101443:	83 ec 04             	sub    $0x4,%esp
f0101446:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101449:	8d 83 85 db fe ff    	lea    -0x1247b(%ebx),%eax
f010144f:	50                   	push   %eax
f0101450:	68 6b 02 00 00       	push   $0x26b
f0101455:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010145b:	50                   	push   %eax
f010145c:	e8 38 ec ff ff       	call   f0100099 <_panic>
		++nfree;
f0101461:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101464:	8b 00                	mov    (%eax),%eax
f0101466:	85 c0                	test   %eax,%eax
f0101468:	75 f7                	jne    f0101461 <mem_init+0x154>
	assert((pp0 = page_alloc(0)));
f010146a:	83 ec 0c             	sub    $0xc,%esp
f010146d:	6a 00                	push   $0x0
f010146f:	e8 87 fb ff ff       	call   f0100ffb <page_alloc>
f0101474:	89 c3                	mov    %eax,%ebx
f0101476:	83 c4 10             	add    $0x10,%esp
f0101479:	85 c0                	test   %eax,%eax
f010147b:	0f 84 3b 02 00 00    	je     f01016bc <mem_init+0x3af>
	assert((pp1 = page_alloc(0)));
f0101481:	83 ec 0c             	sub    $0xc,%esp
f0101484:	6a 00                	push   $0x0
f0101486:	e8 70 fb ff ff       	call   f0100ffb <page_alloc>
f010148b:	89 c7                	mov    %eax,%edi
f010148d:	83 c4 10             	add    $0x10,%esp
f0101490:	85 c0                	test   %eax,%eax
f0101492:	0f 84 46 02 00 00    	je     f01016de <mem_init+0x3d1>
	assert((pp2 = page_alloc(0)));
f0101498:	83 ec 0c             	sub    $0xc,%esp
f010149b:	6a 00                	push   $0x0
f010149d:	e8 59 fb ff ff       	call   f0100ffb <page_alloc>
f01014a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014a5:	83 c4 10             	add    $0x10,%esp
f01014a8:	85 c0                	test   %eax,%eax
f01014aa:	0f 84 50 02 00 00    	je     f0101700 <mem_init+0x3f3>
	assert(pp1 && pp1 != pp0);
f01014b0:	39 fb                	cmp    %edi,%ebx
f01014b2:	0f 84 6a 02 00 00    	je     f0101722 <mem_init+0x415>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014b8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014bb:	39 c7                	cmp    %eax,%edi
f01014bd:	0f 84 81 02 00 00    	je     f0101744 <mem_init+0x437>
f01014c3:	39 c3                	cmp    %eax,%ebx
f01014c5:	0f 84 79 02 00 00    	je     f0101744 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f01014cb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01014ce:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01014d4:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014d6:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01014dc:	8b 10                	mov    (%eax),%edx
f01014de:	c1 e2 0c             	shl    $0xc,%edx
f01014e1:	89 d8                	mov    %ebx,%eax
f01014e3:	29 c8                	sub    %ecx,%eax
f01014e5:	c1 f8 03             	sar    $0x3,%eax
f01014e8:	c1 e0 0c             	shl    $0xc,%eax
f01014eb:	39 d0                	cmp    %edx,%eax
f01014ed:	0f 83 73 02 00 00    	jae    f0101766 <mem_init+0x459>
f01014f3:	89 f8                	mov    %edi,%eax
f01014f5:	29 c8                	sub    %ecx,%eax
f01014f7:	c1 f8 03             	sar    $0x3,%eax
f01014fa:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01014fd:	39 c2                	cmp    %eax,%edx
f01014ff:	0f 86 83 02 00 00    	jbe    f0101788 <mem_init+0x47b>
f0101505:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101508:	29 c8                	sub    %ecx,%eax
f010150a:	c1 f8 03             	sar    $0x3,%eax
f010150d:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101510:	39 c2                	cmp    %eax,%edx
f0101512:	0f 86 92 02 00 00    	jbe    f01017aa <mem_init+0x49d>
	fl = page_free_list;
f0101518:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010151b:	8b 88 94 1f 00 00    	mov    0x1f94(%eax),%ecx
f0101521:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101524:	c7 80 94 1f 00 00 00 	movl   $0x0,0x1f94(%eax)
f010152b:	00 00 00 
	assert(!page_alloc(0));
f010152e:	83 ec 0c             	sub    $0xc,%esp
f0101531:	6a 00                	push   $0x0
f0101533:	e8 c3 fa ff ff       	call   f0100ffb <page_alloc>
f0101538:	83 c4 10             	add    $0x10,%esp
f010153b:	85 c0                	test   %eax,%eax
f010153d:	0f 85 89 02 00 00    	jne    f01017cc <mem_init+0x4bf>
	page_free(pp0);
f0101543:	83 ec 0c             	sub    $0xc,%esp
f0101546:	53                   	push   %ebx
f0101547:	e8 37 fb ff ff       	call   f0101083 <page_free>
	page_free(pp1);
f010154c:	89 3c 24             	mov    %edi,(%esp)
f010154f:	e8 2f fb ff ff       	call   f0101083 <page_free>
	page_free(pp2);
f0101554:	83 c4 04             	add    $0x4,%esp
f0101557:	ff 75 d0             	pushl  -0x30(%ebp)
f010155a:	e8 24 fb ff ff       	call   f0101083 <page_free>
	assert((pp0 = page_alloc(0)));
f010155f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101566:	e8 90 fa ff ff       	call   f0100ffb <page_alloc>
f010156b:	89 c7                	mov    %eax,%edi
f010156d:	83 c4 10             	add    $0x10,%esp
f0101570:	85 c0                	test   %eax,%eax
f0101572:	0f 84 76 02 00 00    	je     f01017ee <mem_init+0x4e1>
	assert((pp1 = page_alloc(0)));
f0101578:	83 ec 0c             	sub    $0xc,%esp
f010157b:	6a 00                	push   $0x0
f010157d:	e8 79 fa ff ff       	call   f0100ffb <page_alloc>
f0101582:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101585:	83 c4 10             	add    $0x10,%esp
f0101588:	85 c0                	test   %eax,%eax
f010158a:	0f 84 80 02 00 00    	je     f0101810 <mem_init+0x503>
	assert((pp2 = page_alloc(0)));
f0101590:	83 ec 0c             	sub    $0xc,%esp
f0101593:	6a 00                	push   $0x0
f0101595:	e8 61 fa ff ff       	call   f0100ffb <page_alloc>
f010159a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010159d:	83 c4 10             	add    $0x10,%esp
f01015a0:	85 c0                	test   %eax,%eax
f01015a2:	0f 84 8a 02 00 00    	je     f0101832 <mem_init+0x525>
	assert(pp1 && pp1 != pp0);
f01015a8:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01015ab:	0f 84 a3 02 00 00    	je     f0101854 <mem_init+0x547>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015b1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01015b4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01015b7:	0f 84 b9 02 00 00    	je     f0101876 <mem_init+0x569>
f01015bd:	39 c7                	cmp    %eax,%edi
f01015bf:	0f 84 b1 02 00 00    	je     f0101876 <mem_init+0x569>
	assert(!page_alloc(0));
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 2c fa ff ff       	call   f0100ffb <page_alloc>
f01015cf:	83 c4 10             	add    $0x10,%esp
f01015d2:	85 c0                	test   %eax,%eax
f01015d4:	0f 85 be 02 00 00    	jne    f0101898 <mem_init+0x58b>
f01015da:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015dd:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01015e3:	89 f9                	mov    %edi,%ecx
f01015e5:	2b 08                	sub    (%eax),%ecx
f01015e7:	89 c8                	mov    %ecx,%eax
f01015e9:	c1 f8 03             	sar    $0x3,%eax
f01015ec:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01015ef:	89 c1                	mov    %eax,%ecx
f01015f1:	c1 e9 0c             	shr    $0xc,%ecx
f01015f4:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01015fa:	3b 0a                	cmp    (%edx),%ecx
f01015fc:	0f 83 b8 02 00 00    	jae    f01018ba <mem_init+0x5ad>
	memset(page2kva(pp0), 1, PGSIZE);
f0101602:	83 ec 04             	sub    $0x4,%esp
f0101605:	68 00 10 00 00       	push   $0x1000
f010160a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010160c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101611:	50                   	push   %eax
f0101612:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101615:	e8 43 27 00 00       	call   f0103d5d <memset>
	page_free(pp0);
f010161a:	89 3c 24             	mov    %edi,(%esp)
f010161d:	e8 61 fa ff ff       	call   f0101083 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101622:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101629:	e8 cd f9 ff ff       	call   f0100ffb <page_alloc>
f010162e:	83 c4 10             	add    $0x10,%esp
f0101631:	85 c0                	test   %eax,%eax
f0101633:	0f 84 97 02 00 00    	je     f01018d0 <mem_init+0x5c3>
	assert(pp && pp0 == pp);
f0101639:	39 c7                	cmp    %eax,%edi
f010163b:	0f 85 b1 02 00 00    	jne    f01018f2 <mem_init+0x5e5>
	return (pp - pages) << PGSHIFT;
f0101641:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101644:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010164a:	89 fa                	mov    %edi,%edx
f010164c:	2b 10                	sub    (%eax),%edx
f010164e:	c1 fa 03             	sar    $0x3,%edx
f0101651:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101654:	89 d1                	mov    %edx,%ecx
f0101656:	c1 e9 0c             	shr    $0xc,%ecx
f0101659:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010165f:	3b 08                	cmp    (%eax),%ecx
f0101661:	0f 83 ad 02 00 00    	jae    f0101914 <mem_init+0x607>
	return (void *)(pa + KERNBASE);
f0101667:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010166d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101673:	80 38 00             	cmpb   $0x0,(%eax)
f0101676:	0f 85 ae 02 00 00    	jne    f010192a <mem_init+0x61d>
f010167c:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f010167f:	39 d0                	cmp    %edx,%eax
f0101681:	75 f0                	jne    f0101673 <mem_init+0x366>
	page_free_list = fl;
f0101683:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101686:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101689:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)
	page_free(pp0);
f010168f:	83 ec 0c             	sub    $0xc,%esp
f0101692:	57                   	push   %edi
f0101693:	e8 eb f9 ff ff       	call   f0101083 <page_free>
	page_free(pp1);
f0101698:	83 c4 04             	add    $0x4,%esp
f010169b:	ff 75 d0             	pushl  -0x30(%ebp)
f010169e:	e8 e0 f9 ff ff       	call   f0101083 <page_free>
	page_free(pp2);
f01016a3:	83 c4 04             	add    $0x4,%esp
f01016a6:	ff 75 cc             	pushl  -0x34(%ebp)
f01016a9:	e8 d5 f9 ff ff       	call   f0101083 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016ae:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01016b4:	83 c4 10             	add    $0x10,%esp
f01016b7:	e9 95 02 00 00       	jmp    f0101951 <mem_init+0x644>
	assert((pp0 = page_alloc(0)));
f01016bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016bf:	8d 83 a0 db fe ff    	lea    -0x12460(%ebx),%eax
f01016c5:	50                   	push   %eax
f01016c6:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01016cc:	50                   	push   %eax
f01016cd:	68 73 02 00 00       	push   $0x273
f01016d2:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01016d8:	50                   	push   %eax
f01016d9:	e8 bb e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01016de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016e1:	8d 83 b6 db fe ff    	lea    -0x1244a(%ebx),%eax
f01016e7:	50                   	push   %eax
f01016e8:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01016ee:	50                   	push   %eax
f01016ef:	68 74 02 00 00       	push   $0x274
f01016f4:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01016fa:	50                   	push   %eax
f01016fb:	e8 99 e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101700:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101703:	8d 83 cc db fe ff    	lea    -0x12434(%ebx),%eax
f0101709:	50                   	push   %eax
f010170a:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101710:	50                   	push   %eax
f0101711:	68 75 02 00 00       	push   $0x275
f0101716:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010171c:	50                   	push   %eax
f010171d:	e8 77 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101722:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101725:	8d 83 e2 db fe ff    	lea    -0x1241e(%ebx),%eax
f010172b:	50                   	push   %eax
f010172c:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101732:	50                   	push   %eax
f0101733:	68 78 02 00 00       	push   $0x278
f0101738:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010173e:	50                   	push   %eax
f010173f:	e8 55 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101744:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101747:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010174d:	50                   	push   %eax
f010174e:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101754:	50                   	push   %eax
f0101755:	68 79 02 00 00       	push   $0x279
f010175a:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101760:	50                   	push   %eax
f0101761:	e8 33 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101766:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101769:	8d 83 f4 db fe ff    	lea    -0x1240c(%ebx),%eax
f010176f:	50                   	push   %eax
f0101770:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101776:	50                   	push   %eax
f0101777:	68 7a 02 00 00       	push   $0x27a
f010177c:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101782:	50                   	push   %eax
f0101783:	e8 11 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101788:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010178b:	8d 83 11 dc fe ff    	lea    -0x123ef(%ebx),%eax
f0101791:	50                   	push   %eax
f0101792:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101798:	50                   	push   %eax
f0101799:	68 7b 02 00 00       	push   $0x27b
f010179e:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01017a4:	50                   	push   %eax
f01017a5:	e8 ef e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017aa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017ad:	8d 83 2e dc fe ff    	lea    -0x123d2(%ebx),%eax
f01017b3:	50                   	push   %eax
f01017b4:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01017ba:	50                   	push   %eax
f01017bb:	68 7c 02 00 00       	push   $0x27c
f01017c0:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01017c6:	50                   	push   %eax
f01017c7:	e8 cd e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01017cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017cf:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f01017d5:	50                   	push   %eax
f01017d6:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01017dc:	50                   	push   %eax
f01017dd:	68 83 02 00 00       	push   $0x283
f01017e2:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01017e8:	50                   	push   %eax
f01017e9:	e8 ab e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01017ee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017f1:	8d 83 a0 db fe ff    	lea    -0x12460(%ebx),%eax
f01017f7:	50                   	push   %eax
f01017f8:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01017fe:	50                   	push   %eax
f01017ff:	68 8a 02 00 00       	push   $0x28a
f0101804:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010180a:	50                   	push   %eax
f010180b:	e8 89 e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101810:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101813:	8d 83 b6 db fe ff    	lea    -0x1244a(%ebx),%eax
f0101819:	50                   	push   %eax
f010181a:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101820:	50                   	push   %eax
f0101821:	68 8b 02 00 00       	push   $0x28b
f0101826:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010182c:	50                   	push   %eax
f010182d:	e8 67 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101832:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101835:	8d 83 cc db fe ff    	lea    -0x12434(%ebx),%eax
f010183b:	50                   	push   %eax
f010183c:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101842:	50                   	push   %eax
f0101843:	68 8c 02 00 00       	push   $0x28c
f0101848:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010184e:	50                   	push   %eax
f010184f:	e8 45 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101854:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101857:	8d 83 e2 db fe ff    	lea    -0x1241e(%ebx),%eax
f010185d:	50                   	push   %eax
f010185e:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101864:	50                   	push   %eax
f0101865:	68 8e 02 00 00       	push   $0x28e
f010186a:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101870:	50                   	push   %eax
f0101871:	e8 23 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101876:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101879:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010187f:	50                   	push   %eax
f0101880:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101886:	50                   	push   %eax
f0101887:	68 8f 02 00 00       	push   $0x28f
f010188c:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101892:	50                   	push   %eax
f0101893:	e8 01 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101898:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010189b:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f01018a1:	50                   	push   %eax
f01018a2:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01018a8:	50                   	push   %eax
f01018a9:	68 90 02 00 00       	push   $0x290
f01018ae:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01018b4:	50                   	push   %eax
f01018b5:	e8 df e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018ba:	50                   	push   %eax
f01018bb:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f01018c1:	50                   	push   %eax
f01018c2:	6a 52                	push   $0x52
f01018c4:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f01018ca:	50                   	push   %eax
f01018cb:	e8 c9 e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018d0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d3:	8d 83 5a dc fe ff    	lea    -0x123a6(%ebx),%eax
f01018d9:	50                   	push   %eax
f01018da:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01018e0:	50                   	push   %eax
f01018e1:	68 95 02 00 00       	push   $0x295
f01018e6:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01018ec:	50                   	push   %eax
f01018ed:	e8 a7 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01018f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f5:	8d 83 78 dc fe ff    	lea    -0x12388(%ebx),%eax
f01018fb:	50                   	push   %eax
f01018fc:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0101902:	50                   	push   %eax
f0101903:	68 96 02 00 00       	push   $0x296
f0101908:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010190e:	50                   	push   %eax
f010190f:	e8 85 e7 ff ff       	call   f0100099 <_panic>
f0101914:	52                   	push   %edx
f0101915:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f010191b:	50                   	push   %eax
f010191c:	6a 52                	push   $0x52
f010191e:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0101924:	50                   	push   %eax
f0101925:	e8 6f e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f010192a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010192d:	8d 83 88 dc fe ff    	lea    -0x12378(%ebx),%eax
f0101933:	50                   	push   %eax
f0101934:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010193a:	50                   	push   %eax
f010193b:	68 99 02 00 00       	push   $0x299
f0101940:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0101946:	50                   	push   %eax
f0101947:	e8 4d e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f010194c:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010194f:	8b 00                	mov    (%eax),%eax
f0101951:	85 c0                	test   %eax,%eax
f0101953:	75 f7                	jne    f010194c <mem_init+0x63f>
	assert(nfree == 0);
f0101955:	85 f6                	test   %esi,%esi
f0101957:	0f 85 f3 07 00 00    	jne    f0102150 <mem_init+0xe43>
	cprintf("check_page_alloc() succeeded!\n");
f010195d:	83 ec 0c             	sub    $0xc,%esp
f0101960:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101963:	8d 83 ec d4 fe ff    	lea    -0x12b14(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	e8 e8 17 00 00       	call   f0103157 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010196f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101976:	e8 80 f6 ff ff       	call   f0100ffb <page_alloc>
f010197b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	0f 84 e9 07 00 00    	je     f0102172 <mem_init+0xe65>
	assert((pp1 = page_alloc(0)));
f0101989:	83 ec 0c             	sub    $0xc,%esp
f010198c:	6a 00                	push   $0x0
f010198e:	e8 68 f6 ff ff       	call   f0100ffb <page_alloc>
f0101993:	89 c7                	mov    %eax,%edi
f0101995:	83 c4 10             	add    $0x10,%esp
f0101998:	85 c0                	test   %eax,%eax
f010199a:	0f 84 f4 07 00 00    	je     f0102194 <mem_init+0xe87>
	assert((pp2 = page_alloc(0)));
f01019a0:	83 ec 0c             	sub    $0xc,%esp
f01019a3:	6a 00                	push   $0x0
f01019a5:	e8 51 f6 ff ff       	call   f0100ffb <page_alloc>
f01019aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019ad:	83 c4 10             	add    $0x10,%esp
f01019b0:	85 c0                	test   %eax,%eax
f01019b2:	0f 84 fe 07 00 00    	je     f01021b6 <mem_init+0xea9>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019b8:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01019bb:	0f 84 17 08 00 00    	je     f01021d8 <mem_init+0xecb>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019c1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01019c4:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01019c7:	0f 84 2d 08 00 00    	je     f01021fa <mem_init+0xeed>
f01019cd:	39 c7                	cmp    %eax,%edi
f01019cf:	0f 84 25 08 00 00    	je     f01021fa <mem_init+0xeed>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019d5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d8:	8b 88 94 1f 00 00    	mov    0x1f94(%eax),%ecx
f01019de:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
	page_free_list = 0;
f01019e1:	c7 80 94 1f 00 00 00 	movl   $0x0,0x1f94(%eax)
f01019e8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019eb:	83 ec 0c             	sub    $0xc,%esp
f01019ee:	6a 00                	push   $0x0
f01019f0:	e8 06 f6 ff ff       	call   f0100ffb <page_alloc>
f01019f5:	83 c4 10             	add    $0x10,%esp
f01019f8:	85 c0                	test   %eax,%eax
f01019fa:	0f 85 1c 08 00 00    	jne    f010221c <mem_init+0xf0f>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a00:	83 ec 04             	sub    $0x4,%esp
f0101a03:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a06:	50                   	push   %eax
f0101a07:	6a 00                	push   $0x0
f0101a09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a0c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a12:	ff 30                	pushl  (%eax)
f0101a14:	e8 91 f7 ff ff       	call   f01011aa <page_lookup>
f0101a19:	83 c4 10             	add    $0x10,%esp
f0101a1c:	85 c0                	test   %eax,%eax
f0101a1e:	0f 85 1a 08 00 00    	jne    f010223e <mem_init+0xf31>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a24:	6a 02                	push   $0x2
f0101a26:	6a 00                	push   $0x0
f0101a28:	57                   	push   %edi
f0101a29:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a32:	ff 30                	pushl  (%eax)
f0101a34:	e8 30 f8 ff ff       	call   f0101269 <page_insert>
f0101a39:	83 c4 10             	add    $0x10,%esp
f0101a3c:	85 c0                	test   %eax,%eax
f0101a3e:	0f 89 1c 08 00 00    	jns    f0102260 <mem_init+0xf53>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a44:	83 ec 0c             	sub    $0xc,%esp
f0101a47:	ff 75 cc             	pushl  -0x34(%ebp)
f0101a4a:	e8 34 f6 ff ff       	call   f0101083 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a4f:	6a 02                	push   $0x2
f0101a51:	6a 00                	push   $0x0
f0101a53:	57                   	push   %edi
f0101a54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a57:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a5d:	ff 30                	pushl  (%eax)
f0101a5f:	e8 05 f8 ff ff       	call   f0101269 <page_insert>
f0101a64:	83 c4 20             	add    $0x20,%esp
f0101a67:	85 c0                	test   %eax,%eax
f0101a69:	0f 85 13 08 00 00    	jne    f0102282 <mem_init+0xf75>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a6f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a72:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a78:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a7a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101a80:	8b 30                	mov    (%eax),%esi
f0101a82:	8b 13                	mov    (%ebx),%edx
f0101a84:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a8a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a8d:	29 f0                	sub    %esi,%eax
f0101a8f:	c1 f8 03             	sar    $0x3,%eax
f0101a92:	c1 e0 0c             	shl    $0xc,%eax
f0101a95:	39 c2                	cmp    %eax,%edx
f0101a97:	0f 85 07 08 00 00    	jne    f01022a4 <mem_init+0xf97>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101aa2:	89 d8                	mov    %ebx,%eax
f0101aa4:	e8 3f f0 ff ff       	call   f0100ae8 <check_va2pa>
f0101aa9:	89 fa                	mov    %edi,%edx
f0101aab:	29 f2                	sub    %esi,%edx
f0101aad:	c1 fa 03             	sar    $0x3,%edx
f0101ab0:	c1 e2 0c             	shl    $0xc,%edx
f0101ab3:	39 d0                	cmp    %edx,%eax
f0101ab5:	0f 85 0a 08 00 00    	jne    f01022c5 <mem_init+0xfb8>
	assert(pp1->pp_ref == 1);
f0101abb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ac0:	0f 85 21 08 00 00    	jne    f01022e7 <mem_init+0xfda>
	assert(pp0->pp_ref == 1);
f0101ac6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ac9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ace:	0f 85 35 08 00 00    	jne    f0102309 <mem_init+0xffc>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad4:	6a 02                	push   $0x2
f0101ad6:	68 00 10 00 00       	push   $0x1000
f0101adb:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ade:	53                   	push   %ebx
f0101adf:	e8 85 f7 ff ff       	call   f0101269 <page_insert>
f0101ae4:	83 c4 10             	add    $0x10,%esp
f0101ae7:	85 c0                	test   %eax,%eax
f0101ae9:	0f 85 3c 08 00 00    	jne    f010232b <mem_init+0x101e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aef:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101af7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101afd:	8b 00                	mov    (%eax),%eax
f0101aff:	e8 e4 ef ff ff       	call   f0100ae8 <check_va2pa>
f0101b04:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b0a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b0d:	2b 0a                	sub    (%edx),%ecx
f0101b0f:	89 ca                	mov    %ecx,%edx
f0101b11:	c1 fa 03             	sar    $0x3,%edx
f0101b14:	c1 e2 0c             	shl    $0xc,%edx
f0101b17:	39 d0                	cmp    %edx,%eax
f0101b19:	0f 85 2e 08 00 00    	jne    f010234d <mem_init+0x1040>
	assert(pp2->pp_ref == 1);
f0101b1f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b22:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b27:	0f 85 42 08 00 00    	jne    f010236f <mem_init+0x1062>

	// should be no free memory
	assert(!page_alloc(0));
f0101b2d:	83 ec 0c             	sub    $0xc,%esp
f0101b30:	6a 00                	push   $0x0
f0101b32:	e8 c4 f4 ff ff       	call   f0100ffb <page_alloc>
f0101b37:	83 c4 10             	add    $0x10,%esp
f0101b3a:	85 c0                	test   %eax,%eax
f0101b3c:	0f 85 4f 08 00 00    	jne    f0102391 <mem_init+0x1084>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b4f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b55:	ff 30                	pushl  (%eax)
f0101b57:	e8 0d f7 ff ff       	call   f0101269 <page_insert>
f0101b5c:	83 c4 10             	add    $0x10,%esp
f0101b5f:	85 c0                	test   %eax,%eax
f0101b61:	0f 85 4c 08 00 00    	jne    f01023b3 <mem_init+0x10a6>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b67:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b6c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101b6f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b75:	8b 00                	mov    (%eax),%eax
f0101b77:	e8 6c ef ff ff       	call   f0100ae8 <check_va2pa>
f0101b7c:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b82:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101b85:	2b 0a                	sub    (%edx),%ecx
f0101b87:	89 ca                	mov    %ecx,%edx
f0101b89:	c1 fa 03             	sar    $0x3,%edx
f0101b8c:	c1 e2 0c             	shl    $0xc,%edx
f0101b8f:	39 d0                	cmp    %edx,%eax
f0101b91:	0f 85 3e 08 00 00    	jne    f01023d5 <mem_init+0x10c8>
	assert(pp2->pp_ref == 1);
f0101b97:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b9a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b9f:	0f 85 52 08 00 00    	jne    f01023f7 <mem_init+0x10ea>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ba5:	83 ec 0c             	sub    $0xc,%esp
f0101ba8:	6a 00                	push   $0x0
f0101baa:	e8 4c f4 ff ff       	call   f0100ffb <page_alloc>
f0101baf:	83 c4 10             	add    $0x10,%esp
f0101bb2:	85 c0                	test   %eax,%eax
f0101bb4:	0f 85 5f 08 00 00    	jne    f0102419 <mem_init+0x110c>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bbd:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bc3:	8b 10                	mov    (%eax),%edx
f0101bc5:	8b 02                	mov    (%edx),%eax
f0101bc7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101bcc:	89 c3                	mov    %eax,%ebx
f0101bce:	c1 eb 0c             	shr    $0xc,%ebx
f0101bd1:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101bd7:	3b 19                	cmp    (%ecx),%ebx
f0101bd9:	0f 83 5c 08 00 00    	jae    f010243b <mem_init+0x112e>
	return (void *)(pa + KERNBASE);
f0101bdf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101be4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101be7:	83 ec 04             	sub    $0x4,%esp
f0101bea:	6a 00                	push   $0x0
f0101bec:	68 00 10 00 00       	push   $0x1000
f0101bf1:	52                   	push   %edx
f0101bf2:	e8 04 f5 ff ff       	call   f01010fb <pgdir_walk>
f0101bf7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bfa:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bfd:	83 c4 10             	add    $0x10,%esp
f0101c00:	39 d0                	cmp    %edx,%eax
f0101c02:	0f 85 4f 08 00 00    	jne    f0102457 <mem_init+0x114a>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c08:	6a 06                	push   $0x6
f0101c0a:	68 00 10 00 00       	push   $0x1000
f0101c0f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c12:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c15:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c1b:	ff 30                	pushl  (%eax)
f0101c1d:	e8 47 f6 ff ff       	call   f0101269 <page_insert>
f0101c22:	83 c4 10             	add    $0x10,%esp
f0101c25:	85 c0                	test   %eax,%eax
f0101c27:	0f 85 4c 08 00 00    	jne    f0102479 <mem_init+0x116c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c2d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101c30:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c36:	8b 18                	mov    (%eax),%ebx
f0101c38:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c3d:	89 d8                	mov    %ebx,%eax
f0101c3f:	e8 a4 ee ff ff       	call   f0100ae8 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101c44:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c4a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101c4d:	2b 0a                	sub    (%edx),%ecx
f0101c4f:	89 ca                	mov    %ecx,%edx
f0101c51:	c1 fa 03             	sar    $0x3,%edx
f0101c54:	c1 e2 0c             	shl    $0xc,%edx
f0101c57:	39 d0                	cmp    %edx,%eax
f0101c59:	0f 85 3c 08 00 00    	jne    f010249b <mem_init+0x118e>
	assert(pp2->pp_ref == 1);
f0101c5f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c62:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c67:	0f 85 50 08 00 00    	jne    f01024bd <mem_init+0x11b0>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c6d:	83 ec 04             	sub    $0x4,%esp
f0101c70:	6a 00                	push   $0x0
f0101c72:	68 00 10 00 00       	push   $0x1000
f0101c77:	53                   	push   %ebx
f0101c78:	e8 7e f4 ff ff       	call   f01010fb <pgdir_walk>
f0101c7d:	83 c4 10             	add    $0x10,%esp
f0101c80:	f6 00 04             	testb  $0x4,(%eax)
f0101c83:	0f 84 56 08 00 00    	je     f01024df <mem_init+0x11d2>
	assert(kern_pgdir[0] & PTE_U);
f0101c89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c8c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c92:	8b 00                	mov    (%eax),%eax
f0101c94:	f6 00 04             	testb  $0x4,(%eax)
f0101c97:	0f 84 64 08 00 00    	je     f0102501 <mem_init+0x11f4>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c9d:	6a 02                	push   $0x2
f0101c9f:	68 00 10 00 00       	push   $0x1000
f0101ca4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ca7:	50                   	push   %eax
f0101ca8:	e8 bc f5 ff ff       	call   f0101269 <page_insert>
f0101cad:	83 c4 10             	add    $0x10,%esp
f0101cb0:	85 c0                	test   %eax,%eax
f0101cb2:	0f 85 6b 08 00 00    	jne    f0102523 <mem_init+0x1216>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cb8:	83 ec 04             	sub    $0x4,%esp
f0101cbb:	6a 00                	push   $0x0
f0101cbd:	68 00 10 00 00       	push   $0x1000
f0101cc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cc5:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ccb:	ff 30                	pushl  (%eax)
f0101ccd:	e8 29 f4 ff ff       	call   f01010fb <pgdir_walk>
f0101cd2:	83 c4 10             	add    $0x10,%esp
f0101cd5:	f6 00 02             	testb  $0x2,(%eax)
f0101cd8:	0f 84 67 08 00 00    	je     f0102545 <mem_init+0x1238>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cde:	83 ec 04             	sub    $0x4,%esp
f0101ce1:	6a 00                	push   $0x0
f0101ce3:	68 00 10 00 00       	push   $0x1000
f0101ce8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ceb:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf1:	ff 30                	pushl  (%eax)
f0101cf3:	e8 03 f4 ff ff       	call   f01010fb <pgdir_walk>
f0101cf8:	83 c4 10             	add    $0x10,%esp
f0101cfb:	f6 00 04             	testb  $0x4,(%eax)
f0101cfe:	0f 85 63 08 00 00    	jne    f0102567 <mem_init+0x125a>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d04:	6a 02                	push   $0x2
f0101d06:	68 00 00 40 00       	push   $0x400000
f0101d0b:	ff 75 cc             	pushl  -0x34(%ebp)
f0101d0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d11:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d17:	ff 30                	pushl  (%eax)
f0101d19:	e8 4b f5 ff ff       	call   f0101269 <page_insert>
f0101d1e:	83 c4 10             	add    $0x10,%esp
f0101d21:	85 c0                	test   %eax,%eax
f0101d23:	0f 89 60 08 00 00    	jns    f0102589 <mem_init+0x127c>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d29:	6a 02                	push   $0x2
f0101d2b:	68 00 10 00 00       	push   $0x1000
f0101d30:	57                   	push   %edi
f0101d31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d34:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d3a:	ff 30                	pushl  (%eax)
f0101d3c:	e8 28 f5 ff ff       	call   f0101269 <page_insert>
f0101d41:	83 c4 10             	add    $0x10,%esp
f0101d44:	85 c0                	test   %eax,%eax
f0101d46:	0f 85 5f 08 00 00    	jne    f01025ab <mem_init+0x129e>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d4c:	83 ec 04             	sub    $0x4,%esp
f0101d4f:	6a 00                	push   $0x0
f0101d51:	68 00 10 00 00       	push   $0x1000
f0101d56:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d59:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d5f:	ff 30                	pushl  (%eax)
f0101d61:	e8 95 f3 ff ff       	call   f01010fb <pgdir_walk>
f0101d66:	83 c4 10             	add    $0x10,%esp
f0101d69:	f6 00 04             	testb  $0x4,(%eax)
f0101d6c:	0f 85 5b 08 00 00    	jne    f01025cd <mem_init+0x12c0>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d75:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d7b:	8b 30                	mov    (%eax),%esi
f0101d7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d82:	89 f0                	mov    %esi,%eax
f0101d84:	e8 5f ed ff ff       	call   f0100ae8 <check_va2pa>
f0101d89:	89 c3                	mov    %eax,%ebx
f0101d8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d8e:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101d94:	89 f9                	mov    %edi,%ecx
f0101d96:	2b 08                	sub    (%eax),%ecx
f0101d98:	89 c8                	mov    %ecx,%eax
f0101d9a:	c1 f8 03             	sar    $0x3,%eax
f0101d9d:	c1 e0 0c             	shl    $0xc,%eax
f0101da0:	39 c3                	cmp    %eax,%ebx
f0101da2:	0f 85 47 08 00 00    	jne    f01025ef <mem_init+0x12e2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101da8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dad:	89 f0                	mov    %esi,%eax
f0101daf:	e8 34 ed ff ff       	call   f0100ae8 <check_va2pa>
f0101db4:	39 c3                	cmp    %eax,%ebx
f0101db6:	0f 85 55 08 00 00    	jne    f0102611 <mem_init+0x1304>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101dbc:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101dc1:	0f 85 6c 08 00 00    	jne    f0102633 <mem_init+0x1326>
	assert(pp2->pp_ref == 0);
f0101dc7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101dca:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101dcf:	0f 85 80 08 00 00    	jne    f0102655 <mem_init+0x1348>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101dd5:	83 ec 0c             	sub    $0xc,%esp
f0101dd8:	6a 00                	push   $0x0
f0101dda:	e8 1c f2 ff ff       	call   f0100ffb <page_alloc>
f0101ddf:	83 c4 10             	add    $0x10,%esp
f0101de2:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101de5:	0f 85 8c 08 00 00    	jne    f0102677 <mem_init+0x136a>
f0101deb:	85 c0                	test   %eax,%eax
f0101ded:	0f 84 84 08 00 00    	je     f0102677 <mem_init+0x136a>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101df3:	83 ec 08             	sub    $0x8,%esp
f0101df6:	6a 00                	push   $0x0
f0101df8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dfb:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101e01:	ff 33                	pushl  (%ebx)
f0101e03:	e8 14 f4 ff ff       	call   f010121c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e08:	8b 1b                	mov    (%ebx),%ebx
f0101e0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e0f:	89 d8                	mov    %ebx,%eax
f0101e11:	e8 d2 ec ff ff       	call   f0100ae8 <check_va2pa>
f0101e16:	83 c4 10             	add    $0x10,%esp
f0101e19:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e1c:	0f 85 77 08 00 00    	jne    f0102699 <mem_init+0x138c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e27:	89 d8                	mov    %ebx,%eax
f0101e29:	e8 ba ec ff ff       	call   f0100ae8 <check_va2pa>
f0101e2e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e31:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101e37:	89 f9                	mov    %edi,%ecx
f0101e39:	2b 0a                	sub    (%edx),%ecx
f0101e3b:	89 ca                	mov    %ecx,%edx
f0101e3d:	c1 fa 03             	sar    $0x3,%edx
f0101e40:	c1 e2 0c             	shl    $0xc,%edx
f0101e43:	39 d0                	cmp    %edx,%eax
f0101e45:	0f 85 70 08 00 00    	jne    f01026bb <mem_init+0x13ae>
	assert(pp1->pp_ref == 1);
f0101e4b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101e50:	0f 85 87 08 00 00    	jne    f01026dd <mem_init+0x13d0>
	assert(pp2->pp_ref == 0);
f0101e56:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e59:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e5e:	0f 85 9b 08 00 00    	jne    f01026ff <mem_init+0x13f2>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e64:	6a 00                	push   $0x0
f0101e66:	68 00 10 00 00       	push   $0x1000
f0101e6b:	57                   	push   %edi
f0101e6c:	53                   	push   %ebx
f0101e6d:	e8 f7 f3 ff ff       	call   f0101269 <page_insert>
f0101e72:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101e75:	83 c4 10             	add    $0x10,%esp
f0101e78:	85 c0                	test   %eax,%eax
f0101e7a:	0f 85 a1 08 00 00    	jne    f0102721 <mem_init+0x1414>
	assert(pp1->pp_ref);
f0101e80:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e85:	0f 84 b8 08 00 00    	je     f0102743 <mem_init+0x1436>
	assert(pp1->pp_link == NULL);
f0101e8b:	83 3f 00             	cmpl   $0x0,(%edi)
f0101e8e:	0f 85 d1 08 00 00    	jne    f0102765 <mem_init+0x1458>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e94:	83 ec 08             	sub    $0x8,%esp
f0101e97:	68 00 10 00 00       	push   $0x1000
f0101e9c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9f:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101ea5:	ff 33                	pushl  (%ebx)
f0101ea7:	e8 70 f3 ff ff       	call   f010121c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eac:	8b 1b                	mov    (%ebx),%ebx
f0101eae:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eb3:	89 d8                	mov    %ebx,%eax
f0101eb5:	e8 2e ec ff ff       	call   f0100ae8 <check_va2pa>
f0101eba:	83 c4 10             	add    $0x10,%esp
f0101ebd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec0:	0f 85 c1 08 00 00    	jne    f0102787 <mem_init+0x147a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ec6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ecb:	89 d8                	mov    %ebx,%eax
f0101ecd:	e8 16 ec ff ff       	call   f0100ae8 <check_va2pa>
f0101ed2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ed5:	0f 85 ce 08 00 00    	jne    f01027a9 <mem_init+0x149c>
	assert(pp1->pp_ref == 0);
f0101edb:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101ee0:	0f 85 e5 08 00 00    	jne    f01027cb <mem_init+0x14be>
	assert(pp2->pp_ref == 0);
f0101ee6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ee9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101eee:	0f 85 f9 08 00 00    	jne    f01027ed <mem_init+0x14e0>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ef4:	83 ec 0c             	sub    $0xc,%esp
f0101ef7:	6a 00                	push   $0x0
f0101ef9:	e8 fd f0 ff ff       	call   f0100ffb <page_alloc>
f0101efe:	83 c4 10             	add    $0x10,%esp
f0101f01:	85 c0                	test   %eax,%eax
f0101f03:	0f 84 06 09 00 00    	je     f010280f <mem_init+0x1502>
f0101f09:	39 c7                	cmp    %eax,%edi
f0101f0b:	0f 85 fe 08 00 00    	jne    f010280f <mem_init+0x1502>

	// should be no free memory
	assert(!page_alloc(0));
f0101f11:	83 ec 0c             	sub    $0xc,%esp
f0101f14:	6a 00                	push   $0x0
f0101f16:	e8 e0 f0 ff ff       	call   f0100ffb <page_alloc>
f0101f1b:	83 c4 10             	add    $0x10,%esp
f0101f1e:	85 c0                	test   %eax,%eax
f0101f20:	0f 85 0b 09 00 00    	jne    f0102831 <mem_init+0x1524>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f26:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f29:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f2f:	8b 08                	mov    (%eax),%ecx
f0101f31:	8b 11                	mov    (%ecx),%edx
f0101f33:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f39:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f3f:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101f42:	2b 18                	sub    (%eax),%ebx
f0101f44:	89 d8                	mov    %ebx,%eax
f0101f46:	c1 f8 03             	sar    $0x3,%eax
f0101f49:	c1 e0 0c             	shl    $0xc,%eax
f0101f4c:	39 c2                	cmp    %eax,%edx
f0101f4e:	0f 85 ff 08 00 00    	jne    f0102853 <mem_init+0x1546>
	kern_pgdir[0] = 0;
f0101f54:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f5a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f5d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f62:	0f 85 0d 09 00 00    	jne    f0102875 <mem_init+0x1568>
	pp0->pp_ref = 0;
f0101f68:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f6b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f71:	83 ec 0c             	sub    $0xc,%esp
f0101f74:	50                   	push   %eax
f0101f75:	e8 09 f1 ff ff       	call   f0101083 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f7a:	83 c4 0c             	add    $0xc,%esp
f0101f7d:	6a 01                	push   $0x1
f0101f7f:	68 00 10 40 00       	push   $0x401000
f0101f84:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101f87:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101f8d:	ff 33                	pushl  (%ebx)
f0101f8f:	e8 67 f1 ff ff       	call   f01010fb <pgdir_walk>
f0101f94:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f97:	8b 0b                	mov    (%ebx),%ecx
f0101f99:	8b 51 04             	mov    0x4(%ecx),%edx
f0101f9c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101fa2:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0101fa8:	8b 1b                	mov    (%ebx),%ebx
f0101faa:	89 d6                	mov    %edx,%esi
f0101fac:	c1 ee 0c             	shr    $0xc,%esi
f0101faf:	83 c4 10             	add    $0x10,%esp
f0101fb2:	39 de                	cmp    %ebx,%esi
f0101fb4:	0f 83 dd 08 00 00    	jae    f0102897 <mem_init+0x158a>
	assert(ptep == ptep1 + PTX(va));
f0101fba:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101fc0:	39 d0                	cmp    %edx,%eax
f0101fc2:	0f 85 eb 08 00 00    	jne    f01028b3 <mem_init+0x15a6>
	kern_pgdir[PDX(va)] = 0;
f0101fc8:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0101fcf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101fd2:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0101fd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fdb:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101fe1:	2b 08                	sub    (%eax),%ecx
f0101fe3:	89 c8                	mov    %ecx,%eax
f0101fe5:	c1 f8 03             	sar    $0x3,%eax
f0101fe8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101feb:	89 c2                	mov    %eax,%edx
f0101fed:	c1 ea 0c             	shr    $0xc,%edx
f0101ff0:	39 d3                	cmp    %edx,%ebx
f0101ff2:	0f 86 dd 08 00 00    	jbe    f01028d5 <mem_init+0x15c8>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ff8:	83 ec 04             	sub    $0x4,%esp
f0101ffb:	68 00 10 00 00       	push   $0x1000
f0102000:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102005:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010200a:	50                   	push   %eax
f010200b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010200e:	e8 4a 1d 00 00       	call   f0103d5d <memset>
	page_free(pp0);
f0102013:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102016:	89 34 24             	mov    %esi,(%esp)
f0102019:	e8 65 f0 ff ff       	call   f0101083 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010201e:	83 c4 0c             	add    $0xc,%esp
f0102021:	6a 01                	push   $0x1
f0102023:	6a 00                	push   $0x0
f0102025:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102028:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010202e:	ff 30                	pushl  (%eax)
f0102030:	e8 c6 f0 ff ff       	call   f01010fb <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102035:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010203b:	89 f2                	mov    %esi,%edx
f010203d:	2b 10                	sub    (%eax),%edx
f010203f:	c1 fa 03             	sar    $0x3,%edx
f0102042:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102045:	89 d1                	mov    %edx,%ecx
f0102047:	c1 e9 0c             	shr    $0xc,%ecx
f010204a:	83 c4 10             	add    $0x10,%esp
f010204d:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102053:	3b 08                	cmp    (%eax),%ecx
f0102055:	0f 83 93 08 00 00    	jae    f01028ee <mem_init+0x15e1>
	return (void *)(pa + KERNBASE);
f010205b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102061:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102064:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f010206a:	8b 75 c8             	mov    -0x38(%ebp),%esi
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010206d:	f6 00 01             	testb  $0x1,(%eax)
f0102070:	0f 85 91 08 00 00    	jne    f0102907 <mem_init+0x15fa>
f0102076:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102079:	39 d0                	cmp    %edx,%eax
f010207b:	75 f0                	jne    f010206d <mem_init+0xd60>
f010207d:	89 75 c8             	mov    %esi,-0x38(%ebp)
	kern_pgdir[0] = 0;
f0102080:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102083:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102089:	8b 00                	mov    (%eax),%eax
f010208b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102091:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102094:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010209a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010209d:	89 b3 94 1f 00 00    	mov    %esi,0x1f94(%ebx)

	// free the pages we took
	page_free(pp0);
f01020a3:	83 ec 0c             	sub    $0xc,%esp
f01020a6:	50                   	push   %eax
f01020a7:	e8 d7 ef ff ff       	call   f0101083 <page_free>
	page_free(pp1);
f01020ac:	89 3c 24             	mov    %edi,(%esp)
f01020af:	e8 cf ef ff ff       	call   f0101083 <page_free>
	page_free(pp2);
f01020b4:	83 c4 04             	add    $0x4,%esp
f01020b7:	ff 75 d0             	pushl  -0x30(%ebp)
f01020ba:	e8 c4 ef ff ff       	call   f0101083 <page_free>

	cprintf("check_page() succeeded!\n");
f01020bf:	8d 83 69 dd fe ff    	lea    -0x12297(%ebx),%eax
f01020c5:	89 04 24             	mov    %eax,(%esp)
f01020c8:	89 df                	mov    %ebx,%edi
f01020ca:	e8 88 10 00 00       	call   f0103157 <cprintf>
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020cf:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01020d5:	8b 00                	mov    (%eax),%eax
f01020d7:	8d 1c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ebx
f01020de:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	for(i=0; i<n; i= i+PGSIZE)
f01020e4:	83 c4 10             	add    $0x10,%esp
		page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm);
f01020e7:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01020ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
	if (PGNUM(pa) >= npages)
f01020f0:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01020f6:	89 c7                	mov    %eax,%edi
f01020f8:	8b 75 c8             	mov    -0x38(%ebp),%esi
	for(i=0; i<n; i= i+PGSIZE)
f01020fb:	89 f0                	mov    %esi,%eax
f01020fd:	39 de                	cmp    %ebx,%esi
f01020ff:	0f 83 5b 08 00 00    	jae    f0102960 <mem_init+0x1653>
f0102105:	8d 8e 00 00 00 ef    	lea    -0x11000000(%esi),%ecx
		page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm);
f010210b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010210e:	8b 12                	mov    (%edx),%edx
	if ((uint32_t)kva < KERNBASE)
f0102110:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102116:	0f 86 0d 08 00 00    	jbe    f0102929 <mem_init+0x161c>
f010211c:	8d 84 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%eax
	if (PGNUM(pa) >= npages)
f0102123:	c1 e8 0c             	shr    $0xc,%eax
f0102126:	3b 07                	cmp    (%edi),%eax
f0102128:	0f 83 17 08 00 00    	jae    f0102945 <mem_init+0x1638>
f010212e:	6a 05                	push   $0x5
f0102130:	51                   	push   %ecx
	return &pages[PGNUM(pa)];
f0102131:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102134:	50                   	push   %eax
f0102135:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102138:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010213e:	ff 30                	pushl  (%eax)
f0102140:	e8 24 f1 ff ff       	call   f0101269 <page_insert>
	for(i=0; i<n; i= i+PGSIZE)
f0102145:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010214b:	83 c4 10             	add    $0x10,%esp
f010214e:	eb ab                	jmp    f01020fb <mem_init+0xdee>
	assert(nfree == 0);
f0102150:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102153:	8d 83 92 dc fe ff    	lea    -0x1236e(%ebx),%eax
f0102159:	50                   	push   %eax
f010215a:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102160:	50                   	push   %eax
f0102161:	68 a6 02 00 00       	push   $0x2a6
f0102166:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010216c:	50                   	push   %eax
f010216d:	e8 27 df ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102172:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102175:	8d 83 a0 db fe ff    	lea    -0x12460(%ebx),%eax
f010217b:	50                   	push   %eax
f010217c:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102182:	50                   	push   %eax
f0102183:	68 ff 02 00 00       	push   $0x2ff
f0102188:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010218e:	50                   	push   %eax
f010218f:	e8 05 df ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102194:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102197:	8d 83 b6 db fe ff    	lea    -0x1244a(%ebx),%eax
f010219d:	50                   	push   %eax
f010219e:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01021a4:	50                   	push   %eax
f01021a5:	68 00 03 00 00       	push   $0x300
f01021aa:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01021b0:	50                   	push   %eax
f01021b1:	e8 e3 de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01021b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021b9:	8d 83 cc db fe ff    	lea    -0x12434(%ebx),%eax
f01021bf:	50                   	push   %eax
f01021c0:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01021c6:	50                   	push   %eax
f01021c7:	68 01 03 00 00       	push   $0x301
f01021cc:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01021d2:	50                   	push   %eax
f01021d3:	e8 c1 de ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01021d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021db:	8d 83 e2 db fe ff    	lea    -0x1241e(%ebx),%eax
f01021e1:	50                   	push   %eax
f01021e2:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01021e8:	50                   	push   %eax
f01021e9:	68 04 03 00 00       	push   $0x304
f01021ee:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01021f4:	50                   	push   %eax
f01021f5:	e8 9f de ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01021fa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021fd:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102203:	50                   	push   %eax
f0102204:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010220a:	50                   	push   %eax
f010220b:	68 05 03 00 00       	push   $0x305
f0102210:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102216:	50                   	push   %eax
f0102217:	e8 7d de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010221c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010221f:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f0102225:	50                   	push   %eax
f0102226:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010222c:	50                   	push   %eax
f010222d:	68 0c 03 00 00       	push   $0x30c
f0102232:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102238:	50                   	push   %eax
f0102239:	e8 5b de ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010223e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102241:	8d 83 0c d5 fe ff    	lea    -0x12af4(%ebx),%eax
f0102247:	50                   	push   %eax
f0102248:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010224e:	50                   	push   %eax
f010224f:	68 0f 03 00 00       	push   $0x30f
f0102254:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010225a:	50                   	push   %eax
f010225b:	e8 39 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102260:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102263:	8d 83 44 d5 fe ff    	lea    -0x12abc(%ebx),%eax
f0102269:	50                   	push   %eax
f010226a:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102270:	50                   	push   %eax
f0102271:	68 12 03 00 00       	push   $0x312
f0102276:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010227c:	50                   	push   %eax
f010227d:	e8 17 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102282:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102285:	8d 83 74 d5 fe ff    	lea    -0x12a8c(%ebx),%eax
f010228b:	50                   	push   %eax
f010228c:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102292:	50                   	push   %eax
f0102293:	68 16 03 00 00       	push   $0x316
f0102298:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010229e:	50                   	push   %eax
f010229f:	e8 f5 dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022a4:	89 cb                	mov    %ecx,%ebx
f01022a6:	8d 81 a4 d5 fe ff    	lea    -0x12a5c(%ecx),%eax
f01022ac:	50                   	push   %eax
f01022ad:	8d 81 de da fe ff    	lea    -0x12522(%ecx),%eax
f01022b3:	50                   	push   %eax
f01022b4:	68 17 03 00 00       	push   $0x317
f01022b9:	8d 81 b8 da fe ff    	lea    -0x12548(%ecx),%eax
f01022bf:	50                   	push   %eax
f01022c0:	e8 d4 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022c8:	8d 83 cc d5 fe ff    	lea    -0x12a34(%ebx),%eax
f01022ce:	50                   	push   %eax
f01022cf:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01022d5:	50                   	push   %eax
f01022d6:	68 18 03 00 00       	push   $0x318
f01022db:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01022e1:	50                   	push   %eax
f01022e2:	e8 b2 dd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01022e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022ea:	8d 83 9d dc fe ff    	lea    -0x12363(%ebx),%eax
f01022f0:	50                   	push   %eax
f01022f1:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01022f7:	50                   	push   %eax
f01022f8:	68 19 03 00 00       	push   $0x319
f01022fd:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102303:	50                   	push   %eax
f0102304:	e8 90 dd ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102309:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230c:	8d 83 ae dc fe ff    	lea    -0x12352(%ebx),%eax
f0102312:	50                   	push   %eax
f0102313:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102319:	50                   	push   %eax
f010231a:	68 1a 03 00 00       	push   $0x31a
f010231f:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102325:	50                   	push   %eax
f0102326:	e8 6e dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010232b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010232e:	8d 83 fc d5 fe ff    	lea    -0x12a04(%ebx),%eax
f0102334:	50                   	push   %eax
f0102335:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010233b:	50                   	push   %eax
f010233c:	68 1d 03 00 00       	push   $0x31d
f0102341:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102347:	50                   	push   %eax
f0102348:	e8 4c dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010234d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102350:	8d 83 38 d6 fe ff    	lea    -0x129c8(%ebx),%eax
f0102356:	50                   	push   %eax
f0102357:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010235d:	50                   	push   %eax
f010235e:	68 1e 03 00 00       	push   $0x31e
f0102363:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102369:	50                   	push   %eax
f010236a:	e8 2a dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010236f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102372:	8d 83 bf dc fe ff    	lea    -0x12341(%ebx),%eax
f0102378:	50                   	push   %eax
f0102379:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010237f:	50                   	push   %eax
f0102380:	68 1f 03 00 00       	push   $0x31f
f0102385:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010238b:	50                   	push   %eax
f010238c:	e8 08 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102391:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102394:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f010239a:	50                   	push   %eax
f010239b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01023a1:	50                   	push   %eax
f01023a2:	68 22 03 00 00       	push   $0x322
f01023a7:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01023ad:	50                   	push   %eax
f01023ae:	e8 e6 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b6:	8d 83 fc d5 fe ff    	lea    -0x12a04(%ebx),%eax
f01023bc:	50                   	push   %eax
f01023bd:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01023c3:	50                   	push   %eax
f01023c4:	68 25 03 00 00       	push   $0x325
f01023c9:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01023cf:	50                   	push   %eax
f01023d0:	e8 c4 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d8:	8d 83 38 d6 fe ff    	lea    -0x129c8(%ebx),%eax
f01023de:	50                   	push   %eax
f01023df:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01023e5:	50                   	push   %eax
f01023e6:	68 26 03 00 00       	push   $0x326
f01023eb:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01023f1:	50                   	push   %eax
f01023f2:	e8 a2 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01023f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023fa:	8d 83 bf dc fe ff    	lea    -0x12341(%ebx),%eax
f0102400:	50                   	push   %eax
f0102401:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102407:	50                   	push   %eax
f0102408:	68 27 03 00 00       	push   $0x327
f010240d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102413:	50                   	push   %eax
f0102414:	e8 80 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102419:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241c:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f0102422:	50                   	push   %eax
f0102423:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102429:	50                   	push   %eax
f010242a:	68 2b 03 00 00       	push   $0x32b
f010242f:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102435:	50                   	push   %eax
f0102436:	e8 5e dc ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010243b:	50                   	push   %eax
f010243c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243f:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0102445:	50                   	push   %eax
f0102446:	68 2e 03 00 00       	push   $0x32e
f010244b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102451:	50                   	push   %eax
f0102452:	e8 42 dc ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102457:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010245a:	8d 83 68 d6 fe ff    	lea    -0x12998(%ebx),%eax
f0102460:	50                   	push   %eax
f0102461:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102467:	50                   	push   %eax
f0102468:	68 2f 03 00 00       	push   $0x32f
f010246d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102473:	50                   	push   %eax
f0102474:	e8 20 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102479:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010247c:	8d 83 a8 d6 fe ff    	lea    -0x12958(%ebx),%eax
f0102482:	50                   	push   %eax
f0102483:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102489:	50                   	push   %eax
f010248a:	68 32 03 00 00       	push   $0x332
f010248f:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102495:	50                   	push   %eax
f0102496:	e8 fe db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010249b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010249e:	8d 83 38 d6 fe ff    	lea    -0x129c8(%ebx),%eax
f01024a4:	50                   	push   %eax
f01024a5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01024ab:	50                   	push   %eax
f01024ac:	68 33 03 00 00       	push   $0x333
f01024b1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01024b7:	50                   	push   %eax
f01024b8:	e8 dc db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c0:	8d 83 bf dc fe ff    	lea    -0x12341(%ebx),%eax
f01024c6:	50                   	push   %eax
f01024c7:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01024cd:	50                   	push   %eax
f01024ce:	68 34 03 00 00       	push   $0x334
f01024d3:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01024d9:	50                   	push   %eax
f01024da:	e8 ba db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e2:	8d 83 e8 d6 fe ff    	lea    -0x12918(%ebx),%eax
f01024e8:	50                   	push   %eax
f01024e9:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01024ef:	50                   	push   %eax
f01024f0:	68 35 03 00 00       	push   $0x335
f01024f5:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01024fb:	50                   	push   %eax
f01024fc:	e8 98 db ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102501:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102504:	8d 83 d0 dc fe ff    	lea    -0x12330(%ebx),%eax
f010250a:	50                   	push   %eax
f010250b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102511:	50                   	push   %eax
f0102512:	68 36 03 00 00       	push   $0x336
f0102517:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010251d:	50                   	push   %eax
f010251e:	e8 76 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102523:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102526:	8d 83 fc d5 fe ff    	lea    -0x12a04(%ebx),%eax
f010252c:	50                   	push   %eax
f010252d:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102533:	50                   	push   %eax
f0102534:	68 39 03 00 00       	push   $0x339
f0102539:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010253f:	50                   	push   %eax
f0102540:	e8 54 db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102545:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102548:	8d 83 1c d7 fe ff    	lea    -0x128e4(%ebx),%eax
f010254e:	50                   	push   %eax
f010254f:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102555:	50                   	push   %eax
f0102556:	68 3a 03 00 00       	push   $0x33a
f010255b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102561:	50                   	push   %eax
f0102562:	e8 32 db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102567:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010256a:	8d 83 50 d7 fe ff    	lea    -0x128b0(%ebx),%eax
f0102570:	50                   	push   %eax
f0102571:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102577:	50                   	push   %eax
f0102578:	68 3b 03 00 00       	push   $0x33b
f010257d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102583:	50                   	push   %eax
f0102584:	e8 10 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102589:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010258c:	8d 83 88 d7 fe ff    	lea    -0x12878(%ebx),%eax
f0102592:	50                   	push   %eax
f0102593:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102599:	50                   	push   %eax
f010259a:	68 3e 03 00 00       	push   $0x33e
f010259f:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01025a5:	50                   	push   %eax
f01025a6:	e8 ee da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ae:	8d 83 c0 d7 fe ff    	lea    -0x12840(%ebx),%eax
f01025b4:	50                   	push   %eax
f01025b5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01025bb:	50                   	push   %eax
f01025bc:	68 41 03 00 00       	push   $0x341
f01025c1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01025c7:	50                   	push   %eax
f01025c8:	e8 cc da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025d0:	8d 83 50 d7 fe ff    	lea    -0x128b0(%ebx),%eax
f01025d6:	50                   	push   %eax
f01025d7:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01025dd:	50                   	push   %eax
f01025de:	68 42 03 00 00       	push   $0x342
f01025e3:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01025e9:	50                   	push   %eax
f01025ea:	e8 aa da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f2:	8d 83 fc d7 fe ff    	lea    -0x12804(%ebx),%eax
f01025f8:	50                   	push   %eax
f01025f9:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01025ff:	50                   	push   %eax
f0102600:	68 45 03 00 00       	push   $0x345
f0102605:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010260b:	50                   	push   %eax
f010260c:	e8 88 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102611:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102614:	8d 83 28 d8 fe ff    	lea    -0x127d8(%ebx),%eax
f010261a:	50                   	push   %eax
f010261b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102621:	50                   	push   %eax
f0102622:	68 46 03 00 00       	push   $0x346
f0102627:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010262d:	50                   	push   %eax
f010262e:	e8 66 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102633:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102636:	8d 83 e6 dc fe ff    	lea    -0x1231a(%ebx),%eax
f010263c:	50                   	push   %eax
f010263d:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102643:	50                   	push   %eax
f0102644:	68 48 03 00 00       	push   $0x348
f0102649:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010264f:	50                   	push   %eax
f0102650:	e8 44 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102655:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102658:	8d 83 f7 dc fe ff    	lea    -0x12309(%ebx),%eax
f010265e:	50                   	push   %eax
f010265f:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102665:	50                   	push   %eax
f0102666:	68 49 03 00 00       	push   $0x349
f010266b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102671:	50                   	push   %eax
f0102672:	e8 22 da ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102677:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010267a:	8d 83 58 d8 fe ff    	lea    -0x127a8(%ebx),%eax
f0102680:	50                   	push   %eax
f0102681:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102687:	50                   	push   %eax
f0102688:	68 4c 03 00 00       	push   $0x34c
f010268d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102693:	50                   	push   %eax
f0102694:	e8 00 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102699:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269c:	8d 83 7c d8 fe ff    	lea    -0x12784(%ebx),%eax
f01026a2:	50                   	push   %eax
f01026a3:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01026a9:	50                   	push   %eax
f01026aa:	68 50 03 00 00       	push   $0x350
f01026af:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01026b5:	50                   	push   %eax
f01026b6:	e8 de d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026be:	8d 83 28 d8 fe ff    	lea    -0x127d8(%ebx),%eax
f01026c4:	50                   	push   %eax
f01026c5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01026cb:	50                   	push   %eax
f01026cc:	68 51 03 00 00       	push   $0x351
f01026d1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01026d7:	50                   	push   %eax
f01026d8:	e8 bc d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01026dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e0:	8d 83 9d dc fe ff    	lea    -0x12363(%ebx),%eax
f01026e6:	50                   	push   %eax
f01026e7:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01026ed:	50                   	push   %eax
f01026ee:	68 52 03 00 00       	push   $0x352
f01026f3:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01026f9:	50                   	push   %eax
f01026fa:	e8 9a d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102702:	8d 83 f7 dc fe ff    	lea    -0x12309(%ebx),%eax
f0102708:	50                   	push   %eax
f0102709:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010270f:	50                   	push   %eax
f0102710:	68 53 03 00 00       	push   $0x353
f0102715:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010271b:	50                   	push   %eax
f010271c:	e8 78 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102721:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102724:	8d 83 a0 d8 fe ff    	lea    -0x12760(%ebx),%eax
f010272a:	50                   	push   %eax
f010272b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102731:	50                   	push   %eax
f0102732:	68 56 03 00 00       	push   $0x356
f0102737:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010273d:	50                   	push   %eax
f010273e:	e8 56 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102743:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102746:	8d 83 08 dd fe ff    	lea    -0x122f8(%ebx),%eax
f010274c:	50                   	push   %eax
f010274d:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102753:	50                   	push   %eax
f0102754:	68 57 03 00 00       	push   $0x357
f0102759:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010275f:	50                   	push   %eax
f0102760:	e8 34 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102765:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102768:	8d 83 14 dd fe ff    	lea    -0x122ec(%ebx),%eax
f010276e:	50                   	push   %eax
f010276f:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102775:	50                   	push   %eax
f0102776:	68 58 03 00 00       	push   $0x358
f010277b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102781:	50                   	push   %eax
f0102782:	e8 12 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102787:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010278a:	8d 83 7c d8 fe ff    	lea    -0x12784(%ebx),%eax
f0102790:	50                   	push   %eax
f0102791:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102797:	50                   	push   %eax
f0102798:	68 5c 03 00 00       	push   $0x35c
f010279d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01027a3:	50                   	push   %eax
f01027a4:	e8 f0 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01027a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ac:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f01027b2:	50                   	push   %eax
f01027b3:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01027b9:	50                   	push   %eax
f01027ba:	68 5d 03 00 00       	push   $0x35d
f01027bf:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01027c5:	50                   	push   %eax
f01027c6:	e8 ce d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01027cb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ce:	8d 83 29 dd fe ff    	lea    -0x122d7(%ebx),%eax
f01027d4:	50                   	push   %eax
f01027d5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01027db:	50                   	push   %eax
f01027dc:	68 5e 03 00 00       	push   $0x35e
f01027e1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01027e7:	50                   	push   %eax
f01027e8:	e8 ac d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027ed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f0:	8d 83 f7 dc fe ff    	lea    -0x12309(%ebx),%eax
f01027f6:	50                   	push   %eax
f01027f7:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01027fd:	50                   	push   %eax
f01027fe:	68 5f 03 00 00       	push   $0x35f
f0102803:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102809:	50                   	push   %eax
f010280a:	e8 8a d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010280f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102812:	8d 83 00 d9 fe ff    	lea    -0x12700(%ebx),%eax
f0102818:	50                   	push   %eax
f0102819:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010281f:	50                   	push   %eax
f0102820:	68 62 03 00 00       	push   $0x362
f0102825:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010282b:	50                   	push   %eax
f010282c:	e8 68 d8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102831:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102834:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f010283a:	50                   	push   %eax
f010283b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102841:	50                   	push   %eax
f0102842:	68 65 03 00 00       	push   $0x365
f0102847:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010284d:	50                   	push   %eax
f010284e:	e8 46 d8 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102853:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102856:	8d 83 a4 d5 fe ff    	lea    -0x12a5c(%ebx),%eax
f010285c:	50                   	push   %eax
f010285d:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102863:	50                   	push   %eax
f0102864:	68 68 03 00 00       	push   $0x368
f0102869:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010286f:	50                   	push   %eax
f0102870:	e8 24 d8 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102875:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102878:	8d 83 ae dc fe ff    	lea    -0x12352(%ebx),%eax
f010287e:	50                   	push   %eax
f010287f:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102885:	50                   	push   %eax
f0102886:	68 6a 03 00 00       	push   $0x36a
f010288b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102891:	50                   	push   %eax
f0102892:	e8 02 d8 ff ff       	call   f0100099 <_panic>
f0102897:	52                   	push   %edx
f0102898:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010289b:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f01028a1:	50                   	push   %eax
f01028a2:	68 71 03 00 00       	push   $0x371
f01028a7:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01028ad:	50                   	push   %eax
f01028ae:	e8 e6 d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b6:	8d 83 3a dd fe ff    	lea    -0x122c6(%ebx),%eax
f01028bc:	50                   	push   %eax
f01028bd:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01028c3:	50                   	push   %eax
f01028c4:	68 72 03 00 00       	push   $0x372
f01028c9:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01028cf:	50                   	push   %eax
f01028d0:	e8 c4 d7 ff ff       	call   f0100099 <_panic>
f01028d5:	50                   	push   %eax
f01028d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028d9:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f01028df:	50                   	push   %eax
f01028e0:	6a 52                	push   $0x52
f01028e2:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f01028e8:	50                   	push   %eax
f01028e9:	e8 ab d7 ff ff       	call   f0100099 <_panic>
f01028ee:	52                   	push   %edx
f01028ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f2:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f01028f8:	50                   	push   %eax
f01028f9:	6a 52                	push   $0x52
f01028fb:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0102901:	50                   	push   %eax
f0102902:	e8 92 d7 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102907:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010290a:	8d 83 52 dd fe ff    	lea    -0x122ae(%ebx),%eax
f0102910:	50                   	push   %eax
f0102911:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102917:	50                   	push   %eax
f0102918:	68 7c 03 00 00       	push   $0x37c
f010291d:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102923:	50                   	push   %eax
f0102924:	e8 70 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102929:	52                   	push   %edx
f010292a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010292d:	8d 83 a8 d4 fe ff    	lea    -0x12b58(%ebx),%eax
f0102933:	50                   	push   %eax
f0102934:	68 b7 00 00 00       	push   $0xb7
f0102939:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010293f:	50                   	push   %eax
f0102940:	e8 54 d7 ff ff       	call   f0100099 <_panic>
		panic("pa2page called with invalid pa");
f0102945:	83 ec 04             	sub    $0x4,%esp
f0102948:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010294b:	8d 83 4c d4 fe ff    	lea    -0x12bb4(%ebx),%eax
f0102951:	50                   	push   %eax
f0102952:	6a 4b                	push   $0x4b
f0102954:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f010295a:	50                   	push   %eax
f010295b:	e8 39 d7 ff ff       	call   f0100099 <_panic>
	if ((uint32_t)kva < KERNBASE)
f0102960:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102963:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102969:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010296e:	0f 86 e6 00 00 00    	jbe    f0102a5a <mem_init+0x174d>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm);
f0102974:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102977:	c7 c2 cc 96 11 f0    	mov    $0xf01196cc,%edx
f010297d:	8b 3a                	mov    (%edx),%edi
f010297f:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102984:	05 00 80 00 20       	add    $0x20008000,%eax
f0102989:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010298c:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010298f:	8d 34 18             	lea    (%eax,%ebx,1),%esi
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
f0102992:	83 ec 04             	sub    $0x4,%esp
f0102995:	6a 01                	push   $0x1
f0102997:	53                   	push   %ebx
f0102998:	57                   	push   %edi
f0102999:	e8 5d e7 ff ff       	call   f01010fb <pgdir_walk>
		if(pte == NULL)
f010299e:	83 c4 10             	add    $0x10,%esp
f01029a1:	85 c0                	test   %eax,%eax
f01029a3:	74 13                	je     f01029b8 <mem_init+0x16ab>
		*pte= pa |perm|PTE_P;
f01029a5:	83 ce 03             	or     $0x3,%esi
f01029a8:	89 30                	mov    %esi,(%eax)
		va  += PGSIZE;
f01029aa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while(size)
f01029b0:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01029b6:	75 d4                	jne    f010298c <mem_init+0x167f>
	boot_map_region(kern_pgdir, KERNBASE, size, 0, perm);
f01029b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029bb:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01029c1:	8b 38                	mov    (%eax),%edi
f01029c3:	bb 00 00 00 f0       	mov    $0xf0000000,%ebx
f01029c8:	8d b3 00 00 00 10    	lea    0x10000000(%ebx),%esi
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
f01029ce:	83 ec 04             	sub    $0x4,%esp
f01029d1:	6a 01                	push   $0x1
f01029d3:	53                   	push   %ebx
f01029d4:	57                   	push   %edi
f01029d5:	e8 21 e7 ff ff       	call   f01010fb <pgdir_walk>
		if(pte == NULL)
f01029da:	83 c4 10             	add    $0x10,%esp
f01029dd:	85 c0                	test   %eax,%eax
f01029df:	74 0d                	je     f01029ee <mem_init+0x16e1>
		*pte= pa |perm|PTE_P;
f01029e1:	83 ce 03             	or     $0x3,%esi
f01029e4:	89 30                	mov    %esi,(%eax)
	while(size)
f01029e6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029ec:	75 da                	jne    f01029c8 <mem_init+0x16bb>
	pgdir = kern_pgdir;
f01029ee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01029f1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01029f7:	8b 30                	mov    (%eax),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01029f9:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01029ff:	8b 00                	mov    (%eax),%eax
f0102a01:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102a04:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102a0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a10:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a13:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102a19:	8b 00                	mov    (%eax),%eax
f0102a1b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0102a1e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102a21:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
	for (i = 0; i < n; i += PGSIZE)
f0102a27:	bf 00 00 00 00       	mov    $0x0,%edi
f0102a2c:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0102a2f:	0f 86 81 00 00 00    	jbe    f0102ab6 <mem_init+0x17a9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a35:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f0102a3b:	89 f0                	mov    %esi,%eax
f0102a3d:	e8 a6 e0 ff ff       	call   f0100ae8 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102a42:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102a49:	76 2b                	jbe    f0102a76 <mem_init+0x1769>
f0102a4b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102a4e:	39 c2                	cmp    %eax,%edx
f0102a50:	75 42                	jne    f0102a94 <mem_init+0x1787>
	for (i = 0; i < n; i += PGSIZE)
f0102a52:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102a58:	eb d2                	jmp    f0102a2c <mem_init+0x171f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a5a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a5d:	50                   	push   %eax
f0102a5e:	8d 83 a8 d4 fe ff    	lea    -0x12b58(%ebx),%eax
f0102a64:	50                   	push   %eax
f0102a65:	68 c5 00 00 00       	push   $0xc5
f0102a6a:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102a70:	50                   	push   %eax
f0102a71:	e8 23 d6 ff ff       	call   f0100099 <_panic>
f0102a76:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a79:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a7c:	8d 83 a8 d4 fe ff    	lea    -0x12b58(%ebx),%eax
f0102a82:	50                   	push   %eax
f0102a83:	68 be 02 00 00       	push   $0x2be
f0102a88:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102a8e:	50                   	push   %eax
f0102a8f:	e8 05 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a94:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a97:	8d 83 24 d9 fe ff    	lea    -0x126dc(%ebx),%eax
f0102a9d:	50                   	push   %eax
f0102a9e:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102aa4:	50                   	push   %eax
f0102aa5:	68 be 02 00 00       	push   $0x2be
f0102aaa:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102ab0:	50                   	push   %eax
f0102ab1:	e8 e3 d5 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ab6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102ab9:	c1 e7 0c             	shl    $0xc,%edi
f0102abc:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ac1:	39 fb                	cmp    %edi,%ebx
f0102ac3:	73 3b                	jae    f0102b00 <mem_init+0x17f3>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ac5:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102acb:	89 f0                	mov    %esi,%eax
f0102acd:	e8 16 e0 ff ff       	call   f0100ae8 <check_va2pa>
f0102ad2:	39 c3                	cmp    %eax,%ebx
f0102ad4:	75 08                	jne    f0102ade <mem_init+0x17d1>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ad6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102adc:	eb e3                	jmp    f0102ac1 <mem_init+0x17b4>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ade:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ae1:	8d 83 58 d9 fe ff    	lea    -0x126a8(%ebx),%eax
f0102ae7:	50                   	push   %eax
f0102ae8:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102aee:	50                   	push   %eax
f0102aef:	68 c3 02 00 00       	push   $0x2c3
f0102af4:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102afa:	50                   	push   %eax
f0102afb:	e8 99 d5 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b00:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f0102b05:	8b 7d c8             	mov    -0x38(%ebp),%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b08:	89 da                	mov    %ebx,%edx
f0102b0a:	89 f0                	mov    %esi,%eax
f0102b0c:	e8 d7 df ff ff       	call   f0100ae8 <check_va2pa>
f0102b11:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102b14:	39 c2                	cmp    %eax,%edx
f0102b16:	75 26                	jne    f0102b3e <mem_init+0x1831>
f0102b18:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b1e:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102b24:	75 e2                	jne    f0102b08 <mem_init+0x17fb>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b26:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b2b:	89 f0                	mov    %esi,%eax
f0102b2d:	e8 b6 df ff ff       	call   f0100ae8 <check_va2pa>
f0102b32:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b35:	75 29                	jne    f0102b60 <mem_init+0x1853>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b37:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b3c:	eb 6d                	jmp    f0102bab <mem_init+0x189e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b3e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b41:	8d 83 80 d9 fe ff    	lea    -0x12680(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102b4e:	50                   	push   %eax
f0102b4f:	68 c7 02 00 00       	push   $0x2c7
f0102b54:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102b5a:	50                   	push   %eax
f0102b5b:	e8 39 d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b63:	8d 83 c8 d9 fe ff    	lea    -0x12638(%ebx),%eax
f0102b69:	50                   	push   %eax
f0102b6a:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102b70:	50                   	push   %eax
f0102b71:	68 c8 02 00 00       	push   $0x2c8
f0102b76:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102b7c:	50                   	push   %eax
f0102b7d:	e8 17 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b82:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102b86:	74 52                	je     f0102bda <mem_init+0x18cd>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b88:	83 c0 01             	add    $0x1,%eax
f0102b8b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102b90:	0f 87 bb 00 00 00    	ja     f0102c51 <mem_init+0x1944>
		switch (i) {
f0102b96:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102b9b:	72 0e                	jb     f0102bab <mem_init+0x189e>
f0102b9d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102ba2:	76 de                	jbe    f0102b82 <mem_init+0x1875>
f0102ba4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ba9:	74 d7                	je     f0102b82 <mem_init+0x1875>
			if (i >= PDX(KERNBASE)) {
f0102bab:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102bb0:	77 4a                	ja     f0102bfc <mem_init+0x18ef>
				assert(pgdir[i] == 0);
f0102bb2:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102bb6:	74 d0                	je     f0102b88 <mem_init+0x187b>
f0102bb8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bbb:	8d 83 a4 dd fe ff    	lea    -0x1225c(%ebx),%eax
f0102bc1:	50                   	push   %eax
f0102bc2:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102bc8:	50                   	push   %eax
f0102bc9:	68 d7 02 00 00       	push   $0x2d7
f0102bce:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102bd4:	50                   	push   %eax
f0102bd5:	e8 bf d4 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102bda:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bdd:	8d 83 82 dd fe ff    	lea    -0x1227e(%ebx),%eax
f0102be3:	50                   	push   %eax
f0102be4:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102bea:	50                   	push   %eax
f0102beb:	68 d0 02 00 00       	push   $0x2d0
f0102bf0:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102bf6:	50                   	push   %eax
f0102bf7:	e8 9d d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bfc:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102bff:	f6 c2 01             	test   $0x1,%dl
f0102c02:	74 2b                	je     f0102c2f <mem_init+0x1922>
				assert(pgdir[i] & PTE_W);
f0102c04:	f6 c2 02             	test   $0x2,%dl
f0102c07:	0f 85 7b ff ff ff    	jne    f0102b88 <mem_init+0x187b>
f0102c0d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c10:	8d 83 93 dd fe ff    	lea    -0x1226d(%ebx),%eax
f0102c16:	50                   	push   %eax
f0102c17:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102c1d:	50                   	push   %eax
f0102c1e:	68 d5 02 00 00       	push   $0x2d5
f0102c23:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102c29:	50                   	push   %eax
f0102c2a:	e8 6a d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c32:	8d 83 82 dd fe ff    	lea    -0x1227e(%ebx),%eax
f0102c38:	50                   	push   %eax
f0102c39:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102c3f:	50                   	push   %eax
f0102c40:	68 d4 02 00 00       	push   $0x2d4
f0102c45:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102c4b:	50                   	push   %eax
f0102c4c:	e8 48 d4 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c51:	83 ec 0c             	sub    $0xc,%esp
f0102c54:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c57:	8d 87 f8 d9 fe ff    	lea    -0x12608(%edi),%eax
f0102c5d:	50                   	push   %eax
f0102c5e:	89 fb                	mov    %edi,%ebx
f0102c60:	e8 f2 04 00 00       	call   f0103157 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c65:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c6b:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c6d:	83 c4 10             	add    $0x10,%esp
f0102c70:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c75:	0f 86 44 02 00 00    	jbe    f0102ebf <mem_init+0x1bb2>
	return (physaddr_t)kva - KERNBASE;
f0102c7b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c80:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c83:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c88:	e8 d8 de ff ff       	call   f0100b65 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c8d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c90:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c93:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c98:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c9b:	83 ec 0c             	sub    $0xc,%esp
f0102c9e:	6a 00                	push   $0x0
f0102ca0:	e8 56 e3 ff ff       	call   f0100ffb <page_alloc>
f0102ca5:	89 c6                	mov    %eax,%esi
f0102ca7:	83 c4 10             	add    $0x10,%esp
f0102caa:	85 c0                	test   %eax,%eax
f0102cac:	0f 84 29 02 00 00    	je     f0102edb <mem_init+0x1bce>
	assert((pp1 = page_alloc(0)));
f0102cb2:	83 ec 0c             	sub    $0xc,%esp
f0102cb5:	6a 00                	push   $0x0
f0102cb7:	e8 3f e3 ff ff       	call   f0100ffb <page_alloc>
f0102cbc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102cbf:	83 c4 10             	add    $0x10,%esp
f0102cc2:	85 c0                	test   %eax,%eax
f0102cc4:	0f 84 33 02 00 00    	je     f0102efd <mem_init+0x1bf0>
	assert((pp2 = page_alloc(0)));
f0102cca:	83 ec 0c             	sub    $0xc,%esp
f0102ccd:	6a 00                	push   $0x0
f0102ccf:	e8 27 e3 ff ff       	call   f0100ffb <page_alloc>
f0102cd4:	89 c7                	mov    %eax,%edi
f0102cd6:	83 c4 10             	add    $0x10,%esp
f0102cd9:	85 c0                	test   %eax,%eax
f0102cdb:	0f 84 3e 02 00 00    	je     f0102f1f <mem_init+0x1c12>
	page_free(pp0);
f0102ce1:	83 ec 0c             	sub    $0xc,%esp
f0102ce4:	56                   	push   %esi
f0102ce5:	e8 99 e3 ff ff       	call   f0101083 <page_free>
	return (pp - pages) << PGSHIFT;
f0102cea:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ced:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102cf3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102cf6:	2b 08                	sub    (%eax),%ecx
f0102cf8:	89 c8                	mov    %ecx,%eax
f0102cfa:	c1 f8 03             	sar    $0x3,%eax
f0102cfd:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d00:	89 c1                	mov    %eax,%ecx
f0102d02:	c1 e9 0c             	shr    $0xc,%ecx
f0102d05:	83 c4 10             	add    $0x10,%esp
f0102d08:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d0e:	3b 0a                	cmp    (%edx),%ecx
f0102d10:	0f 83 2b 02 00 00    	jae    f0102f41 <mem_init+0x1c34>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d16:	83 ec 04             	sub    $0x4,%esp
f0102d19:	68 00 10 00 00       	push   $0x1000
f0102d1e:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102d20:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102d25:	50                   	push   %eax
f0102d26:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d29:	e8 2f 10 00 00       	call   f0103d5d <memset>
	return (pp - pages) << PGSHIFT;
f0102d2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d31:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d37:	89 f9                	mov    %edi,%ecx
f0102d39:	2b 08                	sub    (%eax),%ecx
f0102d3b:	89 c8                	mov    %ecx,%eax
f0102d3d:	c1 f8 03             	sar    $0x3,%eax
f0102d40:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d43:	89 c1                	mov    %eax,%ecx
f0102d45:	c1 e9 0c             	shr    $0xc,%ecx
f0102d48:	83 c4 10             	add    $0x10,%esp
f0102d4b:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d51:	3b 0a                	cmp    (%edx),%ecx
f0102d53:	0f 83 fe 01 00 00    	jae    f0102f57 <mem_init+0x1c4a>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d59:	83 ec 04             	sub    $0x4,%esp
f0102d5c:	68 00 10 00 00       	push   $0x1000
f0102d61:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d63:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102d68:	50                   	push   %eax
f0102d69:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d6c:	e8 ec 0f 00 00       	call   f0103d5d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d71:	6a 02                	push   $0x2
f0102d73:	68 00 10 00 00       	push   $0x1000
f0102d78:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102d7b:	53                   	push   %ebx
f0102d7c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d85:	ff 30                	pushl  (%eax)
f0102d87:	e8 dd e4 ff ff       	call   f0101269 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d8c:	83 c4 20             	add    $0x20,%esp
f0102d8f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d94:	0f 85 d3 01 00 00    	jne    f0102f6d <mem_init+0x1c60>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d9a:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102da1:	01 01 01 
f0102da4:	0f 85 e5 01 00 00    	jne    f0102f8f <mem_init+0x1c82>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102daa:	6a 02                	push   $0x2
f0102dac:	68 00 10 00 00       	push   $0x1000
f0102db1:	57                   	push   %edi
f0102db2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102db5:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102dbb:	ff 30                	pushl  (%eax)
f0102dbd:	e8 a7 e4 ff ff       	call   f0101269 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102dc2:	83 c4 10             	add    $0x10,%esp
f0102dc5:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102dcc:	02 02 02 
f0102dcf:	0f 85 dc 01 00 00    	jne    f0102fb1 <mem_init+0x1ca4>
	assert(pp2->pp_ref == 1);
f0102dd5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102dda:	0f 85 f3 01 00 00    	jne    f0102fd3 <mem_init+0x1cc6>
	assert(pp1->pp_ref == 0);
f0102de0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102de3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102de8:	0f 85 07 02 00 00    	jne    f0102ff5 <mem_init+0x1ce8>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102dee:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102df5:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102df8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dfb:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e01:	89 f9                	mov    %edi,%ecx
f0102e03:	2b 08                	sub    (%eax),%ecx
f0102e05:	89 c8                	mov    %ecx,%eax
f0102e07:	c1 f8 03             	sar    $0x3,%eax
f0102e0a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e0d:	89 c1                	mov    %eax,%ecx
f0102e0f:	c1 e9 0c             	shr    $0xc,%ecx
f0102e12:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102e18:	3b 0a                	cmp    (%edx),%ecx
f0102e1a:	0f 83 f7 01 00 00    	jae    f0103017 <mem_init+0x1d0a>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e20:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102e27:	03 03 03 
f0102e2a:	0f 85 fd 01 00 00    	jne    f010302d <mem_init+0x1d20>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e30:	83 ec 08             	sub    $0x8,%esp
f0102e33:	68 00 10 00 00       	push   $0x1000
f0102e38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e3b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e41:	ff 30                	pushl  (%eax)
f0102e43:	e8 d4 e3 ff ff       	call   f010121c <page_remove>
	assert(pp2->pp_ref == 0);
f0102e48:	83 c4 10             	add    $0x10,%esp
f0102e4b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e50:	0f 85 f9 01 00 00    	jne    f010304f <mem_init+0x1d42>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e56:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e59:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e5f:	8b 08                	mov    (%eax),%ecx
f0102e61:	8b 11                	mov    (%ecx),%edx
f0102e63:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e69:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e6f:	89 f7                	mov    %esi,%edi
f0102e71:	2b 38                	sub    (%eax),%edi
f0102e73:	89 f8                	mov    %edi,%eax
f0102e75:	c1 f8 03             	sar    $0x3,%eax
f0102e78:	c1 e0 0c             	shl    $0xc,%eax
f0102e7b:	39 c2                	cmp    %eax,%edx
f0102e7d:	0f 85 ee 01 00 00    	jne    f0103071 <mem_init+0x1d64>
	kern_pgdir[0] = 0;
f0102e83:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e89:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e8e:	0f 85 ff 01 00 00    	jne    f0103093 <mem_init+0x1d86>
	pp0->pp_ref = 0;
f0102e94:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e9a:	83 ec 0c             	sub    $0xc,%esp
f0102e9d:	56                   	push   %esi
f0102e9e:	e8 e0 e1 ff ff       	call   f0101083 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ea3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ea6:	8d 83 8c da fe ff    	lea    -0x12574(%ebx),%eax
f0102eac:	89 04 24             	mov    %eax,(%esp)
f0102eaf:	e8 a3 02 00 00       	call   f0103157 <cprintf>
}
f0102eb4:	83 c4 10             	add    $0x10,%esp
f0102eb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eba:	5b                   	pop    %ebx
f0102ebb:	5e                   	pop    %esi
f0102ebc:	5f                   	pop    %edi
f0102ebd:	5d                   	pop    %ebp
f0102ebe:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ebf:	50                   	push   %eax
f0102ec0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ec3:	8d 83 a8 d4 fe ff    	lea    -0x12b58(%ebx),%eax
f0102ec9:	50                   	push   %eax
f0102eca:	68 de 00 00 00       	push   $0xde
f0102ecf:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	e8 be d1 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102edb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ede:	8d 83 a0 db fe ff    	lea    -0x12460(%ebx),%eax
f0102ee4:	50                   	push   %eax
f0102ee5:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102eeb:	50                   	push   %eax
f0102eec:	68 97 03 00 00       	push   $0x397
f0102ef1:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102ef7:	50                   	push   %eax
f0102ef8:	e8 9c d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102efd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f00:	8d 83 b6 db fe ff    	lea    -0x1244a(%ebx),%eax
f0102f06:	50                   	push   %eax
f0102f07:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102f0d:	50                   	push   %eax
f0102f0e:	68 98 03 00 00       	push   $0x398
f0102f13:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102f19:	50                   	push   %eax
f0102f1a:	e8 7a d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102f1f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f22:	8d 83 cc db fe ff    	lea    -0x12434(%ebx),%eax
f0102f28:	50                   	push   %eax
f0102f29:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102f2f:	50                   	push   %eax
f0102f30:	68 99 03 00 00       	push   $0x399
f0102f35:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102f3b:	50                   	push   %eax
f0102f3c:	e8 58 d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f41:	50                   	push   %eax
f0102f42:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0102f48:	50                   	push   %eax
f0102f49:	6a 52                	push   $0x52
f0102f4b:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0102f51:	50                   	push   %eax
f0102f52:	e8 42 d1 ff ff       	call   f0100099 <_panic>
f0102f57:	50                   	push   %eax
f0102f58:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f0102f5e:	50                   	push   %eax
f0102f5f:	6a 52                	push   $0x52
f0102f61:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0102f67:	50                   	push   %eax
f0102f68:	e8 2c d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102f6d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f70:	8d 83 9d dc fe ff    	lea    -0x12363(%ebx),%eax
f0102f76:	50                   	push   %eax
f0102f77:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102f7d:	50                   	push   %eax
f0102f7e:	68 9e 03 00 00       	push   $0x39e
f0102f83:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102f89:	50                   	push   %eax
f0102f8a:	e8 0a d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f92:	8d 83 18 da fe ff    	lea    -0x125e8(%ebx),%eax
f0102f98:	50                   	push   %eax
f0102f99:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102f9f:	50                   	push   %eax
f0102fa0:	68 9f 03 00 00       	push   $0x39f
f0102fa5:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102fab:	50                   	push   %eax
f0102fac:	e8 e8 d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102fb1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fb4:	8d 83 3c da fe ff    	lea    -0x125c4(%ebx),%eax
f0102fba:	50                   	push   %eax
f0102fbb:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102fc1:	50                   	push   %eax
f0102fc2:	68 a1 03 00 00       	push   $0x3a1
f0102fc7:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102fcd:	50                   	push   %eax
f0102fce:	e8 c6 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102fd3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fd6:	8d 83 bf dc fe ff    	lea    -0x12341(%ebx),%eax
f0102fdc:	50                   	push   %eax
f0102fdd:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0102fe3:	50                   	push   %eax
f0102fe4:	68 a2 03 00 00       	push   $0x3a2
f0102fe9:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0102fef:	50                   	push   %eax
f0102ff0:	e8 a4 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102ff5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff8:	8d 83 29 dd fe ff    	lea    -0x122d7(%ebx),%eax
f0102ffe:	50                   	push   %eax
f0102fff:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0103005:	50                   	push   %eax
f0103006:	68 a3 03 00 00       	push   $0x3a3
f010300b:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0103011:	50                   	push   %eax
f0103012:	e8 82 d0 ff ff       	call   f0100099 <_panic>
f0103017:	50                   	push   %eax
f0103018:	8d 83 40 d3 fe ff    	lea    -0x12cc0(%ebx),%eax
f010301e:	50                   	push   %eax
f010301f:	6a 52                	push   $0x52
f0103021:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0103027:	50                   	push   %eax
f0103028:	e8 6c d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010302d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103030:	8d 83 60 da fe ff    	lea    -0x125a0(%ebx),%eax
f0103036:	50                   	push   %eax
f0103037:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010303d:	50                   	push   %eax
f010303e:	68 a5 03 00 00       	push   $0x3a5
f0103043:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f0103049:	50                   	push   %eax
f010304a:	e8 4a d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010304f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103052:	8d 83 f7 dc fe ff    	lea    -0x12309(%ebx),%eax
f0103058:	50                   	push   %eax
f0103059:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f010305f:	50                   	push   %eax
f0103060:	68 a7 03 00 00       	push   $0x3a7
f0103065:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010306b:	50                   	push   %eax
f010306c:	e8 28 d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103071:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103074:	8d 83 a4 d5 fe ff    	lea    -0x12a5c(%ebx),%eax
f010307a:	50                   	push   %eax
f010307b:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f0103081:	50                   	push   %eax
f0103082:	68 aa 03 00 00       	push   $0x3aa
f0103087:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f010308d:	50                   	push   %eax
f010308e:	e8 06 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103093:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103096:	8d 83 ae dc fe ff    	lea    -0x12352(%ebx),%eax
f010309c:	50                   	push   %eax
f010309d:	8d 83 de da fe ff    	lea    -0x12522(%ebx),%eax
f01030a3:	50                   	push   %eax
f01030a4:	68 ac 03 00 00       	push   $0x3ac
f01030a9:	8d 83 b8 da fe ff    	lea    -0x12548(%ebx),%eax
f01030af:	50                   	push   %eax
f01030b0:	e8 e4 cf ff ff       	call   f0100099 <_panic>

f01030b5 <tlb_invalidate>:
{
f01030b5:	55                   	push   %ebp
f01030b6:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01030b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030bb:	0f 01 38             	invlpg (%eax)
}
f01030be:	5d                   	pop    %ebp
f01030bf:	c3                   	ret    

f01030c0 <__x86.get_pc_thunk.dx>:
f01030c0:	8b 14 24             	mov    (%esp),%edx
f01030c3:	c3                   	ret    

f01030c4 <__x86.get_pc_thunk.cx>:
f01030c4:	8b 0c 24             	mov    (%esp),%ecx
f01030c7:	c3                   	ret    

f01030c8 <__x86.get_pc_thunk.si>:
f01030c8:	8b 34 24             	mov    (%esp),%esi
f01030cb:	c3                   	ret    

f01030cc <__x86.get_pc_thunk.di>:
f01030cc:	8b 3c 24             	mov    (%esp),%edi
f01030cf:	c3                   	ret    

f01030d0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01030d0:	55                   	push   %ebp
f01030d1:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d6:	ba 70 00 00 00       	mov    $0x70,%edx
f01030db:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030dc:	ba 71 00 00 00       	mov    $0x71,%edx
f01030e1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030e2:	0f b6 c0             	movzbl %al,%eax
}
f01030e5:	5d                   	pop    %ebp
f01030e6:	c3                   	ret    

f01030e7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030e7:	55                   	push   %ebp
f01030e8:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ed:	ba 70 00 00 00       	mov    $0x70,%edx
f01030f2:	ee                   	out    %al,(%dx)
f01030f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030f6:	ba 71 00 00 00       	mov    $0x71,%edx
f01030fb:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030fc:	5d                   	pop    %ebp
f01030fd:	c3                   	ret    

f01030fe <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030fe:	55                   	push   %ebp
f01030ff:	89 e5                	mov    %esp,%ebp
f0103101:	53                   	push   %ebx
f0103102:	83 ec 10             	sub    $0x10,%esp
f0103105:	e8 45 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010310a:	81 c3 fe 41 01 00    	add    $0x141fe,%ebx
	cputchar(ch);
f0103110:	ff 75 08             	pushl  0x8(%ebp)
f0103113:	e8 ae d5 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0103118:	83 c4 10             	add    $0x10,%esp
f010311b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010311e:	c9                   	leave  
f010311f:	c3                   	ret    

f0103120 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103120:	55                   	push   %ebp
f0103121:	89 e5                	mov    %esp,%ebp
f0103123:	53                   	push   %ebx
f0103124:	83 ec 14             	sub    $0x14,%esp
f0103127:	e8 23 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010312c:	81 c3 dc 41 01 00    	add    $0x141dc,%ebx
	int cnt = 0;
f0103132:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103139:	ff 75 0c             	pushl  0xc(%ebp)
f010313c:	ff 75 08             	pushl  0x8(%ebp)
f010313f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103142:	50                   	push   %eax
f0103143:	8d 83 f6 bd fe ff    	lea    -0x1420a(%ebx),%eax
f0103149:	50                   	push   %eax
f010314a:	e8 8d 04 00 00       	call   f01035dc <vprintfmt>
	return cnt;
}
f010314f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103152:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103155:	c9                   	leave  
f0103156:	c3                   	ret    

f0103157 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103157:	55                   	push   %ebp
f0103158:	89 e5                	mov    %esp,%ebp
f010315a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010315d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103160:	50                   	push   %eax
f0103161:	ff 75 08             	pushl  0x8(%ebp)
f0103164:	e8 b7 ff ff ff       	call   f0103120 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103169:	c9                   	leave  
f010316a:	c3                   	ret    

f010316b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010316b:	55                   	push   %ebp
f010316c:	89 e5                	mov    %esp,%ebp
f010316e:	57                   	push   %edi
f010316f:	56                   	push   %esi
f0103170:	53                   	push   %ebx
f0103171:	83 ec 14             	sub    $0x14,%esp
f0103174:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103177:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010317a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010317d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103180:	8b 32                	mov    (%edx),%esi
f0103182:	8b 01                	mov    (%ecx),%eax
f0103184:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103187:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010318e:	eb 2f                	jmp    f01031bf <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103190:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103193:	39 c6                	cmp    %eax,%esi
f0103195:	7f 49                	jg     f01031e0 <stab_binsearch+0x75>
f0103197:	0f b6 0a             	movzbl (%edx),%ecx
f010319a:	83 ea 0c             	sub    $0xc,%edx
f010319d:	39 f9                	cmp    %edi,%ecx
f010319f:	75 ef                	jne    f0103190 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01031a1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031a4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031a7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01031ab:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031ae:	73 35                	jae    f01031e5 <stab_binsearch+0x7a>
			*region_left = m;
f01031b0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031b3:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01031b5:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01031b8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01031bf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01031c2:	7f 4e                	jg     f0103212 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01031c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01031c7:	01 f0                	add    %esi,%eax
f01031c9:	89 c3                	mov    %eax,%ebx
f01031cb:	c1 eb 1f             	shr    $0x1f,%ebx
f01031ce:	01 c3                	add    %eax,%ebx
f01031d0:	d1 fb                	sar    %ebx
f01031d2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01031d5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031d8:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01031dc:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01031de:	eb b3                	jmp    f0103193 <stab_binsearch+0x28>
			l = true_m + 1;
f01031e0:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01031e3:	eb da                	jmp    f01031bf <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01031e5:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031e8:	76 14                	jbe    f01031fe <stab_binsearch+0x93>
			*region_right = m - 1;
f01031ea:	83 e8 01             	sub    $0x1,%eax
f01031ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031f0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01031f3:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01031f5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031fc:	eb c1                	jmp    f01031bf <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01031fe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103201:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103203:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103207:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0103209:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103210:	eb ad                	jmp    f01031bf <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103212:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103216:	74 16                	je     f010322e <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103218:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010321b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010321d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103220:	8b 0e                	mov    (%esi),%ecx
f0103222:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103225:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103228:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010322c:	eb 12                	jmp    f0103240 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f010322e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103231:	8b 00                	mov    (%eax),%eax
f0103233:	83 e8 01             	sub    $0x1,%eax
f0103236:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103239:	89 07                	mov    %eax,(%edi)
f010323b:	eb 16                	jmp    f0103253 <stab_binsearch+0xe8>
		     l--)
f010323d:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103240:	39 c1                	cmp    %eax,%ecx
f0103242:	7d 0a                	jge    f010324e <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103244:	0f b6 1a             	movzbl (%edx),%ebx
f0103247:	83 ea 0c             	sub    $0xc,%edx
f010324a:	39 fb                	cmp    %edi,%ebx
f010324c:	75 ef                	jne    f010323d <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f010324e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103251:	89 07                	mov    %eax,(%edi)
	}
}
f0103253:	83 c4 14             	add    $0x14,%esp
f0103256:	5b                   	pop    %ebx
f0103257:	5e                   	pop    %esi
f0103258:	5f                   	pop    %edi
f0103259:	5d                   	pop    %ebp
f010325a:	c3                   	ret    

f010325b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010325b:	55                   	push   %ebp
f010325c:	89 e5                	mov    %esp,%ebp
f010325e:	57                   	push   %edi
f010325f:	56                   	push   %esi
f0103260:	53                   	push   %ebx
f0103261:	83 ec 3c             	sub    $0x3c,%esp
f0103264:	e8 e6 ce ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103269:	81 c3 9f 40 01 00    	add    $0x1409f,%ebx
f010326f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103272:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103275:	8d 83 b2 dd fe ff    	lea    -0x1224e(%ebx),%eax
f010327b:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010327d:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103284:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103287:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010328e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103291:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103298:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010329e:	0f 86 2f 01 00 00    	jbe    f01033d3 <debuginfo_eip+0x178>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01032a4:	c7 c0 a5 bb 10 f0    	mov    $0xf010bba5,%eax
f01032aa:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f01032b0:	0f 86 00 02 00 00    	jbe    f01034b6 <debuginfo_eip+0x25b>
f01032b6:	c7 c0 97 d9 10 f0    	mov    $0xf010d997,%eax
f01032bc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01032c0:	0f 85 f7 01 00 00    	jne    f01034bd <debuginfo_eip+0x262>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01032c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01032cd:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f01032d3:	c7 c2 a4 bb 10 f0    	mov    $0xf010bba4,%edx
f01032d9:	29 c2                	sub    %eax,%edx
f01032db:	c1 fa 02             	sar    $0x2,%edx
f01032de:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032e4:	83 ea 01             	sub    $0x1,%edx
f01032e7:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032ea:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01032ed:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032f0:	83 ec 08             	sub    $0x8,%esp
f01032f3:	57                   	push   %edi
f01032f4:	6a 64                	push   $0x64
f01032f6:	e8 70 fe ff ff       	call   f010316b <stab_binsearch>
	if (lfile == 0)
f01032fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032fe:	83 c4 10             	add    $0x10,%esp
f0103301:	85 c0                	test   %eax,%eax
f0103303:	0f 84 bb 01 00 00    	je     f01034c4 <debuginfo_eip+0x269>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103309:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010330c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010330f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103312:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103315:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103318:	83 ec 08             	sub    $0x8,%esp
f010331b:	57                   	push   %edi
f010331c:	6a 24                	push   $0x24
f010331e:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f0103324:	e8 42 fe ff ff       	call   f010316b <stab_binsearch>

	if (lfun <= rfun) {
f0103329:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010332c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010332f:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103332:	83 c4 10             	add    $0x10,%esp
f0103335:	39 c8                	cmp    %ecx,%eax
f0103337:	0f 8f ae 00 00 00    	jg     f01033eb <debuginfo_eip+0x190>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010333d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103340:	c7 c1 d4 52 10 f0    	mov    $0xf01052d4,%ecx
f0103346:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0103349:	8b 11                	mov    (%ecx),%edx
f010334b:	89 55 c0             	mov    %edx,-0x40(%ebp)
f010334e:	c7 c2 97 d9 10 f0    	mov    $0xf010d997,%edx
f0103354:	81 ea a5 bb 10 f0    	sub    $0xf010bba5,%edx
f010335a:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f010335d:	73 0c                	jae    f010336b <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010335f:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103362:	81 c2 a5 bb 10 f0    	add    $0xf010bba5,%edx
f0103368:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010336b:	8b 51 08             	mov    0x8(%ecx),%edx
f010336e:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103371:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103373:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103376:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103379:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010337c:	83 ec 08             	sub    $0x8,%esp
f010337f:	6a 3a                	push   $0x3a
f0103381:	ff 76 08             	pushl  0x8(%esi)
f0103384:	e8 b8 09 00 00       	call   f0103d41 <strfind>
f0103389:	2b 46 08             	sub    0x8(%esi),%eax
f010338c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010338f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103392:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103395:	83 c4 08             	add    $0x8,%esp
f0103398:	57                   	push   %edi
f0103399:	6a 44                	push   $0x44
f010339b:	c7 c7 d4 52 10 f0    	mov    $0xf01052d4,%edi
f01033a1:	89 f8                	mov    %edi,%eax
f01033a3:	e8 c3 fd ff ff       	call   f010316b <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f01033a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033ab:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01033ae:	c1 e2 02             	shl    $0x2,%edx
f01033b1:	0f b7 4c 3a 06       	movzwl 0x6(%edx,%edi,1),%ecx
f01033b6:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01033b9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01033bc:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f01033c0:	83 c4 10             	add    $0x10,%esp
f01033c3:	c6 45 c0 00          	movb   $0x0,-0x40(%ebp)
f01033c7:	bf 01 00 00 00       	mov    $0x1,%edi
f01033cc:	89 75 0c             	mov    %esi,0xc(%ebp)
f01033cf:	89 ce                	mov    %ecx,%esi
f01033d1:	eb 34                	jmp    f0103407 <debuginfo_eip+0x1ac>
  	        panic("User address");
f01033d3:	83 ec 04             	sub    $0x4,%esp
f01033d6:	8d 83 bc dd fe ff    	lea    -0x12244(%ebx),%eax
f01033dc:	50                   	push   %eax
f01033dd:	6a 7f                	push   $0x7f
f01033df:	8d 83 c9 dd fe ff    	lea    -0x12237(%ebx),%eax
f01033e5:	50                   	push   %eax
f01033e6:	e8 ae cc ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01033eb:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01033ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01033f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033fa:	eb 80                	jmp    f010337c <debuginfo_eip+0x121>
f01033fc:	83 e8 01             	sub    $0x1,%eax
f01033ff:	83 ea 0c             	sub    $0xc,%edx
f0103402:	89 f9                	mov    %edi,%ecx
f0103404:	88 4d c0             	mov    %cl,-0x40(%ebp)
f0103407:	89 45 bc             	mov    %eax,-0x44(%ebp)
	while (lline >= lfile
f010340a:	39 c6                	cmp    %eax,%esi
f010340c:	7f 2a                	jg     f0103438 <debuginfo_eip+0x1dd>
f010340e:	89 55 c4             	mov    %edx,-0x3c(%ebp)
	       && stabs[lline].n_type != N_SOL
f0103411:	0f b6 0a             	movzbl (%edx),%ecx
f0103414:	80 f9 84             	cmp    $0x84,%cl
f0103417:	74 49                	je     f0103462 <debuginfo_eip+0x207>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103419:	80 f9 64             	cmp    $0x64,%cl
f010341c:	75 de                	jne    f01033fc <debuginfo_eip+0x1a1>
f010341e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103421:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0103425:	74 d5                	je     f01033fc <debuginfo_eip+0x1a1>
f0103427:	8b 75 0c             	mov    0xc(%ebp),%esi
f010342a:	80 7d c0 00          	cmpb   $0x0,-0x40(%ebp)
f010342e:	74 3b                	je     f010346b <debuginfo_eip+0x210>
f0103430:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103433:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103436:	eb 33                	jmp    f010346b <debuginfo_eip+0x210>
f0103438:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010343b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010343e:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103441:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103446:	39 fa                	cmp    %edi,%edx
f0103448:	0f 8d 82 00 00 00    	jge    f01034d0 <debuginfo_eip+0x275>
		for (lline = lfun + 1;
f010344e:	83 c2 01             	add    $0x1,%edx
f0103451:	89 d0                	mov    %edx,%eax
f0103453:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0103456:	c7 c2 d4 52 10 f0    	mov    $0xf01052d4,%edx
f010345c:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0103460:	eb 3b                	jmp    f010349d <debuginfo_eip+0x242>
f0103462:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103465:	80 7d c0 00          	cmpb   $0x0,-0x40(%ebp)
f0103469:	75 26                	jne    f0103491 <debuginfo_eip+0x236>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010346b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010346e:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f0103474:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103477:	c7 c0 97 d9 10 f0    	mov    $0xf010d997,%eax
f010347d:	81 e8 a5 bb 10 f0    	sub    $0xf010bba5,%eax
f0103483:	39 c2                	cmp    %eax,%edx
f0103485:	73 b4                	jae    f010343b <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103487:	81 c2 a5 bb 10 f0    	add    $0xf010bba5,%edx
f010348d:	89 16                	mov    %edx,(%esi)
f010348f:	eb aa                	jmp    f010343b <debuginfo_eip+0x1e0>
f0103491:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103494:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103497:	eb d2                	jmp    f010346b <debuginfo_eip+0x210>
			info->eip_fn_narg++;
f0103499:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f010349d:	39 c7                	cmp    %eax,%edi
f010349f:	7e 2a                	jle    f01034cb <debuginfo_eip+0x270>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01034a1:	0f b6 0a             	movzbl (%edx),%ecx
f01034a4:	83 c0 01             	add    $0x1,%eax
f01034a7:	83 c2 0c             	add    $0xc,%edx
f01034aa:	80 f9 a0             	cmp    $0xa0,%cl
f01034ad:	74 ea                	je     f0103499 <debuginfo_eip+0x23e>
	return 0;
f01034af:	b8 00 00 00 00       	mov    $0x0,%eax
f01034b4:	eb 1a                	jmp    f01034d0 <debuginfo_eip+0x275>
		return -1;
f01034b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034bb:	eb 13                	jmp    f01034d0 <debuginfo_eip+0x275>
f01034bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034c2:	eb 0c                	jmp    f01034d0 <debuginfo_eip+0x275>
		return -1;
f01034c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034c9:	eb 05                	jmp    f01034d0 <debuginfo_eip+0x275>
	return 0;
f01034cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034d3:	5b                   	pop    %ebx
f01034d4:	5e                   	pop    %esi
f01034d5:	5f                   	pop    %edi
f01034d6:	5d                   	pop    %ebp
f01034d7:	c3                   	ret    

f01034d8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01034d8:	55                   	push   %ebp
f01034d9:	89 e5                	mov    %esp,%ebp
f01034db:	57                   	push   %edi
f01034dc:	56                   	push   %esi
f01034dd:	53                   	push   %ebx
f01034de:	83 ec 2c             	sub    $0x2c,%esp
f01034e1:	e8 de fb ff ff       	call   f01030c4 <__x86.get_pc_thunk.cx>
f01034e6:	81 c1 22 3e 01 00    	add    $0x13e22,%ecx
f01034ec:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01034ef:	89 c7                	mov    %eax,%edi
f01034f1:	89 d6                	mov    %edx,%esi
f01034f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034f9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034fc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01034ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103502:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103507:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010350a:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010350d:	39 d3                	cmp    %edx,%ebx
f010350f:	72 09                	jb     f010351a <printnum+0x42>
f0103511:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103514:	0f 87 83 00 00 00    	ja     f010359d <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010351a:	83 ec 0c             	sub    $0xc,%esp
f010351d:	ff 75 18             	pushl  0x18(%ebp)
f0103520:	8b 45 14             	mov    0x14(%ebp),%eax
f0103523:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103526:	53                   	push   %ebx
f0103527:	ff 75 10             	pushl  0x10(%ebp)
f010352a:	83 ec 08             	sub    $0x8,%esp
f010352d:	ff 75 dc             	pushl  -0x24(%ebp)
f0103530:	ff 75 d8             	pushl  -0x28(%ebp)
f0103533:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103536:	ff 75 d0             	pushl  -0x30(%ebp)
f0103539:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010353c:	e8 1f 0a 00 00       	call   f0103f60 <__udivdi3>
f0103541:	83 c4 18             	add    $0x18,%esp
f0103544:	52                   	push   %edx
f0103545:	50                   	push   %eax
f0103546:	89 f2                	mov    %esi,%edx
f0103548:	89 f8                	mov    %edi,%eax
f010354a:	e8 89 ff ff ff       	call   f01034d8 <printnum>
f010354f:	83 c4 20             	add    $0x20,%esp
f0103552:	eb 13                	jmp    f0103567 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103554:	83 ec 08             	sub    $0x8,%esp
f0103557:	56                   	push   %esi
f0103558:	ff 75 18             	pushl  0x18(%ebp)
f010355b:	ff d7                	call   *%edi
f010355d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103560:	83 eb 01             	sub    $0x1,%ebx
f0103563:	85 db                	test   %ebx,%ebx
f0103565:	7f ed                	jg     f0103554 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103567:	83 ec 08             	sub    $0x8,%esp
f010356a:	56                   	push   %esi
f010356b:	83 ec 04             	sub    $0x4,%esp
f010356e:	ff 75 dc             	pushl  -0x24(%ebp)
f0103571:	ff 75 d8             	pushl  -0x28(%ebp)
f0103574:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103577:	ff 75 d0             	pushl  -0x30(%ebp)
f010357a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010357d:	89 f3                	mov    %esi,%ebx
f010357f:	e8 fc 0a 00 00       	call   f0104080 <__umoddi3>
f0103584:	83 c4 14             	add    $0x14,%esp
f0103587:	0f be 84 06 d7 dd fe 	movsbl -0x12229(%esi,%eax,1),%eax
f010358e:	ff 
f010358f:	50                   	push   %eax
f0103590:	ff d7                	call   *%edi
}
f0103592:	83 c4 10             	add    $0x10,%esp
f0103595:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103598:	5b                   	pop    %ebx
f0103599:	5e                   	pop    %esi
f010359a:	5f                   	pop    %edi
f010359b:	5d                   	pop    %ebp
f010359c:	c3                   	ret    
f010359d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01035a0:	eb be                	jmp    f0103560 <printnum+0x88>

f01035a2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01035a2:	55                   	push   %ebp
f01035a3:	89 e5                	mov    %esp,%ebp
f01035a5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01035a8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01035ac:	8b 10                	mov    (%eax),%edx
f01035ae:	3b 50 04             	cmp    0x4(%eax),%edx
f01035b1:	73 0a                	jae    f01035bd <sprintputch+0x1b>
		*b->buf++ = ch;
f01035b3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01035b6:	89 08                	mov    %ecx,(%eax)
f01035b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035bb:	88 02                	mov    %al,(%edx)
}
f01035bd:	5d                   	pop    %ebp
f01035be:	c3                   	ret    

f01035bf <printfmt>:
{
f01035bf:	55                   	push   %ebp
f01035c0:	89 e5                	mov    %esp,%ebp
f01035c2:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01035c5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01035c8:	50                   	push   %eax
f01035c9:	ff 75 10             	pushl  0x10(%ebp)
f01035cc:	ff 75 0c             	pushl  0xc(%ebp)
f01035cf:	ff 75 08             	pushl  0x8(%ebp)
f01035d2:	e8 05 00 00 00       	call   f01035dc <vprintfmt>
}
f01035d7:	83 c4 10             	add    $0x10,%esp
f01035da:	c9                   	leave  
f01035db:	c3                   	ret    

f01035dc <vprintfmt>:
{
f01035dc:	55                   	push   %ebp
f01035dd:	89 e5                	mov    %esp,%ebp
f01035df:	57                   	push   %edi
f01035e0:	56                   	push   %esi
f01035e1:	53                   	push   %ebx
f01035e2:	83 ec 2c             	sub    $0x2c,%esp
f01035e5:	e8 65 cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01035ea:	81 c3 1e 3d 01 00    	add    $0x13d1e,%ebx
f01035f0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035f3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01035f6:	e9 c3 03 00 00       	jmp    f01039be <.L35+0x48>
		padc = ' ';
f01035fb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01035ff:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103606:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010360d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103614:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103619:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010361c:	8d 47 01             	lea    0x1(%edi),%eax
f010361f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103622:	0f b6 17             	movzbl (%edi),%edx
f0103625:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103628:	3c 55                	cmp    $0x55,%al
f010362a:	0f 87 16 04 00 00    	ja     f0103a46 <.L22>
f0103630:	0f b6 c0             	movzbl %al,%eax
f0103633:	89 d9                	mov    %ebx,%ecx
f0103635:	03 8c 83 64 de fe ff 	add    -0x1219c(%ebx,%eax,4),%ecx
f010363c:	ff e1                	jmp    *%ecx

f010363e <.L69>:
f010363e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103641:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103645:	eb d5                	jmp    f010361c <vprintfmt+0x40>

f0103647 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103647:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010364a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010364e:	eb cc                	jmp    f010361c <vprintfmt+0x40>

f0103650 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0103650:	0f b6 d2             	movzbl %dl,%edx
f0103653:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103656:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010365b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010365e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103662:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103665:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103668:	83 f9 09             	cmp    $0x9,%ecx
f010366b:	77 55                	ja     f01036c2 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010366d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103670:	eb e9                	jmp    f010365b <.L29+0xb>

f0103672 <.L26>:
			precision = va_arg(ap, int);
f0103672:	8b 45 14             	mov    0x14(%ebp),%eax
f0103675:	8b 00                	mov    (%eax),%eax
f0103677:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010367a:	8b 45 14             	mov    0x14(%ebp),%eax
f010367d:	8d 40 04             	lea    0x4(%eax),%eax
f0103680:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103683:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103686:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010368a:	79 90                	jns    f010361c <vprintfmt+0x40>
				width = precision, precision = -1;
f010368c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010368f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103692:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103699:	eb 81                	jmp    f010361c <vprintfmt+0x40>

f010369b <.L27>:
f010369b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010369e:	85 c0                	test   %eax,%eax
f01036a0:	ba 00 00 00 00       	mov    $0x0,%edx
f01036a5:	0f 49 d0             	cmovns %eax,%edx
f01036a8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01036ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036ae:	e9 69 ff ff ff       	jmp    f010361c <vprintfmt+0x40>

f01036b3 <.L23>:
f01036b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01036b6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01036bd:	e9 5a ff ff ff       	jmp    f010361c <vprintfmt+0x40>
f01036c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01036c5:	eb bf                	jmp    f0103686 <.L26+0x14>

f01036c7 <.L33>:
			lflag++;
f01036c7:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01036cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01036ce:	e9 49 ff ff ff       	jmp    f010361c <vprintfmt+0x40>

f01036d3 <.L30>:
			putch(va_arg(ap, int), putdat);
f01036d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01036d6:	8d 78 04             	lea    0x4(%eax),%edi
f01036d9:	83 ec 08             	sub    $0x8,%esp
f01036dc:	56                   	push   %esi
f01036dd:	ff 30                	pushl  (%eax)
f01036df:	ff 55 08             	call   *0x8(%ebp)
			break;
f01036e2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01036e5:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01036e8:	e9 ce 02 00 00       	jmp    f01039bb <.L35+0x45>

f01036ed <.L32>:
			err = va_arg(ap, int);
f01036ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f0:	8d 78 04             	lea    0x4(%eax),%edi
f01036f3:	8b 00                	mov    (%eax),%eax
f01036f5:	99                   	cltd   
f01036f6:	31 d0                	xor    %edx,%eax
f01036f8:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01036fa:	83 f8 06             	cmp    $0x6,%eax
f01036fd:	7f 27                	jg     f0103726 <.L32+0x39>
f01036ff:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0103706:	85 d2                	test   %edx,%edx
f0103708:	74 1c                	je     f0103726 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010370a:	52                   	push   %edx
f010370b:	8d 83 f0 da fe ff    	lea    -0x12510(%ebx),%eax
f0103711:	50                   	push   %eax
f0103712:	56                   	push   %esi
f0103713:	ff 75 08             	pushl  0x8(%ebp)
f0103716:	e8 a4 fe ff ff       	call   f01035bf <printfmt>
f010371b:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010371e:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103721:	e9 95 02 00 00       	jmp    f01039bb <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103726:	50                   	push   %eax
f0103727:	8d 83 ef dd fe ff    	lea    -0x12211(%ebx),%eax
f010372d:	50                   	push   %eax
f010372e:	56                   	push   %esi
f010372f:	ff 75 08             	pushl  0x8(%ebp)
f0103732:	e8 88 fe ff ff       	call   f01035bf <printfmt>
f0103737:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010373a:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010373d:	e9 79 02 00 00       	jmp    f01039bb <.L35+0x45>

f0103742 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103742:	8b 45 14             	mov    0x14(%ebp),%eax
f0103745:	83 c0 04             	add    $0x4,%eax
f0103748:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010374b:	8b 45 14             	mov    0x14(%ebp),%eax
f010374e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103750:	85 ff                	test   %edi,%edi
f0103752:	8d 83 e8 dd fe ff    	lea    -0x12218(%ebx),%eax
f0103758:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010375b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010375f:	0f 8e b5 00 00 00    	jle    f010381a <.L36+0xd8>
f0103765:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103769:	75 08                	jne    f0103773 <.L36+0x31>
f010376b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010376e:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103771:	eb 6d                	jmp    f01037e0 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103773:	83 ec 08             	sub    $0x8,%esp
f0103776:	ff 75 cc             	pushl  -0x34(%ebp)
f0103779:	57                   	push   %edi
f010377a:	e8 7e 04 00 00       	call   f0103bfd <strnlen>
f010377f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103782:	29 c2                	sub    %eax,%edx
f0103784:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103787:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010378a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010378e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103791:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103794:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103796:	eb 10                	jmp    f01037a8 <.L36+0x66>
					putch(padc, putdat);
f0103798:	83 ec 08             	sub    $0x8,%esp
f010379b:	56                   	push   %esi
f010379c:	ff 75 e0             	pushl  -0x20(%ebp)
f010379f:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01037a2:	83 ef 01             	sub    $0x1,%edi
f01037a5:	83 c4 10             	add    $0x10,%esp
f01037a8:	85 ff                	test   %edi,%edi
f01037aa:	7f ec                	jg     f0103798 <.L36+0x56>
f01037ac:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01037af:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01037b2:	85 d2                	test   %edx,%edx
f01037b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01037b9:	0f 49 c2             	cmovns %edx,%eax
f01037bc:	29 c2                	sub    %eax,%edx
f01037be:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01037c1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01037c4:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01037c7:	eb 17                	jmp    f01037e0 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01037c9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01037cd:	75 30                	jne    f01037ff <.L36+0xbd>
					putch(ch, putdat);
f01037cf:	83 ec 08             	sub    $0x8,%esp
f01037d2:	ff 75 0c             	pushl  0xc(%ebp)
f01037d5:	50                   	push   %eax
f01037d6:	ff 55 08             	call   *0x8(%ebp)
f01037d9:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01037dc:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01037e0:	83 c7 01             	add    $0x1,%edi
f01037e3:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01037e7:	0f be c2             	movsbl %dl,%eax
f01037ea:	85 c0                	test   %eax,%eax
f01037ec:	74 52                	je     f0103840 <.L36+0xfe>
f01037ee:	85 f6                	test   %esi,%esi
f01037f0:	78 d7                	js     f01037c9 <.L36+0x87>
f01037f2:	83 ee 01             	sub    $0x1,%esi
f01037f5:	79 d2                	jns    f01037c9 <.L36+0x87>
f01037f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037fa:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01037fd:	eb 32                	jmp    f0103831 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01037ff:	0f be d2             	movsbl %dl,%edx
f0103802:	83 ea 20             	sub    $0x20,%edx
f0103805:	83 fa 5e             	cmp    $0x5e,%edx
f0103808:	76 c5                	jbe    f01037cf <.L36+0x8d>
					putch('?', putdat);
f010380a:	83 ec 08             	sub    $0x8,%esp
f010380d:	ff 75 0c             	pushl  0xc(%ebp)
f0103810:	6a 3f                	push   $0x3f
f0103812:	ff 55 08             	call   *0x8(%ebp)
f0103815:	83 c4 10             	add    $0x10,%esp
f0103818:	eb c2                	jmp    f01037dc <.L36+0x9a>
f010381a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010381d:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103820:	eb be                	jmp    f01037e0 <.L36+0x9e>
				putch(' ', putdat);
f0103822:	83 ec 08             	sub    $0x8,%esp
f0103825:	56                   	push   %esi
f0103826:	6a 20                	push   $0x20
f0103828:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010382b:	83 ef 01             	sub    $0x1,%edi
f010382e:	83 c4 10             	add    $0x10,%esp
f0103831:	85 ff                	test   %edi,%edi
f0103833:	7f ed                	jg     f0103822 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103835:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103838:	89 45 14             	mov    %eax,0x14(%ebp)
f010383b:	e9 7b 01 00 00       	jmp    f01039bb <.L35+0x45>
f0103840:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103843:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103846:	eb e9                	jmp    f0103831 <.L36+0xef>

f0103848 <.L31>:
f0103848:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010384b:	83 f9 01             	cmp    $0x1,%ecx
f010384e:	7e 40                	jle    f0103890 <.L31+0x48>
		return va_arg(*ap, long long);
f0103850:	8b 45 14             	mov    0x14(%ebp),%eax
f0103853:	8b 50 04             	mov    0x4(%eax),%edx
f0103856:	8b 00                	mov    (%eax),%eax
f0103858:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010385b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010385e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103861:	8d 40 08             	lea    0x8(%eax),%eax
f0103864:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103867:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010386b:	79 55                	jns    f01038c2 <.L31+0x7a>
				putch('-', putdat);
f010386d:	83 ec 08             	sub    $0x8,%esp
f0103870:	56                   	push   %esi
f0103871:	6a 2d                	push   $0x2d
f0103873:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103876:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103879:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010387c:	f7 da                	neg    %edx
f010387e:	83 d1 00             	adc    $0x0,%ecx
f0103881:	f7 d9                	neg    %ecx
f0103883:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103886:	b8 0a 00 00 00       	mov    $0xa,%eax
f010388b:	e9 10 01 00 00       	jmp    f01039a0 <.L35+0x2a>
	else if (lflag)
f0103890:	85 c9                	test   %ecx,%ecx
f0103892:	75 17                	jne    f01038ab <.L31+0x63>
		return va_arg(*ap, int);
f0103894:	8b 45 14             	mov    0x14(%ebp),%eax
f0103897:	8b 00                	mov    (%eax),%eax
f0103899:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010389c:	99                   	cltd   
f010389d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01038a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01038a3:	8d 40 04             	lea    0x4(%eax),%eax
f01038a6:	89 45 14             	mov    %eax,0x14(%ebp)
f01038a9:	eb bc                	jmp    f0103867 <.L31+0x1f>
		return va_arg(*ap, long);
f01038ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ae:	8b 00                	mov    (%eax),%eax
f01038b0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038b3:	99                   	cltd   
f01038b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01038b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ba:	8d 40 04             	lea    0x4(%eax),%eax
f01038bd:	89 45 14             	mov    %eax,0x14(%ebp)
f01038c0:	eb a5                	jmp    f0103867 <.L31+0x1f>
			num = getint(&ap, lflag);
f01038c2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01038c5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01038c8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038cd:	e9 ce 00 00 00       	jmp    f01039a0 <.L35+0x2a>

f01038d2 <.L37>:
f01038d2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01038d5:	83 f9 01             	cmp    $0x1,%ecx
f01038d8:	7e 18                	jle    f01038f2 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01038da:	8b 45 14             	mov    0x14(%ebp),%eax
f01038dd:	8b 10                	mov    (%eax),%edx
f01038df:	8b 48 04             	mov    0x4(%eax),%ecx
f01038e2:	8d 40 08             	lea    0x8(%eax),%eax
f01038e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038e8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038ed:	e9 ae 00 00 00       	jmp    f01039a0 <.L35+0x2a>
	else if (lflag)
f01038f2:	85 c9                	test   %ecx,%ecx
f01038f4:	75 1a                	jne    f0103910 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01038f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01038f9:	8b 10                	mov    (%eax),%edx
f01038fb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103900:	8d 40 04             	lea    0x4(%eax),%eax
f0103903:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103906:	b8 0a 00 00 00       	mov    $0xa,%eax
f010390b:	e9 90 00 00 00       	jmp    f01039a0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103910:	8b 45 14             	mov    0x14(%ebp),%eax
f0103913:	8b 10                	mov    (%eax),%edx
f0103915:	b9 00 00 00 00       	mov    $0x0,%ecx
f010391a:	8d 40 04             	lea    0x4(%eax),%eax
f010391d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103920:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103925:	eb 79                	jmp    f01039a0 <.L35+0x2a>

f0103927 <.L34>:
f0103927:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010392a:	83 f9 01             	cmp    $0x1,%ecx
f010392d:	7e 15                	jle    f0103944 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010392f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103932:	8b 10                	mov    (%eax),%edx
f0103934:	8b 48 04             	mov    0x4(%eax),%ecx
f0103937:	8d 40 08             	lea    0x8(%eax),%eax
f010393a:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f010393d:	b8 08 00 00 00       	mov    $0x8,%eax
f0103942:	eb 5c                	jmp    f01039a0 <.L35+0x2a>
	else if (lflag)
f0103944:	85 c9                	test   %ecx,%ecx
f0103946:	75 17                	jne    f010395f <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0103948:	8b 45 14             	mov    0x14(%ebp),%eax
f010394b:	8b 10                	mov    (%eax),%edx
f010394d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103952:	8d 40 04             	lea    0x4(%eax),%eax
f0103955:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f0103958:	b8 08 00 00 00       	mov    $0x8,%eax
f010395d:	eb 41                	jmp    f01039a0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010395f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103962:	8b 10                	mov    (%eax),%edx
f0103964:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103969:	8d 40 04             	lea    0x4(%eax),%eax
f010396c:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f010396f:	b8 08 00 00 00       	mov    $0x8,%eax
f0103974:	eb 2a                	jmp    f01039a0 <.L35+0x2a>

f0103976 <.L35>:
			putch('0', putdat);
f0103976:	83 ec 08             	sub    $0x8,%esp
f0103979:	56                   	push   %esi
f010397a:	6a 30                	push   $0x30
f010397c:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010397f:	83 c4 08             	add    $0x8,%esp
f0103982:	56                   	push   %esi
f0103983:	6a 78                	push   $0x78
f0103985:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103988:	8b 45 14             	mov    0x14(%ebp),%eax
f010398b:	8b 10                	mov    (%eax),%edx
f010398d:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103992:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103995:	8d 40 04             	lea    0x4(%eax),%eax
f0103998:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010399b:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01039a0:	83 ec 0c             	sub    $0xc,%esp
f01039a3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01039a7:	57                   	push   %edi
f01039a8:	ff 75 e0             	pushl  -0x20(%ebp)
f01039ab:	50                   	push   %eax
f01039ac:	51                   	push   %ecx
f01039ad:	52                   	push   %edx
f01039ae:	89 f2                	mov    %esi,%edx
f01039b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b3:	e8 20 fb ff ff       	call   f01034d8 <printnum>
			break;
f01039b8:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01039bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01039be:	83 c7 01             	add    $0x1,%edi
f01039c1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01039c5:	83 f8 25             	cmp    $0x25,%eax
f01039c8:	0f 84 2d fc ff ff    	je     f01035fb <vprintfmt+0x1f>
			if (ch == '\0')
f01039ce:	85 c0                	test   %eax,%eax
f01039d0:	0f 84 91 00 00 00    	je     f0103a67 <.L22+0x21>
			putch(ch, putdat);
f01039d6:	83 ec 08             	sub    $0x8,%esp
f01039d9:	56                   	push   %esi
f01039da:	50                   	push   %eax
f01039db:	ff 55 08             	call   *0x8(%ebp)
f01039de:	83 c4 10             	add    $0x10,%esp
f01039e1:	eb db                	jmp    f01039be <.L35+0x48>

f01039e3 <.L38>:
f01039e3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01039e6:	83 f9 01             	cmp    $0x1,%ecx
f01039e9:	7e 15                	jle    f0103a00 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01039eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ee:	8b 10                	mov    (%eax),%edx
f01039f0:	8b 48 04             	mov    0x4(%eax),%ecx
f01039f3:	8d 40 08             	lea    0x8(%eax),%eax
f01039f6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039f9:	b8 10 00 00 00       	mov    $0x10,%eax
f01039fe:	eb a0                	jmp    f01039a0 <.L35+0x2a>
	else if (lflag)
f0103a00:	85 c9                	test   %ecx,%ecx
f0103a02:	75 17                	jne    f0103a1b <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103a04:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a07:	8b 10                	mov    (%eax),%edx
f0103a09:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a0e:	8d 40 04             	lea    0x4(%eax),%eax
f0103a11:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103a14:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a19:	eb 85                	jmp    f01039a0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103a1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a1e:	8b 10                	mov    (%eax),%edx
f0103a20:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a25:	8d 40 04             	lea    0x4(%eax),%eax
f0103a28:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103a2b:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a30:	e9 6b ff ff ff       	jmp    f01039a0 <.L35+0x2a>

f0103a35 <.L25>:
			putch(ch, putdat);
f0103a35:	83 ec 08             	sub    $0x8,%esp
f0103a38:	56                   	push   %esi
f0103a39:	6a 25                	push   $0x25
f0103a3b:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103a3e:	83 c4 10             	add    $0x10,%esp
f0103a41:	e9 75 ff ff ff       	jmp    f01039bb <.L35+0x45>

f0103a46 <.L22>:
			putch('%', putdat);
f0103a46:	83 ec 08             	sub    $0x8,%esp
f0103a49:	56                   	push   %esi
f0103a4a:	6a 25                	push   $0x25
f0103a4c:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103a4f:	83 c4 10             	add    $0x10,%esp
f0103a52:	89 f8                	mov    %edi,%eax
f0103a54:	eb 03                	jmp    f0103a59 <.L22+0x13>
f0103a56:	83 e8 01             	sub    $0x1,%eax
f0103a59:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103a5d:	75 f7                	jne    f0103a56 <.L22+0x10>
f0103a5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a62:	e9 54 ff ff ff       	jmp    f01039bb <.L35+0x45>
}
f0103a67:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a6a:	5b                   	pop    %ebx
f0103a6b:	5e                   	pop    %esi
f0103a6c:	5f                   	pop    %edi
f0103a6d:	5d                   	pop    %ebp
f0103a6e:	c3                   	ret    

f0103a6f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103a6f:	55                   	push   %ebp
f0103a70:	89 e5                	mov    %esp,%ebp
f0103a72:	53                   	push   %ebx
f0103a73:	83 ec 14             	sub    $0x14,%esp
f0103a76:	e8 d4 c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a7b:	81 c3 8d 38 01 00    	add    $0x1388d,%ebx
f0103a81:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a84:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103a87:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a8a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103a8e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103a91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a98:	85 c0                	test   %eax,%eax
f0103a9a:	74 2b                	je     f0103ac7 <vsnprintf+0x58>
f0103a9c:	85 d2                	test   %edx,%edx
f0103a9e:	7e 27                	jle    f0103ac7 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103aa0:	ff 75 14             	pushl  0x14(%ebp)
f0103aa3:	ff 75 10             	pushl  0x10(%ebp)
f0103aa6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103aa9:	50                   	push   %eax
f0103aaa:	8d 83 9a c2 fe ff    	lea    -0x13d66(%ebx),%eax
f0103ab0:	50                   	push   %eax
f0103ab1:	e8 26 fb ff ff       	call   f01035dc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103ab6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103ab9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103abc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103abf:	83 c4 10             	add    $0x10,%esp
}
f0103ac2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103ac5:	c9                   	leave  
f0103ac6:	c3                   	ret    
		return -E_INVAL;
f0103ac7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103acc:	eb f4                	jmp    f0103ac2 <vsnprintf+0x53>

f0103ace <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103ace:	55                   	push   %ebp
f0103acf:	89 e5                	mov    %esp,%ebp
f0103ad1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103ad4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103ad7:	50                   	push   %eax
f0103ad8:	ff 75 10             	pushl  0x10(%ebp)
f0103adb:	ff 75 0c             	pushl  0xc(%ebp)
f0103ade:	ff 75 08             	pushl  0x8(%ebp)
f0103ae1:	e8 89 ff ff ff       	call   f0103a6f <vsnprintf>
	va_end(ap);

	return rc;
}
f0103ae6:	c9                   	leave  
f0103ae7:	c3                   	ret    

f0103ae8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103ae8:	55                   	push   %ebp
f0103ae9:	89 e5                	mov    %esp,%ebp
f0103aeb:	57                   	push   %edi
f0103aec:	56                   	push   %esi
f0103aed:	53                   	push   %ebx
f0103aee:	83 ec 1c             	sub    $0x1c,%esp
f0103af1:	e8 59 c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103af6:	81 c3 12 38 01 00    	add    $0x13812,%ebx
f0103afc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103aff:	85 c0                	test   %eax,%eax
f0103b01:	74 13                	je     f0103b16 <readline+0x2e>
		cprintf("%s", prompt);
f0103b03:	83 ec 08             	sub    $0x8,%esp
f0103b06:	50                   	push   %eax
f0103b07:	8d 83 f0 da fe ff    	lea    -0x12510(%ebx),%eax
f0103b0d:	50                   	push   %eax
f0103b0e:	e8 44 f6 ff ff       	call   f0103157 <cprintf>
f0103b13:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103b16:	83 ec 0c             	sub    $0xc,%esp
f0103b19:	6a 00                	push   $0x0
f0103b1b:	e8 c7 cb ff ff       	call   f01006e7 <iscons>
f0103b20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b23:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103b26:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b2b:	eb 46                	jmp    f0103b73 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103b2d:	83 ec 08             	sub    $0x8,%esp
f0103b30:	50                   	push   %eax
f0103b31:	8d 83 bc df fe ff    	lea    -0x12044(%ebx),%eax
f0103b37:	50                   	push   %eax
f0103b38:	e8 1a f6 ff ff       	call   f0103157 <cprintf>
			return NULL;
f0103b3d:	83 c4 10             	add    $0x10,%esp
f0103b40:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103b45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b48:	5b                   	pop    %ebx
f0103b49:	5e                   	pop    %esi
f0103b4a:	5f                   	pop    %edi
f0103b4b:	5d                   	pop    %ebp
f0103b4c:	c3                   	ret    
			if (echoing)
f0103b4d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b51:	75 05                	jne    f0103b58 <readline+0x70>
			i--;
f0103b53:	83 ef 01             	sub    $0x1,%edi
f0103b56:	eb 1b                	jmp    f0103b73 <readline+0x8b>
				cputchar('\b');
f0103b58:	83 ec 0c             	sub    $0xc,%esp
f0103b5b:	6a 08                	push   $0x8
f0103b5d:	e8 64 cb ff ff       	call   f01006c6 <cputchar>
f0103b62:	83 c4 10             	add    $0x10,%esp
f0103b65:	eb ec                	jmp    f0103b53 <readline+0x6b>
			buf[i++] = c;
f0103b67:	89 f0                	mov    %esi,%eax
f0103b69:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0103b70:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103b73:	e8 5e cb ff ff       	call   f01006d6 <getchar>
f0103b78:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103b7a:	85 c0                	test   %eax,%eax
f0103b7c:	78 af                	js     f0103b2d <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103b7e:	83 f8 08             	cmp    $0x8,%eax
f0103b81:	0f 94 c2             	sete   %dl
f0103b84:	83 f8 7f             	cmp    $0x7f,%eax
f0103b87:	0f 94 c0             	sete   %al
f0103b8a:	08 c2                	or     %al,%dl
f0103b8c:	74 04                	je     f0103b92 <readline+0xaa>
f0103b8e:	85 ff                	test   %edi,%edi
f0103b90:	7f bb                	jg     f0103b4d <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103b92:	83 fe 1f             	cmp    $0x1f,%esi
f0103b95:	7e 1c                	jle    f0103bb3 <readline+0xcb>
f0103b97:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103b9d:	7f 14                	jg     f0103bb3 <readline+0xcb>
			if (echoing)
f0103b9f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103ba3:	74 c2                	je     f0103b67 <readline+0x7f>
				cputchar(c);
f0103ba5:	83 ec 0c             	sub    $0xc,%esp
f0103ba8:	56                   	push   %esi
f0103ba9:	e8 18 cb ff ff       	call   f01006c6 <cputchar>
f0103bae:	83 c4 10             	add    $0x10,%esp
f0103bb1:	eb b4                	jmp    f0103b67 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103bb3:	83 fe 0a             	cmp    $0xa,%esi
f0103bb6:	74 05                	je     f0103bbd <readline+0xd5>
f0103bb8:	83 fe 0d             	cmp    $0xd,%esi
f0103bbb:	75 b6                	jne    f0103b73 <readline+0x8b>
			if (echoing)
f0103bbd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103bc1:	75 13                	jne    f0103bd6 <readline+0xee>
			buf[i] = 0;
f0103bc3:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0103bca:	00 
			return buf;
f0103bcb:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0103bd1:	e9 6f ff ff ff       	jmp    f0103b45 <readline+0x5d>
				cputchar('\n');
f0103bd6:	83 ec 0c             	sub    $0xc,%esp
f0103bd9:	6a 0a                	push   $0xa
f0103bdb:	e8 e6 ca ff ff       	call   f01006c6 <cputchar>
f0103be0:	83 c4 10             	add    $0x10,%esp
f0103be3:	eb de                	jmp    f0103bc3 <readline+0xdb>

f0103be5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103be5:	55                   	push   %ebp
f0103be6:	89 e5                	mov    %esp,%ebp
f0103be8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103beb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bf0:	eb 03                	jmp    f0103bf5 <strlen+0x10>
		n++;
f0103bf2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103bf5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103bf9:	75 f7                	jne    f0103bf2 <strlen+0xd>
	return n;
}
f0103bfb:	5d                   	pop    %ebp
f0103bfc:	c3                   	ret    

f0103bfd <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103bfd:	55                   	push   %ebp
f0103bfe:	89 e5                	mov    %esp,%ebp
f0103c00:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c03:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103c06:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c0b:	eb 03                	jmp    f0103c10 <strnlen+0x13>
		n++;
f0103c0d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103c10:	39 d0                	cmp    %edx,%eax
f0103c12:	74 06                	je     f0103c1a <strnlen+0x1d>
f0103c14:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103c18:	75 f3                	jne    f0103c0d <strnlen+0x10>
	return n;
}
f0103c1a:	5d                   	pop    %ebp
f0103c1b:	c3                   	ret    

f0103c1c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103c1c:	55                   	push   %ebp
f0103c1d:	89 e5                	mov    %esp,%ebp
f0103c1f:	53                   	push   %ebx
f0103c20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103c26:	89 c2                	mov    %eax,%edx
f0103c28:	83 c1 01             	add    $0x1,%ecx
f0103c2b:	83 c2 01             	add    $0x1,%edx
f0103c2e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103c32:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103c35:	84 db                	test   %bl,%bl
f0103c37:	75 ef                	jne    f0103c28 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103c39:	5b                   	pop    %ebx
f0103c3a:	5d                   	pop    %ebp
f0103c3b:	c3                   	ret    

f0103c3c <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103c3c:	55                   	push   %ebp
f0103c3d:	89 e5                	mov    %esp,%ebp
f0103c3f:	53                   	push   %ebx
f0103c40:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103c43:	53                   	push   %ebx
f0103c44:	e8 9c ff ff ff       	call   f0103be5 <strlen>
f0103c49:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103c4c:	ff 75 0c             	pushl  0xc(%ebp)
f0103c4f:	01 d8                	add    %ebx,%eax
f0103c51:	50                   	push   %eax
f0103c52:	e8 c5 ff ff ff       	call   f0103c1c <strcpy>
	return dst;
}
f0103c57:	89 d8                	mov    %ebx,%eax
f0103c59:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c5c:	c9                   	leave  
f0103c5d:	c3                   	ret    

f0103c5e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103c5e:	55                   	push   %ebp
f0103c5f:	89 e5                	mov    %esp,%ebp
f0103c61:	56                   	push   %esi
f0103c62:	53                   	push   %ebx
f0103c63:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c66:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c69:	89 f3                	mov    %esi,%ebx
f0103c6b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103c6e:	89 f2                	mov    %esi,%edx
f0103c70:	eb 0f                	jmp    f0103c81 <strncpy+0x23>
		*dst++ = *src;
f0103c72:	83 c2 01             	add    $0x1,%edx
f0103c75:	0f b6 01             	movzbl (%ecx),%eax
f0103c78:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103c7b:	80 39 01             	cmpb   $0x1,(%ecx)
f0103c7e:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103c81:	39 da                	cmp    %ebx,%edx
f0103c83:	75 ed                	jne    f0103c72 <strncpy+0x14>
	}
	return ret;
}
f0103c85:	89 f0                	mov    %esi,%eax
f0103c87:	5b                   	pop    %ebx
f0103c88:	5e                   	pop    %esi
f0103c89:	5d                   	pop    %ebp
f0103c8a:	c3                   	ret    

f0103c8b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103c8b:	55                   	push   %ebp
f0103c8c:	89 e5                	mov    %esp,%ebp
f0103c8e:	56                   	push   %esi
f0103c8f:	53                   	push   %ebx
f0103c90:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c93:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c96:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c99:	89 f0                	mov    %esi,%eax
f0103c9b:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c9f:	85 c9                	test   %ecx,%ecx
f0103ca1:	75 0b                	jne    f0103cae <strlcpy+0x23>
f0103ca3:	eb 17                	jmp    f0103cbc <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103ca5:	83 c2 01             	add    $0x1,%edx
f0103ca8:	83 c0 01             	add    $0x1,%eax
f0103cab:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103cae:	39 d8                	cmp    %ebx,%eax
f0103cb0:	74 07                	je     f0103cb9 <strlcpy+0x2e>
f0103cb2:	0f b6 0a             	movzbl (%edx),%ecx
f0103cb5:	84 c9                	test   %cl,%cl
f0103cb7:	75 ec                	jne    f0103ca5 <strlcpy+0x1a>
		*dst = '\0';
f0103cb9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103cbc:	29 f0                	sub    %esi,%eax
}
f0103cbe:	5b                   	pop    %ebx
f0103cbf:	5e                   	pop    %esi
f0103cc0:	5d                   	pop    %ebp
f0103cc1:	c3                   	ret    

f0103cc2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103cc2:	55                   	push   %ebp
f0103cc3:	89 e5                	mov    %esp,%ebp
f0103cc5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103cc8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103ccb:	eb 06                	jmp    f0103cd3 <strcmp+0x11>
		p++, q++;
f0103ccd:	83 c1 01             	add    $0x1,%ecx
f0103cd0:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103cd3:	0f b6 01             	movzbl (%ecx),%eax
f0103cd6:	84 c0                	test   %al,%al
f0103cd8:	74 04                	je     f0103cde <strcmp+0x1c>
f0103cda:	3a 02                	cmp    (%edx),%al
f0103cdc:	74 ef                	je     f0103ccd <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103cde:	0f b6 c0             	movzbl %al,%eax
f0103ce1:	0f b6 12             	movzbl (%edx),%edx
f0103ce4:	29 d0                	sub    %edx,%eax
}
f0103ce6:	5d                   	pop    %ebp
f0103ce7:	c3                   	ret    

f0103ce8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103ce8:	55                   	push   %ebp
f0103ce9:	89 e5                	mov    %esp,%ebp
f0103ceb:	53                   	push   %ebx
f0103cec:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cef:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cf2:	89 c3                	mov    %eax,%ebx
f0103cf4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103cf7:	eb 06                	jmp    f0103cff <strncmp+0x17>
		n--, p++, q++;
f0103cf9:	83 c0 01             	add    $0x1,%eax
f0103cfc:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103cff:	39 d8                	cmp    %ebx,%eax
f0103d01:	74 16                	je     f0103d19 <strncmp+0x31>
f0103d03:	0f b6 08             	movzbl (%eax),%ecx
f0103d06:	84 c9                	test   %cl,%cl
f0103d08:	74 04                	je     f0103d0e <strncmp+0x26>
f0103d0a:	3a 0a                	cmp    (%edx),%cl
f0103d0c:	74 eb                	je     f0103cf9 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103d0e:	0f b6 00             	movzbl (%eax),%eax
f0103d11:	0f b6 12             	movzbl (%edx),%edx
f0103d14:	29 d0                	sub    %edx,%eax
}
f0103d16:	5b                   	pop    %ebx
f0103d17:	5d                   	pop    %ebp
f0103d18:	c3                   	ret    
		return 0;
f0103d19:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d1e:	eb f6                	jmp    f0103d16 <strncmp+0x2e>

f0103d20 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103d20:	55                   	push   %ebp
f0103d21:	89 e5                	mov    %esp,%ebp
f0103d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d26:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103d2a:	0f b6 10             	movzbl (%eax),%edx
f0103d2d:	84 d2                	test   %dl,%dl
f0103d2f:	74 09                	je     f0103d3a <strchr+0x1a>
		if (*s == c)
f0103d31:	38 ca                	cmp    %cl,%dl
f0103d33:	74 0a                	je     f0103d3f <strchr+0x1f>
	for (; *s; s++)
f0103d35:	83 c0 01             	add    $0x1,%eax
f0103d38:	eb f0                	jmp    f0103d2a <strchr+0xa>
			return (char *) s;
	return 0;
f0103d3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d3f:	5d                   	pop    %ebp
f0103d40:	c3                   	ret    

f0103d41 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103d41:	55                   	push   %ebp
f0103d42:	89 e5                	mov    %esp,%ebp
f0103d44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d47:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103d4b:	eb 03                	jmp    f0103d50 <strfind+0xf>
f0103d4d:	83 c0 01             	add    $0x1,%eax
f0103d50:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103d53:	38 ca                	cmp    %cl,%dl
f0103d55:	74 04                	je     f0103d5b <strfind+0x1a>
f0103d57:	84 d2                	test   %dl,%dl
f0103d59:	75 f2                	jne    f0103d4d <strfind+0xc>
			break;
	return (char *) s;
}
f0103d5b:	5d                   	pop    %ebp
f0103d5c:	c3                   	ret    

f0103d5d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103d5d:	55                   	push   %ebp
f0103d5e:	89 e5                	mov    %esp,%ebp
f0103d60:	57                   	push   %edi
f0103d61:	56                   	push   %esi
f0103d62:	53                   	push   %ebx
f0103d63:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103d66:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103d69:	85 c9                	test   %ecx,%ecx
f0103d6b:	74 13                	je     f0103d80 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103d6d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103d73:	75 05                	jne    f0103d7a <memset+0x1d>
f0103d75:	f6 c1 03             	test   $0x3,%cl
f0103d78:	74 0d                	je     f0103d87 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103d7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d7d:	fc                   	cld    
f0103d7e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103d80:	89 f8                	mov    %edi,%eax
f0103d82:	5b                   	pop    %ebx
f0103d83:	5e                   	pop    %esi
f0103d84:	5f                   	pop    %edi
f0103d85:	5d                   	pop    %ebp
f0103d86:	c3                   	ret    
		c &= 0xFF;
f0103d87:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103d8b:	89 d3                	mov    %edx,%ebx
f0103d8d:	c1 e3 08             	shl    $0x8,%ebx
f0103d90:	89 d0                	mov    %edx,%eax
f0103d92:	c1 e0 18             	shl    $0x18,%eax
f0103d95:	89 d6                	mov    %edx,%esi
f0103d97:	c1 e6 10             	shl    $0x10,%esi
f0103d9a:	09 f0                	or     %esi,%eax
f0103d9c:	09 c2                	or     %eax,%edx
f0103d9e:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103da0:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103da3:	89 d0                	mov    %edx,%eax
f0103da5:	fc                   	cld    
f0103da6:	f3 ab                	rep stos %eax,%es:(%edi)
f0103da8:	eb d6                	jmp    f0103d80 <memset+0x23>

f0103daa <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103daa:	55                   	push   %ebp
f0103dab:	89 e5                	mov    %esp,%ebp
f0103dad:	57                   	push   %edi
f0103dae:	56                   	push   %esi
f0103daf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103db2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103db5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103db8:	39 c6                	cmp    %eax,%esi
f0103dba:	73 35                	jae    f0103df1 <memmove+0x47>
f0103dbc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103dbf:	39 c2                	cmp    %eax,%edx
f0103dc1:	76 2e                	jbe    f0103df1 <memmove+0x47>
		s += n;
		d += n;
f0103dc3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103dc6:	89 d6                	mov    %edx,%esi
f0103dc8:	09 fe                	or     %edi,%esi
f0103dca:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103dd0:	74 0c                	je     f0103dde <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103dd2:	83 ef 01             	sub    $0x1,%edi
f0103dd5:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103dd8:	fd                   	std    
f0103dd9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103ddb:	fc                   	cld    
f0103ddc:	eb 21                	jmp    f0103dff <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103dde:	f6 c1 03             	test   $0x3,%cl
f0103de1:	75 ef                	jne    f0103dd2 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103de3:	83 ef 04             	sub    $0x4,%edi
f0103de6:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103de9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103dec:	fd                   	std    
f0103ded:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103def:	eb ea                	jmp    f0103ddb <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103df1:	89 f2                	mov    %esi,%edx
f0103df3:	09 c2                	or     %eax,%edx
f0103df5:	f6 c2 03             	test   $0x3,%dl
f0103df8:	74 09                	je     f0103e03 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103dfa:	89 c7                	mov    %eax,%edi
f0103dfc:	fc                   	cld    
f0103dfd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103dff:	5e                   	pop    %esi
f0103e00:	5f                   	pop    %edi
f0103e01:	5d                   	pop    %ebp
f0103e02:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103e03:	f6 c1 03             	test   $0x3,%cl
f0103e06:	75 f2                	jne    f0103dfa <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103e08:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103e0b:	89 c7                	mov    %eax,%edi
f0103e0d:	fc                   	cld    
f0103e0e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103e10:	eb ed                	jmp    f0103dff <memmove+0x55>

f0103e12 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103e12:	55                   	push   %ebp
f0103e13:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103e15:	ff 75 10             	pushl  0x10(%ebp)
f0103e18:	ff 75 0c             	pushl  0xc(%ebp)
f0103e1b:	ff 75 08             	pushl  0x8(%ebp)
f0103e1e:	e8 87 ff ff ff       	call   f0103daa <memmove>
}
f0103e23:	c9                   	leave  
f0103e24:	c3                   	ret    

f0103e25 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103e25:	55                   	push   %ebp
f0103e26:	89 e5                	mov    %esp,%ebp
f0103e28:	56                   	push   %esi
f0103e29:	53                   	push   %ebx
f0103e2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e2d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e30:	89 c6                	mov    %eax,%esi
f0103e32:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103e35:	39 f0                	cmp    %esi,%eax
f0103e37:	74 1c                	je     f0103e55 <memcmp+0x30>
		if (*s1 != *s2)
f0103e39:	0f b6 08             	movzbl (%eax),%ecx
f0103e3c:	0f b6 1a             	movzbl (%edx),%ebx
f0103e3f:	38 d9                	cmp    %bl,%cl
f0103e41:	75 08                	jne    f0103e4b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103e43:	83 c0 01             	add    $0x1,%eax
f0103e46:	83 c2 01             	add    $0x1,%edx
f0103e49:	eb ea                	jmp    f0103e35 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103e4b:	0f b6 c1             	movzbl %cl,%eax
f0103e4e:	0f b6 db             	movzbl %bl,%ebx
f0103e51:	29 d8                	sub    %ebx,%eax
f0103e53:	eb 05                	jmp    f0103e5a <memcmp+0x35>
	}

	return 0;
f0103e55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e5a:	5b                   	pop    %ebx
f0103e5b:	5e                   	pop    %esi
f0103e5c:	5d                   	pop    %ebp
f0103e5d:	c3                   	ret    

f0103e5e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103e5e:	55                   	push   %ebp
f0103e5f:	89 e5                	mov    %esp,%ebp
f0103e61:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e64:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103e67:	89 c2                	mov    %eax,%edx
f0103e69:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103e6c:	39 d0                	cmp    %edx,%eax
f0103e6e:	73 09                	jae    f0103e79 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103e70:	38 08                	cmp    %cl,(%eax)
f0103e72:	74 05                	je     f0103e79 <memfind+0x1b>
	for (; s < ends; s++)
f0103e74:	83 c0 01             	add    $0x1,%eax
f0103e77:	eb f3                	jmp    f0103e6c <memfind+0xe>
			break;
	return (void *) s;
}
f0103e79:	5d                   	pop    %ebp
f0103e7a:	c3                   	ret    

f0103e7b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103e7b:	55                   	push   %ebp
f0103e7c:	89 e5                	mov    %esp,%ebp
f0103e7e:	57                   	push   %edi
f0103e7f:	56                   	push   %esi
f0103e80:	53                   	push   %ebx
f0103e81:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e84:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e87:	eb 03                	jmp    f0103e8c <strtol+0x11>
		s++;
f0103e89:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103e8c:	0f b6 01             	movzbl (%ecx),%eax
f0103e8f:	3c 20                	cmp    $0x20,%al
f0103e91:	74 f6                	je     f0103e89 <strtol+0xe>
f0103e93:	3c 09                	cmp    $0x9,%al
f0103e95:	74 f2                	je     f0103e89 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103e97:	3c 2b                	cmp    $0x2b,%al
f0103e99:	74 2e                	je     f0103ec9 <strtol+0x4e>
	int neg = 0;
f0103e9b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103ea0:	3c 2d                	cmp    $0x2d,%al
f0103ea2:	74 2f                	je     f0103ed3 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ea4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103eaa:	75 05                	jne    f0103eb1 <strtol+0x36>
f0103eac:	80 39 30             	cmpb   $0x30,(%ecx)
f0103eaf:	74 2c                	je     f0103edd <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103eb1:	85 db                	test   %ebx,%ebx
f0103eb3:	75 0a                	jne    f0103ebf <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103eb5:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103eba:	80 39 30             	cmpb   $0x30,(%ecx)
f0103ebd:	74 28                	je     f0103ee7 <strtol+0x6c>
		base = 10;
f0103ebf:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ec4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103ec7:	eb 50                	jmp    f0103f19 <strtol+0x9e>
		s++;
f0103ec9:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103ecc:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ed1:	eb d1                	jmp    f0103ea4 <strtol+0x29>
		s++, neg = 1;
f0103ed3:	83 c1 01             	add    $0x1,%ecx
f0103ed6:	bf 01 00 00 00       	mov    $0x1,%edi
f0103edb:	eb c7                	jmp    f0103ea4 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103edd:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103ee1:	74 0e                	je     f0103ef1 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103ee3:	85 db                	test   %ebx,%ebx
f0103ee5:	75 d8                	jne    f0103ebf <strtol+0x44>
		s++, base = 8;
f0103ee7:	83 c1 01             	add    $0x1,%ecx
f0103eea:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103eef:	eb ce                	jmp    f0103ebf <strtol+0x44>
		s += 2, base = 16;
f0103ef1:	83 c1 02             	add    $0x2,%ecx
f0103ef4:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103ef9:	eb c4                	jmp    f0103ebf <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103efb:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103efe:	89 f3                	mov    %esi,%ebx
f0103f00:	80 fb 19             	cmp    $0x19,%bl
f0103f03:	77 29                	ja     f0103f2e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103f05:	0f be d2             	movsbl %dl,%edx
f0103f08:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103f0b:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103f0e:	7d 30                	jge    f0103f40 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103f10:	83 c1 01             	add    $0x1,%ecx
f0103f13:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103f17:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103f19:	0f b6 11             	movzbl (%ecx),%edx
f0103f1c:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103f1f:	89 f3                	mov    %esi,%ebx
f0103f21:	80 fb 09             	cmp    $0x9,%bl
f0103f24:	77 d5                	ja     f0103efb <strtol+0x80>
			dig = *s - '0';
f0103f26:	0f be d2             	movsbl %dl,%edx
f0103f29:	83 ea 30             	sub    $0x30,%edx
f0103f2c:	eb dd                	jmp    f0103f0b <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103f2e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103f31:	89 f3                	mov    %esi,%ebx
f0103f33:	80 fb 19             	cmp    $0x19,%bl
f0103f36:	77 08                	ja     f0103f40 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103f38:	0f be d2             	movsbl %dl,%edx
f0103f3b:	83 ea 37             	sub    $0x37,%edx
f0103f3e:	eb cb                	jmp    f0103f0b <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103f40:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103f44:	74 05                	je     f0103f4b <strtol+0xd0>
		*endptr = (char *) s;
f0103f46:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f49:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103f4b:	89 c2                	mov    %eax,%edx
f0103f4d:	f7 da                	neg    %edx
f0103f4f:	85 ff                	test   %edi,%edi
f0103f51:	0f 45 c2             	cmovne %edx,%eax
}
f0103f54:	5b                   	pop    %ebx
f0103f55:	5e                   	pop    %esi
f0103f56:	5f                   	pop    %edi
f0103f57:	5d                   	pop    %ebp
f0103f58:	c3                   	ret    
f0103f59:	66 90                	xchg   %ax,%ax
f0103f5b:	66 90                	xchg   %ax,%ax
f0103f5d:	66 90                	xchg   %ax,%ax
f0103f5f:	90                   	nop

f0103f60 <__udivdi3>:
f0103f60:	55                   	push   %ebp
f0103f61:	57                   	push   %edi
f0103f62:	56                   	push   %esi
f0103f63:	53                   	push   %ebx
f0103f64:	83 ec 1c             	sub    $0x1c,%esp
f0103f67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f6b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103f6f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f73:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103f77:	85 d2                	test   %edx,%edx
f0103f79:	75 35                	jne    f0103fb0 <__udivdi3+0x50>
f0103f7b:	39 f3                	cmp    %esi,%ebx
f0103f7d:	0f 87 bd 00 00 00    	ja     f0104040 <__udivdi3+0xe0>
f0103f83:	85 db                	test   %ebx,%ebx
f0103f85:	89 d9                	mov    %ebx,%ecx
f0103f87:	75 0b                	jne    f0103f94 <__udivdi3+0x34>
f0103f89:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f8e:	31 d2                	xor    %edx,%edx
f0103f90:	f7 f3                	div    %ebx
f0103f92:	89 c1                	mov    %eax,%ecx
f0103f94:	31 d2                	xor    %edx,%edx
f0103f96:	89 f0                	mov    %esi,%eax
f0103f98:	f7 f1                	div    %ecx
f0103f9a:	89 c6                	mov    %eax,%esi
f0103f9c:	89 e8                	mov    %ebp,%eax
f0103f9e:	89 f7                	mov    %esi,%edi
f0103fa0:	f7 f1                	div    %ecx
f0103fa2:	89 fa                	mov    %edi,%edx
f0103fa4:	83 c4 1c             	add    $0x1c,%esp
f0103fa7:	5b                   	pop    %ebx
f0103fa8:	5e                   	pop    %esi
f0103fa9:	5f                   	pop    %edi
f0103faa:	5d                   	pop    %ebp
f0103fab:	c3                   	ret    
f0103fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fb0:	39 f2                	cmp    %esi,%edx
f0103fb2:	77 7c                	ja     f0104030 <__udivdi3+0xd0>
f0103fb4:	0f bd fa             	bsr    %edx,%edi
f0103fb7:	83 f7 1f             	xor    $0x1f,%edi
f0103fba:	0f 84 98 00 00 00    	je     f0104058 <__udivdi3+0xf8>
f0103fc0:	89 f9                	mov    %edi,%ecx
f0103fc2:	b8 20 00 00 00       	mov    $0x20,%eax
f0103fc7:	29 f8                	sub    %edi,%eax
f0103fc9:	d3 e2                	shl    %cl,%edx
f0103fcb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103fcf:	89 c1                	mov    %eax,%ecx
f0103fd1:	89 da                	mov    %ebx,%edx
f0103fd3:	d3 ea                	shr    %cl,%edx
f0103fd5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103fd9:	09 d1                	or     %edx,%ecx
f0103fdb:	89 f2                	mov    %esi,%edx
f0103fdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fe1:	89 f9                	mov    %edi,%ecx
f0103fe3:	d3 e3                	shl    %cl,%ebx
f0103fe5:	89 c1                	mov    %eax,%ecx
f0103fe7:	d3 ea                	shr    %cl,%edx
f0103fe9:	89 f9                	mov    %edi,%ecx
f0103feb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103fef:	d3 e6                	shl    %cl,%esi
f0103ff1:	89 eb                	mov    %ebp,%ebx
f0103ff3:	89 c1                	mov    %eax,%ecx
f0103ff5:	d3 eb                	shr    %cl,%ebx
f0103ff7:	09 de                	or     %ebx,%esi
f0103ff9:	89 f0                	mov    %esi,%eax
f0103ffb:	f7 74 24 08          	divl   0x8(%esp)
f0103fff:	89 d6                	mov    %edx,%esi
f0104001:	89 c3                	mov    %eax,%ebx
f0104003:	f7 64 24 0c          	mull   0xc(%esp)
f0104007:	39 d6                	cmp    %edx,%esi
f0104009:	72 0c                	jb     f0104017 <__udivdi3+0xb7>
f010400b:	89 f9                	mov    %edi,%ecx
f010400d:	d3 e5                	shl    %cl,%ebp
f010400f:	39 c5                	cmp    %eax,%ebp
f0104011:	73 5d                	jae    f0104070 <__udivdi3+0x110>
f0104013:	39 d6                	cmp    %edx,%esi
f0104015:	75 59                	jne    f0104070 <__udivdi3+0x110>
f0104017:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010401a:	31 ff                	xor    %edi,%edi
f010401c:	89 fa                	mov    %edi,%edx
f010401e:	83 c4 1c             	add    $0x1c,%esp
f0104021:	5b                   	pop    %ebx
f0104022:	5e                   	pop    %esi
f0104023:	5f                   	pop    %edi
f0104024:	5d                   	pop    %ebp
f0104025:	c3                   	ret    
f0104026:	8d 76 00             	lea    0x0(%esi),%esi
f0104029:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104030:	31 ff                	xor    %edi,%edi
f0104032:	31 c0                	xor    %eax,%eax
f0104034:	89 fa                	mov    %edi,%edx
f0104036:	83 c4 1c             	add    $0x1c,%esp
f0104039:	5b                   	pop    %ebx
f010403a:	5e                   	pop    %esi
f010403b:	5f                   	pop    %edi
f010403c:	5d                   	pop    %ebp
f010403d:	c3                   	ret    
f010403e:	66 90                	xchg   %ax,%ax
f0104040:	31 ff                	xor    %edi,%edi
f0104042:	89 e8                	mov    %ebp,%eax
f0104044:	89 f2                	mov    %esi,%edx
f0104046:	f7 f3                	div    %ebx
f0104048:	89 fa                	mov    %edi,%edx
f010404a:	83 c4 1c             	add    $0x1c,%esp
f010404d:	5b                   	pop    %ebx
f010404e:	5e                   	pop    %esi
f010404f:	5f                   	pop    %edi
f0104050:	5d                   	pop    %ebp
f0104051:	c3                   	ret    
f0104052:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104058:	39 f2                	cmp    %esi,%edx
f010405a:	72 06                	jb     f0104062 <__udivdi3+0x102>
f010405c:	31 c0                	xor    %eax,%eax
f010405e:	39 eb                	cmp    %ebp,%ebx
f0104060:	77 d2                	ja     f0104034 <__udivdi3+0xd4>
f0104062:	b8 01 00 00 00       	mov    $0x1,%eax
f0104067:	eb cb                	jmp    f0104034 <__udivdi3+0xd4>
f0104069:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104070:	89 d8                	mov    %ebx,%eax
f0104072:	31 ff                	xor    %edi,%edi
f0104074:	eb be                	jmp    f0104034 <__udivdi3+0xd4>
f0104076:	66 90                	xchg   %ax,%ax
f0104078:	66 90                	xchg   %ax,%ax
f010407a:	66 90                	xchg   %ax,%ax
f010407c:	66 90                	xchg   %ax,%ax
f010407e:	66 90                	xchg   %ax,%ax

f0104080 <__umoddi3>:
f0104080:	55                   	push   %ebp
f0104081:	57                   	push   %edi
f0104082:	56                   	push   %esi
f0104083:	53                   	push   %ebx
f0104084:	83 ec 1c             	sub    $0x1c,%esp
f0104087:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010408b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010408f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104093:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104097:	85 ed                	test   %ebp,%ebp
f0104099:	89 f0                	mov    %esi,%eax
f010409b:	89 da                	mov    %ebx,%edx
f010409d:	75 19                	jne    f01040b8 <__umoddi3+0x38>
f010409f:	39 df                	cmp    %ebx,%edi
f01040a1:	0f 86 b1 00 00 00    	jbe    f0104158 <__umoddi3+0xd8>
f01040a7:	f7 f7                	div    %edi
f01040a9:	89 d0                	mov    %edx,%eax
f01040ab:	31 d2                	xor    %edx,%edx
f01040ad:	83 c4 1c             	add    $0x1c,%esp
f01040b0:	5b                   	pop    %ebx
f01040b1:	5e                   	pop    %esi
f01040b2:	5f                   	pop    %edi
f01040b3:	5d                   	pop    %ebp
f01040b4:	c3                   	ret    
f01040b5:	8d 76 00             	lea    0x0(%esi),%esi
f01040b8:	39 dd                	cmp    %ebx,%ebp
f01040ba:	77 f1                	ja     f01040ad <__umoddi3+0x2d>
f01040bc:	0f bd cd             	bsr    %ebp,%ecx
f01040bf:	83 f1 1f             	xor    $0x1f,%ecx
f01040c2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01040c6:	0f 84 b4 00 00 00    	je     f0104180 <__umoddi3+0x100>
f01040cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01040d1:	89 c2                	mov    %eax,%edx
f01040d3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040d7:	29 c2                	sub    %eax,%edx
f01040d9:	89 c1                	mov    %eax,%ecx
f01040db:	89 f8                	mov    %edi,%eax
f01040dd:	d3 e5                	shl    %cl,%ebp
f01040df:	89 d1                	mov    %edx,%ecx
f01040e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01040e5:	d3 e8                	shr    %cl,%eax
f01040e7:	09 c5                	or     %eax,%ebp
f01040e9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040ed:	89 c1                	mov    %eax,%ecx
f01040ef:	d3 e7                	shl    %cl,%edi
f01040f1:	89 d1                	mov    %edx,%ecx
f01040f3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01040f7:	89 df                	mov    %ebx,%edi
f01040f9:	d3 ef                	shr    %cl,%edi
f01040fb:	89 c1                	mov    %eax,%ecx
f01040fd:	89 f0                	mov    %esi,%eax
f01040ff:	d3 e3                	shl    %cl,%ebx
f0104101:	89 d1                	mov    %edx,%ecx
f0104103:	89 fa                	mov    %edi,%edx
f0104105:	d3 e8                	shr    %cl,%eax
f0104107:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010410c:	09 d8                	or     %ebx,%eax
f010410e:	f7 f5                	div    %ebp
f0104110:	d3 e6                	shl    %cl,%esi
f0104112:	89 d1                	mov    %edx,%ecx
f0104114:	f7 64 24 08          	mull   0x8(%esp)
f0104118:	39 d1                	cmp    %edx,%ecx
f010411a:	89 c3                	mov    %eax,%ebx
f010411c:	89 d7                	mov    %edx,%edi
f010411e:	72 06                	jb     f0104126 <__umoddi3+0xa6>
f0104120:	75 0e                	jne    f0104130 <__umoddi3+0xb0>
f0104122:	39 c6                	cmp    %eax,%esi
f0104124:	73 0a                	jae    f0104130 <__umoddi3+0xb0>
f0104126:	2b 44 24 08          	sub    0x8(%esp),%eax
f010412a:	19 ea                	sbb    %ebp,%edx
f010412c:	89 d7                	mov    %edx,%edi
f010412e:	89 c3                	mov    %eax,%ebx
f0104130:	89 ca                	mov    %ecx,%edx
f0104132:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104137:	29 de                	sub    %ebx,%esi
f0104139:	19 fa                	sbb    %edi,%edx
f010413b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010413f:	89 d0                	mov    %edx,%eax
f0104141:	d3 e0                	shl    %cl,%eax
f0104143:	89 d9                	mov    %ebx,%ecx
f0104145:	d3 ee                	shr    %cl,%esi
f0104147:	d3 ea                	shr    %cl,%edx
f0104149:	09 f0                	or     %esi,%eax
f010414b:	83 c4 1c             	add    $0x1c,%esp
f010414e:	5b                   	pop    %ebx
f010414f:	5e                   	pop    %esi
f0104150:	5f                   	pop    %edi
f0104151:	5d                   	pop    %ebp
f0104152:	c3                   	ret    
f0104153:	90                   	nop
f0104154:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104158:	85 ff                	test   %edi,%edi
f010415a:	89 f9                	mov    %edi,%ecx
f010415c:	75 0b                	jne    f0104169 <__umoddi3+0xe9>
f010415e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104163:	31 d2                	xor    %edx,%edx
f0104165:	f7 f7                	div    %edi
f0104167:	89 c1                	mov    %eax,%ecx
f0104169:	89 d8                	mov    %ebx,%eax
f010416b:	31 d2                	xor    %edx,%edx
f010416d:	f7 f1                	div    %ecx
f010416f:	89 f0                	mov    %esi,%eax
f0104171:	f7 f1                	div    %ecx
f0104173:	e9 31 ff ff ff       	jmp    f01040a9 <__umoddi3+0x29>
f0104178:	90                   	nop
f0104179:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104180:	39 dd                	cmp    %ebx,%ebp
f0104182:	72 08                	jb     f010418c <__umoddi3+0x10c>
f0104184:	39 f7                	cmp    %esi,%edi
f0104186:	0f 87 21 ff ff ff    	ja     f01040ad <__umoddi3+0x2d>
f010418c:	89 da                	mov    %ebx,%edx
f010418e:	89 f0                	mov    %esi,%eax
f0104190:	29 f8                	sub    %edi,%eax
f0104192:	19 ea                	sbb    %ebp,%edx
f0104194:	e9 14 ff ff ff       	jmp    f01040ad <__umoddi3+0x2d>
