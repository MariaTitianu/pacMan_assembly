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
area_width EQU 640
area_height EQU 480
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

buton_x equ 50
buton_y equ 10
buton_size equ 40

error_iesire_matrice db "Ati incercat sa desenati un pixel pe afara: x = %d, y = %d, culoare = %x",13,10,0
error_suprapunere_culoare_diferita db "Well...s-a pus o alta culoare: x = %d, y = %d, culoare = %x",13,10,0

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

_make_pixel proc
	push ebp
	mov ebp, esp
	;corp 
	mov eax, [ebp+12]
	mov ecx, [esp+8]
	cmp ecx,area_width
	jge it_s_not_ok_now
	cmp ecx,0
	jl it_s_not_ok_now
	cmp eax,area_height
	jge it_s_not_ok_now
	cmp eax,0
	jl it_s_not_ok_now
	mov eax, [ebp+12]	;eax = y
	mov ebx,area_width
	mul ebx  ;eax = y* area_width
	add eax,[ebp+8]	;eax= y* area_width+x
	shl eax, 2;eax= (y* area_width+x)*4
	add eax, area	
	mov edi, [ebp+16]
	cmp dword ptr[eax], 000000h
	je culoare_neagra
	pusha
	push [ebp + 16]
	push [ebp + 12]
	push [ebp + 8]
	push offset error_suprapunere_culoare_diferita
	call printf
	add esp,16
	popa
culoare_neagra:
	mov dword ptr[eax], edi
	jmp finish_make_pixel
it_s_not_ok_now:
	pusha
	push [ebp + 16]
	push [ebp + 12]
	push [ebp + 8]
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
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:		
	mov dword ptr [edi], 0FFFFFFh
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
	mov ecx, [ebp + 16]
	mov eax, [ebp + 8]
bucla_linie:
	make_pixel eax, [ebp+12], [ebp+20]
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
	mov ecx, [ebp + 16]
	mov eax, [ebp+12]
bucla_linie:
	make_pixel [ebp + 8], eax, [ebp+20]
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


_Drept_gol  proc
	push EBP
	mov EBP, ESP 
	;corp procedura
looping: 
	
	loop looping
	;end procedura
	mov ESP, EBP
	pop EBP
	ret
_Drept_gol endp

drept_gol macro x, y,lungime,latime,gros,culoare
	pusha
	push culoare
	push gros
	push latime
	push lungime
	push y
	push x
	call _Drept_gol 
	add esp, 24
	popa
endm

_Drept_plin  proc
	push EBP
	mov EBP, ESP 
	mov ecx, [ebp+20]
	mov eax, [ebp+ 8]
	;corp procedura
looping:
	linie_verticala eax, [ebp+12], [ebp+16],[ebp+24]
	inc eax
	loop looping 
	;end procedura
	mov ESP, EBP
	pop EBP
	ret
_Drept_plin endp

drept_plin macro x, y,lungime,latime,culoare
	pusha
	push culoare
	push latime
	push lungime
	push y
	push x
	call _Drept_plin
	add esp, 20
	popa
endm
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 000
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:

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
	; apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	; terminarea programului
	push 0
	call exit
end start
