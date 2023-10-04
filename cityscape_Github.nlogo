;--------------------------------------------------------------------------------------------------------
globals [
  nb_cells
  nb_citizens
  mean_nb_citizens_here
  mean_satisfied
  mean_unsatisfied
  max_building_height
  list_normal
  aggregate_index
]
; end globals
;--------------------------------------------------------------------------------------------------------
patches-own [nb_citizens_here]
; end patches-own
;--------------------------------------------------------------------------------------------------------
breed [citizens citizen] ;; citizens are turtles
;--------------------------------------------------------------------------------------------------------
citizens-own [
  state                  ;; "A" or "B"
  S_satisfied?           ;; for each citizen, indicates whether at least %-similar-wanted percent of
                         ;; that citizen's neighbors are the same state as the citizen
  E_satisfied?
  nb_similar_neighbor    ;; how many neighboring patches have a citizen with my state ?
  nb_dissimilar_neighbor ;; how many have a citizen of another state ?
  required_tolerance
  segregation_index
]
; end citizens-own

;--------------------------------------------------------------------------------------------------------
; PROCEDURES
;--------------------------------------------------------------------------------------------------------
to startup
   set density                10
   set alpha                   2 ; used to compute max_buiding_height
   set relocation_probability .1 ; used by the Economic and Socio-Economic models only
end ; startup
;--------------------------------------------------------------------------------------------------------
to setup
  clear-all
  set nb_cells count patches
  ask patches [ set pcolor black ]
  ;; create the citizens
  set max_building_height int (alpha * density)
  create-citizens (nb_cells * density) [
     ;; locate one citizen
     setxy random-xcor random-ycor move-to patch-here
     while [count citizens-on patch-here >= max_building_height ]
        [setxy random-xcor random-ycor move-to patch-here]
     set shape   "square"
     set heading 90
     set size    .9
     ifelse (who mod 2 = 0) [set state "A" set color red] [set state "B" set color yellow]
  ]
  set nb_citizens count citizens
  update_citizens
  update_globals
  reset-ticks
end ; setup

;--------------------------------------------------------------------------------------------------------
; MAIN
;--------------------------------------------------------------------------------------------------------
to go
  if (model = "city")           [ stop                                                            ] ; no move
  if (model = "social")         [ move_if_unsatisfied_segregation                                 ]
  if (model = "economic")       [ move_if_unsatisfied_urbanisation                                ]
  if (model = "socio-economic") [ move_if_unsatisfied_segregation move_if_unsatisfied_urbanisation]
  update_citizens
  update_globals
  if (model = "social")         [if (all? citizens [ S_satisfied? = true ])                        [ beep stop ]]
  if (model = "economic")       [if (all? citizens [ E_satisfied? = true ])                        [ beep stop ]]
  if (model = "socio-economic") [if (all? citizens [ S_satisfied? = true and E_satisfied? = true]) [ beep stop ]]
  tick
end ; go
;--------------------------------------------------------------------------------------------------------
to move_if_unsatisfied_urbanisation
  ask citizens with [ not E_satisfied? ]
    [ find_E_spot ]
end ; move_if_unsatisfied_urbanisation
;--------------------------------------------------------------------------------------------------------
to move_if_unsatisfied_segregation
  ask citizens with [ not S_satisfied? ]
    [ find_S_spot ]
end ; move_if_unsatisfied_segregation
;--------------------------------------------------------------------------------------------------------
to find_S_spot
   let cible one-of patches with [count citizens-on self < max_building_height]
   if (cible != nobody) [move-to cible]
end ; find_S_spot
;--------------------------------------------------------------------------------------------------------
to find_E_spot
   let my_nb_citizens_here nb_citizens_here
   let cible one-of patches with [(my_nb_citizens_here < count citizens-on self) and (count citizens-on self < max_building_height)]
   if (cible != nobody and random-float 1. < relocation_probability) [move-to cible]
end ; find_E_spot
;--------------------------------------------------------------------------------------------------------
to update_citizens
  ask citizens [
     set nb_citizens_here count citizens-on self
  ]
  ;; for each citizen, update S_satisfaction
  ask citizens [
    set nb_similar_neighbor     count (citizens-on neighbors) with [ state  = [ state ] of myself ] + count citizens-here with [ state  =  [ state ] of myself ]
    set nb_dissimilar_neighbor  count (citizens-on neighbors) with [ state != [ state ] of myself ] + count citizens-here with [ state  != [ state ] of myself ]
    let nb_neighbor             nb_similar_neighbor + nb_dissimilar_neighbor
    set required_tolerance      nb_dissimilar_neighbor  / nb_neighbor
    set S_satisfied?            (required_tolerance <= tau)
    set segregation_index       nb_similar_neighbor / nb_neighbor
  ]
  ;; for each citizen, update E_satisfaction
  set  mean_nb_citizens_here (mean [nb_citizens_here] of citizens)
  ask citizens [
    ifelse (mean_nb_citizens_here <= nb_citizens_here)
      [ set E_satisfied? true  set shape "circle" ]
      [ set E_satisfied? false set shape "circle" ]
  ]
