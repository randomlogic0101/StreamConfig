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

(unless (package-installed-p 'vc-use-package)
  (package-vc-install "https://github.com/slotThe/vc-use-package"))

(require 'vc-use-package)

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
(require 'core-irc)
(require 'core-pdf)
(require 'core-teaching)
(require 'core-git)
(require 'core-tabs)
(require 'core-xwidget)
;; TODO: Test embr
(require 'core-embr)
(require 'core-dirvish)
(require 'core-emote)
(require 'core-mpv)
(require 'core-ffmpeg)

(require 'core-exwm)

(use-package exec-path-from-shell
  :ensure t
  :init
  ;; Add variables BEFORE initialization
  (setq exec-path-from-shell-variables
        '("PATH" "MANPATH" "AP2" "APCMECH" "PHY" "CURRENT_YEAR"))
  :config
  (exec-path-from-shell-initialize))

;; Make sure auto saves go to ~/.local/share/tmp if available
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "~/.local/share/tmp/") t)
        ("\\`/[^/]*:\\([^/]*/\\)*\\([^/]*\\)\\'"
         ,(expand-file-name "~/.local/share/tmp/\\2") t)))
(setq backup-directory-alist
      `((".*" . ,(expand-file-name "~/.local/share/tmp/"))))

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(all-the-icons dirvish doom-themes ein embr emojify erc-hl-nicks
                   erc-image evil-mc exec-path-from-shell exwm forge
                   magit-todos mpv mpvi obsidian pdf-tools popwin
                   vc-use-package))
 '(package-vc-selected-packages
   '((embr :vc-backend Git :url "https://github.com/emacs-os/embr.el")
     (vc-use-package :vc-backend Git :url
                     "https://github.com/slotThe/vc-use-package"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
