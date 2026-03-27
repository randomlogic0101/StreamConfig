;;; init.el --- Main init file -*- lexical-binding: t; -*-

;; Restore sane GC after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 50 1000 1000))))

;; this would clean up files and remove unintended whitespace in files
(add-hook  'before-save-hook              'delete-trailing-whitespace      )
;; this option would mark trailing whitespace anfd show it, dave has this in his vim as well
(setq-default show-trailing-whitespace t)


(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/"))
      package-archive-priorities
      '(("gnu"    . 20)
        ("melpa"  . 15)
        ("nongnu" . 0)))

(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

;; Add lisp directory
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Load modules
(require 'core-ui)
(require 'core-evil)
(require 'core-shell)
(require 'core-python)
(require 'core-ein)
(require 'core-notes)
(require 'core-media)
(require 'core-fonts)
(require 'core-utils)
(require 'core-dired)

(require 'core-exwm)


(provide 'init)
;;; init.el ends here
