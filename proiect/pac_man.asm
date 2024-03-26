.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Pac-Man",0
area_width EQU 672
area_height EQU 864
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include puncte.inc

punctaj dd 0

buton_x equ 50
buton_y equ 10
buton_size equ 40

error_iesire_matrice db "Ati incercat sa desenati un pixel pe afara: x = %d, y = %d, culoare = %x",13,10,0
error_suprapunere_culoare_diferita db "Well...s-a pus o alta culoare: x = %d, y = %d, culoare = %x",13,10,0
msg db "culoare %x",13,10,0

pacman_lx dd 314
pacman_ly dd 614
pacman_x dd 314
pacman_y dd 614

pacman_lugime dd 48
pacman_inaltime dd 48

increment_lx dd 0
increment_ly dd 0

increment_x dd 0
increment_y dd 0
	
npuncte dd 244	
; npuncte dd 244
fantomite  	dd 314, 326, 0 ;red 
			dd 314, 470, 0 ; pink
			dd 422, 398, 0 ;portocaliu
			dd 206, 398, 0	;cyan
		   
fantomite_last  dd 314, 326, 0 ;red 
			dd 314, 470, 0 ; pink
			dd 422, 398, 0 ;portocaliu
			dd 206, 398, 0	;cyan
		   
fantomite_inc dd 0, 0
			dd 0, 0
			dd 0, 0
			dd 0, 0
			
fantomite_lastinc dd 0, 0
			dd 0, 0
			dd 0, 0
			dd 0, 0		   
game_over_bool db 0

random_frame dd 0

contor_invincibilitate dd 0

debug db 0

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
_get_pixel proc
	push ebp
	mov ebp, esp 
	;corp 
	mov eax, [ebp+arg2]
	mov ecx, [esp+arg1]
	cmp ecx,area_width
	jge it_s_not_ok_now
	cmp ecx,0
	jl it_s_not_ok_now
	cmp eax,area_height
	jge it_s_not_ok_now
	cmp eax,0
	jl it_s_not_ok_now
	mov eax, [ebp+arg2]	;eax = y
	mov ebx,area_width
	mul ebx  ;eax = y* area_width
	add eax,[ebp+arg1]	;eax= y* area_width+x
	shl eax, 2;eax= (y* area_width+x)*4
	add eax, area	
	mov ebx,dword ptr[eax]
	mov eax, ebx
	jmp finish_make_pixel
it_s_not_ok_now:
	cmp debug, 0
	je finish_make_pixel
	pusha
	push [ebp + arg2]
	push [ebp +arg1]
	push offset error_iesire_matrice
	call printf
	add esp,16
	popa
finish_make_pixel:	
	;endcorp
	mov ESP, EBP
	pop EBP
	ret
_get_pixel endp
get_pixel macro x, y
	push ebx
	push ecx
	mov edi, y
	mov ebx, x
	push edi
	push ebx
	call _get_pixel
	add esp, 8
	pop ecx
	pop ebx
endm 
_make_pixel proc
	push ebp
	mov ebp, esp
	;corp 
	mov eax, [ebp+arg2]
	mov ecx, [esp+8]
	cmp ecx,area_width
	jge it_s_not_ok_now
	cmp ecx,0
	jl it_s_not_ok_now
	cmp eax,area_height
	jge it_s_not_ok_now
	cmp eax,0
	jl it_s_not_ok_now
	mov eax, [ebp+arg2]	;eax = y
	mov ebx,area_width
	mul ebx  ;eax = y* area_width
	add eax,[ebp+8]	;eax= y* area_width+x
	shl eax, 2;eax= (y* area_width+x)*4
	add eax, area	
	mov edi, [ebp+arg3]
	cmp dword ptr[eax], 000000h
	je culoare_neagra
	cmp debug, 0
	je culoare_neagra
	pusha
	push [ebp + arg3]
	push [ebp + arg2]
	push [ebp +arg1]
	push offset error_suprapunere_culoare_diferita
	call printf
	add esp,16
	popa
culoare_neagra:
	mov dword ptr[eax], edi
	jmp finish_make_pixel
