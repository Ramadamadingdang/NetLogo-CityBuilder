globals [
  money
  residential-cost
  commercial-cost
  industrial-cost
  marina-cost
  road-cost
  demolish-cost

  selection-cost

  coal-power-plant-cost
  coal-power-plant-radius

  airport-cost

  power-line-cost
  population
  road-capacity
  current-month
  traffic-density
]

turtles-own [
  my-color
  max-value
  current-value
  powered?
]

patches-own [
  connected?
]

breed [houses house]
breed [stores store]
breed [factories factory]
breed [marinas marina]
breed [cars car]
breed [coal-power-plants coal-power-plant]
breed [power-lines power-line]
breed [boats boat]
breed [airports airport]
breed [jets jet]

to setup
  clear-all
  reset-ticks
  set money 25000
  set residential-cost 100
  set commercial-cost 200
  set industrial-cost 500
  set marina-cost 1000
  set road-cost 50
  set demolish-cost  10

  set coal-power-plant-cost 2500
  set coal-power-plant-radius 35

  set airport-cost 50000

  set power-line-cost 10
  set population 0
  set road-capacity 0
  set current-month "Spring"
  set traffic-density 0

  draw-river
end

to go
  tick
  if ticks mod 100 = 0 [update-buildings]
  update-traffic
  if ticks mod 500 = 0 [update-power]
  update-population
  if ticks mod 5000 = 0 [update-calendar]
  if cars-moving = true [move-cars]
  show-stuff

  ;set the "Cost" monitor showing the price of the current selection menu
  if cursor-selection = "Residential" [set selection-cost residential-cost]
  if cursor-selection = "Commercial" [set selection-cost commercial-cost]
  if cursor-selection = "Industrial" [set selection-cost industrial-cost]
  if cursor-selection = "Marina" [set selection-cost marina-cost]
  if cursor-selection = "Roads" [set selection-cost road-cost]
  if cursor-selection = "Demolish" [set selection-cost demolish-cost]
  if cursor-selection = "Power Plant" [set selection-cost coal-power-plant-cost]
  if cursor-selection = "Power Lines" [set selection-cost power-line-cost]
  if cursor-selection = "Airport" [set selection-cost airport-cost]


  if mouse-down? [
    if money >= residential-cost and cursor-selection = "Residential" [place-residential]
    if money >= commercial-cost and cursor-selection = "Commercial" [place-commercial]
    if money >= industrial-cost and cursor-selection = "Industrial" [place-industrial]
    if money >= marina-cost and cursor-selection = "Marina" [place-marina]
    if money >= road-cost and cursor-selection = "Roads" [place-road]
    if money >= demolish-cost and cursor-selection = "Demolish" [demolish-patch]
    if money >= coal-power-plant-cost and cursor-selection = "Power Plant" [place-coal-power-plant]
    if money >= power-line-cost and cursor-selection = "Power Lines" [place-power-line]
    if money >= airport-cost and cursor-selection = "Airport" [place-airport]
  ]



end

to update-power


  ask coal-power-plants [
    set powered? true
  ]


  ;power the power lines and also normal size buildings
  ask turtles with [breed != cars and breed != boats] [
    if any? turtles in-radius 1 with [powered? = true and breed != cars and breed != boats] and any? coal-power-plants in-radius coal-power-plant-radius [set powered? true]
    if any? turtles in-radius 3 with [powered? = true and size > 1 and breed != cars and breed != boats] and any? coal-power-plants in-radius coal-power-plant-radius [set powered? true]
  ]


  ;power the larger buildings
  ask turtles with [size > 1 and breed != boats] [
    if any? turtles in-radius 3 with [powered? = true] and any? coal-power-plants in-radius coal-power-plant-radius [set powered? true]
  ]


end

to draw-river
  let cursor-x -20
  let cursor-y 0
  let river-direction 0

  ifelse random 10 > 5 [set cursor-y random 20 + 1][set cursor-y random -20 + 1]

  ask patch cursor-x cursor-y [set pcolor cyan]

  while [cursor-x != 20] [

    set river-direction random 5 + 1
    print word "River Direction: " river-direction

    ;move left
    if river-direction = 1 and cursor-x > -20 [set cursor-x cursor-x - 1]

    ;move right
    if river-direction = 2 and cursor-x < 20 [set cursor-x cursor-x + 1]
    if river-direction = 3 and cursor-x < 20 [set cursor-x cursor-x + 1]

    ;move up
    if river-direction = 4 and cursor-y > -20 [set cursor-y cursor-y - 1]

    ;move down
    if river-direction = 5 and cursor-y < 20 [set cursor-y cursor-y + 1]

    ask patch cursor-x cursor-y [set pcolor cyan]

    if cursor-x = 20 [stop]

  ]
