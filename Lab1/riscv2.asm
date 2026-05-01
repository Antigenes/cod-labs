	.text
main:
	li a7, 5
	ecall
	addi x2, a0, 0#将输入的n存入R2
	addi x1, x2, -1#序号i
	#R3、R4存一个数，R5、R6存一个数
	li x3, 0
	li x4, 1
	li x5, 0
	li x6, 1
loop:
	addi x1, x1, -1
	blez x1,end#if(i <= 0)
	add x8, x4, x6
	sltu x9, x8, x4#判断溢出
	add x7, x3, x5
	add x7, x7, x9#加上进位
	#现在R7、R8存的是新的数了
	#往前移
	addi x3, x5, 0
	addi x4, x6, 0
	addi x5, x7, 0
	addi x6, x8, 0
	jal x0, loop
end:
	#往前移
	addi x3, x5, 0
	addi x4, x6, 0
	addi x5, x7, 0
	addi x6, x8, 0
	li a7, 10
	ecall
	ebreak
