# Brick_Breaker

This game is the final project in Reconfigurable Computing (ECE 5730) at Utah State University. 

## Authors
- David Rowbotham ([Drowbo990](https://github.com/DRowbo990))
- Eric Reiss ([ereiss123](https://github.com/ereiss123))
## Requirements
1. The digital design must be done in VHDL.
2. The game image shall be 640 pixels wide by 480 pixels tall.
3. Use the two push buttons on the DE10-Lite board to control game play. One button resets the
game, the other drops a new ball. The user may request 5 new balls, after which the game is
over and reset must be pressed to continue.
4. Upon reset, the upper half of the screen (240 lines) shall be filled with red bricks separated by
white mortar. Brick dimensions shall be 15 pixels wide by 7 pixels high. 1-pixel-wide strips of
mortar completely separate every brick from each of its neighbors. Neighboring rows of bricks
shall be offset by half a brick, thus every other row shall be aligned vertically.
5. Upon reset, a brown paddle will appear at the bottom of the display. The paddle shall be 40
pixels wide by 5 pixels tall.
6. Screen portions not occupied by bricks, mortar, ball, or paddle shall be black.
7. When the “drop ball” button is pressed (and there are balls remaining), a ball will drop straight
down from a randomly-chosen point along the horizontal center of the screen. The ball shall be
a white square or octagon with dimensions 10 pixels by 10 pixels. Pick an appropriate rate of
movement for the ball.
8. The user can move the paddle from side-to-side along the bottom of the screen. The paddle
movement can be controlled by either a potentiometer interfaced to the FPGA’s ADC (required
for ECE 5730), or via the on-board accelerometer (required for ECE 6730, extra credit for 5730).
Potentiometers (sometimes called rheostats) are available for checkout or purchase from the
ECE store.
9. If the ball misses the paddle and falls out the bottom of the screen, the ball “dies” and a new
ball must be requested. The ball bounces off the paddle, the sides of the screen, and the top of
the screen. Come up with a scheme for changing the ball direction as it bounces off of these
surfaces.
10. If the ball “hits” one or more bricks, the ball bounces off AND causes those bricks to disappear
from the wall. Entire bricks must disappear (i.e. no partial bricks shall remain on the screen).
Only bricks that have been hit by the ball disappear. The object of the game is knock all of the
bricks out of the wall before all 5 balls have been lost.
11. Produce 4 unique sounds using the FPGA and an external speaker. One when the ball hits the
paddle, one when the ball hits the top or side of the screen, one when the ball breaks a brick,
and one when the ball dies.

## Usage
To run this game as is, you will need a Terasic DE10-Lite development board, a potentiometer, hookup wires, a VGA-capable monitor, and the Quartus development software. The project was developped using Quartus Lite 18.1 on Windows, which is available for free from the Quartus website. 
- Clone this repository
- Install Quartus Lite
- Install drivers as necessary for your machine
- Open Brick_Breaker.qpf
- Compile the project
- Program DE10-Lite board
- Connect VGA monitor to onboard VGA port
- Connect potientometer to pins **Placeholder**