it_s_not_ok_now:
	cmp debug, 0
	je finish_make_pixel
	pusha
	push [ebp + arg3]
	push [ebp + arg2]
	push [ebp +arg1]
	push offset error_iesire_matrice
	call printf
	add esp,16
	popa
finish_make_pixel:	
	;endcorp
	mov ESP, EBP
	pop EBP
	ret
_make_pixel endp

make_pixel macro x, y, culoare
	pusha
	mov esi, culoare
	mov edi, y
	mov ebx, x
	push esi
	push edi
	push ebx
	call _make_pixel
	add esp, 12
	popa
endm
_eat_pixeli proc
	push ebp
	mov ebp, esp
	;corp 
	mov ecx, npuncte
	mov ebx, 0
looping_punct:	
	mov esi,ebx
	add esi,8
	cmp puncte[esi], 0
	je increment
	cmp puncte[esi], 1
	je no_power
	;nu merge corect, daca e pornit e doar pornit si vice versa, nu poate comuta corect
	;mov contor_invincibilitate, 50
no_power:
	mov edi, pacman_x
	cmp puncte[ebx],edi
	jl increment
	add edi,48
	mov eax, puncte[ebx]
	add eax, 5
	cmp eax,edi
	jg increment
	mov edi, pacman_y
	cmp puncte[ebx + 4], edi
	jl increment
	add edi,48
	mov eax, puncte[ebx + 4]
	add eax, 5
	cmp eax,edi
	jg increment
	inc punctaj
	mov puncte[esi],0
increment:	
	add ebx,12
	dec ecx
	cmp ecx,0
	jne looping_punct
	;endcorp
	mov ESP, EBP
	pop EBP
	ret
_eat_pixeli endp 
eat_pixeli macro 
pusha
call _eat_pixeli
popa
endm
; ciocniri_fantoma_red macro 
	; call _ciocniri_fantoma_red
; endm
; _ciocniri_fantoma_red proc
	; push EBP
    ; mov EBP, ESP
	; corp proc
	; mov eax,fantomaRed_x 
	; mov fantomaRed_lx,eax
	; mov eax,fantomaRed_y 
	; mov fantomaRed_ly,eax
	; cmp increment_x, 0
	; je if_y
	; cmp increment_x, -1
	; je stanga
	; jmp dreapta
; if_y:
	; cmp increment_y, 1
	; je jos
	; jmp sus
	
; sus:
	; mov ecx,pacman_x
	; add ecx,pacman_lugime
	; dec ecx
; bucla_s:
	; mov edx,pacman_y
	; dec edx
	; get_pixel ecx, edx 
	; cmp eax,02121deh
	; je end_ifuri 
	; dec ecx
	; cmp ecx,pacman_x
	; jne bucla_s
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	; je end_ifuri
	
; stanga:
	; mov ecx,pacman_y
	; add ecx,pacman_inaltime
	; dec ecx
; bucla_st:
	; mov edx,pacman_x
	; dec edx
	; get_pixel edx, ecx 
	; cmp eax,02121deh
	; je end_ifuri
	; dec ecx 
	; cmp ecx,pacman_y
	; jne bucla_st
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	; je end_ifuri
	
; dreapta:
	; mov ecx, pacman_y
	; add ecx, pacman_inaltime
	; dec ecx
; bucla_dr:
	; mov edx, pacman_x
	; add edx, pacman_lugime
	; get_pixel edx, ecx 
	; cmp eax,02121deh
	; je end_ifuri
	; dec ecx 
	; cmp ecx,pacman_y
	; jne bucla_dr
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	; je end_ifuri
; jos:
	; mov ecx,pacman_x
	; add ecx,pacman_lugime
	; dec ecx
; bucla_j:
	; mov edx,pacman_y
	; add edx,pacman_inaltime
	; get_pixel ecx, edx 
	; cmp eax,02121deh
	; je end_ifuri
	; dec ecx 
	; cmp ecx,pacman_x
	; jne bucla_j
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	; je end_ifuri
; end_ifuri:
; end corp 
	; mov ESP, EBP
    ; pop EBP
	; ret
; _ciocniri_fantoma_red endp
; ciocniri macro 
	; call _ciocniri
