#include "asm.h"

#define ALLOCA             0x00
#define COMMIT             0x08
#define CONSUME            0x10
#define COPY               0x18
#define LOAD               0x20
#define STORE              0x28
#define MEM                0x30
#define STRIDE             0x38

// Int is a model of a trivial, inline type.
.data
.global SYM(Int_vwtable_combined)
SYM(Int_vwtable_combined):
	.quad SYM(Int_alloca)
	.quad SYM(Int_commit)
	.quad SYM(Int_consume)
	.quad SYM(Int_copy)
	.quad SYM(Int_load)
	.quad SYM(Int_store)
	.quad SYM(Int_mem)
	.quad 8

.text
SYM(nop):
SYM(Int_alloca):
SYM(Int_consume):
	ret

SYM(ret_self):
SYM(Int_copy):
	mov %rdi, %rax
	ret

SYM(Int_commit):
SYM(Int_store):
	mov %rdi, (%rsi)
	mov %rsi, %rax
	ret

SYM(Int_load):
	mov (%rdi), %rax
	ret

SYM(Int_mem):
	mov (%rdi), %rdx
	mov %rdx, (%rsi)
	mov %rsi, %rax
	ret

// Rect {double, double, double, double} is a model of a trivial
// shared-memory type.
.data
.global SYM(Rect_vwtable_combined)
SYM(Rect_vwtable_combined):
	.quad SYM(Rect_alloca)
	.quad SYM(Rect_commit)
	.quad SYM(Rect_consume)
	.quad SYM(Rect_copy)
	.quad SYM(Rect_load)
	.quad SYM(Rect_store)
	.quad SYM(Rect_mem)
	.quad 32

.text
SYM(Rect_alloca):
	pop %rdx
	sub $32, %rsp
	mov %rsp, %rax
	push %rdx
	ret
	
SYM(Rect_commit) = SYM(nop)
SYM(Rect_consume) = SYM(nop)

SYM(Rect_copy):
SYM(Rect_load):
  test $1, %rdx // independent copy?
  mov %rdi, %rax
  jz 9f
  test %rsi, %rsi // dest addr given?
  jnz 1f
  pop %rdx
  sub $32, %rsp
  mov %rsp, %rsi
  push %rdx
1:
  movdqu (%rdi), %xmm0
	movdqu 16(%rdi), %xmm1
	movdqu %xmm0, (%rsi)
	movdqu %xmm1, 16(%rsi)
  mov %rsi, %rax
9:
  ret

SYM(Rect_store):
SYM(Rect_mem):
	movdqu (%rdi), %xmm0
	movdqu 16(%rdi), %xmm1
	movdqu %xmm0, (%rsi)
	movdqu %xmm1, 16(%rsi)
	mov %rsi, %rax
	ret

// Test function: min
.text
.global SYM(generic_min_combined)
// min(@owned a: gv T, @owned b: gv T, T, T: Comparable,
//     @out return: ugv T) -> @owned gv T
SYM(generic_min_combined):
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
	//   a' = copy a dep
  xor %rsi, %rsi
	xor %rdx, %rdx
	call *COPY(%r12)
	mov %rax, -48(%rbp) // a'
	//   b' = copy b dep
	mov -16(%rbp), %rdi
  xor %rsi, %rsi
	xor %rdx, %rdx
	call *COPY(%r12)
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
	mov $3, %rdx
	call *COPY(%r12)
	//   br end(x)
	jmp 2f
	// more:
1:
	//   y = take b into return
	mov -16(%rbp), %rdi
	mov -40(%rbp), %rsi
	mov $3, %rdx
	call *COPY(%r12)
	//   br end(y)
	// end(z):
2:
	//   ret z
	mov -24(%rbp), %r12
	mov -32(%rbp), %r13
	leave
	ret

/* TODO
.global SYM(generic_qsort_new)
// quicksort_generic(beginp: ptr, endp: ptr, T, T: Comparable)
SYM(generic_qsort_new):
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
	jmp SYM(generic_qsort_new)
	// end:
9:
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
*/