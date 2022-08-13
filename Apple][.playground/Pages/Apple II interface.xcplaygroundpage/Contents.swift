import PlaygroundSupport

/**
 Hello, Welcome to your Apple][. Turn it on by pressing the power key in the bottom left corner of the keyboard. Physical keyboards are also supported: turn on using control P and use backspace to move the cursor left. Due to budget cuts and an aggressive development schedule, only a subset of the Integer Basic has been implemented. The available words are:
 PRINT: print a string or int to the screen
 GR: make the graphics layer visible and clear the screen
 TEXT: make the graphics layer hidden
 INPUT: get user input and store in int variable
 COLOR= : set the color to new value (0: clear, 1: white, 2: red, 3: green, 4: blue)
 PLOT: plot a point on the graphics layer
 IF .statements1. THEN .statements2. {: .statements3.} : exec statements2 or statements3 depending on statements1 evaluating to nonzero or zero
 RND(n) : random int 0 ..< n
 ABS(n) : absolute value of n
 NEW : clear current stored program
 LOAD : load demo program
 LIST : print out stored program
 RUN : execute stored program
 END: stop program execution
 GOTO line number : continue execution from line number
 operators: +,*,-,/,>,MOD,=, and ^
 If you are familiar with Integer Basic, feel free to play around with the interpreter. However, not all functionality may be identical to expected functionality and there may be some unexpected errors. If you do experiment with the interpreter, please type NEW before loading the demo.
 
 For your convenience in evaluating this test article, a demo program has been hardcoded into the machine's software.
 To start this demo, please type in to the computer LOAD (followed by a return of course, but you hardly need to be told that from now on, so we wont) and then type RUN and the following code will begin to execute:
 10 GR
 20 H = RND(200)
 30 TGT = RND(350)+20
 40 G = -10
 99 COLOR = 3
 100 PLOT 0,(390-H)/10
 109 COLOR = 2
 110 PLOT 39,(390-TGT)/10
 111 PLOT 39,(((390-TGT)/10)+1)
 112 PLOT 39,(((390-TGT)/10)+2)
 113 PLOT 39,(((390-TGT)/10)-1)
 114 PLOT 39,(((390-TGT)/10)-2)
 200 PRINT "Enter x velocity"
 210 INPUT XVEL
 250 PRINT "Enter y velocity"
 260 INPUT YVEL
 499 COLOR = 4
 500 X = 30
 510 T = (100*X/XVEL)
 520 Y = (H+T*YVEL/100+G*T*T/10000)
 529 IF (((Y/10)>39) + (0>Y)) THEN GOTO 540
 530 PLOT X/10, (390-Y)/10
 540 X = (X + 30)
 550 IF 391 > X THEN GOTO 510
 600 IF ABS(Y-TGT)>20 THEN GOTO 700 : GOTO 800
 700 PRINT "YOU LOSE"
 710 GOTO 900
 800 PRINT "YOU WIN"
 810 GOTO 900
 900 PRINT "DO YOU WANT TO PLAY AGAIN?(Y:1, N:0)"
 910 INPUT AGAIN
 920 IF AGAIN THEN GOTO 10
 1000 PRINT "THANKS FOR PLAYING"
 1005 TEXT
 1010 END
 
 When prompted for input, input a number folowed by a return.
 This program is a simple game where you input the initial velocity of a projectile and try to hit the target on the right side of the screen.
 hint: xvel 100 and yvel 40 hits approximately level with the initial height
 Please Enjoy!
 */

let appleII = AppleII()
PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = appleII
