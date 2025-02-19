(in-package :mgl-pax)

(in-readtable pythonic-string-syntax)

;;;; HANDLE-PAX*-REQUEST

(defmacro with-errors-to-html (&body body)
  (alexandria:with-gensyms (error)
    `(block nil
       (handler-bind
           ((error (lambda (,error)
                     (when hunchentoot:*catch-errors-p*
                       (trivial-backtrace:print-backtrace ,error)
                       (return (format nil "<h2>Error</h2><p>~A</p>"
                                       ,error))))))
         (progn ,@body)))))

(defun handle-pax*-request ()
  (with-errors-to-html
    (with-swank ()
      (let* ((pax-url (request-pax*-url))
             (pkgname (hunchentoot:get-parameter "pkg"))
             (*package* (or (find-package* pkgname)
                            (find-package* (ignore-errors
                                            (read-from-string pkgname)))
                            (find-package :cl)))
             (editp (hunchentoot:get-parameter "edit")))
        (if editp
            (progn
              (edit-pax-url-in-emacs pax-url)
              (setf (hunchentoot:return-code*) hunchentoot:+http-no-content+)
              nil)
            (uiop:with-temporary-file (:pathname temp-file-name)
              (let ((url (document-for-web pax-url temp-file-name)))
                (multiple-value-bind (scheme authority path) (parse-url url)
                  (declare (ignore authority))
                  (if (and (string= scheme "file")
                           (string= path (namestring temp-file-name)))
                      (alexandria:read-file-into-string path)
                      (hunchentoot:redirect url))))))))))

(defun request-pax*-url ()
  (let ((uri (hunchentoot:request-uri*)))
    (assert (char= (aref uri 0) #\/))
    (subseq uri 1)))

(defun document-for-web (pax-url filename)
  (let ((*document/open-extra-args*
          `(:pages ((:objects :default
                     :header-fn ,(lambda (stream)
                                   (html-header stream
                                                :title (urldecode pax-url)
                                                :stylesheet "style.css"))
                     :footer-fn ,#'html-footer
                     :source-uri-fn ,#'reference-to-edit-uri)))))
    (document-pax*-url pax-url filename)))

(defun reference-to-edit-uri (reference)
  (let ((url (finalize-pax-url (reference-to-pax-url reference))))
    (if (find #\? url)
        (format nil "~A&edit" url)
        (format nil "~A?edit" url))))

(defun edit-pax-url-in-emacs (pax-url)
  (when (swank::default-connection)
    (multiple-value-bind (scheme authority path) (parse-url pax-url)
      (declare (ignore authority))
      (unless (equal scheme "pax")
        (error "~S doesn't have pax: scheme." pax-url))
      (multiple-value-bind (object locative foundp)
          (read-reference-from-string path)
        (when foundp
          (swank::with-connection ((swank::default-connection))
            (let* ((reference (make-reference object locative))
                   (dspec (reference-to-dspec reference))
                   (location (ignore-errors (find-source reference))))
              (when (eq (first location) :location)
                (swank:eval-in-emacs `(mgl-pax-edit-for-cl
                                       '((,dspec ,location))))))))))))


;;;; Hyperspec

;;; The previous hyperspec root with which ENSURE-WEB-SERVER was
;;; called.
(defvar *web-hyperspec-root* nil)

;;; Dispatcher if the hyperspec is published via this web server.
(defvar *hyperspec-dispatch-table* ())

;;; The *DOCUMENT-HYPERSPEC-ROOT* to use when DOCUMENTing.
(defvar *web-document-hyperspec-root* nil)

(defun set-web-hyperspec-root (hyperspec-root)
  (unless (equal hyperspec-root *web-hyperspec-root*)
    (setq *web-hyperspec-root* hyperspec-root)
    ;; Treat normal file names as file URLs.
    (if (equal (or (ignore-errors (parse-url hyperspec-root))
                   "file")
               "file")
        ;; By default, Chrome and Firefox don't allow linking or
        ;; redirection from a http: URL to a file: URL, so we publish
        ;; the files under CLHS/.
        (let ((path (or (ignore-errors (nth-value 2 (parse-url hyperspec-root)))
                        hyperspec-root)))
          (setq *hyperspec-dispatch-table*
                (list (hunchentoot:create-folder-dispatcher-and-handler
                       "/CLHS/" path)))
          (setq *web-document-hyperspec-root* "/CLHS/"))
        (setq *hyperspec-dispatch-table* ()
              *web-document-hyperspec-root* hyperspec-root))))


;;;; Web server

;;; HUNCHENTOOT:*DISPATCH-TABLE* will be bound to this locally to
;;; avoid conflicts with other HUNCHENTOOT servers running in the same
;;; image.
(defun web-toplevel-static-files ()
  (let ((static-root (asdf:system-relative-pathname :mgl-pax "web/")))
    (values (uiop:directory* (merge-pathnames "*.*" static-root))
            static-root)))

(defparameter *dispatch-table*
  (multiple-value-bind (static-files static-root) (web-toplevel-static-files)
    (let ((dispatchers ()))
      (dolist (file static-files)
        (unless (let ((name (pathname-name file)))
                  (and (stringp name)
                       (alexandria:starts-with-subseq "README" name)))
          (let ((uri (format nil "/~A" (enough-namestring file static-root))))
            (pushnew (if (uiop:directory-pathname-p file)
                         (hunchentoot:create-folder-dispatcher-and-handler
                          uri file)
                         (hunchentoot:create-static-file-dispatcher-and-handler
                          uri file))
                     dispatchers))))
      (push (hunchentoot:create-prefix-dispatcher "/pax" 'handle-pax*-request)
            dispatchers)
      dispatchers)))

(defvar *server*
  (make-instance 'hunchentoot:easy-acceptor
                 ;; Any free port
                 :port 0
                 :access-log-destination nil))

(defun %start-server (port)
  (when port
    (setf (slot-value *server* 'hunchentoot::port) port))
  (hunchentoot:start *server*)
  (assert (plusp (hunchentoot:acceptor-port *server*))))

(defmethod hunchentoot:acceptor-dispatch-request
    :around ((acceptor (eql *server*)) request)
  (let ((hunchentoot:*dispatch-table* (append *dispatch-table*
                                              *hyperspec-dispatch-table*))
        (*document-hyperspec-root*
          (cond ((null *web-document-hyperspec-root*)
                 *document-hyperspec-root*)
                ((equal *web-document-hyperspec-root* "/CLHS/")
                 (format nil "~A/CLHS/" (web-base-url)))
                (t
                 *web-document-hyperspec-root*)))
        (*read-eval* nil))
    (call-next-method)))

(defun/autoloaded ensure-web-server (&key hyperspec-root port)
  (swank/backend:converting-errors-to-error-location
    (if (not (hunchentoot:started-p *server*))
        (%start-server port)
        ;; Treat both NIL and 0 as 'any port'.
        (when (and port (plusp port)
                   (/= port (hunchentoot:acceptor-port *server*)))
          (hunchentoot:stop *server*)
          (%start-server port)))
    (when hyperspec-root
      (set-web-hyperspec-root hyperspec-root))
    `(:base-url ,(web-base-url))))

(defun web-base-url ()
  (format nil "http://localhost:~S" (hunchentoot:acceptor-port *server*)))
