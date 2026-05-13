;;; core-ui.el --- UI configuration -*- lexical-binding: t; -*-

(use-package emacs
  :ensure nil
  :init
  (setq inhibit-startup-message t
        vc-follow-symlinks t
        indent-tabs-mode nil
        tab-width 2)  ;; <- 4 would be a more standard set and leads to better readability
  (fset 'yes-or-no-p 'y-or-n-p)
  :config
  (save-place-mode 1)
  (electric-pair-mode 1)
  (global-display-line-numbers-mode 1)

  ;; Window resizing
  (defun my/shrink-window-horizontally ()
    "Shrink window width by 5 columns."
    (interactive)
    (shrink-window-horizontally 5))

  (defun my/enlarge-window-horizontally ()
    "Enlarge window width by 5 columns."
    (interactive)
    (enlarge-window-horizontally 5))

  (global-set-key (kbd "C-c <left>")  #'my/shrink-window-horizontally)
  (global-set-key (kbd "C-c <right>") #'my/enlarge-window-horizontally))

;; (use-package popwin
;;   :ensure t
;;   :config
;;   (popwin-mode 1))
;; 
;; (setq popwin:special-display-config nil)
;; (setq popwin:popup-window-position 'bottom)
;; (setq popwin:popup-window-height 0.3)
;; (setq popwin:reuse-window t)
;; (setq popwin:close-popup-window-timer-interval nil)

;; Relative line numbers
(defun my/relative-line-numbers ()
  (unless (or (minibufferp)
              (derived-mode-p 'special-mode))
    (setq display-line-numbers-type 'relative)))

(add-hook 'after-change-major-mode-hook #'my/relative-line-numbers)
;; this may also be on hook to prog mode, or always active
;; (add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Theme
(use-package doom-themes
  :config
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

;; Toggle menu/tool bars

(defun my/toggle-tool-and-menu-bars ()
  "Toggle the visibility of the tool‑bar and the menu‑bar.
   If either the tool‑bar or the menu‑bar is currently shown, both are
   hidden; otherwise both are shown.  The command also prints a short
   message in the echo area so you know the new state."
  (interactive)
  (let* ((tool-visible   (frame-parameter nil 'tool-bar-lines))
         (menu-visible   (frame-parameter nil 'menu-bar-lines))
         (new-visibility (if (or (= tool-visible 1)
                                 (= menu-visible 1))
                             0 1))) ;; for better readability in lisps i would keep or statements bellow each other

    ;; Apply the same value to both parameters
    (modify-frame-parameters nil
                             `((tool-bar-lines . ,new-visibility)
                               (menu-bar-lines . ,new-visibility)))
    (message "%s %s"
             (if (= new-visibility 1) "Enabled" "Disabled")
             (if (= new-visibility 1) "tool‑bar & menu‑bar" "tool‑bar & menu‑bar"))))

;; TODO add these names to the exwm buffers
(defvar my/layout-buffers
  '(:left "*Left-Buffer*"
          :top-right "*Top-Right*"
          :bottom-right "*Bottom-Right*")
  "Named buffers for custom layout.")

;; This mimics what happens in exwm, but runs if not in exwm

(defun my/setup-custom-layout ()
  "Set up a 3-pane layout with named buffers.
   Only runs if $EXWM is not 1."
  (interactive)
  (unless (string= (getenv "EXWM") "1")
    (delete-other-windows)  ;; start clean

    ;; Split left/right
    (let ((left-width (/ (window-total-width) 2)))
      (let ((left (selected-window))  ;; why is this let nested and not declared with the one above?
            (right (split-window-right left-width)))

        ;; Left buffer
        (select-window left)
        (switch-to-buffer (get-buffer-create (plist-get my/layout-buffers :left)))

        ;; Right: split top/bottom
        (select-window right)
        (let ((top-right (selected-window)) ;; this as well could be in the starting let
              (bottom-right (split-window-below)))

          ;; Top-right buffer
          (select-window top-right)
          (switch-to-buffer (get-buffer-create (plist-get my/layout-buffers :top-right)))

          ;; Bottom-right buffer
          (select-window bottom-right)
          (switch-to-buffer (get-buffer-create (plist-get my/layout-buffers :bottom-right)))

          ;; Start shell in bottom-right
          (ansi-term "/usr/bin/env bash")))))
  ;; Go back to left buffer at the end
  (select-window (get-buffer-window (plist-get my/layout-buffers :left))))

(defun my/start-term ()
  "Start a terminal in the current directory."
  (interactive)
  (let ((proc (make-term-process "my-term" nil default-directory "/usr/bin/env bash")))
    (set-process-query-on-exit-flag proc nil)
    (with-current-buffer (process-buffer proc)
      (term-mode)
      (term-char-mode))))

;; Jump to buffer functions
(defun my/jump-to-left-buffer ()
  (interactive)
  (let ((buf (get-buffer (plist-get my/layout-buffers :left))))
    (when buf (switch-to-buffer buf))))

(defun my/jump-to-top-right-buffer ()
  (interactive)
  (let ((buf (get-buffer (plist-get my/layout-buffers :top-right))))
    (when buf (switch-to-buffer buf))))

(defun my/jump-to-bottom-right-buffer ()
  (interactive)
  (let ((buf (get-buffer (plist-get my/layout-buffers :bottom-right))))
    (when buf (switch-to-buffer buf))))

;; Highlight annoying white space
;; Define a light green face for trailing whitespace
(defface my/trailing-whitespace-face
  '((t (:background "#4a5d23" :foreground "white")))
  "Face for highlighting trailing whitespace.")

;; Configure whitespace-mode
(setq whitespace-style
      '(face                    ; Highlight trailing whitespace with face
        tabs                    ; Show tabs
        spaces                  ; Show spaces
        trailing                ; Mark trailing whitespace
        empty-line              ; Highlight blank lines with spaces
        empty-line-before       ; Blank lines before
        space-mark              ; Show space markers
        tab-mark))              ; Show tab markers

(setq whitespace-face 'default)
(setq whitespace-trailing-face 'my/trailing-whitespace-face)
(setq whitespace-empty-line-face 'my/trailing-whitespace-face)

;; Try to keep popups in the same window
(setq display-buffer-base-action '(display-buffer-same-window))
;; (setq display-buffer-alist
;;       '((".*"
;;          (display-buffer-reuse-window
;;           display-buffer-same-window)
;;          (reusable-frames . t))))

;; Enable whitespace-mode globally
(global-whitespace-mode 1)
(setq column-number-mode t)

(global-set-key (kbd "C-c 1") #'my/jump-to-left-buffer)
(global-set-key (kbd "C-c 2") #'my/jump-to-top-right-buffer)
(global-set-key (kbd "C-c 3") #'my/jump-to-bottom-right-buffer)
(global-set-key (kbd "C-c C-t") #'my/toggle-tool-and-menu-bars)
(global-set-key (kbd "C-c l") #'my/setup-custom-layout)

;; Set an after load hook to setup the layout
(add-hook 'emacs-startup-hook #'my/setup-custom-layout)

(provide 'core-ui)
;;; core-ui.el ends here
