################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Rudraksh Monga, 1008018342
# Student 2: Saleh Yasin, 1008321941
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

########################### Easy Features ####################################
# 5. Allow the user to pause the game by pressing the keyboard key p.
# 9. Allow the player to launch the ball at the beginning of each attempt (by pressing p).
# 7. Add 'unbreakable' bricks
########################### Hard Features ####################################
# 1. Track and display the playher's score, which is based on how many bricks have been broken so far.
# 4. Create a second level with a different layout of bricks.
##############################################################################

.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
    #0x61 is "a"
    #0x64 is "d"
    #0x69 is "i"
    #0x70 is "p"
    #0x71 is "q"
    
MY_COLOUR:
    .word 0xa3a3a3	# 0 grey color - wall
    .word 0x000000	# 4 black color - for redrawing/covering other drawn stuff, illusion of movement
    .word 0xffffff	# 8 white color - paddle, ball
    .word 0xff0000	# 12 red color - brick layer 1
    .word 0xCC8899	# 16 purple color - brick layer 3
    .word 0x0000FF	# 20 blue color - brick layer 2
    .word 0xa3a3a4	# 24 greyish color - unbreakable brick

##############################################################################
# Mutable Data
##############################################################################
LEVEL:
    .word 1		#0 1 if level 1, 2 if level 2

PADDLE_POSITION:
    .word 12		# 0 x_coordinate of paddle
    .word 12 		# 4 previous x_coordiante of paddle
    
BALL_POSITION:
	.word 16	# 0 x_coordinate of ball
	.word 58	# 4 y_coordinate of ball
	.word 16 	# 8 previous x_coordinate of ball
	.word 58	# 12 previous y_coordainte of ball
	
BALL_VECTOR:
	.word 0		# 0 change in x_coordinate of ball
	.word -1	# 4 change in y_coordinate of ball
	
PAUSE:
	.word 0		# 0  game is paused when 0, and unpaused when 1
	
NUM_OF_BRICKS:		# breakable bricks
	.word 0		# 0 number of bricks in the level
	
SCORE:
	.word 0		# 0 score of player

##############################################################################
# Code
##############################################################################
.text
# Run the Brick Breaker game.
	
main:
    jal DRAW_SCENE	# jump to the function responsible for drawing the initial scene
    
main_pause_loop:

	# this is where the user should be able to move the paddle beforehand
	# three possible inputs, a, d, or p (to begin)
	
	lw $t0, ADDR_KBRD
	lw $s0, 0($t0)				# contains keyword input signal
   	beq $s0, 1, main_pause_key_input	# if key has been pressed, handle it

    	j main_pause_loop
    	
    	main_pause_key_input:
    	lw $s0, 4($t0)				# $s0 = hex of key pressed
    	
    	# if a is pressed, go left
    	beq $s0, 0x61, main_pause_left
    	# if d is pressed, go right
    	beq $s0, 0x64, main_pause_right
    	# if p is pressed, go to game loop
    	beq $s0, 0x70, game_loop
    	# else, back to main_pause_loop
    	j main_pause_loop
    	
    	main_pause_left:
    	# want to make paddle move left
    	
    	la $t0, PADDLE_POSITION
    	lw $s1, 0($t0)			# $t1 = current_paddle_pos
    	
    	ble $s1, 1, main_pause_loop 	# don't update pos if at left-most point
    	
    	# if paddle_x > 1, 
    	# draw over current pos of paddle with black
    	addi $a0, $s1, 0
    	li $a1, 0x000000
    	jal DRAW_PADDLE
    	
    	# shift paddle left by 1
    	la $t0, PADDLE_POSITION
    	sw $s1, 4($t0)			# update prev paddle pos
    	addi $s1, $s1, -1		# pos -= 1
    	sw $s1, 0($t0)    		# update curr paddle pos
    	
    	# redraw paddle
    	addi $a0, $s1, 0
    	li $a1, 0xffffff
    	jal DRAW_PADDLE
    	
    	# draw over current pos of ball
    	la $t0, BALL_POSITION
    	lw $s0, 0($t0)			# $s0 = x_pos of ball
    	lw $s1, 4($t0)			# $s1 = y_pos of ball
    	
    	addi $a0, $s0, 0
    	addi $a1, $s1, 0
    	li $a2, 0x000000
    	jal DRAW_BALL
    	
    	# change ball x_pos
    	la $t0, BALL_POSITION
    	sw $s0, 8($t0)			# update prev x_pos of ball
    	addi $s0, $s0, -1		# new x_pos of ball
    	sw $s0, 0($t0)			# update x_pos of ball
    	# redraw ball
    	addi $a0, $s0, 0
    	addi $a1, $s1, 0
    	li $a2, 0xffffff
    	jal DRAW_BALL
    	
    	# jump back to main_pause_loop
    	j main_pause_loop
    	
    	main_pause_right:
    	# want to make paddle move right
    	
    	la $t0, PADDLE_POSITION
    	lw $s1, 0($t0)			# $t1 = current_paddle_pos
    	
    	bge $s1, 24, main_pause_loop 	# don't update pos if at right-most point
    	
    	# if paddle_x < 24, 
    	# draw over current pos of paddle with black
    	addi $a0, $s1, 0
    	li $a1, 0x000000
    	jal DRAW_PADDLE
    	
    	# shift paddle right by 1
    	la $t0, PADDLE_POSITION
    	sw $s1, 4($t0)			# update prev paddle pos
    	addi $s1, $s1, 1		# pos += 1
    	sw $s1, 0($t0)    		# update curr paddle pos
    	
    	# redraw paddle
    	addi $a0, $s1, 0
    	li $a1, 0xffffff
    	jal DRAW_PADDLE
    	
    	# draw over current pos of ball
    	la $t0, BALL_POSITION
    	lw $s0, 0($t0)			# $s0 = x_pos of ball
    	lw $s1, 4($t0)			# $s1 = y_pos of ball
    	
    	addi $a0, $s0, 0
    	addi $a1, $s1, 0
    	li $a2, 0x000000
    	jal DRAW_BALL
    	
    	# change ball x_pos
    	la $t0, BALL_POSITION
    	sw $s0, 8($t0)			# update prev x_pos of ball
    	addi $s0, $s0, 1		# new x_pos of ball
    	sw $s0, 0($t0)			# update x_pos of ball
    	# redraw ball
    	addi $a0, $s0, 0
    	addi $a1, $s1, 0
    	li $a2, 0xffffff
    	jal DRAW_BALL
    	
    	# jump back to main_pause_loop
    	j main_pause_loop

