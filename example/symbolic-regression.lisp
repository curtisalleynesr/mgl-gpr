(defpackage symbolic-regression-example
  (:use :common-lisp :mgl-gpr))

(in-package :symbolic-regression-example)

(defparameter *operators* (list (operator (+ real real) real)
                                (operator (- real real) real)
                                (operator (* real real) real)
                                (operator (sin real) real)))

(defparameter *literals* (list (literal (real)
                                 (- (random 32.0) 16.0))
                               (literal (real)
                                 '*x*)))

(defparameter *target-expr* '(+ 7 (sin (expt (* *x* 2 pi) 2))))

(defvar *x*)

(defun evaluate (gp expr target-expr)
  (declare (ignore gp))
  (/ 1
     (1+
      ;; Calculate average difference from target.
      (/ (loop for x from 0d0 to 10d0 by 0.5d0
               summing (let ((*x* x))
                         (abs (- (eval expr)
                                 (eval target-expr)))))
         21))
     ;; Penalize large expressions.
     (let ((min-penalized-size 40)
           (size (count-nodes expr)))
       (if (< size min-penalized-size)
           1
           (exp (min 120 (/ (- size min-penalized-size) 10d0)))))))

(defun randomize (gp type expr)
  (if (and (numberp expr)
           (< (random 1.0) 0.5))
      (+ expr (random 1.0) -0.5)
      (random-gp-expression gp (lambda (level)
                                 (<= 3 level))
                            :type type)))

(defun select (gp fitnesses)
  (declare (ignore gp))
  (hold-tournament fitnesses :n-contestants 2))

(defun report-fittest (gp fittest fitness)
  (format t "Best fitness until generation ~S: ~S for~%  ~S~%"
          (generation-counter gp) fitness fittest))

(defun advance-gp (gp)
  (when (zerop (mod (generation-counter gp) 20))
    (format t "Generation ~S~%" (generation-counter gp)))
  (advance gp))

(defun run ()
  (let ((*print-length* nil)
        (*print-level* nil)
        (gp (make-instance
             'genetic-programming
             :toplevel-type 'real
             :operators *operators*
             :literals *literals*
             :population-size 1000
             :copy-chance 0.0
             :mutation-chance 0.5
             :evaluator (lambda (gp expr)
                          (evaluate gp expr *target-expr*))
             ;; Note the use of ' instead of #' to allow
             ;; redefinitions to take effect during a long run.
             :randomizer 'randomize
             :selector 'select
             :fittest-changed-fn 'report-fittest)))
    (loop repeat (population-size gp) do
      (add-individual gp (random-gp-expression gp (lambda (level)
                                                    (<= 5 level)))))
    (loop repeat 1000 do
      ;; This is also a separate function to allow changes during
      ;; runs.
      (advance-gp gp))
    (destructuring-bind (fittest . fitness) (fittest gp)
      (format t "Best fitness: ~S for~%  ~S~%" fitness fittest))))

#|

(run)

|#
