(in-package :mgl-pax)

(in-readtable pythonic-string-syntax)

;;;; Text based markdown fragments

(defun parse-markdown (string)
  (let ((3bmd-grammar:*smart-quotes* nil))
    ;; To be able to recognize symbols like FOO* join (... "FOO" "*"
    ;; ...) to look like (... "FOO*" ...).
    (join-consecutive-non-blank-strings-in-parse-tree
     (parse-markdown-fast string))))

(defun parse-markdown-fast (string)
  (if (< (length string) 1000)
      (3bmd-grammar:parse-doc string)
      ;; This is 3BMD-GRAMMAR:PARSE-DOC's currently commented out
      ;; alternative implementation, which is much faster on long
      ;; strings but perhaps slower on short strings. This still has a
      ;; performance problem with large lists, which are processed in
      ;; one %BLOCK, hence the workaround in PAX-APROPOS*.
      (progn
        ;; (format t "PMF ~S~%" (length string))
        (loop
          for start = 0 then pos
          for (%block pos) = (multiple-value-list
                              (esrap:parse
                               (if (esrap:find-rule '3bmd-grammar::%block)
                                   '3bmd-grammar::%block
                                   ;; Make it work with old 3BMD.
                                   '3bmd-grammar::block)
                               string :start start :junk-allowed t))
          ;; do (format t "PMF  ~S~%" pos)
          while %block
          collect %block
          while pos))))

(defmacro with-colorize-silenced (() &body body)
  `(let ((*trace-output* (make-broadcast-stream)))
     ,@body))

(defun print-markdown (parse-tree stream &key (format :markdown))
  (with-colorize-silenced ()
    (3bmd::print-doc-to-stream-using-format parse-tree stream format)))

(defun heading (level stream)
  (loop repeat (1+ level) do (write-char #\# stream)))

(defun code (string)
  (if (zerop (length string))
      ""
      (format nil "`~A`" string)))

(defun bold (string stream)
  (if (zerop (length string))
      ""
      (format stream "**~A**" string)))

(defun italic (string stream)
  (if (zerop (length string))
      ""
      (format stream "*~A*" string)))

(defun markdown-special-char-p (char)
  (member char '(#\* #\_ #\` #\< #\> #\[ #\])))

(defun/autoloaded escape-markdown (string &key (escape-newline t))
  "Construct a new string from STRING by adding a backslash before
  special markdowns character

      *_`<>[]

  and newline if ESCAPE-NEWLINE."
  (with-output-to-string (stream)
    (dotimes (i (length string))
      (let ((char (aref string i)))
        (when (or (markdown-special-char-p char)
                  (and escape-newline
                       (char= char #\Newline)))
          (write-char #\\ stream))
        (write-char char stream)))))

(defun unescape-markdown (string)
  (let ((escaping nil))
    (with-output-to-string (stream)
      (dotimes (i (length string))
        (let ((char (aref string i)))
          (cond (escaping
                 (setq escaping nil)
                 (write-char char stream))
                ((eql char #\\)
                 (setq escaping t))
                (t
                 (write-char char stream))))))))

;;; This is a workaround for "\"mgl-pax\" ASFD:SYSTEM" being displayed
;;; with the backslashes.
(defun escape-markdown-reflink-definition-title (string)
  (cond ((not (find #\" string))
         (format nil "~S" string))
        ((not (find #\' string))
         (format nil "'~A'" string))
        ((not (find #\) string))
         (format nil "(~A)" string))
        (t
         (format nil "~S" string))))


;;;; Parse tree based markdown fragments

(declaim (inline parse-tree-tag-p))
(defun parse-tree-p (parse-tree tag)
  (and (listp parse-tree)
       (eq (first parse-tree) tag)))

(defmacro pt-get (parse-tree attr)
  `(getf (rest ,parse-tree) ,attr))

(defun code-fragment (string)
  `(:code ,(princ-to-string string)))

(defun indent-verbatim (tree)
  (assert (eq (first tree) :verbatim))
  `(:verbatim ,(prefix-lines "  " (second tree))))

(defun indent-code-block (tree)
  (assert (eq (first tree) '3bmd-code-blocks::code-block))
  (let ((tree (copy-list tree)))
    (setf (pt-get tree :content)
          (prefix-lines "  " (pt-get tree :content)))
    tree))

(defun parse-tree-to-text (parse-tree &key deemph)
  (labels
      ((recurse (e)
         (cond ((stringp e)
                ;; "S" -> "S"
                e)
               ((and (listp e)
                     (or (stringp (first e))
                         (listp (first e))))
                ;; ("mgl-pax-test:" (:EMPH "test-variable")) =>
                ;; "mgl-pax-test:*test-variable*"
                (apply #'concatenate 'string (mapcar #'recurse e)))
               ;; Recurse into (:PLAIN ...)
               ((parse-tree-p e :plain)
                (format nil "~A" (recurse (rest e))))
               ;; (:EMPH "S") -> "*S*"
               ((and deemph (parse-tree-p e :emph))
                (format nil "*~A*" (recurse (rest e))))
               ;; (:CODE "S") -> "S"
               ((parse-tree-p e :code)
                (let ((string (second e)))
                  (cond ((alexandria:starts-with-subseq "\\\\" string)
                         (recurse (subseq string 2)))
                        ((alexandria:starts-with-subseq "\\" string)
                         (recurse (subseq string 1)))
                        (t
                         (recurse string)))))
               (t
                (return-from parse-tree-to-text nil)))))
    (recurse parse-tree)))


;;;; Markdown parse tree transformation

;;; Perform a depth-first traversal of TREE. Call FN with the parent
;;; of each node and the node itself. FN returns three values:
;;;
;;; 1. New tree: It's substituted for the node.
;;;
;;; 2. Recurse flag: If recurse and the new tree is not a leaf, then
;;;    traversal recurses into the new tree.
;;;
;;; 3. Slice flag: If slice, then instead of add the new tree as an
;;;    element to the transformed output (of the parent), all elements
;;;    of new tree (which must be a LIST) are added. No slice is like
;;;    MAPCAR, slice is is MAPCAN.
(defun transform-tree (fn tree)
  (labels ((foo (parent tree)
             (multiple-value-bind (new-tree recurse slice)
                 (funcall fn parent tree)
               (assert (or (not slice) (listp new-tree)))
               (if (or (atom new-tree)
                       (not recurse))
                   (values new-tree slice)
                   (values (loop for sub-tree in new-tree
                                 append (multiple-value-bind
                                              (new-sub-tree slice)
                                            (foo new-tree sub-tree)
                                          (if slice
                                              new-sub-tree
                                              (list new-sub-tree))))
                           slice)))))
    (foo nil tree)))

;;; When used as the FN argument to TRANSFORM-TREE, leave the tree
;;; intact except for subtrees (lists) whose CAR is in TAGS, whose
;;; transformation is deferred to FN. FN must return the three values
;;; TRANSFORM-TREE expects. If HANDLE-STRINGS, then FN is called with
;;; STRING nodes, too.
;;;
;;; If the CAR of a subtree is in STOP-TAGS, then the entire subtree
;;; is included in the output without further processing.
(defun defer-tag-handling (tags stop-tags handle-strings fn parent tree)
  (cond ((or (and (listp tree)
                  (member (first tree) tags))
             (and handle-strings
                  (stringp tree)))
         (funcall fn parent tree))
        ((and (listp tree)
              (member (first tree) stop-tags))
         (values tree nil nil))
        (t
         (values tree (and tree (listp tree)) nil))))

(defun map-markdown-parse-tree (tags stop-tags handle-strings fn parse-tree)
  (transform-tree (lambda (parent tree)
                    (defer-tag-handling tags stop-tags
                      handle-strings fn parent tree))
                  parse-tree))

(defun join-consecutive-non-blank-strings-in-parse-tree (parse-tree)
  (transform-tree
   (lambda (parent tree)
     (declare (ignore parent))
     (if (listp tree)
         (values (join-consecutive-non-blank-strings-in-list tree) t nil)
         tree))
   parse-tree))

(defun join-consecutive-non-blank-strings-in-list (list)
  (let ((result ()))
    (dolist (element list)
      (if (and (stringp element)
               (stringp (first result))
               (not (blankp element))
               (not (blankp (first result))))
          (setf (first result)
                (concatenate 'string (first result) element))
          (push element result)))
    (reverse result)))

;;; Call FN with STRING and START, END indices of @WORDS.
;;;
;;; FN must return two values: a replacement markdown parse tree
;;; fragment (or NIL, if the subseq shall not be replaced), whether
;;; the replacement shall be sliced into the result list. MAP-WORDS
;;; returns a parse tree fragment that's a list of non-replaced parts
;;; of STRING and replacements (maybe sliced). Consecutive strings are
;;; concatenated.
(defun map-words (string fn)
  (declare (type string string))
  (let ((translated ())
        (n (length string))
        (start 0))
    (flet ((add (a)
             (if (and (stringp a)
                      (stringp (first translated)))
                 (setf (first translated)
                       (concatenate 'string (first translated) a))
                 (push a translated))))
      (loop while (< start n)
            do (let* ((at-delimiter-p (delimiterp (aref string start)))
                      (end (or (if at-delimiter-p
                                   (position-if-not #'delimiterp string
                                                    :start start)
                                   (position-if #'delimiterp string
                                                :start start))
                               n)))
                 (if at-delimiter-p
                     (add (subseq string start end))
                     (multiple-value-bind (replacement slice)
                         (funcall fn string start end)
                       (cond ((null replacement)
                              (add (subseq string start end)))
                             (slice
                              (dolist (a replacement)
                                (add a)))
                             (t
                              (add replacement)))))
                 (setq start end))))
    (nreverse translated)))
