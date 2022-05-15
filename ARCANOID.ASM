; Copyright 2022 Khadiev Edem
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; 
;     http://www.apache.org/licenses/LICENSE-2.0
; 
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

	.model	tiny
	.code
	org	100h

start:
	mov	dx, offset  welcome_msg
	call	print

	mov	ah, 00h			; wait for key press
	int	16h

	mov	ax, 0003h
	int	10h
;;;; hide text cursor:;;;
	mov	ah, 1
	mov	ch, 2bh
	mov	cl, 0bh
	int	10h
;;;;;;;;;;;;;;;;;;;;;;;;
	call	gen_ball
	call	gen_field
	call	print_ball
	call	print_field
	call	print_platform
	call	print_walls
game_loop:
	cmp	next_gen, 1
	jne	elements_exist
	dec	next_gen
	call	gen_field
elements_exist:
	call	read_character
					; wait some time
	mov	ah, 00h
	int	1ah
	cmp	dx, wait_time
	jb	elements_exist
	add	dx, 2
	mov	wait_time, dx

	call	move_ball
	call	lose_check
	cmp	lose, 1
	je	game_over

	call	wall_check
	;call	 brick_check

	jmp	game_loop
game_over:
	call	stop_game
	mov	dx, offset lose_msg
	call	print
	mov	dx, offset end_msg
	call	print
	ret
; --- procedures --- ;

read_character proc
	push	ax
	push	dx
	mov	ax, 0100h
	int	16h
	jz	end_read

	xor	ah, ah
	int	16h
	cmp	al, 1bh			; ESC
	jne	other_key_press

	call	stop_game
	mov	dx, offset end_msg
	call	print
	int	20h
	jmp	end_read
other_key_press:
	cmp	ah, 4bh			; left
	jne	no_left_press
	cmp	platform_x, 0
	je	end_read
	dec	platform_x
	call	print_platform
	jmp	end_read
no_left_press:
	cmp	ah, 4dh			; right
	jne	end_read		; if no	right then end
	cmp	platform_x, 80 - platform_len
	je	end_read
	inc	platform_x
	call	print_platform
end_read:
	pop	dx
	pop	ax
	ret
read_character endp

clean_platform_line proc
	push	ax
	push	bx
	push	cx
	push	dx

	mov	ah, 02h
	xor	bh, bh
	mov	dh, 24
	xor	dl, dl
	int	10h

	mov	ah, 09h
	mov	al, ' '
	xor	bl, bl
	mov	cx, 80
	int	10h

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
clean_platform_line endp

print_platform proc
	push	ax
	push	bx
	push	dx
	push	cx

	call	clean_platform_line

	mov	ah, 02h
	mov	dh, 24
	mov	dl, platform_x
	int	10h

	mov	ah, 09h
	mov	al, 0dch
	mov	cx, platform_len
	mov	bl, 0eh
	int	10h

	pop	cx
	pop	dx
	pop	bx
	pop	ax
	ret
print_platform endp

clean_ball proc
	push	ax
	push	dx
	push	bx
	push	cx

	mov	ax, 0200h
	xor	bh, bh
	mov	dh, myball.y
	mov	dl, myball.x
	int	10h

	mov	ah, 09h
	mov	al, ' '
	xor	bl, bl
	mov	cx, 1
	int	10h

	pop	cx
	pop	bx
	pop	dx
	pop	ax
	ret
clean_ball endp

print_ball proc
	push	ax
	push	dx
	push	bx
	push	cx

	mov	ax, 0200h
	xor	bh, bh
	mov	dh, myball.y
	mov	dl, myball.x
	int	10h

	mov	ah, 09h
	mov	al, 0feh
	mov	bl, 0bh
	mov	cx, 1
	int	10h

	pop	cx
	pop	bx
	pop	dx
	pop	ax
	ret
print_ball endp

print_walls proc
	push	ax
	push	bx
	push	dx
	push	cx

	mov	ah, 2
	mov	dx, 1h
	xor	bx, bx
	int	10h

	mov	ah, 09h
	mov	al, 0c4h
	mov	bl, 07h
	mov	cx, 78
	int	10h

	mov	cx, 23
wall_loop:
	push	cx
	mov	ah, 2
	mov	dh, cl
	xor	dl, dl
	xor	bx, bx
	int	10h

	mov	ah, 09h
	mov	al, 0b3h
	mov	bl, 07h
	mov	cx, 1
	int	10h

	pop	cx
	push	cx
	mov	ah, 2
	mov	dh, cl
	mov	dl, 79
	xor	bx, bx
	int	10h

	mov	ah, 09h
	mov	al, 0b3h
	mov	bl, 07h
	mov	cx, 1
	int	10h
	pop	cx
	loop	wall_loop

	mov	ah, 2
	xor	dx, dx
	xor	bx, bx
	int	10h

	mov	ah, 09h
	mov	al, 0dah
	mov	bl, 07h
	mov	cx, 1
	int	10h

	mov	ah, 2
	mov	dl, 79
	xor	bx, bx
	int	10h

	mov	ah, 09h
	mov	al, 0bfh
	mov	bl, 07h
	mov	cx, 1
	int	10h

	pop	cx
	pop	dx
	pop	bx
	pop	ax
	ret
