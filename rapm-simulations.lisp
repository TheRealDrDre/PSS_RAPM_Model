;;; ================================================================
;;; RAPM SIMULATIONS
;;; ----------------------------------------------------------------
;;; Contains code for running simulations of the RAPM model
;;; ----------------------------------------------------------------

(defun simulate (n &optional (res-file "results.csv"))
  (with-open-file (file res-file
			   :direction :output
			   :if-exists :overwrite
			   :if-does-not-exist :create)
    (let ((names (list 'd1 'ticks 'alpha 'egs 'accuracy 'problem 'choice)))
      (format file "~{~a~^, ~}~%" names))

    (dolist (d1 '(1/10 1/5 1 5 10))
      (dolist (ticks '(10 15 20))
	(dolist (alpha '(2/10 4/10 6/10 8/10 1))
	  (dolist (egs '(1/10 2/10 3/10 4/10 5/10))
	    (format t "~{~a~^, ~}~%" (list 'd1 d1 'ticks ticks 'alpha alpha 'egs egs))
	    (dotimes (j n)
	      (rapm-reload)  ; Reload
	      (setf *d1* d1)
	      (setf *ticks* ticks)
	      (sgp-fct `(:egs ,egs :alpha ,alpha :v nil)) ; Sets the params
	      (run 1000 :real-time nil)
	      (let* ((trial (first (experiment-log (current-device))))
		     (res (list d1 ticks alpha egs
				(trial-accuracy trial)
				(trial-problem-rt trial)
				(trial-choice-rt trial))))
		(format file "~{~a~^, ~}~%" (mapcar #'float res))))))))))


(defun simulate-d2 (n &key (d2vals '(1/2 1 3/2 2 5/2 3 7/2 4)))
  (let ((results nil))
    (dolist (d2 d2vals)
      (setf *d2* d2)
      (let ((partial nil))
	(dotimes (j n)
	  (rapm-reload nil)  ; Reload
	  (sgp :v nil)
	  (no-output (run 10000 :real-time nil))
	  (push (trial-accuracy (first (experiment-log (current-device))))
		partial))
	(push (apply #'mean partial) results)))
    (pairlis (mapcar #'float (reverse d2vals)) (mapcar #'float results))))
    

(defun simulate-d1 (n &key (d1vals '(1/2 1 3/2 2 5/2 3 7/2 4)))
  (let ((results nil))
    (dolist (d1 d1vals)
      (setf *d1* d1)
      (let ((partial nil))
	(dotimes (j n)
	  (rapm-reload nil)  ; Reload
	  (sgp :v nil)
	  (no-output (run 10000 :real-time nil))
	  (print (list j (index (current-device)) (mp-time)))
	  (push (apply #'mean
		       (mapcar #'trial-accuracy (experiment-log (current-device)))
		       )
		partial))
	(push (apply #'mean partial) results)))
    (pairlis (mapcar #'float (reverse d1vals)) (mapcar #'float results))))

