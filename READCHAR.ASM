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
	cmp	platform_x, 79 - platform_len
	je	end_read
	inc	platform_x
	call	print_platform
end_read:
	pop	dx
	pop	ax
	ret
read_character endp

;setup_keyboard	 proc
;	 push	 ax
;	 push	 dx
;
;	 mov	 ax, 3509h
;	 int	 21h
;
;	 mov	 word ptr old_int_09h, bx
;	 mov	 word ptr old_int_09h +	2, es
;
;	 mov	 ax, 2509h
;	 mov	 dx, offset new_int_09h
;	 int	 21h
;
;	 pop	 dx
;	 pop	 ax
;	 ret
;setup_keyboard	 endp
;
;new_int_09h	 proc	 far
;	 pushf
;	 push	 ax
;
;	 in	 al, 60h
;	 cmp	 al, ESCAPE
;	 jne	 other_key_press
;	 sti
;	 call	 stop_game
;	 mov	 dx, offset end_msg
;	 call	 print
;	 int	 20h
;other_key_press:
;	 cmp	 al, ARROW_LEFT			; left
;	 jne	 no_left_press
;	 sti
;	 cmp	 platform_x, 0
;	 je	 end_read
;	 dec	 platform_x
;	 jmp	 end_read
;no_left_press:
;	 cmp	 al, ARROW_RIGHT		 ; right
;	 jne	 not_needed_key
;	 sti			   ; if	no right then end
;	 cmp	 platform_x, 79	- platform_len
;	 je	 end_read
;	 inc	 platform_x
;	 jmp	 end_read
;not_needed_key:
;	 popf
;	 jmp	 dword ptr cs:[old_int_09h]
;end_read:
;	 in	 al, 61h
;	 push	 ax
;	 or	 al, 80h
;	 out	 61h, al
;	 pop	 ax
;	 out	 61h, al
;	 cli
;	 mov	 al, 20h
;	 out	 20h, al
;	 pop	 ax
 ;	 popf
;	 iret
;new_int_09h	 endp