end



to update-buildings
  ;check for new houses sprouting up
  if road-capacity > 0 [
    ask patches with [pcolor = green and not any? turtles-here with [breed != power-lines] and any? turtles with [powered? = true] in-radius 2] [
      if random 500 = 1 [
        if not any? houses in-radius 2 with [size > 1] and any? turtles in-radius 1 with [powered? = true] [
          ask power-lines-here [die]
          sprout-houses 1 [
            set max-value 1
            set current-value 1
            set powered? false
            set my-color color
          ]
        ]
      ]
    ]
  ]


  ;update max-values
  if any? houses [
    ifelse traffic-density < 100 [
      ask houses with [powered? = true] [
        set max-value 1
        set max-value max-value + ((count stores in-radius 3) * 2) + ((count stores in-radius 4)  * 1) - ((count factories in-radius 2) * 1)
        set max-value max-value + ((count stores with [size > 1] in-radius 5) * 5)
        set max-value max-value + (count patches with [pcolor = cyan] in-radius 3) * 5
        set max-value max-value + ((count marinas in-radius 3) * 3)
        if any? airports [set max-value max-value + 10]
        if count stores = 0 [set max-value 0]
        if count factories = 0 [set max-value 0]
        if size = 1 and max-value > 5 [set max-value 5]
      ]
    ] [
      if random 500 = 1 [
        ask one-of houses [
          set max-value max-value - 1
          if max-value < 1 [set max-value 1]
        ]
      ]
    ]

    ;start loosing value if there's no power
    ask houses with [powered? = false] [
        if random 500 = 1 [set max-value max-value - 1]
    ]
  ]



  ;check each patch to see if it's value has grown
  ask houses with [current-value < max-value] [
    if random 50 = 1 and road-capacity > population [
      set current-value current-value + 1
    ]
  ]

  ask houses with [current-value > max-value] [set current-value max-value]


  ;check for new stores sprouting up
  if road-capacity > 0 [
    ask patches with [pcolor = blue and not any? turtles-here with [breed != power-lines] and any? turtles with [powered? = true] in-radius 1] [
      if random 500 = 1 [
        if not any? stores in-radius 2 with [size > 1] and any? turtles in-radius 1 with [powered? = true] [
          ask power-lines-here [die]
          sprout-stores 1 [
            set max-value 1
            set current-value 1
            set powered? false
            set my-color color
          ]
        ]
      ]
    ]
  ]




  ;update stores max values
  if any? stores [
    ifelse traffic-density < 100 [
      ask stores with [powered? = true]  [
        set max-value 1
        set max-value max-value + ((count houses in-radius 2) * 2) +  ((count houses in-radius 3) * 1) + ((count factories in-radius 2) * 2)
        set max-value max-value + ((count houses with [size > 1] in-radius 5) * 5)
        set max-value max-value + (count patches with [pcolor = cyan] in-radius 3) * 5
        if any? airports [set max-value max-value + 10]
        if size = 1 and max-value > 5 [set max-value 5]
      ]
    ][
      if random 500 = 1 [
        ask one-of stores [
          set max-value max-value - 1
          if max-value < 1 [set max-value 1]
        ]
      ]
    ]

    ;start loosing value if there's no power
    ask stores with [powered? = false] [
        if random 500 = 1 [set max-value max-value - 1]
    ]
  ]

  ;check each patch to see if it's value has grown
  ask stores with [current-value < max-value] [
    if random 150 = 1 and road-capacity > population [
      set current-value current-value + 1
    ]
  ]

  ask stores with [current-value > max-value] [set current-value max-value]




  ;check for new factories sprouting up
  if road-capacity > 0 [
    ask patches with [pcolor = yellow and not any? turtles-here with [breed != power-lines] and any? turtles with [powered? = true] in-radius 1] [
      if random 500 = 1 [
        if not any? factories in-radius 2 with [size > 1] and any? turtles in-radius 1 with [powered? = true] [
          ask power-lines-here [die]
          sprout-factories 1 [
            set max-value 1
            set current-value 1
            set powered? false
            set my-color color
          ]
        ]
      ]
    ]
  ]




  ;update factories max values
  if any? factories [
    ifelse traffic-density < 100 [
      ask factories with [powered? = true]  [
        set max-value 1
        set max-value max-value + ((count houses in-radius 3) * 2) + ((count houses in-radius 4) * 1)
        set max-value max-value + ((count houses with [size > 1] in-radius 5) * 5)
        set max-value max-value + (count patches with [pcolor = cyan] in-radius 3) * 5
        set max-value max-value + ((count marinas in-radius 3) * 3)
        if any? airports [set max-value max-value + 10]
        if size = 1 and max-value > 5 [set max-value 5]
      ]
    ][
      if random 250 = 1 [
        ask one-of factories [
          set max-value max-value - 1
          if max-value < 1 [set max-value 1]
        ]
      ]
    ]

    ;start loosing value if there's no power
    ask factories with [powered? = false] [
        if random 500 = 1 [set max-value max-value - 1]
    ]
  ]

  ;check each patch to see if it's value has grown
  ask factories with [current-value < max-value] [
    if random 250 = 1 and road-capacity > population [
      set current-value current-value + 1
    ]
  ]

  ask factories with [current-value > max-value] [set current-value max-value]


  ;check for new marina buildings sprouting up
  if road-capacity > 0 [
    ask patches with [pcolor = pink and not any? turtles-here with [breed != power-lines] and any? turtles with [powered? = true] in-radius 1] [
      if random 500 = 1 [
        if not any? marinas in-radius 2 with [size > 1] and any? turtles in-radius 1 with [powered? = true] [
          ask power-lines-here [die]
          sprout-marinas 1 [
            set max-value 1
            set current-value 1
            set powered? false
            set my-color color
          ]
        ]
      ]
    ]
  ]

  ;start loosing value if there's no power
  ask marinas with [powered? = false] [
    if random 500 = 1 [set current-value current-value - 1]
  ]

  ;check each patch to see if it's value has grown
  if random 50 = 1 and road-capacity > population [
    ask marinas with [powered? = true] [
      set current-value current-value + 1
    ]
  ]




  ;update how houses, stores and factories look
  ask houses [
    if current-value <= 0 [die]

    if current-value = 1 [
      set shape "house"
      set size 1
    ]

    if current-value = 3 [
      set shape "die 6"
      set size 1
    ]


    if random 50 = 1 [
      if current-value >= 5 [
        if (sum [count houses-here] of neighbors = 8) [
          ask houses-on neighbors [
            if size = 1 [die]
          ]
          set size 3
          set max-value 50
          set current-value 50
        ]
      ]
    ]

  ]

  ask stores [
    if current-value <= 0 [die]

    if current-value = 1 [
      set shape "building store"
      set size 1
    ]

    if current-value = 3 [
      set shape "i beam"
      set size 1
    ]

    ;check for promotion
    if random 50 = 1 [
      if current-value >= 5 [
        if (sum [count stores-here] of neighbors = 8) [
          ask stores-on neighbors [
            if size = 1 [die]
          ]
          set size 3
          set max-value 150
          set current-value 100
        ]
      ]
    ]
  ]

  ask factories [
    if current-value <= 0 [die]

    if current-value = 1 [
      set shape "house colonial"
      set size 1
    ]

    if current-value = 3 [
      set shape "factory"
      set size 1
    ]

    ;check for promotion
    if random 50 = 1 [
      if current-value >= 5 [
        if (sum [count factories-here] of neighbors = 8) [
          ask factories-on neighbors [
            if size = 1 [die]
          ]
          set size 3
          set max-value 250
          set current-value 200
        ]
      ]
    ]
  ]

  ask marinas [
    if current-value <= 0 [die]

    if current-value = 1 [
      set shape "box"
      set size 1
    ]

    if current-value = 3 [
      set shape "box"
      set size 1
    ]

    ;check for promotion
    if random 500 = 1 [
      if current-value >= 5 [
        if (sum [count marinas-here] of neighbors = 8) [
          ask marinas-on neighbors [
            if size = 1 [die]
          ]
          set size 3
          set current-value 1000
        ]
      ]
    ]
  ]


