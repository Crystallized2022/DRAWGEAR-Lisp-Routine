(defun saveVars ()
  (setq module (atoi (get_tile "module")))
  (setq numt (atoi (get_tile "numt")))
  (setq pressure_angle (atof (get_tile "pressure_angle")))
  (setq fillet_r (atof (get_tile "fillet_r")))
  (setq step (atoi (get_tile "step")))
  (setq height (atof (get_tile "height")))
  (setq pitch_angle (atof (get_tile "pitch_angle")))
  (setq helix_angle (atof (get_tile "helix_angle")))
  );defun

(defun C:DRAWGEAR ()
  (setq dcl_id (load_dialog "draw_gear.dcl"))
  (if (not (new_dialog "draw_gear" dcl_id)
	   );not
    (exit)
    );if
  
  (action_tile "rb1" "(setq geartype 1)")
  (action_tile "rb2" "(setq geartype 2)")
  (action_tile "rb3" "(setq geartype 3)")
  (action_tile "rb4" "(setq geartype 4)")
  (action_tile "rb5" "(setq geartype 5)")
  (action_tile "cancel" "(done_dialog 1)")
  (action_tile "accept" "(saveVars)(done_dialog 2)")

  (setq ddiag (start_dialog))
  (unload_dialog dcl_id)
  (if (= ddiag 2)
    (cond
      ((= geartype 1) (spur_gear module numt pressure_angle fillet_r step height))
      ((= geartype 2) (helical_gear module numt pressure_angle fillet_r step height helix_angle))
      ((= geartype 3) (straight_bevel_gear module numt pressure_angle fillet_r step height pitch_angle))
      ((= geartype 4) (arc_spiral_bevel_gear module numt pressure_angle fillet_r step height pitch_angle helix_angle))
      ((= geartype 5) (zerol_gear module numt pressure_angle fillet_r step height pitch_angle helix_angle))
      ))
  (princ)
  );

(defun spur_gear (module numt pressure_angle fillet_r step height)
  (gear_profile module numt pressure_angle fillet_r step)
  (command "_EXTRUDE" gear "" height)											;extrude
  (princ)
  );defun

(defun helical_gear (module numt pressure_angle fillet_r step height helix_angle)
  (gear_profile module numt pressure_angle fillet_r step)
  (command "_LINE" (list 0 0 0) (list 0 0 height) "")									;sweep
  (setq sw_line (entlast))												;
  (command "_SWEEP" gear "" "T" helix_angle sw_line)									;
  (setq gear (ssget "x"))
  (setq delta total_base_thickness)											;draw characteristic curve
  (setq A1 (list (- delta) (+ tip_r 1) (- (/ height 2) (* delta (tan (dtr helix_angle))))))				;
  (setq A2 (list delta (+ tip_r 1) (+ (/ height 2) (* delta (tan (dtr helix_angle))))))					;
  (command "_LINE" A1 A2 "")												;
  (setq proj_line (entlast))												;
  (command "_DVIEW" proj_line "" "CA" 0 90 "")										;
  (command "_PROJECTGEOMETRY" proj_line "" gear "")									;
  (entdel proj_line)													;
  (princ)
  );defun

(defun straight_bevel_gear (module numt pressure_angle fillet_r step height pitch_angle)
  (gear_profile module numt pressure_angle fillet_r step)
  (setq height_prime (* 0.9 height)) 											;arbitrary cutting height of cone
  (setq max_height (/ pitch_r (tan (dtr pitch_angle))))									;restrict height_prime < max_height
  (if (> height (* 0.9 max_height))											;
    (setq height (* 0.9 max_height)))											;
  (setq contraction (/ (* (- max_height height) (tan (dtr pitch_angle))) pitch_r))					;contraction variable

  (command "_LINE" (list 0 0 0) (list 0 0 height) "")									;scale
  (setq sw_line (entlast))												;
  (command "_SWEEP" gear "" "S" contraction sw_line)									;
  (setq gear (ssget "x"))												;
  
  (setq inv_pitch_angle (- 90 pitch_angle))										;calculate
  (setq r_prime (+ (* height (tan (dtr inv_pitch_angle))) root_r))							;cutting cone
  (setq h_prime (+ height (/ root_r (tan (dtr inv_pitch_angle)))))							;
  (command "_CONE" (list 0 0 height) r_prime (- h_prime))								;
  (setq cone1 (entlast))												;
  (command "_CONE" (list 0 0 height) (* 1.5 r_prime) "t" (* 1.5 r_prime) (- h_prime))					;1.5 is arbitrary
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" cone2 "" cone1 "")										;
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" gear "" cone2 "")										;
  (setq gear (ssget "x"))												;
  
  (setq h_add (/ height 2))												;base height
  (cond															;restrict h_add < h_add_max
    ((> h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))								;
     (setq h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))))							;
  (command "_CONE" (list 0 0 0) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))			;draw base
  (setq cone2 (entlast))												;
  
  (command "_UNION" gear cone2)												;union 2 parts
  (command)														;
  (setq gear (ssget "x"))												;
  
  (command "_CONE" (list 0 0 height) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))		;arbitrarily cut the top
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" gear "" cone2 "")										;
  (princ)
  );defun

