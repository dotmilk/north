        mov edi, 0xb8000		; Clear the screen
	mov ax, 0x0720
	mov cx, 2000
	rep stosw
