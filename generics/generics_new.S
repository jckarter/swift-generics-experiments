#include "asm.h"

#define ALLOCA             0x00
#define MALLOC             0x08
#define FREE               0x10
#define COMMIT             0x18
#define CONSUME            0x20
#define TAKE_INTO          0x28
#define COPY_DEP           0x30
#define COPY_INTO          0x38
#define LOAD_TAKE_DEP      0x40
#define LOAD_TAKE_INTO     0x48
#define LOAD_COPY_DEP      0x50
#define LOAD_COPY_INTO     0x58
#define STORE_TAKE_INIT    0x60
#define STORE_COPY_INIT    0x68
#define STORE_TAKE_ASSIGN  0x70
#define STORE_COPY_ASSIGN  0x78
#define MEM_COPY_ASSIGN    0x80
#define STRIDE             0x88
#define CALL_COPY0_COPY1   0x90

// Int is a model of a trivial, inline type.
.data
.global SYM(Int_vwtable_new)
SYM(Int_vwtable_new):
	.quad SYM(Int_alloca)
	.quad SYM(Int_malloc)
	.quad SYM(Int_free)
	.quad SYM(Int_commit)
	.quad SYM(Int_consume)
	.quad SYM(Int_take_into)
	.quad SYM(Int_copy_dep)
	.quad SYM(Int_copy_into)
	.quad SYM(Int_load_take_dep)
	.quad SYM(Int_load_take_into)
	.quad SYM(Int_load_copy_dep)
	.quad SYM(Int_load_copy_into)
	.quad SYM(Int_store_take_init)
	.quad SYM(Int_store_copy_init)
	.quad SYM(Int_store_take_assign)
	.quad SYM(Int_store_copy_assign)
	.quad SYM(Int_mem_copy_assign)
	.quad 8
  .quad SYM(nopcall)

.text
SYM(nopcall):
  jmp *%rax

SYM(nop):
SYM(Int_alloca):
SYM(Int_malloc):
SYM(Int_free):
SYM(Int_consume):
	ret

SYM(ret_self):
SYM(Int_copy_dep):
SYM(Int_copy_into):
SYM(Int_take_into):
	mov %rdi, %rax
	ret

SYM(Int_commit):
SYM(Int_store_take_init):
SYM(Int_store_take_assign):
SYM(Int_store_copy_init):
SYM(Int_store_copy_assign):
	mov %rdi, (%rsi)
	mov %rsi, %rax
	ret

SYM(Int_load_take_dep):
SYM(Int_load_take_into):
SYM(Int_load_copy_dep):
SYM(Int_load_copy_into):
	mov (%rdi), %rax
	ret

SYM(Int_mem_copy_assign):
	mov (%rdi), %rdx
	mov %rdx, (%rsi)
	mov %rsi, %rax
	ret

.data
.global SYM(Int_Comparable)
SYM(Int_Comparable):
	.quad SYM(Int_less)

.text
SYM(Int_less):
	xor %eax, %eax
	cmp %rsi, %rdi
	setl %al
	ret

// Rect {double, double, double, double} is a model of a trivial
// shared-memory type.
.data
.global SYM(Rect_vwtable_new)
SYM(Rect_vwtable_new):
	.quad SYM(Rect_alloca)
	.quad SYM(Rect_malloc)
	.quad SYM(Rect_free)
	.quad SYM(Rect_commit)
	.quad SYM(Rect_consume)
	.quad SYM(Rect_take_into)
	.quad SYM(Rect_copy_dep)
	.quad SYM(Rect_copy_into)
	.quad SYM(Rect_load_take_dep)
	.quad SYM(Rect_load_take_into)
	.quad SYM(Rect_load_copy_dep)
	.quad SYM(Rect_load_copy_into)
	.quad SYM(Rect_store_take_init)
	.quad SYM(Rect_store_copy_init)
	.quad SYM(Rect_store_take_assign)
	.quad SYM(Rect_store_copy_assign)
	.quad SYM(Rect_mem_copy_assign)
	.quad 32
  .quad SYM(nopcall)

.text
SYM(Rect_alloca):
	pop %rdx
	sub $32, %rsp
	mov %rsp, %rax
	push %rdx
	ret
	
SYM(Rect_malloc):
	mov $32, %rdi
	jmp SYM(malloc)
	
SYM(Rect_free):
	jmp SYM(free)

SYM(Rect_commit) = SYM(nop)
SYM(Rect_consume) = SYM(nop)
SYM(Rect_copy_dep) = SYM(ret_self)
SYM(Rect_load_take_dep) = SYM(ret_self)
SYM(Rect_load_copy_dep) = SYM(ret_self)