(defun arc_spiral_bevel_gear (module numt pressure_angle fillet_r step height pitch_angle helix_angle)
  (gear_profile module numt pressure_angle fillet_r step)
  (setq height_prime (* 0.9 height)) 											;arbitrary cutting height of cone
  (setq max_height (/ pitch_r (tan (dtr pitch_angle))))									;restrict height_prime < max_height
  (if (> height (* 0.9 max_height))											;
    (setq height (* 0.9 max_height)))											;
  (setq contraction (/ (* (- max_height height) (tan (dtr pitch_angle))) pitch_r))					;contraction variable

  (command "_LINE" (list 0 0 0) (list 0 0 height) "")									;sweep and scale
  (setq sw_line (entlast))												;
  (command "_SWEEP" gear "" "S" contraction "T" helix_angle sw_line)							;
  (setq gear (ssget "x"))												;
  
  (setq inv_pitch_angle (- 90 pitch_angle))										;calculate
  (setq r_prime (+ (* height (tan (dtr inv_pitch_angle))) root_r))							;cutting cone
  (setq h_prime (+ height (/ root_r (tan (dtr inv_pitch_angle)))))							;
  (command "_CONE" (list 0 0 height) r_prime (- h_prime))								;
  (setq cone1 (entlast))												;
  (command "_CONE" (list 0 0 height) (* 1.5 r_prime) "t" (* 1.5 r_prime) (- h_prime))					;1.5 is arbitrary
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" cone2 "" cone1 "")										;
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" gear "" cone2 "")										;
  (setq gear (ssget "x"))												;
  
  (setq h_add (/ height 2))												;base height
  (cond															;restrict h_add < h_add_max
    ((> h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))								;
     (setq h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))))							;
  (command "_CONE" (list 0 0 0) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))			;draw base
  (setq cone2 (entlast))												;
  
  (command "_UNION" gear cone2)												;union 2 parts
  (command)														;
  (setq gear (ssget "x"))												;
  
  (command "_CONE" (list 0 0 height) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))		;arbitrarily cut the top
  (setq cone2 (entlast))												;
  (command "_SUBTRACT" gear "" cone2 "")										;
  );defun

