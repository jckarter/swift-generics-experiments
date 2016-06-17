#include "asm.h"

#define CLASSIC_TAKE_INIT        0x00
#define CLASSIC_TAKE_ASSIGN      0x08
#define CLASSIC_COPY_INIT        0x10
#define CLASSIC_COPY_ASSIGN      0x18
#define CLASSIC_DESTROY          0x20
#define CLASSIC_COPY_INIT_BUFFER 0x28
#define CLASSIC_ALLOC_BUFFER     0x30
#define CLASSIC_DEALLOC_BUFFER   0x38
#define CLASSIC_STRIDE           0x40

.data
.global SYM(Int_vwtable_classic)
SYM(Int_vwtable_classic):
	.quad SYM(Int_classic_take_init)
	.quad SYM(Int_classic_take_assign)
	.quad SYM(Int_classic_copy_init)
	.quad SYM(Int_classic_copy_assign)
	.quad SYM(Int_classic_destroy)
	.quad SYM(Int_classic_copy_init_buffer)
	.quad SYM(Int_classic_alloc_buffer)
	.quad SYM(Int_classic_dealloc_buffer)
	.quad 8

.text
SYM(nop):
SYM(Int_classic_destroy):
SYM(Int_classic_dealloc_buffer):
	ret

SYM(ret_self):
SYM(Int_classic_alloc_buffer):
	mov %rdi, %rax
	ret

SYM(Int_classic_take_init):
SYM(Int_classic_take_assign):
SYM(Int_classic_copy_init):
SYM(Int_classic_copy_assign):
SYM(Int_classic_copy_init_buffer):
	mov (%rdi), %rdx
	mov %rdx, (%rsi)
	mov %rsi, %rax
	ret

.data
.global SYM(Int_Comparable_classic)
SYM(Int_Comparable_classic):
	.quad SYM(Int_less_classic)

.text
SYM(Int_less_classic):
	xor %eax, %eax
	mov (%rdi), %rdx
	mov (%rsi), %rcx
	cmp %rcx, %rdx
	setl %al
	ret

.data
.global SYM(Rect_vwtable_classic)
SYM(Rect_vwtable_classic):
	.quad SYM(Rect_classic_take_init)
	.quad SYM(Rect_classic_take_assign)
	.quad SYM(Rect_classic_copy_init)
	.quad SYM(Rect_classic_copy_assign)
	.quad SYM(Rect_classic_destroy)
	.quad SYM(Rect_classic_copy_init_buffer)
	.quad 0 // TODO: should be classic_alloc_buffer
	.quad SYM(Rect_classic_dealloc_buffer)
	.quad 32

.global SYM(Rect_vwtable_neoclassic)
SYM(Rect_vwtable_neoclassic):
	.quad SYM(Rect_classic_take_init)
	.quad SYM(Rect_classic_take_assign)
	.quad SYM(Rect_classic_copy_init)
	.quad SYM(Rect_classic_copy_assign)
	.quad SYM(Rect_classic_destroy)
	.quad SYM(Rect_neoclassic_copy_init_buffer)
	.quad 0
	.quad 32

.text
SYM(Rect_classic_take_init):
SYM(Rect_classic_copy_init):
SYM(Rect_classic_take_assign):
SYM(Rect_classic_copy_assign):
	movdqu (%rdi), %xmm0
	movdqu 16(%rdi), %xmm1
	movdqu %xmm0, (%rsi)
	movdqu %xmm1, 16(%rsi)
	mov %rsi, %rax
	ret

SYM(Rect_classic_copy_init_buffer):
	sub $24, %rsp
	mov %rdi, (%rsp)
	mov %rsi, 8(%rsp)
	mov $32, %rdi
	call SYM(malloc)
	mov (%rsp), %rdi
	mov 8(%rsp), %rsi
	add $24, %rsp
	mov %rax, (%rsi)
	movdqu (%rdi), %xmm0
	movdqu 16(%rdi), %xmm1
	movdqu %xmm0, (%rax)
	movdqu %xmm1, 16(%rax)
	ret

SYM(Rect_neoclassic_copy_init_buffer):
        pop %rdx
        sub $32, %rsp
        mov %rsp, %rax
        movdqu (%rdi), %xmm0
        movdqu 16(%rdi), %xmm1
        movdqu %xmm0, (%rax)
        movdqu %xmm1, 16(%rax)
        push %rdx
        ret

SYM(Rect_classic_dealloc_buffer):
	mov (%rdi), %rdi
	jmp SYM(free)

SYM(Rect_classic_destroy) = SYM(nop)