; endm

ciocniri macro 
	call _ciocniri
endm
_ciocniri proc
	push EBP
    mov EBP, ESP
	;corp proc
	mov eax,pacman_x 
	mov pacman_lx,eax
	mov eax,pacman_y 
	mov pacman_ly,eax
	cmp increment_x, 0
	je if_y
	cmp increment_x, -1
	je stanga
	jmp dreapta
if_y:
	cmp increment_y, 1
	je jos
	jmp sus
	
sus:
	mov ecx,pacman_x
	add ecx,pacman_lugime
	dec ecx
bucla_s:
	mov edx,pacman_y
	dec edx
	get_pixel ecx, edx 
	cmp eax, 02121deh
	je margine
	cmp eax, 0ff0000h
	je game_over_red
	cmp eax, 0FFB8DEh
	je game_over_cyan
	cmp eax, 0FFB847h
	je game_over_pink
	cmp eax, 00FFDEh
	je game_over_portocaliu	
	dec ecx
	cmp ecx,pacman_x
	jge bucla_s
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	jmp end_ifuri
	
stanga:
	mov ecx,pacman_y
	add ecx,pacman_inaltime
	dec ecx
bucla_st:
	mov edx,pacman_x
	dec edx
	get_pixel edx, ecx 
	cmp eax, 02121deh
	je margine
	cmp eax, 0ff0000h
	je game_over_red
	cmp eax, 0FFB8DEh
	je game_over_cyan
	cmp eax, 0FFB847h
	je game_over_pink
	cmp eax, 00FFDEh
	je game_over_portocaliu
	dec ecx 
	cmp ecx,pacman_y
	jge bucla_st
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	jmp end_ifuri
	
dreapta:
	mov ecx, pacman_y
	add ecx, pacman_inaltime
	dec ecx
bucla_dr:
	mov edx, pacman_x
	add edx, pacman_lugime
	get_pixel edx, ecx 
	cmp eax, 02121deh
	je margine
	cmp eax, 0ff0000h
	je game_over_red
	cmp eax, 0FFB8DEh
	je game_over_cyan
	cmp eax, 0FFB847h
	je game_over_pink
	cmp eax, 00FFDEh
	je game_over_portocaliu
	dec ecx 
	cmp ecx,pacman_y
	jge bucla_dr
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	jmp end_ifuri
jos:
	mov ecx,pacman_x
	add ecx,pacman_lugime
	dec ecx
bucla_j:
	mov edx,pacman_y
	add edx,pacman_inaltime
	get_pixel ecx, edx 
	cmp eax, 02121deh
	je margine
	cmp eax, 0ff0000h
	je game_over_red
	cmp eax, 0FFB8DEh
	je game_over_cyan
	cmp eax, 0FFB847h
	je game_over_pink
	cmp eax, 00FFDEh
	je game_over_portocaliu
	dec ecx 
	cmp ecx,pacman_x
	jge bucla_j
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	jmp end_ifuri
game_over_red:
	cmp contor_invincibilitate, 0
	jne death_red
	mov game_over_bool, 1
	mov increment_x, 0
	mov increment_lx, 0
	mov increment_y, 0
	mov increment_ly, 0
	jmp end_ifuri
death_red:
	mov fantomite[0], 314
	mov fantomite[4], 326
	add punctaj, 50
	jmp end_ifuri
game_over_pink:
	cmp contor_invincibilitate, 0
	jne death_pink
	mov game_over_bool, 1
	mov increment_x, 0
	mov increment_lx, 0
	mov increment_y, 0
	mov increment_ly, 0
	jmp end_ifuri
death_pink:
	mov fantomite[12], 314
	mov fantomite[16], 470
	add punctaj, 50
	jmp end_ifuri
game_over_cyan:
	cmp contor_invincibilitate, 0
	jne death_cyan
	mov game_over_bool, 1
	mov increment_x, 0
	mov increment_lx, 0
	mov increment_y, 0
	mov increment_ly, 0
	jmp end_ifuri
death_cyan:
	mov fantomite[24], 422
	mov fantomite[28], 398
	add punctaj, 50
	jmp end_ifuri