end


to move-cars

  ;move cars
  if any? cars [
    ask cars [
      ifelse can-move? 1 [
        ifelse ([pcolor = gray] of patch-ahead 1) [
          if random 5 = 1 [fd 0.05]
        ][
          ifelse random 10 <= 5 [left 90] [right 90]
        ]
      ][
        left 180
      ]
      if random 500 = 1 [left 90]
      if random 500 = 1 [right 90]
    ]
  ]

  ;move boats
  if any? boats [
    ask boats [
      ifelse can-move? 1 [
        ifelse ([pcolor = cyan] of patch-ahead 1) [
          if random 5 = 1 [fd 0.05]
        ][
          ifelse random 10 <= 5 [left 90] [right 90]
        ]
      ][
        left 180
      ]
      if random 500 = 1 [set heading random 360]
    ]
  ]

  ;move jets
  if any? jets [
    ask jets [if random 5 = 1 [fd 0.05]]
    ask jets [if [pcolor = sky] of patch-here [die]]
  ]

end


to update-traffic
  ;update traffic density
  if road-capacity > 0 [
    set traffic-density precision ((population / road-capacity) * 100) 0


    ;start adding cars if the car count when population is growing
    if count patches with [pcolor = gray] > 0 [
      if random 1000 = 1 [
        if count cars / count patches with [pcolor = gray] < (traffic-density / 100) [
          ask one-of patches with [pcolor = gray] [
            sprout-cars 1 [
              set shape "car"
              set size 1
              set my-color color
              let car-heading random 3 + 1
              if car-heading = 1 [set heading 0]
              if car-heading = 2 [set heading 90]
              if car-heading = 3 [set heading 180]
              if car-heading = 4 [set heading 270]
              move-to patch-here
            ]
          ]
        ]
      ]

      ;remove a car when traffic density is decreasing
      if random 1000 = 1 [
        if count cars / count patches with [pcolor = gray] > (traffic-density / 100) [
          ask one-of cars [die]
        ]
      ]
    ]
  ]

  ;if the city has become weathly enough, sprout a boat and possibly remove a boat
  if any? marinas [
    if random 1500 = 1 [
      ask one-of patches with [pcolor = cyan] [
        sprout-boats 1 [
          set shape "boat"
          set my-color color
          set size 1.5
        ]
      ]
    ]

    if random 750 = 1 and any? boats [
      ask one-of boats [die]
    ]
  ]

  ;if there's an airport, check for a new flight
  if any? airports [
    if random 1500 = 1 [
      ask one-of patches [
        sprout-jets 1 [
          set shape "airplane"
          set my-color color
          set size 2
          set heading towards one-of airports
        ]
      ]
    ]
  ]

  ;update road-capacity
  set road-capacity count patches with [pcolor = gray] * 250