print_walls endp

move_ball proc
	call	clean_ball
	call	print_platform
	call	print_walls
	;call	 print_field
;
	push	ax
	mov	al, myball.angle
	xor	ah, ah
	add	myball.y, al
	mov	al, myball.dir
	add	myball.x, al
	pop	ax

	call	print_ball
	ret
move_ball endp

lose_check proc
	push	ax
	cmp	myball.y, 24
	jne	end_lose_check
	mov	al, platform_x
	cmp	myball.x, al
	jl	_lose
right_check:
	add	al, platform_len
	cmp	myball.x, al
	jle	end_lose_check
_lose:
	inc	lose
	call	stop_game
	int	10h
end_lose_check:
	pop	ax
	ret
lose_check endp

wall_check proc
	push	ax
	mov	ah, 'b'
	mov	al, myball.x
	cmp	al, 0
	je	cont_b
	cmp	al, 79
	je	cont_b
	jmp	check_vert
cont_b:
	mov	al, myball.y
	cmp	al, 0
	je	change_dir
	cmp	al, 24
	je     change_dir
check_vert:
	mov	ah, 'x'	 ; to recognize, that it's a vertial wall
	mov	al, myball.x
	cmp	al, 0
	je	change_dir
	cmp	al, 79
	je	change_dir

	mov	ah, 'y'	 ; to recognize	that it's a horizontal wall
	mov	al, myball.y
	cmp	al, 0
	je	change_dir
	cmp	al, 24
	je	change_dir
	jmp	end_wall_check
change_dir:
	call	change_ball_dir
end_wall_check:
	pop	ax
	ret
wall_check endp

brick_check	proc
	push	ax
	push	bx
	push	dx

	cmp	myball.x, 7	; bricks
	jle	end_brick_check	; starts in 8
	cmp	myball.x, 73	; and
	jge	end_brick_check	; ends in 71
	cmp	myball.y, 23
	jge	end_brick_check
;;;;;;;;;;;;; Y	coord set ;;;;;;;;;
	mov	dl, myball.y	; 2
	xor	dh, dh
	dec	dx		; 1
	shl	dl, 4		; 16
;;;;;;;;;;;;; X	coord set ;;;;;;;;;
	mov	bl, myball.x	; 11
	xor	bh, bh
	sub	bx, 8		; 11 - 8 = 3
	shr	bx, 2
	add	bx, dx		; 16 + 0
	shl	bx, 1		; 32

	test	bricks[bx], 8000h
	jnz	end_brick_check
	mov	ax, bricks[bx]
	or	bricks[bx], 8000h

	xor	bx, bx
	mov	dl, ah
	mov	dh, al
	mov	ah, 2h
	int	10h

	mov	ax, 0920h
	mov	cx, 4
	mov	bl, 1
	int	10h

	;mov	 ah, 'y'
	;call	 change_ball_dir


end_brick_check:
	pop	dx
	pop	bx
	pop	ax
	ret
brick_check	endp


change_ball_dir	proc
	push	cx
	xor	ch, ch
	mov	cl, -1
	cmp	ah, 'b'
	jne	vert_wall
	mov	al, myball.dir
	imul	cl
	mov	myball.dir, al
	mov	al, myball.angle
	imul	cl
	mov	myball.angle, al
	jmp	end_change_dir
vert_wall:
	cmp	ah, 'x'	 ; if ah = x ->	vertical wall
	jne	hor_wall
	mov	al, myball.dir
	imul	cl
	mov	myball.dir, al
	jmp	end_change_dir
hor_wall:
	mov	al, myball.angle
	imul	cl
	mov	myball.angle, al
end_change_dir:
	pop	cx
	ret
change_ball_dir	endp

stop_game proc
	push	ax
	push	bx
	push	cx
	push	dx

	call	clean_ball
	call	clean_platform_line
	mov	ah, 1
	mov	ch, 0bh
	mov	cl, 0bh
	int	10h
	mov	ax, 0003h		  ; cursor to the x:0, y:0
	xor	bh, bh
	xor	dx, dx
	int	10h

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
stop_game endp


gen_ball	proc
	push	ax
	push	cx
	push	dx
