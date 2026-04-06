;-------------------------------------------------------
; Project: Microverse Survival in Assembly 68k
;-------------------------------------------------------
;-------------------------------------------------------
; Author: Illia Karban
; Date: 06.03.2026
; Description: Survival game with Story and Endless modes
;-------------------------------------------------------

        ORG $1000                 ; Program starting memory address

; ===== EASy68K Trap Task Codes =====
PRINT_STR   EQU 14                ; Task 14: Print string to console
PRINT_NUM   EQU 3                 ; Task 3: Print number in D1
READ_NUM    EQU 4                 ; Task 4: Read numeric input into D1
STOP        EQU 9                 ; Task 9: Terminate program


START:
        CLR.B HIGH_SCORE      ; Initialize high score 
        BSR INIT                  ; Initialize all game variables
        BSR INTRO_SCREEN          ; Display introduction screen
        BSR WELCOME               ; Show welcome message
        BSR SELECT_MODE           ; Let player choose Story or Endless mode
        
MAIN_LOOP:
        BSR HUD                   ; Display current player status (Day, HP, Food, Energy)
        BSR INPUT                 ; Get player action for the day
        BSR WORLD_EVENT           ; Generate random world event
        BSR RESOURCE_UPDATE       ; Update resources based on actions and events
        BSR CHECK_STATUS          ; Check win/lose conditions
        BRA MAIN_LOOP             ; Repeat main game loop


;-------------------------------------------------------
; INTRODUCTION SCREEN 
;-------------------------------------------------------
INTRO_SCREEN:
        LEA INTRO_MSG,A1          ; Load address of intro message
        MOVE.B #PRINT_STR,D0      ; Prepare print string task
        TRAP #15                  ; Execute trap (print string)
        BSR ENDL                  ; Print  line

        LEA PRESS_KEY_MSG,A1      ; Load "Press any key" message
        MOVE.B #PRINT_STR,D0      ; Prepare print string task
        TRAP #15                  ; Execute trap (print string)
        BSR ENDL                  ; Print newline

        ; Wait for user to press any key before starting the game
        MOVE.B #5,D0              ; Task 5: Read single key press
        TRAP #15                  ; Execute trap (result stored in D1)
        RTS                       ; Return to caller

;-------------------------------------------------------
; INITIALISE GAME VARIABLES
;-------------------------------------------------------
INIT:
        MOVE.B #100,HEALTH      ; Set starting health to 100
        MOVE.B #50,ENERGY       ; Set starting energy to 50
        MOVE.B #20,FOOD         ; Set starting food supply to 20
        MOVE.B #1,DAY_COUNT     ; Start counting from Day 1
        RTS                     ; Return from subroutine


;-------------------------------------------------------
; WELCOME MESSAGE
;-------------------------------------------------------
WELCOME:
        BSR ENDL                ; Print a blank line before the welcome message
        LEA WELCOME_MSG,A1      ; Load address of welcome message
        MOVE.B #PRINT_STR,D0    ; Prepare print string task
        TRAP #15                ; Execute trap (display message)
        BSR ENDL                ; Print another blank line after the message
        RTS                     ; Return from subroutine

;-------------------------------------------------------
;GAME MODE SELECTION
;-------------------------------------------------------
SELECT_MODE:
        LEA MODE_MSG,A1          ; Load the address of the mode selection message into A1
        MOVE.B #PRINT_STR,D0     ; Load the EASy68K "print string" task code into D0
        TRAP #15                 ; Execute the system call to print the string