(defun zerol_gear (module numt pressure_angle fillet_r step height pitch_angle helix_angle)
  (setvar "orthomode" 0)
  (setvar "coords" 1)
  (setvar "osmode" 0)
  (setq pressure_angle (dtr pressure_angle))
  (setq height_prime (* 0.9 height))
  (setq pitch_r (/ (* numt module) 2.0))
  (setq tip_r (+ pitch_r module))
  (setq base_r (* pitch_r (cos pressure_angle)))
  (setq pitch_thickness (/ (* pi module) 2.0))
  (setq alpha_tip (acos (/ base_r tip_r)))
  (setq base_thickness (* 2.0 base_r (+ (/ pitch_thickness (* 2.0 pitch_r)) (inv pressure_angle))))
  (setq half_angle_base (/ base_thickness (* 2.0 base_r)))
  (setq pz1 (polar (list 0 0) 1.65 (* base_r 0.9)))		;zoom corner 1
  (setq pz2 (polar (list 0 0) 1.35 (* tip_r 1.5)))		;zoom corner 2 
  (COMMAND "ZOOM" "w" pz1 pz2) 				;window for drawing curve
  (involute_curve base_r 0.0 alpha_tip step)
  (setq curve (entlast))
  (command "_ROTATE" curve "" (list 0 0) (rtd half_angle_base))
  (command "_PEDIT" curve "S" "")
  (setq tip_thickness (* 2.0 tip_r (+ (/ pitch_thickness (* 2.0 pitch_r)) (inv pressure_angle) (- (inv alpha_tip)))))
  (setq half_angle_tip (/ tip_thickness (* 2.0 tip_r)))
  (command "_ARC" "C" (list 0 0) (list 0 tip_r) "A" (rtd half_angle_tip))
  (setq arc (entlast))
  (setq total_base_thickness (* 2 pi (/ base_r numt)))
  (setq fillet_base_thickness (- total_base_thickness base_thickness))
  (setq fillet_half_angle_base (/ fillet_base_thickness (* 2 base_r)))
  (setq fillet_r 1)
  (setq root_r (- base_r fillet_r))
  (setq pz1 (list (- (* 15 fillet_r)) base_r)) 		;zoom corner 1
  (setq pz2 (list (- (* 2 fillet_r)) root_r))		;zoom corner 2 
  (COMMAND "ZOOM" "w" pz1 pz2) 				;window for drawing curve
  (setq fillet_angle (acos (- 1 (/ (* fillet_r fillet_r) (* 2 (- base_r fillet_r) base_r)))))
  (command "_ARC" "C" (list 0 0) (polar (list 0 0) (+ half_angle_base fillet_angle (/ pi 2)) root_r)
	   "A" (rtd (- fillet_half_angle_base fillet_angle))) ;polar angle in radian
  (setq unfilleted_base (entlast))
  (setq start_point (vlax-curve-getStartPoint unfilleted_base))
  (command "_BLEND" "CON" "S" curve start_point)
  (setq fillet (entlast))
  (command)
  (command)
  (command "_MIRROR" curve arc fillet unfilleted_base "" (list 0 0) (list 0 1) "n")
  (setq tooth (ssget "x"))
  (COMMAND "_ARRAY" tooth "" "p" (list 0 0) numt "" "")
  (setq gear (ssget "x"))
  (command "_REGION" gear "")
  (setq gear (ssget "x"))
  (command "_EXPLODE" gear "")
  (setq gear (ssget "x"))
  (initcommandversion)
  (command)
  (command "_.join" "_All" ""); region, explode then turn into polyline
  (setq gear (ssget "x"))
  (setq pz1 (list 1 1)) 		;zoom corner 1
  (setq pz2 (list (- 1) (- 1)))		;zoom corner 2 
  (COMMAND "ZOOM" "w" pz1 pz2) 				;window for drawing curve
  (setq max_height (/ pitch_r (tan (dtr pitch_angle))))
  (if (> height (* 0.9 max_height))
    (setq height (* 0.9 max_height)))
  (setq contraction (/ (* (- max_height height) (tan (dtr pitch_angle))) pitch_r))

  (command "_SCALE" gear "" (list 0 0 0) "c" (/ (+ 1 contraction) 2))
  (setq gear1 (entlast))
  (command "_SCALE" gear "" (list 0 0 0) "c" contraction)
  (setq gear2 (entlast))
  (command "_MOVE" gear1 "" "d" (list 0 0 (/ height 2)))
  (command "_MOVE" gear2 "" "d" (list 0 0 height))
  (command "_ROTATE" gear1 "" (list 0 0 0) helix_angle)
  (command "_ROTATE" gear2 "" (list 0 0 0) (* helix_angle 2))
  (command "_ROTATE" gear2 "" (list 0 0 0) helix_angle 2)
  (command "_LOFT" "mo" "so" gear gear1 gear2 "" "");loft: very slow & unstable

  (setq gear (ssget "x"))
  (setq inv_pitch_angle (- 90 pitch_angle))
  (setq r_prime (+ (* height (tan (dtr inv_pitch_angle))) root_r))
  (setq h_prime (+ height (/ root_r (tan (dtr inv_pitch_angle)))))
  (command "_CONE" (list 0 0 height) r_prime (- h_prime))
  (setq cone1 (entlast))
  (command "_CONE" (list 0 0 height) (* 1.5 r_prime) "t" (* 1.5 r_prime) (- h_prime))
  (setq cone2 (entlast))
  (command "_SUBTRACT" cone2 "" cone1 "")
  (setq cone2 (entlast))
  (command "_SUBTRACT" gear "" cone2 "")
  (setq gear (ssget "x"))
  (setq h_add (/ height 2))
  (cond
    ((> h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))
     (setq h_add (* 0.9 (/ root_r (tan (dtr inv_pitch_angle)))))))
  (command "_CONE" (list 0 0 0) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))
  (setq cone1 (entlast))
  (command "_CONE" (list 0 0 height) root_r "t" (- root_r (* h_add (tan (dtr inv_pitch_angle)))) (- h_add))
  (setq cone2 (entlast))
  (command ".SUBTRACT" gear "" cone2 "")
  (princ)
  );defun

(defun tan (a)
  (setq tan_a (/ (sin a) (cos a))))

(defun dtr (a)
  (setq a (/ (* a pi) 180.0)))

(defun rtd(a)
  (setq a (/ (* a 180.0) pi)))

(defun inv (a)
  (setq tan_a (/ (sin a) (cos a)))
  (setq phi (- tan_a a)))

(defun acos ( x )
    (if (<= -1.0 x 1.0)
        (atan (sqrt (- 1.0 (* x x))) x)
    )
)

