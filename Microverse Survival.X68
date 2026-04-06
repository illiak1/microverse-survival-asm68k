;-------------------------------------------------------
; Project: Microverse Survival
;-------------------------------------------------------

        ORG $1000

PRINT_STR   EQU 14
PRINT_NUM   EQU 3
READ_NUM    EQU 4
STOP        EQU 9

START:
        BSR INIT
        BSR WELCOME
        BSR SELECT_MODE
        
MAIN_LOOP:
        BSR HUD
        BSR INPUT
        BSR WORLD_EVENT
        BSR RESOURCE_UPDATE
        BSR CHECK_STATUS
        BRA MAIN_LOOP

;-------------------------------------------------------
; INITIALISE
;-------------------------------------------------------
INIT:
        MOVE.B #100,HEALTH
        MOVE.B #50,ENERGY
        MOVE.B #20,FOOD
        MOVE.B #1,DAY_COUNT    
        RTS

;-------------------------------------------------------
; WELCOME & MODE
;-------------------------------------------------------
WELCOME:
        LEA WELCOME_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BSR ENDL
        RTS

SELECT_MODE:
        LEA MODE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15

READ_M:
        MOVE.B #READ_NUM,D0
        TRAP #15
        CMP.L #0,D1
        BLT INVALID_INPUT 
        CMP.L #1,D1
        BGT INVALID_INPUT   
        MOVE.B D1,MODE     
        RTS

INVALID_INPUT:
        LEA INVALID_MODE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BRA READ_M          

;-------------------------------------------------------
; INPUT 
;-------------------------------------------------------
INPUT:
        BSR ENDL
        LEA POTION_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
READ_P:
        MOVE.B #READ_NUM,D0
        TRAP #15
        CMP.L #1,D1
        BLT BAD_IN
        CMP.L #9,D1
        BGT BAD_IN
        MOVE.B D1,POTIONS    
        RTS
BAD_IN:
        LEA INVALID_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BRA READ_P

;-------------------------------------------------------
; RESOURCE UPDATE 
;-------------------------------------------------------
;-------------------------------------------------------
; RESOURCE UPDATE
;-------------------------------------------------------
RESOURCE_UPDATE:
        CLR.L D2
        MOVE.B POTIONS,D2    
        
     
        SUB.B D2,ENERGY
        BCC .EN_OK
        CLR.B ENERGY
        SUB.B #5,HEALTH      
.EN_OK:

        
        ADD.B D2,FOOD        
        SUB.B #5,FOOD        
        BCC .FD_OK
        CLR.B FOOD
       
        LEA STARVE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #10,HEALTH
.FD_OK:

       
        TST.B HEALTH
        BEQ GAME_OVER   

        RTS
.HEALTH_OK:
        RTS

.LOW_FOOD:
        CMP.B #10,FOOD      
        BGE .FD_OK_LOW      
        
        LEA STARVE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #15,HEALTH    
        BCC .FD_OK_LOW

.FD_OK_LOW:
        RTS
;-------------------------------------------------------
; EVENTS 
;-------------------------------------------------------
WORLD_EVENT:
        MOVE.B #8,D0
        TRAP #15
        ANDI.L #%111,D1     
        CMP.L #0,D1
        BEQ DROUGHT
        CMP.L #1,D1
        BEQ BASE_ATTACK
        CMP.L #2,D1
        BEQ RARE_RESOURCE
        RTS

DROUGHT:
        LEA DROUGHT_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #10,FOOD
        BPL .SKIP
        CLR.B FOOD
.SKIP:
        RTS

BASE_ATTACK:
        LEA BASE_ATTACK_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #15,HEALTH  
        RTS

RARE_RESOURCE:
        LEA RARE_RESOURCE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        ADD.B #10,FOOD    
        RTS

;-------------------------------------------------------
; STATUS & HUD
;-------------------------------------------------------
;-------------------------------------------------------
; STATUS & HUD
;-------------------------------------------------------
CHECK_STATUS:
        ADD.B #1,DAY_COUNT
        TST.B HEALTH
        BEQ GAME_OVER    

        CMP.B #0,MODE
        BNE .RET
        CMP.B #15,DAY_COUNT
        BGE STORY_WIN
.RET:
        RTS

HUD:
        MOVEM.L D0-D1/A1,-(A7)
        BSR ENDL
        LEA DAY_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        CLR.L D1
        MOVE.B DAY_COUNT,D1
        MOVE.B #PRINT_NUM,D0
        TRAP #15

        BSR ENDL
        LEA HEALTH_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        CLR.L D1
        MOVE.B HEALTH,D1
        MOVE.B #PRINT_NUM,D0
        TRAP #15

        LEA FOOD_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        CLR.L D1
        MOVE.B FOOD,D1
        MOVE.B #PRINT_NUM,D0
        TRAP #15
        
        LEA ENERGY_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        CLR.L D1
        MOVE.B ENERGY,D1
        MOVE.B #PRINT_NUM,D0
        TRAP #15
        BSR ENDL
        MOVEM.L (A7)+,D0-D1/A1
        RTS

;-------------------------------------------------------
; SYSTEM
;-------------------------------------------------------
GAME_OVER:
        LEA GAME_OVER_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        
        
        LEA DAYS_SURVIVED_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        CLR.L D1
        MOVE.B DAY_COUNT,D1
        MOVE.B #PRINT_NUM,D0
        TRAP #15
        
        MOVE.B #STOP,D0
        TRAP #15

STORY_WIN:
        LEA STORY_WIN_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        MOVE.B #STOP,D0
        TRAP #15

ENDL:
        MOVEM.L D0/A1,-(A7)
        LEA CRLF,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        MOVEM.L (A7)+,D0/A1
        RTS

;-------------------------------------------------------
; DATA
;-------------------------------------------------------
CRLF:           DC.B $0D,$0A,0
WELCOME_MSG:    DC.B '=== MICROVERSE SURVIVAL ===',0
MODE_MSG:       DC.B '0:Story (15 days), 1:Endless. Choice: ',0
POTION_MSG:     DC.B 'Choose activity level (1=Rest, 9=Hunt): ',0
INVALID_MSG:    DC.B 'Bad input! (1-9 only)',0
INVALID_MODE_MSG: DC.B 'Invalid mode! Please enter 0 for Story or 1 for Endless: ',0
DROUGHT_MSG:    DC.B '>>> EVENT: DROUGHT! Food lost.',0
STARVE_MSG:     DC.B '>>> ALERT: STARVING! HP drops.',0
BASE_ATTACK_MSG: DC.B '>>> ALERT: Your base is under attack!',0
RARE_RESOURCE_MSG: DC.B '>>> YOU FOUND RARE RESOURCES! +10 FOOD',0
HEALTH_MSG:     DC.B ' HEALTH: ',0
FOOD_MSG:       DC.B ' | FOOD: ',0
ENERGY_MSG:     DC.B ' | ENERGY: ',0
DAY_MSG:        DC.B '--- DAY ',0
GAME_OVER_MSG:  DC.B $0D,$0A,'*** YOU PERISHED. GAME OVER :(  ***',0
STORY_WIN_MSG:  DC.B $0D,$0A,'*** VICTORY! YOU SURVIVED! ***',0
DAYS_SURVIVED_MSG: DC.B 'Days survived: ',0

        
HEALTH:      DS.B 1
ENERGY:      DS.B 1
FOOD:        DS.B 1
DAY_COUNT:   DS.B 1
MODE:        DS.B 1
POTIONS:     DS.B 1

        END START



