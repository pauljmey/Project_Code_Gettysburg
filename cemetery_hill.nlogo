breed [confederates confederate]
breed [unions union]

confederates-own [health attack attack-range]
unions-own [health attack attack-range]
globals [confederate-engage-tick]


to setup
  clear-all
  setup-confederates
  setup-unions
  set confederate-engage-tick 0
  reset-ticks  ; Resets the tick counter for the simulation
end

to setup-confederates
  let num-confederates 30  ; The total number of Confederate agents you plan to create
  let max-xcor (1 *(max-pxcor / 2))  ; Maximum x-coordinate limit for the upper left quadrant
  let max-ycor (max-pycor / 2)  ; Maximum y-coordinate limit for the upper left quadrant
  
  create-confederates num-confederates [
    let random-x random-float max-xcor  ; Generate a random x-coordinate within the limit
    let random-y random-float max-ycor  ; Generate a random y-coordinate within the limit
    setxy (- random-x) random-y  ; Set the random x and y coordinates in the upper-left quadrant
    set color red
    set health 10
    set attack 2
    set attack-range 5
  ]
end




to setup-unions
  
  let total-unions 20  ; The total number of Union agents you plan to create
  let center-x 0  ; Center x-coordinate
  let center-y (max-pycor / 4) - 10  ; Center y-coordinate, adjusted lower than Confederates
  let radius 2.5; Radius of the circular formation
  
  create-unions total-unions [
    let angle (who * (360 / total-unions))  ; Calculate angle for each Union agent
    let x-position center-x + (radius * cos angle)  ; Calculate x-coordinate for each Union agent
    let y-position center-y + (radius * sin angle)  ; Calculate y-coordinate for each Union agent
    setxy x-position y-position  ; Set the position of the Union agent
    
    set color blue
    set health 10
    set attack 3
    set attack-range 3
  ]
end





to go
  ; Allow Confederates to engage only every 6 ticks
  if (confederate-engage-tick >= 6) [
    ask confederates [engage unions]
    set confederate-engage-tick 0
  ]
  
  ; Union forces engage every tick
  ask unions [
    move-to-defend
    engage confederates
  ]

  ; Increment Confederate engage tick counter and global tick counter
  set confederate-engage-tick confederate-engage-tick + 1
  ask confederates [move-towards-union]
  tick
end


to move-towards-union
  ; Ensure there are Union agents before proceeding
  if count unions > 0 [
    ; Central y-coordinate as a reference point
    let center-y (min-pycor / 2)

    ; Calculate the average position (centroid) of Union forces
    let union-center-x mean [xcor] of unions
    let union-center-y mean [ycor] of unions

    ; Generate a random target point across the width and below the current position
    let random-target-x (min-pxcor + random (2 * max-pxcor))
    let random-target-y center-y + random-float ((min [ycor] of confederates) - center-y)

    ; Ensure the target doesn't go too low or off-screen
    if random-target-y < center-y [set random-target-y center-y]

    ; Calculate a weighted target point, partially oriented towards Union centroid
    let weight 0.7  ; Adjust the weight for more or less orientation towards Union
    let target-x (weight * union-center-x + (1 - weight) * random-target-x)
    let target-y (weight * union-center-y + (1 - weight) * random-target-y)

    ; Adjust heading towards the weighted target position
    set heading towardsxy target-x target-y

    ; Move forward with randomness in speed to simulate terrain and uncertainty
    forward 0.5 + (random-float 0.5)  ; Adjusted for noticeable variability
  ]
end



to move-to-defend
  ; Define the center of the circular defense formation
  let center-x 0  ; Center x-coordinate
  let center-y (max-pycor / 4) - 10  ; Center y-coordinate, adjusted lower than Confederates
  
  ; Each Union agent will move to a position on a circle around this center
  let my-index who - min [who] of unions  ; Index to order Union agents
  let total-unions count unions
  let angle-increment 360 / total-unions  ; Determine angle step based on total agents
  
  ; Calculate the target position for this agent on the circle
  let my-angle (angle-increment * my-index) * pi / 180  ; Convert degrees to radians for trig functions
  let radius 10  ; Radius of the circle
  
  let target-x center-x + (radius * cos my-angle)
  let target-y center-y + (radius * sin my-angle)
  
  ; Calculate the angle towards the confederates
  let towards-confederates atan (ycor - [ycor] of min-one-of confederates [distance myself]) (xcor - [xcor] of min-one-of confederates [distance myself])
  
  ; Move towards the target position with reduced distance for defensive purposes
  let target-patch patch target-x target-y
  if target-patch != nobody [
    ; Calculate the angle towards the weighted direction
    let weighted-angle atan (0.9 * (target-y - ycor) + 0.1 * sin towards-confederates) (0.9 * (target-x - xcor) + 0.1 * cos towards-confederates)
    ; Adjust heading towards the weighted direction
    if weighted-angle != heading [
      ifelse (weighted-angle - heading) > 180 [
        right (360 - (weighted-angle - heading))
      ] [
        left (weighted-angle - heading)
      ]
    ]
    
    let distance-to-target distancexy target-x target-y
    if distance-to-target > 0.5 [  ; Adjusted distance threshold for defensive movements
      forward min (list 0.1 distance-to-target)  ; Move with reduced distance
    ]
  ]
end





to engage [enemy-breed]
  let actor self  ; Store the current agent as 'actor' for clarity and to avoid misuse of 'myself'
  let target min-one-of enemy-breed [distance actor]
  if target != nobody and distance target < [attack-range] of actor [
    ask actor [  ; Ensure 'ask' is correctly scoped to use 'actor' not 'myself'
      fight target
    ]
  ]
end

to fight [target]
  ; Capture the attack value before the 'ask' to avoid 'myself' confusion
  let attack-value [attack] of myself
  ask target [
    ; Using the previously captured attack value
    if random 100 < 75 [  ; Assuming a 75% chance to hit
      set health health - attack-value
      if health <= 0 [
        die
      ]
    ]
  ]
end