game_loop:
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
    	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep
	# 5. Go back to 1
	
	# update screen
	jal UPDATE_SCENE
	
	#check if key has been pressed
	lw $s0, ADDR_KBRD
	lw $s1, 0($s0)			# contains keyword input signal
	beq $s1, 1, KEYBOARD_INPUT	# if key has been pressed, handle it
	
	continue:
	# change update ball location using ball vector
	jal UPDATE_BALL_LOCATION
	
	# when checking for collision , update ball vector
	jal CHECK_COLLISION
	
	# update score drawn on screen
	jal UPDATE_SCORE
	
	# check if game has finished
	jal CHECK_FINISHED
	
		
	###SLEEP
	li $v0, 32
    	li $a0, 40
    	syscall
	###SLEEP
	    
   	b game_loop
   	
   	pause_loop:
   	lw $s0, ADDR_KBRD
	lw $s1, 0($s0)			# contains keyword input signal
   	beq $s1, 1, PAUSE_INPUT		# if key has been pressed, handle it
   	
   	b pause_loop
   	
   	
# draw_one_digit(x, y, num)
# 	Draws the input digit at the given (x, y) coordinate
#	and draws it within a 3x3 block with color white (0xFFFFFF).
#	Note that (x, y) represents start_coordinate of 3x3 block.
#
# $a0 - x_coordinate
# $a1 - y_coordinate
# $a2 - number to be draws
DRAW_ONE_DIGIT:
	# calls other sub functions to draw number, where each sub func draws 1 number
	# case/switch statement etc
	
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	j ERASE_SCORE
	
	# BODY
	# note - each of these branches should jump back to draw_one_digit_epi
	# note - made design decision to not make them functions to make following switch statement simpler
	draw_digit_body:
	beq $a2, 0, DRAW_ZERO
	beq $a2, 1, DRAW_ONE
	beq $a2, 2, DRAW_TWO
	beq $a2, 3, DRAW_THREE
	beq $a2, 4, DRAW_FOUR
	beq $a2, 5, DRAW_FIVE
	beq $a2, 6, DRAW_SIX
	beq $a2, 7, DRAW_SEVEN
	beq $a2, 8, DRAW_EIGHT
	beq $a2, 9, DRAW_NINE
	
	# EPILOGUE
	draw_one_digit_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



DRAW_ZERO:
	# do stuff here to draw the digit 0 in the 5x5 block specified by $a0, $a1 in DRAW_ONE_DIGIT
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)			
	
	
	jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 128($s1)
    sw $s0, 256($s1)
    sw $s0, 384($s1)
    sw $s0, 512($s1)
    sw $s0, 516($s1)
    sw $s0, 520($s1)
    sw $s0, 524($s1)
    sw $s0, 528($s1)
    sw $s0, 400($s1)
    sw $s0, 272($s1)
    sw $s0, 144($s1)
    sw $s0, 16($s1)
    
    	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	j  draw_one_digit_epi

DRAW_ONE:

	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)			
	
	

	jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 132($s1)
    sw $s0, 136($s1)
    sw $s0, 392($s1)
    sw $s0, 264($s1)
    sw $s0, 512($s1)
    sw $s0, 516($s1)
    sw $s0, 520($s1)
    sw $s0, 524($s1)
    sw $s0, 528($s1)

	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	j  draw_one_digit_epi


DRAW_TWO:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)	

    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 140($s1)
    sw $s0, 264($s1)
    sw $s0, 388($s1)
    sw $s0, 516($s1)
    sw $s0, 520($s1)
    sw $s0, 524($s1)
    sw $s0, 528($s1)
    
    	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	

	j  draw_one_digit_epi

