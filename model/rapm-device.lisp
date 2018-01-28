;;; ------------------------------------------------------------------
;;; RAPM-DEVICE.LISP
;;; ------------------------------------------------------------------
;;; A class that provides an ACT-R GUI interface for a modified
;;; version of Raven's Advanced Progressive Matrices
;;; ------------------------------------------------------------------
;;; Author: Andrea Stocco,
;;;       : University of Washington
;;;       : Seattle, WA, 98195
;;;       : stocco@uw.edu
;;; ------------------------------------------------------------------

;;; Sets up the logical pathname for all files in the same folder
;;;
(setf (logical-pathname-translations "RAPM")
  `(("**;*.*" ,(namestring (merge-pathnames "**/*.*" *load-truename*)))))


(defun act-r-loaded? ()
  "Cheap hack to check whether ACTR is loaded"
  (member :act-r *features*))

(defparameter *experimental-window-visible?* t
  "Whether a window is visible for demo purposes")

(defparameter *d1* 1 "Dopamine Receptor 1 density")

(defparameter *d2* 1 "Dopamine Receptor 2 density")

(defparameter *striatal-activity*
  '((reward .
     ((problem . 0.0) (choice . 0.0)))
    (rpe .
     ((problem . 0.0) (choice . 0.0))))
  "Default init values for striatal BOLD response")

(defun reset-striatal-activity ()
  "Resets striatal activity"
  (setf *striatal-activity*
	(list (cons 'reward (list (cons 'problem 0.0)
				  (cons 'choice 0.0)))
	      (cons 'rpe (list (cons 'problem 0.0)
			       (cons 'choice 0.0))))))

;;  (setf *striatal-activity* *default-striatal-activity*))


(defparameter *negative-reward* -1.0 "Negative reward for retrieving the same feature")

(defparameter *initial-value-upper-bound* 1.0 "Upper bound of the range of initial values")

(defparameter *ticks* 30 "Internal time threshold to decide to respond")

;;; Boolean parameters

(defparameter *verbose* nil)

(defparameter *calculate-striatal-activity* t)

#|
;;; The original reward hook.
;;; -------------------------
(defun bg-reward-hook (production reward time)
  "Modified reward function with different parameters for 'Pick' and 'Dont' productions" 
  (declare (ignore time))
  (when *verbose*
    (format t "BG: ~A, <~A>~%" production reward))
  (let* ((pname (symbol-name production))
	 (i (position #\* pname))
	 (start (subseq pname (1+ i) (+ 5 i))))
    ;(format t "~A (~A) ~%" production start)
    (cond ((string-equal start "PICK")
	   (* *d1* reward))
	  ((string-equal start "DONT")
	   (* *d2* reward))
	  (t
	   nil))))

;;; The anticorrelated reward hook
;;; ------------------------------

|#
(defun production-pathway (production)
  "Determines if a production is a 'pathway' production, and, if so, which pathway"
  (let* ((pname (symbol-name production))
	 (i (position #\* pname)))
    (when i
      (let ((start (subseq pname (1+ i) (+ 5 i))))
	
	(cond ((string-equal start "PICK")
	       'pick)
	      ((string-equal start "DONT")
	       'dontpick)
	      (t
	       nil))))))

#|
(defun production-pathway-action (production)
  "If we have a 'path' production, determines its gate (action)"
  (when (production-pathway production)
    (let* ((pname (symbol-name production))
	   (start (search "PICK" pname)))
      (subseq pname (+ start 5)))))


|#
(defun production-prefix (production)
  (let* ((pname (symbol-name production))
	 (i (position #\* pname)))
    (subseq pname 0 i)))
#|

(defun production-twin (production)
  (let ((path (production-pathway production)))
    (when path
      (let ((prefix (production-prefix production))
	    (action (production-pathway-action production)))
	(case path
	  (pick
	   (concatenate 'string prefix "*DONT-PICK-" action))
	  (dontpick
	   (concatenate 'string prefix "*PICK-" action))
	  (otherwise nil))))))



(defun bg-reward-hook-anticorrelated (production reward time)
  "Modified reward function with different parameters for 'Pick' and 'Dont' productions" 
  (declare (ignore time))
  (let ((module (get-module utility)))
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (let* ((path (production-pathway production))
	   (twin (production-twin production)))
      (case path
	(pick
	 (when twin
	   (linear-update-utility module (intern twin) (* -1 *d2* reward)))
	 (* *d1* reward))
	(dontpick
	 (when twin
	   (linear-update-utility module (intern twin) (* -1 *d1* reward)))
	 (* *d2* reward))
	(othwerise
	 nil)))))

;;; The asymmetrical anticorrelated reward hook
;;; -------------------------------------------


(defun all-productions-negative (history)
  (not (remove-if-not #'(lambda (x) (let ((path (production-pathway x)))
				      (equal path 'pick)))
		      history :key #'utility-history-name)))


(defun bg-reward-hook-anticorrelated-asymmetrical (production reward time)
  "Modified reward function with different parameters for 'Pick' and 'Dont' productions" 
  (declare (ignore time))
  (let ((module (get-module utility)))
    
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (let* ((path (production-pathway production))
	   (twin (production-twin production)))
      (case path
	(pick
	 (when twin
	   (linear-update-utility module (intern twin) (* -1 *d2* reward)))
	 (* *d1* reward))
	(dontpick
	 (if (all-productions-negative (utility-history module))
	     (progn
	       (when twin
		 (linear-update-utility module (intern twin) (* -1 *d1* reward)))
	       (* *d2* reward))
	     (caar (spp-fct (list production :u)))))
	(othwerise
	 nil)))))

;;; The new version --- works if we have only PICK productions
;;; ----------------------------------------------------------

|#
(defun conflict-set (production)
  "Returns the specific conflict set for a pick production"
  (let ((prefix (production-prefix production))
	(pathway (production-pathway production)))
    (when pathway
      (remove-if-not #'(lambda (x) (and (production-pathway x)
					(string= (production-prefix x) prefix)))
		     (no-output (pp))))))
#|

(defun bg-reward-hook-selection (production reward time)
  "The newest version, with amazing abilities"
  (declare (ignore time))
  (let ((module (get-module utility))
	(path (production-pathway production)))    
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (when path
      (progn
	(let ((rivals (remove production (conflict-set production))))
	  (dolist (rival rivals)
	    (linear-update-utility module rival (* -1 *d2* reward))))
	(* *d1* reward)))))


(defun bg-reward-hook-selection2 (production reward time)
  "The newest version, with amazing abilities"
  (declare (ignore time))
  (let ((module (get-module utility))
	(path (production-pathway production)))    
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (when path
      (progn
	(let ((rivals (remove production (conflict-set production))))
	  (dolist (rival rivals)
	    (linear-update-utility module rival (* -1 *d2* reward))))
	(* *d1* reward)))))


(defun bg-reward-hook-selection3 (production reward time)
  "The newest version, with amazing abilities"
  (declare (ignore time))
  (let ((module (get-module utility))
	(path (production-pathway production)))    
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (when path
      (progn
	(let ((rivals (remove production (conflict-set production))))
	  (dolist (rival rivals)
	    (linear-update-utility module rival (/ (* -1 *d2* reward)
						   (length rivals)))))
	(* *d1* reward)))))

(defun production-utility (production)
  (caar (no-output (spp-fct `((,production) :u)))))

