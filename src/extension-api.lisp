(in-package :mgl-pax)

(in-readtable pythonic-string-syntax)

(defsection @mgl-pax-extension-api (:title "Extension API")
  (@mgl-pax-locatives-and-references section)
  (@mgl-pax-new-object-types section)
  (@mgl-pax-reference-based-extensions section)
  (@mgl-pax-sections section))


(defsection @mgl-pax-new-object-types (:title "Adding New Object Types")
  "One may wish to make the DOCUMENT function and `M-.` navigation
  work with new object types. Extending DOCUMENT can be done by
  defining a DOCUMENT-OBJECT method. To allow these objects to be
  referenced from DEFSECTION, a LOCATE-OBJECT method is to be defined.
  For `M-.` FIND-SOURCE can be specialized. Finally,
  EXPORTABLE-LOCATIVE-TYPE-P may be overridden if exporting does not
  makes sense. Here is a stripped down example of how all this is done
  for ASDF:SYSTEM:"
  (asdf-example (include (:start (asdf:system locative)
                          :end (end-of-asdf-example variable))
                         :header-nl "```commonlisp"
                         :footer-nl "```"))
  (define-locative-type macro)
  (define-locative-alias macro)
  (exportable-locative-type-p generic-function)
  (locate-object generic-function)
  (locate-error function)
  (canonical-reference generic-function)
  (collect-reachable-objects generic-function)
  (collect-reachable-objects (method () (t)))
  (*format* variable)
  (document-object generic-function)
  (document-object (method () (string t)))
  (find-source generic-function))