end ; update_citizens
;--------------------------------------------------------------------------------------------------------
to update_globals
  set mean_unsatisfied mean [(nb_dissimilar_neighbor / (nb_similar_neighbor + nb_dissimilar_neighbor))] of citizens
  set mean_satisfied   mean [(nb_similar_neighbor    / (nb_similar_neighbor + nb_dissimilar_neighbor))] of citizens
  ifelse (mean_satisfied >= .5) [set aggregate_index (mean_satisfied - .5) / (1 - 0.5) ] [set aggregate_index (mean_satisfied - .5) / (0.5)]
end ; update_globals
;--------------------------------------------------------------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
250
45
858
654
-1
-1
6.0
1
10
1
1
1
0
1
1
1
0
99
0
99
1
1
1
ticks
10.0

SLIDER
40
615
210
648
tau
tau
0
1
0.33
.01
1
NIL
HORIZONTAL

BUTTON
385
10
550
43
setup
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
642
10
857
43
go-for-ever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
550
10
640
43
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
865
315
1225
550
.
time
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"E_sat" 1.0 0 -13345367 true "" "plotxy ticks (count turtles with [E_satisfied? = true] / nb_citizens)"
"S_sat" 1.0 0 -2674135 true "" "plotxy ticks (count turtles with [S_satisfied? = true] / nb_citizens)"
"av_rent (x 2)" 1.0 0 -16777216 true "" "plotxy ticks (1 / mean_nb_citizens_here) * 2"
"av+sd rent (x 2)" 1.0 0 -7500403 true "" "let m  (1 / mean_nb_citizens_here) * 2\nlet v variance [1 / nb_citizens_here] of turtles * 2\nplotxy ticks m + sqrt(v)"
"av-sd rent (x 2)" 1.0 0 -7500403 true "" "let m  (1 / mean_nb_citizens_here) * 2\nlet v variance [1 / nb_citizens_here] of turtles * 2\nplotxy ticks m - sqrt(v)"
"% max_height" 1.0 0 -10899396 true "" "let nb_free_cells count patches with [count turtles-here = 0] \nplotxy ticks (count patches with [count turtles-here = max_building_height] / (nb_cells - nb_free_cells))"

MONITOR
60
340
185
385
# citizens
nb_citizens
1
1
11

SLIDER
10
115
110
148
density
density
0
10
10.0
.1
1
NIL
HORIZONTAL

PLOT
865
10
1225
255
Building height distribution
NIL
NIL
0.0
23.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 1 -13345367 true "" "histogram [count citizens-on self] of patches with [count citizens-on self >= 0]"
"normal" 1.0 0 -2674135 true "set  list_normal []\n  repeat nb_cells [\n     set list_normal lput (random-normal density (sqrt(nb_cells * density * (1 / nb_cells) * (1 - (1 / nb_cells))))) list_normal\n  ]" "histogram list_normal"

SLIDER
40
540
210
573
relocation_probability
relocation_probability
0
1
0.1
.01
1
NIL
HORIZONTAL

MONITOR
865
550
1040
595
S_sat rate
(count turtles with [S_satisfied? = true ] / nb_citizens)
2
1
11

MONITOR
60
270
185
315
# spatial units
nb_cells
0
1
11

MONITOR
865
265
1020
310
mean building height
mean [count turtles-on self] of patches ;with [count turtles-on self > 0]
2
1
11

MONITOR
1025
265
1225
310
standart deviation building height
sqrt( variance [count turtles-on self] of patches with [count turtles-on self > 0])
2
1
11

MONITOR
60
175
202
220
NIL
max_building_height
2
1
11

SLIDER
140
115
232
148
alpha
alpha
1
2
2.0
.1
1
NIL
HORIZONTAL

TEXTBOX
120
130
135
151
X
12
0.0
1

TEXTBOX
120
155
150
173
=
14
0.0
1

MONITOR
1045
550
1225
595
E_sat rate
(count turtles with [E_satisfied? = true ] / nb_citizens)
2
1
11

CHOOSER
55
10
195
55
model
model
"city" "economic" "social" "socio-economic"
2

MONITOR
865
610
1045
655
aggregate Index
;mean [segregation_index] of turtles\naggregate_index
2
1
11

MONITOR
1050
610
1225
655
microMACRO_gap
tau - mean [required_tolerance] of turtles
2
1
11

BUTTON
250
10
385
43
NIL
startup
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

This project models the behavior of two types of agents in a neighborhood. The orange agents and blue agents get along with one another. But each agent wants to make sure that it lives near some of "its own." That is, each orange agent wants to live near at least some orange agents, and each blue agent wants to live near at least some blue agents. The simulation shows how these individual preferences ripple through the neighborhood, leading to large-scale patterns.

