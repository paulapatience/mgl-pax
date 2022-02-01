(in-package :mgl-pax-test)

;;; Make Allegro record lambda lists, from which we can extract
;;; default values of arguments.
#+allegro
(eval-when (:compile-toplevel)
  (declaim (optimize (debug 3))))

(defun check-document (object output)
  (is (null (mismatch% (let ((*package* (find-package :mgl-pax-test)))
                         (first (document object)))
                       output))))

(defun check-one-liner (input expected &key (format :markdown) msg)
  (let* ((*package* (find-package :mgl-pax-test))
         (*document-hyperspec-root* "CLHS/")
         (full-output (first (document input :format format)))
         (got (first-line full-output)))
    (is (equal got expected)
        :ctx ("Input:~S~%Full output:~%~S" input full-output))))

(defun first-line (string)
  (with-input-from-string (s string)
    (read-line s nil nil)))

(defun internedp (name)
  (find-symbol (string name) :mgl-pax-test))


(mgl-pax:define-locative-alias instance class)
(mgl-pax:define-locative-alias object class)
(mgl-pax:define-locative-alias type-of type)

(defsection @test (:export nil)
  "[*TEST-VARIABLE*][]"
  "[`*TEST-VARIABLE*`][]"
  "[*test-variable*][]"
  "[`*test-variable*`][]"
  "[mgl-pax-test::*test-variable*][]"
  "FOO function,"
  "function FOO,"
  "`FOO` function,"
  "function `FOO`,"
  "FOO `function`,"
  "`function` FOO,"
  "`FOO` `function`,"
  "`function` `FOO`,"
  "[foo][function],"
  "[foo][FUNCTION],"
  "[FOO][function],"
  "[FOO][FUNCTION],"
  "[`foo`][function],"
  "[`foo`][FUNCTION],"
  "[`FOO`][function],"
  "[`FOO`][FUNCTION],"

  "FOO-A `(accessor foo)`,"
  "`(accessor foo)` FOO-A,"
  "`FOO-A` `(accessor foo)`,"
  "`(accessor foo)` `FOO-A`,"
  "[foo-a][(accessor foo)],"
  "[foo-a][(ACCESSOR FOO)],"
  "[FOO-A][(accessor foo)],"
  "[FOO-A][(ACCESSOR FOO)],"
  "[`foo-a`][(accessor foo)],"
  "[`foo-a`][(ACCESSOR FOO)],"
  "[`FOO-A`][(accessor foo)],"
  "[`FOO-A`][(ACCESSOR FOO)]

  ->MAX

  Escaped: \\FOO [`FOO`][dislocated] *\\NAVIGATION-TEST-CASES*
  Non escaped: FOO *TEST-VARIABLE*
  @TEST-OTHER

  This should be no link because the page of @TEST-EXAMPLES
  has :URI-FRAGMENT NIL.

  This is code: T"

  "Plural uppercase ambiguous symbol: see FOOs"
  "Plural uppercase symbol: TEST-GFs"
  "Plural uppercase dislocated symbol: ->MAXs"

  "See
  FOO compiler-macro"
  "See FOO
  compiler-macro"
  "See
  compiler-macro FOO"
  "See compiler-macro
  FOO"
  "See
  compiler-macro 
  FOO"

  "See
  FOO"

  "```cl-transcript
  (values (print (1+ 2)) :aaa)
  ..
  .. 3 
  => 3
  => :AAA
  ```

  ```cl-transcript
  (values '(1 2) '(3 4))
  ;=> (1 2)
  ;=> (3
  ;->  4)
  ```

  ```cl-transcript
  (make-array 12 :initial-element 0d0)
  => #(0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0 0.0d0
       0.0d0)
  ```

  In documentation, when the only ambiguity is between a generic
  function and its methods, it's resolved in favor if the gf:
  TEST-GF."
  (foo function)
  (foo compiler-macro)
  (foo class)
  ;; aliases defined above
  "FOO instance"
  "and FOO object"
  "type-of BAR"
  (foo-a (accessor foo))
  (bar macro)
  (bar type)
  (bar constant)
  (baz type)
  (*test-variable* variable)
  (*some-var* (variable '*needs-markdown-escape*))
  (some-restart restart)
  (my-error condition)
  (@test-examples section)
  (@test-other section)
  (test-gf generic-function)
  (test-gf (method () (number)))
  (test-gf (method () ((eql 7))))
  (some-term glossary-term)
  (@test-section-with-link-to-other-page-in-title section)
  (@test-section-with-link-to-same-page-in-title section)
  (@test-tricky-title section)
  (@stealing-from-other-package section)
  (function-with-optional-args function)
  (function-with-keyword-args function)
  (encapsulated-function function)
  (encapsulated-generic-function generic-function))

(defsection @stealing-from-other-package (:package (find-package :mgl-pax))
  (method locative))

(defsection @test-examples (:export nil)
  "example section")

(defsection @test-other (:export nil :title "test other title")
  "backlink @TEST")

(defsection @test-section-with-link-to-other-page-in-title
    (:title "Link to @TEST-OTHER"
            :link-title-to (@test-other section))
  "Same link in docstring to @TEST-OTHER.")

(defsection @test-section-with-link-to-same-page-in-title
    (:title "Link to @TEST" :link-title-to (@test section))
  "Same link in docstring to @TEST.")

(defsection @test-tricky-title
    (:export nil :title "`CODE` *italic* _italic2_ *bold* [link][sdf] <thing>")
  "backlink @TEST")

(define-locative-type my-loc ()
  "This is MY-LOC.")

(defun foo (ook x)
  "FOO has args OOK and X.

  This function FOO is related to compiler-macro FOO.

  Or [foo][compiler-macro], if you prefer.

  Now, [foo][] should link to [foo][compiler-macro] and [foo][class]
  but not to [foo][function]."
  (declare (ignore ook x))
  nil)
(define-compiler-macro foo ()
  "Docstring of a compiler macro."
  nil)
(defclass foo (unexported-class)
  ((a :accessor foo-a)
   (r :reader foo-r)
   (w :writer foo-w)))
(defclass unexported-class () ())
(defvar foo-a)
(defvar foo-b)
(defvar foo-c)

(defparameter *test-variable*
  '(xxx 34)
  "*TEST-VARIABLE* is not a link.")
(defvar *some-var*)

(define-restart some-restart (arg1)
  "This is SOME-RESTART with ARG1.")

(define-condition my-error (error)
  ()
  (:documentation "This is MY-ERROR."))
(defun my-error ())

(defmacro bar (x y &key (z 7))
  "BAR has args X, Y and Z."
  (declare (ignore x y z))
  nil)
(deftype bar (x &rest r)
  "BAR has args X and R."
  (declare (ignore x r))
  'null)
(defconstant bar 2
  "BAR is not a link.")

(defgeneric baz ())
;; KLUDGE: CMUCL clobbers the DEFVAR's source location with that of
;; the DEFSTRUCT if they have the same name.
(defvar bazz)
(defstruct baz
  aaa)

(defgeneric test-gf (x)
  (:documentation "TEST-GF is not a link."))
(defmethod test-gf ((x number))
  "TEST-GF links to the generic function. X is not a link."
  nil)
(defmethod test-gf ((x (eql 7))))

(define-glossary-term some-term ()
  "SOME-TERM is not a link.")

(defun ->max ())

(defun function-with-optional-args (x &optional o1 (o2 7))
  (declare (ignore x o1 o2)))

(defun function-with-keyword-args (x &key k1 (k2 14) (k3 21 k3p))
  (declare (ignore x k1 k2 k3 k3p)))

(when (fboundp 'encapsulated-function)
  (untrace encapsulated-function))
(defun encapsulated-function (x &rest args)
  "This may be encapsulated by TRACE."
  (declare (ignore x args))
  nil)
(trace encapsulated-function)

(when (fboundp 'encapsulated-generic-function)
  (untrace encapsulated-generic-function))
(defgeneric encapsulated-generic-function (x)
  (:documentation "This may also be encapsulated by TRACE."))
(trace encapsulated-generic-function)

(defmacro define-declaration (decl-name (decl-spec env) &body body)
  #+sbcl
  `(sb-cltl2:define-declaration ,decl-name (,decl-spec ,env)
     ,@body)
  #-sbcl
  (declare (ignore decl-name decl-spec env body)))