end


to show-stuff

  ;toggle buildings on/off
  ifelse show-buildings = true [
    ask houses [show-turtle]
    ask stores [show-turtle]
    ask factories [show-turtle]
    ask marinas [show-turtle]
    ask airports [show-turtle]
    ask coal-power-plants [show-turtle]
  ][
    ask houses [hide-turtle]
    ask stores [hide-turtle]
    ask factories [hide-turtle]
    ask marinas [hide-turtle]
    ask airports [hide-turtle]
    ask coal-power-plants [hide-turtle]
  ]

  ;toggle cars on/off
  ifelse show-cars = true [
    ask cars [show-turtle]
    ask boats [show-turtle]
    ask jets [show-turtle]
  ][
    ask cars [hide-turtle]
    ask boats [hide-turtle]
    ask jets [hide-turtle]
  ]


  ;toggle patch values on/off
  ifelse show-values = true [
    ask houses [set label current-value]
    ask stores [set label current-value]
    ask factories [set label current-value]
    ask marinas [set label current-value]
  ][
    ask turtles [set label ""]
  ]


  ifelse show-power = true [
    ask turtles with [powered? = true] [set color orange]
    ask turtles with [powered? = false] [set color grey]
  ][
    ask turtles [set color my-color]
  ]


end



to update-population
  set population (sum [current-value] of houses * 100)