(defun involute_curve (r_b theta1 theta2 step)
  (setq theta theta1)
  (setq stepsize (/ (- theta2 theta1) step))
  (setq x_1 (list ()))
  (setq y_1 (list ()))
  (while (<= theta theta2)
    (setq x_1 (append x_1 (list (* (/ (sin (inv theta)) (cos theta)) r_b))))
    (setq y_1 (append y_1 (list (* (/ (cos (inv theta)) (cos theta)) r_b))))
    (setq theta (+ stepsize theta))
    );while
  (setq i 2)
  (command "_PLINE" (list (nth 1 x_1) (nth 1 y_1)))
  (repeat step
    (command (list (nth i x_1) (nth i y_1)))
    (setq i (1+ i))
  );repeat
  (command)
  (princ) 
  );defun

(defun gear_profile (module numt pressure_angle fillet_r step)
  (setvar "orthomode" 0)
  (setvar "coords" 1)
  (setvar "osmode" 0)

  (setq pressure_angle (dtr pressure_angle))										;Basic calculation
  (setq pitch_r (/ (* numt module) 2.0))										;
  (setq tip_r (+ pitch_r module))											;
  (setq base_r (* pitch_r (cos pressure_angle)))									;
  (setq root_r (- base_r fillet_r))											;
  
  (setq pitch_thickness (/ (* pi module) 2.0))										;Calculation
  (setq alpha_tip (acos (/ base_r tip_r)))										;to draw the
  (setq base_thickness (* 2.0 base_r (+ (/ pitch_thickness (* 2.0 pitch_r)) (inv pressure_angle))))			;tooth
  (setq half_angle_base (/ base_thickness (* 2.0 base_r)))								;
  
  (setq pz1 (polar (list 0 0) 1.65 (* base_r 0.9)))									;zoom corner 1
  (setq pz2 (polar (list 0 0) 1.35 (* tip_r 1.5)))									;zoom corner 2 
  (COMMAND "_ZOOM" "w" pz1 pz2) 											;window for drawing curve
  
  (involute_curve base_r 0.0 alpha_tip step)										;Draw involute curve
  (setq curve (entlast))												;
  (command "_ROTATE" curve "" (list 0 0) (rtd half_angle_base))								;
  (command "_PEDIT" curve "S" "")											;
  
  (setq tip_thickness (* 2.0 tip_r (+ (/ pitch_thickness (* 2.0 pitch_r)) (inv pressure_angle) (- (inv alpha_tip)))))	;Draw tip arc
  (setq half_angle_tip (/ tip_thickness (* 2.0 tip_r)))									;
  (command "_ARC" "C" (list 0 0) (list 0 tip_r) "A" (rtd half_angle_tip))						;
  (setq arc (entlast))													;
  
  (setq total_base_thickness (* 2 pi (/ base_r numt)))									;Draw unfilleted base
  (setq fillet_base_thickness (- total_base_thickness base_thickness))							;
  (setq fillet_half_angle_base (/ fillet_base_thickness (* 2 base_r)))							;
  
  (setq pz1 (list (- (* 15 fillet_r)) base_r)) 										;zoom corner 1
  (setq pz2 (list (- (* 2 fillet_r)) root_r))										;zoom corner 2 
  (COMMAND "ZOOM" "w" pz1 pz2) 												;window for drawing curve
  
  (setq fillet_angle (acos (- 1 (/ (* fillet_r fillet_r) (* 2 (- base_r fillet_r) base_r)))))				;
  (command "_ARC" "C" (list 0 0) (polar (list 0 0) (+ half_angle_base fillet_angle (/ pi 2)) root_r)			;
	   "A" (rtd (- fillet_half_angle_base fillet_angle))) 								;polar angle in radian
  (setq unfilleted_base (entlast))											;
  
  (setq start_point (vlax-curve-getStartPoint unfilleted_base))								;draw fillet
  (command "_BLEND" "CON" "S" start_point curve)									;
  (setq fillet (entlast))												;
  (command)														;
  
  (command "_MIRROR" curve arc fillet unfilleted_base "" (list 0 0) (list 0 1) "n")					;draw full tooth
  (setq tooth (ssget "x"))												;
  
  (COMMAND "_ARRAY" tooth "" "p" (list 0 0) numt "" "")									;draw entire gear
  (setq gear (ssget "x"))												;
  (command "_REGION" gear "")												;
  (setq gear (ssget "x"))												;
  
  (setq pz1 (list 1 1)) 												;zoom corner 1
  (setq pz2 (list (- 1) (- 1)))												;zoom corner 2 
  (COMMAND "ZOOM" "w" pz1 pz2) 												;window for drawing curve
);defun