This project was inspired by Thomas Schelling's writings about social systems (such as housing patterns in cities).

## HOW TO USE IT

Click the SETUP button to set up the agents. There are approximately equal numbers of orange and blue agents. The agents are set up so no patch has more than one agent.  Click GO to start the simulation. If agents don't have enough same-color neighbors, they move to a nearby patch. (The topology is wrapping, so that patches on the bottom edge are neighbors with patches on the top and similar for left and right).

The DENSITY slider controls the occupancy density of the neighborhood (and thus the total number of agents). (It takes effect the next time you click SETUP.)  The %-SIMILAR-WANTED slider controls the percentage of same-color agents that each agent wants among its neighbors. For example, if the slider is set at 30, each blue agent wants at least 30% of its neighbors to be blue agents.

The % SIMILAR monitor shows the average percentage of same-color neighbors for each agent. It starts at about 50%, since each agent starts (on average) with an equal number of orange and blue agents as neighbors. The NUM-UNHAPPY monitor shows the number of unhappy agents, and the % UNHAPPY monitor shows the percent of agents that have fewer same-color neighbors than they want (and thus want to move). The % SIMILAR and the NUM-UNHAPPY monitors are also plotted.

The VISUALIZATION chooser gives two options for visualizing the agents. The OLD option uses the visualization that was used by the segregation model in the past. The SQUARE-X option visualizes the agents as squares. Unhappy agents are visualized as Xs.

## THINGS TO NOTICE

When you execute SETUP, the orange and blue agents are randomly distributed throughout the neighborhood. But many agents are "unhappy" since they don't have enough same-color neighbors. The unhappy agents move to new locations in the vicinity. But in the new locations, they might tip the balance of the local population, prompting other agents to leave. If a few  agents move into an area, the local blue agents might leave. But when the blue agents move to a new area, they might prompt orange agents to leave that area.

Over time, the number of unhappy agents decreases. But the neighborhood becomes more segregated, with clusters of orange agents and clusters of blue agents.

In the case where each agent wants at least 30% same-color neighbors, the agents end up with (on average) 70% same-color neighbors. So relatively small individual preferences can lead to significant overall segregation.

## THINGS TO TRY

Try different values for %-SIMILAR-WANTED. How does the overall degree of segregation change?

If each agent wants at least 40% same-color neighbors, what percentage (on average) do they end up with?

Try different values of DENSITY. How does the initial occupancy density affect the percentage of unhappy agents? How does it affect the time it takes for the model to finish?

Can you set sliders so that the model never finishes running, and agents keep looking for new locations?

## EXTENDING THE MODEL

The `find-new-spot` procedure has the agents move locally till they find a spot. Can you rewrite this procedure so the agents move directly to an appropriate new spot?

Incorporate social networks into this model.  For instance, have unhappy agents decide on a new location based on information about what a neighborhood is like from other agents in their network.

Change the rules for agent happiness.  One idea: suppose that the agents need some minimum threshold of "good neighbors" to be happy with their location.  Suppose further that they don't always know if someone makes a good neighbor. When they do, they use that information.  When they don't, they use color as a proxy -- i.e., they assume that agents of the same color make good neighbors.

The two different visualizations emphasize different aspects of the model. The SQUARE-X visualization shows whether an agent is happy or not. Can you design a different visualization that emphasizes different aspects?

## NETLOGO FEATURES

`sprout` is used to create agents while ensuring no patch has more than one agent on it.

When an agent moves, `move-to` is used to move the agent to the center of the patch it eventually finds.

Note two different methods that can be used for find-new-spot, one of them (the one we use) is recursive.

## CREDITS AND REFERENCES

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

See also: Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. https://www.theatlantic.com/magazine/archive/2002/04/seeing-around-corners/302471/

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 -->
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

face-happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

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

person2
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 285 180 255 210 165 105
Polygon -7500403 true true 105 90 15 180 60 195 135 105

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

square
false
0
Rectangle -7500403 true true 30 30 270 270

square - happy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 75 195 105 240 180 240 210 195 75 195

square - unhappy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 60 225 105 180 195 180 240 225 75 225

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square-small
false
0
Rectangle -7500403 true true 45 45 255 255

square-x
false
0
Rectangle -7500403 true true 30 30 270 270
Line -16777216 false 75 90 210 210
Line -16777216 false 210 90 75 210

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
Polygon -7500403 true true 0 0 0 300 300 300 30 30

triangle2
false
0
Polygon -7500403 true true 150 0 0 300 300 300

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

x
false
0
Polygon -7500403 true true 300 60 225 0 0 225 60 300
Polygon -7500403 true true 0 60 75 0 300 240 225 300
@#$#@#$#@
NetLogo 6.3.0
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
1
@#$#@#$#@