DRAW_THREE:

	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)   
	
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 144($s1)
    sw $s0, 272($s1)
    sw $s0, 400($s1)
    sw $s0, 528($s1)
    sw $s0, 524($s1)
    sw $s0, 520($s1)
    sw $s0, 516($s1)
    sw $s0, 512($s1)
    sw $s0, 268($s1)
    sw $s0, 264($s1)
    sw $s0, 260($s1)
    sw $s0, 400($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	

	j  draw_one_digit_epi

DRAW_FOUR:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)   
	
    sw $s0, 0($s1)
    sw $s0, 128($s1)
    sw $s0, 256($s1)
    sw $s0, 260($s1)
    sw $s0, 16($s1)
    sw $s0, 144($s1)
    sw $s0, 272($s1)
    sw $s0, 400($s1)
    sw $s0, 528($s1)
    sw $s0, 264($s1)
    sw $s0, 268($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	j  draw_one_digit_epi

DRAW_FIVE:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 272($s1)
    sw $s0, 400($s1)
    sw $s0, 256($s1)
    sw $s0, 128($s1)
    sw $s0, 528($s1)
    sw $s0, 524($s1)
    sw $s0, 520($s1)
    sw $s0, 516($s1)
    sw $s0, 512($s1)
    sw $s0, 268($s1)
    sw $s0, 264($s1)
    sw $s0, 260($s1)
    sw $s0, 400($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	j  draw_one_digit_epi

DRAW_SIX:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 272($s1)
    sw $s0, 400($s1)
    sw $s0, 256($s1)
    sw $s0, 128($s1)
    sw $s0, 528($s1)
    sw $s0, 524($s1)
    sw $s0, 520($s1)
    sw $s0, 516($s1)
    sw $s0, 512($s1)
    sw $s0, 268($s1)
    sw $s0, 264($s1)
    sw $s0, 260($s1)
    sw $s0, 400($s1)
    sw $s0, 384($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	j  draw_one_digit_epi

DRAW_SEVEN:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
    jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 268($s1)
    sw $s0, 392($s1)
    sw $s0, 516($s1)
    sw $s0, 144($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	j  draw_one_digit_epi

DRAW_EIGHT:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
	jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 128($s1)
    sw $s0, 256($s1)
    sw $s0, 384($s1)
    sw $s0, 512($s1)
    sw $s0, 516($s1)
    sw $s0, 520($s1)
    sw $s0, 524($s1)
    sw $s0, 528($s1)
    sw $s0, 400($s1)
    sw $s0, 272($s1)
    sw $s0, 144($s1)
    sw $s0, 16($s1)
    sw $s0, 260($s1)
    sw $s0, 264($s1)
    sw $s0, 268($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	j  draw_one_digit_epi

DRAW_NINE:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
   jal GET_LOCATION_ADDRESS
    
    addi $s1, $v0, 0
    
    la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    lw $s0, 8($s0)      	# colour is white
    
    sw $s0, 0($s1)
    sw $s0, 4($s1)
    sw $s0, 8($s1)
    sw $s0, 12($s1)
    sw $s0, 16($s1)
    sw $s0, 128($s1)
    sw $s0, 256($s1)
    sw $s0, 400($s1)
    sw $s0, 272($s1)
    sw $s0, 144($s1)
    sw $s0, 16($s1)
    sw $s0, 260($s1)
    sw $s0, 264($s1)
    sw $s0, 268($s1)
    sw $s0, 528($s1)
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
   	
   	j  draw_one_digit_epi
   	

# update_score()
# 	Draw the updated score on screen	
UPDATE_SCORE: 	
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	
	# BODY
	la $t0, SCORE
	lw $s0, 0($t0)		# $s0 = curr_score
	
	bgt $s0, 9, update_score_draw_two_digits	# if curr_score > 9, go to two digit draw func
	
	update_score_draw_one_digit:
	addi $a2, $s0, 0	# $a2 = num to be drawn
	li $a0, 10		# $a0 = x_coord = 10
	li $a1,	0		# $a1 = y_coord = 1
	# ^ begin drawing the one_digit within the 3x3 block whose top left cornor is specified by (x, y)
	
	jal DRAW_ONE_DIGIT
	
	j update_score_epi
	
	
	update_score_draw_two_digits:
	# need to break down score into 2 digits, use div operation
	li $t0, 10
	div $s0, $t0		# lo = score // 10 = left most digit of score (as score is always 2 digits)
				# hi = score % 10 = right most digit of score
				
	mflo $t0		# $t0 = left most digit of score
				
	addi $a2, $t0, 0	# $a2 = num to be drawn = left digit of score
	li $a0, 10		# $a0 = x_coord = 10
	li $a1,	0		# $a1 = y_coord = 0
	# ^ begin drawing the one_digit within the 3x3 block whose top left cornor is specified by (x, y)
	
	jal DRAW_ONE_DIGIT
	
	mfhi $t0		# $t0 = right most digit of score
				
	addi $a2, $t0, 0	# $a2 = num to be drawn = right digit of score
	li $a0, 17		# $a0 = x_coord = 17
	li $a1,	0		# $a1 = y_coord = 0
	# ^ begin drawing the one_digit within the 3x3 block whose top left cornor is specified by (x, y)
	
	jal DRAW_ONE_DIGIT
	
	
	# EPILOGUE
	update_score_epi:
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
			
  	
# check_finished()
# 	Checks if the game has finished
CHECK_FINISHED:
	# BODY
	la $t0, SCORE
	lw $t0, 0($t0)		# $t0 = curr_score
	
	la $t1, NUM_OF_BRICKS
	lw $t1, 0($t1)		# $t1 = num_of_breakable_bricks
	
	la $t2, LEVEL
	lw $t2, 0($t2)		# t2 = levels
	
	beq $t2, 2, check_finished_level_two
	# if here, then still on level 1
	
	beq $t0, 1, DRAW_SCENE_LEVEL_2	# if curr_score = num_breakable_bricks, then all breakable bricks
						# have been broken, so go to next level
	
	#if not, then return to where you were before without changing anything
	j check_finished_epi
	
	check_finished_level_two:
	# if here, then on level 2
	
	beq $t0, $t1, QUIT_GAME			# if curr_Score = num_breakable_bricks and on level 2, quit game
	
	# EPILOGUE
	check_finished_epi:
	jr $ra
   	

PAUSE_INPUT: 
	lw $s0, 4($s0)				# $s0 contains hex corresponding to input key
	beq $s0, 0x71, QUIT_GAME		# if q is pressed, quit game
	beq $s0, 0x70, HANDLE_PAUSE		# if p is pressed outside of gameloop, handle pause
	j pause_loop
	

HANDLE_PAUSE:
	la $t0, PAUSE
	lw $t1, 0($t0)
	
	beq $t1, 0, unpause_game		#unpause game if paused
	beq $t1, 1, pause_game			#pause game if unpaused
	
	
	unpause_game: 				#switch pause => 1
	addi $t1, $0, 1
	sw $t1, 0($t0)
	j game_loop
	
	pause_game:
	addi $t1, $0, 0
	sw $t1, 0($t0)
	j pause_loop

# check_collision()
#	Check's if there are any collisions for ball and changes ball vector accordingly   	
CHECK_COLLISION:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# BODY
	jal CHECK_PADDLE_COLLISION
	
	jal CHECK_OTHER_COLLISION
	
	# EPILOGUE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

   	
# check_paddle_collision()
#	Checks if the ball collides with the paddle
CHECK_PADDLE_COLLISION:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# BODY
	
	# get current position of ball
	la $t0, BALL_POSITION
	lw $s0, 0($t0)		# $s0 = x_coord of ball
	lw $s1, 4($t0)		# $s1 = y_coord of ball
	# get curr ball vector
	la $t0, BALL_VECTOR
	lw $t1, 0($t0)		# $t1 = x_change
	lw $t2, 4($t0)		# $t2 = y_change
	# calculate next position of ball
	add $s2, $s0, $t1	# $s2 = next x_cord of ball
	add $s3, $s1, $t2	# $s3 = next y_cord of ball
	
	addi $a0, $s2, 0	# $a0 = x_coord
	addi $a1, $s3, 0	# $a1 = y_cord
	jal GET_LOCATION_ADDRESS
	
	lw $t3, 0($v0)		# $t3 = color at next location address
	
	# if next position color is not white, jump to epilogue; y_cord of paddle don't matter
	bne $t3, 0xffffff, check_paddle_collision_epi
	
	# if next position color is white
	# first, get x_cord of paddle
	la $t0, PADDLE_POSITION
	lw $t0, 0($t0)		# $t0 = x_cord of paddle
	# determine where on paddle is it by doing curr_x_cord_ball - x_cord_paddle
	sub $s1, $s0, $t0	# $s1 = no. of units away from x_coord of paddle; $s1 = 0, 1, 2, 3, 4, 5, or 6
	# based on paddle collision position, change ball vector
	# define middle = 2, 3, or 4
	beq $s1, 2, middle	# if in the middle, branch to middle
	beq $s1, 3, middle	# if in the middle, branch to middle
	beq $s1, 4, middle	# if in the middle, branch to middle
	
	addi $t0, $0, 2		# $t0 = 2
	
	slt $t1, $s1, $t0	# no. of units away < 2?
	beq $t1, 0, right_of_middle	# if not, then paddle is right of middle
	
	# if yes, then proceed to left_of_middle
	left_of_middle:
	# collision on left of paddle, put x_change to -1, y_change to -1
	la $t0, BALL_VECTOR
	addi $t1, $0, -1		# $t1 = -1
	sw $t1, 0($t0)			# set x_change to -1
	sw $t1, 4($t0)			# set y_change to -1
	
	b check_paddle_collision_epi
	
	middle:
	# collision in the middle of paddle, put y_change of ball vector to -1, put x_change to 0
	la $t0, BALL_VECTOR
	addi $t1, $0, -1		# $t1 = -1
	sw $t1, 4($t0)			# update y_change to -1
	addi $t1, $0, 0			# $t1 = 0
	sw $t1, 0($t0)			# update x_change to 0
	
	b check_paddle_collision_epi
	
	right_of_middle:
	# collision on right of paddle, put x_change to 1, y_change to -1
	la $t0, BALL_VECTOR
	addi $t1, $0, 1			# $t1 = 1
	sw $t1, 0($t0)			# set x_change to 1
	addi $t1, $0, -1		# $t1 = -1
	sw $t1, 4($t0)			# set y_change to -1
	
	# EPILOGUE
	check_paddle_collision_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
   	
   	
# check_other_collision()
#	checks for other collisions   	
CHECK_OTHER_COLLISION:	
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# BODY
	
	# get current position of ball
	la $t0, BALL_POSITION
	lw $s0, 0($t0)		# $s0 = x_coord of ball
	lw $s1, 4($t0)		# $s1 = y_coord of ball
	# get curr ball vector
	la $t0, BALL_VECTOR
	lw $t1, 0($t0)		# $t1 = x_change
	lw $t2, 4($t0)		# $t2 = y_change
	# calculate next position of ball
	add $s2, $s0, $t1	# $s2 = next x_cord of ball
	add $s3, $s1, $t2	# $s3 = next y_cord of ball
	
	addi $a0, $s2, 0	# $a0 = x_coord
	addi $a1, $s3, 0	# $a1 = y_cord
	jal GET_LOCATION_ADDRESS
	
	lw $t3, 0($v0)		# $t3 = color at next location address
	
	beq $t3, 0x000000, check_other_collision_epi	# skip function if black folor found, i.e. empty space
	beq $t3, 0xffffff, check_other_collision_epi	# skip function if white color found, i.e. paddle
	
	#Following executes only if the colors are Grey, Red, Blue or Purple
	
	seq $t4, $t3, 0xa3a3a3			# Checks if collision is with grey, hence wall
	beq $t4, 1, handle_wall_collision	# if it is grey, go to handle_wall_collision	
	beq $t3, 0xa3a3a4, ball_bounce		# check if it is a grey block, then do ONLY collision
	b color_collision
	
	# handles wall collision
	handle_wall_collision:
	beq $s3, 5, handle_top_wall_collision		# Checks if it is about to hit top wall
	
    	beq $s2, 0, handle_left_wall_collision        # Checks if it is hitting left wall

    	beq $s2, 31, handle_right_wall_collision      # Checks if it is hitting right wall
    	
    	j check_other_collision_epi 			# pls dont remove this, it is a contingency ty


    	# left wall collision
    	handle_left_wall_collision:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, 1        # $t1 = +1
    	sw $t1, 0($t0)        # put x-vector as +1
    	j check_other_collision_epi

    	#right wall collision
    	handle_right_wall_collision:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, -1        # $t1 = -1
    	sw $t1, 0($t0)        # put x-vector as -1
    	j check_other_collision_epi
    	
    	handle_top_wall_collision:
    	beq $s2, 0, handle_top_left_corner_collision
    	beq $s3, 31, handle_top_right_corner_collision
    	
    	la $t0, BALL_VECTOR
    	addi $t1, $0, 1        # $t1 = 1
    	sw $t1, 4($t0)        # put y-vector as 1
    	j check_other_collision_epi  
    		
    		
    	handle_top_left_corner_collision:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, 1        # $t1 = 1
    	sw $t1, 4($t0)
    	sw $t1, 0($t0)
    	j check_other_collision_epi
    	
    	handle_top_right_corner_collision:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, 1        # $t1 = -1
    	sw $t1, 4($t0) 
    	addi $t1, $0, -1
    	sw $t1, 0($t0)
    	j check_other_collision_epi 
    	
    			
    	#brick removal
    	brick_removal:
    	addi $a0, $s2, 0	# $a0 = x_coord
	addi $a1, $s3, 0	# $a1 = y_cord
    	jal REMOVE_BRICK
    	
    	addi $t5, $0, 0
    	j check_other_collision_epi
    	
    	#This is for when the ball collides into a brick
    	color_collision:    	
    	addi $t5, $0, 1
    	
    	ball_bounce:
    	bne $t2, 0, handle_y_axis_collision	#check if y-axis is not equal to zero
    	
    	bne $t1, 0, handle_x_axis_collision	#check if x-axis is not equal to zero, only when y = 0
    	

    	#Handles y-axis parts of collision
    	handle_y_axis_collision:	
    	beq $t2, 1, reverse_y_to_negative	#This means $t1 = 1 and needs to be changed to -1
    	beq $t2, -1, reverse_y_to_positive	#This means $t1 = -1 and needs to be changed to +1
    	
    	reverse_y_to_negative:
    	la $t0, BALL_VECTOR
    	addi $t2, $0, -1        # $t1 = -1
    	sw $t2, 4($t0)        # put y-vector as -1
    	j check_other_collision_epi
    	
    	reverse_y_to_positive:
    	la $t0, BALL_VECTOR
    	addi $t2, $0, 1        # $t1 = 1
    	sw $t2, 4($t0)        # put y-vector as 1
    	j check_other_collision_epi
    	
    	
    	#handles when x!=0
    	handle_x_axis_collision:	
    	beq $t1, 1, reverse_x_to_negative	#This means $t1 = 1 and needs to be changed to -1
    	beq $t1, -1, reverse_x_to_positive	#This means $t1 = -1 and needs to be changed to +1
    	
    	reverse_x_to_negative:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, -1        # $t1 = -1
    	sw $t1, 0($t0)        # put x-vector as -1
    	j check_other_collision_epi
    	
    	reverse_x_to_positive:
    	la $t0, BALL_VECTOR
    	addi $t1, $0, 1        # $t1 = 1
    	sw $t1, 0($t0)        # put x-vector as 1
    	j check_other_collision_epi
	
	# EPILOGUE
	check_other_collision_epi:
	beq $t5, 1, brick_removal
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
   
   
# remove_brick($a0: x, $a1, y)
#		finds and removes the brick at point (x, y)

REMOVE_BRICK:
	#PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#BODY
	jal FIND_BRICK		#Brick to remove is at ($v0, $v1)
	
	la $t5, MY_COLOUR
	lw $a2, 4($t5)		#make t5 as black
	move $a0, $v0
	move $a1, $v1
	jal DRAW_BRICK
	
	# increment score as brick has been broken
	la $t0, SCORE
	lw $t1, 0($t0)		# $t1 = curr_score
	addi $t1, $t1, 1	# curr_score += 1
	sw $t1, 0($t0)		# update curr_score
	
	#EPILOGUE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# find_brick()
#		removes brick at point (x, y)
FIND_BRICK:
	#assume $a0 = x, $a1 = y of a point at ANY brick
	
	#PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#BODY
	find_brick_calculate_x:
	addi $a0, $a0, -1
	addi $t0, $0, 3
	div $a0, $t0
	mflo $t0
	mulo $v0, $t0, 3
	addi $v0, $v0, 1
	
	find_brick_calulate_y:
	addi $t1, $0, 2
	div $a1, $t1
	mflo $v1
	sll $v1, $v1, 1
	
	
	#EPILOGUE
	find_brick_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# update_ball_location()
# 	Updates prev and curr ball coordiantes using ball vector
UPDATE_BALL_LOCATION:
	la $t0, BALL_POSITION
	lw $t1, 0($t0)		# $t1 = x_coord
	sw $t1, 8($t0)		# update prev x_coord
	lw $t1, 4($t0)		# $t1 = y_coord
	sw $t1, 12($t0)		# update prev y_coord
	
	la $t1, BALL_VECTOR
	lw $t2, 0($t1) 		# $t2 = x_change
	lw $t3, 4($t1)		# $t3 = y_change
	lw $t4, 0($t0)		# $t4 = x_cord
	lw $t5, 4($t0)		# $t5 = y_coord
	
	add $t4, $t4, $t2 	# x_cord = x_cord + x_change
	add $t5, $t5, $t3	# y_cord = y_cord + y_change
	
	bge $t5, 63, QUIT_GAME
	
	sw $t4, 0($t0)		# update x_cord
	sw $t5, 4($t0)		# update y_cord
	
	update_ball_location_epi:
	jr $ra
    
    
KEYBOARD_INPUT:
	lw $s0, 4($s0)				# $s0 contains hex corresponding to input key
	beq $s0, 0x71, QUIT_GAME		# if q is pressed, quit game
	beq $s0, 0x61, HANDLE_LEFT_INPUT	# if a is pressed, handle left input
	beq $s0, 0x64, HANDLE_RIGHT_INPUT	# if d is pressed, handle right input
	beq $s0, 0x70, HANDLE_PAUSE		# if p is pressed within game loop, handle pause
	
	j continue


HANDLE_LEFT_INPUT:
	# left input has been called	
	# set previous coordinate of paddle to current coordinate	
	la $t0, PADDLE_POSITION
	lw $t1, 0($t0)		# $t1 = current x_coordinate
	beq $t1, 1, handle_left_input_epi	# if at the left end, don't go more left
	sw $t1, 4($t0)		# set prev x_coordinate to curr x_coordinate
	# update current coordinate by decrementing x_coordiante
	addi $t1, $t1, -1	# x_cord = prev_x - 1
	sw $t1, 0($t0)		# updated current coordinate
	
	handle_left_input_epi:
	j continue


HANDLE_RIGHT_INPUT:
	# right input has been called
	# set previous coordinate of paddle to current coordinate
	la $t0, PADDLE_POSITION
	lw $t1, 0($t0)		# $t1 = current x_coordinate
	beq $t1, 24, handle_right_input_epi	# if at the right end, don't go more right
	sw $t1, 4($t0)		# set prev x_cooridnate to curr x_coordinate
	# update current coordinate by incrementing x coordiante
	addi $t1, $t1, 1	# x_cord += 1
	sw $t1, 0($t0)		# updated current coordinate
	
	handle_right_input_epi:
	j continue


QUIT_GAME:
	li $v0, 10                      # Quit gracefully
	syscall


# update_scene()
# 	Updates scene by redrawing paddle and ball
UPDATE_SCENE:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# BODY
	
	# firstly, draw the paddle with black over its previous position
	la $a0, PADDLE_POSITION
	lw $a0, 4($a0)		# $a0 = previous x_coordinate of paddle
	la $t0, MY_COLOUR
	lw $a1, 4($t0)		# $a1 = color of background black
	jal DRAW_PADDLE
	# then, draw paddle with white over its current position
	la $a0, PADDLE_POSITION
	lw $a0, 0($a0)		# $a0 = x_coordinate of paddle
	la $t0, MY_COLOUR
	lw $a1, 8($t0)		# $a1 = color of paddle (white)
	jal DRAW_PADDLE
	
	# draw the ball with black over its previous position
	la $t0, BALL_POSITION
	lw $a0, 8($t0)		# x = previous x coordinate
	lw $a1, 12($t0)		# y = previous y coordinate
	la $t0, MY_COLOUR
	lw $a2, 4($t0)		# $a2 = color of background (black)
	jal DRAW_BALL
	# then draw the ball with white over its current position
	la $t0, BALL_POSITION
	lw $a0, 0($t0)		# x = x coordinate
	lw $a1, 4($t0)		# y = y coordinate
	la $t0, MY_COLOUR
	lw $a2, 8($t0)		# $a2 = color of ball (white)
	jal DRAW_BALL
	
	# EPILOGUE
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	

DRAW_SCENE:
	# PROLOGUE
	# before calling another procedure store current $ra in stack 
	
	addi $sp, $sp, -4 	# make space in stack to store $ra
	sw $ra, 0($sp) 		# store current $ra into stack

	jal DRAW_WALLS		# jump to the function responsible for drawing walls
	
	# draw paddle initally at (14, 61)
	la $a0, PADDLE_POSITION
	lw $a0, 0($a0)		# $a0 = x_coordinate of paddle
	la $t0, MY_COLOUR
	lw $a1, 8($t0)		# $a1 = color of paddle (white)
	jal DRAW_PADDLE
	
	
	# draw ball initally at (16, 60)
	la $t0, BALL_POSITION
	lw $a0, 0($t0)		# x = 16
	lw $a1, 4($t0)		# y = 60
	la $t0, MY_COLOUR
	lw $a2, 8($t0)		# $a2 = color of ball (white)
	jal DRAW_BALL
	
	li $a0, 8		# y_coordinate of first brick layer = 8
	jal DRAW_BRICK_LAYERS
	
	# EPILOGUE
	lw $ra, 0($sp)		# retrieve stored value of $ra from stack
	addi $sp, $sp, 4	# move stack back down
	
	jr $ra			# back to main
	
	
DRAW_WALLS:
	#PROLOGUE
	#store all previous values in the stack
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4	#s1 stores the display
	sw $s1, 0($sp)
	
	addi $sp, $sp, -4	#stores horizontal wall unit count
	sw $s2, 0($sp)
	
	addi $sp, $sp, -4	#loop counter for horizontal walls
	sw $s3, 0($sp)
	
	addi $sp, $sp, -4	#the conditional for all loops
	sw $s4, 0($sp)
	
	addi $sp, $sp, -4	#s5 stores the vertical uwall nit count
	sw $s5, 0($sp)
	
	addi $sp, $sp, -4	#loop counter for vertical walls
	sw $s6, 0($sp)
	
	
	# Let us start by getting the colour we want to draw with
    	la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    	lw $s0, 0($s0)      	# colour = temp[0]

   	# We also need to know where to write to the display
    	la $s1, ADDR_DSPL   	# temp = &ADDR_DSPL
    	lw $s1, 0($s1)   	# display = *temp

    	# Since the display is 256 pixels wide, and each unit is 8 pixels wide,
    	# then a line is 32 units wide
    
    	# Because the display is 512 pixels long, and each unit is 8 pixels long,
    	# then a wall is 64 units long
    	li $s2, 32		# Horizontal_UNIT_COUNT = 32
    	li $s5, 64		# Vertical_UNIT_COUNT = 64

    	# Now let's iterate 32 on t3, and 64 times on t6, drawing each unit in the line
    	li $s3, 0        	# i = 0
    	li $s6, 0
    
    	j draw_top_line_loop
    
draw_top_line_loop:
    slt $s4, $s3, $s2           # i < UNIT_COUNT ?
    beq $s4, $0, draw_both_walls_loop  # if not, then done

        sw $s0, 640($s1)        # Paint unit with colour
        addi $s1, $s1, 4        # Go to next unit

    addi $s3, $s3, 1            # i = i + 1
    b draw_top_line_loop
    
#Function to draw a wall on the left side
draw_both_walls_loop:
	slt $s4, $s6, $s5		# i < UNIT_COUNT ?
	beq $s4, $0, end_draw_line	# if not, then done
	
	    sw $s0, 640($s1)		# Paint the first element of the first row
	    sw $s0, 764($s1)		# Paint the last element of the first row
	    addi $s1, $s1, 128		# Go to next line
	    
	addi $s6, $s6, 1		# i = i + 1
	b draw_both_walls_loop		# saleh
	

end_draw_line:
	#EPILOGUE
	#restore stack values (KEEP LAST-IN FIRST-OUT IN MIND)
	lw $s6, 0($sp)
	addi $sp, $sp, 4
	
	lw $s5, 0($sp)
	addi $sp, $sp, 4
	
	lw $s4, 0($sp)
	addi $sp, $sp, 4
	
	lw $s3, 0($sp)
	addi $sp, $sp, 4
	
	lw $s2, 0($sp)
	addi $sp, $sp, 4
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	#jump back
	jr $ra 


# get_location_address(x_coordinate, y_coordinate) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 63, inclusive
#
#   $a0 = x;
#   $a1 = y;
GET_LOCATION_ADDRESS:
	
	sll $a0, $a0, 2		# x_bytes = x * 4; 4 bytes in a word; each word corresponds to 8 pixels in row
	sll $a1, $a1, 7		# y_bytes = y * 128; each row contains 32 units = 32*4 = 128 bytes
	
	# loc_address = base_address + x_bytes + y_bytes
	la $v0, ADDR_DSPL
	lw $v0, 0($v0)
	add $v0, $v0, $a0	# base_address + x_bytes
	add $v0, $v0, $a1	# $v0 = base_Address + x_bytes + y_bytes
	
	jr $ra			# return to caller
	
	
# draw_paddle(x_coordinate, color)
# 	Draw the paddle at the given start_address with the given color
# 
# $a0 = x_coordinate of paddle
# $a1 = color of paddle
DRAW_PADDLE:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# BODY
	addi $s0, $a1, 0		# $s0 saves value of $a1
					# $a0 = x
	li $a1, 61			# $a1 = 61
	jal GET_LOCATION_ADDRESS
	addi $a0, $v0, 0		# $a0 is start_address
	
	addi $a1, $s0, 0		# $a1 is back to being color
	
	# paddle width is 7 units
	# not calling other procedures after this, ok to use non-preserved registers for counters
	li $t0, 0	# counter ($t0) = 0
	li $t3, 7	# size ($t3) = 7
	
	draw_paddle_loop:
	slt $t1, $t0, $t3		# counter < size?
	beq $t1, 0, draw_paddle_epi	# if yes, means 7 units drawn, branch to end; else:
	
	sw $a1, 0($a0)			# draw color square at address
	addi $a0, $a0, 4		# update address to point to next unit
	addi $t0, $t0, 1		# counter = counter + 1
	
	j draw_paddle_loop		# loop
	
	#EPILOGUE
	draw_paddle_epi:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
# draw_ball(x_coordinate, y_coordinate, color)
#	Draw the ball at the given start with the given color
#
# $a0 = x_coordinate
# $a1 = y_coordinate
# $a2 = color of ball
DRAW_BALL:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# BODY
	# $a0, $a1 already equal x, y, so no need to edit
	jal GET_LOCATION_ADDRESS
	addi $a0, $v0, 0	# $a0 contains address of ball
	
	sw $a2, ($a0)	# draw color square at address
	
	# EPILOGUE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# draw_brick_layers(y_coordinate)
# 	Draw 3 brick layers of different colors
#
# $a0 = y_coordiante of starting brick_layer
DRAW_BRICK_LAYERS:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# store $ra onto stack
	addi $sp, $sp, -4
	sw $s0, 0($sp)		# store $s0 onto stack
	
	# BODY
	addi $s0, $a0, 0	# $s0 conatins y_coordinate of starting brick layer
	
	la $a1, MY_COLOUR	# $a0 contains y_coorediante of first brick layer
	lw $a1, 12($a1)		# $a1 conatins red
	jal DRAW_BRICK_LAYER
	
	addi $s0, $s0, 2 	# $s0 contains starting y-coordiante of next layer
	addi $a0, $s0, 0
	la $a1, MY_COLOUR	# $a0 contains y_coorediante of next brick layer
	lw $a1, 20($a1)		# $a1 conatins blue
	jal DRAW_BRICK_LAYER
	
	addi $s0, $s0, 2	# $s0 contains starting y-coordiante of next layer
	addi $a0, $s0, 0
	la $a1, MY_COLOUR	# $a0 contains y_coorediante of next brick layer
	lw $a1, 16($a1)		# $a1 conatins purple
	jal DRAW_BRICK_LAYER
	
	# EPILOGUE
	lw $s0, 0($sp)
	addi $sp, $sp, 4	# pop $s0 from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# pop $ra from stack
	jr $ra
	
	
# draw_brick_layer(y_coordiante, color)
#	Draw a brick layer with the given color
#
# $a0 = y_coordinate of brick layer
# $a1 = color of brick layer
DRAW_BRICK_LAYER:

	# Edit to include random num generation between 0-9 inclusive


	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $sp, $sp, -16
	sw $s3, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
	# BODY
	#to draw the actual bricks: 30 units in row, 3 units per brick, 10 bricks per row
	li $s0, 0		# counter = 0
	li $s1, 10		# counter_terminator
	
	addi $s2, $a0, 0	# $s2 contains y_coordiante of brick layer
	addi $a2, $a1, 0	# $a2 = color of brick
	
	li $s3, 1		# $s3 = starting x_coordiante
	
	draw_brick_layer_loop:
	slt $t0, $s0, $s1	# counter < 10?
	beq $t0, 0, draw_brick_layer_epi	# if not, end loop
	
		# for draw_brick, $a0 = x, $a1 = y, $a2 = color (fixed, not being changed in function)
		addi $a0, $s3, 0	
		addi $a1, $s2, 0
		jal DRAW_BRICK
		addi $s3, $s3, 3	# update x_coordiante by adding 3 as each brick is 3 wide		
	
	addi $s0, $s0, 1	# counter += 1
	j draw_brick_layer_loop
	
	# EPILOGUE
	draw_brick_layer_epi:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	addi $sp, $sp, 16
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	

# draw_brick(x_coordinate, y_coordinate, color)
#	Draw a brack at the given start with the given color
#
# $a0 = x coordinate of brick
# $a1 = y coordinate of brick
# $a2 = color of brick
DRAW_BRICK:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	
	# BODY
	
	# $a0, $a1 is already x, y, so no need to make changes
	jal GET_LOCATION_ADDRESS
	addi $a0, $v0, 0	# $a0 = start_address of brick
	
	# randomly generate a number between 0-14. If it is 14, set color to greyish for 
	# unbreakable brick
	
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	
	# if brick color is black (0x000000) then is is being erased so don't generate
	# grey brick to replace it
	
	beq $a2, 0x000000, continue_draw_brick	# skips grey-brick code if brick is being erased
	
	# increment brick-count if non-black brick being drawn (does not matter if grey or not)
	la $t0, NUM_OF_BRICKS
	lw $t1, 0($t0)		# $t1 = num of breakable bricks
	addi $t1, $t1, 1	# breakable_bricks += 1
	sw $t1, 0($t0)		# update breakable bricks	
	
	li $v0, 42		# syscall produced ranodm number upto val in $a1
	li $a0, 0		# random num generator ID
	li $a1, 30		# max value (exclusive)
	syscall	
	
	# now, $a0 contains random return value
	
	bne $a0, 0, continue_draw_brick		# if rand_int is not 0, continue as before
						# if rand_int is 0, make color of brick greyish for unbreakable
						
	# decrement brick-count if grey brick drawn (in total, num_breakable_brick does not change)
	la $t0, NUM_OF_BRICKS
	lw $t1, 0($t0)		# $t1 = num of breakable bricks
	addi $t1, $t1, -1	# breakable_bricks -= 1
	sw $t1, 0($t0)		# update breakable bricks
						
	la $a2, MY_COLOUR
	lw $a2, 24($a2)		# loads greyish color into $a2 for unbreakable brick	
	
	continue_draw_brick:
	
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	
	# this calls no other function afterwards, so can use $t0, $t1 for counters
	
	# dimensions of brick: 2 x 3
	li $t0, 0 	# outside_counter = 0
	li $t3, 2	# outside brick width for loop termination
	
	draw_brick_outer_loop:
	slt $t4, $t0, $t3		# outside_counter < 2?
	beq $t4, 0, draw_brick_epi	# if no, exit for loop
	
	li $t1, 0	# inside_counter = 0
	li $t2, 3	# inside brick length for loop termination
	
	addi $t5, $a0, 0		# $t5 = start address of brick
	
		draw_brick_inner_loop:
		slt $t4, $t1, $t2	# inside_counter < 3?
		beq $t4, 0, draw_brick_outer_loop_epi 	# if no, exit inner for loop
		
		sw $a2, 0($t5)		# draw unit at the address
		addi $t5, $t5, 4	# go to next unit to the right
		
		addi $t1, $t1, 1	# inside_counter += 1
		j draw_brick_inner_loop
	
	draw_brick_outer_loop_epi:
	addi $t0, $t0, 1		# outside_counter += 1
	addi $a0, $a0, 128		# update start_address to (x, y+1)
	j draw_brick_outer_loop
	
	# EPILOGUE
	draw_brick_epi:
	lw $a2, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
	
DRAW_BRICK_LAYERS_LEVEL_2:
	# PROLOGUE
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# store $ra onto stack
	addi $sp, $sp, -4
	sw $s0, 0($sp)		# store $s0 onto stack
	
	# BODY
	addi $s0, $a0, 0	# $s0 conatins y_coordinate of starting brick layer
	
	la $a1, MY_COLOUR	# $a0 contains y_coordinate of first brick layer
	lw $a1, 12($a1)		# $a1 conatins red
	jal DRAW_BRICK_LAYER
	
	addi $s0, $s0, 2	# $s0 contains starting y-coordiante of next layer
	addi $a0, $s0, 0
	la $a1, MY_COLOUR	# $a0 contains y_coorediante of next brick layer
	lw $a1, 20($a1)		# $a1 conatins blue
	jal DRAW_BRICK_LAYER
	
	addi $s0, $s0, 8	# $s0 contains starting y-coordiante of next layer
	addi $a0, $s0, 0
	la $a1, MY_COLOUR	# $a0 contains y_coorediante of next brick layer
	lw $a1, 16($a1)		# $a1 contains purple
	jal DRAW_BRICK_LAYER
	
	# EPILOGUE
	lw $s0, 0($sp)
	addi $sp, $sp, 4	# pop $s0 from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# pop $ra from stack
	jr $ra
	
DRAW_SCENE_LEVEL_2:
	# PROLOGUE
	# before calling another procedure store current $ra in stack 
	jal ERASE_SCREEN

	jal DRAW_WALLS		# jump to the function responsible for drawing walls
	
	# draw paddle initally at (14, 61)
	addi $t6, $0, 12
	la $a0, PADDLE_POSITION
	sw $t6, 0($a0)
	lw $a0, 0($a0)		# $a0 = x_coordinate of paddle
	la $t0, MY_COLOUR
	lw $a1, 8($t0)		# $a1 = color of paddle (white)
	jal DRAW_PADDLE
	
	
	# draw ball initally at (16, 60)
	la $t0, BALL_POSITION
	addi $t6, $0, 14
	sw $t6, 0($t0)
	addi $t6, $0, 58
	sw $t6, 4($t0)
	lw $a0, 0($t0)		# x = 16
	lw $a1, 4($t0)		# y = 60
	la $t0, MY_COLOUR
	lw $a2, 8($t0)		# $a2 = color of ball (white)
	jal DRAW_BALL
	
	li $a0, 8		# y_coordinate of first brick layer = 8
	jal DRAW_BRICK_LAYERS_LEVEL_2
	
	# EPILOGUE
	lw $ra, 0($sp)		# retrieve stored value of $ra from stack
	addi $sp, $sp, 4	# move stack back down
	
	###Reset ball vector
	la $t0, BALL_VECTOR
	addi $t1, $0, 0
	sw $t1, 0($t0)
	addi $t1, $0, -1
	sw $t1, 4($t0)
	
	###Reset pause
    la $t0, PAUSE
    addi $t6, $0, 0
    sw $t6, 0($t0)

    ###Reset number of bricks
    #la $t0, NUM_OF_BRICKS
    #addi $t6, $0, 0
    #sw $t6, 0($t0)

    ###Reset score
    #la $t0, SCORE
    #addi $t6, $0, 0
    #sw $t6, 0($t0)

    ###Update Level score
    la $t0, LEVEL
    addi $t6, $0, 2
    sw $t6, 0($t0)
	
	j main_pause_loop			# pause the game
	
	
ERASE_SCORE:
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $s1, 0($sp)
	
	addi $sp, $sp, -4	#s0 stores color
	sw $a0, 0($sp)
	
	addi $sp, $sp, -4		#original display location	
	sw $a1, 0($sp)			
	
	jal GET_LOCATION_ADDRESS
    
    	addi $s1, $v0, 0
    
    	la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    	lw $s0, 4($s0)      	# colour is black
    	
    	sw $s0, 0($s1)
    	sw $s0, 4($s1)
    	sw $s0, 8($s1)
    	sw $s0, 12($s1)
    	sw $s0, 16($s1)
    	
    	sw $s0, 128($s1)
    	sw $s0, 132($s1)
    	sw $s0, 136($s1)
    	sw $s0, 140($s1)
    	sw $s0, 144($s1)
    	
    	sw $s0, 256($s1)
    	sw $s0, 260($s1)
    	sw $s0, 264($s1)
    	sw $s0, 268($s1)
    	sw $s0, 272($s1)
    	
    	sw $s0, 384($s1)
    	sw $s0, 388($s1)
    	sw $s0, 392($s1)
    	sw $s0, 396($s1)
    	sw $s0, 400($s1)
    	
    	sw $s0, 512($s1)
    	sw $s0, 516($s1)
    	sw $s0, 520($s1)
    	sw $s0, 524($s1)
    	sw $s0, 528($s1)
	
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	j draw_digit_body
	
ERASE_SCREEN:
	#PROLOGUE
	#store all previous values in the stack
	addi $sp, $sp, -4	#s0 stores color
	sw $s0, 0($sp)
	
	addi $sp, $sp, -4	#s1 stores the display
	sw $s1, 0($sp)
	
	addi $sp, $sp, -4	#stores horizontal wall unit count
	sw $s2, 0($sp)
	
	addi $sp, $sp, -4	#loop counter for horizontal walls
	sw $s3, 0($sp)
	
	addi $sp, $sp, -4	#the conditional for all loops
	sw $s4, 0($sp)
	
	addi $sp, $sp, -4	#s5 stores the vertical uwall nit count
	sw $s5, 0($sp)
	
	addi $sp, $sp, -4	#loop counter for vertical walls
	sw $s6, 0($sp)
	
	
	la $s0, MY_COLOUR    	# temp = &MY_COLOURS
    	lw $s0, 4($s0)      	# colour = black

   	# We also need to know where to write to the display
    	la $s1, ADDR_DSPL   	# temp = &ADDR_DSPL
    	lw $s1, 0($s1)   	# display = *temp

    	# Since the display is 256 pixels wide, and each unit is 8 pixels wide,
    	# then a line is 32 units wide
    
    	# Because the display is 512 pixels long, and each unit is 8 pixels long,
    	# then a wall is 64 units long
    	li $s2, 32		# Horizontal_UNIT_COUNT = 32
    	li $s5, 64		# Vertical_UNIT_COUNT = 64

    	# Now let's iterate 32 on t3, and 64 times on t6, drawing each unit in the line
    	li $s3, 0        	# i = 0
    	li $s6, 0
    
erase_row_loop:
    slt $s4, $s3, $s2           # i < UNIT_COUNT ?
    beq $s4, $0, confirm_screen_reset  # if not, then done

        sw $s0, 0($s1)        # Paint unit with colour
        addi $s1, $s1, 4        # Go to next unit

    addi $s3, $s3, 1            # i = i + 1
    b erase_row_loop
    
    confirm_screen_reset:
    li $s3, 0
    addi $s6, $s6, 1
    slt $s4, $s6, $s5
    beq $s4, $0, screen_reset_epi
    b erase_row_loop
    
    
    screen_reset_epi:
    lw $s6, 0($sp)
	addi $sp, $sp, 4
	
	lw $s5, 0($sp)
	addi $sp, $sp, 4
	
	lw $s4, 0($sp)
	addi $sp, $sp, 4
	
	lw $s3, 0($sp)
	addi $sp, $sp, 4
	
	lw $s2, 0($sp)
	addi $sp, $sp, 4
	
	lw $s1, 0($sp)
	addi $sp, $sp, 4
	
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	#jump back
	jr $ra
	