_COORDS:
	xor	ah, ah
	int	1ah
	mov	al, dl
	mov	cl, 7
	div	cl
	add	al, 2
	add	ah, 4
	mov	myball.x, al
	mov	myball.y, ah
_ANGLE:
	mov	cl, 1
	test	dl, 1
	jz	pos_angle
	mov	cl, -45
pos_angle:
	mov	myball.angle, cl
_DIR:
	mov	cl, 1
	test	dl, 4
	jz	neg_die
	dec	cl
	dec	cl
neg_die:
	mov	myball.dir, cl
	pop	dx
	pop	cx
	pop	ax
	ret
gen_ball	endp

gen_field	proc
	push	cx
	push	ax
	call offset_field
	mov	cx, 16
gen_loop:
	push	cx
	xor	bh, bh
	mov	bl, 16
	sub	bl, cl
	push	bx
	shl	bl, 2
	add	bl, 8
	mov	al, 1
	mov	ah, bl
	pop	bx
	shl	bx, 1
	mov	bricks[bx], ax
	pop	cx
	loop	gen_loop
	pop	ax
	pop	cx
	ret
gen_field	endp

offset_field	proc
	push	ax
	push	bx
	push	cx
	push	dx

	mov	cx, 21
offset_l1:
    push    cx
    mov	ax, cx
    mov	cx, 16
offset_l2:
    push    ax
    push    cx

    mov	dx, cx
    mov	bx, ax
    dec	bx
    push    bx
    shl	bx, 4
    mov	ax, 16
    sub	ax, dx
    add	bx, ax
    mov	dx, ax
    shl	bx, 1
    mov	ax, bricks[bx]
    cmp	ax, 0FFFFh
    je	no_data
    inc	al
no_data:
    pop	bx
    inc	bx
    shl	bx, 4
    add	bx, dx
    shl	bx, 1
    mov	bricks[bx], ax

    pop	cx
    pop	ax
loop	offset_l2
    pop	cx
loop	offset_l1
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
offset_field	endp

check_bricks_exist	 proc
	push	ax
	push	bx
	push	cx
	xor	ax, ax
	mov	cx, 384
check_exist_loop:
	cmp	ax, 4
	je	exit_exist_loop
	mov	bx, 384
	sub	bx, cx
	shl	bx, 1
	test	bricks[bx], 8000h
	jnz	 cont_exist_loop
	inc	ax
cont_exist_loop:
	loop check_exist_loop
exit_exist_loop:
	cmp	ax, 4
	jge	no_need_bricks
	mov	next_gen, 1
no_need_bricks:
	pop	cx
	pop	bx
	pop	ax
	ret
check_bricks_exist	 endp

print_field	proc
	push	ax
	push	cx
	push	bx
	push	dx

	mov	cx, 23
	shl	cx, 4
	mov	bx, cx
print_field_loop:
	push	cx
	push	bx
	sub	bx, cx
	shl	bx, 1
	mov	ax, bricks[bx]
	cmp	ax, 0FFFFh
	je	no_brick
	mov	cx, 09b1h
	push	cx
	test	ax, 8000h
	jz	is_brick
	pop	cx
	mov	cx, 0920h
	push	cx
is_brick:
	xor	bx, bx
	mov	dl, ah
	mov	dh, al
	mov	ah, 2h
	int	10h
	pop	ax
	mov	cx, 4
	mov	bl, 6
	int	10h
no_brick:
	pop	bx
	pop	cx
	loop	print_field_loop
	pop	dx
	pop	bx
	pop	cx
	pop	ax
	ret
print_field	endp

print	proc
	push	ax
	mov	ax, 0900h
	int	21h
	pop	ax
	ret
print	endp

; --- data --- ;
welcome_msg	db 'Welcome to the arcanoid game!!!'
		db 0ah,	0dh
		db 'Made by Khadiev Edem 21SE-2'
		db 0ah,	0dh
		db 'Press any key to start the game...', '$'
;
end_msg		db 0ah,	0dh, 0ah, 0dh
		db '###########################', 0ah, 0dh
		db '# Thanks for the game !!! #', 0ah, 0dh
		db '###########################', '$'
;
lose_msg	db 0ah,	0dh, '########## GAME OVER!!! ##########', '$'
;
platform_x	db 37
game_score	dw 0
wait_time	dw 0

lose		db 0
next_gen	db 0 ; if 1 then need to generate bricks

bricks		dw 384	dup(-1)

ball	struc
x		db 0
y		db 0
dir		db 1			; -1 ->	left dir, 1 -> rught dir.
angle		db 1
ball	ends

myball	ball	<?, ?, 1, 45>
platform_len	equ 10
gen_checker	db 0

ARROW_LEFT	equ	4bh
ARROW_RIGHT	equ	4dh
ESCAPE		equ	1

old_int_09h	dd	?

end	start
