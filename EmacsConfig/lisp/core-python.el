;;; core-python.el -*- lexical-binding: t; -*-

(use-package python
  :ensure nil
  :hook (python-mode . (lambda () ;; again with a diffrent style with (lambda ()
                         (setq python-shell-interpreter "python3"))))

(provide 'core-python)
