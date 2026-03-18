(defclass dish ()
  ((name
    :type string
    :initform ""
    :initarg :name
    :accessor name-of)))

(defclass menu ()
  ((capacity
    :type integer
    :initform 0
    :initarg :capacity
    :accessor capacity-of

    :documentation
    "Defines number of dishes that menu can include")

   (contents
    :type list
    :initform '()
    :initarg :contents
    :accessor contents-of

    :documentation
    "Defines actual menu - a list of dishes")))

(defgeneric to-sexp (obj))

(defmethod to-sexp ((obj dish))
  (list 'dish (list :name (name-of obj))))

(defmethod to-sexp ((obj menu))
  (list 'menu
        (list :capacity (capacity-of obj)
              :contents (map 'list
                             (lambda (elm) (to-sexp elm))
                             (contents-of obj)))))

(defun from-sexp (sexp)
  (if (> (length sexp) 1)
      (%from-sexp% sexp)
      nil))

(defun %from-sexp% (sexp)
  (let ((type (first sexp))
        (params (second sexp)))

    (case type
      (dish (%dish-from-sexp% params))
      (menu (%menu-from-sexp% params)))))

(defun %dish-from-sexp% (params)
  (destructuring-bind (param value) params
    (if (equal :name param)
        (make-instance 'dish :name value)
        nil)))

(defun %menu-from-sexp% (params)
  (destructuring-bind (capacity-param capacity contents-param contents) params
    (if (and (equal :capacity capacity-param)
             (equal :contents contents-param))

        (make-instance 'menu
                       :capacity capacity
                       :contents (map 'list
                                      #'from-sexp
                                      contents)))))