(defmacro define-locative-type (locative-type lambda-list &body docstring)
  """Declare LOCATIVE-TYPE as a [LOCATIVE][locative]. One gets two
  things in return: first, a place to document the format and
  semantics of LOCATIVE-TYPE (in LAMBDA-LIST and DOCSTRING); second,
  being able to reference `(LOCATIVE-TYPE LOCATIVE)`. For example, if
  you have:

  ```common-lisp
  (define-locative-type variable (&optional initform)
    "Dummy docstring.")
  ```

  then `(VARIABLE LOCATIVE)` refers to this form."""
  (assert (or (endp docstring)
              (and (= 1 (length docstring))
                   (string (first docstring)))))
  `(defmethod locative-lambda-list ((symbol (eql ',locative-type)))
     ,@docstring
     ',lambda-list))

(defmacro define-locative-alias (alias locative-type)
  """Define ALIAS as a locative equivalent to LOCATIVE-TYPE (both
  SYMBOLs). The following example shows how to make docstrings read
  more naturally by defining an alias.

  ```common-lisp
  (defclass my-string ()
    ())

  (defgeneric my-string (obj)
    (:documentation "Convert OBJ to MY-STRING."))

  ;;; This version of FOO has a harder to read docstring because
  ;;; it needs to disambiguate the MY-STRING reference.
  (defun foo (x)
    "FOO takes and argument X, a [MY-STRING][class] object.")

  ;;; Define OBJECT as an alias for the CLASS locative.
  (define-locative-alias object class)

  ;;; Note how no explicit link is needed anymore.
  (defun foo (x)
    "FOO takes an argument X, a MY-CLASS object.")
  ```
  """
  `(progn
     (define-locative-type ,alias ()
       ,(format nil "An alias for the ~S locative." locative-type))
     (defmethod locate-object (symbol (locative-type (eql ',alias))
                               locative-args)
       (locate-object symbol ',locative-type locative-args))
     (defmethod canonical-locative ((locative-type (eql ',alias))
                                    locative-args)
       (cons ',locative-type locative-args))))

;;; A somewhat dummy generic function on which the docstring can be
;;; hung and which provides a source location. It returns LAMBDA-LIST
;;; from DEFINE-LOCATIVE-TYPE.
(defgeneric locative-lambda-list (symbol))

(defgeneric locate-object (object locative-type locative-args)
  (:documentation "Return the object to which OBJECT and the locative
  refer. For example, if LOCATIVE-TYPE is the symbol
  [PACKAGE][dislocated], this returns `(FIND-PACKAGE SYMBOL)`. Signal
  a LOCATE-ERROR condition by calling the LOCATE-ERROR function if the
  lookup fails. Signal other errors if the types of the argument are
  bad, for instance LOCATIVE-ARGS is not the empty list in the package
  example. If a REFERENCE is returned then it must be canonical in the
  sense that calling CANONICAL-REFERENCE on it will return the same
  reference. For extension only, don't call this directly.")
  (:method (object locative-type locative-args)
    (locate-error object (cons locative-type locative-args))))

(defun locate-error (object locative &rest format-and-args)
  "Call this function to signal a LOCATE-ERROR condition from a
  LOCATE-OBJECT method. FORMAT-AND-ARGS contains a format string and
  args suitable for FORMAT from which the LOCATE-ERROR-MESSAGE is
  constructed. If FORMAT-AND-ARGS is NIL, then the message will be NIL
  too.

  The object and the locative are not specified, they are added by
  LOCATE when it resignals the condition."
  (error 'locate-error :object object :locative locative
         :message (if format-and-args
                      (apply #'format nil format-and-args)
                      nil)))

(defgeneric canonical-reference (object)
  (:documentation "Return a REFERENCE that resolves to OBJECT. Signals
  LOCATE-ERROR if it is not possible to construct a REFERENCE for
  OBJECT."))

(defgeneric locate-canonical-reference (object locative-type locative-args))

(defmethod locate-canonical-reference (object locative-type locative-args)
  (handler-case
      (let ((located (locate-object object locative-type locative-args)))
        (if (typep located 'reference)
            ;; If the locative is (COMPILER-MACRO) for example, then
            ;; turn it into a single symbol.
            (let ((locative (reference-locative located)))
              (if (and (listp locative) (= (length locative) 1))
                  (make-reference (reference-object located)
                                  (first locative))
                  located))
            (canonical-reference located)))
    (locate-error ()
      ;; DISLOCATED and ARGUMENT end up here
      (make-reference object (cons locative-type locative-args)))))

(defmethod canonical-reference ((reference reference))
  (locate-canonical-reference (reference-object reference)
                              (reference-locative-type reference)
                              (reference-locative-args reference)))

(defgeneric canonical-locative (locative-type locative-args))

(defmethod canonical-locative (locative-type locative-args)
  (cons locative-type locative-args))

(defgeneric collect-reachable-objects (object)
  (:documentation "Return a list of objects representing all things
  that would be documented in a (DOCUMENT OBJECT) call. For sections
  this is simply the union of references reachable from references in
  SECTION-ENTRIES. The returned objects can be anything provided that
  CANONICAL-REFERENCE works on them. The list need not include OBJECT
  itself.

  One only has to specialize this for new container-like objects."))

(defmethod collect-reachable-objects (object)
  "This default implementation returns the empty list. This means that
  nothing is reachable from OBJECT."
  (declare (ignore object))
  ())

(defgeneric document-object (object stream)
  (:documentation "Write OBJECT (and its references recursively) in
  *FORMAT* to STREAM.

  Add methods specializing on OBJECT to customize how objects of that
  type are presented in the documentation."))

(defmethod document-object ((string string) stream)
  "Print STRING verbatim to STREAM after cleaning up indentation.

  Docstrings in sources are indented in various ways, which can easily
  mess up markdown. To handle the most common cases leave the first
  line alone, but from the rest of the lines strip the longest run of
  leading spaces that is common to all non-blank lines."
  (format stream "~a~%"
          (massage-docstring string :indentation "")))

;;; This is bound to an EQUAL hash table in MAKE-GITHUB-SOURCE-URI-FN
;;; to speed up FIND-SOURCE. It's still very slow though.
(defvar *find-source-cache* nil)

(defgeneric find-source (object)
  (:documentation """Like SWANK:FIND-DEFINITION-FOR-THING, but this
  one is a generic function to be extensible. In fact, the default
  implementation simply defers to SWANK:FIND-DEFINITION-FOR-THING.
  This function is called by LOCATE-DEFINITIONS-FOR-EMACS, which lies
  behind the `M-.` extension (see @MGL-PAX-NAVIGATING-IN-EMACS).

  If successful, the return value looks like this:

  ```commonlisp
  (:location (:file "/home/mega/own/mgl/pax/test/test.lisp")
             (:position 24) nil)
  ```

  The NIL is the source snippet, which is optional. Note that position
  1 is the first character. If unsuccessful, the return value is
  like:

  ```commonlisp
  (:error "Unknown source location for SOMETHING")
  ```""")
  (:method :around (object)
    (if *find-source-cache*
        (let ((key (if (typep object 'reference)
                       (list (reference-object object)
                             (reference-locative object))
                       object)))
          (or (gethash key *find-source-cache*)
              (setf (gethash key *find-source-cache*)
                    (call-next-method))))
        (call-next-method)))
  (:method (object)
    (swank:find-definition-for-thing object)))

;;; A utility for writing FIND-SOURCE methods. Try FILTER-STRINGS one
;;; by one, and if one matches exactly one of LOCATIONS, then return
;;; that location. Matching is performed by substring search on the
;;; stringified first element of the location.
(defun find-one-location (locations filter-strings)
  (let ((n-matches ()))
    (loop for filter-string in filter-strings
          do (let ((filtered-locations
                     (filter-locations locations filter-string)))
               (cond ((= 1 (length filtered-locations))
                      ;; A location looks like this in SBCL:
                      ;;
                      ;; ((DEFVAR *FOO*)
                      ;;  (:LOCATION
                      ;;   (:BUFFER-AND-FILE "pax.lisp"
                      ;;    "/home/mega/own/mgl/pax/src/pax.lisp")
                      ;;   (:OFFSET 106 0) (:SNIPPET "(defvar *foo*)")))
                      (return-from find-one-location
                        (second (first filtered-locations))))
                     (t
                      (push (length filtered-locations) n-matches)))))
    (error "~@<Could not find a single location in with filters ~S. ~
           Number of matches for each filter ~S.~:@>"
           filter-strings n-matches)))

(defun filter-locations (locations filter-string)
  (remove-if-not (lambda (location)
                   (let ((location-as-string
                           (prin1-to-string (first location))))
                     (search filter-string location-as-string
                             :test #'equalp)))
                 locations))


(defsection @mgl-pax-reference-based-extensions
    (:title "Reference Based Extensions")
  "Let's see how to extend DOCUMENT and `M-.` navigation if there is
  no first class object to represent the thing of interest. Recall
  that LOCATE returns a REFERENCE object in this case. DOCUMENT-OBJECT
  and FIND-SOURCE defer to LOCATE-AND-DOCUMENT and
  LOCATE-AND-FIND-SOURCE, which have LOCATIVE-TYPE in their argument
  list for [EQL][type] specializing pleasure. Here is a stripped down
  example of how the VARIABLE locative is defined:"
  (variable-example (include (:start (variable locative)
                                     :end (end-of-variable-example variable))
                             :header-nl "```commonlisp"
                             :footer-nl "```"))
  (collect-reachable-objects (method () (reference)))
  (locate-and-collect-reachable-objects generic-function)
  (locate-and-collect-reachable-objects (method () (t t t)))
  (document-object (method () (reference t)))
  (locate-and-document generic-function)
  (find-source (method () (reference)))
  (locate-and-find-source generic-function)
  "We have covered the basic building blocks of reference based
  extensions. Now let's see how the obscure
  DEFINE-SYMBOL-LOCATIVE-TYPE and
  DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE macros work together to
  simplify the common task of associating definition and documentation
  with symbols in a certain context."
  (define-symbol-locative-type macro)
  (define-definer-for-symbol-locative-type macro))

(defmethod collect-reachable-objects ((reference reference))
  "If REFERENCE can be resolved to a non-reference, call
  COLLECT-REACHABLE-OBJECTS with it, else call
  LOCATE-AND-COLLECT-REACHABLE-OBJECTS on the object, locative-type,
  locative-args of REFERENCE"
  (let ((object (resolve reference)))
    (if (typep object 'reference)
        (let ((locative (reference-locative reference)))
          (locate-and-collect-reachable-objects (reference-object reference)
                                                (locative-type locative)
                                                (locative-args locative)))
        (collect-reachable-objects object))))

(defgeneric locate-and-collect-reachable-objects (object locative-type
                                                  locative-args)
  (:documentation "Called by COLLECT-REACHABLE-OBJECTS on REFERENCE
  objects, this function has essentially the same purpose as its
  caller but it has different arguments to allow specializing on
  LOCATIVE-TYPE."))

(defmethod locate-and-collect-reachable-objects (object locative-type
                                                 locative-args)
  "This default implementation returns the empty list. This means that
  nothing is reachable from the reference."
  (declare (ignore object locative-type locative-args))
  ())

(defgeneric locate-and-document (object locative-type locative-args
                                 stream)
  (:documentation "Called by DOCUMENT-OBJECT on REFERENCE objects,
  this function has essentially the same purpose as DOCUMENT-OBJECT
  but it has different arguments to allow specializing on
  LOCATIVE-TYPE."))

(defmethod find-source ((reference reference))
  "If REFERENCE can be resolved to a non-reference, call FIND-SOURCE
  with it, else call LOCATE-AND-FIND-SOURCE on the object,
  locative-type, locative-args of REFERENCE"
  (let ((locative (reference-locative reference)))
    (locate-and-find-source (reference-object reference)
                            (locative-type locative)
                            (locative-args locative))))

(defgeneric locate-and-find-source (object locative-type locative-args)
  (:documentation "Called by FIND-SOURCE on REFERENCE objects, this
  function has essentially the same purpose as FIND-SOURCE but it has
  different arguments to allow specializing on LOCATIVE-TYPE."))

(defvar *locative-source-search-list* ())

(defun add-locative-to-source-search-list (locative)
  "Some locatives are implemented in terms of Lisp types, for which
  Slime's `M-.` finds source code of the corresponding definition out
  of the box. For example, SECTIONs are simply global variables. To be
  able to list all definitions that belong to a name, we register
  locatives to try with ADD-LOCATIVE-TO-SOURCE-SEARCH-LIST."
  (pushnew locative *locative-source-search-list* :test #'equal))

(defmacro define-symbol-locative-type (locative-type lambda-list
                                       &body docstring)
  """Similar to DEFINE-LOCATIVE-TYPE but it assumes that all things
  locatable with LOCATIVE-TYPE are going to be just symbols defined
  with a definer defined with DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE.
  It is useful to attach documentation and source location to symbols
  in a particular context. An example will make everything clear:

  ```commonlisp
  (define-symbol-locative-type direction ()
    "A direction is a symbol. (After this `M-.` on `DIRECTION LOCATIVE`
    works and it can also be included in DEFSECTION forms.)")

  (define-definer-for-symbol-locative-type define-direction direction
    "With DEFINE-DIRECTION one can document what a symbol means when
    interpreted as a direction.")

  (define-direction up ()
    "UP is equivalent to a coordinate delta of (0, -1).")
  ```

  After all this, `(UP DIRECTION)` refers to the `DEFINE-DIRECTION`
  form above."""
  (check-body-docstring docstring)
  `(progn
     (define-locative-type ,locative-type ,lambda-list ,@docstring)
     (defmethod locate-object
         (symbol (locative-type (eql ',locative-type)) locative-args)
       (or (symbol-lambda-list-method symbol ',locative-type)
           (locate-error symbol (cons ',locative-type locative-args)))
       (make-reference symbol (cons locative-type locative-args)))
     (defmethod locate-and-document
         (symbol (locative-type (eql ',locative-type)) locative-args stream)
       (let ((method (symbol-lambda-list-method symbol ',locative-type))
             (lambda-list (symbol-lambda-list symbol ',locative-type)))
         (locate-and-print-bullet locative-type locative-args symbol stream)
         (with-local-references ((list (make-reference symbol
                                                       (cons locative-type
                                                             locative-args))))
             (with-dislocated-symbols ((macro-arg-names lambda-list))
               (when lambda-list
                 (write-char #\Space stream)
                 (print-arglist lambda-list stream))
               (print-end-bullet stream)
               (maybe-print-docstring method t stream))))
       (format stream "~&"))
     (defmethod locate-and-find-source
         (symbol (locative-type (eql ',locative-type)) locative-args)
       (declare (ignore locative-args))
       (find-source (symbol-lambda-list-method symbol ',locative-type)))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun check-body-docstring (docstring)
    (assert (or (endp docstring)
                (and (= 1 (length docstring))
                     (string (first docstring)))))))

;;; A somewhat dummy generic function whose methods are
;;; eql-specialized on SYMBOL and LOCATIVE-TYPE. The appropriate
;;; method's docstring is the docstring of SYMBOL as LOCATIVE-TYPE. As
;;; an afterthought, this method also returns the LAMBDA-LIST given in
;;; the definition.
(defgeneric symbol-lambda-list (symbol locative-type))

(defun symbol-lambda-list-method (symbol locative-type)
  (find-method #'symbol-lambda-list () `((eql ,symbol) (eql ,locative-type))
               nil))

(defmacro define-definer-for-symbol-locative-type
    (name locative-type &body docstring)
  "Define a macro with NAME which can be used to attach documentation,
  a lambda-list and source location to a symbol in the context of
  LOCATIVE-TYPE. The defined macro's arglist is (SYMBOL LAMBDA-LIST
  &OPTIONAL DOCSTRING). LOCATIVE-TYPE is assumed to have been defined
  with DEFINE-SYMBOL-LOCATIVE-TYPE."
  `(defmacro ,name (symbol lambda-list &body docstring)
     ,@docstring
     `,(expand-define-definer-for-symbol-as-locative-definer-body
        symbol ',locative-type lambda-list docstring)))

(defun expand-define-definer-for-symbol-as-locative-definer-body
    (symbol locative-type lambda-list docstring)
  `(defmethod symbol-lambda-list ((symbol (eql ',symbol))
                                  (locative-type (eql ',locative-type)))
     ,@docstring
     ',lambda-list))


(defsection @mgl-pax-sections (:title "Sections")
  "[Section][class] objects rarely need to be dissected since
  DEFSECTION and DOCUMENT cover most needs. However, it is plausible
  that one wants to subclass them and maybe redefine how they are
  presented."
  (section class)
  (section-name (reader section))
  (section-package (reader section))
  (section-readtable (reader section))
  (section-title (reader section))
  (section-link-title-to (reader section))
  (section-entries (reader section))
  (describe-object (method () (section t))))