(define-declaration test-declaration (decl-spec env)
  (declare (ignore env))
  (values :declare decl-spec))

(unless (named-readtables:find-readtable 'xxx-rt)
  (named-readtables:defreadtable xxx-rt
    ;; KLUDGE: ABCL bundles an older named-readtables version that
    ;; does not support docstrings.
    #-abcl
    "ddd"))

(defparameter *navigation-test-cases*
  '(;; @MGL-PAX-VARIABLELIKE-LOCATIVES
    (foo-a variable (defvar foo-a))
    (foo-b variable (defvar foo-b))
    (foo-c variable (defvar foo-c))
    (bar constant (defconstant bar))
    ;; @MGL-PAX-MACROLIKE-LOCATIVES
    (bar macro (defmacro bar))
    (my-smac symbol-macro (define-symbol-macro my-smac))
    (foo compiler-macro (define-compiler-macro foo))
    ;; @MGL-PAX-FUNCTIONLIKE-LOCATIVES
    (foo function (defun foo))
    (test-gf generic-function (defgeneric test-gf))
    (test-gf (method () (number)) (defmethod test-gf))
    (my-comb method-combination (define-method-combination my-comb))
    (foo-a (accessor foo) (defclass foo) (a :accessor foo-a))
    (foo-r (reader foo) (defclass foo) (r :reader foo-r))
    (foo-w (writer foo) (defclass foo) (w :writer foo-w))
    (baz-aaa structure-accessor (defstruct baz))
    ;; @MGL-PAX-TYPELIKE-LOCATIVES
    (bar type (deftype bar))
    (foo type (defclass foo))
    (my-error type (define-condition my-error))
    (foo class (defclass foo))
    (test-declaration declaration (define-declaration test-declaration))
    ;; @MGL-PAX-CONDITION-SYSTEM-LOCATIVES
    (my-error condition (define-condition my-error))
    (some-restart restart (define-restart some-restart))
    ;; @MGL-PAX-PACKAGELIKE-LOCATIVES
    (mgl-pax asdf:system ())
    (mgl-pax package
     (eval-when (:compile-toplevel :load-toplevel :execute))
     (cl:defpackage))
    (xxx-rt readtable (defreadtable xxx-rt))
    ;; @MGL-PAX-PAX-LOCATIVES
    (@mgl-pax-manual section (defsection @mgl-pax-manual))
    (some-term glossary-term (define-glossary-term some-term))
    (my-loc locative (define-locative-type my-loc))))

