(in-package :mgl-pax)

(defvar *transcribe-check-consistency*)
(export '*transcribe-check-consistency*)
(defvar *transcribe-syntaxes*)
(export '*transcribe-syntaxes*)

(autoload transcribe '#:mgl-pax/transcribe)
(autoload transcribe-for-emacs '#:mgl-pax/transcribe :export nil)
(autoload squeeze-whitespace '#:mgl-pax/transcribe)
(autoload delete-trailing-whitespace '#:mgl-pax/transcribe)
(autoload delete-comments '#:mgl-pax/transcribe)

;;; Silence SBCL compiler notes.
#+sbcl
(define-condition transcription-error (error) ())
(export 'transcription-error)

#+sbcl
(define-condition transcription-consistency-error (transcription-error) ())
(export 'transcription-consistency-error)

#+sbcl
(define-condition transcription-consistency-error (transcription-error) ())
(export 'transcription-values-consistency-error)

#+sbcl
(define-condition transcription-consistency-error (transcription-error) ())
(export 'transcription-output-consistency-error)

(defsection @transcripts (:title "Transcripts")
  "This is a placeholder until MGL-PAX/TRANSCRIBE is loaded."
  (mgl-pax/transcribe asdf:system))