game_over_portocaliu:
	cmp contor_invincibilitate, 0
	jne death_portocaliu
	mov game_over_bool, 1
	mov increment_x, 0
	mov increment_lx, 0
	mov increment_y, 0
	mov increment_ly, 0
	jmp end_ifuri
death_portocaliu:
	mov fantomite[36], 206
	mov fantomite[40], 398
	add punctaj, 50
	jmp end_ifuri
margine:
	mov eax, increment_lx
	cmp eax, increment_x
	je ix_0
	mov increment_x, eax
	jmp iy
ix_0:
	mov increment_x, 0
	mov increment_lx, 0
iy:
	mov eax, increment_ly
	cmp eax, increment_y
	je iy_0
	mov increment_y, eax
	jmp end_ixy
iy_0:
	mov increment_y, 0
	mov increment_ly, 0
end_ixy:
end_ifuri:
;end corp 
	mov ESP, EBP
    pop EBP
	ret
_ciocniri endp
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_negru
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0000000h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

_linie_orizontala proc 
	push EBP
	mov EBP, ESP 
;corp_procedura	
	mov ecx, [ebp + arg3]
	mov eax, [ebp +arg1]
bucla_linie:
	make_pixel eax, [ebp+arg2], [ebp+arg4]
	add eax, 1
	loop bucla_linie
;end corp
	mov ESP, EBP
	pop EBP
	ret
_linie_orizontala endp

linie_orizontala macro x, y, len, culoare
	pusha
	mov edi, culoare
	mov ebx, len
	mov edx, y
	mov eax, x
	push edi 
	push ebx
	push edx
	push eax
	CALL _linie_orizontala
	add esp, 16
	popa
endm

_linie_verticala proc
 	push EBP
	mov EBP, ESP 
;corp_procedura	
	mov ecx, [ebp + arg3]
	mov eax, [ebp+arg2]
bucla_linie:
	make_pixel [ebp +arg1], eax, [ebp+arg4]
	add eax, 1
	loop bucla_linie
;end corp
	mov ESP, EBP
	pop EBP
	ret
_linie_verticala endp

linie_verticala macro x, y, len, culoare
	pusha
	mov edi, culoare
	mov ebx, len
	mov edx, y
	mov eax, x
	push edi 
	push ebx
	push edx
	push eax
	CALL _linie_verticala
	add esp, 16
	popa
endm


_Drept_plin  proc
	push EBP
	mov EBP, ESP 
	mov ecx, [ebp+arg4]
	mov eax, [ebp+arg1]
	;corp procedura
looping:
	linie_verticala eax, [ebp+arg2], [ebp+arg3],[ebp+24]
	inc eax
	loop looping 
	;end procedura
	mov ESP, EBP
	pop EBP
	ret
_Drept_plin endp

drept_plin macro x, y, latime, inaltime, culoare
	pusha
	push culoare
	push latime
	push inaltime
	push y
	push x
	call _Drept_plin
	add esp, 20
	popa
endm

_Drept_gol  proc
	push EBP
	mov EBP, ESP 
	;corp procedura
	mov eax, [ebp+8]
	mov ebx, [ebp+arg2]
	mov ecx, [ebp+arg3]
	mov edx, [ebp+arg4]
	mov esi, [ebp+28]
	drept_plin eax, ebx, ecx, edx, esi
	;drept_plin [ebp+8]-edx,[ebp+arg2]-edx,[ebp+arg4]- 2 * edx, 000000h
	mov edx, [ebp + 24]
	shl edx, 1
	mov eax, [ebp +arg1]
	add eax, [ebp + 24]
	mov ebx, [ebp + arg2]
	add ebx, [ebp + 24]
	mov ecx, [ebp + arg3]
	sub ecx, edx
	mov esi, [ebp + arg4]
	sub esi, edx
	drept_plin eax, ebx, ecx, esi, 0000000h
	;end procedura
	mov ESP, EBP
	pop EBP
	ret
_Drept_gol endp

drept_gol macro x, y, latime, inaltime, grosime, culoare
	pusha
	push culoare
	push grosime
	push inaltime
	push latime
	push y
	push x
	call _Drept_gol 
	add esp, 24
	popa