READ_M:
        MOVE.B #5,D0             ; Load task code 5: read a single key press (ASCII) into D0
        TRAP #15                 ; Execute the system call; the pressed key is returned in D1

        CMP.B #$0D,D1            ; Compare D1 with ASCII code for Enter (Carriage Return)
        BEQ READ_M                ; If Enter is pressed, ignore it and read again

        CMP.B #'0',D1             ; Compare D1 with ASCII '0'
        BEQ VALID_INPUT           ; If it's '0', branch to VALID_INPUT
        CMP.B #'1',D1             ; Compare D1 with ASCII '1'
        BEQ VALID_INPUT           ; If it's '1', branch to VALID_INPUT

        ; ----- INVALID INPUT -----
        BSR ENDL                  ; Call ENDL subroutine to print a newline
        LEA INVALID_MODE_MSG,A1   ; Load the address of the invalid input message into A1
        MOVE.B #PRINT_STR,D0      ; Load the print string task code into D0
        TRAP #15                  ; Execute system call to display the invalid input message

        BRA READ_M                ; Repeat input reading until valid

VALID_INPUT:
        SUB.B #'0',D1             ; Convert ASCII '0' or '1' to numeric 0 or 1
        MOVE.B D1,MODE            ; Store the numeric value into the MODE variable
        RTS                        ; Return from subroutine

;-------------------------------------------------------
; INPUT (Choose Action)
; 1 = Rest
; 2 = Explore
; 3 = Hunt
;-------------------------------------------------------
INPUT:
        BSR ENDL                  ; Print new line
        LEA ACTION_MSG,A1         ; Load action prompt message
        MOVE.B #PRINT_STR,D0      ; Prepare print string task
        TRAP #15                  ; Display message

READ_ACT:
        MOVE.B #READ_NUM,D0       ; Read numeric input
        TRAP #15                  ; Result returned in D1

        CMP.B #1,D1               ; Check if input < 1
        BLT BAD_ACT               ; If invalid, show error
        CMP.B #3,D1               ; Check if input > 3
        BGT BAD_ACT               ; If invalid, show error

        MOVE.B D1,ACTION          ; Store valid action
        RTS                       ; Return to main loop

BAD_ACT:
        LEA INVALID_ACT_MSG,A1    ; Load invalid input message
        MOVE.B #PRINT_STR,D0      ; Prepare print task
        TRAP #15                  ; Display error message
        BRA READ_ACT              ; Ask for input again

;-------------------------------------------------------
; RESOURCE UPDATE (3 Action System)
; Updates player resources based on chosen action
;-------------------------------------------------------
RESOURCE_UPDATE:

        MOVE.B ACTION,D0          ; Load selected action into D0

        CMP.B #1,D0               ; Check if action = 1 (Rest)
        BEQ DO_REST               ; Branch to rest routine

        CMP.B #2,D0               ; Check if action = 2 (Explore)
        BEQ DO_EXPLORE            ; Branch to explore routine

        CMP.B #3,D0               ; Check if action = 3 (Hunt)
        BEQ DO_HUNT               ; Branch to hunt routine

        RTS                       ; Return if no valid action


; ---------- REST ----------
DO_REST:
        LEA REST_MSG,A1           ; Load rest message
        MOVE.B #PRINT_STR,D0      ; Prepare print task
        TRAP #15                  ; Display message
        BSR ENDL                  ; Print new line

        ADD.B #5,ENERGY           ; Gain energy from resting
        SUB.B #7,FOOD             ; Consume food while resting
        BRA CHECK_LIMITS          ; Check resource limits


; ---------- EXPLORE ----------
DO_EXPLORE:
        LEA EXPLORE_MSG,A1        ; Load explore message
        MOVE.B #PRINT_STR,D0      ; Prepare print task
        TRAP #15                  ; Display message
        BSR ENDL                  ; Print new line

        SUB.B #7,ENERGY           ; Exploring consumes energy
        ADD.B #3,FOOD             ; Chance to find food
        BRA CHECK_LIMITS          ; Check resource limits


; ---------- HUNT ----------
DO_HUNT:
        LEA HUNT_MSG,A1           ; Load hunt message
        MOVE.B #PRINT_STR,D0      ; Prepare print task
        TRAP #15                  ; Display message
        BSR ENDL                  ; Print new line

        SUB.B #9,ENERGY           ; Hunting costs energy
        ADD.B #8,FOOD             ; Gain food from hunting
        BRA CHECK_LIMITS          ; Check resource limits        

