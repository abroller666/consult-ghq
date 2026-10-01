;;; consult-ghq.el --- Select ghq repositories with Consult -*- lexical-binding: t; -*-

;; Author: maruko
;; URL: https://github.com/abroller666/consult-ghq
;; Version: 0.2.0
;; Package-Requires: ((emacs "29.1") (consult "1.0"))
;; Keywords: convenience, tools

;;; Commentary:
;; `consult-ghq' selects a ghq-managed repository with Consult and opens it
;; as an Emacs project.

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'project)
(require 'subr-x)

(defgroup consult-ghq nil
  "Select ghq repositories with Consult."
  :group 'convenience)

(defcustom consult-ghq-program "ghq"
  "Name or path of the ghq executable."
  :type 'string)

(defcustom consult-ghq-action #'project-switch-project
  "Function called with the selected repository directory."
  :type 'function)

(defvar consult-ghq-history nil
  "History for `consult-ghq'.")

(defun consult-ghq--program ()
  "Return the ghq executable path, or signal an error."
  (or (executable-find consult-ghq-program)
      (user-error "ghq executable not found: %s" consult-ghq-program)))

(defun consult-ghq--call (&rest args)
  "Run ghq with ARGS and return its stdout lines.
Signal a `user-error' on non-zero exit, including ghq's stderr."
  (let ((stderr (make-temp-file "consult-ghq-stderr")))
    (unwind-protect
        (with-temp-buffer
          (let ((status (apply #'call-process (consult-ghq--program)
                               nil (list t stderr) nil args)))
            (unless (eq status 0)
              (user-error "ghq %s failed: %s"
                          (string-join args " ")
                          (string-trim
                           (with-temp-buffer
                             (insert-file-contents stderr)
                             (buffer-string)))))
            (split-string (buffer-string) "\n" t)))
      (delete-file stderr))))

(defun consult-ghq--candidates ()
  "Return ghq candidates: display names carrying their absolute path."
  (let ((names (consult-ghq--call "list"))
        (paths (consult-ghq--call "list" "--full-path")))
    (unless names
      (user-error "No ghq repositories found"))
    (unless (= (length names) (length paths))
      (error "ghq list output mismatch (%d names, %d paths)"
             (length names) (length paths)))
    (cl-mapcar
     (lambda (name path)
       (propertize name 'consult-ghq-directory
                   (file-name-as-directory (expand-file-name path))))
     names paths)))

(defun consult-ghq--lookup (selected candidates &rest _)
  "Return the directory of SELECTED among CANDIDATES."
  (when-let* ((cand (car (member selected candidates))))
    (get-text-property 0 'consult-ghq-directory cand)))

(defun consult-ghq--annotate (cand)
  "Annotate CAND with its absolute repository path."
  (when-let* ((dir (get-text-property 0 'consult-ghq-directory cand)))
    (concat "  " (propertize (abbreviate-file-name (directory-file-name dir))
                             'face 'completions-annotations))))

;;;###autoload
(defun consult-ghq ()
  "Select a ghq repository with Consult and open it as a project."
  (interactive)
  (let ((directory
         (consult--read
          (consult-ghq--candidates)
          :prompt "ghq repository: "
          :category 'consult-ghq
          :require-match t
          :sort nil
          :history 'consult-ghq-history
          :lookup #'consult-ghq--lookup
          :annotate #'consult-ghq--annotate)))
    (funcall consult-ghq-action directory)))

(provide 'consult-ghq)
;;; consult-ghq.el ends here