end

to update-calendar

  if current-month = "Spring" [set current-month "Summer" stop]
  if current-month = "Summer" [set current-month "Fall" stop]
  if current-month = "Fall" [set current-month "Winter"]
  if current-month = "Winter" [
    set current-month "Spring"
    set money money + sum [current-value] of turtles * 10
    reset-ticks
    stop
  ]

end

to place-marina
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if any? patches with [pcolor = cyan] in-radius 3 [
        if pcolor = black and not any? coal-power-plants-here [
          set pcolor pink
          set money money - marina-cost
        ]
      ]
    ]
  ]
end


to place-residential
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? coal-power-plants-here [
        set pcolor green
        set money money - residential-cost
      ]
    ]
  ]
end

to place-commercial
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? coal-power-plants-here [
        set pcolor blue
        set money money - commercial-cost
      ]
    ]
  ]
end

to place-industrial
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? coal-power-plants-here [
        set pcolor yellow
        set money money - industrial-cost
      ]
    ]
  ]
end

to place-road
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? coal-power-plants-here [
        set pcolor gray
        set money money - road-cost
      ]
    ]
  ]
end

to place-coal-power-plant
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? houses-here and not any? stores-here and not any? factories-here and not any? coal-power-plants-here [

        set money money - coal-power-plant-cost

        ask power-lines-here [die]

        sprout-coal-power-plants 1 [
          set powered? true
          set shape "factory"
          set color yellow
          set my-color color
          set size 2
          set max-value 100
          set current-value 100
        ]

        set pcolor orange
        ask neighbors [set pcolor orange]

      ]
    ]
  ]
end

to place-airport
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if pcolor = black and not any? houses-here and not any? stores-here and not any? factories-here and not any? coal-power-plants-here [

        set money money - airport-cost

        ask power-lines-here [die]

        sprout-airports 1 [
          set powered? false
          set shape "airport"
          set color white
          set my-color color
          set size 10
          set current-value 500
        ]

        set pcolor sky
        ask patches in-radius 5 [set pcolor sky]

      ]
    ]
  ]
end

to place-power-line
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not any? houses-here and not any? stores-here and not any? factories-here and not any? power-lines-here and not any? coal-power-plants-here and pcolor != cyan [

        set money money - power-line-cost

        sprout-power-lines 1 [
          set powered? false
          set shape "line"
          set color yellow
          set my-color color

          ;orient power lines accordingly so they line up
          carefully [
            if any? power-lines-on patch-at-heading-and-distance 0 1 or any? power-lines-on patch-at-heading-and-distance 180 1 [set heading 0]
            if any? power-lines-on patch-at-heading-and-distance 90 1 or any? power-lines-on patch-at-heading-and-distance 270 1 [set heading 90]
          ][]
        ]
      ]

    ]
  ]
end




to demolish-patch

  let power-outage? false

  print power-outage?

  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [

      ;zoned areas
      if pcolor = green or pcolor = yellow or pcolor = blue or pcolor = pink [
        ask turtles-here [die]
        set pcolor black
        set plabel ""
        set money money - demolish-cost
      ]

      ;power plants
      if pcolor = orange [
        if any? coal-power-plants-here [
          ask neighbors [set pcolor black]
          ask turtles-here [die]
          set pcolor black
          ask neighbors [set pcolor black]
          set plabel ""
          set money money - demolish-cost
        ]
      ]

      ;airports
      if pcolor = sky [
        if any? airports-here [
          ask neighbors [set pcolor black]
          ask turtles-here [die]
          set pcolor black
          ask neighbors [set pcolor black]
          set plabel ""
          set money money - demolish-cost
        ]

        if not any? airports [
          ask jets [die]
        ]
      ]

      ;power lines that aren't in a zoned area
      if pcolor = black [
        ask power-lines-here [
          set power-outage? true
          set money money - demolish-cost
          die
        ]
      ]

      ;roads
      if pcolor = gray [
        set pcolor black
        ask cars-here [die]
        set plabel ""
        set money money - demolish-cost
      ]
    ]

    print power-outage?

    if power-outage? = true [
      ask turtles [set powered? false]
    ]

  ]

end

