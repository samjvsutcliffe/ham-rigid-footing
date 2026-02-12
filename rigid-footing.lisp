(in-package :cl-mpm/examples/fbar/rigid-footing)
(defparameter *refine* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))
(defparameter *enable-fbar* (if (uiop:getenv "FBAR") (string= (uiop:getenv "FBAR") "TRUE") nil))

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defun run (&key (output-dir (format nil "./output/")))
  (let* ((lstps 5)
         (total-disp -2d-3)
         (current-disp 0d0)
         (step 0))
    (defparameter *data-disp* (list 0d0))
    (defparameter *data-load* (list 0d0))
    (cl-mpm/dynamic-relaxation::run-load-control
     *sim*
     :output-dir output-dir
     :plotter (lambda (sim))
     :loading-function (lambda (i)
                         (setf current-disp (* i total-disp))
                         (cl-mpm/penalty::bc-set-displacement
                          *penalty*
                          (cl-mpm/utils:vector-from-list (list 0d0 current-disp 0d0))))
     :post-conv-step (lambda (sim)
                       (push current-disp *data-disp*)
                       (let ((load (* 2d0 (cl-mpm/penalty::resolve-load *penalty*))))
                         (format t "Load ~E~%" load)
                         (push load *data-load*))
                       (incf step))
     :load-steps lstps
     :enable-plastic t
     :damping (sqrt 2)
     :substeps 50
     :criteria 1d-3
     :save-vtk-dr nil
     :save-vtk-loadstep nil
     :dt-scale 1d0)))

;; (defun test ()
;;   (dolist (r (list 1 2 3))
;;     (dolist (fbar (list t nil))
;;       (setup :mps 4 :refine r :enable-fbar fbar)
;;       (run :output-dir "./data/")
;;       (save-csv "./data/" (format nil "data_fbar_~A.csv" fbar) *data-disp* *data-load*)
;;       ))
;;   )
(defun test ()
  (let ((r *refine*)
        (fbar *enable-fbar*))
    (setup :mps 2 :refine r :enable-fbar fbar)
    (run :output-dir (format nil "./data/output-~D_~A/" r fbar))
    (save-csv "./results/" (format nil "data_~D_~A.csv" r fbar) *data-disp* *data-load*)))
(test)
