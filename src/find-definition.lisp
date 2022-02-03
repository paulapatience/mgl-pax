(in-package :mgl-pax)

(defmacro find-definition* (object name dspecs)
  `(or (find-source-location ,object)
       (find-definition ,name ,dspecs)))

;;; SWANK-BACKEND:FIND-SOURCE-LOCATION is much faster than
;;; SWANK-BACKEND:FIND-DEFINITIONS, but it is not widely supported.
(defun find-source-location (object)
  (when object
    (let ((location (swank-backend:find-source-location object)))
      (when (and (listp location)
                 (eq (first location) :location))
        location))))


;;; Return a definition among (SWANK-BACKEND:FIND-DEFINITIONS NAME)
;;; that matches one of DSPECS. Normally there should be at most one
;;; anyway.
(defun find-definition (name dspecs)
  (let* ((dspec-and-location-list (ignore-errors
                                   (swank-backend:find-definitions name)))
         (entry (loop for dspec in dspecs
                        thereis (find dspec dspec-and-location-list
                                      :key #'first :test #'match-dspec))))
    (if entry
        (second entry)
        `(:error (format nil "Could not find source location for ~S."
                         dspecs)))))

(defmacro define-dspecs (name lambda-list &body body)
  (multiple-value-bind (clauses declarations) (alexandria:parse-body body)
    (let ((dspec-forms (loop for (feature-expr dspec-form) on clauses
                             by #'cddr
                             when (alexandria:featurep feature-expr)
                               collect dspec-form)))
      `(defun ,name ,lambda-list
         ,@declarations
         (list ,@(or dspec-forms
                     (loop for clause on clauses by #'cddr
                           collect (second clause))))))))

(defun match-dspec (dspec-prefix dspec)
  (and (listp dspec)
       (let (#+ecl (dspec (normalize-method-dspec dspec)))
         (alexandria:starts-with-subseq dspec-prefix dspec :test #'equal))))

;;; (DEFMETHOD TEST-GF (X NUMBER) (Y (EQL 'F)) => (DEFMETHOD TEST-GF
;;; NUMBER (EQL F)) so that it matches SWANK-METHOD-DSPECS.
#+ecl
(defun normalize-method-dspec (dspec)
  (flet ((remove-arg-name (specifier)
           (if (and (listp specifier)
                    (= (length specifier) 2))
               (second specifier)
               specifier))
         (remove-quote-from-eql (specifier)
           (if (and (listp specifier)
                    (= (length specifier) 2)
                    (eq (first specifier) 'eql)
                    ;; OBJ is (QUOTE F) in the above example.
                    (let ((obj (second specifier)))
                      (and (listp obj)
                           (= (length obj) 2)
                           (eq (first obj) 'quote))))
               `(eql ,(second (second specifier)))
               specifier)))
    (if (eq (first dspec) 'defmethod)
        (list* 'defmethod (second dspec)
               (mapcar (lambda (specifier)
                         (remove-quote-from-eql
                          (remove-arg-name specifier)))
                       (cddr dspec)))
        dspec)))

(define-dspecs swank-variable-dspecs (name)
  (:or :abcl :ecl :sbcl) `(defvar ,name)
  :allegro `(:special-declaration ,name)
  :allegro `(:variable ,name)
  :ccl `(variable ,name)
  :cmucl `(variable :special ,name)
  :ecl `(defparameter ,name))

(define-dspecs swank-constant-dspecs (name)
  (:or :abcl :ecl :sbcl) `(defconstant ,name)
  :allegro `(:variable ,name)
  #+ccl :ccl #+ccl `(ccl::constant ,name)
  :cmucl `(variable :constant ,name))

(define-dspecs swank-macro-dspecs (name)
  (:or :abcl :ecl :cmucl :sbcl) `(defmacro ,name)
  :allegro `(:operator ,name)
  :ccl `(function ,name))

(define-dspecs swank-compiler-macro-dspecs (name)
  (:or :abcl :ecl :cmucl :sbcl) `(define-compiler-macro ,name)
  :allegro `(:compiler-macro ,name)
  :ccl `(compiler-macro ,name))

(define-dspecs swank-symbol-macro-dspecs (name)
  (:or :abcl :ecl :sbcl) `(define-symbol-macro ,name)
  :allegro `(:symbol-macro ,name)
  :cmucl `(variable :macro ,name))

(define-dspecs swank-function-dspecs (name)
  (:or :abcl :ecl :sbcl) `(defun ,name)
  :allegro `(:operator ,name)
  (:or :ccl :cmucl) `(function ,name))

(define-dspecs swank-generic-function-dspecs (name)
  (:or :abcl :cmucl :ecl :sbcl) `(defgeneric ,name)
  :allegro `(:operator ,name)
  :ccl `(function ,name))

;;; QUALIFIERS and SPECIALIZERS are straight from the DEFMETHOD form.
;;; That is, SPECIALIZERS contains names such as NUMBER or (EQL 7),
;;; not class objects and eql specializer objects.
(define-dspecs swank-method-dspecs (name qualifiers specializers)
  (:or :abcl :ecl :sbcl) `(defmethod ,name ,@qualifiers ,@specializers)
  :allegro `(:operator (method ,name ,@qualifiers ,specializers))
  :ccl `(:method ,name ,@qualifiers
          ,(mapcar 'specializer-to-object specializers))
  :cmucl `(method ,name ,@qualifiers ,specializers))

(define-dspecs swank-method-combination-dspecs (name)
  :sbcl `(define-method-combination ,name)
  :allegro `(:define-method-combination ,name)
  :ccl `(method-combination ,name))

(define-dspecs swank-accessor-dspecs (name class-name writerp)
  :allegro `(:type (method ,name (,@(when writerp '(t))
                                  ,class-name)))
  #+ccl :ccl #+ccl `(,(if writerp
                          'ccl::writer-method
                          'ccl::reader-method)
                     (:method ,name
                       (,@(when writerp (list (find-class t)))
                        ,(find-class class-name))))
  :cmucl `(method ,name () (,@(when writerp '(t))
                            ,class-name))
  :sbcl `(defmethod ,name ,@(when writerp '(t)) ,class-name))

(define-dspecs swank-type-dspecs (name)
  (:or :abcl :cmucl :sbcl) `(deftype ,name)
  :allegro `(:type ,name)
  :ccl `(type ,name)
  :cmucl `(variable :macro ,name))

(define-dspecs swank-class-dspecs (name)
  (:or :abcl :cmucl :ecl :sbcl) `(defclass ,name)
  :allegro `(:type ,name)
  :ccl `(class ,name)
  :cmucl `(variable :macro ,name))

(define-dspecs swank-condition-dspecs (name)
  :sbcl `(define-condition ,name)
  (:or :abcl :ecl) `(defclass ,name)
  :allegro `(:type ,name)
  (:or :ccl :cmucl) `(class ,name))

(define-dspecs swank-package-dspecs (name)
  ;; Name may be a string or a symbol. MATCH-DSPEC wouldn't work if we
  ;; had NAME in the prefix.
  (declare (ignore name))
  :sbcl `(defpackage)
  :ccl `(package))