; ---------- COMMON CHECKS ----------
; Ensures resource values stay within limits and applies penalties

CHECK_LIMITS:
    ; --- Clamp Energy to 0–100 ---
        TST.B ENERGY             ; Check if ENERGY is negative
        BPL .EN_OK               ; If >= 0, continue
        CLR.B ENERGY             ; Set ENERGY to 0 if negative
.EN_OK:
        CMP.B #100,ENERGY        ; Check if ENERGY exceeds max
        BLE .EN_CAP_OK           ; If <=100, continue
        MOVE.B #100,ENERGY       ; Limit ENERGY to 100
.EN_CAP_OK:

    ; --- Clamp Food to 0–100 ---
        TST.B FOOD               ; Check if FOOD is negative
        BPL .FOOD_OK             ; If >= 0, continue
        CLR.B FOOD               ; Set FOOD to 0 if negative
.FOOD_OK:
        CMP.B #100,FOOD          ; Check if FOOD exceeds max
        BLE .FOOD_CAP_OK         ; If <=100, continue
        MOVE.B #100,FOOD         ; Limit FOOD to 100
.FOOD_CAP_OK:
    ; --- Clamp Health to maximum 100 ---
        CMP.B #100,HEALTH        ; Check if HEALTH exceeds max
        BLE .HEALTH_OK           ; If <=100, continue
        MOVE.B #100,HEALTH       ; Limit HEALTH to 100
.HEALTH_OK:
    ; --- Starvation penalty (Food = 0) ---
        TST.B FOOD               ; Check if FOOD is zero
        BNE .CHECK_ENERGY        ; Skip if player has food
        LEA STARVE_MSG,A1        ; Load starvation message
        MOVE.B #PRINT_STR,D0     ; Prepare print task
        TRAP #15                 ; Display message
        BSR ENDL                 ; Print blank line
        SUB.B #15,HEALTH         ; Reduce HEALTH due to starvation
        BCC .CHECK_ENERGY        ; Continue if no underflow
        CLR.B HEALTH             ; Clamp HEALTH to 0 if negative

.CHECK_ENERGY:
    ; --- Exhaustion penalty (Energy = 0) ---
        TST.B ENERGY             ; Check if ENERGY is zero
        BNE CHECK_HEALTH         ; Skip if player has energy
        LEA EXHAUST_MSG,A1       ; Load exhaustion message
        MOVE.B #PRINT_STR,D0     ; Prepare print task
        TRAP #15                 ; Display message
        BSR ENDL                 ; Print blank line
        SUB.B #15,HEALTH         ; Reduce HEALTH due to exhaustion
        BCC CHECK_HEALTH         ; Continue if no underflow
        CLR.B HEALTH             ; Clamp HEALTH to 0 if negative

CHECK_HEALTH:
        TST.B HEALTH             ; Check if player is alive
        BEQ GAME_OVER            ; End game if HEALTH = 0

DONE_UPDATE:
        RTS                      ; Return to main program

;-------------------------------------------------------
; EVENTS (Random Dynamic World Events)
; Generates random events that affect player resources
;-------------------------------------------------------

; ----- Event probabilities -----
; D1 = 0  -> DROUGHT (-10 FOOD)
; D1 = 1  -> BASE_ATTACK (-15 HEALTH)
; D1 = 2  -> RARE_RESOURCE (+5 FOOD)
; D1 = 3–5 -> No event
; D1 = 6  -> RARE_HEAL (+10 HEALTH)
; D1 = 7  -> SCREEN_GLITCH

WORLD_EVENT:
        MOVE.B #8,D0              ; Task 8: generate random number
        TRAP #15                  ; Result returned in D1

        ANDI.L #%111,D1           ; Limit random value to range 0–7

        CMP.L #0,D1               ; Check for drought event
        BEQ DROUGHT               ; Player loses food

        CMP.L #1,D1               ; Check for base attack
        BEQ BASE_ATTACK           ; Player takes damage

        CMP.L #2,D1               ; Check for rare resource
        BEQ RARE_RESOURCE         ; Player gains food
        
        CMP.L #6,D1               ; Check for rare heal event
        BEQ RARE_HEAL             ; Restore player health
        
        CMP.L #7,D1               ; Check for screen glitch event
        BEQ SCREEN_GLITCH         ; Display glitch message

        RTS                       ; If 3–5, no event occurs