to save-game
  let filepath "../cbuilder.csv"
  ifelse user-yes-or-no? (word "File will be saved at: " filepath "\nIf this file already exists, it will be overwritten.\nAre you sure you want to save?") [
    export-world filepath
    user-message "File Saved."
  ][
    user-message "Save Canceled. File not saved."
  ]
end

to load-game
  let filepath (word "../cbuilder.csv")
  ifelse user-yes-or-no? (word "Load File: " filepath "\nThis will clear your current level and replace it with the level loaded." "\nAre you sure you want to Load?") [
    import-world filepath
    user-message "Successfully loaded!"
  ][
    user-message "Load Canceled. File not loaded."
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
755
757
-1
-1
18.0
1
14
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

CHOOSER
803
172
941
217
cursor-selection
cursor-selection
"Residential" "Commercial" "Industrial" "Marina" "Roads" "Power Lines" "Power Plant" "Airport" "Demolish"
5

BUTTON
800
11
863
44
Start
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
883
13
973
46
Setup
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

MONITOR
1209
15
1301
76
City Funds
money
0
1
15

MONITOR
1309
15
1456
76
NIL
population
0
1
15

SWITCH
848
397
981
430
show-values
show-values
1
1
-1000

MONITOR
1212
94
1314
155
Calendar
current-month
0
1
15

SWITCH
848
434
981
467
show-buildings
show-buildings
0
1
-1000

SWITCH
849
509
981
542
cars-moving
cars-moving
0
1
-1000

PLOT
1211
163
1496
363
Value
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
"Value" 1.0 0 -16777216 true "" "plot sum [current-value] of turtles"

SWITCH
849
471
981
504
show-cars
show-cars
0
1
-1000

MONITOR
1321
95
1418
156
Total Value
sum [current-value] of turtles
0
1
15

SWITCH
849
547
982
580
show-power
show-power
1
1
-1000

MONITOR
950
165
1022
226
Cost
selection-cost
0
1
15

BUTTON
1541
19
1604
52
Save
save-game
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
1618
21
1681
54
Load
load-game
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

airport
true
0
Rectangle -7500403 true true 135 60 150 240
Rectangle -7500403 true true 105 150 270 165
Rectangle -2674135 true false 180 120 195 135
Rectangle -2674135 true false 195 105 210 120
Rectangle -1 true false 180 105 195 120
Rectangle -1 true false 195 120 210 135
Rectangle -2674135 true false 210 90 225 105
Rectangle -2674135 true false 210 120 225 135
Rectangle -2674135 true false 180 90 195 105
Rectangle -1 true false 195 90 210 105
Rectangle -1 true false 210 105 225 120

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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

container
false
0
Rectangle -7500403 false false 0 75 300 225
Rectangle -7500403 true true 0 75 300 225
Line -16777216 false 0 210 300 210
Line -16777216 false 0 90 300 90
Line -16777216 false 150 90 150 210
Line -16777216 false 120 90 120 210
Line -16777216 false 90 90 90 210
Line -16777216 false 240 90 240 210
Line -16777216 false 270 90 270 210
Line -16777216 false 30 90 30 210
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Line -16777216 false 180 90 180 210

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crate
false
0
Rectangle -7500403 true true 45 45 255 255
Rectangle -16777216 false false 45 45 255 255
Rectangle -16777216 false false 60 60 240 240
Line -16777216 false 180 60 180 240
Line -16777216 false 150 60 150 240
Line -16777216 false 120 60 120 240
Line -16777216 false 210 60 210 240
Line -16777216 false 90 60 90 240
Polygon -7500403 true true 75 240 240 75 240 60 225 60 60 225 60 240
Polygon -16777216 false false 60 225 60 240 75 240 240 75 240 60 225 60

cylinder
false
0
Circle -7500403 true true 0 0 300

die 6
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 84 69 42
Circle -16777216 true false 84 129 42
Circle -16777216 true false 84 189 42
Circle -16777216 true false 174 69 42
Circle -16777216 true false 174 129 42
Circle -16777216 true false 174 189 42

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

i beam
false
0
Polygon -7500403 true true 165 15 240 15 240 45 195 75 195 240 240 255 240 285 165 285
Polygon -7500403 true true 135 15 60 15 60 45 105 75 105 240 60 255 60 285 135 285

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

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
NetLogo 6.1.1
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
