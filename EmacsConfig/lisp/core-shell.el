;;; core-shell.el -*- lexical-binding: t; -*-

(use-package shell
  :ensure nil
  :init
  (setq explicit-shell-file-name "/usr/bin/bash")
  (setenv "SHELL" explicit-shell-file-name)
  (setenv "TERM" "xterm-256color")
  :config
  (setq comint-terminfo-terminal "xterm-256color"))

(provide 'core-shell)
