;;; core-shell.el -*- lexical-binding: t; -*-

(use-package shell :ensure nil
  :init
  ;; Try to find a bash shell
  (setq explicit-shell-file-name (or (getenv "BASH")
				     (getenv "SHELL")
				     "/usr/bin/bash"))
  (setenv "SHELL" explicit-shell-file-name)
  (setenv "TERM" "xterm-256color")
  :config
  (setq comint-terminfo-terminal "xterm-256color"))

(provide 'core-shell)