; ----- Rare Event: Heal Player -----
RARE_HEAL:
        TST.B HEALTH              ; Check current health
        CMP.B #100,HEALTH         ; Is health already full?
        BEQ FULL_HEALTH           ; If full, show special message

        LEA RARE_HEAL_MSG,A1      ; Load healing message
        MOVE.B #PRINT_STR,D0
        TRAP #15

        ADD.B #10,HEALTH          ; Increase health
        CMP.B #100,HEALTH         ; Ensure health does not exceed max
        BLE .HEALTH_CAP
        MOVE.B #100,HEALTH
.HEALTH_CAP:
        RTS                       ; Return to game loop


; ----- Message if Health Already Full -----
FULL_HEALTH:
        LEA FULL_HEALTH_MSG,A1    ; Display message for full health
        MOVE.B #PRINT_STR,D0
        TRAP #15
       
        BSR ENDL                  ; Print blank line
        RTS


; ----- Rare Event: Screen Glitch -----
SCREEN_GLITCH:
        LEA GLITCH_MSG,A1         ; Load glitch message
        MOVE.B #PRINT_STR,D0
        TRAP #15

        BSR ENDL                  ; Print blank line
        RTS
                
; ----- EVENT: DROUGHT -----
DROUGHT:
        LEA DROUGHT_MSG,A1         ; Load drought message
        MOVE.B #PRINT_STR,D0       ; Prepare print task
        TRAP #15                   ; Display drought message
        SUB.B #10,FOOD             ; Lose 10 FOOD units
        BCC .DROUGHT_OK            ; If no underflow, skip next
        CLR.B FOOD                 ; Prevent negative FOOD
.DROUGHT_OK:
        BSR ENDL                   ; Print blank line
        RTS                        ; Return from event


; ----- EVENT: BASE ATTACK -----
BASE_ATTACK:
        LEA BASE_ATTACK_MSG,A1     ; Load base attack message
        MOVE.B #PRINT_STR,D0       ; Prepare print task
        TRAP #15                   ; Display message
        SUB.B #15,HEALTH           ; Reduce 15 HEALTH
        BCC .BASE_OK               ; If no underflow, skip next
        CLR.B HEALTH               ; Prevent negative HEALTH
.BASE_OK:
        BSR ENDL                   ; Print blank line
        RTS                        ; Return from event

; ----- EVENT: RARE RESOURCE FOUND -----
RARE_RESOURCE:
        LEA RARE_RESOURCE_MSG,A1   ; Load rare resource message
        MOVE.B #PRINT_STR,D0       ; Prepare print task
        TRAP #15                   ; Display message
        ADD.B #5,FOOD             ; Gain 5 FOOD units
        
        BSR ENDL                   ; Print blank line
        RTS                        ; Return from event

;-------------------------------------------------------
; STATUS CHECK & WIN/LOSS CONDITIONS
;-------------------------------------------------------

CHECK_STATUS:
        ADD.B #1,DAY_COUNT        ; Increment day counter by 1

        TST.B HEALTH              ; Test HEALTH value
        BEQ GAME_OVER             ; If HEALTH equals 0, branch to GAME_OVER

        CMP.B #0,MODE             ; Compare MODE with 0 (Story mode)
        BNE .RET                  ; If not Story mode (i.e., Endless), skip win check

        CMP.B #15,DAY_COUNT       ; Compare DAY_COUNT with 15
        BGE STORY_WIN             ; If 15 days survived, branch to STORY_WIN

.RET:
        RTS                       ; Return to main loop

