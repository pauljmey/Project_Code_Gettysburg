breed [confederates confederate]
breed [unions union]
breed[devins devin]

patches-own [elevation road?]
confederates-own [health attack attack-range]
unions-own [health attack attack-range]
globals [confederate-engage-tick color-min color-max
  patch-data deployment-path max-elevation
  union-start buford-deploy-1 buford-deploy-2
  stored-deploy-index stored-deploy-paths union-start-pos
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

    ; Done reading in patch information.  Close the file.
    file-close
  ]
  [user-message "Road data file does not exist!"]

end

to initialize
  clear-patches
  ask patches[set road? false]
  set stored-deploy-index []
  set stored-deploy-paths []
  set buford-deploy-1 []
  set buford-deploy-2 []

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

  set union-start-pos -1
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

  let num-confederates 7600 / 5  ; The total number of Confederate agents you plan to create

  let max-xcor (1 *(max-pxcor / 2))  ; Maximum x-coordinate limit for the upper left quadrant
  let max-ycor (max-pycor / 2)  ; Maximum y-coordinate limit for the upper left quadrant

  create-confederates num-confederates [
    let random-off-x random-float  13  ; Generate a random x-coordinate within the limit
    let x-cor -49 + random-off-x
    let y-bnd (-1 * x-cor)
    let y-cor 49 - random-float y-bnd
    ;let random-y random-float 0  ; Generate a random y-coordinate within the limit
    setxy x-cor y-cor  ; Set the random x and y coordinates in the upper-left quadrant
    set color red
    set health 10
    set attack 2
    set attack-range 5
    face patch first item 7 deployment-path last item 7 deployment-path
  ]


  reset-ticks
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
      ;user-message word "len " length max-n-of 8 neighbors [elevation]
      let close-p neighbors
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

  let total-unions (2750 / 5)  ; The total number of Union agents you plan to create
  let center-x 0  ; Center x-coordinate
  let center-y (max-pycor / 4) - 10  ; Center y-coordinate, adjusted lower than Confederates
  let radius 2.5; Radius of the circular formation

  let start-above  list first union-start (last union-start + 3)
  ;user-message (word "start-above" start-above)
  let start-below list first union-start (last union-start - 3)
  let half-total 275
  let patch-limit 8  ; 8 agents per path, i.e. 40 over 65 square meter patch

  ;user-message "Calling get def 1st time"
  if not member? union-start-pos stored-deploy-index[
    user-message word "setting up deploy paths for index " union-start-pos
    let path-1-first? true
    get-defensive-line start-above half-total patch-limit path-1-first?

    set path-1-first? false
    get-defensive-line start-below half-total patch-limit path-1-first?

    let path-1 []
    let path-2 []
    foreach buford-deploy-1 [v -> set path-1 lput v path-1]
    foreach buford-deploy-2 [v -> set path-2 lput v path-2]

    set stored-deploy-index lput union-start-pos stored-deploy-index
    set stored-deploy-paths lput list path-1 path-2 stored-deploy-paths
  ]

  let cur-deploy-path-index position union-start-pos stored-deploy-index
  user-message word "getting deploy path at pos " cur-deploy-path-index
  deploy-to-path half-total patch-limit item 0 item cur-deploy-path-index stored-deploy-paths

  deploy-to-path half-total patch-limit item 1 item cur-deploy-path-index stored-deploy-paths

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
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1518
1319
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-50
49
-49
50
0
0
1
ticks
30.0

BUTTON
42
58
108
91
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
48
158
111
191
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
43
10
118
43
Initialize
initialize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
16
236
188
269
start-pos-choice
start-pos-choice
-1
20
11.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
