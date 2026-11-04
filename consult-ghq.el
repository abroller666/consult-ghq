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

(defun consult-ghq--roots ()
  "Return all ghq roots as directory names, longest first."
  (sort (mapcar (lambda (root) (file-name-as-directory (expand-file-name root)))
                (consult-ghq--call "root" "--all"))
        (lambda (a b) (> (length a) (length b)))))

(defun consult-ghq--split (dir roots)
  "Return (ROOT . NAME) for repository DIR, using the longest match in ROOTS.
ROOT is nil when DIR is under none of ROOTS; NAME is then the full path."
  (if-let* ((root (cl-find-if (lambda (r) (string-prefix-p r dir)) roots)))
      (cons root (directory-file-name (substring dir (length root))))
    (cons nil (abbreviate-file-name (directory-file-name dir)))))

(defun consult-ghq--candidates ()
  "Return ghq candidates: display names carrying their absolute path.
Names that occur under several roots are suffixed with their root."
  (let* ((roots (consult-ghq--roots))
         (dirs (mapcar (lambda (path) (file-name-as-directory (expand-file-name path)))
                       (consult-ghq--call "list" "--full-path")))
         (splits (mapcar (lambda (dir) (consult-ghq--split dir roots)) dirs))
         (counts (make-hash-table :test #'equal)))
    (unless dirs
      (user-error "No ghq repositories found"))
    (dolist (split splits)
      (cl-incf (gethash (cdr split) counts 0)))
    (cl-mapcar
     (lambda (dir split)
       (let ((root (car split))
             (name (cdr split)))
         (propertize
          (if (and root (> (gethash name counts) 1))
              (format "%s [%s]" name (abbreviate-file-name (directory-file-name root)))
            name)
          'consult-ghq-directory dir)))
     dirs splits)))

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
