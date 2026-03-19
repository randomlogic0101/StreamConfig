;;; core-evil.el -*- lexical-binding: t; -*-

(use-package evil
  :init
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(defun my/evil-delete-whole-buffer ()
  (interactive)
  (evil-normal-state)
  (delete-region (point-min) (point-max)))

(define-key evil-normal-state-map (kbd "C-c d")
  #'my/evil-delete-whole-buffer)

(provide 'core-evil)