endm

_make_fantome_move_red proc
	push EBP
	mov EBP, ESP
	; corp 
	mov eax, fantomite_inc[0]
	mov fantomite_lastinc[0], eax
	mov eax, fantomite_inc[4]
	mov fantomite_lastinc[4], eax
	
	mov ebx, pacman_x
	sub ebx, fantomite[0]
	mov ecx, pacman_y
	sub ecx, fantomite[4]
	cmp ebx, 0
	jl pacman_maimicx
	cmp ecx, 0
	jl xpozyneg
	;xpozypoz
	cmp ebx, ecx
	jg miscare_ox_xpozypoz
	;miscare_oy_xpozypoz
	mov fantomite_inc[0], 0
	mov fantomite_inc[4], 1
	jmp finally
miscare_ox_xpozypoz:
	mov fantomite_inc[0], 1
	mov fantomite_inc[4], 0
	jmp finally
xpozyneg:
	mov eax, ecx
	mov ecx, -1
	mul ecx
	mov ecx, eax
	cmp ebx, ecx
	jg miscare_ox_xpozyneg
	;miscare_oy_xpozyneg
	mov fantomite_inc[0], 0
	mov fantomite_inc[4], -1
	jmp finally
miscare_ox_xpozyneg:
	mov fantomite_inc[0], 1
	mov fantomite_inc[4], 0
	jmp finally
pacman_maimicx:
	cmp ebx, 0
	jl xnegyneg
	;xnegypoz
	mov eax, ebx
	mov ebx, -1
	mul ebx
	mov ebx, eax
	cmp ebx, ecx
	jg miscare_ox_xnegypoz
	;miscare_oy_xnegypoz
	mov fantomite_inc[0], 0
	mov fantomite_inc[4], 1
	jmp finally
miscare_ox_xnegypoz:
	mov fantomite_inc[0], -1
	mov fantomite_inc[4], 0
	jmp finally
xnegyneg:
	mov eax, ecx
	mov ecx, -1
	mul ecx
	mov ecx, eax
	mov eax, ebx
	mov ebx, -1
	mul ebx
	mov ebx, eax
	cmp ebx, ecx
	jg miscare_ox_xnegyneg
	;miscare_oy_xnegyneg
	mov fantomite_inc[0], 0
	mov fantomite_inc[4], -1
	jmp finally
miscare_ox_xnegyneg:
	mov fantomite_inc[0], -1
	mov fantomite_inc[4], 0
	jmp finally
finally:
	; end corp 
	mov ESP, EBP
	pop EBP
	ret 4
_make_fantome_move_red endp
; _make_fantome_move_red proc
	; push EBP
	; mov EBP, ESP
	; corp 
	; mov edx,[ebp+arg1]
	; cmp edx,0
	; je aaaaah_ma_mananca_red
	; mov eax, pacman_x
	; sub eax, fantomite[0]
	; cmp eax, 0
	; jl x_mai_mic_zero
	; mov ebx, pacman_y
	; sub ebx, fantomite[4]
	; cmp ebx, 0
	; jl c1
	; aici e c4
	; mov edi,eax
	; mov eax, ebx
	; mov edx,0
	; mov ecx, -1
	; mul ecx
	; cmp eax,edi
	; jg c4
; c4:
	; inc fantomite[0] 
	
	; drept_plin fantomite[0],fantomite[4],pacman_lugime,pacman_inaltime,0ff0000h
	
; c1:	


; x_mai_mic_zero:	
	; mov eax, pacman_y
	; sub eax, fantomite[4]
	; cmp eax, 0
	; jl c2
	; aici e c3
; c2:	

; aaaaah_ma_mananca_red:
	
	; end corp 
	; mov ESP, EBP
	; pop EBP
	; ret 4
; _make_fantome_move_red endp
make_fantome_move_red macro mod_pacman
	pusha
	push mod_pacman
	call _make_fantome_move_red
	popa
endm 

ciocniri_red macro 
	call _ciocniri_red
