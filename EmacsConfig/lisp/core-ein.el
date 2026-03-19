;;; core-ein.el -*- lexical-binding: t; -*-

(defvar my/ein-prefix (make-sparse-keymap))
(define-key global-map (kbd "C-c e") my/ein-prefix)

(use-package ein
  :defer t
  :commands (ein:notebooklist-open
             ein:login
             ein:worksheet-run-cell
             ein:worksheet-run-all-cells)
  :init
  (define-key my/ein-prefix (kbd "l") #'ein:login)
  (define-key my/ein-prefix (kbd "n") #'ein:notebooklist-open)
  (define-key my/ein-prefix (kbd "r") #'ein:worksheet-run-cell)
  (define-key my/ein-prefix (kbd "a") #'ein:worksheet-run-all-cells)
  :custom
  (ein:jupyter-default-notebook-directory "~/Documents/Notebooks/"))

(provide 'core-ein)