;-------------------------------------------------------
; HUD (Heads-Up Display)
; Displays current game statistics
;-------------------------------------------------------
HUD:
                        ;-(A7) : Decrement A7, push data to stack
        MOVEM.L D0-D1/A1,-(A7)    ; Save registers D0, D1, and A1 onto the stack
                                  ; This preserves their values before modification
        BSR ENDL                  ; Call ENDL subroutine to print a blank line


        ; ----- DISPLAY CURRENT DAY -----
        LEA DAY_MSG,A1            ; Load address of the "DAY" label string into A1
        MOVE.B #PRINT_STR,D0      ; Load print-string task number into D0
        TRAP #15                  ; Execute system call to display the string

        CLR.L D1                  ; Clear register D1 before loading numeric value
        MOVE.B DAY_COUNT,D1       ; Move current day value into D1
        MOVE.B #PRINT_NUM,D0      ; Load print-number task number into D0
        TRAP #15                  ; Execute system call to print day number

        BSR ENDL                  ; Print a blank line after displaying the day


        ; ----- DISPLAY HEALTH -----
        LEA HEALTH_MSG,A1         ; Load address of the "HEALTH" label string
        MOVE.B #PRINT_STR,D0      ; Prepare print-string task
        TRAP #15                  ; Display the health label

        CLR.L D1                  ; Clear D1 before loading health value
        MOVE.B HEALTH,D1          ; Move current health value into D1
        MOVE.B #PRINT_NUM,D0      ; Prepare print-number task
        TRAP #15                  ; Display numeric health value


        ; ----- DISPLAY FOOD -----
        LEA FOOD_MSG,A1           ; Load address of the "FOOD" label string
        MOVE.B #PRINT_STR,D0      ; Prepare print-string task
        TRAP #15                  ; Display the food label

        CLR.L D1                  ; Clear D1 before loading food value
        MOVE.B FOOD,D1            ; Move current food value into D1
        MOVE.B #PRINT_NUM,D0      ; Prepare print-number task
        TRAP #15                  ; Display numeric food value
        

        ; ----- DISPLAY ENERGY -----
        LEA ENERGY_MSG,A1         ; Load address of the "ENERGY" label string
        MOVE.B #PRINT_STR,D0      ; Prepare print-string task
        TRAP #15                  ; Display the energy label

        CLR.L D1                  ; Clear D1 before loading energy value
        MOVE.B ENERGY,D1          ; Move current energy value into D1
        MOVE.B #PRINT_NUM,D0      ; Prepare print-number task
        TRAP #15                  ; Display numeric energy value

        BSR ENDL                  ; Print a final blank line for formatting

                ; (A7)+ : read data from the stack, increment A7
        MOVEM.L (A7)+,D0-D1/A1    ; Restore previously saved registers from the stack
                                  ; Ensures no side effects on calling code

        RTS                       ; Return from HUD subroutine

;-------------------------------------------------------
; SYSTEM (Game Over, Restart, Exit, and Utility Routines)
;-------------------------------------------------------

GAME_OVER:
        BSR HUD                     ; Display final HUD with player stats

        LEA GAME_OVER_MSG,A1        ; Load address of "Game Over" message
        MOVE.B #PRINT_STR,D0        ; Set task to print string
        TRAP #15                    ; Execute system call to display message

        LEA DAYS_SURVIVED_MSG,A1    ; Load "Days Survived" label
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display label text

        CLR.L D1                    ; Clear D1 before loading value
        MOVE.B DAY_COUNT,D1         ; Move number of survived days into D1
        MOVE.B #PRINT_NUM,D0        ; Set task to print number
        TRAP #15                    ; Display the number of days survived
        
        BSR ENDL                    ; Print blank line for formatting
        
        CMP.B #1,MODE               ; Check if game mode is Endless
        BNE .SKIP_HS                ; Skip high score if not Endless mode
        CLR.L D0                    ; Clear register D0

        MOVE.B DAY_COUNT,D0         ; Move survived days into D0
        CMP.B HIGH_SCORE,D0         ; Compare with stored high score
        BLS .NORMAL_HS              ; If lower or equal, show normal score

        MOVE.B D0,HIGH_SCORE        ; Update HIGH_SCORE with new record
        