endm
_ciocniri_red proc
	push EBP
    mov EBP, ESP
	;corp proc
	mov eax,fantomite[0] 
	mov fantomite_last[0],eax
	mov eax,fantomite[4]
	mov fantomite_last[4],eax
	cmp fantomite_inc[0], 0
	je if_y
	cmp fantomite_inc[0], -1
	je stanga
	jmp dreapta
if_y:
	cmp fantomite_inc[4], 1
	je jos
	jmp sus
	
sus:
	mov ecx,fantomite[0] 
	add ecx,pacman_lugime
	dec ecx
bucla_s:
	mov edx,fantomite[4]
	dec edx
	get_pixel ecx, edx 
	cmp eax, 02121deh
	je margine
	dec ecx
	cmp ecx,pacman_x
	jge bucla_s
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	jmp end_ifuri
	
stanga:
	mov ecx,fantomite[4]
	add ecx,pacman_inaltime
	dec ecx
bucla_st:
	mov edx,fantomite[0] 
	dec edx
	get_pixel edx, ecx 
	cmp eax, 02121deh
	je margine
	dec ecx 
	cmp ecx,pacman_y
	jge bucla_st
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	jmp end_ifuri
	
dreapta:
	mov ecx, fantomite[4]
	add ecx, pacman_inaltime
	dec ecx
bucla_dr:
	mov edx, fantomite[0]
	add edx, pacman_lugime
	get_pixel edx, ecx 
	cmp eax, 02121deh
	je margine
	dec ecx 
	cmp ecx,pacman_y
	jge bucla_dr
	; mov eax, pacman_x
	; add eax, increment_x
	; mov pacman_x, eax
	jmp end_ifuri
jos:
	mov ecx,fantomite[0]
	add ecx,pacman_lugime
	dec ecx
bucla_j:
	mov edx,fantomite[4]
	add edx,pacman_inaltime
	get_pixel ecx, edx 
	cmp eax, 02121deh
	je margine
	dec ecx 
	cmp ecx,pacman_x
	jge bucla_j
	; mov eax, pacman_y
	; add eax, increment_y
	; mov pacman_y, eax
	jmp end_ifuri
margine:
	mov eax, fantomite_lastinc[0]
	cmp eax, fantomite_inc[0]
	je ix_0
	mov fantomite_inc[0], eax
	jmp iy
ix_0:
	mov fantomite_inc[0], 0
	mov fantomite_lastinc[0], 0
iy:
	mov eax, fantomite_lastinc[4]
	cmp eax, fantomite_inc[4]
	je iy_0
	mov fantomite_inc[4], eax
	jmp end_ixy
iy_0:
	mov fantomite_inc[4], 0
	mov fantomite_lastinc[4], 0
end_ixy:
end_ifuri:
;end corp 
	mov ESP, EBP
    pop EBP
	ret
_ciocniri_red endp

afisare_puncte proc
	push EBP
	mov EBP, ESP
	;corp_procedura
	mov ecx, npuncte
	mov ebx,0
looping_punct:	
	mov edx,ebx
	add edx,4
	cmp puncte[edx+4],0
	je increment
	cmp puncte[edx+4], 2
	je big_chungus
	drept_plin puncte[ebx], puncte[edx], 6, 6, 0FFB8B5h
	jmp final_colorare
increment:
	drept_plin puncte[ebx], puncte[edx], 6, 6, 0
	jmp final_colorare
big_chungus:
	mov esi, puncte[ebx]
	mov edi, puncte[edx]
	sub esi, 4
	sub edi, 4
	drept_plin esi, edi, 14, 14, 0FFB8B5h
final_colorare:
	add ebx,12
	dec ecx
	cmp ecx,-1
	jne looping_punct
	;end corp 
	mov ESP, EBP
	pop EBP
	ret 
afisare_puncte endp

randomise_var macro max_value
	push max_value
	call _randomise_var
endm

_randomise_var proc
	push EBP
    mov EBP, ESP
	
	rdtsc
	mov ebx, [ebp + arg1]
	mov edx, 0
	div ebx
	mov eax, edx
	
	mov ESP, EBP
    pop EBP
	ret 4
_randomise_var endp