(defun working-locative-p (locative)
  (let ((type (locative-type locative)))
    (cond ((and (alexandria:featurep :abcl)
                (member type '(variable constant method type restart
                               section locative glossary-term)))
           nil)
          ((alexandria:featurep :clisp)
           nil)
          ((eq type 'symbol-macro)
           (alexandria:featurep '(:not :ccl)))
          ((eq type 'declaration)
           (alexandria:featurep :sbcl))
          ((eq type 'readtable)
           nil)
          ((eq type 'generic-function)
           ;; AllegroCL is off by one form.
           (alexandria:featurep '(:not :allegro)))
          ((eq type 'method-combination)
           (alexandria:featurep '(:not (:or :abcl :cmucl :ecl))))
          ((member type '(reader writer accessor))
           (alexandria:featurep '(:not (:or :abcl :cmucl :ecl))))
          ((eq type 'structure-accessor)
           (alexandria:featurep '(:not (:or :abcl :ecl))))
          ((eq type 'type)
           (alexandria:featurep '(:not :ecl)))
          ((eq type 'package)
           (alexandria:featurep '(:not (:or :abcl :allegro :clisp :cmucl
                                        :ecl))))
          (t
           t))))

(deftest test-navigation ()
  (dolist (test-case *navigation-test-cases*)
    (destructuring-bind
        (symbol locative prefix &optional alternative-prefix) test-case
      (let* ((ref (make-reference symbol locative))
             (located (resolve ref)))
        ;; Test FIND-SOURCE with a REFERENCE and a resolved object if
        ;; there is one.
        (dolist (target (if (and (typep located 'reference)
                                 (mgl-pax::reference= located ref))
                            (list ref)
                            (list ref located)))
          (with-test ((format nil "navigate to ~S" target))
            (with-failure-expected ((not (working-locative-p locative)))
              (let ((location (ignore-errors (find-source target))))
                (when (is (and location (not (eq :error (first location))))
                          :msg `("Find source location for (~S ~S)."
                                 ,symbol ,locative))
                  (multiple-value-bind (file position function-name)
                      (extract-source-location location)
                    (is (or position function-name))
                    (when position
                      (let ((form
                              (let ((*package* (find-package :mgl-pax-test)))
                                (read-form-from-file-position file position))))
                        (is (and (listp form)
                                 (or (alexandria:starts-with-subseq
                                      prefix form :test #'equal)
                                     (and alternative-prefix
                                          (alexandria:starts-with-subseq
                                           alternative-prefix form
                                           :test #'equal))))
                            :msg `("Find prefix ~S~@[ or ~S~] ~
                                    at source location~%~S~% ~
                                    for reference (~S ~S).~%~
                                    Form found was:~%~S."
                                   ,prefix ,alternative-prefix
                                   ,location ,symbol ,locative
                                   ,form))))))))))))))

(defun extract-source-location (location)
  (let ((file-entry (find :file (rest location) :key #'first))
        (position-entry (find :position (rest location) :key #'first))
        (offset-entry (find :offset (rest location) :key #'first))
        (function-name-entry (find :function-name (rest location)
                                   :key #'first)))
    (values (second file-entry)
            (cond (position-entry
                   (1- (second position-entry)))
                  (offset-entry
                   (1- (third offset-entry))))
            (second function-name-entry))))

(defun read-form-from-file-position (filename position)
  (with-open-file (stream filename :direction :input)
    (file-position stream position)
    (read stream)))

(deftest test-read-locative-from-string ()
  (let ((*package* (find-package :mgl-pax-test)))
    (unintern (read-from-string "non-interned"))
    (unintern (read-from-string "yyy"))
    (is (null (mgl-pax::read-locative-from-string "non-interned")))
    (is (null (find-symbol (string '#:non-interned))))
    (is (null (mgl-pax::read-locative-from-string "find")))
    (is (eq (mgl-pax::read-locative-from-string "function") 'function))
    (is (eq (mgl-pax::read-locative-from-string " function") 'function))
    (is (eq (mgl-pax::read-locative-from-string "function ") 'function))
    (is (null (mgl-pax::read-locative-from-string "function junk")))
    (let ((locative (mgl-pax::read-locative-from-string "(function yyy)")))
      (is (eq (first locative) 'function))
      (is (string= (symbol-name (second locative)) (string '#:yyy)))
      (is (eq (symbol-package (second locative)) *package*)))))

(deftest test-read-reference-from-string ()
  (let ((*package* (find-package :mgl-pax-test)))
    (unintern (read-from-string "non-interned"))
    (unintern (read-from-string "yyy"))
    (is (null (mgl-pax::read-reference-from-string "yyy non-interned")))
    (is (null (find-symbol (string '#:non-interned))))
    (is (null (find-symbol (string '#:yyy))))
    (is (null (mgl-pax::read-reference-from-string "yyy (non-interned)")))
    (is (null (find-symbol (string '#:non-interned))))
    (is (null (find-symbol (string '#:yyy))))
    (is (null (mgl-pax::read-reference-from-string "yyy find")))
    (is (null (find-symbol (string '#:yyy))))
    (is (match-values (mgl-pax::read-reference-from-string "yyy function")
          (and (string= (symbol-name *) (string '#:yyy))
               (eq (symbol-package *) *package*))
          (eq * 'function)
          (eq * t)))
    (is (match-values (mgl-pax::read-reference-from-string " yyy  function ")
          (and (string= (symbol-name *) (string '#:yyy))
               (eq (symbol-package *) *package*))
          (eq * 'function)
          (eq * t)))
    (is (null (mgl-pax::read-reference-from-string "yyy function junk")))))

(deftest test-transform-tree ()
  (is (equal '(1)
             (mgl-pax::transform-tree (lambda (parent a)
                                        (declare (ignore parent))
                                        (values a (listp a) nil))
                                      '(1))))

  (is (equal '(2 (3 (4 5)))
             (mgl-pax::transform-tree (lambda (parent a)
                                        (declare (ignore parent))
                                        (values (if (listp a) a (1+ a))
                                                (listp a)
                                                nil))
                                      '(1 (2 (3 4))))))

  (is (equal '(1 2 (2 3 (3 4 4 5)))
             (mgl-pax::transform-tree (lambda (parent a)
                                        (declare (ignore parent))
                                        (values (if (listp a)
                                                    a
                                                    (list a (1+ a)))
                                                (listp a)
                                                (not (listp a))))
                                      '(1 (2 (3 4)))))))

(deftest test-macro-arg-names ()
  (is (equal '(x a b c)
             (mgl-pax::macro-arg-names '((&key (x y)) (a b) &key (c d))))))


(defparameter *baseline-dirname*
  #-(or abcl allegro ccl clisp cmucl ecl) "baseline"
  #+abcl "abcl-baseline"
  #+allegro "acl-baseline"
  #+ccl "ccl-baseline"
  #+clisp "clisp-baseline"
  #+cmucl "cmucl-baseline"
  #+ecl "ecl-baseline")

;;; set by test.sh
(defvar *update-baseline* nil)

(deftest test-document (format)
  (let* ((*package* (find-package :common-lisp))
         (*document-link-to-hyperspec* nil)
         (outputs (write-test-document-files
                   (asdf:system-relative-pathname :mgl-pax "test/data/tmp/")
                   format)))
    (is (= 4 (length outputs)))
    ;; the default page corresponding to :STREAM is empty
    (is (string= "" (first outputs)))
    (is (= 2 (count-if #'pathnamep outputs)))
    (dolist (output outputs)
      (when (pathnamep output)
        (let ((baseline (make-pathname
                         :directory (substitute *baseline-dirname* "tmp"
                                                (pathname-directory output)
                                                :test #'equal)
                         :defaults output)))
          (unless (string= (alexandria:read-file-into-string baseline)
                           (alexandria:read-file-into-string output))
            (unless *update-baseline*
              (restart-case
                  ;; KLUDGE: PROGN prevents the restart from being
                  ;; associated with the condition. Thus the restart
                  ;; is visible when TRY resignals the condition as
                  ;; TRY:UNHANDLED-ERROR.
                  (progn
                    (error "~@<Output ~S ~_differs from baseline ~S.~@:>"
                           output baseline))
                (update-output-file ()
                  :report "Update output file.")))
            (update-test-document-baseline format)))))))

(defun write-test-document-files (basedir format)
  (flet ((rebase (pathname)
           (merge-pathnames pathname
                            (make-pathname
                             :type (if (eq format :markdown) "md" "html")
                             :directory (pathname-directory basedir)))))
    (let ((open-args '(:if-exists :supersede :ensure-directories-exist t))
          (*document-downcase-uppercase-code* (eq format :html)))
      (document @test
                :pages `((:objects
                          ,(list @test-examples)
                          :output (nil))
                         (:objects
                          ,(list @test-other)
                          :output (,(rebase "other/test-other") ,@open-args))
                         (:objects
                          ,(list @test)
                          :output (,(rebase "test") ,@open-args)))
                :format format))))

(defun update-test-document-baseline (format)
  (write-test-document-files (asdf:system-relative-pathname
                              :mgl-pax
                              (format nil "test/data/~A/" *baseline-dirname*))
                             format))


(deftest test-codify ()
  (with-test ("unadorned")
    (with-test ("uninterned")
      (with-test ("len=1")
        (is (not (internedp "U")))
        (check-one-liner "U" "U")
        (check-one-liner "\\U" "U")
        (check-one-liner "-" "-"))
      (with-test ("len=2")
        (is (not (internedp "UN")))
        (check-one-liner "UN" "UN")
        (check-one-liner "\\UN" "UN")
        (check-one-liner "/=" "/="))
      (with-test ("len=3")
        (is (not (internedp "UNI")))
        (check-one-liner "UNI" "UNI")
        (check-one-liner "\\UNI" "UNI")
        (is (not (internedp "*U*")))
        (check-one-liner "*U*" "*U*")
        (check-one-liner "*\\U*" "*U*")
        (check-one-liner "///" "///")
        (check-one-liner "Uni" "Uni")
        (check-one-liner "UnI" "UnI")))
    (with-test ("internal")
      (with-test ("len=1")
        (is (not (mgl-pax::external-symbol-p 'q)))
        (check-one-liner "Q" "Q")
        (check-one-liner "\\Q" "Q"))
      (with-test ("len=2")
        (is (not (mgl-pax::external-symbol-p 'qq)))
        (check-one-liner "QQ" "QQ")
        (check-one-liner "\\QQ" "QQ"))
      (with-test ("len=3")
        (is (not (mgl-pax::external-symbol-p 'qqq)))
        (check-one-liner "QQQ" "`QQQ`")
        (check-one-liner "\\QQQ" "QQQ")
        (is (not (mgl-pax::external-symbol-p '*q*)))
        (check-one-liner "*Q*" "`*Q*`")
        (check-one-liner "*\\Q*" "*Q*")))
    (with-test ("external")
      (let ((*document-link-to-hyperspec* nil))
        (check-one-liner "T" "`T`")
        (check-one-liner "\\T" "T")
        (check-one-liner "DO" "`DO`")
        (check-one-liner "\\DO" "DO")
        (check-one-liner "COS" "`COS`")
        (check-one-liner "\\COS" "COS")))
    (with-test ("external with ref")
      ;; T is not autolinked.
      (check-one-liner "T" "`T`")
      (check-one-liner "\\T" "T")
      (check-one-liner "DO" "[`DO`][be20]")
      (check-one-liner "\\DO" "DO")
      (check-one-liner "COS" "[`COS`][90ce]")
      (check-one-liner "\\COS" "COS")))
  ;; FIXME
  (with-test ("reflink")
    (with-test ("no refs")
      (check-one-liner "[U]" "[U][]")
      (check-one-liner "[FORMAT][dislocated]" "`FORMAT`"))))

(defun q ())
(defun qq ())
(defun qqq ())
(defvar *q*)


(deftest test-plural ()
  (with-test ("Uppercase name with uppercase plural.")
    (check-one-liner "CARS" "[`CAR`][86ef]s")
    (check-one-liner "CARS." "[`CAR`][86ef]s.")
    (check-one-liner "CLASSES" "[`CLASS`][46f7]es")
    (check-one-liner "CLASSES." "[`CLASS`][46f7]es."))
  (with-test ("Uppercase name with lowercase plural.")
    (check-one-liner "CARs" "[`CAR`][86ef]s")
    (check-one-liner "CARs." "[`CAR`][86ef]s.")
    (check-one-liner "CLASSes" "[`CLASS`][46f7]es")
    (check-one-liner "CLASSes." "[`CLASS`][46f7]es."))
  (with-test ("Uppercase code + lowercase plural.")
    (check-one-liner "`CAR`s" "[`CAR`][86ef]s")
    (check-one-liner "`CAR`s." "[`CAR`][86ef]s.")
    (check-one-liner "`CLASS`es" "[`CLASS`][46f7]es")
    (check-one-liner "`CLASS`es." "[`CLASS`][46f7]es."))
  (with-test ("Lowercase code + lowercase plural.")
    (check-one-liner "`car`s" "[`car`][86ef]s")
    (check-one-liner "`car`s." "[`car`][86ef]s.")
    (check-one-liner "`class`es" "[`class`][46f7]es")
    (check-one-liner "`class`es." "[`class`][46f7]es."))
  (with-test ("Lowercase code with lowercase plural.")
    (check-one-liner "`cars`" "[`cars`][86ef]")
    (check-one-liner "`cars.`" "`cars.`")
    (check-one-liner "`classes`" "[`classes`][46f7]")
    (check-one-liner "`classes.`" "`classes.`"))
  (with-test ("Uppercase name with uppercase plural in reflink.")
    (check-one-liner "[CARS][]" "[`CAR`s][86ef]")
    (check-one-liner "[CARS.][]" "[`CAR`s.][]")
    (check-one-liner "[CLASSES][]" "[`CLASS`es][46f7]")
    (check-one-liner "[CLASSES.][]" "[`CLASS`es.][]"))
  (with-test ("Uppercase name with lowercase plural in reflink.")
    (check-one-liner "[CARs][]" "[`CAR`s][86ef]")
    (check-one-liner "[CARs.][]" "[`CAR`s.][]")
    (check-one-liner "[CLASSes][]" "[`CLASS`es][46f7]")
    (check-one-liner "[CLASSes.][]" "[`CLASS`es.][]"))
  (with-test ("Uppercase code + lowercase plural in reflink.")
    (check-one-liner "[`CAR`s][]" "[`CAR`s][86ef]")
    (check-one-liner "[`CAR`s.][]" "[`CAR`s.][]")
    (check-one-liner "[`CLASS`es][]" "[`CLASS`es][46f7]")
    (check-one-liner "[`CLASS`es.][]" "[`CLASS`es.][]")))


(deftest test-downcasing ()
  (test-downcasing-in-docstrings)
  (test-downcasing-of-section-names))

(defsection @section-without-title ())

(deftest test-downcasing-in-docstrings ()
  (with-test ("unadorned")
    (check-downcasing "NOT-INTERNED" "NOT-INTERNED")
    ;; has no refs
    (check-downcasing "TEST" "`test`")
    ;; has refs
    (check-downcasing "CLASS" "[`class`][46f7]")
    ;; has no refs
    (check-downcasing "*FORMAT*" "`*format*`")
    ;; has refs
    (check-downcasing "*PACKAGE*" "[`*package*`][1063]")
    ;; section with refs
    (check-downcasing (list "@SECTION-WITHOUT-TITLE" @section-without-title)
                      "[`@section-without-title`][9a4b]"))
  (with-test ("escaped unadorned")
    (check-downcasing "\\NOT-INTERNED" "NOT-INTERNED")
    (check-downcasing "\\TEST" "TEST")
    (check-downcasing "\\CLASS" "CLASS")
    (check-downcasing "*\\FORMAT*" "*FORMAT*")
    (check-downcasing "*\\PACKAGE*" "*PACKAGE*")
    (check-downcasing (list "\\@SECTION-WITHOUT-TITLE" @section-without-title)
                      "@SECTION-WITHOUT-TITLE"))
  (with-test ("code")
    (check-downcasing "`NOT-INTERNED`" "`not-interned`")
    (check-downcasing "`TEST`" "`test`")
    (check-downcasing "`CLASS`" "[`class`][46f7]")
    (check-downcasing "`*FORMAT*`" "`*format*`")
    (check-downcasing "`*PACKAGE*`" "[`*package*`][1063]")
    (check-downcasing (list "`@SECTION-WITHOUT-TITLE`" @section-without-title)
                      "[`@section-without-title`][9a4b]"))
  (with-test ("escaped code")
    (check-downcasing "`\\NOT-INTERNED`" "`NOT-INTERNED`")
    (check-downcasing "`\\TEST`" "`TEST`")
    (check-downcasing "`\\CLASS`" "`CLASS`")
    (check-downcasing "`\\*FORMAT*`" "`*FORMAT*`")
    (check-downcasing "`\\*PACKAGE*`" "`*PACKAGE*`")
    (check-downcasing (list "`\\@SECTION-WITHOUT-TITLE`"
                            @section-without-title)
                      "`@SECTION-WITHOUT-TITLE`"))
  (with-test ("reflink unadorned")
    (check-downcasing "[NOT-INTERNED][]" "[NOT-INTERNED][]")
    (check-downcasing "[TEST][]" "[`test`][]")
    (check-downcasing "[CLASS][]" "[`class`][46f7]")
    (check-downcasing "[*FORMAT*][]" "[`*format*`][]")
    (check-downcasing "[*PACKAGE*][]" "[`*package*`][1063]")
    (check-downcasing (list "[@SECTION-WITHOUT-TITLE][]"
                            @section-without-title)
                      "[`@section-without-title`][9a4b]"))
  (with-test ("reflink code")
    (check-downcasing "[`NOT-INTERNED`][]" "[`not-interned`][]")
    (check-downcasing "[`TEST`][]" "[`test`][]")
    (check-downcasing "[`CLASS`][]" "[`class`][46f7]")
    (check-downcasing "[`*FORMAT*`][]" "[`*format*`][]")
    (check-downcasing "[`*PACKAGE*`][]" "[`*package*`][1063]")
    (check-downcasing (list "[`@SECTION-WITHOUT-TITLE`][]"
                            @section-without-title)
                      "[`@section-without-title`][9a4b]"))
  (with-test ("multiple symbols")
    (check-downcasing "`(LIST :XXX 'PRINT)`" "`(list :xxx 'print)`")
    (with-failure-expected (t)
      (check-downcasing "`(PRINT \"hello\")`" "`(print \"hello\")`")))
  (with-test ("no-uppercase-is-code")
    (let ((*document-uppercase-is-code* nil))
      (check-downcasing "XXX" "XXX")
      (check-downcasing "`XXX`" "`xxx`")
      (check-downcasing "`(PRINT \"hello\")`" "`(print \"hello\")`"))))

(defsection @parent-section-without-title ()
  (@section-without-title section))

(deftest test-downcasing-of-section-names ()
  (let ((*document-downcase-uppercase-code* t))
    (check-document @parent-section-without-title
                    "<a id='x-28MGL-PAX-TEST-3A-40PARENT-SECTION-WITHOUT-TITLE-20MGL-PAX-3ASECTION-29'></a>

# @parent-section-without-title

## Table of Contents

- [1 @section-without-title][9a4b]

###### \\[in package MGL-PAX-TEST\\]
<a id='x-28MGL-PAX-TEST-3A-40SECTION-WITHOUT-TITLE-20MGL-PAX-3ASECTION-29'></a>

## 1 @section-without-title


  [9a4b]: #x-28MGL-PAX-TEST-3A-40SECTION-WITHOUT-TITLE-20MGL-PAX-3ASECTION-29 \"mgl-pax-test:@section-without-title\"
")))

(defun check-downcasing (docstring expected)
  (let ((*document-downcase-uppercase-code* t))
    (check-one-liner docstring expected)))


(deftest test-link ()
  (test-autolink)
  (test-resolve-reflink)
  (test-explicit-label))


(deftest test-autolink ()
  (with-test ("object with multiple refs")
    (check-one-liner (list "macro BAR function"
                           (make-reference 'bar 'type)
                           (make-reference 'bar 'macro))
                     ;; "9119" is the id of the macro.
                     "macro [`BAR`][9119] function"
                     :msg "locative before, irrelavant locative after")
    (check-one-liner (list "function BAR macro"
                           (make-reference 'bar 'type)
                           (make-reference 'bar 'macro))
                     "function [`BAR`][9119] macro"
                     :msg "locative after, irrelavant locative before")
    (check-one-liner (list "macro BAR type"
                           (make-reference 'bar 'type)
                           (make-reference 'bar 'macro)
                           (make-reference 'bar 'constant))
                     ;; "cece" is the the id of the type.
                     "macro `BAR`([`0`][9119] [`1`][cece]) type"
                     :msg "ambiguous locative"))
  (with-test ("locative in code")
    (check-one-liner (list "`TEST-GF` `(method t (number))`"
                           (make-reference 'test-gf '(method () (number))))
                     "[`TEST-GF`][ba01] `(method t (number))`")
    (check-one-liner (list "`(method t (number))` `TEST-GF`"
                           (make-reference 'test-gf '(method () (number))))
                     "`(method t (number))` [`TEST-GF`][ba01]")))

(deftest test-resolve-reflink ()
  (with-test ("label is a single name")
    (check-one-liner "[*package*][]" "[*package*][]")
    (check-one-liner "[*emphasized*][normaldef]" "[*emphasized*][normaldef]")
    (check-one-liner "[*format*][]" "[*format*][]"))
  (with-test ("definition is a reference")
    (check-one-liner "[see this][car function]" "[see this][86ef]")
    (check-one-liner "[`see` *this*][car function]" "[`see` *this*][86ef]")
    (check-one-liner "[see this][foo2]" "[see this][foo2]")))


(defsection @section-with-title (:title "My Title"))
(define-glossary-term @gt-with-title (:title "My Title") "")

(deftest test-explicit-label ()
  (with-test ("section")
    (check-downcasing (list "@SECTION-WITH-TITLE" @section-with-title)
                      "[My Title][224f]")
    (check-downcasing (list "`@SECTION-WITH-TITLE`" @section-with-title)
                      "[My Title][224f]")
    (check-downcasing (list "[@SECTION-WITH-TITLE][]" @section-with-title)
                      "[My Title][224f]")
    (check-downcasing (list "[`@SECTION-WITH-TITLE`][]" @section-with-title)
                      "[My Title][224f]"))
  (with-test ("glossary-term")
    (check-downcasing (list "@GT-WITH-TITLE" @gt-with-title)
                      "[My Title][cf05]")
    (check-downcasing (list "`@GT-WITH-TITLE`" @gt-with-title)
                      "[My Title][cf05]")
    (check-downcasing (list "[@GT-WITH-TITLE][]" @gt-with-title)
                      "[My Title][cf05]")
    (check-downcasing (list "[`@GT-WITH-TITLE`][]" @gt-with-title)
                      "[My Title][cf05]")))


(deftest test-macro ()
  (test-macro/canonical-reference)
  (test-macro/arglist))

(setf (macro-function 'setfed-macro)
      (lambda (whole env)
        (declare (ignore whole env))))

(deftest test-macro/canonical-reference ()
  (let ((ref (make-reference 'setfed-macro 'macro)))
    (is (mgl-pax::reference= (canonical-reference ref) ref))))

(defmacro macro-with-fancy-args (x &optional (o 1) &key (k 2 kp))
  (declare #+sbcl (sb-ext:muffle-conditions style-warning)
           (ignore x o k kp))
  ())

(deftest test-macro/arglist ()
  (with-failure-expected ((alexandria:featurep '(:or :allegro)))
    (is (or (equal (% (mgl-pax::arglist 'macro-with-fancy-args))
                   '(x &optional (o 1) &key (k 2 kp)))
            (equal (mgl-pax::arglist 'macro-with-fancy-args)
                   '(x &optional (o 1) &key (k 2)))))))


(defsection @test-symbol-macro ()
  (my-smac symbol-macro))

(define-symbol-macro my-smac 42)
(setf (documentation 'my-smac 'symbol-macro)
      "This is MY-SMAC.")

(deftest test-symbol-macro ()
  (progn;with-failure-expected ((alexandria:featurep '(:or :abcl :allegro)))
    (is (null (mismatch% (let ((*document-max-table-of-contents-level* 0)
                               (*document-max-numbering-level* 0)
                               (*document-text-navigation* nil)
                               (*document-link-sections* nil))
                           (first (document @test-symbol-macro)))
                         "# @TEST-SYMBOL-MACRO

###### \\[in package MGL-PAX-TEST\\]
<a id='x-28MGL-PAX-TEST-3AMY-SMAC-20MGL-PAX-3ASYMBOL-MACRO-29'></a>

- [symbol-macro] **MY-SMAC**

    This is `MY-SMAC`.
")))))


(deftest test-function ()
  (test-function/canonical-reference)
  (test-function/arglist))

(setf (symbol-function 'setfed-function)
      (lambda ()))

(deftest test-function/canonical-reference ()
  (let ((ref (make-reference 'setfed-function 'function)))
    (is (mgl-pax::reference= (canonical-reference ref) ref))))

(defun function-with-fancy-args (x &optional (o 1) &key (k 2 kp))
  (declare #+sbcl (sb-ext:muffle-conditions style-warning)
           (ignore x o k kp))
  nil)

(deftest test-function/arglist ()
  (with-failure-expected ((alexandria:featurep :ccl))
    (is (equal (mgl-pax::arglist 'function-with-fancy-args)
               '(x &optional (o 1) &key (k 2 kp))))))


(setf (symbol-function 'setfed-generic-function)
      (lambda ()))

(deftest test-generic-function ()
  (let ((ref (make-reference 'setfed-generic-function 'function)))
    (is (mgl-pax::reference= (canonical-reference ref) ref))))


(defsection @test-method-combination ()
  (my-comb method-combination))

(define-method-combination my-comb :identity-with-one-argument t
  :documentation "This is MY-COMB.")

(deftest test-method-combination ()
  (with-failure-expected ((alexandria:featurep '(:or :abcl :allegro)))
    (is (null (mismatch% (let ((*document-max-table-of-contents-level* 0)
                               (*document-max-numbering-level* 0)
                               (*document-text-navigation* nil)
                               (*document-link-sections* nil))
                           (first (document @test-method-combination)))
                         "# @TEST-METHOD-COMBINATION

###### \\[in package MGL-PAX-TEST\\]
<a id='x-28MGL-PAX-TEST-3AMY-COMB-20METHOD-COMBINATION-29'></a>

- [method-combination] **MY-COMB**

    This is `MY-COMB`.
")))))


(deftest test-hyperspec ()
  (check-one-liner "FIND-IF" "[`FIND-IF`][badc]")
  (check-one-liner "LIST" "`LIST`([`0`][df43] [`1`][7def])")
  (check-one-liner "[LIST][type]" "[`LIST`][7def]")
  (check-one-liner "T" "`T`")
  (check-one-liner "NIL" "`NIL`")
  (check-one-liner "[T][]" "`T`([`0`][b743] [`1`][cb19])")
  (check-one-liner "[T][constant]" "[`T`][b743]"))


(deftest test-clhs-section ()
  ;; "A.1" and "3.4" are section names in the CLHS.
  (check-one-liner "A.1" "A.1")
  (check-one-liner "`A.1`" "`A.1`")
  (check-one-liner "CLHS A.1" "`CLHS` A.1")
  (check-one-liner "CLHS 3.4" "`CLHS` 3.4")
  (check-one-liner "CLHS `3.4`" "`CLHS` [`3.4`][76476]")
  (check-one-liner "`3.4` CLHS" "[`3.4`][76476] `CLHS`")
  (check-one-liner "[3.4][]" "[3.4][76476]")
  (check-one-liner "[`3.4`][]" "[`3.4`][76476]")
  (check-one-liner "[3.4][CLHS]" "[3.4][76476]")
  (check-one-liner "[Lambda Lists][clhs]" "[Lambda Lists][76476]")
  (check-one-liner "[03_d][clhs]" "[03\\_d][76476]"))


(deftest test-clhs-issue ()
  (check-one-liner "ISSUE:AREF-1D" "ISSUE:AREF-1D")
  (check-one-liner "`ISSUE:AREF-1D`" "`ISSUE:AREF-1D`")
  (check-one-liner "CLHS ISSUE:AREF-1D" "`CLHS` ISSUE:AREF-1D")
  (check-one-liner "ISSUE:AREF-1D CLHS" "ISSUE:AREF-1D `CLHS`")
  (check-one-liner "CLHS `ISSUE:AREF-1D`" "`CLHS` [`ISSUE:AREF-1D`][3e36]")
  (check-one-liner "`ISSUE:AREF-1D` CLHS" "[`ISSUE:AREF-1D`][3e36] `CLHS`")
  (check-one-liner "[ISSUE:AREF-1D][]" "[ISSUE:AREF-1D][3e36]")
  (check-one-liner "[`ISSUE:AREF-1D`][]" "[`ISSUE:AREF-1D`][3e36]")
  (check-one-liner "[ISSUE:AREF-1D][CLHS]" "[ISSUE:AREF-1D][3e36]")
  (check-one-liner "[iss009][clhs]" "[iss009][eed0]"))


(defsection @argument-test ()
  "[PRINT][argument]

   PRINT argument")

(deftest test-argument ()
  (is
   (null
    (mismatch%
     (let ((*document-max-table-of-contents-level* 0)
           (*document-max-numbering-level* 0)
           (*document-text-navigation* nil)
           (*document-link-sections* nil))
       (first (document @argument-test)))
     "# @ARGUMENT-TEST

###### \\[in package MGL-PAX-TEST\\]
`PRINT`

`PRINT` argument
"))))


(deftest test-declaration ()
  (check-one-liner "SAFETY" "[`SAFETY`][9f0e]")
  (check-one-liner "SAFETY declaration" "[`SAFETY`][9f0e] declaration")
  (check-one-liner "[safety][declaration]" "[safety][9f0e]"))


(deftest test-readtable ()
  (with-failure-expected ((alexandria:featurep :abcl))
    (check-document (named-readtables:find-readtable 'xxx-rt)
                    "<a id='x-28MGL-PAX-TEST-3A-3AXXX-RT-20READTABLE-29'></a>

- [readtable] **XXX-RT**

    ddd
"))
  (check-one-liner (list "[XXX-RT][readtable]"
                         (named-readtables:find-readtable 'xxx-rt))
                   "[`XXX-RT`][9ac2]"))


(defsection @test-package ()
  "INTERNED-PKG-NAME"
  "NON-INTERNED-PKG-NAME"
  "[NON-INTERNED-PKG-NAME][]"
  "[NON-INTERNED-PKG-NAME][package]"
  (interned-pkg-name package)
  (#:non-interned-pkg-name package))

(defpackage interned-pkg-name)
(defpackage #:non-interned-pkg-name)

(deftest test-package ()
  (is
   (null
    (mismatch%
     (let ((*document-max-table-of-contents-level* 0)
           (*document-max-numbering-level* 0)
           (*document-text-navigation* nil)
           (*document-link-sections* nil))
       (first (document @test-package)))
     "# @TEST-PACKAGE

###### \\[in package MGL-PAX-TEST\\]
[`INTERNED-PKG-NAME`][2509]

[`NON-INTERNED-PKG-NAME`][11d0]

[`NON-INTERNED-PKG-NAME`][11d0]

[`NON-INTERNED-PKG-NAME`][11d0]

<a id='x-28-22INTERNED-PKG-NAME-22-20PACKAGE-29'></a>

- [package] **\"INTERNED-PKG-NAME\"**

<a id='x-28-22NON-INTERNED-PKG-NAME-22-20PACKAGE-29'></a>

- [package] **\"NON-INTERNED-PKG-NAME\"**

  [11d0]: #x-28-22NON-INTERNED-PKG-NAME-22-20PACKAGE-29 \"(\\\"NON-INTERNED-PKG-NAME\\\" PACKAGE)\"
  [2509]: #x-28-22INTERNED-PKG-NAME-22-20PACKAGE-29 \"(\\\"INTERNED-PKG-NAME\\\" PACKAGE)\"
"))))


(defsection @test-asdf-system ()
  "MGL-PAX/FULL"
  "MGL-PAX/TEST"
  "[MGL-PAX/TEST][]"
  "[MGL-PAX/TEST][asdf:system]"
  (mgl-pax/full asdf:system)
  (#:mgl-pax/test asdf:system))

(deftest test-asdf-system ()
  (is (find-symbol (string '#:mgl-pax/full) '#:mgl-pax-test))
  (is (null (find-symbol (string '#:mgl-pax/test) '#:mgl-pax-test)))
  (is
   (null
    (mismatch%
     (let ((*document-max-table-of-contents-level* 0)
           (*document-max-numbering-level* 0)
           (*document-text-navigation* nil)
           (*document-link-sections* nil)
           (mgl-pax::*omit-asdf-slots* t))
       (first (document @test-asdf-system)))
     "# @TEST-ASDF-SYSTEM

###### \\[in package MGL-PAX-TEST\\]
[`MGL-PAX/FULL`][0785]

[`MGL-PAX/TEST`][4b83]

[`MGL-PAX/TEST`][4b83]

[`MGL-PAX/TEST`][4b83]

## MGL-PAX/FULL ASDF System Details


## MGL-PAX/TEST ASDF System Details


  [0785]: #x-28-22mgl-pax-2Ffull-22-20ASDF-2FSYSTEM-3ASYSTEM-29 \"(\\\"mgl-pax/full\\\" ASDF/SYSTEM:SYSTEM)\"
  [4b83]: #x-28-22mgl-pax-2Ftest-22-20ASDF-2FSYSTEM-3ASYSTEM-29 \"(\\\"mgl-pax/test\\\" ASDF/SYSTEM:SYSTEM)\"
"))))


(deftest test-all ()
  (test-transcribe)
  (test-navigation)
  (test-read-locative-from-string)
  (test-read-reference-from-string)
  (test-transform-tree)
  (test-macro-arg-names)
  (test-codify)
  (test-plural)
  (test-downcasing)
  (test-link)
  (test-document :markdown)
  (test-document :html)
  (test-function)
  (test-generic-function)
  (test-macro)
  (test-symbol-macro)
  (test-method-combination)
  (test-hyperspec)
  (test-clhs-section)
  (test-clhs-issue)
  (test-argument)
  (test-declaration)
  (test-readtable)
  (test-package)
  (test-asdf-system))

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

(deftest test-trimming ()
  (check-one-liner "`#<CLASS>`" "`#<CLASS>`")
  (check-one-liner "#<CLASS>" "#<[`CLASS`][46f7]>"))

#+nil
(is (equal
     (let ((delimiteds ()))
       (is (equal
            (mgl-pax::map-names "hello world"
                                (lambda (string start end)
                                  (push (subseq string start end) delimiteds)
                                  nil))
            '("hello world")))
       (reverse delimiteds))
     '("hello" "world")))

#+nil
(is (equal
     (mgl-pax::map-names "hello world"
                         (lambda (string start end)
                           (if (zerop start)
                               (values "hi" nil nil)
                               nil)))
     '("hi world")))

#+nil
(is (equal
     (mgl-pax::map-names "hello world"
                         (lambda (string start end)
                           (let ((word (subseq string start end)))
                             (when (string= word "hello")
                               (values "hi" nil 2)))))
     '("hillo world")))

#+nil
(let ((words ()))
  (is (equal
       (mgl-pax::map-names "hello world"
                           (lambda (string start end)
                             (let ((word (subseq string start end)))
                               (push word words)
                               (when (string= word "hello")
                                 (values "hi" nil 2)))))
       '("hillo world")))
  (is (equal (reverse words) '("hello" "world"))))

#+nil
(let ((words ()))
  (is (equal
       (mgl-pax::map-names "hello world"
                           (lambda (string start end)
                             (let ((word (subseq string start end)))
                               (push word words)
                               (when (string= word "hello")
                                 (values "hi " nil 2)))))
       '("hi llo world")))
  (is (equal (reverse words) '("hello" "llo" "world"))))
