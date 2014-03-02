

;===============================================================;

; INT 8 - System timer

	; no input data

	; related memory:

	; 40:6C = Daily timer counter (4 bytes)
	; 40:70 = 24 hr overflow flag (1 byte)
	; 40:67 = Day counter on all products after AT
	; 40:40 = Motor shutoff counter - decremented until 0 then
	;		  shuts off diskette motor


	; - INT 1C is invoked as a user interrupt
	; - the byte at 40:70 is a flag that certain DOS functions use
	;	and adjust the date if necessary.  Since this is a flag and
	;	not a counter it results in DOS (not the RTC) losing days
	;	when several midnights pass before a DOS call
	; - generated 18.2 times per second by the 8253 Programmable Interval
	;	Timer (PIT)
	; - normal INT 8 execution takes approximately 100 microseconds

	; - see	8253



;===============================================================;

; INT 16 - Keyboard BIOS Services

; For more information, see the following topics:


	; INT 16,0   Wait for keystroke and read
	; INT 16,1   Get keystroke status
	; INT 16,2   Get shift status
	; INT 16,3   Set keyboard typematic rate (AT+)
	; INT 16,4   Keyboard click adjustment (AT+)
	; INT 16,5   Keyboard buffer write  (AT,PS/2 enhanced keyboards)
	; INT 16,10  Wait for keystroke and read  (AT,PS/2 enhanced keyboards)
	; INT 16,11  Get keystroke status  (AT,PS/2 enhanced keyboards)
	; INT 16,12  Get shift status  (AT,PS/2 enhanced keyboards)


	; - with IBM BIOS's, INT 16 functions do not restore the flags to
	;	the pre-interrupt state to allow returning of information via
	;	the flags register
	; - functions 3 through 12h are not available on all AT machines
	;	unless the extended keyboard BIOS is present
	; - all registers are preserved except AX and FLAGS
	; - see	SCAN CODES


;===============================================================;
; DOS 2+ - DOS IDLE INTERRUPT

; SS:SP = top of MS-DOS stack for I/O functions

; Return:
; All registers preserved

; Desc: This interrupt is invoked each time one of the DOS character input functions loops while waiting for input. Since a DOS call is in progress even though DOS is actually idle during such input waits, hooking this function is necessary to allow a TSR to perform DOS calls while the foreground program is waiting for user input. The INT 28h handler may invoke any INT 21h function except functions 00h through 0Ch.

; Notes: Under DOS 2.x, the critical error flag (the byte immediately after the InDOS flag) must be set in order to call DOS functions 50h/51h from the INT 28h handler without destroying the DOS stacks.. Calls to INT 21/AH=3Fh,40h from within an INT 28 handler may not use a handle which refers to CON. At the time of the call, the InDOS flag (see INT 21/AH=34h) is normally set to 01h; if larger, DOS is truly busy and should not be reentered. The default handler is an IRET instruction. Supported in OS/2 compatibility box. The _MS-DOS_Programmer's_Reference_ for DOS 5.0 incorrectly documents this interrupt as superseded. The performance of NetWare Lite servers (and probably other peer-to- peer networks) can be dramatically improved by calling INT 28 frequently from an application's idle loop 

;===============================================================;

Input_wait MACRO
	
	AH = 86h
	CX,DX = 3D0h ; number of microseconds to wait (976 as resolution)

	; on return:
	; CF = set if error (PC,PCjr,XT)
	;    = set if wait in progress
	;	 = clear if successful wait
	; AH = 80h for PC and PCjr
	;    = 86h for XT


	; - AT and PS/2 only for system timing
	; - not designed for user application usage
	
	ENDM
	
;===============================================================;

Dos_Idle_Loop MACRO

; INT 28 - DOS Idle Loop / Scheduler (Undocumented)

	; - issued by DOS during keyboard poll loop
	; - indicates DOS may be carefully re-entered by TSR
	; - used by TSR programs to popup and make DOS disk I/O calls
	; - supported by OS/2 compatibility box
	; - default behavior is to simply perform an IRET
	; - any DOS functions above 0Ch may be called while in this handler
	; - INT 21,3F and INT 21,40 may not use a handle that refers to
	;	CON while in this handler
	; - see also  INDOS

	ENDM