|#

(defun compute-striatal-activity (production reward)
  "Computes predicted striatal activity (as a function of dopamine response)"
  (when *calculate-striatal-activity*
    (let ((q (production-utility production))
	  (rpe 0.0)
	  (rt 0.0)
	  (phase (task-phase (current-device))))
      (when (member phase '(problem choice))
	(if (plusp reward)
	    (progn
	      (setf rt (* *d1* reward))
	      (setf rpe (- (* *d1* reward) q)))
	    (progn
	      (setf rt (* *d2* reward))
	      (setf rpe (- (* *d2* reward) q))))

	;; Update the two possible counters for BOLD
	(let ((reward-accum (cdr (assoc 'reward *striatal-activity*)))
	      (rpe-accum (cdr (assoc 'rpe *striatal-activity*)))
	      (alpha (car (no-output (sgp-fct '(:alpha))))))
	  (incf (cdr (assoc phase reward-accum)) rt)
	  (incf (cdr (assoc phase rpe-accum)) (* alpha rpe)))))))

  
;;; THE REAL ONE
;;;
(defun bg-reward-hook-selection4 (production reward time)
  "Different parameters, depending on sign of reward"
  (declare (ignore time))
  (compute-striatal-activity production reward)
  (let (;(module (get-module utility))
	(path (production-pathway production)))    
    (when *verbose*
      (format t "BG: ~A, <~A>~%" production reward))
    (when path
      (progn  
	(let* ((rivals (remove production (conflict-set production)))
	       (n (length rivals)))
	  (cond ((plusp reward)
		 (* *d1* reward))
		((minusp reward)
		 (/ (* *d2* reward) n))))))))


(defun prod-utilities ()
  (dolist (prod (no-output (pp)))
    (when (production-pathway prod)
      (format t "~A : ~A~%" prod (production-u prod)))))

;; ---------------------------------------------------------------- ;;
;; Some utilities
;; ---------------------------------------------------------------- ;;

(defun pick (lst)
  "Picks up an element from a list"
  (when  (listp lst)
    (elt lst (random (length lst)))))

(defun scramble (lst &optional (sofar nil))
  "Scrambles a list of different elements"
  (if (null lst)
      sofar
    (let ((picked (pick lst)))
      (scramble (remove picked lst) (cons picked sofar)))))

(defun scramble* (lst)
  "Scrambles any list of objects"
  (let ((l (length lst))
        (pos nil))
    (dotimes (i l)
      (push i pos))
    (mapcar #'(lambda (x) (elt lst x)) (scramble pos))))

(defun mean (&rest nums)
  (when (every #'numberp nums)
    (/ (reduce #'+ nums)
       (length nums))))

;;; ------------------------------------------------------------------
;;; PARAMETERS
;;; ------------------------------------------------------------------

(defparameter *number-names* '((0 . zero) (1 . one) (2 . two)
			       (3 . three) (4 . four) (5 . five)
			       (6 . six) (7 . seven) (8 . eight)
			       (9 . nine) (10 . ten))
  "Maps numbers onto their symbolic names")

(defparameter *responses* '(("j" . 0) ("k" . 1) ("l" . 2) (";" . 3))
  "Maps finger responses onto screen options")

      
(defun convert-to-number (token)
  (car (rassoc token *number-names*)))

(defun convert-to-name (number)
  (cdr (assoc number *number-names*)))

(defparameter *pid* nil)

(defun generate-pid (problem)
  "Generates an ID for a problem"
  (if (assoc problem *pid* :test #'equal-problem)
      (rest (assoc problem *pid* :test #'equal-problem))
      (let ((id (1+ (apply #'max (cons 0 (mapcar #'rest *pid*))))))
	(push (cons problem id) *pid*)
	id)))
  
;;; ------------------------------------------------------------------
;;; CELLS AND PROBLEMS: PROCESSING AND DEFINITION
;;; ------------------------------------------------------------------

(defun divide-into-pairs (lst &optional (partial nil) (open nil))
  "Recursively divides a list into pairs"
  (cond ((null lst)
	 (append partial open))
	((= (length (car open)) 2)
	 (divide-into-pairs (rest lst)
			    (append partial open)
			    (list (list (first lst)))))
	((= (length (car open)) 1)
	 (divide-into-pairs (rest lst)
			    partial
			    (list (list (caar open)
					(first lst)))))
	(t
	 (divide-into-pairs (rest lst)
			    partial
			    (list (list (first lst)))))))
	  

(defun same-elements (lst1 lst2)
  "Quickly determines whether two lists contains the same elements (barring repetitions)"
  (and (= (length lst1) (length lst2))
       (every #'(lambda (x) (member x lst2 :test #'equalp)) lst1)
       (every #'(lambda (x) (member x lst1 :test #'equalp)) lst2)))

(defun valid-cell? (c)
  (and (listp c)
       (evenp (length c))
       (every #'atom c)))

(defun equal-cell (c1 c2)
  "Equality for RAPM cells"
  (and (valid-cell? c1)
       (valid-cell? c2)
       (same-elements (divide-into-pairs c1)
		      (divide-into-pairs c2))))

(defun valid-coordinates? (x y)
  "Tests whether the coordinate of a cell are valid (i.e., [0, 1, 2])"
  (and (>= x 0)
       (< x 3)
       (>= y 0)
       (< y 3)))

(defun cell-features (cell)
  "Returns the features of a RAPM cell"
  (when (valid-cell? cell)
    (mapcar #'first (divide-into-pairs cell))))


(defun valid-problem? (p)
  "A problem is valid if it is made of three rows of cells"
  (and (= 3 (length p))
       (every #'(lambda (x) (and (= 3 (length x))
				 (every #'valid-cell? x)))
	      p)))

(defun equal-row (row1 row2)
  "Two rows are equal if their cells are equal"
  (every #'equal-cell row1 row2))

(defun equal-problem (p1 p2)
  "two problems are the same when they have the same cells in the same order"
  (and (valid-problem? p1)
       (valid-problem? p2)
       (every #'equal-row p1 p2)))


(defun problem-cell (problem row col)
  "Returns the cell in position ROW/COL"
  (when (and (valid-coordinates? row col)
	     (valid-problem? problem))
    (nth col (nth row problem))))


;;; ------------------------------------------------------------------
;;; EXPERIMENTAL TRIALS
;;; ------------------------------------------------------------------
;;; A trial is a list containing  a problem, a solution, a list of
;;; options, and a set of optional values to measure accuracy and RTs.
;;; ------------------------------------------------------------------

;;; Checks whether a trial is valid

(defun valid-trial? (trl)
  "A trial is valid is it is made of a valid problem, a valid cell (solution), and a list of valid options" 
  (and (>= (length trl) 3)
       (valid-problem? (first trl))
       (valid-cell? (second trl))
       (valid-options? (third trl))))


(defun make-trial (trl)
  "Generates a fully useable trial from a three-item list"
  (let* ((new-options (scramble* (trial-options trl)))
	 (correct (position (trial-solution trl)
			    new-options
			    :test #'equal-cell)))
    (list (trial-problem trl)              ; Problem
	  (trial-solution trl)             ; Solution
	  new-options                      ; Options
	  correct                          ; Correct response
	  nil                              ; Actual response
	  0                                ; Problem onset
	  0                                ; Problem offset
	  0                                ; Choice onset
	  0)))                             ; Choice response time


;;; The trial problem

(defun trial-problem (trl)
  "Returns the problem in a RAPM trial"
  (nth 0 trl))

(defun set-trial-problem (trl p)
  "Returns the problem in a RAPM trial"
  (setf (nth 0 trl) p))

;;; The trial solution

(defun trial-solution (trl)
  "Returns the solution of problem in a RAPM trial"
  (nth 1 trl))

(defun set-trial-solution (trl sol)
  "Returns the solution of problem in a RAPM trial"
  (setf (nth 1 trl) sol))

;;; The trial's list of options to choose from

(defun trial-options (trl)
  "Returns the response options available for a trial" 
  (nth 2 trl))

(defun set-trial-options (trl opts)
  "Returns the response options available for a trial" 
  (setf (nth 2 trl) opts))

(defun valid-options? (opt)
  "A list of options is valid if every member is a valid cell" 
  (every #'valid-cell? opt))

;;; The correct response

(defun trial-correct-response (trl)
  "Returns the correct answer of a trial"
  (nth 3 trl))

(defun set-trial-correct-response (trl val)
  "Returns the correct answer of a trial"
  (setf (nth 3 trl) val))

;;; The actual responses

(defun trial-actual-response (trl)
  "Returns the answer given by the model"
  (nth 4 trl))

(defun set-trial-actual-response (trl val)
  "Returns the answer given by the model"
  (setf (nth 4 trl) val))

;;; The problem onset

(defun trial-problem-onset (trl)
  (nth 5 trl))

(defun set-trial-problem-onset (trl val)
  (setf (nth 5 trl) val))

;;; The problem response time

(defun trial-problem-response-time (trl)
  (nth 6 trl))

(defun set-trial-problem-response-time (trl val)
  (setf (nth 6 trl) val))


;;; The choice onset

(defun trial-choice-onset (trl)
  (nth 7 trl))

(defun set-trial-choice-onset (trl val)
  (setf (nth 7 trl) val))


;;; The choice response time

(defun trial-choice-response-time (trl)
  (nth 8 trl))

(defun set-trial-choice-response-time (trl val)
  (setf (nth 8 trl) val))


;;; Accuracy and RTs

(defun trial-accuracy (trl)
  "Returns 1 if the choice was correct, 0 otherwise" 
  (if (and (>= (length trl) 7)
	   (numberp (trial-correct-response trl))
	   (numberp (trial-actual-response trl))
	   (= (trial-correct-response trl)
	      (trial-actual-response trl)))
      1
      0))

(defun trial-problem-rt (trl)
  "Calculates the problem's RT"
  (let ((rsp (trial-problem-response-time trl))
	(onset (trial-problem-onset trl)))
    (if (and (numberp rsp)
	     (numberp onset))
      (- rsp onset)
      -1)))

(defun trial-choice-rt (trl)
  "Calculates the problem's RT"
  (let ((rsp (trial-choice-response-time trl))
	(onset (trial-choice-onset trl)))
    (if (and (numberp rsp)
	     (numberp onset))
      (- rsp onset)
      -1)))




;;; ------------------------------------------------------------------
;;; ACT-R DEVICE INTERFACE
;;; ------------------------------------------------------------------

(defparameter *trials* nil)

;;; ------------
;;; Task Manager
;;; ------------
;;;
(defclass rapm-task ()
  ((task-phase :accessor task-phase
	       :initform nil)
   (index :accessor index
	  :initform nil)
   (trials :accessor trials
	   :initform (generate-trials 16)) ;(scramble* *trials*))
   (current-trial :accessor current-trial
		  :initform nil)
   (experiment-log :accessor experiment-log
		   :initform nil))
  (:documentation "A manager for Lauren's version of the RAPM task"))

(defmethod init ((task rapm-task))
  "Initializes the PSS task manager"
  (when (not (null (trials task)))
    (setf (index task) 0)
    (setf (experiment-log task) nil)
    (setf (trials task) (scramble* (trials task)))
    (setf (current-trial task) (make-trial (nth (index task) (trials task))))
    (setf (task-phase task) 'problem)
    (when (act-r-loaded?)
      (set-trial-problem-onset (current-trial task) (mp-time)))
    (when *experimental-window-visible?*
      (setf *window*
	    (open-exp-window "INST Experiment"                                    
			     :visible t
			     :width 400
			     :height 300
			     :x 600
			     :y 600)))))

(defparameter *phase-transitions* '((problem . pause1) (pause1 . choice)
				    (choice . pause2) (pause2 . problem)))

(defun get-next-phase (phase)
  "Next phase in the task's phase transitions diagram"
  (cdr (assoc phase *phase-transitions*)))

(defmethod next ((task rapm-task))
  "Moves on to the next stage of the task"
  (unless (null (index task))  ; If it nil, the tast is not initialized yetr
    (let* ((current-phase (task-phase task))
	   (next-phase (get-next-phase current-phase)))
      (when  (equal next-phase 'problem)
	
	;; If we are moving to a new problem, we need to do some checks

	(incf (index task))  ; Increament the index. This is easy
	(push (current-trial task)   ; Save the current trial
	      (experiment-log task))
	(setf (current-trial task) nil)

	;; If we are out of problems, the next phase is 'done.
	;; Otherwise, we simply update the current problem 

	(if (>= (index task) (length (trials task)))
	    (setf next-phase 'done)
	    (setf (current-trial task)
		  (make-trial (nth (index task) (trials task))))))
	   
      ;; Now, we can update the phase safely

      (setf (task-phase task) next-phase)

      ;; Schedule the appropriate updates if ACTR is loaded,
      ;; And make sure to record the onset times.
      
      (when (act-r-loaded?)
	
	;; cannot trust the "next-phase" variable, since now the phase could
	;; also be 'done'.

	(setf current-phase (task-phase task))
	
	;; Record times if we have a new problem or choice phase

	(cond ((equal current-phase 'problem)
	       (set-trial-problem-onset (current-trial task) (mp-time)))
	      ((equal current-phase 'choice)
	       (set-trial-choice-onset (current-trial task) (mp-time))))
	(schedule-event-relative 0 #'proc-display :params nil)
	(when (member next-phase '(pause1 pause2))
	  (schedule-event-relative 1 #'next :params (list task)))))))
	      
	

(defmethod respond ((task rapm-task) response)
  "Records a response in the PSS task"
  (unless (null (current-trial task))
    (let* ((trial (current-trial task))
	   (phase (task-phase task)))
      (when (equal phase 'choice)
	(set-trial-actual-response trial response))
      
      ;; If ACT-R is loaded, we need to record response times
      ;; and sync the visicon
      
      (when (act-r-loaded?)
	(let ((tme (mp-time)))
	  (cond ((equal (task-phase task) 'problem)
		 (set-trial-problem-response-time trial tme))
		((equal (task-phase task) 'choice)
		 (set-trial-choice-response-time trial tme)))
	  (schedule-event-relative 0 #'next :params (list task)))))))


(defmethod device-handle-keypress ((task rapm-task) key)
  "Converts the key into a symbol and passes it on to the task manager"
  (let ((val (cdr (assoc (format nil "~a" key)
			 *responses*
			 :test #'string-equal))))
    (respond task val)))
			   
(defmethod device-handle-click ((task rapm-task))
  "Does nothing"
  (declare (ignore task))
  nil)

(defmethod device-move-cursor-to ((task rapm-task) pos)
  "Does nothing"
  (declare (ignore task))
  nil)


(defmethod get-mouse-coordinates ((task rapm-task))
  "Does nothing"
  (declare (ignore task))
  (vector 0 0))

(defmethod cursor-to-vis-loc ((task rapm-task))
  "Does nothing"
  (declare (ignore task))
  nil)

(defmethod build-vis-locs-for ((task rapm-task) vismod)
  (let ((phase (task-phase task))
	(trial (current-trial task)))
    (cond ((equal phase 'problem)
	   (build-vis-locs-for-problem trial vismod))
	  ((equal phase 'choice)
	   (build-vis-locs-for-choice trial vismod))
	  (t
	   (build-vis-locs-for-pauses phase vismod)))))

(defmethod build-vis-locs-for-pauses ((name symbol) vismod)
  (declare (ignore vismod))
  (define-chunks-fct  `((isa visual-location 
			     kind rapm-pause
			     value ,name
			     screen-x 0
			     screen-y 0
			     ;problem ,pid
			     height 400 
			     width 600))))

(defun generate-feature-slots (cell)
  (let ((i -1)
	(results nil))
    (dolist (feat (cell-features cell) results)
      (push feat results)
      (push (intern (format nil "~A~A" 'feature (incf i))) results))))

(defmethod build-vis-locs-for-problem ((trial list) vismod)
  "Creates a list of visual locations for a problem"
  (declare (ignore vismod))
  (let* ((problem (first trial))
	 (pid (generate-pid problem))
	 (results nil))

    ;; The cells within each problem
    
    (dotimes (i 3)
      (dotimes (j 3)
	(let* ((cell (problem-cell problem i j))
	       (feature-slots (generate-feature-slots cell)))
	  (unless (null cell)  ; Unless we are in the missing cell	
	    (push  `(isa rapm-cell-location 
			 kind rapm-cell
			 value ,(intern (format nil "ROW~A-COL~A" i j))
			 color black
			 row ,(convert-to-name i)
			 column ,(convert-to-name j)
			 row-num ,i
			 column-num ,j
			 screen-x ,(* j 200)
			 screen-y ,(* i 200)
			 problem ,pid
			 height 200 
			 width 200
			 ,@cell
			 ,@feature-slots)
		   results)))))
    
    ;; Now the problem  

    (push `(isa rapm-screen-location
		kind rapm-problem
		id ,(generate-pid problem)
		screen-x 0
		screen-y 0
		height 400
		width 600)
	  results)

    ;; Creates the chunks
    
    (funcall #'define-chunks-fct results)))
		    

(defmethod build-vis-locs-for-choice ((trial list) vismod)
  "Creates a list of visual locations for a problem"
  (declare (ignore vismod))
  (let* ((problem (trial-problem trial))
	 (options (trial-options trial))
	 (pid (generate-pid problem))
	 (results nil))

    ;; The cells within each problem
    
    (dotimes (i (length options))
      (let ((cell (nth i  options)))
	(push  `(isa rapm-cell-location 
		     kind rapm-cell
		     row zero
		     column ,(convert-to-name i)
		     row-num ,0
		     column-num ,i
		     screen-x ,(* i 200)
		     screen-y 100
		     problem ,pid
		     height 200 
		     width 200
		     ,@cell)
	       results)))
    
    ;; Now the choice scree

    (push `(isa rapm-screen-location
		kind rapm-choice
		id ,(generate-pid problem)
		screen-x 0
		screen-y 0
		height 400
		width 800)
	  results)

    ;; Creates the chunks
    
    (funcall #'define-chunks-fct results)))



(defmethod vis-loc-to-obj ((task rapm-task) vis-loc)
  "Transforms a visual-loc into a visual object"
  (let ((kind (chunk-slot-value-fct vis-loc 'kind))
	(new-chunk nil)
	(trial (current-trial task))
	(phase (task-phase task)))
    (cond ((equal kind 'rapm-cell)
	   
	   ;; If the location was a cell

	   (let* ((row (chunk-slot-value-fct vis-loc 'row))
		  (column (chunk-slot-value-fct vis-loc 'column))
		  (r (convert-to-number row))
		  (c (convert-to-number column))
		  (pid (chunk-slot-value-fct vis-loc 'problem))
		  (cell (if (equal (task-phase task)
				   'problem)
			    (problem-cell (trial-problem trial)
					  r
					  c)
			    (nth c (trial-options trial))))
		  (feature-slots (generate-feature-slots cell)))
	     (setf new-chunk
		   (first (define-chunks-fct 
			      `((isa rapm-cell
				     kind ,kind 
				     row ,row
				     column ,column
				     row-num ,r
				     column-num ,c
				     problem ,pid
				     phase ,phase  ;; Whether a problem cell or a choice cell
				     ,@cell    ;; shape triangle; number 1; etc.
				     ,@feature-slots  ;; feature0, feature1, etc.
				     )))))))

	  ;; If the locations was a rapm-problem 

	  ((member kind '(rapm-problem rapm-choice))
	   (let ((id (chunk-slot-value-fct vis-loc 'id)))
	     (setf new-chunk
		   (first (define-chunks-fct 
			      `((isa rapm-screen
				     kind ,kind 
				     id ,id
				     )))))))

	  (t
	   (setf new-chunk
		 (first (define-chunks-fct 
			    `((isa visual-object
				   kind ,kind 
				     )))))))
	   
    
    ;; No matter what, fill in the slots and return the new chunk
    (fill-default-vis-obj-slots new-chunk vis-loc)
    new-chunk))

(defun schedule-task-update (tm)
  "Schedules the next update of the trial manager"
  (when (act-r-loaded?)
    (next tm)
    (proc-display :clear t)))


;;; ----------------------------------------------------------------
;;; ACT-R extensions to imaginal module (imaginal actions)
;;; ----------------------------------------------------------------

(defparameter *rapm-features* '(number shape texture background orientation) "Possible features")

(defun chunk-to-cell (chunk)
  "Turns a chunk into a lisp representation of a cell"
  (let ((result nil))
    (dolist (slot *rapm-features* result)
      (let ((val (chunk-slot-value-fct chunk slot)))
	(when val
	  (setf result (append result (list slot val))))))))

(defun compare-cells (&rest params)
  (declare (ignore params))
  "Checks whether an internally-imagined cell matches the one being looked at"
  (let* ((hypothesis (first (no-output
			     (buffer-chunk-fct '(imaginal)))))
	 (hypothesis-cell (chunk-to-cell hypothesis))
	 (test (first (no-output (buffer-chunk-fct '(visual)))))
	 (test-cell (chunk-to-cell test))) 
    (if (equal-cell hypothesis-cell test-cell)
      (set-chunk-slot-value-fct hypothesis 'match 'yes)
      (set-chunk-slot-value-fct hypothesis 'match 'no))
    (schedule-event-relative 0.1 #'set-imaginal-free :params nil)))


(defun predict-feature-value (&rest params)
  "Quick and dirty prediction of various properties"
  (declare (ignore params))
  (let* ((rule (first (no-output (buffer-chunk-fct '(retrieval)))))
	 (rule-name (chunk-slot-value-fct rule 'rule))
	 (rule-feature (chunk-slot-value-fct rule 'feature))
	 (current (first (no-output (buffer-chunk-fct '(imaginal)))))
	 (predicted-value nil))
    
    ;; If the rule is "Same", then simply copy the value of the pattern 

    (cond ((equal rule-name 'same)
	   (let ((value (chunk-slot-value-fct current 'zero)))
	     (setf predicted-value value)))

	  ((equal rule-name 'constant)
	   ;; If it's a constant set (e.g., always triangle, circle, square)
	   ;; The the last value of the rule is the predicted value (e.g., square_
	   (let ((value (chunk-slot-value-fct rule 'two)))
	     (setf predicted-value value)))

	  ((equal rule-name 'disjoint)
	   
	   ;; If it's a disjoint rule (e.g., triangle, circle, square, but in
	   ;; different orders), the the predicted value is whatever value of the
	   ;; original rule that has not been used yet (e.g., circle if triangle
	   ;; and square are listed).

	   (let* ((current-row (list
				(chunk-slot-value-fct current 'zero)
				(chunk-slot-value-fct current 'one)))
		  
		  (in-the-rule (list
				(chunk-slot-value-fct rule 'zero)
				(chunk-slot-value-fct rule 'one)
				(chunk-slot-value-fct rule 'two)))
		  (odd-man-out (first (set-difference in-the-rule current-row))))
	     (setf predicted-value odd-man-out)))

	  ((equal rule-name 'progression)
	   ;; In case of a progression, we should do better, but we are treating
	   ;; it like a 'constant' set of values.
	   (let ((value (chunk-slot-value-fct rule 'two)))
	     (setf predicted-value value))))

		  
    ;; Once the feature has been predicted, it will be set in the 
    ;; missing cell slot.
    
    (set-chunk-slot-value-fct current rule-feature predicted-value)
    ;(format t "Changing the chunk ~a with new slot ~a and value ~a from rule ~a~%"
;	    current rule-feature predicted-value rule-name)

    ;; Removes all the irrelevant slots
    (mod-chunk-fct current '(zero nil one nil direction nil value nil feature nil)) 
    (schedule-event-relative 0.1 #'set-imaginal-free :params nil)))


(defun verify-current-value (&rest params)
  "Quick and dirty verification of various rules"
  (declare (ignore params))
  (let* ((rule (first (no-output (buffer-chunk-fct '(retrieval)))))
	 (rule-name (chunk-slot-value-fct rule 'rule))
	 ;;(rule-feature (chunk-slot-value-fct rule 'feature))
	 (current (first (no-output (buffer-chunk-fct '(imaginal)))))
	 ;;(index (chunk-slot-value-fct rule 'focus))
	 (verified 'yes))
    
    ;; A serious verification needs to be done only when we are
    ;; examining the second cell.

    (let ((current-values (list
			   (chunk-slot-value-fct current 'zero)
			   (chunk-slot-value-fct current 'one)
			   (chunk-slot-value-fct current 'two)))
	  
	  (rule-values (list
			(chunk-slot-value-fct rule 'zero)
			(chunk-slot-value-fct rule 'one)
			(chunk-slot-value-fct rule 'two))))
      (when (and (= 3 (length current-values))
		 (not (null (third current-values))))
	;; nothing yet
	;(format nil "Rule name ~a~%" current-values)
	      
	(cond ((equal rule-name 'same)
	       (unless (and (equal (third current-values)
				   (first current-values))
			    (equal (third current-values)
				   (second current-values)))
		 (setf verified 'no)))
	      ((equal rule-name 'constant)
	       ;(print (list current-values rule-values))
	       (unless (equalp current-values rule-values)
		 (setf verified 'no)))

	      ((equal rule-name 'disjoint)
	       (unless (null (set-difference current-values rule-values))
		 (setf verified 'no)))

	      ((equal rule-name 'progression)

	       ;; This is not quite right---makes lots of assumptions.
	       ;(print (list current-values rule-values))
	       (unless (equalp current-values rule-values)
		 (setf verified 'no)))
	      )))
	
    (set-chunk-slot-value-fct current 'verified verified)
    (schedule-event-relative 0.05 #'set-imaginal-free :params nil)))


;; Loads the definition of the problems and the correct value of
;; the *trials* parameter
(load (translate-logical-pathname "RAPM:rapm-problems.lisp"))
