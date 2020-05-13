.model tiny
.code


locals @@

org 100h


VIDEOSEG				equ 0b800h
SPACE 					equ 20h 
HORIZONTAL_EDGE			equ 0cdh
VERTIKAL_EDGE			equ 0bah
LEFT_TOP_CORNER			equ 0c9h
RIGHT_UP_CORNER			equ 0bbh
LEFT_DOWN_CORNER 		equ 0c8h
RIGHT_DOWN_CORNER		equ 0bch

BACK_COLOR				equ 070h
SHADOW_COLOR			equ 013h

ARGST					equ 80h
			

Start:	
	mov si, offset ARGS
	mov bx, S_ARGS

	call SCANF
	mov bl, byte ptr[ARGS]
	mov bh, byte ptr[ARGS + 1]
	mov dl, byte ptr[ARGS + 2]
	mov dh, byte ptr[ARGS + 3]


;ofset
xor ax, ax

mov al, 80
mul bh
xor bh, bh
add ax, bx
add ax, ax

mov di, ax


;end_ofset

	mov ah, BACK_COLOR
	mov al, RIGHT_UP_CORNER	
	push ax
	mov al, HORIZONTAL_EDGE	
	push ax
	mov al, LEFT_TOP_CORNER	
	push ax
	
	push ax ; fiction push
	call DrawTable	

	mov ah, BACK_COLOR
	mov al, VERTIKAL_EDGE
	push ax
	mov al, SPACE
	push ax
	mov al, VERTIKAL_EDGE
	push ax

xor cx, cx
mov cl, dh ;number of iteration
sub cl, 2
@@fill:
	sub cx, 1
	push cx
	call Drawtable
	;call Drawtable
	pop cx
	cmp cx, 0
	jne @@fill



	mov ah, BACK_COLOR
	mov al, RIGHT_DOWN_CORNER
	push ax
	mov al, HORIZONTAL_EDGE	
	push ax
	mov al, LEFT_DOWN_CORNER 
	push ax
	push ax ; fiction push

	call Drawtable

	add di, 2 ;shift right
	dec dl ; resize

	mov ah, SHADOW_COLOR
	mov al, SPACE
	push ax
	mov al, SPACE
	push ax
	mov al, SPACE
	push ax
	push ax ; fiction push

	call Drawtable

	mov ax, 4c00h
	int 21h

ARGS	DB	4 DUP(?)
S_ARGS	equ	$ - ARGS
			

;============================
; Inputs:	si - adress array bytes
;			bx - arraysize
; Outputs:	parse string to array
; Destroys: 	ax, bx, cx, dx, di, si
;============================

SCANF		PROC
	mov di, ARGST		 ;arg start
	
	xor ch, ch
	mov cl, byte ptr[di] ; kol args

	cmp cx, 0h
	je @@end 	;if cx == 0

	inc di

@@args_loop:

; if readed all args - end

	cmp bx, 0h
	je @@end

	mov al, ' '
	repe scasb

	cmp byte ptr[di - 1], ' '
	je @@end

	xor ax, ax
	xor dx, dx

@@num_loop:
;TO DIGHT

	mov dl, 10
	mul dl					;ax *= 10

	mov dl, byte ptr [di - 1]
	sub dl, '0' 			; dl = [di] - '0'

	add al, dl
	adc ah, 0h	; ax += dl

; if last sym...

	cmp cx, 0h
	je @@write_end

	dec cx
	inc di
	
	;if !SPACE - continue

	cmp byte ptr [di - 1], ' '
	jne @@num_loop

;out

	mov byte ptr[si], al

	inc si
	dec bx

	jmp @@args_loop

@@write_end:
	mov byte ptr[si], al
	dec bx

@@end:
	ret	

SCANF		ENDP

;========================
;Inputs: 	ah
;			bh
;			bl
;========================
DRAWTABLE	PROC

	push bp
	mov bp, sp 
	mov cx, VIDEOSEG
	mov es, cx
	mov cx, bx	; save bx

;LEFT_TOP_CORNER	
	

 	mov ax, [bp + 6] ; push bp, cx	
	mov	word ptr es:[di], ax

	mov bx, cx
	
;UP_LINE
	add di, 02h

	xor cx, cx
	add cl, dl	; cx = sizeX
	sub cl, 02h	; cx = sizeX - 2

	mov ax, [bp + 8]	
	cld	
	rep stosw

	mov cx, bx

;RIGHT_UP_CORNER	

	;mov ah, BACK_COLOR
	;mov al, RIGHT_UP_CORNER	
	mov ax, [bp + 10]
	mov word ptr es:[di], ax
 
	mov cx, bx
	add di, 2

	mov al, SPACE
	mov ah, SHADOW_COLOR
	mov	word ptr es:[di], ax


	;xor dh, dh
	xor cx, cx
	mov cl, dl
	add di, 80*2
	sub di, cx
	sub di, cx

	


	pop bp
	ret

DrawTable	endp
																		
																																																	
end 	start	
                                                                                                                                           
