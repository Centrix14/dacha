(defclass dish ()
  ((name
    :type string
    :initform ""
    :initarg :name
    :accessor name-of)))

(defclass menu ()
  ((length
    :type integer
    :initform 0
    :initarg :length
    :accessor length-of)))

(defgeneric to-sexp (obj))

(defmethod to-sexp ((obj dish))
  (list 'dish (list :name (name-of obj))))

(defun from-sexp (sexp)
  (if (> (length sexp) 1)
      (%from-sexp% sexp)
      nil))

(defun %from-sexp% (sexp)
  (let ((type (first sexp))
        (params (second sexp)))

    (case type
      (dish (%dish-from-sexp% params)))))

(defun %dish-from-sexp% (params)
  (destructuring-bind (param value) params
    (if (equal :name param)
        (make-instance 'dish :name value)
        nil)))