SYM(Rect_copy_into):
SYM(Rect_take_into):
SYM(Rect_load_take_into):
SYM(Rect_load_copy_into):
SYM(Rect_store_take_init):
SYM(Rect_store_take_assign):
SYM(Rect_store_copy_init):
SYM(Rect_store_copy_assign):
SYM(Rect_mem_copy_assign):
	movdqu (%rdi), %xmm0
	movdqu 16(%rdi), %xmm1
	movdqu %xmm0, (%rsi)
	movdqu %xmm1, 16(%rsi)
	mov %rsi, %rax
	ret

.data
.global SYM(Rect_Comparable)
SYM(Rect_Comparable):
	.quad SYM(Rect_less)

.text
SYM(Rect_less):
	xor %eax, %eax
	movsd (%rdi), %xmm0
	ucomisd (%rsi), %xmm0
	jnz 1f
	movsd 8(%rdi), %xmm0
	ucomisd 8(%rsi), %xmm0
	jnz 1f
	movsd 16(%rdi), %xmm0
	ucomisd 16(%rsi), %xmm0
	jnz 1f
	movsd 24(%rdi), %xmm0
	ucomisd 24(%rsi), %xmm0
1:
	setc %al
	ret

// Test function: min
.text
.global SYM(generic_min_new)
// min(@owned a: gv T, @owned b: gv T, T, T: Comparable,
//     @out return: ugv T) -> @owned gv T
SYM(generic_min_new):
	push %rbp
	mov %rsp, %rbp
	sub $48, %rsp
	mov %rdi,  -8(%rbp) // a
	mov %rsi, -16(%rbp) // b
	mov %r12, -24(%rbp)
	mov %rdx, %r12 // T
	mov %r13, -32(%rbp)
	mov %rcx, %r13 // T: Comparable
	mov %r8,  -40(%rbp) // return
	// Test: extra allocas to simulate alloc_dep
	//call *ALLOCA(%r12)
	//call *ALLOCA(%r12)
	//   a' = copy a dep
	call *COPY_DEP(%r12)
	mov %rax, -48(%rbp) // a'
	//   b' = copy b dep
	mov -16(%rbp), %rdi
	call *COPY_DEP(%r12)
	//   isLess = less(a', b')
	mov -48(%rbp), %rdi
	mov %rax, %rsi
	call *(%r13)
	//   br isLess, less, more
	test %eax, %eax
	jz 1f
	// less:
	//   x = take a into return
	mov -8(%rbp), %rdi
	mov -40(%rbp), %rsi
	call *TAKE_INTO(%r12)
	//   br end(x)
	jmp 2f
	// more:
1:
	//   y = take b into return
	mov -16(%rbp), %rdi
	mov -40(%rbp), %rsi
	call *TAKE_INTO(%r12)
	//   br end(y)
	// end(z):
2:
	//   ret z
	mov -24(%rbp), %r12
	mov -32(%rbp), %r13
	leave
	ret

.text
.global SYM(generic_min_new_callop)
// min(@owned a: gv T, @owned b: gv T, T, T: Comparable,
//     @out return: ugv T) -> @owned gv T
SYM(generic_min_new_callop):
	push %rbp
	mov %rsp, %rbp
	sub $48, %rsp
	mov %rdi,  -8(%rbp) // a
	mov %rsi, -16(%rbp) // b
	mov %r12, -24(%rbp)
	mov %rdx, %r12 // T
	mov %r13, -32(%rbp)
	mov %rcx, %r13 // T: Comparable
	mov %r8,  -40(%rbp) // return
	// Test: extra allocas to simulate alloc_dep
	//call *ALLOCA(%r12)
	//call *ALLOCA(%r12)
	//   a' = copy a dep
	//   b' = copy b dep
	//   isLess = less(a', b')
  mov (%r13), %rax
	call *CALL_COPY0_COPY1(%r12)
	//   br isLess, less, more
	test %eax, %eax
	jz 1f
	// less:
	//   x = take a into return
	mov -8(%rbp), %rdi
	mov -40(%rbp), %rsi
	call *TAKE_INTO(%r12)
	//   br end(x)
	jmp 2f
	// more:
1:
	//   y = take b into return
	mov -16(%rbp), %rdi
	mov -40(%rbp), %rsi
	call *TAKE_INTO(%r12)
	//   br end(y)
	// end(z):
2:
	//   ret z
	mov -24(%rbp), %r12
	mov -32(%rbp), %r13
	leave
	ret


