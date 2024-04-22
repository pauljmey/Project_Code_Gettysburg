breed [confederates confederate]
breed [unions union]
breed[devins devin]

patches-own [elevation road?]
confederates-own [health attack attack-range]
unions-own [health attack attack-range]
globals [confederate-engage-tick color-min color-max patch-data deployment-path max-elevation union-start buford-deploy-1 buford-deploy-2
]

to load-patch-data
;; Code from File Input Example and Grand Canyon

  ; We check to make sure the file exists first
  ;user-message "Trace 1"
  ifelse ( file-exists? "elev-by-rc.txt" )
  [
    ; We are saving the data into a list, so it only needs to be loaded once.
    set patch-data []
    let max-values []

    ; This opens the file, so we can use it.
    file-open "elev-by-rc.txt"

    ; Read in all the data in the file

    while [ not file-at-end? ]
    [
      ; file-read gives you variables.  In this case numbers.
      ; We store them in a double list (ex [[1 1 9.9999] [1 2 9.9999] ...
      ; Each iteration we append the next three-tuple to the current list

      set patch-data sentence patch-data (list (list file-read file-read file-read))

    ]

    ;if empty? patch-data [user-message "empty list"]

    set max-elevation 123.148

    let min-elevation 0
    set color-min 0
    set color-max 100


    ; Done reading in patch information.  Close the file.
    file-close
  ]
  [ user-message "There is no file by that name in current directory!" ]


  ifelse ( file-exists? "ChambersburgRoad-init-data.txt" )
  [
    ; We are saving the data into a list, so it only needs to be loaded once.
    ; This opens the file, so we can use it.
    file-open "ChambersburgRoad-init-data.txt"

    ; Read in all the data in the file
    set deployment-path []
    while [ not file-at-end? ]
    [
      ; file-read gives you variables.  In this case numbers.
      ; We store them in a double list (ex [[1 1 9.9999] [1 2 9.9999] ...
      ; Each iteration we append the next three-tuple to the current list
      ;let line list file-read file-read
      ;user-message "Trace 4"
      ;ifelse (first line = "lname") []
      ;show file-read
      set deployment-path sentence deployment-path (list (list file-read file-read))
    ]

    ;if empty? patch-data [user-message "empty list"]


    let min-elevation 0
    ;set color-min min-elevation - ((color-max - min-elevation) / 10)
    set color-min 0

    ; Done reading in patch information.  Close the filest.
    file-close
  ]
  [user-message "Road data file does not exist!"]

end

to initialize
  clear-patches
  ask patches[set road? false]
  load-patch-data
  show-patch-data
  ;ask patches[ set pcolor round (135 * elevation / color-max) ];[set pcolor round (135 * elevation / color-max)]
    ;ifelse pxcor mod 10 = 0 and pycor mod 10 = 0
    ;   [set pcolor red]
   ask patches [ set pcolor scale-color brown elevation 0 100]

  ask patches[ if road?[set pcolor blue]]
end

to show-patch-data
  ifelse ( is-list? patch-data )
    [foreach patch-data [ three-tuple -> ask patch first three-tuple item 1 three-tuple [ set elevation last three-tuple ] ] ]
    [ user-message "You need to load in patch data first!" ]

  foreach deployment-path [ two-tuple -> ask patch first two-tuple last two-tuple [set road? true]]
  display
end


to setup
  ;clear-all
  ;user-message deployment-path
  clear-turtles

  let union-start-pos -1
  ifelse start-pos-choice = -1 [
    set union-start-pos random length deployment-path
  ]
  [
    set union-start-pos start-pos-choice
  ]

  set union-start item union-start-pos deployment-path
  ;user-message union-start
  foreach deployment-path [pos -> ask patch first pos last pos  [set pcolor blue]]
  ask patch first union-start last union-start [set pcolor orange]

  setup-confederates
  setup-unions
  set confederate-engage-tick 0
  reset-ticks  ; Resets the tick counter for the simulation
end

to setup-confederates
  let num-confederates 760  ; The total number of Confederate agents you plan to create
  let num-lines 2  ; Number of lines to create

  let max-xcor (max-pxcor / 6)  ; Maximum x-coordinate limit for the upper left quadrant
  let max-ycor (max-pycor / 5)  ; Maximum y-coordinate limit for the upper left quadrant

  let start-x1 -45
  let start-y1 25
  let end-x1 -40
  let end-y1 30

  let start-x2 -25
  let start-y2 45
  let end-x2 -20
  let end-y2 50

  let agents-per-line (num-confederates / num-lines)  ; Number of agents per line

  create-confederates num-confederates [
    set color red
    set health 10
    set attack 2
    set attack-range 5
    let line-index (who mod num-lines)  ; Determine which line to place the agent on
    let start-x ifelse-value (line-index = 0) [start-x1] [start-x2]
    let start-y ifelse-value (line-index = 0) [start-y1] [start-y2]
    let end-x ifelse-value (line-index = 0) [end-x1] [end-x2]
    let end-y ifelse-value (line-index = 0) [end-y1] [end-y2]
    let t ((who - (line-index * agents-per-line)) / agents-per-line)  ; Interpolation parameter within each line
    let x-pos (start-x + t * (end-x - start-x))
    let y-pos (start-y + t * (end-y - start-y))
    setxy x-pos y-pos
  ]
end

;to get-highest-neighbor[cur-p]
;  let max 0
;  let max-p cur-p
;  ;let next-p min-n-of 1 neighbors
;
; ; foreach neighors[cur-n -> if turtles-here ]
;  foreach neighbors with [turtles-here = 0] []
;end

to get-defensive-line[start-pt num-agents patch-limit path-1-first?]

  let cur-path-pos  start-pt
  let cnt num-agents
  let rem cnt
  ;let list-pos = sta

  while [rem > 0]
  [

    ;ask patch first cur-p last cur-p [let ]
    ;user-message (word "cur path pos" cur-path-pos)
    ask patch first cur-path-pos last cur-path-pos [
      let close-p max-n-of 8 neighbors [elevation]
      ;user-message max-n-of 8 neighbors [elevation] user-message (word "highest elev:" close-p)
      ;let p-list [self] of close-p
      let elevs sort-by [[p1 p2] -> [elevation] of p1 > [elevation] of p2] close-p

      let test-out []
      ; user-message (word "for elev " [elevation] of ptch " " [pxcor] of ptch " " [pycor] of ptch )
      let found? false
      let elev-pos 0
      while[not found?][
        let high-patch item elev-pos elevs
        let high-coords list [pxcor] of high-patch [pycor] of high-patch
        ifelse path-1-first?
        [
          ifelse not member? high-coords buford-deploy-1 and not member? high-coords buford-deploy-2
          [
            set buford-deploy-1 sentence buford-deploy-1 (list (list first high-coords last high-coords))
            set found? true
            set cur-path-pos high-coords
          ]
          [
            set elev-pos elev-pos + 1
          ]
        ]
        [
          ifelse not member? high-coords buford-deploy-1 and not member? high-coords buford-deploy-2
          [
            set buford-deploy-2 sentence buford-deploy-2 (list (list first high-coords last high-coords))
            set found? true
            set cur-path-pos high-coords
          ]
          [
            set elev-pos elev-pos + 1
          ]

        ]

      ]
    ]
    set rem (rem - patch-limit)
  ]
end



to deploy-to-path[num-agents patch-limit path-list]

  let cur-path-pos 0
  let rem  num-agents
  ;user-message word "deploy path list " path-list
  while [rem > 0]
  [
    let cur-troop-pos item cur-path-pos path-list

;    let random-x random-float max-xcor  ; Generate a random x-coordinate within the limit
;    let random-y random-float max-ycor  ; Generate a random y-coordinate within the limit
;    setxy (- random-x) random-y  ; Set the random x and y coordinates in the upper-left quadrant
;    set color red
;    set health 10
;    set attack 2
;    set attack-range 5

    ;user-message word "cur u pos:" cur-troop-pos
    create-unions patch-limit [

      setxy first cur-troop-pos last cur-troop-pos; Set the position of the Union agent

      set color blue
      set health 10
      set attack 3
      set attack-range 3
    ]
    set cur-path-pos cur-path-pos + 1
    set rem rem - patch-limit
  ]
end

to setup-unions

  let total-unions (2750 / 10)  ; The total number of Union agents you plan to create
  let center-x 0  ; Center x-coordinate
  let center-y (max-pycor / 4) - 10  ; Center y-coordinate, adjusted lower than Confederates
  let radius 2.5; Radius of the circular formation

;  create-unions total-unions [
;    let angle (who * (360 / total-unions))  ; Calculate angle for each Union agent
;    let x-position center-x + (radius * cos angle)  ; Calculate x-coordinate for each Union agent
;    let y-position center-y + (radius * sin angle)  ; Calculate y-coordinate for each Union agent
;    setxy x-position y-position  ; Set the position of the Union agent
;
;    set color blue
;    set health 10
;    set attack 3
;    set attack-range 3
;  ]

  let start-above  list first union-start (last union-start + 3)
  ;user-message (word "start-above" start-above)
  let start-below list first union-start (last union-start - 3)
  let half-total 275
  let patch-limit 8  ; 8 agents per path, i.e. 40 over 65 square meter patch

  set buford-deploy-1 []
  set buford-deploy-2 []

  ;user-message "Calling get def 1st time"
  let path-1-first? true
  get-defensive-line start-above half-total patch-limit path-1-first?
  ;user-message word "bu dep 1 after get-defensive-line " buford-deploy-1
  deploy-to-path half-total patch-limit buford-deploy-1
  ;user-message word "bu path list 1" buford-deploy-1
  ;user-message word "bu path list 2" buford-deploy-2

  ;user-message "Calling get def 2nd time"
  set path-1-first? false
  get-defensive-line start-below half-total patch-limit path-1-first?
  deploy-to-path half-total patch-limit buford-deploy-2
  ;user-message word "bu path list 1" buford-deploy-1
  ;user-message word "bu path list 2" buford-deploy-2




end

to go
  ; Allow Confederates to engage only every 6 ticks
  if (confederate-engage-tick >= 2) [
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

to move
  right random 360
  forward 1
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
    forward 0.5 + (random-float 0.2)  ; Adjusted for noticeable variability
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
