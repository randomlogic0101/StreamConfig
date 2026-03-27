;;; core-version.el --- Git setup with Magit -*- lexical-binding: t; -*-

;; have you looked at emacs built-in vc-mode, it is what i use
;; a quick C-h f vc-mode could be a good start
;; here is some videos for it: https://codeberg.org/trondelag/BLOG/src/branch/WRITTEN/EMACS/VIDEO.org

;; Magit configuration
(use-package magit
  :bind ("C-x g" . magit-status)
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1)
  (setq magit-save-repository-buffers 'dontask))


(provide 'core-version)
;;; core-version.el ends here