; ----- New Record -----
        LEA NEW_RECORD_MSG,A1       ; Load "New Record" message
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display message

        LEA NEW_HS_LABEL,A1         ; Load high score label
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display label
        BRA .PRINT_NUM              ; Jump to print high score value


; ----- Normal High Score -----
.NORMAL_HS:
        LEA HS_LABEL,A1             ; Load high score label
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display label

; ----- Print High Score Value -----
.PRINT_NUM:
        CLR.L D1                    ; Clear D1 before loading value
        MOVE.B HIGH_SCORE,D1        ; Move high score into D1
        MOVE.B #PRINT_NUM,D0        ; Set task to print number
        TRAP #15                    ; Display high score value
  
        BSR ENDL                    ; Print blank line

.SKIP_HS:

        LEA PLAY_AGAIN_MSG,A1       ; Load "Play again?" message
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display message

        MOVE.B #5,D0                ; Task 5: read single key press
        TRAP #15                    ; Execute system call (result in D1)

        ANDI.B #$DF,D1              ; Convert lowercase input to uppercase

        CMP.B #'Y',D1               ; Check if player pressed 'Y'
        BEQ RESTART_GAME            ; Restart the game

        CMP.B #'N',D1               ; Check if player pressed 'N'
        BEQ EXIT_GAME               ; Exit the game
        
        ; --- Invalid Input ---
        BSR ENDL                    ; Print newline
        LEA INVALID_INPUT_MSG,A1    ; Load invalid input message
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display error message
        BSR ENDL                    ; Print blank line for spacing
  
        BRA .SKIP_HS                ; Ask player again

        

RESTART_GAME:
        BSR INIT                    ; Reset all game variables to starting values
        BSR ENDL                    ; Print blank line for spacing
        BSR WELCOME                 ; Display the welcome message again
        BSR SELECT_MODE             ; Ask player to choose game mode
        BRA MAIN_LOOP               ; Jump back to the main game loop


EXIT_GAME:
        MOVE.B #STOP,D0             ; Load STOP task code
        TRAP #15                    ; Terminate the program


STORY_WIN:
        LEA STORY_WIN_MSG,A1        ; Load "Story Mode Win" message
        MOVE.B #PRINT_STR,D0        ; Set task to print string
        TRAP #15                    ; Display win message

        BSR ENDL                    ; Print blank line

.WIN_INPUT:

        LEA PLAY_AGAIN_MSG,A1       ; Load "Play Again?" prompt
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display prompt

        MOVE.B #5,D0                ; Task 5: read single key press
        TRAP #15                    ; Execute system call (result in D1)

        ANDI.B #$DF,D1              ; Convert lowercase input to uppercase

        CMP.B #'Y',D1               ; Check if player entered 'Y'
        BEQ RESTART_GAME            ; Restart the game if yes

        CMP.B #'N',D1               ; Check if player entered 'N'
        BEQ EXIT_GAME               ; Exit the program if no

        ; --- Invalid Input ---
        BSR ENDL                    ; Print newline
        LEA INVALID_INPUT_MSG,A1    ; Load invalid input message
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Display error message
        BSR ENDL                    ; Print blank line

        BRA .WIN_INPUT              ; Repeat input until valid

;-------------------------------------------------------
; ENDL (Print New Line Utility Subroutine)
;-------------------------------------------------------
ENDL:
        ;STORE DATA
        ; Save registers D0 and A1 onto the stack
        ; Prevents modification of caller registers 
        MOVE.L D0,-(A7)             			   
        MOVE.L A1,-(A7)                            

        LEA CRLF,A1                 ; Load address of carriage return + line feed
        MOVE.B #PRINT_STR,D0        ; Prepare print-string task
        TRAP #15                    ; Print newline characters

        ;RESTORE DATA
        MOVE.L (A7)+,A1
        MOVE.L (A7)+,D0
        RTS                         ; Return from subroutine