.global SYM(generic_min_classic)
// min(@in a: ptr T, @in b: ptr T, T, T: Comparable,
//     @out return: ptr T)
SYM(generic_min_classic):
	push %rbp
	mov %rsp, %rbp
	sub $96, %rsp
	mov %r12, (%rsp)
	mov %rdx, %r12 // T
	mov %r13, 8(%rsp)
	mov %rcx, %r13 // T: Comparable
	mov %rdi, 16(%rsp)
	mov %rsi, 24(%rsp)
	mov %r8, 88(%rsp)
	//   a' = copy_init_buffer a to abuf
	lea 32(%rsp), %rsi
	call *CLASSIC_COPY_INIT_BUFFER(%r12)
	mov %rax, 56(%rsp)
	//   b' = copy_init_buffer b to bbuf
	mov 24(%rsp), %rdi
	lea 64(%rsp), %rsi
	call *CLASSIC_COPY_INIT_BUFFER(%r12)
	//   isLess = less(a', b')
	mov 56(%rsp), %rdi
	mov %rax, %rsi
	call *(%r13)
	mov %rax, %r13
	//   dealloc_buffer abuf
	lea 32(%rsp), %rdi
	call *CLASSIC_DEALLOC_BUFFER(%r12)
	//   dealloc_buffer bbuf
	lea 64(%rsp), %rdi
	call *CLASSIC_DEALLOC_BUFFER(%r12)
	//   br isLess, less, more
	test %r13d, %r13d
	jz 1f
	// less:
	//   take_init a to return
	mov 16(%rsp), %rdi
	mov 88(%rsp), %rsi
	call *CLASSIC_TAKE_INIT(%r12)
	//   br end
	jmp 2f
	// more:
1:
	//   take_init b to return
	mov 24(%rsp), %rdi
	mov 88(%rsp), %rsi
	call *CLASSIC_TAKE_INIT(%r12)
	//   br end
	// end:
2:
	//   ret
	mov (%rsp), %r12
	mov 8(%rsp), %r13
	add $96, %rsp
  pop %rbp
	ret

.global SYM(generic_min_neoclassic)
// min(@in a: ptr T, @in b: ptr T, T, T: Comparable,
//     @out return: ptr T)
SYM(generic_min_neoclassic):
        push %rbp
        mov %rsp, %rbp
	sub $96, %rsp
	mov %r12, -8(%rbp)
	mov %rdx, %r12 // T
	mov %r13, -16(%rbp)
	mov %rcx, %r13 // T: Comparable
	mov %rdi, -24(%rbp)
	mov %rsi, -32(%rbp)
	mov %r8, -96(%rbp)
	//   a' = copy_init_buffer a to abuf
	lea -56(%rbp), %rsi
	call *CLASSIC_COPY_INIT_BUFFER(%r12)
	mov %rax, -64(%rbp)
	//   b' = copy_init_buffer b to bbuf
	mov -32(%rbp), %rdi
	lea -88(%rbp), %rsi
	call *CLASSIC_COPY_INIT_BUFFER(%r12)
	//   isLess = less(a', b')
	mov -64(%rbp), %rdi
	mov %rax, %rsi
	call *(%r13)
	mov %rax, %r13
	//   br isLess, less, more
	test %r13d, %r13d
	jz 1f
	// less:
	//   take_init a to return
	mov -24(%rbp), %rdi
	mov -96(%rbp), %rsi
	call *CLASSIC_TAKE_INIT(%r12)
	//   br end
	jmp 2f
	// more:
1:
	//   take_init b to return
	mov -32(%rbp), %rdi
	mov -96(%rbp), %rsi
	call *CLASSIC_TAKE_INIT(%r12)
	//   br end
	// end:
2:
	//   ret
	mov -8(%rbp), %r12
	mov -16(%rbp), %r13
	leave
	ret

.global SYM(generic_qsort_classic)
// quicksort_generic(beginp: ptr, endp: ptr, T, T: Comparable)
SYM(generic_qsort_classic):
	//   br endp-beginp <= 1, end, go
	mov %rsi, %rax
	sub %rdi, %rax
	cmp CLASSIC_STRIDE(%rdx), %rax
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
	call SYM(partition_classic)
	mov %rax, (%rsp)
	//   qsort(beginp, p)
	mov %r12, %rdi
	mov %rax, %rsi
	mov %r14, %rdx
	mov %r15, %rcx
	call SYM(generic_qsort_classic)
	//   qsort(p+1, endp)
	mov (%rsp), %rdi
	add CLASSIC_STRIDE(%r14), %rdi
	mov %r13, %rsi
	mov %r14, %rdx
	mov %r15, %rcx
	add $8, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	jmp SYM(generic_qsort_classic)
	// end:
9:
	ret

// partition(begin: ptr, end: ptr, T, T: Comparable)
SYM(partition_classic):
	
	//   tmp = allocateBuffer
	//   pivotp = end - 1
	//   br loop(begin, begin)
	// loop(ip, jp):
	//   br jp < pivotp, body, end
	// body:
	//   jp' = allocateBuffer
	//   copy jp init jp'
	//   pivotp' = allocateBuffer
	//   copy pivotp init pivotp'
	//   shouldKeep = less(pivotp', jp')
	//   deallocBuffer jp'
	//   deallocBuffer pivotp'
	//   br shouldKeep, next(ip), doSwap
	// doSwap:
	//   take ip init tmp
	//   take jp init ip
	//   take tmp init ip
	//   br next(ip+1)
	// next(ip'):
	//   br loop(ip', jp+1)
	// end:
	//   take ip into tmp
	//   take pivotp into ip
	//   take tmp into pivotp
	//   deallocateBuffer tmp
	//   ret ip

