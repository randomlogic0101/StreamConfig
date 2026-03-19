;;; core-version.el --- Git setup with Magit -*- lexical-binding: t; -*-

;; Magit configuration
(use-package magit
  :bind ("C-x g" . magit-status)
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1)
  (setq magit-save-repository-buffers 'dontask))


(provide 'core-version)
;;; core-version.el ends here