random_event macro
	pusha
	call _random_event
	popa
endm

_random_event proc
	push EBP
    mov EBP, ESP
	
	cmp random_frame, 0
	jg skip_frame
	pusha
	mov eax, npuncte
	dec eax
	randomise_var eax
	mov ebx, 12
	mov edx, 0
	mul ebx
	mov puncte[eax + 8], 2
	popa
	pusha
	randomise_var 100
	mov random_frame, eax
	popa
	jmp end_rnd
skip_frame:
	dec random_frame
end_rnd:
	mov ESP, EBP
    pop EBP
	ret
_random_event endp
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	cmp game_over_bool, 1
	jne not_game_over
	;game over
	make_text_macro 'G', area, 326, 410
	make_text_macro 'G', area, 336, 410
	jmp final_draw
not_game_over:	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 3
	jz evt_key
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	inc counter
	get_pixel [ebp+arg2], [ebp+arg3]
	push eax
	push offset msg
	call printf
	add ESP, 8

	jmp afisare_litere
	
evt_key:
	inc counter
	
	mov eax, pacman_x
	mov pacman_lx, eax
	mov eax, pacman_y
	mov pacman_ly, eax
	
	mov eax, increment_x
	mov increment_lx, eax
	mov eax, increment_y
	mov increment_ly, eax
	
	mov eax, [ebp + arg2]
	
	cmp eax, 057h
	jne skip_up
	mov increment_x, 0
	mov increment_y, -1
	
	jmp final_miscare
skip_up:

	cmp eax, 041h
	jne skip_left
	mov increment_x, -1
	mov increment_y, 0
	jmp final_miscare
skip_left:

	cmp eax, 053h
	jne skip_down
	mov increment_x, 0
	mov increment_y, 1
	jmp final_miscare
skip_down:

	cmp eax, 044h
	jne skip_right
	mov increment_x, 1
	mov increment_y, 0
skip_right:
final_miscare:
	jmp afisare_litere
evt_timer:
	inc counter

afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	mov ebx, 10
	mov eax, punctaj
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 652, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 642, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 632, 10
	
	make_text_macro 'S', area, 582, 10
	make_text_macro 'C', area, 592, 10
	make_text_macro 'O', area, 602, 10
	make_text_macro 'R', area, 612, 10
	
	make_text_macro 'I', area, 492, 10
	make_text_macro 'N', area, 502, 10
	make_text_macro 'V', area, 512, 10
	
	mov ebx, 10
	mov eax, contor_invincibilitate
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 552, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 542, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 532, 10
	
	; colt1 (stanga sus)
	drept_plin 0  , 74 , 336, 12 , 02121deh
	drept_plin 0  , 74 , 14 , 240, 02121deh
	drept_plin 0  , 302, 132, 12 , 02121deh
	
	; l1 
	drept_plin 122, 302, 12 , 144 , 02121deh
	; drept_plin 0  , 386, 132, 12 , 02121deh
	
	; colt2 (dreapta sus)
	drept_plin 338, 74 , 336, 12 , 02121deh
	drept_plin 662, 74 , 12 , 240, 02121deh
	drept_plin 542, 302, 132, 12 , 02121deh
	
	; l2
	drept_plin 542, 302, 12 , 144 , 02121deh
	; drept_plin 540, 386, 132, 12 , 02121deh
	
	; colt3 (stanga jos)
	drept_plin 0  , 806, 336, 12 , 02121deh
	drept_plin 0  , 530, 14 , 288, 02121deh
	drept_plin 0  , 530, 132, 12 , 02121deh
	
	; l3
	drept_plin 122, 446, 12 , 96 , 02121deh
	; drept_plin 0  , 446, 132, 12 , 02121deh
	
	; colt4 (dreapta jos)
	drept_plin 338, 806, 336, 12 , 02121deh
	drept_plin 662, 530, 12 , 288, 02121deh
	drept_plin 542, 530, 132, 12 , 02121deh
	
	; l4
	drept_plin 542, 446, 12 , 96 , 02121deh
	; drept_plin 540, 446, 132, 12 , 02121deh
	
	; trebe dat mirror
	; 1 
	drept_plin 62 , 134, 72 , 48 , 02121deh
	; 2
	drept_plin 182, 134, 96 , 48 , 02121deh
	; 3
	drept_plin 62 , 230, 72 , 24 , 02121deh
	; 4
	drept_plin 182, 230, 24 , 168, 02121deh
	drept_plin 182, 302, 96 , 24 , 02121deh
	; 5
	drept_plin 182, 446, 24 , 96 , 02121deh
	; 6
	drept_plin 182, 590, 96 , 24 , 02121deh
	; 7
	drept_plin 62 , 734, 216, 24 , 02121deh
	drept_plin 182, 662, 24 , 96 , 02121deh
	; 8
	drept_plin 62 , 590, 72 , 24 , 02121deh
	drept_plin 110, 590, 24 , 96 , 02121deh
	; p2
	drept_plin 0  , 662, 62 , 24 , 02121deh
	
	; mirror
	; 1 
	drept_plin 542, 134, 72 , 48 , 02121deh
	; 2
	drept_plin 398, 134, 96 , 48 , 02121deh
	; 3
	drept_plin 542, 230, 72 , 24 , 02121deh
	; 4
	drept_plin 470, 230, 24 , 168, 02121deh
	drept_plin 398, 302, 96 , 24 , 02121deh
	; 5
	drept_plin 470, 446, 24 , 96 , 02121deh
	; 6
	drept_plin 398, 590, 96 , 24 , 02121deh
	; 7
	drept_plin 398, 734, 216, 24 , 02121deh
	drept_plin 470, 662, 24 , 96 , 02121deh
	; 8
	drept_plin 542, 590, 72 , 24 , 02121deh
	drept_plin 542, 590, 24 , 96 , 02121deh
	; p2
	drept_plin 614, 662, 60 , 24 , 02121deh
	
	; p1
	drept_plin 326, 74 , 24 , 108, 02121deh
	
	; T1
	drept_plin 254, 230, 168, 24 , 02121deh
	drept_plin 326, 230, 24 , 96 , 02121deh 
	
	; T2
	drept_plin 254, 518, 168, 24 , 02121deh
	drept_plin 326, 518, 24 , 96 , 02121deh 
	
	; T3
	drept_plin 254, 662, 168, 24 , 02121deh
	drept_plin 326, 662, 24 , 96 , 02121deh 
	
	; cuib fantome
	drept_gol  254, 374, 168, 96 , 12 , 02121deh
	drept_plin 314, 374, 48 , 12 , 0000000h
	drept_plin 314, 377, 48 , 6  , 0FFB8DEh
	call afisare_puncte
	random_event
	cmp contor_invincibilitate, 0
	je skip_decrement
	dec contor_invincibilitate
skip_decrement:
	;fantoma 
	
	make_fantome_move_red 0
	ciocniri_red
	
	mov eax, fantomite[0]
	mov fantomite_last[0], eax
	add eax, fantomite_inc[0]
	mov fantomite[0], eax
	mov eax, fantomite[4]
	mov fantomite_last[4], eax
	add eax, fantomite_inc[4]
	mov fantomite[4], eax

	drept_plin fantomite_last[0],fantomite_last[4],pacman_lugime,pacman_inaltime,0
	drept_plin fantomite[0],fantomite[4],pacman_lugime,pacman_inaltime,0ff0000h
	drept_plin fantomite[12],fantomite[16],pacman_lugime,pacman_inaltime,0FFB8DEh
	drept_plin fantomite[24],fantomite[28],pacman_lugime,pacman_inaltime,0FFB847h
	drept_plin fantomite[36],fantomite[40],pacman_lugime,pacman_inaltime,00FFDEh
	; pacman
	
	ciocniri
	mov eax, pacman_x
	add eax, increment_x
	mov pacman_x, eax
	mov eax, pacman_y
	add eax, increment_y
	mov pacman_y, eax
	
	eat_pixeli
	drept_plin pacman_lx, pacman_ly,pacman_lugime,pacman_inaltime,0000000h
	drept_plin pacman_x , pacman_y,pacman_lugime,pacman_inaltime,0FFFF00h
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
