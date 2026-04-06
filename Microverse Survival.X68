;-------------------------------------------------------
; Project: Microverse Survival (REBALANCED)
;-------------------------------------------------------

        ORG $1000

PRINT_STR   EQU 14
PRINT_NUM   EQU 3
READ_NUM    EQU 4
STOP        EQU 9

START:
        BSR INIT
        BSR INTRO_SCREEN       ; Вступительный экран
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
; ВСТУПИТЕЛЬНЫЙ ЭКРАН (КРАСИВОЕ ОФОРМЛЕНИЕ)
;-------------------------------------------------------
INTRO_SCREEN:
        LEA INTRO_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BSR ENDL

        LEA PRESS_KEY_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BSR ENDL

        ; ??? "Press Enter" ????? ???????????? ?????? ?????? ??? ???????
        MOVE.B #5,D0               ; ??????? ???? ?????? (Task 5)
        TRAP #15                   ; ???? ??????? ???????
        RTS


;-------------------------------------------------------
; INITIALISE
;-------------------------------------------------------
INIT:
        MOVE.B #100,HEALTH
        MOVE.B #50,ENERGY
        MOVE.B #20,FOOD
        MOVE.B #1,DAY_COUNT     ; Начинаем с 1-го дня
        RTS

;-------------------------------------------------------
; WELCOME & MODE
;-------------------------------------------------------
WELCOME:
        BSR ENDL             ; Add a newline before the welcome message
        LEA WELCOME_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BSR ENDL             ; Add another newline after the message (optional)
        RTS

SELECT_MODE:
        LEA MODE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15

READ_M:
        CLR.B D1                    ; Clear D1 before reading the input
        MOVE.B #READ_NUM,D0         ; Request input
        TRAP #15                    ; Read input into D1

        ; Check if the input is valid (either 0 or 1)
        CMP.B #0,D1                 ; Compare input with 0
        BEQ VALID_INPUT        
        CMP.B #1,D1                 ; Compare input with 1
        BEQ VALID_INPUT        

        ; If the input is invalid, print an error message
        LEA INVALID_MODE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        
        ; Ask the user for valid input again
        BRA READ_M                  ; Loop until valid input (0 or 1)

VALID_INPUT:
        MOVE.B D1,MODE              ; Store the selected mode (0 or 1)
        RTS
        
INVALID_INPUT:
        LEA INVALID_MODE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BRA READ_M               ; Повторный ввод, если не '0' и не '1'


;-------------------------------------------------------
; INPUT (Выбор интенсивности дня)
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
        MOVE.B D1,POTIONS    ; Сохраняем выбор игрока
        RTS
BAD_IN:
        LEA INVALID_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        BRA READ_P

;-------------------------------------------------------
; RESOURCE UPDATE (Логика выживания)
;-------------------------------------------------------
RESOURCE_UPDATE:
        CLR.L D2
        MOVE.B POTIONS,D2    ; ????? ???? ?????? (1-9)
        
        ; ??????? ?????? ??????????????? ?????
        SUB.B D2,ENERGY
        BCC .EN_OK
        CLR.B ENERGY
        SUB.B #5,HEALTH      ; ????? ?? ?????????????
.EN_OK:

        ; ??? ????????????? (????? ?? ???????), ?? ???????? ?? ??????????
        ADD.B D2,FOOD        ; ????????? ??? ?? ???????
        SUB.B #5,FOOD        ; ????? ???????? ????? (5)
        BCC .FD_OK
        CLR.B FOOD
        LEA STARVE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #10,HEALTH
.FD_OK:

        ; ???????? ?? ?????? (???? ???????? 0 ??? ??????) ??? ?????? Story
        TST.B HEALTH
        BEQ GAME_OVER        ; ???? ?????????????, ???? ???????? = 0

        ; ???? ????? "Endless", ?????????? ????
        CMP.B #0,MODE        ; ?????????, ???? ??? ????? Story (0)
        BEQ .CHECK_DEATH     ; ?????? ???? ??? ????? Story, ????????? ??????
        RTS

.CHECK_DEATH:
        TST.B HEALTH
        BEQ GAME_OVER        ; ???? ?????????????, ???? ???????? = 0
        RTS
        
.HEALTH_OK:
        RTS

.LOW_FOOD:
        CMP.B #10,FOOD      ; Если еды меньше 10
        BGE .FD_OK_LOW      ; Пищи достаточно, пропускаем
        LEA STARVE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        SUB.B #15,HEALTH    ; Штраф за голод
        BCC .FD_OK_LOW

.FD_OK_LOW:
        RTS

;-------------------------------------------------------
; EVENTS (Добавляем дополнительные события)
;-------------------------------------------------------
WORLD_EVENT:
        MOVE.B #8,D0
        TRAP #15
        ANDI.L #%111,D1      ; Шанс на 3 типа событий
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
        SUB.B #15,HEALTH   ; Нападение на базу, потеря здоровья
        RTS

RARE_RESOURCE:
        LEA RARE_RESOURCE_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        ADD.B #10,FOOD    ; Находка редких ресурсов (пища)
        RTS

;-------------------------------------------------------
; STATUS & HUD
;-------------------------------------------------------
CHECK_STATUS:
        ADD.B #1,DAY_COUNT
        TST.B HEALTH
        BEQ GAME_OVER    ; Игра заканчивается, если здоровье = 0

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
;-------------------------------------------------------
; SYSTEM
;-------------------------------------------------------
GAME_OVER:
        ; --- New part of GAME_OVER for debugging ---
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
        
        BSR ENDL  ; Add new line before the prompt
        LEA PLAY_AGAIN_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15

        MOVE.B #5,D0                   ; Task 5: Get input
        TRAP #15                       ; Read key press into D1
        ANDI.B #$DF,D1                 ; Convert lowercase to uppercase
        CMP.B #'Y',D1                  ; Compare with 'Y'
        BEQ RESTART_GAME

        CMP.B #'N',D1                  
        BEQ EXIT_GAME
        
        BRA GAME_OVER                  ; If not Y or N, prompt again
RESTART_GAME:
        BSR INIT
        BSR ENDL             ; Ensure there's a newline before the welcome message
        BSR WELCOME          ; Print welcome message
        BSR SELECT_MODE      ; Prompt for mode selection (0 or 1)
        BRA MAIN_LOOP        ; Start the main loop

EXIT_GAME:
        MOVE.B #STOP,D0
        TRAP #15

STORY_WIN:
        LEA STORY_WIN_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15
        
        BSR ENDL  ; Add new line before the prompt
        LEA PLAY_AGAIN_MSG,A1
        MOVE.B #PRINT_STR,D0
        TRAP #15

        MOVE.B #5,D0                   ; Task 5: Get input
        TRAP #15                       ; Read key press into D1
        ANDI.B #$DF,D1                 ; Convert lowercase to uppercase
        CMP.B #'Y',D1                  ; Compare with 'Y'
        BEQ RESTART_GAME

        CMP.B #'N',D1                  
        BEQ EXIT_GAME
        
        BRA STORY_WIN                  ; If not Y or N, prompt again

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
INTRO_MSG:      DC.B '********************************************',0
                DC.B '***  Welcome to MICROVERSE SURVIVAL!  ***',0
                DC.B '********************************************',0
PRESS_KEY_MSG:  DC.B 'Press any key to start...',0
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
PLAY_AGAIN_MSG: DC.B 'Do you want to play again? (Y/N): ',0

HEALTH:     DS.B 1
ENERGY:     DS.B 1
FOOD:       DS.B 1
DAY_COUNT:  DS.B 1
MODE:       DS.B 1
POTIONS:    DS.B 1


        END START