;-------------------------------------------------------
; DATA (Strings and Game Variables)
;-------------------------------------------------------

CRLF:           DC.B $0D,$0A,0      ; newline terminator

; ----- Intro & Welcome Messages -----
INTRO_MSG:      DC.B '********************************************', $0D,$0A
                DC.B '***  Welcome to MICROVERSE SURVIVAL!  ***', $0D,$0A
                DC.B '********************************************', $0D,$0A
                DC.B 0

PRESS_KEY_MSG:  DC.B 'Press any key to start...',0       ; Prompt before game starts

WELCOME_MSG:    DC.B '=== MICROVERSE SURVIVAL ===',0     ; Game title display

MODE_MSG:       DC.B '0:Story (15 days), 1:Endless. Choice: ',0 ; Mode selection prompt


; ----- Action Messages -----
ACTION_MSG:        DC.B 'Choose action: 1=Rest 2=Explore 3=Hunt: ',0
INVALID_ACT_MSG:   DC.B 'Invalid choice! Enter 1, 2, or 3: ',0
INVALID_MODE_MSG:  DC.B 'Invalid mode! Please enter 0 for Story or 1 for Endless: ',0
INVALID_INPUT_MSG: DC.B 'Wrong input! Only Y/y or N/n are accepted.',0


REST_MSG:       DC.B $0D,$0A,'YOU RECHARGED YOUR BATTERIES (+5 ENERGY, -7 FOOD)',$0D,$0A,0
EXPLORE_MSG:    DC.B $0D,$0A,'YOU SCOUTED THE AREA (+3 FOOD, -7 ENERGY)',$0D,$0A,0
HUNT_MSG:       DC.B $0D,$0A,'YOU RETURNED WITH FOOD (+8 FOOD, -9 ENERGY)',$0D,$0A,0


; ----- Event Messages -----
DROUGHT_MSG:    DC.B $0D,$0A,'========================================', $0D,$0A
                DC.B '   *** DROUGHT STRIKES! ***', $0D,$0A
                DC.B '   THE SUN IS ANGRY TODAY...', $0D,$0A
                DC.B '   (-10 FOOD)', $0D,$0A
                DC.B '========================================', $0D,$0A,0

STARVE_MSG:     DC.B $0D,$0A,'========================================', $0D,$0A
                DC.B '        !!! STARVING !!!', $0D,$0A
                DC.B '   YOUR STOMACH FILED A COMPLAINT...', $0D,$0A
                DC.B '        (-15 HP)', $0D,$0A
                DC.B '========================================', $0D,$0A,0

EXHAUST_MSG:    DC.B $0D,$0A,'========================================', $0D,$0A
                DC.B 'YOUR LEGS HAVE RESIGNED! Energy is 0, health is decreasing.', $0D,$0A
                DC.B '========================================', $0D,$0A,0

BASE_ATTACK_MSG:
	        DC.B $0D,$0A,'########################################', $0D,$0A
                DC.B '      !!! BASE UNDER ATTACK !!!', $0D,$0A
                DC.B '   SOMETHING BIG WANTS TO COME IN!', $0D,$0A
                DC.B '            (-15 HP)', $0D,$0A
                DC.B '########################################', $0D,$0A,0

RARE_RESOURCE_MSG:
                DC.B $0D,$0A,'******** FORTUNE SMILES UPON YOU! ********', $0D,$0A
                DC.B '   You discovered hidden supplies!', $0D,$0A
                DC.B '            (+5 FOOD)', $0D,$0A
                DC.B '*******************************************', $0D,$0A,0

RARE_HEAL_MSG:
                DC.B $0D,$0A,'***************************************************', $0D,$0A
                DC.B 'YOU DRANK MYSTERY JUICE! LIFE RETURNS TO YOUR BODY!', $0D,$0A
                DC.B '     +10 HEALTH', $0D,$0A
                DC.B '***************************************************', $0D,$0A,0