.global SYM(generic_qsort_new)
// quicksort_generic(beginp: ptr, endp: ptr, T, T: Comparable)
SYM(generic_qsort_new):
  push %rbp
  mov %rsp, %rbp
1:
	//   br endp-beginp <= 1, end, go
	mov %rsi, %rax
	sub %rdi, %rax
	cmp STRIDE(%rdx), %rax
	jle 9f
	// go:
	push %r12
	push %r13
	push %r14
	push %r15
        sub $8, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %r14
	mov %rcx, %r15
	//   p = partition(beginp, endp)
	call SYM(partition)
	mov %rax, (%rsp)
	//   qsort(beginp, p)
	mov %r12, %rdi
	mov %rax, %rsi
	mov %r14, %rdx
	mov %r15, %rcx
	call SYM(generic_qsort_new)
	//   qsort(p+1, endp)
	mov (%rsp), %rdi
	add STRIDE(%r14), %rdi
	mov %r13, %rsi
	mov %r14, %rdx
	mov %r15, %rcx
	add $8, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	jmp 1b
	// end:
9:
  pop %rbp
	ret

// partition(begin: ptr, end: ptr, T, T: Comparable)
SYM(partition):
	push %rbp
	mov %rsp, %rbp
	push %r12 // -8(%rbp)
	push %r13 // -16(%rbp)
	push %r14 // -24(%rbp)
	push %r15 // -32(%rbp)
	push %rbx // -40(%rbp)
	sub $24, %rsp // -64(%rbp)
	mov %rdx, %r12 // T
	mov %rcx, %r13 // T: Comparable
	mov %rdi, %r15 // begin
	//   pivotp = end - 1
	mov %rsi, %r14
	sub STRIDE(%rdx), %r14 // pivotp
	//   tmp = alloca
	call *ALLOCA(%rdx)
	mov %rax, -56(%rbp) // tmp
	//   pivot = load take pivotp dep
	mov %r14, %rdi
	call *LOAD_TAKE_DEP(%r12)
	mov %rax, -64(%rbp) // pivot
	//   br loop(begin, begin)
	mov %r14, -48(%rbp) // pivotp
	mov %r15, %r14 // ip
	// jp kills begin in %r15
	// loop(ip, jp):
1:
	//   br jp < pivotp, body, end
	cmp -48(%rbp), %r15
	jge 9f
	// body:
	//   je = load copy jp dep
	mov %r15, %rdi
	call *LOAD_COPY_DEP(%r12)
	mov %rax, %rbx // je
	//   pivot' = copy pivot dep
	mov -64(%rbp), %rdi
	call *COPY_DEP(%r12)
	//   shouldKeep = less(pivot', je)
	mov %rax, %rdi
	mov %rbx, %rsi
	call *(%r13)
	//   br shouldKeep, next(i), doSwap
	test %rax, %rax
	jnz 8f
	// doSwap:
	//   ie = load take ip into tmp
	mov %r14, %rdi
	mov -56(%rbp), %rsi
	call *LOAD_TAKE_INTO(%r12)
	mov %rax, %rbx // ie
	//   je' = load take jp into (emplace)ip
	mov %r15, %rdi
	mov %r14, %rsi
	call *LOAD_TAKE_INTO(%r12)
	//   commit je' to ip
	mov %rax, %rdi
	mov %r14, %rsi
	call *COMMIT(%r12)
	//   store take ie init jp
	mov %rbx, %rdi
	mov %r15, %rsi
	call *STORE_TAKE_INIT(%r12)
	//   br next(ip+size)
	add STRIDE(%r12), %r14
	// next(ip'):
8:
	//   br loop(ip', jp+size)
	add STRIDE(%r12), %r15
	jmp 1b
	// end:
9:
	//   ie' = load take ip into tmp
	mov %r14, %rdi
	mov -56(%rbp), %rsi
	call *LOAD_TAKE_INTO(%r12)
	mov %rax, %r13 // ie'
	//   store take pivot init ip
	mov -64(%rbp), %rdi
	mov %r14, %rsi
	call *STORE_TAKE_INIT(%r12)
	//   store take ie' init pivotp
	mov %r13, %rdi
	mov -48(%rbp), %rsi
	call *STORE_TAKE_INIT(%r12)
	//   ret ip
	mov %r14, %rax
	mov -8(%rbp), %r12
	mov -16(%rbp), %r13
	mov -24(%rbp), %r14
	mov -32(%rbp), %r15
	mov -40(%rbp), %rbx
	leave
	ret

.global SYM(notailcall)
SYM(notailcall):
  ret
