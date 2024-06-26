;breed [confederates confederate]
;breed [unions union]
;breed[devins devin]

breed [infantry squad]
infantry-own [health attack attack-range unit-speed mode goals army unit target-id target-dist
  unit-id deploy-path-pos
]

patches-own [elevation road? road-marker ridge? cover orig-color]
;confederates-own [health attack attack-range unit-speed]
;unions-own [health attack attack-range unit-speed]
globals [confederate-engage-tick color-min color-max
  patch-data deployment-path max-elevation
  union-start buford-deploy-1 ;buford-deploy-2
  stored-deploy-paths union-start-pos
  wave-1-confederates
  union-orientation phases phase-index
  confed-turn cemetary-hill total-unions-Buford personnel-per-turtle
  ridge-toggle? Gettysburg-town-center town town-toggle?
  south-health Chambersburg-road cemetary-hill-set
  max-health
  infantry-default-speed column-limit
  debug-mode? max-right message-id

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

to show-ridges

  ifelse not ridge-toggle?
  [
    ask patches [
      if ridge?
      [
        set orig-color pcolor
        set pcolor pink
      ]
    ]
  ]
  [
      ask patches [
      if ridge?
      [
        set pcolor orig-color
      ]
    ]
  ]
  set ridge-toggle? not ridge-toggle?
end

to show-town

  ifelse not town-toggle?
  [
    ask town [
        set orig-color pcolor
        set pcolor green
    ]
  ]
  [
      ask town [
        set pcolor orig-color
    ]
  ]
  set town-toggle? not town-toggle?
end

to toggle-debug

  set debug-mode? not debug-mode?

end



to initialize
  clear-patches
  clear-turtles ; if any, with settings set at good values, initialize should only need to be called once
  ask patches[set road? false]
  set stored-deploy-paths []
  set buford-deploy-1 []
  set personnel-per-turtle 5
  let historical-Buford 2750
  set ridge-elev-threshold .925
  set ridge-toggle? false
  set town-toggle? false
  set south-health 0
  set max-health 10
  set infantry-default-speed .5
  set column-limit 32
  set debug-mode? false
  set max-right 0

  ask patches [set cover 1]

  ask patches [ set ridge? false ]

  set total-unions-Buford historical-Buford / personnel-per-turtle

  set phases (list "SouthEnter1" "NorthEnter1")

  load-patch-data
  let buford-historical-deploy 6

  set union-orientation get-angle item 0 deployment-path item buford-historical-deploy deployment-path
  ;user-message word "dep or:" union-orientation
  show-patch-data
  ;ask patches[ set pcolor round (135 * elevation / color-max) ];[set pcolor round (135 * elevation / color-max)]
    ;ifelse pxcor mod 10 = 0 and pycor mod 10 = 0
    ;   [set pcolor red]
   ask patches [ set pcolor scale-color brown elevation 0 100]

  ask patches[ ifelse road?[set pcolor blue][set road-marker -1]]
  ;user-message word "item 7 " item 7 deployment-path
  set confed-turn item 7 deployment-path
  ask patch first confed-turn last confed-turn
  [
    foreach range 69 [n -> ask patch-at-heading-and-distance union-orientation n [
          set pcolor yellow
          set road? true
          set road-marker n
          set cover 0
      ]
    ]
  ]

  set Chambersburg-road patches with [road? = true]
  user-message word "Road init: " Chambersburg-road
  set Gettysburg-town-center list ((first confed-turn) + 7) last confed-turn
  let center-patch patch first Gettysburg-town-center last Gettysburg-town-center
  set town patches with [distance center-patch <= 8]
  ask town [ set cover 8]
  let last-pos length deployment-path - 1
  set cemetary-hill item last-pos deployment-path
  set cemetary-hill-set patches with [distance patch first cemetary-hill last cemetary-hill < 4]
  ask cemetary-hill-set [set cover 10]


end

to show-patch-data
  ifelse ( is-list? patch-data )
    [foreach patch-data [ three-tuple -> ask patch first three-tuple item 1 three-tuple [ set elevation last three-tuple ] ] ]
    [ user-message "You need to load in patch data first!" ]

  foreach deployment-path [ two-tuple -> ask patch first two-tuple last two-tuple [set road? true]]

  let deploy-index 0
  let half-total round (total-unions-Buford / 2)
  let patch-limit 8  ; 8 agents per path, i.e. 40 over 65 square meter patch

  let quit? false
  while[not quit?] [
    ;user-message word "setting up deploy paths for index " union-start-pos
    let cur-start item deploy-index deployment-path
    let start-above list first cur-start (last cur-start + 2)
    ;user-message (word "start-above" start-above)
    let start-below list first cur-start (last cur-start - 2)

    ;user-message (word "start-above" start-above)
    set buford-deploy-1 []
    get-defensive-line start-above half-total patch-limit
    ;user-message word "after get-def 1 " buford-deploy-1
    get-defensive-line start-below half-total patch-limit

    let path-1 []
    foreach buford-deploy-1 [v -> set path-1 lput v path-1]

    set stored-deploy-paths lput path-1 stored-deploy-paths
    ;user-message word "length of stored-deploy-paths: " length stored-deploy-paths
    ;user-message word "last deployment path: " last stored-deploy-paths
    set deploy-index deploy-index + 1
    if deploy-index = length deployment-path [set quit? true]
  ]

  ;user-message word "deployment path 0 " item 0 stored-deploy-paths
  ;5user-message word "deployment path 1 " item 1 stored-deploy-paths
  ;foreach stored-deploy-paths [nd -> user-message word "cur path len: " length nd]

  let pairs-2 [[[1 -1] [1 1]] [[1 0]  [0 1]] [[1 0]  [0 -1]] [[0 1][0 -1]] [[1 -1][-1 1]]]
  ask patches [

    if find-ridge  [
      set ridge? true
      set cover 8
      ;set pcolor pink
    ]


  ]
  display
end
to trace[level msg]
  if debug-mode?
  [
    if debug-set = 1 or debug-set = level [
      let continue user-yes-or-no? (word msg " " "Continue debug?")
        if not continue [
          set debug-mode? false
        ]
    ]
  ]
end
to-report find-ridge
  let pairs-1 [
    [  [[1 1] [1 0] [1 -1]] [[-1 1] [-1 0] [-1 -1]] ] ; front row vs back
    [  [[1 -1] [0 -1] [-1 -1]]  [[1 1] [0 1] [-1 -1]] ] ; left row vs right
    ;[  [[1 1] [1 0] [0 1]] [[-1 -1] [-1 0] [0 -1]] ] ; split along diagonal
    ;[  [[1 -1] [1 0] [0 -1]] [[-1 1] [-1 0] [0 1]] ] ; split along the other diagonal
  ]

;    if pxcor = -12 and pycor = 27
;    [
;     set debug? true
;    ]
    let cur-row 0
    while [cur-row < length pairs-1][
      let row-pair item cur-row pairs-1
      let my-elev elevation
      let s1 patches at-points first row-pair
      let elev1 s1 with [elevation < ridge-elev-threshold * my-elev]
      trace 2 word "s1 = " s1
      if debug-set = 1 or debug-set = 2 [user-message word "elev1 = " elev1]
      if any? elev1
      [
        let s2 patches at-points last row-pair
        let elev2 s2 with [elevation < my-elev]
        if any? elev2
        [
          report true
        ]
      ]
      set cur-row cur-row + 1
   ]

  report false
end

to setup
  ;clear-all
  ;user-message deployment-path
  clear-turtles
  clear-all-plots
  ;set converge? false

  let center-patch patch first Gettysburg-town-center last Gettysburg-town-center
  set town patches with [distance center-patch <= 10]

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

  ;setup-confederates-2
  setup-unions
  set confederate-engage-tick 0
  reset-ticks  ; Resets the tick counter for the simulation
end

to add-confederates-phase-1
  let num-confederates (7600 / 5)  ; The total number of Confederate agents you plan to create
  let num-lines 2  ; Number of lines to create

  let max-xcor (max-pxcor / 6)  ; Maximum x-coordinate limit for the upper left quadrant
  let max-ycor (max-pycor / 5)  ; Maximum y-coordinate limit for the upper left quadrant

  let start-x1 -50
  let start-y1 37
  let end-x1 -40
  let end-y1 30

  let start-x2 -25
  let start-y2 45
  let end-x2 -20
  let end-y2 50

  let agents-per-line (num-confederates / num-lines)  ; Number of agents per line

  let on-road round(num-confederates / 2)
  let on-rr on-road
  let top-of-road list -50 37
  let top-of-rr list -50 42
  let goal-1 item 7 deployment-path
  let rem  on-road


  let cur-count count turtles with [xcor = first top-of-road and last top-of-road = ycor]
  ;user-message word "at top of road " cur-count
  let total count infantry with [army = "South" and unit = "RoadWave1"]

  if total < on-road and cur-count < column-limit
    [
      let cur-to-make column-limit - cur-count
      create-infantry  cur-to-make [
        set color red
        set army "South"
        set unit "RoadWave1"
        set health max-health
        set attack 2
        set attack-range 5
        set unit-speed infantry-default-speed
        set mode "M"
        set deploy-path-pos -1

        setxy first top-of-road last top-of-road
      ]
  ]

  if total < on-road and cur-count < column-limit
    [
      let cur-to-make column-limit - cur-count
      create-infantry  cur-to-make [
        set color red
        set army "South"
        set unit "RRWave1"
        set health max-health
        set attack 2
        set attack-range 5
        set unit-speed infantry-default-speed
        set mode "M"
        set deploy-path-pos -1

        setxy first top-of-rr last top-of-rr
      ]
  ]


end

to-report in-bounds [cur aleft aright]
  if cur < 0 [user-message "cur < 0 "]

  let left-okay? false
  if aleft < 0
  [
    set cur cur - 360
  ]

  set left-okay? true
  if aleft = 270 [
    if cur <= 360 and cur > aleft [report true]
    if cur >= 0 and cur <= aright [report true]
  ]


  if aright = 270 [
    if cur < 270 and cur >= aleft [report true]
  ]

   let msg (word "left > cur < right " aleft ": " cur ": " aright)
   ;user-message msg

  report false
end

to-report in-line-of-sight[possible-target]  ;; walker procedure
  let dist 1
  let a1 0
  ;let c color
  let last-patch patch-here
  ;; iterate through all the patches
  ;; starting at the patch directly ahead
  ;; going through MAXIMUM-VISIBILITY

  ;user-message (word possible-target " x:" [xcor] of possible-target " y:" [ycor] of possible-target)
  face possible-target
  while [dist <= 10] [
    let p patch-ahead dist
    ;; if we are looking diagonally across
    ;; a patch it is possible we'll get the
    ;; same patch for distance x and x + 1
    ;; but we don't need to check again.
    if p != last-patch [
      ;; find the angle between the turtle's position
      ;; and the top of the patch.
      let a2 atan dist (elevation - [elevation] of p)
      ;; if that angle is less than the angle toward the
      ;; last visible patch there is no direct line from the turtle
      ;; to the patch in question that is not obstructed by another
      ;; patch.
      ifelse a1 < a2
      [
        ;user-message get-print-string (list "targ coords" [xcor] of possible-target [ycor] of possible-target) 3
        ;user-message get-print-string (list "visible patch coords " [pxcor] of p  [pycor] of p) 3
        if round [xcor] of possible-target = [pxcor] of p
           and round [ycor] of possible-target = [pycor] of p
        [ report true]
      ]
      [
        set a1 a2
      ]
      set last-patch p
    ]
    set dist dist + 1
  ]
  report false
end


;to setup-confederates
;
;  let num-confederates 7600 / 5  ; The total number of Confederate agents you plan to create
;  set wave-1-confederates num-confederates
;  let max-xcor (1 *(max-pxcor / 2))  ; Maximum x-coordinate limit for the upper left quadrant
;  let max-ycor (max-pycor / 2)  ; Maximum y-coordinate limit for the upper left quadrant
;
;  create-confederates num-confederates [
;    let random-off-x random-float  13  ; Generate a random x-coordinate within the limit
;    let x-cor -49 + random-off-x
;    let y-bnd (-1 * x-cor)
;    let y-cor 49 - random-float y-bnd
;    ;let random-y random-float 0  ; Generate a random y-coordinate within the limit
;    setxy x-cor y-cor  ; Set the random x and y coordinates in the upper-left quadrant
;    set color red
;    set health 10
;    set attack 2
;    set attack-range 5
;    set unit-speed .5
;    face patch first item 7 deployment-path last item 7 deployment-path
;  ]
;
;
;  reset-ticks
;end

;to get-highest-neighbor[cur-p]
;  let max 0
;  let max-p cur-p
;  ;let next-p min-n-of 1 neighbors
;
; ; foreach neighors[cur-n -> if turtles-here ]
;  foreach neighbors with [turtles-here = 0] []
;end

to-report get-angle[coord1 coord2] ; angle measure clockwise from north = 0
  let xrun  first coord1 - first coord2
  let yrise  last coord1 - last coord2

  report atan xrun yrise
end

to-report convert-to-geometric[a]
  report (90 - a) mod 360
end

to-report get-geometric-angle[coord1 coord2] ; geometric angle, where angles measured from horizontal x-axis
  let xrun  first coord1 - first coord2
  let yrise  last coord1 - last coord2

  report convert-slope-to-geometric-angle xrun yrise
end

to-report convert-slope-to-geometric-angle[x y]
  report convert-to-geometric atan x y
end

to get-defensive-line[start-pt num-agents patch-limit]

  let cur-path-pos  start-pt
  let cnt num-agents
  let rem cnt
  let north? true
  if length buford-deploy-1 > 0 [set north? false]

  let main-dir 0
  let a-left 0
  let a-right 0
  ifelse north?[
    set main-dir union-orientation - 270
    set a-left 270
    set a-right 90
  ]
  [
    set main-dir union-orientation - 90
    set a-left 90
    set a-right 270
  ]

  while [rem > 0]
  [
    let cur-patch patch first cur-path-pos last cur-path-pos
    ask cur-patch [
      ;user-message word "len " length max-n-of 8 neighbors [elevation]
      let close-p neighbors
      ;user-message max-n-of 8 neighbors [elevation] user-message (word "highest elev:" close-p)
      ;let p-list [self] of close-p
      let elevs sort-by [[p1 p2] -> [elevation] of p1 > [elevation] of p2] close-p

      let test-out []
      ; user-message (word "for elev " [elevation] of ptch " " [pxcor] of ptch " " [pycor] of ptch )
      let found? false
      let elev-pos 0
      let a-cur -1
      while[not found? and elev-pos < length elevs]
      [
        let high-patch item elev-pos elevs
        let high-coords list [pxcor] of high-patch [pycor] of high-patch
        set a-cur get-angle high-coords list pxcor pycor

        ifelse in-bounds a-cur a-left a-right
        [
          if not member? high-coords buford-deploy-1
          [
            set buford-deploy-1 sentence buford-deploy-1 (list (list first high-coords last high-coords))
            set found? true
            set cur-path-pos high-coords
          ]
        ]
        [

        ]
        if not found?
        [
            set elev-pos elev-pos + 1
        ]
      ]

      if not found?[
        user-message (word "didn't find it for cur-patch: " cur-patch " start-pt: " start-pt)
        let high-coords list [pxcor] of cur-patch [pycor] of cur-patch
        while [not member? high-coords buford-deploy-1][
            set high-coords list (first high-coords - 1) (last high-coords - 1)
        ]
        set buford-deploy-1 sentence buford-deploy-1 (list (list first high-coords last high-coords))

      ]

    ]
    set rem (rem - patch-limit)
  ]
end



to deploy-to-path[num-agents patch-limit path-list]
  let cur-path-pos 0
  let rem  num-agents
  ;user-message word "deploy path list " path-list
  ;user-message word "path-list " path-list
  while [rem > 0]
  [
    let cur-troop-pos item cur-path-pos path-list

    create-infantry patch-limit [

      setxy first cur-troop-pos last cur-troop-pos; Set the position of the Union agent

      set color blue
      set health max-health
      set attack 3
      set attack-range 5
      set unit-speed .5
      set army "North"
      set unit "Buford"
      set mode "D"
      set goals []
      set target-id -1
      set target-dist 0
      set unit-id -1
      set message-id -1
      set deploy-path-pos cur-path-pos
    ]

    set cur-path-pos cur-path-pos + 1
    set rem rem - patch-limit
  ]

  let cur-unit-id 1
  foreach range cur-path-pos [
    pn ->
    ;let n-on-pos count infantry with [deploy-path-pos = np]
    foreach sort infantry with [deploy-path-pos = pn]
    [
      cur-agent ->
      ask cur-agent[
        set unit-id cur-unit-id
      ]
      set cur-unit-id cur-unit-id + 1

    ]
  ]

end

to setup-unions

  let center-x 0  ; Center x-coordinate
  let center-y (max-pycor / 4) - 10  ; Center y-coordinate, adjusted lower than Confederates
  let radius 2.5; Radius of the circular formation
  let patch-limit 8 ; low density to reproduce Buford deployment

  ;user-message "Calling get def 1st time"

  let cur-deploy-path-index union-start-pos
  ;user-message word "getting deploy path at pos " cur-deploy-path-index

  deploy-to-path total-unions-Buford patch-limit item cur-deploy-path-index stored-deploy-paths
  ask infantry with [army = "North"]
  [
    let saved-heading [heading] of self
    uphill cover
    set heading saved-heading
  ]
end

to-report get-print-string[ inputs prec ] ; expecting list
  let res-str ""
  ifelse length inputs = 2
  [
    report word item 0 inputs item 1 inputs
  ]
  [
    foreach range length inputs
    [
      index ->
        let cur item index inputs
        ifelse index = 0 [
        ifelse is-number? cur
        [
          set res-str word "" precision cur prec
          set res-str word res-str " "
        ]
        [
          set res-str word "" cur
          set res-str word res-str " "
        ]
      ]
      [
        ifelse is-number? cur
        [
          set res-str word res-str precision cur prec
          set res-str word res-str " "
        ]
        [
          set res-str word res-str cur
          set res-str word res-str " "
        ]
      ]

    ]
  ]
  report res-str
end

to-report get-unit-speed[cur-unit targ-patch]
  let cur-pos list [xcor] of cur-unit [ycor] of cur-unit
  let cur-elevation [elevation] of patch first cur-pos last cur-pos
  let targ-pos list [pxcor] of targ-patch [pycor] of targ-patch
  let targ-elevation [elevation] of targ-patch
  let elevation-difference cur-elevation - targ-elevation
  let targ-patch-pop count turtles-on targ-patch

  if targ-patch-pop > column-limit [report 0]

  let base-speed [unit-speed] of cur-unit
  if debug-set = 1 or debug-set = 3 [user-message word "base-speed: " base-speed]
  let cur-speed base-speed
  if debug-set = 1 or debug-set = 3 [user-message word "cur-speed b4: " cur-speed]

  set cur-speed cur-speed * ([health] of cur-unit) / max-health

  let res-speed cur-speed
  let slope-a convert-slope-to-geometric-angle 65 elevation-difference ; 65~ path length in meters
  let downhill? false
  let uphill? false
  ifelse elevation-difference > 0
  [
    if slope-a > 30 ; set stumble factor
    [
      set res-speed res-speed * .8
    ]
    trace 3 word "res-speed down: " res-speed
  ]
  [
    set res-speed res-speed * cos slope-a
    trace 3 word "res-speed up: " res-speed
  ]

  if res-speed > base-speed[ user-message word "Something fishy with speed, res speed: " (res-speed / base-speed) ]
;  if res-speed < .2 * base-speed and debug-mode? [
;    user-message get-print-string (list "very slow unit:" base-speed "cur:" cur-speed "res-speed " res-speed "slope/cos" slope-a "/" cos slope-a "elev diff" elevation-difference ) 3
;    ask patch first cur-pos last cur-pos [ set pcolor lime]
;    ask targ-patch [ set pcolor brown]
;  ]
  trace 3 word "respeed" res-speed
  report res-speed
end

to confed-move
  let actor self
  let next nobody
 ;set debug-mode? true
  if [army] of actor = "North"
  [stop]

  if [health] of actor < .9 * max-health
  [
    ask actor [uphill cover]
  ]
  if mode = "M"
  [
    if phase-index = 0
    [
      ;max-one-of turtles [distance myself
      let test [road?] of patch-here
      if [unit] of actor = "RRWave1"
      [
        let double min-one-of infantry with [unit = "RoadWave1"][xcor] ; move in parallel with front of road column
        ;user-message word "double " double

        ifelse double = nobody
        [
          set heading union-orientation - 180

        ]
        [
          set heading [heading] of double
        ]
        if heading > 180
        [
          set heading union-orientation - 180
        ]
        set next patch-ahead 1
        if next = nobody
        [
          show "pa failed"
          show word "cur actor " actor
          user-message (word "patch ahead failed: " patch-here " heading " [heading] of actor)
        ]

      ]

      if [unit] of actor = "RoadWave1"
      [
        ; should be RoadWave1 unit
        ifelse test
        [
          let cur-marker [road-marker] of patch-here
          set next one-of patches with [road? and road-marker = cur-marker - 1]

          while [next = nobody and cur-marker > 0]
          [
            set cur-marker cur-marker - 1
            set next one-of patches with [road? and road-marker = cur-marker - 1]
          ]
          set next one-of patches with [road? and road-marker = cur-marker - 1]
          ifelse next = nobody
          [
            user-message (word "found a nobody " next " cur " cur-marker)
            set phase-index phase-index + 1
          ]
          [
            face next
          ]

      ]
      [
        set next min-one-of Chambersburg-road [distance myself]
        face next
      ]
    ]

    if distance patch first confed-turn last confed-turn < 2
    [set phase-index 1]

    ]
    if phase-index = 1
    [
      face patch first cemetary-hill last cemetary-hill
    ]

    if actor = nobody or next = nobody
    [
      user-message (word "actor/next " actor next)
    ]

    let cur-speed get-unit-speed actor next
    fd cur-speed
    trace 4 (word "next: " next " speed: " cur-speed " base speed" [unit-speed] of actor)
  ]
end

to go
  if item phase-index phases = "SouthEnter1" [
    add-confederates-phase-1
  ]


;  if (confederate-engage-tick >= 2) [
;    ask infantry with [army = "South"]  [engage infantry with [ army = "North" ]]
;    set confederate-engage-tick 0
;  ]


  ; Union forces engage every tick
  ask infantry with [ army = "North" ] [
    move-to-defend infantry with [army = "South"]
    engage infantry with [army = "South"]
    set south-health sum [health] of infantry with [army = "South"]
    ;user-message word "s health: " south-health
  ]

  ; Increment Confederate engage tick counter and global tick counter
  set confederate-engage-tick confederate-engage-tick + 1
  ask infantry with [army = "South"] [
    confed-move
    engage infantry with [army = "North"]
  ]
  if count infantry with [army = "South"] < .5 * wave-1-confederates [
    user-message "Simulation ends, more than 50% confederate casualties."
    stop
  ]

  if count infantry with [army = "North"] <= 0 [
    user-message "Simulation ends, union forces destroyed."
    stop
  ]

  if ticks > 360
  [
    user-message "Reynolds reinforcements arrived."
    stop
  ]


  tick
end

;to move-2
;
;
;  let hill-dist 22
;
;  ifelse distance patch first cemetary-hill last cemetary-hill < 22
;  [
;    face patch first cemetary-hill last cemetary-hill
;    forward .5
;  ]
;  [
;    face patch first turn last turn
;    forward .5
;  ]
;
;
;
;end

;to move-towards-union
;  ; Ensure there are Union agents before proceeding
;  if count infantry with [army = "North"] > 0 [
;    ; Central y-coordinate as a reference point
;    let center-y (min-pycor / 2)
;
;    ; Calculate the average position (centroid) of Union forces
;    let union-center-x mean [xcor] of infantry with [army = "North"]
;    let union-center-y mean [ycor] of infantry with [army = "North"]
;
;    ; Generate a random target point across the width and below the current position
;    let random-target-x (min-pxcor + random (2 * max-pxcor))
;
;
;    ;let random-target-y center-y + random-float ((min [ycor] of confederates) - center-y)
;    let last-pos length deployment-path - 1
;    let cemetary-hill item last-pos deployment-path
;
;    ; Ensure the target doesn't go too low or off-screen
;    ;if random-target-y < center-y [set random-target-y center-y]
;
;    ; Calculate a weighted target point, partially oriented towards Union centroid
;    let weight 0.7  ; Adjust the weight for more or less orientation towards Union
;    let target-x (weight * union-center-x + (1 - weight) * first cemetary-hill)
;    let target-y (weight * union-center-y + (1 - weight) * last cemetary-hill)
;
;    ; Adjust heading towards the weighted target position
;    set heading towardsxy target-x target-y
;
;    ; Move forward with randomness in speed to simulate terrain and uncertainty
;    forward 0.5 + (random-float 0.2)  ; Adjusted for noticeable variability
;  ]
;end

to message-up [actor]
  let next-bud min-one-of infantry with [unit-id > [unit-id] of actor] [unit-id]
  if next-bud != nobody
  [
    ask next-bud
    [
      if mode = "D" [
        set mode "DF"
        set message-id [unit-id] of actor
      ]
    ]
  ]
end

to message-down [actor]
  let next-bud min-one-of infantry with [unit-id < [unit-id] of actor] [unit-id]
  if next-bud != nobody
  [
    ask next-bud
    [
      if mode = "D" [
        set mode "DF"
        set message-id [unit-id] of actor
      ]
    ]
  ]
end
to move-to-defend[enemy-breed]
  let actor self  ; Store the current agent as 'actor' for clarity and to avoid misuse of 'myself'
  let debug-proc false

  ;if any? infantry with [mode = "DF"]
  ;[ user-message word "df mode " infantry with [mode = "DF"]]
  if [health] of actor < .9 * max-health
  [
    ask actor [
      let near-cover max-one-of neighbors [cover]
      if [cover] of near-cover = [cover] of actor
      [
        ; climb instead
        uphill elevation
      ]
      uphill cover
    ]
  ]
  ifelse [health] of actor < 3
  [

    face patch first cemetary-hill last cemetary-hill
    let cur-speed get-unit-speed actor patch-ahead 1
    forward cur-speed
  ]
  [
    ;even out the line
    ifelse [mode] of actor = "D"
    [
      let my-enemy min-one-of enemy-breed [distance actor]
      if my-enemy != nobody
      [face my-enemy]
    ]
    [
      ifelse [mode] of actor = "DF"
      [
        set color green
        ;show word "got a moving message " [who] of actor
        let saved-heading heading
        let move-targ one-of infantry with [unit-id = message-id]
        if move-targ != nobody
        [
          let next-p patch-ahead 1
          ifelse next-p = nobody
          [
            user-message (word "next p " [pxcor] of patch-here ":" [pycor] of patch-here)
          ]
          [
            forward get-unit-speed actor next-p
            set heading saved-heading
          ]
        ]


        let next-bud nobody
        let au-id [unit-id] of actor
        if not is-number? message-id or not is-number? au-id
        [
          user-message (word " message id is " message-id "and  unit id " au-id)
        ]
        if message-id < [unit-id] of actor ; keep pass the message to the "left"
        [
          message-up actor
        ]

       if message-id > [unit-id] of actor
       [
          message-down actor
       ]
      ]
      [

      ]
    ]
 ]

end


to engage [enemy-breed]
  let actor self  ; Store the current agent as 'actor' for clarity and to avoid misuse of 'myself'
  ;let target min-one-of enemy-breed [distance actor]
  let target one-of enemy-breed in-cone attack-range 150
  let seen? target != nobody
  ;user-message word "vision test " seen?

  ifelse not seen?
  [
    ;set color blue
  ]
  [
    ;let in-sight? in-line-of-sight target
    let in-sight? true
    if in-sight?[
      if target != nobody and distance target < [attack-range] of actor
      [
        ;let engaged? [who] of target = [target-id] of actor
        let dist-delta 0
        let follow? false
        set dist-delta distance target - [target-dist] of actor
        if dist-delta > 0 [set follow? true]

        ask actor [  ; Ensure 'ask' is correctly scoped to use 'actor' not 'myself'
          set mode "E"
          set color orange
          set target-id [who] of target
          set target-dist distance target
          fight target
        ]
        if follow?
        [
          ask actor
          [
            if target != nobody
            [
              set heading [heading] of target
              forward get-unit-speed actor patch-ahead 1
              face target
              message-up actor
              message-down actor

            ]
          ]
       ]
     ]
   ]
 ]


end

to-report get-effective-cover[target ]
  let my-elevation [elevation] of patch xcor ycor
  let targ-pos list [xcor] of target [ycor] of target
  let targ-patch patch first targ-pos last targ-pos
  let patch-cover [cover] of targ-patch
  let targ-elevation [elevation] of targ-patch
  let elevation-difference my-elevation - targ-elevation
  let dist-meters (distance target * 65)
  let slope-a convert-slope-to-geometric-angle dist-meters elevation-difference


  let slope-factor 1 + .5 * tan slope-a

  report patch-cover * slope-factor
end

to fight [target]
  let actor self
  let attack-value [attack] of myself
  let dist-meters (distance target * 65)
  let targ-pos list [xcor] of target [ycor] of target
  let targ-patch patch first targ-pos last targ-pos
  let targ-mode [mode] of target
  let targ-patch-pop count turtles-on targ-patch


  let my-attack-range [attack-range] of myself * 65
  ; Calculate the attack success probability based on elevation difference


  let effective-cover get-effective-cover target

  let success-prob .05
  if dist-meters < 1 * my-attack-range [set success-prob .3]
  if dist-meters < .8 * my-attack-range [set success-prob .4]
  if dist-meters < .6 * my-attack-range [set success-prob .5]
  if dist-meters < .4 * my-attack-range [set success-prob .6]
  if dist-meters < .2 * my-attack-range [set success-prob .7]
  if dist-meters < .1 * my-attack-range [set success-prob .8]

  let cover-factor .2 ; reduction of success by availability of cover
  ifelse targ-mode = "M"
  [
    set cover-factor 1  ; no coverage while moving
  ]
  [
    if targ-patch-pop > effective-cover;
    [
      let not-covered targ-patch-pop - [cover] of targ-patch
      let prob-not-covered not-covered / targ-patch-pop
      if random-float 1 < prob-not-covered [set cover-factor 1]
    ]
  ]

  let saved-prob success-prob * 100
  set success-prob (success-prob * cover-factor) * 100

  ;user-message (word "before/after prob " saved-prob " " success-prob)
  ;user-message (word "prob: " success-prob " slope: " slope " cover: " cover-factor " meters: " dist-meters)

  ; success probability is within the valid range (0 to 100)

  ; Check if the attack is successful based on the success probability

  if random 100 < success-prob [
    ask target [
      set health health - attack-value
      if health <= 0
      [
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
39
287
105
320
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
37
339
100
372
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
26
64
59
233
start-pos-choice
start-pos-choice
-1
10
1.0
1
1
NIL
VERTICAL

PLOT
1655
17
2384
492
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "plot count unions" "plot count infantry with [army = \"South\"]"
"pen-1" 1.0 0 -14070903 true "" "plot count infantry with [army = \"North\"]"

BUTTON
34
409
130
442
NIL
show-ridges
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
155
63
188
231
ridge-elev-threshold
ridge-elev-threshold
.8
.975
0.925
.025
1
NIL
VERTICAL

BUTTON
35
453
125
487
NIL
show-town
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1649
555
2381
929
plot 2
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot south-health"

SLIDER
14
639
47
789
debug-set
debug-set
0
7
5.0
1
1
NIL
VERTICAL

BUTTON
35
575
137
609
NIL
toggle-debug
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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
