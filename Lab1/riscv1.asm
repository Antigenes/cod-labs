
	.text
main:
	li a7, 5
	ecall
	addi x2, a0, 0#将输入的n存入R2
	addi x1, x2, -1#序号i
	# 存入初始值
	li x4, 1
	li x5, 1
loop:
	addi x1, x1, -1#i--
	ble x1, x0, save#if(i == 0)
	bge x4, x5, next
	add x4, x4, x5
	jal x0, loop
next:
	add x5, x4, x5#下一项存进R5
	jal x0, loop
save:
	#更大的数就是最终结果，存入R3
	bge x4, x5, R4
	addi x3, x5, 0
	jal x0, end
R4:
	addi x3, x4, 0
end:
	#打印
	addi a0, x3, 0
	li a7, 1
	ecall
	li a7, 10
	ecall
	