FULL_HEALTH_MSG:
                DC.B $0D,$0A,'**************************************************', $0D,$0A
                DC.B 'You found a healing potion... but your body says:', $0D,$0A
                DC.B 'NAH, I AM GOOD! ;(', $0D,$0A
                DC.B '**************************************************', $0D,$0A,0

GLITCH_MSG:    
                DC.B $0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A
                DC.B $0D,$0A,$0D,$0A,$0D
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '!!! ERROR 404: LOGIC NOT FOUND !!!', $0D,$0A
                DC.B 'Searching for common sense...', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '########################################', $0D,$0A
                DC.B '010101010101010101010101010101010101', $0D,$0A
                DC.B 'DIVIDING BY ZERO...', $0D,$0A
                DC.B 'THIS WAS A TERRIBLE IDEA.', $0D,$0A
                DC.B '........................................', $0D,$0A
                DC.B 'REBOOTING UNIVERSE...', $0D,$0A
                DC.B '########################################', $0D,$0A,0


; ----- End / Win / High Score Messages -----
GAME_OVER_MSG:
                DC.B $0D,$0A,'================================================', $0D,$0A
                DC.B '           YOU HAVE PERISHED', $0D,$0A
                DC.B '     THE MICROVERSE CLAIMS ANOTHER.', $0D,$0A
                DC.B '     YOUR STORY ENDS HERE', $0D,$0A
                DC.B '================================================', $0D,$0A,0
                
STORY_WIN_MSG:
                DC.B $0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0A,$0D,$0A,$0D,$0A
                DC.B $0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0A,$0D,$0A,$0D,$0A
                DC.B $0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0D,$0A,$0A,$0D,$0A,$0D,$0A
                DC.B '**************************************************',$0D,$0A
        	        DC.B '*                                                *',$0D,$0A
        	        DC.B '*          CONGRATULATIONS, SURVIVOR!            *',$0D,$0A
        	        DC.B '*                                                *',$0D,$0A
        	        DC.B '*           YOU SURVIVED 15 DAYS IN              *',$0D,$0A
                DC.B '*              THE MICROVERSE!                   *',$0D,$0A
                DC.B '*                                                *',$0D,$0A
        	        DC.B '*           LEGEND OF THE MICROVERSE             *',$0D,$0A
        	        DC.B '*                                                *',$0D,$0A
        	        DC.B '**************************************************',$0D,$0A,0
                DC.B 0

; ----- Post-Game / Replay Messages -----        
DAYS_SURVIVED_MSG: 
                DC.B '----------------------------------------', $0D,$0A
                DC.B '        Days survived: ',0

PLAY_AGAIN_MSG: DC.B '----------------------------------------', $0D,$0A
                DC.B '   Do you want to play again? (Y/N): ',0

; ----- HUD / Status Labels -----
HEALTH_MSG:     DC.B ' HEALTH: ',0
FOOD_MSG:       DC.B ' | FOOD: ',0
ENERGY_MSG:     DC.B ' | ENERGY: ',0
DAY_MSG:        DC.B '--- DAY ',0


; ----- High Score / Record Messages -----
NEW_RECORD_MSG: DC.B '************************************', $0D,$0A
                DC.B '   NEW ENDLESS RECORD ACHIEVED!', $0D,$0A
                DC.B '   You are a true survivor!', $0D,$0A
                DC.B '************************************', $0D,$0A,0

HS_LABEL:       DC.B 'High Score: ',0

NEW_HS_LABEL:   DC.B '        New High Score: ',0



;-------------------------------------------------------
; GAME VARIABLES (Reserved Memory Space)
;-------------------------------------------------------
HEALTH:        DS.B 1          ; Player health
ENERGY:        DS.B 1          ; Player energy
FOOD:          DS.B 1          ; Player food supply
DAY_COUNT:     DS.B 1          ; Day counter
HIGH_SCORE:    DS.B 1          ; High score for endless mode
MODE:          DS.B 1          ; Selected game mode (0=Story,1=Endless)
ACTION:        DS.B 1          ; Current action selected by player

	END START













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
