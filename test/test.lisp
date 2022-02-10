(in-package :mgl-pax-test)

(deftest test-all ()
  (test-navigate)
  (test-document)
  (test-transcribe))

(defun test (&key (debug nil) (print 't) (describe *describe*))
  ;; Bind *PACKAGE* so that names of tests printed have package names,
  ;; and M-. works on them in Slime.
  (let ((*package* (find-package :common-lisp))
        (*print-duration* nil)
        (*print-compactly* t)
        (*defer-describe* t))
    (warn-on-tests-not-run ((find-package :mgl-pax-test))
      (print (try 'test-all :debug debug :print print :describe describe)))))

#+nil
(test)

#+nil
(test-all)
